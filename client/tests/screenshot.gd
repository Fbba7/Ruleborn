extends SceneTree
## A still of the replay screen part-way through a heist, for looking at:
##
##     xvfb-run -s "-screen 0 1080x2340x24" <godot> --path client \
##         --rendering-driver opengl3 -s res://tests/screenshot.gd -- out.png [golden] [second]
##
## It needs a display, which a headless run does not have; the tests do not.

func _initialize() -> void:
	_shoot()


func _shoot() -> void:
	var args := OS.get_cmdline_user_args()
	var out := args[0] if args.size() > 0 else "user://replay.png"
	var golden := args[1] if args.size() > 1 else "planned-clean"
	var second := int(args[2]) if args.size() > 2 else 40
	root.size = Vector2i(1080, 2340)
	var screen: ReplayScreen = load("res://scenes/replay_screen.tscn").instantiate()
	root.add_child(screen)
	await process_frame
	screen.playing = false
	screen.open_golden(ReplayScreen.find_goldens().find(golden))
	screen.advance(second * RulebornReplay.ticks_per_second())
	screen.playing = false
	screen._refresh()
	for i in 3:
		await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(out)
	print("wrote ", out)
	quit()
