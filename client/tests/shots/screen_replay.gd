extends SceneTree
## The replay screen playing a golden replay, part-way through
## (tools/render/shoot.sh). SHOT is the file; GOLDEN names the golden
## (planned-clean by default), TICKS how far in, HOUR the sky's hour.


func _initialize() -> void:
	_go()


func _go() -> void:
	var frame := SubViewport.new()
	frame.size = Vector2i(1080, 2340)
	frame.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(frame)
	App.services = Fixtures.answered(Services.build(frame, "", null, "user://outbox-shot.json"))
	var screen: ReplayScreen = load("res://scenes/replay_screen.tscn").instantiate()
	frame.add_child(screen)
	await process_frame
	screen.set_process(false)
	screen.playing = false
	var golden := OS.get_environment("GOLDEN") if OS.get_environment("GOLDEN") != "" else "planned-clean"
	screen.open_golden(golden)
	(screen.view as WorldView).set_sky_hour(int(OS.get_environment("HOUR")) if OS.get_environment("HOUR") != "" else 17)
	var ticks := int(OS.get_environment("TICKS")) if OS.get_environment("TICKS") != "" else 900
	for k in ticks / 15:
		screen.advance(15)
		screen.view._process(0.5)
	screen._refresh()
	for i in 8:
		await process_frame
	await RenderingServer.frame_post_draw
	frame.get_texture().get_image().save_png(OS.get_environment("SHOT"))
	print("wrote")
	quit()
