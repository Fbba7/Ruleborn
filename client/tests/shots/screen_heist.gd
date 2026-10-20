extends SceneTree
## The heist screen at a moment of a rehearsal on WorldTests' island
## (tools/render/shoot.sh). SHOT is the file; MOMENT picks the moment:
## "start" (just landed, the first orders given), "sneak" (the crew spread, a
## guard looking), "vault" (the crew at the Vault, cracking), "alarm" (a
## guard alerted, the alarm up), "pick" (the landing picker, before landing),
## "cross" (the swoop to another realm, at its middle). HOUR and ZOOM are
## optional; BUTTONS shows Settings' turn and zoom buttons.

const TO := {"cross": [[4, 9], [3, 10], [4, 11]], "sneak": [[4, 9], [3, 10], [4, 11]],
	"vault": [[6, 10], [5, 10], [7, 10]], "alarm": [[5, 6], [3, 10], [4, 11]], "start": [[7, 8], [2, 10], [1, 10]]}
const TICKS := {"cross": 60, "start": 30, "sneak": 150, "vault": 300, "alarm": 150}


func _initialize() -> void:
	_go()


func _go() -> void:
	# A phone's frame of its own, so the still is 1080 by 2340 whatever the
	# window does.
	var frame := SubViewport.new()
	frame.size = Vector2i(1080, 2340)
	frame.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(frame)
	App.services = Fixtures.answered(Services.build(frame, "", null, "user://outbox-shot.json"))
	Settings.camera_buttons = OS.get_environment("BUTTONS") != ""
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
	if moment == "cross":
		# §21.1's swoop between realms, caught at its middle.
		view.swoop()
		view._process(0.45)
		view.set_process(false)
	if OS.get_environment("ZOOM") != "":
		view.set_zoom(int(OS.get_environment("ZOOM")))
	screen.set_process(false)
	screen._refresh()
	for i in 6:
		await process_frame
	await RenderingServer.frame_post_draw
	frame.get_texture().get_image().save_png(OS.get_environment("SHOT"))
	print("wrote")
	quit()
