extends SceneTree
## The terrain editor over a dressed island, a ward's ghost under the
## pointer and a refused tap in red (tools/render/shoot.sh); KIND a ground
## feature to choose after, so its card shows.
func _initialize() -> void:
	_go()


func _go() -> void:
	root.size = Vector2i(1080, 2340)
	ShotKit.prepare()
	App.services = Fixtures.answered(Services.build(root, "", null, "user://outbox-shot.json"))
	Draft.path = "user://island-shot.rbi"
	Draft.keep(StageFixtures.island())
	var screen: BuilderScreen = load("res://scenes/builder.tscn").instantiate()
	root.add_child(screen)
	await process_frame
	screen.tool = BuilderScreen.Tool.GROUND
	screen.kind = screen.kinds().find("raised_ground")
	for t: Vector2i in [Vector2i(4, 4), Vector2i(5, 4), Vector2i(4, 5)]:
		screen.tap_tile(t)
	screen.tool = BuilderScreen.Tool.WARD
	screen.kind = 0
	screen.tap_tile(Vector2i(6, 6))
	screen.show_ghost(Vector2i(8, 11))
	# KIND: a ground feature chosen, its card shown, as the design's still.
	if OS.get_environment("KIND") != "":
		screen.tool = BuilderScreen.Tool.GROUND
		screen.kind = screen.kinds().find(OS.get_environment("KIND"))
		screen._refresh()
	await ShotKit.settle(self, screen)
	quit()
