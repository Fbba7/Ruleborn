extends SceneTree
## The heist screen in a rehearsal of WorldTests' island, part-way through
## (tools/render/shoot.sh). SHOT is the file; TICKS and HOUR are optional.
func _initialize() -> void:
	_go()


func _go() -> void:
	root.size = Vector2i(1080, 2340)
	App.services = Fixtures.answered(Services.build(root, "", null, "user://outbox-shot.json"))
	App.services.store.dispatch(&"heist_started", {"island": WorldTests.island(), "testing": true})
	var screen: HeistScreen = load("res://scenes/heist_screen.tscn").instantiate()
	root.add_child(screen)
	await process_frame
	(screen.view as WorldView).set_sky_hour(int(OS.get_environment("HOUR")) if OS.get_environment("HOUR") != "" else 12)
	var ticks := int(OS.get_environment("TICKS")) if OS.get_environment("TICKS") != "" else 0
	if ticks > 0:
		screen.controller.land_here()
		screen.controller.world.give(0, HeistController.Kind.MOVE_TO, 6 * 256 + 128, 6 * 256 + 128)
		screen.controller.world.give(1, HeistController.Kind.MOVE_TO, 5 * 256 + 128, 7 * 256 + 128)
		screen.controller.world.give(2, HeistController.Kind.MOVE_TO, 7 * 256 + 128, 6 * 256 + 128)
		screen.controller.advance(ticks)
	screen.set_process(false)
	screen._refresh()
	for i in 4:
		await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(OS.get_environment("SHOT"))
	print("wrote")
	quit()
