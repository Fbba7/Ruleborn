class_name UniverseTests
extends RefCounted
## The universe screen (§5.2, §10.2): its reducers and words headless, its
## purchases through a FakeTransport, the screen's two taps, and the routes
## against the server when one is named.

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
	_reducers()
	_words()
	await _flows()
	await _offline()
	await _on_screen()
	await _online()


## A universe as the server answers GET /v1/universe: the start, 4,650
## Starlight, a ward built and room for more.
static func sample(starlight := 4650) -> Dictionary:
	var no := {"cost": 1720, "needs": {"keeper": 0, "spire": 2}, "blocked": "spire_level"}
	return {"keeper": 3, "spire": 1, "starlight": starlight, "realms": [
		{"realm": "heart", "type": "Heart", "level": 3, "raise": null,
			"buildings": [
				{"kind": "vault", "name": "Vault", "n": 1, "level": 1, "top": 10, "next": no},
				{"kind": "ward", "name": "Ward", "n": 1, "level": 5, "top": 5, "next": null},
				{"kind": "hearth", "name": "Hearth", "n": 1, "level": 1, "top": 5,
					"next": {"cost": 1820, "needs": {"keeper": 0, "spire": 3}, "blocked": "spire_level"}}],
			"room": [
				{"kind": "ward", "name": "Ward", "n": 2, "cost": 350, "needs": {"keeper": 0, "spire": 1}, "blocked": null},
				{"kind": "library", "name": "Library", "n": 1, "cost": 900, "needs": {"keeper": 4, "spire": 0},
					"blocked": "keeper_level"}]},
		{"realm": "outer-1", "type": "Lantern Vale", "level": 1, "buildings": [], "room": [],
			"raise": {"cost": 6000, "needs": {"keeper": 0, "spire": 3}, "blocked": "spire_level"}}],
		"open": {"realm": "outer-2", "types": ["Skyfield", "Verdant"], "cost": 2000,
			"needs": {"keeper": 6, "spire": 1}, "blocked": "keeper_level"}}


func _reducers() -> void:
	var store := Store.new()
	UniverseState.register(store)
	store.dispatch(&"universe_loaded", {"view": sample()})
	store.dispatch(&"purchase_asked", {"key": "build:heart:ward:2:1"})
	var asked: Dictionary = store.get_slice(UniverseState.UNIVERSE)
	store.dispatch(&"universe_failed", {"code": "not_enough_starlight", "detail": {"cost": 350}})
	var failed: Dictionary = store.get_slice(UniverseState.UNIVERSE)
	store.dispatch(&"purchase_made", {"universe": sample(4300), "what": {"kind": "ward", "n": 2, "to": 1},
		"keeper": {"gained": 8, "level": 3}})
	var made: Dictionary = store.get_slice(UniverseState.UNIVERSE)
	check.call("the universe reducers mark the purchase on its way, keep the universe on show when one fails, "
			+ "and take the server's universe and what it bought when one is made (5.2, 10.2)",
		asked["busy"] == "build:heart:ward:2:1" and failed["busy"] == "" and failed["view"]["starlight"] == 4650
			and failed["error"] == "not_enough_starlight" and made["view"]["starlight"] == 4300
			and made["error"] == "" and made["last"]["keeper"]["gained"] == 8 and not made["last"]["repeated"],
		"%s | %s | %s" % [asked, failed, made])
	# A view fetched before a purchase's answer is not put back over it, and a
	# fetch clears the last purchase's words.
	store.dispatch(&"universe_asked")
	var fetching: Dictionary = store.get_slice(UniverseState.UNIVERSE)
	store.dispatch(&"universe_loaded", {"view": sample(9999), "purchases": 0})
	var stale: Dictionary = store.get_slice(UniverseState.UNIVERSE)
	store.dispatch(&"universe_loaded", {"view": sample(4200), "purchases": 1})
	var fresh: Dictionary = store.get_slice(UniverseState.UNIVERSE)
	check.call("a universe fetched before a purchase was answered never replaces the universe that purchase "
			+ "answered with, and a fetch clears the last purchase's words (10.2)",
		fetching["last"].is_empty() and fetching["busy"] == "view" and stale["view"]["starlight"] == 4300
			and stale["busy"] == "" and fresh["view"]["starlight"] == 4200,
		"%s | %s | %s" % [fetching, stale, fresh])


func _words() -> void:
	var u := UniversePresenter.screen({"view": sample(), "busy": "", "error": "", "last": {}})
	var heart: Dictionary = u["realms"][0]
	var vault: Dictionary = heart["rows"][0]
	var ward: Dictionary = heart["rows"][1]
	var room_ward: Dictionary = heart["room"][0]
	var library: Dictionary = heart["room"][1]
	var outer: Dictionary = u["realms"][1]
	Strings.set_locale("pt_BR")
	var pt := UniversePresenter.screen({"view": sample(12345), "busy": "", "error": "", "last": {}})
	Strings.set_locale("en")
	check.call("the universe says each realm, each building's level and its next level's price, and why a price "
			+ "cannot be paid yet in words; a kind with more than one place is numbered; the next realm offers "
			+ "each type still unowned (5.2, 10.2, 20.8)",
		u["header"] == "4,650 Starlight · Spire 1 · Keeper 3" and heart["title"].contains("3")
			and vault["text"] == "Vault, level 1 of 10" and vault["action"] == "Raise to level 2, 1,720 Starlight"
			and not vault["can"] and vault["why"] == "Needs the Spire at level 2"
			and vault["spoken"].contains("Needs the Spire at level 2") and vault["key"] == "build:heart:vault:1:2"
			and ward["text"].begins_with("Ward 1, level 5 of 5") and ward["key"] == ""
			and room_ward["action"] == "Build: Ward 2, 350 Starlight" and room_ward["can"]
			and room_ward["args"] == {"realm": "heart", "kind": "ward", "n": 2, "to": 1}
			and library["why"] == "Needs Keeper 4" and outer["title"] == "Lantern Vale, realm level 1"
			and outer["raise"]["key"] == "raise:outer-1:2" and outer["raise"]["action"].begins_with("Raise the realm")
			and u["open"]["rows"].size() == 2 and u["open"]["rows"][1]["action"] == "Open Verdant, 2,000 Starlight"
			and u["open"]["rows"][1]["why"] == "Needs Keeper 6" and pt["header"].begins_with("12.345"),
		"%s" % [u])
	var built_ward: Dictionary = UniversePresenter.building("heart",
		{"kind": "ward", "name": "Ward", "n": 2, "level": 1, "top": 5,
			"next": {"cost": 880, "needs": {"keeper": 0, "spire": 3}, "blocked": "spire_level"}}, true)
	check.call("a purchase's button keeps its item when bought, so focus returns to the same building, and "
			+ "its spoken words name what is bought",
		room_ward["item"] == "build:heart:ward:2" and built_ward["item"] == room_ward["item"]
			and outer["raise"]["item"] == "raise:outer-1" and u["open"]["rows"][0]["item"] == "open"
			and vault["spoken"].begins_with("Vault, level 1 of 10"),
		"%s | %s" % [room_ward, built_ward])
	var bought := UniversePresenter.said({"what": {"kind": "ward", "n": 2, "to": 1},
		"keeper": {"gained": 8, "level": 3, "levelled": 0}, "repeated": false})
	var opened := UniversePresenter.said({"what": {"realm": "Verdant"}, "keeper": null, "repeated": true})
	var refused := UniversePresenter.screen({"view": sample(), "busy": "", "error": "needs_keeper_level",
		"detail": {"needs": 6}, "last": {}})
	check.call("a purchase says what it bought and the Keeper experience it earned (14.2); a refusal says what "
			+ "it needed",
		bought == "Ward, level 1\n" + Strings.t("RESULT_KEEPER", "8") and opened == "Verdant is open"
			and refused["error"] == "Needs Keeper 6",
		"%s | %s | %s" % [bought, opened, refused["error"]])


func _flows() -> void:
	var transport := FakeTransport.new()
	var s := Fixtures.answered(Services.build(tree.root, "https://edge.example", transport,
		"user://outbox-universe-test.json"))
	s.api.token = "t"
	transport.on("GET /v1/universe", sample())
	await s.universe_flow.load_universe()
	s.store.dispatch(&"keeper_loaded", {"view": {"level": 3, "xp": 10, "toNext": 270, "cap": 40}})
	transport.on("POST /v1/universe/buildings", {"universe": sample(4300),
		"keeper": {"gained": 8, "level": 3, "xp": 18, "toNext": 270, "levelled": 0}})
	await s.universe_flow.build("heart", "ward", 2, 1)
	var sent: Dictionary = JSON.parse_string((transport.calls[-1]["body"] as PackedByteArray).get_string_from_utf8())
	var made: Dictionary = s.store.get_slice(UniverseState.UNIVERSE)
	var keeper: Dictionary = s.store.get_slice(KeeperState.KEEPER)
	transport.on("POST /v1/universe/realms/outer-1/level", {"error": "needs_spire_level", "needs": 3}, 409)
	await s.universe_flow.raise_realm("outer-1", 2)
	var refused: Dictionary = s.store.get_slice(UniverseState.UNIVERSE)
	# One purchase at a time: a tap while one is on its way asks nothing, and
	# neither does a fetch, whose answer could undo the purchase's.
	var asked := transport.calls.size()
	s.store.dispatch(&"purchase_asked", {"key": "open:Verdant"})
	await s.universe_flow.open_realm("Verdant")
	await s.universe_flow.load_universe()
	check.call("a purchase sends the level it leads to, shows the universe the server answers, and moves the "
			+ "Keeper bar with what it earned; a refusal keeps the universe on show and says what it needed; "
			+ "a second purchase waits for the first (10.2, 14.2, 24.12)",
		transport.calls[1]["route"] == "POST /v1/universe/buildings"
			and sent["realm"] == "heart" and sent["kind"] == "ward" and int(sent["n"]) == 2 and int(sent["to"]) == 1
			and (transport.calls[1]["body"] as PackedByteArray).get_string_from_utf8().contains('"n":2,')
			and made["view"]["starlight"] == 4300 and keeper["view"]["xp"] == 18
			and refused["error"] == "needs_spire_level" and refused["view"]["starlight"] == 4300
			and UniversePresenter.screen(refused)["error"] == "Needs the Spire at level 3"
			and transport.calls.size() == asked,
		"%s | %s | %s | %s" % [sent, made, keeper, refused])
	s.close()


## §24: "The device may build … offline, confirmed on reconnection". A build
## the network does not reach waits in the outbox, shown as confirming; when
## the outbox is sent, the server confirms one and refuses another, and the
## screen says which, and why.
func _offline() -> void:
	var path := "user://outbox-universe-offline-test.json"
	DirAccess.remove_absolute(path)
	var transport := FakeTransport.new()
	var s := Fixtures.answered(Services.build(tree.root, "https://edge.example", transport, path))
	s.api.token = "t"
	transport.on("GET /v1/universe", sample())
	await s.universe_flow.load_universe()
	transport.offline = true
	await s.universe_flow.build("heart", "ward", 2, 1)
	await s.universe_flow.build("heart", "library", 1, 1)
	var waiting: Dictionary = s.store.get_slice(UniverseState.UNIVERSE)
	var shown := UniversePresenter.screen(waiting)
	var kept := s.outbox.pending()
	transport.offline = false
	transport.then("POST /v1/offline", [
		[{"results": [{"confirmed": true, "keeper": {"gained": 8, "level": 3, "xp": 18, "toNext": 270, "levelled": 0}}],
			"universe": sample(4300), "home": {}}, 200],
		[{"results": [{"refused": "needs_keeper_level", "detail": {"needs": 4}}], "universe": sample(4300),
			"home": {}}, 200]])
	await s.outbox.flush(s.api)
	var after: Dictionary = s.store.get_slice(UniverseState.UNIVERSE)
	var sent: Array = transport.calls.filter(func(c: Dictionary) -> bool: return c["route"] == "POST /v1/offline")
	var first: Dictionary = JSON.parse_string((sent[0]["body"] as PackedByteArray).get_string_from_utf8()) \
		if not sent.is_empty() else {}
	var action: Dictionary = (first.get("actions", [{}]) as Array)[0]
	var refused_line := str(UniversePresenter.screen(after)["refused"])
	check.call("a build the network does not reach waits in the outbox, shown as confirming; sent on reconnection, "
			+ "each is confirmed or refused by the server, and the screen says which and why (24)",
		kept == 2 and (waiting["confirming"] as Dictionary).size() == 2 and waiting["busy"] == ""
			and shown["confirming"] == Strings.t("UNIVERSE_CONFIRMING", 2)
			and sent.size() == 2 and action.get("do") == "build" and action.get("kind") == "ward"
			and int(action.get("n", 0)) == 2 and int(action.get("to", 0)) == 1
			and s.outbox.pending() == 0 and (after["confirming"] as Dictionary).is_empty()
			and int(after["view"]["starlight"]) == 4300
			and refused_line == Strings.t("UNIVERSE_OFFLINE_REFUSED",
				[UniversePresenter.building_name("library"), Strings.t("UNIVERSE_NEEDS_KEEPER", 4)]),
		"%s | %s | %s | %s" % [kept, waiting["confirming"], after, refused_line])
	s.close()
	DirAccess.remove_absolute(path)


## The screen as drawn: a blocked purchase says why beside its button; the
## first tap on one that can be bought asks to confirm, and only the second
## buys.
func _on_screen() -> void:
	var services: Services = App.services
	var screen: UniverseScreen = await mount.call("universe")
	await tree.process_frame
	services.store.dispatch(&"universe_loaded", {"view": sample()})
	var button := func(key: String) -> Button:
		for b: Button in screen.find_children("*", "Button", true, false):
			if b.get_meta("key", "") == key:
				return b
		return null
	var vault: Button = button.call("build:heart:vault:1:2")
	var ward: Button = button.call("build:heart:ward:2:1")
	var blocked := vault != null and vault.disabled and screen.body.find_children("*", "Label", true, false).any(
		func(l: Label) -> bool: return l.text == "Needs the Spire at level 2")
	var before := ward.text
	ward.pressed.emit()
	await tree.process_frame
	var asked: Button = button.call("build:heart:ward:2:1")
	var confirming: bool = asked.text == Strings.t("UNIVERSE_CONFIRM", "350") \
		and asked.accessibility_name.begins_with("Build: Ward 2") \
		and services.store.get_slice(UniverseState.UNIVERSE)["busy"] == ""
	asked.pressed.emit()
	for i in 5:
		await tree.process_frame
	# Offline here: the purchase was asked for, and waits in the outbox to be
	# confirmed (§24), which the screen says.
	var tried: Dictionary = services.store.get_slice(UniverseState.UNIVERSE)
	var shown := screen.status_label.text
	screen.queue_free()
	var kept := services.outbox.has(UniverseController.OFFLINE + "build:heart:ward:2:1")
	services.outbox.drop(UniverseController.OFFLINE + "build:heart:ward:2:1")
	check.call("the universe screen shows why a purchase waits beside its button; the first tap on one asks to "
			+ "spend the Starlight, and the second buys (5.2, 10.2, 20.8)",
		blocked and before.begins_with("Build: Ward 2") and confirming and kept
			and (tried["confirming"] as Dictionary).has("build:heart:ward:2:1")
			and shown.contains(Strings.t("UNIVERSE_CONFIRMING", 1)),
		"%s %s %s | %s | %s" % [blocked, before, confirming, tried, shown])


func _online() -> void:
	var name := "against the server: a new universe is the Heart and its start, and a purchase with no "
	name += "Starlight is refused in words (5.2, 10.2, F56)"
	if server_url == "":
		check.call(name, false, "no server: run through client/status.py, which starts one")
		return
	var s := Fixtures.answered(Services.build(tree.root, server_url, null, "user://outbox-test-universe.json"))
	s.router.change = func(_path: String) -> void: pass
	var me := await s.account.sign_in("test:universe")
	if not me.ok:
		check.call(name, false, "sign-in refused: %s" % me.code)
		s.close()
		return
	await s.universe_flow.load_universe()
	var loaded: Dictionary = s.store.get_slice(UniverseState.UNIVERSE)
	await s.universe_flow.build("heart", "ward", 1, 1)
	var after: Dictionary = s.store.get_slice(UniverseState.UNIVERSE)
	var kinds: Array = []
	if not loaded["view"].is_empty():
		for b: Dictionary in loaded["view"]["realms"][0]["buildings"]:
			kinds.append(b["kind"])
	kinds.sort()
	check.call(name,
		loaded["error"] == "" and kinds == ["aether_spring", "garden", "hearth", "keeper_s_spire", "star_well", "vault"]
			and after["error"] == "not_enough_starlight"
			and UniversePresenter.screen(after)["error"] == Errors.message("UNIVERSE_FAILED", "not_enough_starlight"),
		"%s | %s" % [loaded, after])
	s.close()
