extends SceneTree
## The Universe map screen or the universe screen over the 3D universe, saved
## as a still (tools/render/shoot.sh). SHOT is the file; SCREEN ("map", the
## default, or "universe"), OUTER and TIME are optional.


func _initialize() -> void:
	_go()


func _go() -> void:
	var env := func(k: String, d: String) -> String: return OS.get_environment(k) if OS.get_environment(k) != "" else d
	App.services = Fixtures.answered(Services.build(root, "", null, "user://outbox-shot.json"))
	var store := App.services.store
	var d := MapTests.slices()
	store.dispatch(&"weaving_loaded", {"view": d["weaving"]["view"]})
	store.dispatch(&"roster_loaded", {"view": d["home"]["view"]})
	store.dispatch(&"defences_badge", {"unseen": 2})
	var view := UniverseSample.view(int(env.call("OUTER", "6")))
	view["realms"][0]["room"] = UniverseTests.sample()["realms"][0]["room"]
	store.dispatch(&"universe_loaded", {"view": view})
	var screen: Control = load("res://scenes/%s.tscn" % env.call("SCREEN", "map")).instantiate()
	root.add_child(screen)
	for i in maxi(4, int(float(env.call("TIME", "1.5")) * 30.0)):
		await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(OS.get_environment("SHOT"))
	print("wrote")
	quit()
