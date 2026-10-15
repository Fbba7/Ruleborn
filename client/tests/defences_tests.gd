class_name DefencesTests
extends RefCounted
## The defence log (§13.2, §23.2; TD.66): its words headless, the flows
## through a FakeTransport, the screen as drawn, and the log against the
## server when one is named.

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


## A log as GET /v1/defences answers: a foiled raid, a partial one whose
## replay is gone, and a loud one the server offers to Trace.
static func sample() -> Dictionary:
	return {"season": {"held": 1, "leaked": 2, "partial": 1}, "unseen": 1, "trace_hours": 24, "raids": [
		{"heist": "h3", "island": "b1", "at": 3, "raider": {"keeper_level": 8}, "grade": "foiled", "held": true,
			"denied": 1840, "held_seconds": 95, "caught": 3, "crew": 3, "defence": {"total": 92},
			"replay": "kept", "trace": null, "new": true},
		{"heist": "h2", "island": "b1", "at": 2, "raider": {"keeper_level": 6}, "grade": "partial", "held": false,
			"denied": 900, "held_seconds": 61, "caught": 1, "crew": 3, "defence": null,
			"replay": "gone", "trace": null, "new": false},
		{"heist": "h1", "island": "b1", "at": 1, "raider": {"keeper_level": 7}, "grade": "loud", "held": false,
			"denied": null, "held_seconds": null, "caught": 0, "crew": 3, "defence": null,
			"replay": "kept", "trace": {"bundle": "r1"}, "new": false}]}


func _words() -> void:
	var d := DefencesPresenter.screen({"view": sample(), "busy": "", "error": ""})
	var raids: Array = d["raids"]
	check.call("the defence log counts the season's raids held and leaked, Partial apart, and names each raid held "
			+ "when foiled and leaked otherwise, with its grade (12.9, 13.2, G69)",
		d["header"] == "This season: held 1, leaked 2 (1 partial)" and raids[0]["lines"][0] == "Held (Foiled)"
			and raids[1]["lines"][0] == "Leaked (Partial)" and raids[2]["lines"][0] == "Leaked (Loud)"
			and raids[0]["title"] == "A Keeper of level 8" and raids[0]["new"] and not raids[1]["new"],
		"%s | %s" % [d.get("header"), raids.map(func(r: Dictionary) -> String: return r["lines"][0])])
	check.call("each raid's report gives the haul denied, how long the defence held, who was caught and the share "
			+ "earned, and says when the server did not record a fact (13.2, 9.4)",
		raids[0]["lines"] == ["Held (Foiled)", "Haul denied: 1,840", "The defence held 1:35", "Crew caught: 3",
			"Where the crew was seen and what fired: not recorded for this raid", "Defence share earned: 92"]
			and raids[2]["lines"].slice(1, 3) == ["Haul denied: not recorded", "How long it held: not recorded"],
		"%s | %s" % [raids[0]["lines"], raids[2]["lines"]])
	var rep := {"side": 12, "landing": {"x": 0, "y": 6},
		"seen": [{"crew": 1, "x": 4, "y": 5}, {"crew": 0, "x": 7, "y": 7}],
		"fired": [{"ward": "static_coil", "x": 6, "y": 6, "times": 2}], "bells": 1, "alarm": 3,
		"caught_by": [{"row": 0, "x": 4, "y": 4}, {"row": null, "x": 11, "y": 11}]}
	var quiet := {"side": 10, "landing": {"x": 3, "y": 0}, "seen": [], "fired": [], "bells": 0, "alarm": 0,
		"caught_by": []}
	check.call("a raid's report says from the event log where the crew landed, each place a guard was alerted to it, "
			+ "each ward that fired and how often, the bells, how high the alarm climbed and whose guards caught "
			+ "anyone (13.2, TD.39)",
		DefencesPresenter.report(rep) == ["Landed: West edge, 7 of 12", "A guard was alerted to the crew at 5, 6; at 8, 8",
			"Wards fired: Static Coil at 7, 7 ×2", "Bells rung: 1", "The realm alarm reached level 3",
			"Caught by the %s post at 5, 5" % Strings.term("ROLE", "Scout"),
			"Caught by the Warden who came at alarm level 5"]
			and DefencesPresenter.report(quiet) == ["Landed: North edge, 4 of 10", "No guard was ever alerted to the crew"],
		"%s | %s" % [DefencesPresenter.report(rep), DefencesPresenter.report(quiet)])
	var isl := RulebornIsland.new()
	isl.reset(3)
	isl.set_ground(2, 1, "tall_grass")
	isl.place_ward("static_coil", 6, 6)
	isl.post_guard(0, 2, 2)
	var placed := {"side": 12, "landing": {"x": 0, "y": 6}, "fired": [], "bells": 0, "alarm": 0, "caught_by": [],
		"seen": [{"crew": 0, "x": 2, "y": 2}, {"crew": 1, "x": 6, "y": 8}, {"crew": 2, "x": 6, "y": 5}]}
	var near := DefencesPresenter.report(placed, isl.bytes())
	check.call("with the island it was played on, the report names each place a guard was alerted to the crew by its "
			+ "nearest building or feature, a guard post being none (13.2)",
		near[1] == "A guard was alerted to the crew near the Tall grass at 3, 3; near the %s at 7, 9; " \
			% UniversePresenter.building_name("vault") + "near the Static Coil at 7, 6"
			and DefencesPresenter.report(placed)[1].begins_with("A guard was alerted to the crew at 3, 3"),
		"%s" % [near])
	check.call("a raid offers Watch replay while the replay is kept and says when it is gone, and Trace only where "
			+ "the server offers it (12.3, 13, 24.3)",
		not (raids[0]["watch"] as Dictionary).is_empty() and (raids[1]["watch"] as Dictionary).is_empty()
			and "The replay is no longer kept" in raids[1]["lines"] and (raids[0]["trace"] as Dictionary).is_empty()
			and raids[2]["trace"]["action"] == "Trace · no fee"
			and DefencesPresenter.screen({"view": {"raids": [], "season": {}}})["empty"]
				== "No raids on your universe this season",
		"%s %s" % [raids[1]["watch"], raids[2]["trace"]])


func _flows() -> void:
	var transport := FakeTransport.new()
	var s := Fixtures.answered(Services.build(tree.root, "https://edge.example", transport,
		"user://outbox-defences-test.json"))
	s.api.token = "t"
	var routes: Array[StringName] = []
	s.router.change = func(path: String) -> void: routes.append(StringName(path.get_file().get_basename()))
	transport.on("GET /v1/defences/badge", {"unseen": 2})
	await s.defences_flow.load_badge()
	var badge := int(s.store.get_slice(DefencesState.DEFENCES)["unseen"])
	var before := DefencesPresenter.place(badge)
	transport.on("GET /v1/defences", sample())
	await s.defences_flow.load_log()
	var after := int(s.store.get_slice(DefencesState.DEFENCES)["unseen"])
	check.call("the home names new raids on the log's button, and reading the log clears the raid badge (TD.66)",
		badge == 2 and before == "Defence log · 2 new" and after == 0 and DefencesPresenter.place(after) == "Defence log",
		"%d %s %d" % [badge, before, after])
	var golden := FileAccess.get_file_as_bytes("res://goldens/%s.rbh" % ReplayScreen.find_goldens()[0])
	transport.on("GET /v1/heists/h3/replay", golden)
	transport.on("GET /v1/bundles/b1", PackedByteArray([7, 7]))
	var raids: Array = sample()["raids"]
	await s.defences_flow.watch(raids[0])
	var watching: Dictionary = s.store.get_slice(DefencesState.DEFENCES)["watching"]
	s.defences_flow.trace(raids[2])
	var heist: Dictionary = s.store.get_slice(AppState.HEIST)
	check.call("Watch replay fetches the raid's replay and the island it was played on and opens the replay; Trace "
			+ "leases the raider's island as a Trace (12.3, 13)",
		watching.get("replay") == golden and watching.get("island") == PackedByteArray([7, 7])
			and &"replay_screen" in routes and heist["target"] == {"bundle": "r1", "trace": true}
			and &"heist_screen" in routes,
		"%s %s" % [routes, heist["target"]])
	var isl := RulebornIsland.new()
	isl.reset(3)
	isl.set_ground(2, 1, "tall_grass")
	var reported := sample()
	reported["raids"][0]["island"] = "b9"
	reported["raids"][0]["report"] = {"side": 12, "landing": {"x": 0, "y": 6}, "fired": [], "bells": 0,
		"alarm": 0, "caught_by": [], "seen": [{"crew": 0, "x": 2, "y": 2}]}
	transport.on("GET /v1/defences", reported)
	transport.on("GET /v1/bundles/b9", isl.bytes())
	await s.defences_flow.load_log()
	var shown: Array = DefencesPresenter.screen(s.store.get_slice(DefencesState.DEFENCES))["raids"][0]["lines"]
	var fetched := transport.calls.filter(func(c: Dictionary) -> bool: return c["route"] == "GET /v1/bundles/b9")
	check.call("the log fetches each reported raid's island once, by its bundle, and its report names the places "
			+ "on it (13.2, 24.8)",
		fetched.size() == 1 and "A guard was alerted to the crew near the Tall grass at 3, 3" in shown,
		"%s %s" % [fetched.size(), shown])
	s.close()


func _on_screen() -> void:
	var services: Services = App.services
	var screen: DefencesScreen = await mount.call("defences")
	for i in 5:
		await tree.process_frame
	services.store.dispatch(&"defences_loaded", {"view": sample()})
	var heists := screen.body.find_children("*", "Label", true, false).filter(
		func(l: Label) -> bool: return l.has_meta("heist")).map(func(l: Label) -> String: return l.get_meta("heist"))
	var keys := screen.find_children("*", "Button", true, false).map(
		func(b: Button) -> String: return str(b.get_meta("key", ""))).filter(func(k: String) -> bool: return k != "")
	screen.queue_free()
	await tree.process_frame
	check.call("the defence log screen draws the season's raids newest first, each with its Watch replay and Trace "
			+ "where it has them (13.2, 23.2)",
		heists == ["h3", "h2", "h1"] and keys == ["watch:h3", "watch:h1", "trace:h1"],
		"%s %s" % [heists, keys])
	# The replay screen opens a watched raid first, on the island it names.
	var golden := FileAccess.get_file_as_bytes("res://goldens/%s.rbh" % ReplayScreen.find_goldens()[0])
	services.store.dispatch(&"defences_watching", {"replay": golden, "island": PackedByteArray()})
	var replay: ReplayScreen = await mount.call("replay_screen")
	var first: String = replay.entries[0][0]
	var loaded := replay.replay.ticks() > 0
	replay.queue_free()
	services.store.dispatch(&"defences_watching", {})
	await tree.process_frame
	check.call("the replay screen plays a watched raid first (13)",
		first == Strings.t("REPLAY_RAID") and loaded, "%s %s" % [first, loaded])


func _online() -> void:
	var name := "against the server: a new Keeper's defence log holds no raids, a season of none held or leaked, "
	name += "and no raid badge (13.2)"
	if server_url == "":
		check.call(name, false, "no server: run through client/status.py, which starts one")
		return
	var s := Fixtures.answered(Services.build(tree.root, server_url, null, "user://outbox-test-defences.json"))
	s.router.change = func(_path: String) -> void: pass
	var me := await s.account.sign_in("test:defences")
	if not me.ok:
		check.call(name, false, "sign-in refused: %s" % me.code)
		s.close()
		return
	await s.defences_flow.load_badge()
	await s.defences_flow.load_log()
	var slice: Dictionary = s.store.get_slice(DefencesState.DEFENCES)
	var v: Dictionary = slice["view"]
	check.call(name,
		(v.get("raids", [1]) as Array).is_empty()
			and ["held", "leaked", "partial"].all(func(k: String) -> bool: return int(v["season"][k]) == 0)
			and int(slice["unseen"]) == 0 and slice["error"] == "",
		"%s %s" % [v, slice["error"]])
	s.close()
