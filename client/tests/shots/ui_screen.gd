extends SceneTree
## Any screen by its scene name (SCREEN=settings), on the tests' answered
## fixtures, for judging the kit's look on real screens (tools/render/shoot.sh).
## HC=1 draws it in high contrast, TEXT=200 at that text size; AUDIT=1
## lists where it draws past the kit (UiAudit); NO_WORLD=1 leaves the worlds'
## 3D undrawn.


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
	# T10's screens with their tests' samples (ScreenShots), as screen_meta.gd.
	if Router.ROUTES.has(StringName(scene)):
		services.store.dispatch(&"navigated", {"name": StringName(scene), "params": ScreenShots.params(scene)})
	var path := "res://scenes/%s.tscn" % scene
	if not ResourceLoader.exists(path):
		path = Router.ROUTES[StringName(scene)]
	var screen: Control = load(path).instantiate()
	root.add_child(screen)
	await process_frame
	ScreenShots.fill(scene, services.store)
	for i: int in 12:
		await process_frame
	# NO_WORLD=1 leaves the worlds' 3D undrawn (their grass moves from one
	# shot to the next), so two shots of the kit compare pixel for pixel.
	if OS.get_environment("NO_WORLD") != "":
		for w: Node in screen.find_children("*", "WorldView", true, false):
			(w as WorldView).viewport.disable_3d = true
	await ShotKit.settle(self, screen)
	if OS.get_environment("AUDIT") != "":
		for line: String in UiAudit.report(screen):
			print("audit " + line)
	# §21.3: under 150 draw calls on every screen, 2D and 3D together.
	print("budget %s: %d draw calls in all" % [scene,
		RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_DRAW_CALLS_IN_FRAME)])
	quit()
