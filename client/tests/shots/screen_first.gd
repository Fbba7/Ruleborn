extends SceneTree
## The first launch's title beat (tools/render/shoot.sh), its welcome scene
## above the words.
func _initialize() -> void:
	_go()


func _go() -> void:
	root.size = Vector2i(1080, 2340)
	# TEXT=200 and HC=1 render §20.8's larger text and high contrast.
	if OS.get_environment("TEXT") != "":
		Settings.text_scale = int(OS.get_environment("TEXT"))
	Settings.high_contrast = OS.get_environment("HC") != ""
	Settings.apply()
	DirAccess.remove_absolute("user://outbox-first-shot-first.json")
	DirAccess.remove_absolute("user://outbox-first-shot-age.json")
	App.services = Services.build(root, "", null, "user://outbox-first-shot.json")
	App.services.router.change = func(_p: String) -> void: pass
	var screen: FirstScreen = load("res://scenes/first.tscn").instantiate()
	root.add_child(screen)
	for i in 20:
		await process_frame
	# STEPS moves on that many beats (the protections, the name).
	for i in int(OS.get_environment("STEPS")) if OS.get_environment("STEPS") != "" else 0:
		await screen.controller.next()
		for j in 4:
			await process_frame
	screen.stage.moving = false
	screen.stage.at_time(2.0)
	for i in 3:
		await process_frame
	await RenderingServer.frame_post_draw
	# §21.3's budget, as RenderingServer counts the frame.
	print("draw calls ", RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_DRAW_CALLS_IN_FRAME),
		", primitives ", RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_PRIMITIVES_IN_FRAME))
	root.get_texture().get_image().save_png(OS.get_environment("SHOT"))
	print("wrote")
	quit()
