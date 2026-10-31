extends SceneTree
## The home key frame's world: the game's universe (§23.2) as
## client/tests/shots/universe_home.gd sets it up, at the phone's full 1080 x
## 2340 and with the interface and the realms' pins hidden, since the key frame
## draws those itself. Run by bake.sh; SHOT is the file, CONTRAST high contrast.
## PINS prints where each realm's pin stands, in points, for the page.


func _initialize() -> void:
	_go()


func _go() -> void:
	Settings.path = "user://settings-keyframes.cfg"
	Settings.restore()
	Settings.text_scale = 100
	Settings.high_contrast = OS.get_environment("CONTRAST") != ""
	Settings.locale = "en"
	Settings.apply()
	DisplayServer.window_set_size(Vector2i(1080, 2340))
	root.size = Vector2i(1080, 2340)
	App.services = Fixtures.answered(Services.build(root, "", null, "user://outbox-keyframes.json"))
	UniverseSample.fill(App.services.store, 6, 0, false)
	var screen: Home = load("res://scenes/home.tscn").instantiate()
	root.add_child(screen)
	for i in 45:
		await process_frame
	for c: Node in screen.get_children():
		if c is CanvasItem and c != screen.world:
			(c as CanvasItem).visible = false
	if OS.get_environment("PINS") != "":
		for p: Node in screen.world.pins.get_children():
			if p is Control:
				var r := (p as Control).get_global_rect()
				print("pin ", p.name, " ", r.position / 2.769, " ", r.size / 2.769)
	screen.world.pins.visible = false
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(OS.get_environment("SHOT"))
	print("wrote ", root.get_texture().get_image().get_size())
	quit()
