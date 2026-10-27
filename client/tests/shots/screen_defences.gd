extends SceneTree
## Rehearsal and defence log: TAB=0 the rehearsal, played to its end; TAB=1
## (the default) the defence log (tools/render/shoot.sh).
func _initialize() -> void:
	_go()


func _go() -> void:
	root.size = Vector2i(1080, 2340)
	ShotKit.prepare()
	App.services = Fixtures.answered(Services.build(root, "", null, "user://outbox-shot.json"))
	StageFixtures.realm(App.services)
	App.services.store.dispatch(&"defences_loaded", {"view": DefencesTests.sample()})
	DefencesScreen.tab = int(OS.get_environment("TAB")) if OS.get_environment("TAB") != "" else 1
	var screen: Control = load("res://scenes/defences.tscn").instantiate()
	root.add_child(screen)
	await process_frame
	App.services.store.dispatch(&"defences_loaded", {"view": DefencesTests.sample()})
	await process_frame
	if DefencesScreen.tab == 0:
		var stage := (screen as DefencesScreen).rehearsal
		if OS.get_environment("STYLE") != "":
			stage._choose(OS.get_environment("STYLE"))
			stage.playing = false
			stage.run()
		stage._finish()
	await ShotKit.settle(self, screen)
	quit()
