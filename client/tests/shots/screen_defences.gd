extends SceneTree
## The defence log over the player's own island and its defence
## (tools/render/shoot.sh).
func _initialize() -> void:
	_go()


func _go() -> void:
	root.size = Vector2i(1080, 2340)
	App.services = Fixtures.answered(Services.build(root, "", null, "user://outbox-shot.json"))
	StageFixtures.realm(App.services)
	App.services.store.dispatch(&"defences_loaded", {"view": DefencesTests.sample()})
	var screen: Control = load("res://scenes/defences.tscn").instantiate()
	root.add_child(screen)
	await process_frame
	App.services.store.dispatch(&"defences_loaded", {"view": DefencesTests.sample()})
	await ShotKit.settle(self, screen)
	quit()
