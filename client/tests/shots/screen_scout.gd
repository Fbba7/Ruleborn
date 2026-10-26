extends SceneTree
## The scout report on a player's universe (tools/render/shoot.sh).
func _initialize() -> void:
	_go()


func _go() -> void:
	root.size = Vector2i(1080, 2340)
	ShotKit.prepare()
	App.services = Fixtures.answered(Services.build(root, "", null, "user://outbox-shot.json"))
	App.services.store.dispatch(&"observatory_loaded", {"view": ObservatoryTests.sample()})
	App.services.store.dispatch(&"observatory_chosen", {"bundle": "p1"})
	var screen: Control = load("res://scenes/scout.tscn").instantiate()
	root.add_child(screen)
	await ShotKit.settle(self, screen)
	quit()
