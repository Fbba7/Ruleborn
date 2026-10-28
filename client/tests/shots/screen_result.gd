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
	if OS.get_environment("LOCALE") != "":
		Strings.set_locale(OS.get_environment("LOCALE"))
	if OS.get_environment("TEXT") != "":
		Settings.text_scale = int(OS.get_environment("TEXT"))
		Settings.apply()
	# The golden clean heist on the fixture realm: what the result shows when
	# a heist pays. GOLDEN picks another.
	var golden := OS.get_environment("GOLDEN") if OS.get_environment("GOLDEN") != "" else "planned-clean"
	var replay := FileAccess.get_file_as_bytes("res://goldens/%s.rbh" % golden)
	App.services.store.dispatch(&"heist_started", {})
	var verdict := RulebornReplay.validate(replay, PackedByteArray())
	if OS.get_environment("SERVER") != "":
		# SERVER: the server's settle answer as HeistController.settled reads
		# it, with the design's split (Starlight, Essence, Renown) and fee.
		var paid := str(verdict.get("grade", "")) != "Foiled"
		verdict.merge({"server": true, "haul": 3115, "fee": 2840, "fee_returned": 2840 if paid else 0,
			"starlight": 2310 if paid else 0, "essence": 805 if paid else 0, "renown": 15 if paid else -8,
			"token": "shot", "rest": {"crew": 5, "minutes": 180 if not paid else 45}}, true)
	App.services.store.dispatch(&"heist_finished", {"replay": replay, "verdict": verdict})
	var screen: Control = load("res://scenes/result_screen.tscn").instantiate()
	frame.add_child(screen)
	if (screen as ResultScreen).world_view != null:
		var hour := int(OS.get_environment("HOUR")) if OS.get_environment("HOUR") != "" else 18
		(screen as ResultScreen).world_view.set_sky_hour(hour)
	settle(root)
	for i in 30:
		await process_frame
	await RenderingServer.frame_post_draw
	# §21.3's budgets, as the renderer counted the frame.
	print("budget: %d draw calls, %d primitives" % [
		RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_DRAW_CALLS_IN_FRAME),
		RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_PRIMITIVES_IN_FRAME)])
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


## Let each character model's clip play on as it would have in real time,
## since a shot runs a heist's seconds in a few frames.
func settle(node: Node) -> void:
	for c in node.find_children("*", "CreatureModel", true, false):
		var p: AnimationPlayer = (c as CreatureModel).player()
		if p != null:
			p.advance(2.0)
