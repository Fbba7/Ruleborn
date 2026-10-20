extends SceneTree
## The Observatory's target cards, each with its universe drawn by the
## shared offscreen world (tools/render/shoot.sh).
func _initialize() -> void:
	_go()


func _go() -> void:
	root.size = Vector2i(1080, 2340)
	App.services = Fixtures.answered(Services.build(root, "", null, "user://outbox-shot.json"))
	var screen: Control = load("res://scenes/observatory.tscn").instantiate()
	root.add_child(screen)
	await process_frame
	App.services.store.dispatch(&"observatory_loaded", {"view": ObservatoryTests.sample()})
	for i in 40:
		await process_frame
	await ShotKit.settle(self, screen)
	var n := 0
	for r: Node in screen.find_children("*", "TextureRect", true, false):
		if (r as TextureRect).texture is ImageTexture:
			(r as TextureRect).texture.get_image().save_png(OS.get_environment("SHOT").replace(".png", "-%d.png" % n))
			n += 1
	quit()
