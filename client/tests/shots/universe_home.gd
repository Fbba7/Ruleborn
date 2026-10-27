extends SceneTree
## The home screen with its interface over the universe (§23.2), saved as a
## still (tools/render/shoot.sh). SHOT is the file; OUTER (outer realms, 6),
## ZOOM and FOCUS (as universe_zoom.gd), TEXT (the text size, 100) and TIME
## (seconds of animation) are optional; WHOLE shows the whole universe; RAIDS the
## raids not yet seen (2); MOST every amount at its widest;
## LOCALE the language; CONTRAST high contrast; TALL the window's height in
## points over 540 wide (960 for 9:16).


func _initialize() -> void:
	_go()


func _go() -> void:
	var env := func(k: String, d: String) -> String: return OS.get_environment(k) if OS.get_environment(k) != "" else d
	# The shot's own settings, read before they are set, so home's restore
	# keeps them.
	Settings.path = "user://settings-shot.cfg"
	Settings.restore()
	Settings.text_scale = int(env.call("TEXT", "100"))
	Settings.high_contrast = env.call("CONTRAST", "") != ""
	Settings.locale = env.call("LOCALE", "en")
	Settings.apply()
	if env.call("TALL", "") != "":
		DisplayServer.window_set_size(Vector2i(540, int(env.call("TALL", "1170"))))
		root.size = Vector2i(540, int(env.call("TALL", "1170")))
	App.services = Fixtures.answered(Services.build(root, "", null, "user://outbox-shot.json"))
	var store := App.services.store
	UniverseSample.fill(store, int(env.call("OUTER", "6")), int(env.call("RAIDS", "2")), env.call("MOST", "") != "")
	var screen: Home = load("res://scenes/home.tscn").instantiate()
	root.add_child(screen)
	await process_frame
	var zoom := int(env.call("ZOOM", "0"))
	if zoom > 0:
		screen.world.focus_realm(env.call("FOCUS", "heart"), zoom)
	elif env.call("WHOLE", "") != "":
		await process_frame
		screen.world.show_whole()
	for i in maxi(4, int(float(env.call("TIME", "1.5")) * 30.0)):
		await process_frame
	await RenderingServer.frame_post_draw
	print("triangles ", screen.world.triangles, " draw calls ", screen.world.draw_calls())
	root.get_texture().get_image().save_png(OS.get_environment("SHOT"))
	print("wrote")
	quit()
