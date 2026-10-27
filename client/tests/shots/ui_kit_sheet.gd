extends SceneTree
## The kit's component sheet (tools/render/shoot.sh): every material and every
## component on the night backdrop, judged beside the design's stills in
## art/design/stills/screens/. PAGE picks a page (1 materials and type, 2
## controls, 3 status pieces, up to 11); HC=1 draws it in high contrast,
## TEXT=150 or 200 at that text size.


func _initialize() -> void:
	_go()


func _go() -> void:
	root.size = Vector2i(1080, 2340)
	Settings.path = "user://settings-shot.cfg"
	# Read once now, so a screen that restores the settings keeps these.
	Settings.restore()
	Settings.locale = "en"
	Settings.high_contrast = OS.get_environment("HC") != ""
	Settings.text_scale = int(OS.get_environment("TEXT")) if OS.get_environment("TEXT") != "" else 100
	Settings.apply()
	var screen := Control.new()
	screen.name = "KitSheet"
	root.add_child(screen)
	var column := UI.frame(screen)
	var page := int(OS.get_environment("PAGE")) if OS.get_environment("PAGE") != "" else 1
	UiKitPages.page(column, page)
	for i: int in 8:
		await process_frame
	# Portraits draw in a frame or two each; the page waits for them.
	for i: int in 120:
		if Portrait.settled():
			break
		await process_frame
	for i: int in 4:
		await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(OS.get_environment("SHOT"))
	# §21.3: under 150 draw calls on every screen.
	print("budget %s: %d draw calls, %d boxes" % [screen.name,
		RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_DRAW_CALLS_IN_FRAME),
		screen.find_children("*", "RbBox", true, false).size()])
	print("wrote")
	quit()
