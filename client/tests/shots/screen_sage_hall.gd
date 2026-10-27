extends SceneTree
## The Sage hall as SageTests' Keeper 8 sees it (tools/render/shoot.sh):
## the Archivist on guard, the Tinkerer unlocked, two locked. SCROLL scrolls.
func _initialize() -> void:
	_go()


func _go() -> void:
	root.size = Vector2i(1080, 2340)
	# TEXT=200 and HC=1 render §20.8's larger text and high contrast.
	if OS.get_environment("TEXT") != "":
		Settings.text_scale = int(OS.get_environment("TEXT"))
	Settings.high_contrast = OS.get_environment("HC") != ""
	Settings.apply()
	App.services = Fixtures.answered(Services.build(root, "", null, "user://outbox-shot.json"))
	var screen: SageHallScreen = load("res://scenes/sage_hall.tscn").instantiate()
	root.add_child(screen)
	await process_frame
	App.services.store.dispatch(&"sages_loaded", {"view": SageTests.sample()})
	for i in 60:
		await process_frame
		if Portrait.settled() and i > 6:
			break
	screen.stage.moving = false
	screen.stage.at_time(1.5)
	# SAGE chooses which Sage the hall shows (the_tinkerer, the_gardener).
	if OS.get_environment("SAGE") != "":
		screen._choose(OS.get_environment("SAGE"))
		for i in 30:
			await process_frame
			if Portrait.settled() and i > 6:
				break
		screen.stage.moving = false
		screen.stage.at_time(1.5)
	if OS.get_environment("SCROLL") != "":
		(screen.body.get_parent() as ScrollContainer).scroll_vertical = int(OS.get_environment("SCROLL"))
	for i in 4:
		await process_frame
	await RenderingServer.frame_post_draw
	# §21.3's budget, as RenderingServer counts the frame.
	print("draw calls ", RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_DRAW_CALLS_IN_FRAME),
		", primitives ", RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_PRIMITIVES_IN_FRAME))
	root.get_texture().get_image().save_png(OS.get_environment("SHOT"))
	print("wrote")
	quit()
