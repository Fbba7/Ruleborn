class_name ObservatoryTests
extends RefCounted
## The Observatory and the scout report (§12.3, §12.4, §23.2): their words
## headless, the flows through a FakeTransport, the screens as drawn, and the
## Observatory against the server when one is named.

var tree: SceneTree
var check: Callable
var mount: Callable
var server_url := ""


func _init(t: SceneTree, c: Callable, m: Callable, url: String) -> void:
	tree = t
	check = c
	mount = m
	server_url = url


func run() -> void:
	_words()
	_names()
	await _flows()
	await _on_screen()
	await _online()


static func _card(bundle: String, kind: String, extra := {}) -> Dictionary:
	var c := {"bundle": bundle, "kind": kind, "reason": "fair", "fee": 120, "keeper_level": 7, "realms": 3,
		"renown": 410, "loot": 1200, "strain": 1.12, "band": 5, "faults": 2,
		"realm": {"realm": "heart", "realm_level": 3, "vault_level": 3, "watch": [1.0, 0.7],
			"laws": ["brittle_stone", "glass"], "guards": {"Warden": 1, "Breaker": 1},
			"wards": {"gravity_well": 2, "time_snare": 1}}}
	c.merge(extra, true)
	return c


## An Observatory as GET /v1/observatory answers: a player's universe, an
## echo, the game's own island and a Trace apart.
static func sample() -> Dictionary:
	return {"size": 3, "aether": 40, "protected": true, "echoes": true, "generated": true,
		"refresh": {"aether": 50},
		"trace": _card("t1", "trace", {"fee": 0, "reason": "trace"}),
		"targets": [_card("p1", "player", {"reason": "easier"}), _card("e1", "echo", {"reason": "harder"}),
			_card("g1", "generated", {"keeper_level": null, "renown": null, "realms": 1, "success": [0.55, 0.7]})]}


func _words() -> void:
	var o := ObservatoryPresenter.screen({"view": sample(), "busy": "", "error": ""})
	var cards: Array = o["cards"]
	check.call("the Observatory labels each target — a player's universe, an echo, the game's own island with its "
			+ "band — and pins a Trace apart, with no fee (12.3, 12.22)",
		cards.size() == 3 and cards[0]["title"] == "A Keeper of level 7"
			and cards[1]["title"] == "An echo of a Keeper of level 7"
			and cards[2]["title"] == "The game's own island, won 55 to 70% of the time"
			and o["trace"]["title"] == "Trace: the Keeper of level 7 who robbed you"
			and "No entry fee" in o["trace"]["lines"]
			and o["fallback"] == "Few universes fit you now: the game's own islands are among these",
		"%s | %s" % [cards.map(func(c: Dictionary) -> String: return c["title"]), o["trace"]])
	var at_home := sample()
	at_home["wanderer"] = true
	at_home["size"] = 4
	var w := ObservatoryPresenter.screen({"view": at_home, "busy": "", "error": ""})
	check.call("with the Wanderer at home the Observatory says so and offers one more target (12.3, 11.7)",
		w["wanderer"] == "The Wanderer is at home: one more target" and w["header"].ends_with("4 targets")
			and o["wanderer"] == "",
		"%s | %s" % [w.get("wanderer"), w.get("header")])
	var lines: Array = cards[0]["lines"]
	check.call("each target card shows §12.4's free facts — realms, Renown, a rough loot estimate, strain and open "
			+ "faults — the lease's fee and why it was offered (12.4, 12.15)",
		lines == ["3 realms · Renown 410 · about 1,200 loot", "Strain 112%, Cracking · open faults: 2",
			"Realm level 3 · 2 laws · 2 guards · 3 wards", "Entry fee 120 Starlight", "Offered as an easier target"],
		"%s" % [lines])
	check.call("a refresh says its price, and waits with why when the Aether is short; a protected new Keeper is told "
			+ "raiding a player ends it (12.3)",
		o["refresh"]["action"] == "New targets for 50 Aether" and not o["refresh"]["can"]
			and o["refresh"]["why"] == "needs 50 Aether"
			and o["protected"] == "You are protected as a new Keeper; raiding a player ends that",
		"%s" % [o["refresh"]])
	var s := ObservatoryPresenter.scout({"view": sample(), "chosen": "p1"})
	check.call("the scout report reads a target realm by realm — its laws, guards by role, wards by kind, its watch — "
			+ "and says nothing placed is shown (12.4)",
		s["ready"] and s["lines"] == ["The Heart · realm level 3 · Vault level 3", "Laws: Brittle stone, Glass",
			"Guards: Breaker 1, Warden 1", "Wards: Gravity Well 2, Time Snare 1",
			"Watch: suspicion fills at 100%, sight reaches 70%",
			"Where guards stand and wards lie is found in the heist"]
			and s["raid"]["action"] == "Plan · Entry fee 120 Starlight",
		"%s" % [s.get("lines")])


## G58: a card names its Keeper from the word lists; the game's own island
## has none.
func _names() -> void:
	var words := HatchTests.words()
	var named := sample()
	named["targets"][0]["keeper_name"] = {"adjective": 1, "noun": 0}
	var o := ObservatoryPresenter.screen({"view": named, "busy": "", "error": "", "words": words})
	var expected := "Keeper: " + SocialPresenter.word_name(words, 1, 0)
	var s := ObservatoryPresenter.scout({"view": named, "chosen": "p1", "words": words})
	check.call("each target card names its Keeper from the word lists, a free fact, and the game's own island names "
			+ "none (12.4, G58)",
		o["cards"][0]["lines"][0] == expected and s["facts"][0] == expected
			and not str(o["cards"][2]["lines"]).contains("Keeper: "),
		"%s | %s" % [o["cards"][0]["lines"], s["facts"]])


func _flows() -> void:
	var transport := FakeTransport.new()
	var s := Fixtures.answered(Services.build(tree.root, "https://edge.example", transport,
		"user://outbox-observatory-test.json"))
	s.api.token = "t"
	var routes: Array[StringName] = []
	s.router.change = func(path: String) -> void: routes.append(StringName(path.get_file().get_basename()))
	transport.on("GET /v1/observatory", sample())
	await s.observatory_flow.load_observatory()
	var refreshed := sample()
	refreshed["aether"] = 0
	transport.on("POST /v1/observatory/refresh", refreshed)
	await s.observatory_flow.refresh()
	var after: Dictionary = s.store.get_slice(ObservatoryState.OBSERVATORY)
	s.observatory_flow.choose("t1")
	var chosen := str(s.store.get_slice(ObservatoryState.OBSERVATORY)["chosen"])
	s.observatory_flow.raid(sample()["trace"])
	var planned: Dictionary = s.store.get_slice(PlannerState.PLANNER)["target"]
	check.call("the Observatory is fetched and refreshed from the server; a card opens its scout report, and its Plan "
			+ "opens the planner on that target, a Trace as a Trace (12.3, 12.5)",
		int(after["view"]["aether"]) == 0 and transport.calls[-1]["route"] == "POST /v1/observatory/refresh"
			and chosen == "t1" and planned.get("bundle") == "t1" and planned.get("kind") == "trace"
			and &"scout" in routes and &"planner" in routes,
		"%s | %s | %s" % [chosen, planned, routes])
	s.close()


func _on_screen() -> void:
	var services: Services = App.services
	var screen: ObservatoryScreen = await mount.call("observatory")
	# The screen's own fetch answers first; the sample is the newer view.
	for i in 5:
		await tree.process_frame
	services.store.dispatch(&"observatory_loaded", {"view": sample()})
	var kinds := screen.body.find_children("*", "Label", true, false).filter(
		func(l: Label) -> bool: return l.has_meta("kind")).map(func(l: Label) -> String: return l.get_meta("kind"))
	var refresh: Button = null
	for b: Button in screen.find_children("*", "Button", true, false):
		if b.get_meta("key", "") == "refresh":
			refresh = b
	var waits := refresh != null and refresh.disabled
	var keys := screen.find_children("*", "Button", true, false).map(
		func(b: Button) -> String: return "%s:%s" % [b.get_meta("key", ""), b.disabled])
	screen.queue_free()
	await tree.process_frame
	check.call("the Observatory screen draws the Trace first and apart, then each target, and a refresh that waits "
			+ "while the Aether is short (12.3, 23.2)",
		kinds == ["trace", "player", "echo", "generated"] and waits,
		"%s %s" % [kinds, keys])


func _online() -> void:
	var name := "against the server: a new Keeper's Observatory lists targets as cards with no rating and a fee, "
	name += "and a refresh it cannot pay for is refused at 50 Aether (12.3, 12.4)"
	if server_url == "":
		check.call(name, false, "no server: run through client/status.py, which starts one")
		return
	var s := Fixtures.answered(Services.build(tree.root, server_url, null, "user://outbox-test-observatory.json"))
	s.router.change = func(_path: String) -> void: pass
	var me := await s.account.sign_in("test:observatory")
	if not me.ok:
		check.call(name, false, "sign-in refused: %s" % me.code)
		s.close()
		return
	await s.observatory_flow.load_observatory()
	var v: Dictionary = s.store.get_slice(ObservatoryState.OBSERVATORY)["view"]
	var targets: Array = v.get("targets", [])
	var clean := targets.all(func(c: Dictionary) -> bool:
		return not c.has("rating") and not c.has("deviation") and c.has("fee") and c.has("realm"))
	await s.observatory_flow.refresh()
	var after: Dictionary = s.store.get_slice(ObservatoryState.OBSERVATORY)
	check.call(name,
		int(v.get("size", 0)) == 3 and clean and after["error"] == "not_enough_aether"
			and int((after["detail"] as Dictionary).get("cost", 0)) == 50,
		"%s targets, clean %s, %s" % [targets.size(), clean, after["error"]])
	s.close()
