extends SceneTree
## Every ruleborn's and Sage's bust (CreatureBust) on a disc of its school's
## colour, as the heist's crew row and Sage disc draw them, six to a row
## (tools/render/shoot.sh). FORM draws one form for all ("guard" for the
## guard form); SIDE is a disc's size in pixels (160); CLEAR=1 asks for the
## busts without their lit ground.


func _initialize() -> void:
	_go()


func _go() -> void:
	var side := int(OS.get_environment("SIDE")) if OS.get_environment("SIDE") != "" else 160
	var clear := OS.get_environment("CLEAR") == "1"
	var kinds: Array = StageHeroFigure.KINDS.keys().filter(func(k: String) -> bool: return k not in ["egg", "shell"])
	var size := Vector2i(side * 6 + 14, (side + 8) * ceili(kinds.size() / 6.0) + 6)
	DisplayServer.window_set_size(size)
	root.size = size
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED
	var bg := ColorRect.new()
	bg.color = Color("#2A1E52")
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(bg)
	var grid := GridContainer.new()
	grid.columns = 6
	grid.position = Vector2(4, 4)
	grid.add_theme_constant_override("h_separation", 1)
	grid.add_theme_constant_override("v_separation", 8)
	root.add_child(grid)
	for k: String in kinds:
		var disc := Panel.new()
		disc.custom_minimum_size = Vector2(side, side)
		var box := StyleBoxFlat.new()
		var ground: Color = (Palette.SCHOOL.get(StageHeroFigure.school(k), Palette.MOTION) as Color).lightened(0.15)
		if k in StageHeroFigure.SAGES:
			ground = Color("#3A2A8C")
		box.bg_color = ground
		box.set_corner_radius_all(side / 2)
		box.border_color = Color("#9A6A2C")
		box.set_border_width_all(maxi(2, side / 28))
		disc.add_theme_stylebox_override("panel", box)
		var t := TextureRect.new()
		t.set_anchors_preset(Control.PRESET_FULL_RECT)
		t.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		t.texture = CreatureBust.of(k, OS.get_environment("FORM"), Color.TRANSPARENT if clear else ground)
		disc.add_child(t)
		grid.add_child(disc)
	for i in 240:
		await process_frame
		if CreatureBust.settled() and i > 4:
			break
	for i in 3:
		await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(OS.get_environment("SHOT"))
	print("wrote")
	quit()
