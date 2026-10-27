extends SceneTree
## The landing picker across a universe (tools/render/shoot.sh): the heist
## screen before landing, on LandingTests' universe of a Heart and two outer
## realms, with the deck of islands. PICK chooses which card is on show.


func _initialize() -> void:
	_go()


func _go() -> void:
	root.size = Vector2i(1080, 2340)
	ShotKit.prepare()
	App.services = Fixtures.answered(Services.build(root, "", null, "user://outbox-shot.json"))
	var u := LandingTests.universe()
	App.services.store.dispatch(&"heist_started", {"island": u["islands"][1], "testing": true})
	var screen: HeistScreen = load("res://scenes/heist_screen.tscn").instantiate()
	root.add_child(screen)
	await process_frame
	screen.set_process(false)
	var islands: Array[PackedByteArray] = []
	islands.assign(u["islands"])
	screen.begin_universe("42", 3, u["leased"], u["bytes"], islands)
	if OS.get_environment("PICK") != "":
		var cards := OverlayLandingDeck.choices(screen.controller.marks)
		screen.controller.pick = int(cards[int(OS.get_environment("PICK"))]["first"])
		screen.controller.next_spot(0)
	screen._refresh()
	# The deck's pictures are drawn offscreen, one a few frames.
	for i in 30:
		await process_frame
	screen._refresh()
	await ShotKit.settle(self, screen)
	quit()
