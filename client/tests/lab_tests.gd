class_name LabTests
extends RefCounted
## The Resonance Lab (§8.6, §10.2, §23.2): its words headless, the flows
## through a FakeTransport, the screen as drawn, and the Lab against the
## server when one is named.

const MINUTE := 60 * 1000
## A fixed clock for the time left.
const NOW := 1791763200000

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
	_spheres()
	await _flows()
	await _on_screen()
	await _online()


## A Lab of level 3 as GET /v1/lab answers: chamber 1 running an unstable
## pairing, chamber 2 idle after an empty experiment that left a hint.
static func sample() -> Dictionary:
	return {"level": 3, "aether": 1000, "sphere": {"today": false, "next_at": null, "can": true},
		"terms": {"minutes": 300, "aether": 1200, "first": false},
		"chambers": [
			{"chamber": 1, "running": {"laws": ["slow_rivers", "bloom"], "ready_at": NOW + 65 * MINUTE,
				"unstable": true}, "result": null},
			{"chamber": 2, "running": null, "result": {"laws": ["bloom", "half_gravity"], "found": null,
				"pages": {"law": "bloom", "n": 3}, "hint": {"law": "bloom", "school": "Time"}}}],
		"found": [{"kind": "resonance", "id": "mangrove_banks"}, {"kind": "chord", "id": "ghost_tide"}],
		"hinted": ["frozen_moment"],
		"remaining": {"Motion": 3, "Matter": 2, "Time": 4, "Energy": 2, "Life": 3, "Spirit": 2},
		"restored": ["slow_rivers", "bloom", "half_gravity", "bounce"]}


static func _slice(view: Dictionary, picks := {}) -> Dictionary:
	return {"view": view, "busy": "", "error": "", "picks": picks, "said": ""}


func _words() -> void:
	var l := LabPresenter.screen(_slice(sample()), NOW)
	var chambers: Array = l["chambers"]
	var idle: Dictionary = chambers[1]
	check.call("the Lab shows one chamber per Lab slot, an idle one with a sphere for each restored law placed and "
			+ "its price and time on the button, which waits with why while the Aether is short (8.6, 10.2, 23.2)",
		chambers.size() == 2 and l["terms"] == "Each experiment: 1,200 Aether, 5 h"
			and idle["slots"].map(func(s: Dictionary) -> String: return s["text"])
				== ["Sphere 1: Slow rivers", "Sphere 2: Bloom"]
			and idle["run"]["action"] == "Run · 1,200 Aether · 5 h" and not idle["run"]["can"]
			and idle["run"]["why"] == "needs 1,200 Aether" and (chambers[0]["run"] as Dictionary).is_empty(),
		"%s | %s" % [l.get("terms"), idle])
	check.call("a running chamber says its laws and time left, and warns of a paradox; a finished one says what it "
			+ "found, or nothing with its pages and the hint after three empty experiments (7.6, 8.6, 23.2)",
		chambers[0]["lines"] == ["Running: Slow rivers, Bloom, ready in 1 h 5 min",
			"Paradox warning: two tier III laws with opposite notes make an unstable pairing"]
			and idle["lines"] == ["Nothing new in Bloom, Half gravity", "3 pages of Bloom",
				"Hint: Bloom has a resonance with a Time law"]
			and LabPresenter.result({"laws": ["slow_rivers", "bloom"], "found": "resonance", "id": "mangrove_banks",
				"pages": {"law": "slow_rivers", "n": 3}})
				== ["Found the resonance Mangrove banks in Slow rivers, Bloom", "3 pages of Slow rivers"]
			and LabPresenter.result({"laws": ["bloom", "bounce", "half_gravity"], "found": "chord",
				"id": "ghost_tide"})[0] == "Found the chord Ghost tide in Bloom, Bounce, Half gravity",
		"%s | %s" % [chambers[0]["lines"], idle["lines"]])
	check.call("the Lab lists what it has found by name, how many are hinted, and how many signature resonances "
			+ "remain in each school (8.6)",
		l["found"] == ["Mangrove banks, a resonance", "Ghost tide, a chord", "Hinted, not yet found: 1",
			"Still to find: Motion 3, Matter 2, Time 4, Energy 2, Life 3, Spirit 2"],
		"%s" % [l["found"]])
	var first := sample()
	first["level"] = 1
	first["sphere"] = null
	first["terms"] = {"minutes": 5, "aether": 0, "first": true}
	first["chambers"] = [{"chamber": 1, "running": null, "result": null}]
	var f := LabPresenter.screen(_slice(first), NOW)
	var none := sample()
	none["level"] = 0
	none["terms"] = null
	none["chambers"] = []
	var n := LabPresenter.screen(_slice(none), NOW)
	check.call("the first experiment runs free for five minutes; a Lab below level 3 says what its third sphere will "
			+ "do; a universe without a Lab is told to build one (8.5, 8.6, 10.2)",
		f["terms"] == "Your first experiment is free and takes 5 min" and f["chambers"][0]["run"]["action"]
			== "Run free · 5 min" and f["chambers"][0]["run"]["can"] and f["chambers"][0]["run"]["cost"] == ""
			and (f["sphere"] as Dictionary).is_empty() and f["chords"]
				== "From Lab level 3 a third sphere names a chord you have woven or crossed, once a day and free"
			and n["none"] == "Build the Resonance Lab in your universe to run experiments" and n["chambers"].is_empty(),
		"%s | %s | %s" % [f.get("terms"), f["chambers"][0]["run"], n.get("none")])


func _spheres() -> void:
	var restored := ["slow_rivers", "bloom", "half_gravity", "bounce"]
	var next := LabPresenter.cycled(restored, ["slow_rivers", "bloom"], 0, 1)
	var back := LabPresenter.cycled(restored, ["slow_rivers", "bloom"], 1, -1)
	var only := LabPresenter.cycled(["slow_rivers", "bloom"], ["slow_rivers", "bloom"], 0, 1)
	var placed := LabPresenter.picks(_slice(sample(), {"2": ["bounce", "bloom"]}), 2)
	check.call("a tap moves a sphere to the next restored law, past any another sphere holds; an untouched chamber "
			+ "holds the first two restored (8.6, 23.2)",
		next == ["half_gravity", "bloom"] and back == ["slow_rivers", "bounce"] and only == ["slow_rivers", "bloom"]
			and placed == ["bounce", "bloom"] and LabPresenter.picks(_slice(sample()), 1) == ["slow_rivers", "bloom"],
		"%s %s %s %s" % [next, back, only, placed])
	var open := LabPresenter.sphere({"today": false, "next_at": null, "can": true})
	var today := LabPresenter.sphere({"today": true, "next_at": NOW, "can": true})
	var none := LabPresenter.sphere({"today": false, "next_at": null, "can": false})
	check.call("from Lab level 3 the third sphere names a chord free, and waits with why once it has named one today "
			+ "or no chord woven or crossed is left; a name it gives is said (8.5)",
		open["action"] == "Name a chord · free" and open["can"] and not today["can"]
			and today["why"] == "named one today; the next tomorrow" and not none["can"]
			and none["why"] == "weave or cross a chord first" and LabPresenter.sphere(null).is_empty()
			and LabPresenter.said("named:ghost_tide") == "The third sphere named the chord Ghost tide",
		"%s | %s | %s" % [open, today, none])


func _flows() -> void:
	var transport := FakeTransport.new()
	var s := Fixtures.answered(Services.build(tree.root, "https://edge.example", transport,
		"user://outbox-lab-test.json"))
	s.api.token = "t"
	var notifier := FakeLocalNotifier.new()
	notifier.ask_permission()
	s.notifier = notifier
	var view := sample()
	view["aether"] = 5000
	transport.on("GET /v1/lab", view)
	await s.lab_flow.load_lab()
	s.lab_flow.cycle(2, 1)
	var placed := LabPresenter.picks(s.store.get_slice(LabState.LAB), 2)
	var after := view.duplicate(true)
	after["chambers"][1] = {"chamber": 2, "running": {"laws": placed, "ready_at": NOW + 300 * MINUTE,
		"unstable": false}, "result": null}
	transport.on("POST /v1/lab", after)
	transport.on("GET /v1/home", {"night": null, "producers": [], "experiments": [
		{"chamber": 1, "ready_at": NOW + 65 * MINUTE}, {"chamber": 2, "ready_at": NOW + 300 * MINUTE}]})
	await s.lab_flow.start(2)
	var sent: Dictionary = {}
	for c: Dictionary in transport.calls:
		if c["route"] == "POST /v1/lab":
			sent = JSON.parse_string((c["body"] as PackedByteArray).get_string_from_utf8())
	var slice: Dictionary = s.store.get_slice(LabState.LAB)
	var timer: Dictionary = notifier.timers.get(DeviceNotices.EXPERIMENT, {})
	check.call("an experiment sends its chamber and the laws in its spheres, shows the Lab the server answers, and "
			+ "sets the device's experiment-finished timer from the home (8.6, 14.6)",
		placed == ["slow_rivers", "half_gravity"] and int(sent.get("chamber", 0)) == 2 and sent.get("laws") == placed
			and slice["view"]["chambers"][1]["running"] is Dictionary and slice["said"] == "started"
			and int(timer.get("at", 0)) == NOW + 65 * MINUTE,
		"%s %s %s" % [placed, sent, timer])
	transport.on("POST /v1/lab", {"error": "chamber_busy", "until": NOW}, 409)
	await s.lab_flow.start(1)
	var refused: Dictionary = s.store.get_slice(LabState.LAB)
	var named := view.duplicate(true)
	named["named"] = "ghost_tide"
	named["sphere"] = {"today": true, "next_at": NOW, "can": true}
	transport.on("POST /v1/lab/sphere", named)
	await s.lab_flow.name_chord()
	var after_name := LabPresenter.screen(s.store.get_slice(LabState.LAB), NOW)
	check.call("a refused experiment keeps the Lab on show and says why; the third sphere asks the server, says the "
			+ "chord it named and waits for tomorrow (8.5, 8.6)",
		refused["error"] == "chamber_busy" and not (refused["view"] as Dictionary).is_empty()
			and LabPresenter.screen(refused, NOW)["error"]
				== "The Lab could not answer: that chamber is still running an experiment"
			and transport.calls[-1]["route"] == "POST /v1/lab/sphere"
			and after_name["said"] == "The third sphere named the chord Ghost tide" and not after_name["sphere"]["can"],
		"%s %s" % [refused["error"], after_name.get("said")])
	s.close()


func _on_screen() -> void:
	var services: Services = App.services
	var screen: LabScreen = await mount.call("lab")
	screen.clock = func() -> int: return NOW
	for i in 5:
		await tree.process_frame
	var view := sample()
	view["aether"] = 5000
	services.store.dispatch(&"lab_loaded", {"view": view})
	var chambers := screen.body.find_children("*", "Label", true, false).filter(
		func(l: Label) -> bool: return l.has_meta("chamber")).map(func(l: Label) -> int: return l.get_meta("chamber"))
	var find := func(key: String) -> Button:
		for b: Button in screen.find_children("*", "Button", true, false):
			if b.get_meta("key", "") == key:
				return b
		return null
	var sphere: Button = find.call("slot:2:0")
	sphere.pressed.emit()
	await tree.process_frame
	var moved: String = (find.call("slot:2:0") as Button).text
	var spend: Button = find.call("run:2")
	var before := spend.text
	spend.pressed.emit()
	await tree.process_frame
	var confirm: String = (find.call("run:2") as Button).text
	var no_run := find.call("run:1") == null and find.call("sphere") != null
	screen.queue_free()
	services.store.dispatch(&"lab_picked", {"chamber": 2, "laws": []})
	await tree.process_frame
	check.call("the Lab screen draws each chamber, a sphere a tap moves along the restored laws, and a run that "
			+ "spends on a second tap; a running chamber has no run; the third sphere has its button (8.5, 8.6, 23.2)",
		chambers == [1, 2] and moved == "Sphere 1: Half gravity" and before == "Run · 1,200 Aether · 5 h"
			and confirm == "Tap again to spend 1,200 Aether" and no_run,
		"%s %s %s %s" % [chambers, moved, before, confirm])


func _online() -> void:
	var name := "against the server: a new Keeper's Lab is not built, has no chambers, and refuses an experiment "
	name += "until it is (8.6, 10.2)"
	if server_url == "":
		check.call(name, false, "no server: run through client/status.py, which starts one")
		return
	var s := Fixtures.answered(Services.build(tree.root, server_url, null, "user://outbox-test-lab.json"))
	s.router.change = func(_path: String) -> void: pass
	var me := await s.account.sign_in("test:lab")
	if not me.ok:
		check.call(name, false, "sign-in refused: %s" % me.code)
		s.close()
		return
	await s.lab_flow.load_lab()
	var v: Dictionary = s.store.get_slice(LabState.LAB)["view"]
	await s.lab_flow.start(1)
	var after: Dictionary = s.store.get_slice(LabState.LAB)
	check.call(name,
		int(v.get("level", -1)) == 0 and (v.get("chambers", [1]) as Array).is_empty() and v.get("terms") == null
			and after["error"] == "no_lab",
		"%s | %s" % [v, after["error"]])
	s.close()
