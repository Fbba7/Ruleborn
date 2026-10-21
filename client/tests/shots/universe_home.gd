extends SceneTree
## The home screen with its interface over the universe (§23.2), saved as a
## still (tools/render/shoot.sh). SHOT is the file; OUTER (outer realms, 6),
## ZOOM and FOCUS (as universe_zoom.gd), TEXT (the text size, 100) and TIME
## (seconds of animation) are optional; WHOLE shows the whole universe.


func _initialize() -> void:
	_go()


func _go() -> void:
	var env := func(k: String, d: String) -> String: return OS.get_environment(k) if OS.get_environment(k) != "" else d
	Settings.text_scale = int(env.call("TEXT", "100"))
	App.services = Fixtures.answered(Services.build(root, "", null, "user://outbox-shot.json"))
	var store := App.services.store
	store.dispatch(&"universe_loaded", {"view": UniverseSample.view(int(env.call("OUTER", "6")))})
	var extras := UniverseSample.extras()
	store.dispatch(&"roster_loaded", {"view": {"producers": extras["producers"]}})
	store.dispatch(&"defences_badge", {"unseen": extras["raids"]})
	store.dispatch(&"keeper_loaded", {"view": {"level": 14, "xp": 1240, "toNext": 2000}})
	store.dispatch(&"wallet_loaded", {"balance": {"starlight": 142050, "essence": 61020}})
	store.dispatch(&"codex_loaded", {"view": {"aether": 31400}})
	store.dispatch(&"league_loaded", {"view": {"renown": 1460, "season": 2}})
	store.dispatch(&"weaving_loaded", {"view": {"stability": {"strain": extras["strain"], "band": extras["band"]}}})
	store.dispatch(&"track_loaded", {"view": {"season": 2, "stars": 1130, "claimed": 6, "tiers": [],
		"next": {"tier": 7, "cost": 1200}}})
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
