class_name PlannerTests
extends RefCounted
## The heist planner (§12.5, §23.2; TD.18): its words headless, the plan as
## the crew manifest the replay carries, the flows from the scout report to
## the heist, the screen as drawn, and the planner against the server when
## one is named.

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
	_manifest()
	await _flows()
	await _on_screen()
	await _online()


static func _member(id: int, kind: String, level: int, wire: Dictionary, resting := false) -> Dictionary:
	return {"id": id, "kind": kind, "level": level, "traits": [], "state": "resting" if resting else "idle",
		"wire": wire, "name": null}


## The slices the planner reads: a Keeper of level 1, four characters (one
## resting), two Sages, three restored laws, and a player's target card.
static func slices() -> Dictionary:
	var card := ObservatoryTests._card("p1", "player", {"clock": 150})
	return {
		"planner": {"target": card, "crew": [], "sage": "", "casts": [], "load": 100},
		"keeper": {"view": {"level": 1, "plan": {"crew": 3, "casts": 1, "sage": false, "load": [50, 100, 10]}}},
		"roster": {"view": {"characters": [
			_member(1, "featherkin", 2, {"kind": 0, "form": 1, "level": 2, "traits": [4]}),
			_member(2, "emberling", 1, {"kind": 7, "form": 0, "level": 1, "traits": []}),
			_member(3, "tidewalker", 1, {"kind": 12, "form": 0, "level": 1, "traits": [1, 9]}),
			_member(4, "rambler", 1, {"kind": 2, "form": 0, "level": 1, "traits": []}, true)]}},
		"sages": {"view": {"sages": [
			{"id": "the_archivist", "unlocks_at": 1, "unlocked": true, "guardian": false},
			{"id": "the_tinkerer", "unlocks_at": 7, "unlocked": false, "guardian": false}]}},
		"codex": {"view": {"laws": [{"law": "bloom", "tier": 1}, {"law": "slow_rivers", "tier": 1},
			{"law": "half_gravity", "tier": 1}, {"law": "glass", "tier": 0}], "albums": []}},
		"observatory": {"view": {"protected": true}},
	}


static func drawn(s: Dictionary) -> Dictionary:
	return PlannerPresenter.screen(s["planner"], s["keeper"], s["roster"], s["sages"], s["codex"], s["observatory"])


func _words() -> void:
	var s := slices()
	var p := drawn(s)
	var crew: Array = p["crew"]
	check.call("the planner shows the target's clock and laws, flags those the Codex has not met, and says the entry "
			+ "is chosen on landing (5.4, 12.5, 23.2)",
		p["clock"] == "Heist clock 2:30" and p["laws"]["line"] == "Laws: Brittle stone, Glass"
			and p["laws"]["unfamiliar"] == "Unfamiliar: Brittle stone" and p["entry"].begins_with("Entry: "),
		"%s | %s" % [p["laws"], p["clock"]])
	var across := slices()
	across["planner"]["target"].merge({"across": true, "clock": 165, "clock_longest": 180, "depth": 2,
		"fault_realms": ["outer-2"]}, true)
	var u := drawn(across)
	check.call("across a universe the planner says the entry is any outer realm's edge or a fault, the route realm by "
			+ "realm to the Heart and out, where the faults open, and the clock by the realm landed in "
			+ "(5.4, 12.5, 23.2, T3.3)",
		u["entry"] == "Entry: you choose an outer realm's edge spot, or a fault, as the crew lands"
			and u["route"] == "Route: realm by realm to the Heart, up to 2 realms, then out by skiff from wherever "
				+ "the crew stands"
			and u["faults"] == "Faults open from outer realm 2"
			and u["clock"] == "Heist clock 2:45 to 3:00, by the realm you land in"
			and p["route"] == "" and p["faults"] == "",
		"%s | %s | %s | %s" % [u["entry"], u["route"], u["faults"], u["clock"]])
	s["planner"]["crew"] = [1, 2, 3]
	var full := drawn(s)
	check.call("the crew is 3 to the Keeper's most, a resting character unavailable, and Start waits until 3 are "
			+ "chosen (11.6, 12.5)",
		p["crew_count"] == "Crew: 0 of 3" and not crew[3]["can"] and crew[3]["why"] == "resting"
			and not p["start"]["can"] and p["start"]["why"] == "choose 3 to 3 crew"
			and full["start"]["can"] and full["crew"][0]["picked"] and full["crew"][0]["action"].begins_with("● ")
			and full["crew"][3]["why"] == "resting",
		"%s | %s" % [crew.map(func(c: Dictionary) -> String: return c["why"]), full["start"]])
	var sages: Array = p["sages"]
	s["keeper"]["view"]["plan"] = {"crew": 4, "casts": 1, "sage": true, "load": [50, 100, 10]}
	s["sages"]["view"]["sages"][0]["guardian"] = true
	var later := drawn(s)
	check.call("a Sage goes from Keeper level 2, never one not yet unlocked or the one guarding the Heart; casts "
			+ "fill the Keeper's slots from restored laws (11.7, 12.5)",
		sages[0]["action"] == "● No Sage" and not sages[1]["can"] and sages[1]["why"] == "a Sage joins from Keeper level 2"
			and not later["sages"][1]["can"] and later["sages"][1]["why"] == "guarding the Heart"
			and later["sages"][2]["why"] == "Unlocks at Keeper level 7"
			and (p["casts"] as Array).map(func(c: Dictionary) -> String: return c["law"])
				== ["bloom", "slow_rivers", "half_gravity"]
			and p["casts_count"] == "Casts: 0 of 1, paid only if used",
		"%s | %s" % [sages.map(func(o: Dictionary) -> String: return o["why"]), later["sages"][2]])
	check.call("the load target steps from 50 to 100% in tens, and a protected Keeper's Start says raiding a player "
			+ "ends it (12.3, 12.5)",
		p["load"] == "Load target: 100%" and p["load_down"] and not p["load_up"]
			and p["protected"] == "You are protected as a new Keeper; raiding a player ends that",
		"%s %s" % [p["load"], p["protected"]])


func _manifest() -> void:
	var s := slices()
	s["planner"]["crew"] = [3, 1, 2]
	s["planner"]["sage"] = "the_archivist"
	s["planner"]["casts"] = ["bloom"]
	s["planner"]["load"] = 70
	var plan: Dictionary = drawn(s)["plan"]
	var bloom := RulebornStability.law_ids().find("bloom")
	var want := PackedByteArray([12, 0, 1, 2, 1, 9, 0, 1, 2, 1, 4, 7, 0, 1, 0, 1, 1, bloom])
	check.call("the plan is the replay's crew manifest: each member's kind, form, level and traits in portrait order, "
			+ "the Sage and the casts, with the crew's ids and the load target (12.5, TD.34)",
		plan["manifest"] == want and plan["crew"] == [3, 1, 2] and plan["load"] == 70,
		"%s %s" % [plan["manifest"], plan["crew"]])
	# The heist begins on it: an RBH3 replay carrying that crew.
	var c := HeistController.new()
	var began := c.begin("42", 600, 3, LandingTests.island(false), "", want)
	var replay := c.record()
	var wrong := HeistController.new().begin("42", 600, 4, LandingTests.island(false), "", want)
	check.call("a heist begun on the plan records a replay carrying its manifest, and one that does not fit its crew "
			+ "is refused (12.5, 24.11)",
		began and replay.slice(0, 4).get_string_from_ascii() == "RBH3" and not wrong,
		"%s %s %s" % [began, replay.slice(0, 4), wrong])


func _flows() -> void:
	var transport := FakeTransport.new()
	var s := Fixtures.answered(Services.build(tree.root, "https://edge.example", transport,
		"user://outbox-planner-test.json"))
	s.api.token = "t"
	var routes: Array[StringName] = []
	s.router.change = func(path: String) -> void: routes.append(StringName(path.get_file().get_basename()))
	var d := slices()
	s.store.dispatch(&"keeper_loaded", {"view": d["keeper"]["view"]})
	s.store.dispatch(&"roster_loaded", {"view": d["roster"]["view"]})
	s.store.dispatch(&"sages_loaded", {"view": d["sages"]["view"]})
	s.store.dispatch(&"codex_loaded", {"view": d["codex"]["view"], "changes": 0})
	s.observatory_flow.raid(d["planner"]["target"])
	for id: int in [1, 2, 4, 3]:            # 4 rests, and cannot join
		s.planner_flow.toggle(id)
	s.planner_flow.step_load(-1)
	s.planner_flow.step_load(-1)
	s.planner_flow.start()
	var heist: Dictionary = s.store.get_slice(AppState.HEIST)
	var plan: Dictionary = heist.get("plan", {})
	transport.on("POST /v1/heists/tok", {"validated": true})
	await s.heists.submit("tok", PackedByteArray([1, 2]), plan.get("crew", []))
	var url := str(transport.calls[-1]["url"])
	check.call("the scout report's Plan opens the planner on its target, where a resting character cannot join; Start "
			+ "carries the crew, Sage, casts and load target into the heist, which names its crew to the server "
			+ "(12.5, TD.34)",
		&"planner" in routes and &"heist_screen" in routes
			and heist["target"] == {"bundle": "p1", "trace": false, "across": false}
			and plan.get("crew") == [1, 2, 3] and int(plan.get("load", 0)) == 80 and url.ends_with("?crew=1,2,3"),
		"%s %s %s" % [routes, plan.get("crew"), url])
	s.close()


func _on_screen() -> void:
	var services: Services = App.services
	var d := slices()
	services.store.dispatch(&"keeper_loaded", {"view": d["keeper"]["view"]})
	services.store.dispatch(&"roster_loaded", {"view": d["roster"]["view"]})
	services.store.dispatch(&"sages_loaded", {"view": d["sages"]["view"]})
	services.store.dispatch(&"codex_loaded", {"view": d["codex"]["view"], "changes": 0})
	services.store.dispatch(&"planner_opened", {"card": d["planner"]["target"]})
	var screen: PlannerScreen = await mount.call("planner")
	await tree.process_frame
	var find := func(key: String) -> Button:
		for b: Button in screen.find_children("*", "Button", true, false):
			if b.get_meta("key", "") == key:
				return b
		return null
	var resting: Button = find.call("crew:4")
	var waits := resting != null and resting.disabled
	(find.call("crew:1") as Button).pressed.emit()
	await tree.process_frame
	var picked := (find.call("crew:1") as Button).text.begins_with("● ")
	var start: Button = find.call("start")
	var blocked := start != null and start.disabled
	screen.queue_free()
	await tree.process_frame
	check.call("the planner screen draws the crew with resting characters unavailable, a tap adds a member, and Start "
			+ "waits for a full crew (12.5, 23.2)",
		waits and picked and blocked, "%s %s %s" % [waits, picked, blocked])


func _online() -> void:
	var name := "against the server: a new Keeper's planner offers the starting crew of three, no Sage before level 2, "
	name += "one cast slot from the restored laws and the target's clock (12.5)"
	if server_url == "":
		check.call(name, false, "no server: run through client/status.py, which starts one")
		return
	var s := Fixtures.answered(Services.build(tree.root, server_url, null, "user://outbox-test-planner.json"))
	s.router.change = func(_path: String) -> void: pass
	var me := await s.account.sign_in("test:planner")
	if not me.ok:
		check.call(name, false, "sign-in refused: %s" % me.code)
		s.close()
		return
	await s.observatory_flow.load_observatory()
	var targets: Array = (s.store.get_slice(ObservatoryState.OBSERVATORY)["view"] as Dictionary).get("targets", [])
	if targets.is_empty():
		check.call(name, false, "no target offered")
		s.close()
		return
	s.planner_flow.open(targets[0])
	await s.planner_flow.load_all()
	var p := PlannerPresenter.screen(s.store.get_slice(PlannerState.PLANNER), s.store.get_slice(KeeperState.KEEPER),
		s.store.get_slice(RosterState.ROSTER), s.store.get_slice(SageState.SAGES), s.store.get_slice(CodexState.CODEX),
		s.store.get_slice(ObservatoryState.OBSERVATORY))
	var sages_wait := (p.get("sages", []) as Array).slice(1).all(func(o: Dictionary) -> bool: return not o["can"])
	check.call(name,
		p["ready"] and (p["crew"] as Array).size() == 3 and p["crew_count"] == "Crew: 0 of 3" and sages_wait
			and (p["casts"] as Array).size() == 3 and p["casts_count"] == "Casts: 0 of 1, paid only if used"
			and p["clock"] == "Heist clock 2:30",
		"%s %s %s" % [p.get("crew_count"), p.get("casts_count"), p.get("clock")])
	s.close()
