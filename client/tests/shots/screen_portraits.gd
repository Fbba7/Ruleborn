extends SceneTree
## Every kind's portrait in a grid (tools/render/shoot.sh), on cards in its
## school's colour, as the roster draws them; LOOK draws one look for all.
func _initialize() -> void:
	_go()


func _go() -> void:
	DisplayServer.window_set_size(Vector2i(1200, 800))
	root.size = Vector2i(1200, 800)
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED
	var bg := ColorRect.new()
	bg.color = Color("#221A50")
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(bg)
	var grid := GridContainer.new()
	grid.columns = 6
	root.add_child(grid)
	var kinds: Array = StageHeroFigure.KINDS.keys()
	for k: String in kinds:
		var t := TextureRect.new()
		t.custom_minimum_size = Vector2(200, 200)
		t.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		t.texture = Portrait.of(k, OS.get_environment("LOOK"))
		grid.add_child(t)
	for i in 120:
		await process_frame
		if Portrait.settled() and i > 4:
			break
	for i in 3:
		await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(OS.get_environment("SHOT"))
	print("wrote")
	quit()
