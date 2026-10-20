extends SceneTree
## The result screen after a rehearsal on WorldTests' island, the island in
## 3D behind the outcome card (tools/render/shoot.sh). SHOT is the file.


func _initialize() -> void:
	_go()


func _go() -> void:
	root.size = Vector2i(1080, 2340)
	App.services = Fixtures.answered(Services.build(root, "", null, "user://outbox-shot.json"))
	var island := WorldTests.island()
	App.services.store.dispatch(&"heist_started", {"island": island, "testing": true})
	var c := HeistController.new()
	c.begin(HeistController.SEED, 900, HeistController.CREW, island)
	c.land_here()
	c.world.give(0, HeistController.Kind.MOVE_TO, 9 * 256 + 128, 6 * 256 + 128)
	c.advance(900)
	var replay := c.record()
	var verdict := RulebornReplay.validate(replay, island)
	App.services.store.dispatch(&"heist_finished", {"replay": replay, "verdict": verdict})
	var screen: Control = load("res://scenes/result_screen.tscn").instantiate()
	root.add_child(screen)
	for i in 30:
		await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(OS.get_environment("SHOT"))
	print("wrote ", verdict)
	quit()
