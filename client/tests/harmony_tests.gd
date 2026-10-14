class_name HarmonyTests
extends RefCounted
## The Harmony view (§8, §23.2): its words headless, its fetch through a
## FakeTransport, the screen as drawn, and the view against the server when
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
	await _flows()
	await _on_screen()
	await _online()


## A view as GET /v1/weaving/harmony answers: the Heart running Half gravity
## and Bounce, with Slow rivers crowned; a resonance the Lab has not named
## and a chord it has; and Verdant running nothing.
static func sample() -> Dictionary:
	return {"stability": {"band": 2, "strain": 0.774},
		"realms": [
			{"realm": "heart", "type": "Heart",
				"laws": [{"law": "half_gravity", "notes": ["Flow"], "crowned": false},
					{"law": "bounce", "notes": ["Flow", "Echo"], "crowned": false},
					{"law": "slow_rivers", "notes": ["Weight"], "crowned": true}],
				"harmonies": [{"note": "Flow", "laws": ["half_gravity", "bounce"], "factor": 0.85}],
				"clashes": [{"notes": ["Flow", "Weight"], "laws": ["half_gravity", "bounce", "slow_rivers"],
					"factor": 1.25}],
				"resonances": [{"name": null, "laws": ["slow_rivers", "bloom"], "factor": 0.8}],
				"chords": [{"name": "Tempest", "notes": ["Flow", "Spark", "Glow"], "laws": ["half_gravity", "bounce"],
					"factor": 0.9}]},
			{"realm": "outer-1", "type": "Verdant", "laws": [], "harmonies": [], "clashes": [], "resonances": [],
				"chords": []}]}


func _words() -> void:
	var h := HarmonyPresenter.screen({"view": sample(), "busy": false, "error": ""})
	var heart: Dictionary = h["realms"][0]
	check.call("the Harmony view shows every law working in a realm with its notes, a crown law among them as "
			+ "crowned, and the universe's strain (8.1, 5.1, 23.2)",
		heart["title"] == "The Heart"
			and heart["laws"] == ["Half gravity: Flow", "Bounce: Flow, Echo", "Slow rivers, crowned: Weight"]
			and h["header"] == "Strain 77%, Humming",
		"%s | %s" % [heart["laws"], h.get("header")])
	check.call("the Harmony view shows each realm's harmonies and clashes, and its resonances and chords, a "
			+ "named one by its name and one not yet named as an unnamed line, each with what it does to its "
			+ "laws' cost (8.2, 8.3, 8.4, 8.6, 5.5)",
		heart["lines"] == ["Harmony on Flow: Half gravity, Bounce, each costs 15% less",
			"Clash of Flow and Weight: Half gravity, Bounce, Slow rivers, each costs 25% more",
			"An unnamed resonance: Slow rivers, Bloom, each costs 20% less",
			"Tempest, of Flow, Spark, Glow: Half gravity, Bounce, each costs 10% less"],
		"%s" % [heart["lines"]])
	var verdant: Dictionary = h["realms"][1]
	check.call("a realm with no laws working says so (23.2)",
		verdant["title"] == "Verdant" and verdant["laws"] == ["No laws work here yet"] and verdant["lines"] == [],
		"%s" % [verdant])


func _flows() -> void:
	var transport := FakeTransport.new()
	var s := Fixtures.answered(Services.build(tree.root, "https://edge.example", transport,
		"user://outbox-harmony-test.json"))
	s.api.token = "t"
	transport.on("GET /v1/weaving/harmony", sample())
	await s.harmony_flow.load_harmony()
	var loaded: Dictionary = s.store.get_slice(HarmonyState.HARMONY)
	transport.offline = true
	await s.harmony_flow.load_harmony()
	transport.offline = false
	var failed: Dictionary = s.store.get_slice(HarmonyState.HARMONY)
	check.call("the Harmony view is fetched from the server, and a failed fetch keeps the last view on show and "
			+ "says why (23.2)",
		not (loaded["view"] as Dictionary).is_empty() and failed["error"] != ""
			and failed["view"] == loaded["view"] and HarmonyPresenter.screen(failed)["error"] != "",
		"%s" % [failed["error"]])
	s.close()


func _on_screen() -> void:
	var services: Services = App.services
	var screen: HarmonyScreen = await mount.call("harmony")
	await tree.process_frame
	services.store.dispatch(&"harmony_loaded", {"view": sample()})
	var labels := screen.body.find_children("*", "Label", true, false)
	var realms := labels.filter(func(l: Label) -> bool: return l.has_meta("realm"))
	var lines := labels.filter(func(l: Label) -> bool: return l.has_meta("combination")).map(
		func(l: Label) -> String: return l.text)
	screen.queue_free()
	await tree.process_frame
	check.call("the Harmony screen draws each realm and every combination its laws make, in words (23.2, 20.8)",
		realms.size() == 2 and lines.size() == 4 and "An unnamed resonance: Slow rivers, Bloom, each costs 20% less" in lines,
		"%s %s" % [realms.size(), lines])


func _online() -> void:
	var name := "against the server: the Harmony view shows a new universe's Heart running nothing yet (23.2)"
	if server_url == "":
		check.call(name, false, "no server: run through client/status.py, which starts one")
		return
	var s := Fixtures.answered(Services.build(tree.root, server_url, null, "user://outbox-test-harmony.json"))
	s.router.change = func(_path: String) -> void: pass
	var me := await s.account.sign_in("test:harmony")
	if not me.ok:
		check.call(name, false, "sign-in refused: %s" % me.code)
		s.close()
		return
	await s.harmony_flow.load_harmony()
	var slice: Dictionary = s.store.get_slice(HarmonyState.HARMONY)
	var h := HarmonyPresenter.screen(slice)
	var realms: Array = h.get("realms", [])
	check.call(name,
		slice["error"] == "" and realms.size() == 1 and realms[0]["title"] == "The Heart"
			and realms[0]["laws"] == ["No laws work here yet"] and str(h.get("header", "")).begins_with("Strain 0%"),
		"%s | %s" % [slice["error"], realms])
	s.close()
