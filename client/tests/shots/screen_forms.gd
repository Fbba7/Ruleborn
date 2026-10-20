extends SceneTree
## The Forms album with FormsTests sample (tools/render/shoot.sh).
func _initialize() -> void:
	_go()


func _go() -> void:
	root.size = Vector2i(1080, 2340)
	App.services = Fixtures.answered(Services.build(root, "", null, "user://outbox-shot.json"))
	var screen: FormsScreen = load("res://scenes/forms.tscn").instantiate()
	root.add_child(screen)
	await process_frame
	App.services.store.dispatch(&"forms_loaded", {"view": FormsTests.sample()})
	for i in 60:
		await process_frame
		if Portrait.settled() and i > 6:
			break
	screen.stage.moving = false
	screen.stage.at_time(1.5)
	if OS.get_environment("SCROLL") != "":
		(screen.body.get_parent() as ScrollContainer).scroll_vertical = int(OS.get_environment("SCROLL"))
	for i in 4:
		await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(OS.get_environment("SHOT"))
	print("wrote")
	quit()
