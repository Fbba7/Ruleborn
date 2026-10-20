extends SceneTree
## The law card with its live preview (scripts/law_screen.gd, LawFxPreview),
## as a still (tools/render/shoot.sh). LAW picks the law (default Bloom, the
## one CodexTests' sample opens); SECONDS how far into its loop (default 2).

func _initialize() -> void:
	_go()


func _go() -> void:
	root.size = Vector2i(1080, 2340)
	App.services = Fixtures.answered(Services.build(root, "", null, "user://outbox-shot.json"))
	var services: Services = App.services
	services.router.change = func(_path: String) -> void: pass
	services.store.dispatch(&"codex_loaded", {"view": CodexTests.sample(), "changes": 0})
	var law := OS.get_environment("LAW") if OS.get_environment("LAW") != "" else "bloom"
	services.router.go(&"law", {"law": law})
	var screen: LawScreen = load("res://scenes/law.tscn").instantiate()
	root.add_child(screen)
	await process_frame
	var seconds := float(OS.get_environment("SECONDS")) if OS.get_environment("SECONDS") != "" else 2.0
	screen.preview._tick(seconds)
	screen.preview.set_process(false)
	for i in 4:
		await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(OS.get_environment("SHOT"))
	print("wrote")
	quit()
