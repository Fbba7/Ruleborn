class_name HatchTests
extends RefCounted
## The Hatch screen (§11.5, §11.9, §11.10, §19.20, §23.2): its words
## headless, its changes through a FakeTransport, the screen as drawn, and
## naming against the server when one is named.

const NOW := 1_000_000_000

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
	await _flows()
	await _on_screen()
	await _online()


## Two word lists, cut to their English.
static func words() -> Dictionary:
	return {"adjectives": [{"en": "Quiet"}, {"en": "Brave"}], "nouns": [{"en": "Lantern"}, {"en": "Comet"}]}


## A home as GET /v1/home answers with a Nursery in Lantern Vale holding two
## of its three births, its laws tying Hush and Echo, and a stray a heist
## found under Stillness.
static func sample() -> Dictionary:
	var v := RosterTests.sample()
	v["next_birth"] = 135
	v["essence"] = 500
	v["nurseries"] = [{"realm": "outer-1", "ready": 2, "holds": 3, "next_at": NOW + 65 * 60000,
		"kinds": [{"kind": "lantern_wisp", "odds": 0.5}, {"kind": "soulmender", "odds": 0.25},
			{"kind": "echoplate", "odds": 0.25}],
		"forms": [{"note": "hush", "odds": 0.5}, {"note": "spark", "odds": 0.0}, {"note": "echo", "odds": 0.5}]}]
	v["strays"] = [{"id": 7, "kind": "hourkeeper", "school": "Time", "role": "Mender",
		"traits": ["swift", "quiet", "lucky"],
		"law": "stillness", "forms": [{"note": "hush", "odds": 1.0}, {"note": "spark", "odds": 0.0},
			{"note": "echo", "odds": 0.0}], "cost": 135}]
	return v


## The home after a first birth: a Lantern wisp with its two traits.
static func born() -> Dictionary:
	var v := sample()
	(v["characters"] as Array).append({"id": 9, "kind": "lantern_wisp", "school": "Spirit", "role": "Scout",
		"traits": ["brave", "sleepy"], "level": 1, "top": 4, "home": "outer-1", "via": "birth", "state": "idle",
		"work": null, "form": "echo", "name": null, "next_level": {"to": 2, "cost": 150, "blocked": null}})
	v["nurseries"][0]["ready"] = 1
	return v


func _words() -> void:
	var slice := {"view": sample(), "busy": "", "error": "", "last": {}}
	var h := HatchPresenter.screen(slice, words(), NOW)
	var n: Dictionary = h["nurseries"][0]
	check.call("Hatch shows each Nursery's ready births of the three it holds, when the next comes, and the price "
			+ "(10.2, 9.5, 23.2)",
		n["title"] == "Nursery in Lantern Vale" and n["ready"] == "2 of 3 births ready"
			and n["next"] == "the next in 1 h 5 min" and h["header"] == "Each birth costs 135 Essence; you have 500"
			and n["button"]["action"] == "Hatch, 135 Essence" and n["button"]["can"]
			and n["button"]["args"] == {"realm": "outer-1"},
		"%s | %s" % [h["header"], n])
	var poor := sample()
	poor["essence"] = 100
	poor["nurseries"][0]["ready"] = 0
	var waits: Dictionary = HatchPresenter.screen({"view": poor}, {}, NOW)["nurseries"][0]["button"]
	var none := sample()
	none["nurseries"] = []
	check.call("Hatch shows each kind's odds by 11.9's weights and the form's odds on a tie, as the server works "
			+ "them out, and says why a birth waits (11.9, 11.10, 23.2)",
		n["kinds"] == ["Lantern Wisp: 50%", "Soulmender: 25%", "Echoplate: 25%"]
			and n["forms"] == "Hush: 50% · Echo: 50%" and h["strays"][0]["forms"] == "Hush, certain"
			and not waits["can"] and waits["why"] == "no birth ready yet"
			and HatchPresenter.screen({"view": none}, {}, NOW)["none"]
				== "Build a Nursery in an outer realm to hatch ruleborn",
		"%s | %s | %s" % [n["kinds"], n["forms"], waits])
	var after := HatchPresenter.screen({"view": born(), "busy": "", "error": "",
		"last": {"what": {"do": "birth", "born": 9, "first": true, "outfit": "hatch-outfit"}}}, words(), NOW,
		{"adjective": 1, "noun": 0})
	var nb: Dictionary = after["newborn"]
	check.call("Hatch shows the two traits a birth rolled, its form, and the free outfit with the first hatch, and "
			+ "offers a name from the word lists (11.3, 19.20, 23.2)",
		nb["title"] == "Hatched: Lantern Wisp" and nb["traits"] == "Traits: Brave, Sleepy"
			and nb["form"].begins_with("Echo · ") and nb["outfit"] == "A free outfit comes with your first hatch"
			and nb["name"] == "Name: Brave Lantern" and nb["give"]["args"] == {"id": 9, "adjective": 1, "noun": 0}
			and nb["give"]["can"],
		"%s" % [nb])
	var s: Dictionary = h["strays"][0]
	check.call("Hatch offers a heist's stray at a birth's price, with the law it was born under, its traits and "
			+ "its form's odds, to take in or let go (11.5, 23.2)",
		s["title"] == "A stray Hourkeeper, found on a heist" and s["born"] == "Born under Stillness"
			and s["traits"] == "Traits: Swift, Quiet, Lucky" and s["take"]["action"] == "Take it in, 135 Essence"
			and s["take"]["can"] and s["take"]["args"] == {"stray": 7} and s["decline"]["action"] == "Let it go"
			and s["decline"]["spoken"] == "Let the Hourkeeper go",
		"%s" % [s])


func _flows() -> void:
	var transport := FakeTransport.new()
	var s := Fixtures.answered(Services.build(tree.root, "https://edge.example", transport,
		"user://outbox-hatch-test.json"))
	s.api.token = "t"
	transport.on("GET /v1/home", sample())
	await s.roster_flow.load_roster()
	transport.on("POST /v1/home/births", {"born": 9, "first": true, "outfit": "hatch-outfit", "home": born()})
	await s.roster_flow.hatch("outer-1")
	var sent: Dictionary = JSON.parse_string((transport.calls[-1]["body"] as PackedByteArray).get_string_from_utf8())
	var after: Dictionary = s.store.get_slice(RosterState.ROSTER)
	transport.on("POST /v1/home/characters/9/name", {"home": born()})
	await s.roster_flow.name_character(9, 1, 0)
	var named: Dictionary = JSON.parse_string((transport.calls[-1]["body"] as PackedByteArray).get_string_from_utf8())
	transport.on("POST /v1/home/strays/7/take", {"error": "not_enough_essence", "cost": 135}, 409)
	await s.roster_flow.take_stray(7)
	var refused: Dictionary = s.store.get_slice(RosterState.ROSTER)
	var gone := born()
	gone["strays"] = []
	transport.on("POST /v1/home/strays/7/decline", {"home": gone})
	await s.roster_flow.decline_stray(7)
	var declined: Dictionary = s.store.get_slice(RosterState.ROSTER)
	check.call("a hatch names the roster size it leads to, a stray is taken or let go, and a name is sent as the "
			+ "word lists' indices; a refusal says why (11.5, 19.20)",
		int(sent["n"]) == 5 and sent["realm"] == "outer-1" and after["last"]["what"]["born"] == 9
			and after["last"]["what"]["first"] and int(named["adjective"]) == 1 and int(named["noun"]) == 0
			and HatchPresenter.screen(refused, {}, NOW)["error"] == Errors.message("HATCH_FAILED", "not_enough_essence")
			and (declined["view"]["strays"] as Array).is_empty()
			and HatchPresenter.screen(declined, {}, NOW)["said"] == "The stray went on its way",
		"%s | %s | %s" % [sent, named, refused["error"]])
	s.close()


func _on_screen() -> void:
	var services: Services = App.services
	var screen: HatchScreen = await mount.call("hatch")
	screen.clock = func() -> int: return NOW
	await tree.process_frame
	services.store.dispatch(&"workshop_words", {"words": words()})
	services.store.dispatch(&"roster_loaded", {"view": born()})
	services.store.dispatch(&"roster_changed", {"home": born(),
		"what": {"do": "birth", "born": 9, "first": true, "outfit": "hatch-outfit"}})
	var find := func(key: String) -> Button:
		for b: Button in screen.find_children("*", "Button", true, false):
			if b.get_meta("key", "") == key or b.get_meta("item", "") == key:
				return b
		return null
	var words_on := screen.body.find_children("*", "Label", true, false).map(func(l: Label) -> String: return l.text)
	var drawn: bool = words_on.has("Nursery in Lantern Vale") and words_on.has("Lantern Wisp: 50%") \
		and words_on.has("A stray Hourkeeper, found on a heist") and words_on.has("Name: Quiet Lantern") \
		and words_on.has("A free outfit comes with your first hatch")
	(find.call("word:adjective") as Button).pressed.emit()
	await tree.process_frame
	var renamed: bool = screen.body.find_children("*", "Label", true, false).any(
		func(l: Label) -> bool: return l.text == "Name: Brave Lantern")
	(find.call("birth:outer-1") as Button).pressed.emit()
	await tree.process_frame
	var asked: Button = find.call("birth:outer-1")
	var confirming: bool = asked != null and asked.text == "Tap again to spend 135 Essence" \
		and services.store.get_slice(RosterState.ROSTER)["busy"] == ""
	screen.queue_free()
	check.call("the Hatch screen draws each Nursery, the strays and the newborn's card; a word changes with a tap, "
			+ "and a birth is spent on a second tap (23.2)",
		drawn and renamed and confirming, "%s %s %s | %s" % [drawn, renamed, confirming, words_on])


func _online() -> void:
	var name := "against the server: with no Nursery yet Hatch says to build one, and a ruleborn is named from "
	name += "the word lists, the Roster then calling it by its name (19.20, 23.2)"
	if server_url == "":
		check.call(name, false, "no server: run through client/status.py, which starts one")
		return
	var s := Fixtures.answered(Services.build(tree.root, server_url, null, "user://outbox-test-hatch.json"))
	s.router.change = func(_path: String) -> void: pass
	var me := await s.account.sign_in("test:hatch")
	if not me.ok:
		check.call(name, false, "sign-in refused: %s" % me.code)
		s.close()
		return
	await s.roster_flow.load_roster()
	await s.roster_flow.load_words()
	var w: Dictionary = s.store.get_slice(WorkshopState.WORKSHOP)["words"]
	var first: Dictionary = s.store.get_slice(RosterState.ROSTER)["view"]
	var none: String = HatchPresenter.screen(s.store.get_slice(RosterState.ROSTER), w, NOW).get("none", "")
	var id := int(first["characters"][0]["id"]) if not (first.get("characters", []) as Array).is_empty() else 0
	await s.roster_flow.name_character(id, 2, 3)
	var after: Dictionary = s.store.get_slice(RosterState.ROSTER)
	var called: String = str(RosterPresenter.screen(after, NOW, w).get("rows", [{}])[0].get("name", ""))
	check.call(name,
		none == Strings.t("HATCH_NO_NURSERY", UniversePresenter.building_name("nursery")) and after["error"] == ""
			and int(after["view"]["characters"][0]["name"]["adjective"]) == 2
			and int(after["view"]["characters"][0]["name"]["noun"]) == 3
			and called == SocialPresenter.word_name(w, 2, 3) and called != "",
		"%s | %s | %s" % [none, after["error"], called])
	s.close()
