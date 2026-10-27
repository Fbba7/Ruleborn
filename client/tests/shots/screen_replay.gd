extends SceneTree
## The replay screen playing a golden replay, part-way through
## (tools/render/shoot.sh). SHOT is the file; GOLDEN names the golden
## (planned-clean by default), TICKS how far in, HOUR the sky's hour, FRAMES
## how long the last moment's effects play. planned-clean breaks a pylon at
## tick 113, knocks a guard out at 319 and opens the Vault at 1224.


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
	var screen: ReplayScreen = load("res://scenes/replay_screen.tscn").instantiate()
	frame.add_child(screen)
	await process_frame
	screen.set_process(false)
	screen.playing = false
	var golden := OS.get_environment("GOLDEN") if OS.get_environment("GOLDEN") != "" else "planned-clean"
	screen.open_golden(golden)
	(screen.view as WorldView).set_sky_hour(int(OS.get_environment("HOUR")) if OS.get_environment("HOUR") != "" else 17)
	var ticks := int(OS.get_environment("TICKS")) if OS.get_environment("TICKS") != "" else 900
	var done := 0
	while done < ticks:
		var step := mini(15, ticks - done)
		screen.advance(step)
		done += step
		screen.view._process(0.5 if ticks - done > 30 else 1.0 / 30.0 * step)
	settle(root)
	screen._refresh()
	# FRAMES: how many frames the effects of the last moment play before the
	# still is taken.
	var frames := int(OS.get_environment("FRAMES")) if OS.get_environment("FRAMES") != "" else 8
	for i in frames:
		await process_frame
	await RenderingServer.frame_post_draw
	# §21.3's budgets, as the renderer counted the frame.
	print("budget: %d draw calls, %d primitives" % [
		RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_DRAW_CALLS_IN_FRAME),
		RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_PRIMITIVES_IN_FRAME)])
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
