extends SceneTree
## Weaving and Harmony with their live previews, as stills
## (tools/render/shoot.sh): WeavingTests' universe with Stillness tapped once
## in the Heart, then HarmonyTests' Heart with its links. SCREEN picks
## "weaving" (default) or "harmony".

func _initialize() -> void:
	_go()


func _go() -> void:
	root.size = Vector2i(1080, 2340)
	App.services = Fixtures.answered(Services.build(root, "", null, "user://outbox-shot.json"))
	var services: Services = App.services
	services.router.change = func(_path: String) -> void: pass
	var which := OS.get_environment("SCREEN") if OS.get_environment("SCREEN") != "" else "weaving"
	var preview: LawFxPreview
	if which == "harmony":
		services.store.dispatch(&"harmony_loaded", {"view": HarmonyTests.sample()})
		var h: HarmonyScreen = load("res://scenes/harmony.tscn").instantiate()
		root.add_child(h)
		await process_frame
		services.store.dispatch(&"harmony_loaded", {"view": HarmonyTests.sample()})
		preview = h.preview
	else:
		services.store.dispatch(&"weaving_loaded", {"view": WeavingTests.sample()})
		var w: WeavingScreen = load("res://scenes/weaving.tscn").instantiate()
		root.add_child(w)
		await process_frame
		services.store.dispatch(&"weaving_loaded", {"view": WeavingTests.sample()})
		w.confirm = "weave:heart:stillness"
		w._refresh()
		preview = w.preview
	await process_frame
	preview._tick(2.0)
	preview.set_process(false)
	for i in 4:
		await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(OS.get_environment("SHOT"))
	print("wrote")
	quit()
