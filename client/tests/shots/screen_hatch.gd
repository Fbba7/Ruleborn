extends SceneTree
## Hatch (tools/render/shoot.sh): HatchTests' Nursery with its egg; with
## BORN set, the birth arrives and the still is taken T seconds into the
## reveal (default 0.6). SCROLL scrolls.
func _initialize() -> void:
	_go()


func _go() -> void:
	root.size = Vector2i(1080, 2340)
	App.services = Fixtures.answered(Services.build(root, "", null, "user://outbox-shot.json"))
	var screen: HatchScreen = load("res://scenes/hatch.tscn").instantiate()
	root.add_child(screen)
	screen.clock = func() -> int: return HatchTests.NOW
	await process_frame
	App.services.store.dispatch(&"workshop_words", {"words": HatchTests.words()})
	App.services.store.dispatch(&"roster_loaded", {"view": HatchTests.sample()})
	for i in 10:
		await process_frame
	var t := float(OS.get_environment("T")) if OS.get_environment("T") != "" else 0.6
	if OS.get_environment("BORN") != "":
		App.services.store.dispatch(&"roster_changed", {"home": HatchTests.born(),
			"what": {"do": "birth", "born": 9, "first": true, "outfit": "hatch-outfit"}})
		await process_frame
		screen.stage.moving = false
		screen.stage.set("_reveal", t)
		screen.stage.set("_actions", [t] as Array[float])
	screen.stage.moving = false
	screen.stage.at_time(1.5)
	for i in 30:
		await process_frame
		if Portrait.settled():
			break
	if OS.get_environment("SCROLL") != "":
		(screen.body.get_parent() as ScrollContainer).scroll_vertical = int(OS.get_environment("SCROLL"))
	screen.stage.at_time(1.5)
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(OS.get_environment("SHOT"))
	print("wrote")
	quit()
