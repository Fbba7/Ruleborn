extends SceneTree
## The realm view screen over a lived-in Heart (tools/render/shoot.sh). SHOT
## is the file; HOUR is optional.
func _initialize() -> void:
	_go()


func _go() -> void:
	root.size = Vector2i(1080, 2340)
	App.services = Fixtures.answered(Services.build(root, "", null, "user://outbox-shot.json"))
	StageFixtures.realm(App.services)
	var screen: Control = load("res://scenes/realm.tscn").instantiate()
	root.add_child(screen)
	await process_frame
	StageFixtures.realm(App.services)
	await ShotKit.settle(self, screen)
	quit()
