extends SceneTree
## A heist on WorldTests' island with the laws in LAWS woven (comma-separated
## ids; three at the most a realm), the heist screen at a sneaking moment, so
## each law's world and movement signature can be judged on the phone
## (tools/render/shoot.sh). SHOT is the file; HOUR is optional.


func _initialize() -> void:
	_go()


func _go() -> void:
	cast()
	WorldView.heist_perspective = OS.get_environment("ORTHO") == ""
	var frame := SubViewport.new()
	frame.size = Vector2i(1080, 2340)
	frame.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(frame)
	App.services = Fixtures.answered(Services.build(frame, "", null, "user://outbox-shot.json"))
	var island := RulebornIsland.new()
	island.read(WorldTests.island())
	island.clear(9, 4)
	var spots := [[9, 4], [2, 2], [10, 10]]
	var laws := (OS.get_environment("LAWS") if OS.get_environment("LAWS") != "" else "stillness").split(",")
	for i in mini(laws.size(), spots.size()):
		island.weave(laws[i], spots[i][0], spots[i][1])
	print(island.problems())
	App.services.store.dispatch(&"heist_started", {"island": island.bytes(), "testing": true})
	var screen: HeistScreen = load("res://scenes/heist_screen.tscn").instantiate()
	frame.add_child(screen)
	await process_frame
	var view := screen.view
	view.set_sky_hour(int(OS.get_environment("HOUR")) if OS.get_environment("HOUR") != "" else 12)
	screen.controller.land_here()
	for i in 3:
		screen.controller.world.give(i, HeistController.Kind.MOVE_TO, (4 + i) * 256 + 128, 9 * 256 + 128)
	for k in 10:
		screen.controller.advance(10)
		screen._refresh()
		view._process(1.0 / 3.0)
	view.set_zoom(int(OS.get_environment("ZOOM")) if OS.get_environment("ZOOM") != "" else 1)
	settle(root)
	screen.set_process(false)
	screen._refresh()
	for i in 8:
		await process_frame
	await RenderingServer.frame_post_draw
	frame.get_texture().get_image().save_png(OS.get_environment("SHOT"))
	print("wrote")
	quit()


## The integrator's cast of character models, until the app sets one: each
## role's default kind, guards as Glass Golems in the guard form (CAST).
static func cast() -> void:
	if WorldView.figure_maker.is_valid() or OS.get_environment("CAST") == "":
		return
	var kinds := {"Scout": &"featherkin", "Breaker": &"rambler", "Carrier": &"skyskipper", "Warden": &"mossbear",
		"Mender": &"hourkeeper", "guard": &"glassgolem"}
	WorldView.figure_maker = func(role: String, _height: float) -> Node3D:
		var c := CreatureModel.make(kinds.get(role, &"featherkin"))
		if c != null and role == "guard":
			c.set_guard(true)
		return c


## Let each character model's clip play on as it would have in real time,
## since a shot runs a heist's seconds in a few frames.
func settle(node: Node) -> void:
	for c in node.find_children("*", "CreatureModel", true, false):
		var p: AnimationPlayer = (c as CreatureModel).player()
		if p != null:
			p.advance(2.0)
