extends SceneTree
## T14's proof (docs/art/ui-quality/report.md): what the HUD's authored art
## does in motion, as frames side by side, since a still cannot show it. Top:
## Get out pressed and let go (sinks onto its lip, squashes, springs back past
## its size and settles). Below: loot taken, coins flying in arcs to the loot
## panel, its number rolling up and the panel pulsing as each lands. Each
## column is one moment (UiqJuice's curves at that time).

const TIMES := [0.0, 0.06, 0.16, 0.24, 0.4]
const COL := 380.0


func _initialize() -> void:
	_go()


func _go() -> void:
	# A frame of its own, so the still is 1900 by 900 whatever the window.
	var frame := SubViewport.new()
	frame.size = Vector2i(1900, 900)
	frame.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(frame)
	var bg := ColorRect.new()
	bg.color = Color("#24163E")
	bg.size = Vector2(1900, 900)
	frame.add_child(bg)
	for i in TIMES.size():
		var t: float = TIMES[i]
		var x := 20.0 + COL * i
		var stamp := UiqArt.words("%d ms" % int(t * 1000.0), 34.0, Color("#B8A8D8"))
		stamp.position = Vector2(x + 120.0, 10)
		frame.add_child(stamp)
		frame.add_child(UiqJuice.button_at(t, Vector2(x + 60.0, 70)))
		var flight := float(i) / float(TIMES.size() - 1)
		frame.add_child(UiqJuice.loot_at(flight, Vector2(x, 380), 946))
	for i in 6:
		await process_frame
	await RenderingServer.frame_post_draw
	frame.get_texture().get_image().save_png(OS.get_environment("SHOT"))
	print("wrote")
	quit()
