extends SceneTree
## The kit's component sheet (tools/render/shoot.sh): every material and every
## component on the night backdrop, judged beside the design's stills in
## art/design/stills/screens/. PAGE picks a page (1 materials and type, 2
## controls, 3 status pieces); HC=1 draws it in high contrast.


func _initialize() -> void:
	_go()


func _go() -> void:
	root.size = Vector2i(1080, 2340)
	Settings.locale = "en"
	Settings.high_contrast = OS.get_environment("HC") != ""
	Settings.apply()
	var screen := Control.new()
	screen.name = "KitSheet"
	root.add_child(screen)
	var column := UI.frame(screen)
	var page := int(OS.get_environment("PAGE")) if OS.get_environment("PAGE") != "" else 1
	UiKitPages.page(column, page)
	for i: int in 8:
		await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(OS.get_environment("SHOT"))
	print("wrote")
	quit()
