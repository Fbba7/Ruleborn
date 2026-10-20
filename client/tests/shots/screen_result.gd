extends SceneTree
## The result screen after a golden heist, the island in 3D behind the
## outcome card (tools/render/shoot.sh). SHOT is the file; GOLDEN and HOUR
## are optional.


func _initialize() -> void:
	_go()


func _go() -> void:
	cast()
	WorldView.heist_perspective = OS.get_environment("ORTHO") == ""
	# A phone's frame of its own, so the still is 1080 by 2340 whatever the
	# window does.
	var frame := SubViewport.new()
	frame.size = Vector2i(1080, 2340)
	frame.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(frame)
	App.services = Fixtures.answered(Services.build(frame, "", null, "user://outbox-shot.json"))
	# The golden clean heist on the fixture realm: what the result shows when
	# a heist pays. GOLDEN picks another.
	var golden := OS.get_environment("GOLDEN") if OS.get_environment("GOLDEN") != "" else "planned-clean"
	var replay := FileAccess.get_file_as_bytes("res://goldens/%s.rbh" % golden)
	App.services.store.dispatch(&"heist_started", {})
	var verdict := RulebornReplay.validate(replay, PackedByteArray())
	App.services.store.dispatch(&"heist_finished", {"replay": replay, "verdict": verdict})
	var screen: Control = load("res://scenes/result_screen.tscn").instantiate()
	frame.add_child(screen)
	if (screen as ResultScreen).world_view != null:
		var hour := int(OS.get_environment("HOUR")) if OS.get_environment("HOUR") != "" else 18
		(screen as ResultScreen).world_view.set_sky_hour(hour)
	for i in 30:
		await process_frame
	await RenderingServer.frame_post_draw
	frame.get_texture().get_image().save_png(OS.get_environment("SHOT"))
	print("wrote ", verdict)
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
