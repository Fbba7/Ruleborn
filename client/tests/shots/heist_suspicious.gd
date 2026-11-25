extends SceneTree
## A heist moment with a guard Suspicious (tools/render/shoot.sh): the crew
## lands on WorldTests' island and Pip walks up into the first guard's far
## sight, and the heist plays one tick at a time until a guard's suspicion
## crosses into Suspicious (sim::SUSPICIOUS_AT, 200 of 1000). The still shows
## that moment, each guard's state over its head, and prints what guards()
## gave for it: the fields of docs/art/3d-quality/data-spec.md, "Guards".
## SHOT is the file. It fails, with no still, if no guard is Suspicious by
## LIMIT ticks.

const Heist := preload("res://tests/shots/screen_heist.gd")
## Where each crew member walks: Pip north to (6, 8), into the far zone of
## the guard posted at (6, 4) and facing south, so its meter climbs slowly,
## 12 a tick (a near sighting also passes through Suspicious, but at 67 a
## tick it is there for a few ticks only); the others stay back by the
## landing.
const TO := [[6, 8], [1, 10], [2, 10]]
const LIMIT := 900


func _initialize() -> void:
	_go()


func _go() -> void:
	Heist.cast()
	var frame := SubViewport.new()
	frame.size = Vector2i(1080, 2340)
	frame.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(frame)
	App.services = Fixtures.answered(Services.build(frame, "", null, "user://outbox-shot.json"))
	UI.root_theme()
	App.services.store.dispatch(&"heist_started", {"island": WorldTests.island(), "testing": true})
	var screen: HeistScreen = load("res://scenes/heist_screen.tscn").instantiate()
	frame.add_child(screen)
	await process_frame
	var view := screen.view
	view.set_sky_hour(12)
	screen.controller.land_here()
	var world := screen.controller.world
	for i in mini(TO.size(), world.crew().size()):
		var t: Array = TO[i]
		world.give(i, HeistController.Kind.MOVE_TO, int(t[0]) * 256 + 128, int(t[1]) * 256 + 128)
	var found := -1
	for k in LIMIT:
		screen.controller.advance(1)
		if k % 10 == 9:
			screen._refresh()
			view._process(1.0 / 3.0)
		var guards: Array = world.guards()
		for g in guards.size():
			if str(guards[g]["state"]) == "Suspicious":
				found = g
		if found >= 0:
			break
	if found < 0:
		print("FAIL no guard Suspicious by tick ", world.tick())
		quit(1)
		return
	var guards: Array = world.guards()
	var g: Dictionary = guards[found]
	if int(g["suspicion"]) < 200:
		print("FAIL guard ", found, " Suspicious at suspicion ", g["suspicion"])
		quit(1)
		return
	print("tick ", world.tick(), " guard ", found, " ", g)
	view.set_zoom(1)
	screen._refresh()
	view._process(1.0 / 3.0)
	_settle(root)
	screen.set_process(false)
	screen._refresh()
	for i in guards.size():
		view.anchors.say(i, str(guards[i]["state"]))
	for i in 40:
		await process_frame
	for i in guards.size():
		view.anchors.speech.get(i, {})["t"] = 0.6
	await process_frame
	await RenderingServer.frame_post_draw
	frame.get_texture().get_image().save_png(OS.get_environment("SHOT"))
	print("wrote ", OS.get_environment("SHOT"))
	quit()


## Let each character model's clip play on, as screen_heist's settle does.
func _settle(node: Node) -> void:
	for c in node.find_children("*", "CreatureModel", true, false):
		var p: AnimationPlayer = (c as CreatureModel).player()
		if p != null:
			p.advance(2.0)
