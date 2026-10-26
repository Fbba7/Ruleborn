extends SceneTree
## Any screen by its scene name (SCREEN=settings), on the tests' answered
## fixtures, for judging the kit's look on real screens (tools/render/shoot.sh).
## HC=1 draws it in high contrast, TEXT=200 at that text size.


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
	var services := Fixtures.answered(Services.build(root, "", null, "user://outbox-shot.json"))
	services.router.change = func(_path: String) -> void: pass
	App.services = services
	var scene := OS.get_environment("SCREEN") if OS.get_environment("SCREEN") != "" else "settings"
	var screen: Control = load("res://scenes/%s.tscn" % scene).instantiate()
	root.add_child(screen)
	for i: int in 12:
		await process_frame
	await ShotKit.settle(self, screen)
	# §21.3: under 150 draw calls on every screen, 2D and 3D together.
	print("budget %s: %d draw calls in all" % [scene,
		RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_DRAW_CALLS_IN_FRAME)])
	quit()
