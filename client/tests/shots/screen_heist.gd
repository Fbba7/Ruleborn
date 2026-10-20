extends SceneTree
## The heist screen at a moment of a rehearsal on WorldTests' island
## (tools/render/shoot.sh). SHOT is the file; MOMENT picks the moment:
## "start" (just landed, the first orders given), "sneak" (the crew spread, a
## guard looking), "vault" (the crew at the Vault, cracking), "alarm" (a
## guard alerted, the alarm up), "pick" (the landing picker, before landing),
## "cross" (the swoop to another realm, at its middle), "escape" (Get out,
## the skiff called to the edge), "entry" (a realm's entry card), "hold" (the gait menu
## a held press opens). HOUR and ZOOM are optional; BUTTONS shows
## Settings' turn and zoom buttons, CONTRAST high contrast, LEFT left-handed
## play, TEXT a text size (150, 200), NAMES the names a long press shows.

const TO := {"hold": [[4, 9], [3, 10], [4, 11]], "entry": [], "escape": [[2, 10], [3, 10], [2, 11]],
	"cross": [[4, 9], [3, 10], [4, 11]], "sneak": [[4, 9], [3, 10], [4, 11]], "vault": [[6, 10], [5, 10], [7, 10]],
	"alarm": [[5, 6], [3, 10], [4, 11]], "start": [[7, 8], [2, 10], [1, 10]]}
const TICKS := {"hold": 150, "entry": 20, "escape": 120, "cross": 60, "start": 30, "sneak": 150, "vault": 300,
	"alarm": 150}


func _initialize() -> void:
	_go()


func _go() -> void:
	cast()
	WorldView.heist_perspective = OS.get_environment("ORTHO") == ""
	# A phone's frame of its own, so the still is 1080 by 2340 whatever the
	# window does.
	var frame := SubViewport.new()
	frame.size = Vector2i(1080, 2340)
	frame.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(frame)
	App.services = Fixtures.answered(Services.build(frame, "", null, "user://outbox-shot.json"))
	Settings.camera_buttons = OS.get_environment("BUTTONS") != ""
	Settings.high_contrast = OS.get_environment("CONTRAST") != ""
	Settings.left_handed = OS.get_environment("LEFT") != ""
	Settings.text_scale = int(OS.get_environment("TEXT")) if OS.get_environment("TEXT") != "" else 100
	Settings.apply()
	App.services.store.dispatch(&"heist_started", {"island": WorldTests.island(), "testing": true})
	var screen: HeistScreen = load("res://scenes/heist_screen.tscn").instantiate()
	frame.add_child(screen)
	await process_frame
	var view := screen.view
	view.set_sky_hour(int(OS.get_environment("HOUR")) if OS.get_environment("HOUR") != "" else 12)
	var moment := OS.get_environment("MOMENT") if OS.get_environment("MOMENT") != "" else "sneak"
	if moment == "pick":
		# §5.4's landing picker, before the crew lands.
		screen.set_process(false)
		screen._refresh()
		for i in 8:
			await process_frame
		await RenderingServer.frame_post_draw
		frame.get_texture().get_image().save_png(OS.get_environment("SHOT"))
		quit()
		return
	screen.controller.land_here()
	var to: Array = TO.get(moment, [])
	for i in to.size():
		var t: Array = to[i]
		screen.controller.world.give(i, HeistController.Kind.MOVE_TO, int(t[0]) * 256 + 128, int(t[1]) * 256 + 128)
	var total: int = TICKS.get(moment, 160)
	# Played in steps, so the screen sees each moment as the player would.
	for k in total / 10:
		screen.controller.advance(10)
		screen._refresh()
		view._process(1.0 / 3.0)
	if moment == "vault":
		screen.controller.select(0)
		screen.controller.tap_tile(screen.controller.world.vault()["at"])
		for k in 4:
			screen.controller.advance(10)
			screen._refresh()
			view._process(1.0 / 3.0)
	if moment == "escape":
		# Get out, and the skiff called to the south-west edge.
		screen.controller.get_out()
		screen.controller.tap_tile(Vector2i(1, 11))
		for k in 4:
			screen.controller.advance(10)
			screen._refresh()
			view._process(1.0 / 3.0)
	if moment == "hold":
		# A held press on the ground: the gait menu at the finger.
		screen.open_gait_menu(view.screen_at(Vector2i(5, 8)))
	if moment == "entry":
		# §15.3's banner as the crew comes into a realm.
		screen.entry_card(HeistHud.realm(0, 0))
		# The still is taken at its full showing, past the fade in.
		screen.card.modulate.a = 1.0
		screen.card.set_process(false)
		for t in screen.get_tree().get_processed_tweens():
			t.pause()
	if moment == "cross":
		# §21.1's swoop between realms, caught at its middle.
		view.swoop()
		view._process(0.45)
		view.set_process(false)
	# The landing's drop from the whole realm is long over by the moment shot.
	view.set_zoom(int(OS.get_environment("ZOOM")) if OS.get_environment("ZOOM") != "" else 1)
	if OS.get_environment("NAMES") != "":
		# A long press: every crew member's name over its head.
		view.anchors.names_for = 60.0
	settle(root)
	screen.set_process(false)
	screen._refresh()
	# Portraits rendered from the models fill in over a few frames.
	for i in 40:
		await process_frame
	await RenderingServer.frame_post_draw
	frame.get_texture().get_image().save_png(OS.get_environment("SHOT"))
	print("wrote")
	quit()


## The integrator's cast of character models, until the app sets one: each
## role's default kind, guards as Glass Golems in the guard form (CAST).
static func cast() -> void:
	if WorldView.figure_maker.is_valid() or OS.get_environment("CAST") == "":
		return
	var kinds := {"Scout": &"featherkin", "Breaker": &"rambler", "Carrier": &"skyskipper", "Warden": &"mossbear",
		"Mender": &"hourkeeper", "guard": &"glassgolem"}
	WorldView.figure_maker = func(role: String, _height: float) -> Node3D:
		var c := CreatureModel.make(kinds.get(role, &"featherkin"))
		if c != null and role == "guard":
			c.set_guard(true)
		return c


## Let each character model's clip play on as it would have in real time,
## since a shot runs a heist's seconds in a few frames.
func settle(node: Node) -> void:
	for c in node.find_children("*", "CreatureModel", true, false):
		var p: AnimationPlayer = (c as CreatureModel).player()
		if p != null:
			p.advance(2.0)
