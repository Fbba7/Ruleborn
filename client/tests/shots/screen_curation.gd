extends SceneTree
## Defence curation over a dressed Heart, a post picked (tools/render/shoot.sh);
## its hold as the server measured it (232 of 800 raids held).
func _initialize() -> void:
	_go()


func _go() -> void:
	root.size = Vector2i(1080, 2340)
	ShotKit.prepare()
	App.services = Fixtures.answered(Services.build(root, "", null, "user://outbox-shot.json"))
	var view := CurationTests.sample()
	view["hold"] = {"status": "measured", "held": 232, "raids": 800}
	App.services.store.dispatch(&"curation_loaded", {"view": view})
	App.services.store.dispatch(&"curation_island", {"island": StageFixtures.island()})
	App.services.store.dispatch(&"curation_words", {"words": FirstTests.words()})
	var screen: Control = load("res://scenes/curation.tscn").instantiate()
	root.add_child(screen)
	await process_frame
	App.services.store.dispatch(&"curation_loaded", {"view": view})
	App.services.store.dispatch(&"curation_island", {"island": StageFixtures.island()})
	App.services.curation_flow.pick_post(Vector2i(7, 8))
	await ShotKit.settle(self, screen)
	quit()
