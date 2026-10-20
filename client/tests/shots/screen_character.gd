extends SceneTree
## The Character screen for one of ShotData's roster (tools/render/shoot.sh):
## ID picks the character (5, a Skyskipper, by default); SCROLL scrolls.
func _initialize() -> void:
	_go()


func _go() -> void:
	root.size = Vector2i(1080, 2340)
	App.services = Fixtures.answered(Services.build(root, "", null, "user://outbox-shot.json"))
	App.services.store.dispatch(&"roster_loaded", {"view": ShotData.roster()})
	var id := int(OS.get_environment("ID")) if OS.get_environment("ID") != "" else 5
	App.services.router.go(&"character", {"id": id})
	await process_frame
	var screen: CharacterScreen = null
	for i in 10:
		await process_frame
		for c in root.get_children():
			if c is CharacterScreen:
				screen = c
		if screen != null:
			break
	if screen == null:
		screen = load("res://scenes/character.tscn").instantiate()
		root.add_child(screen)
	screen.clock = func() -> int: return RosterTests.NOW
	screen._refresh()
	for i in 60:
		await process_frame
		if Portrait.settled() and i > 30:
			break
	for s: StageHero in [screen.stage]:
		s.moving = false
		s.at_time(1.5)
	if OS.get_environment("SCROLL") != "":
		(screen.body.get_parent() as ScrollContainer).scroll_vertical = int(OS.get_environment("SCROLL"))
	for i in 4:
		await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(OS.get_environment("SHOT"))
	print("wrote")
	quit()
