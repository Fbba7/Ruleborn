extends SceneTree
## The universe map at a zoom level, saved as a still (tools/render/shoot.sh).
## SHOT is the file; ZOOM (0 the whole universe, 1 a realm, 2 a close-up),
## FOCUS (a realm id, "heart" by default), OUTER (outer realms, 6), TURN and
## TIME (seconds of animation before the still) are optional. Prints the
## triangles and draw calls against §21.3's budget.


func _initialize() -> void:
	var env := func(k: String, d: String) -> String: return OS.get_environment(k) if OS.get_environment(k) != "" else d
	var view := UniverseView.new()
	root.add_child(view)
	# The project's frame, 1080 × 2340, which the window shows at half size.
	view.size = Vector2(1080, 2340)
	view.show_universe(UniverseSample.view(int(env.call("OUTER", "6"))), UniverseSample.extras())
	var zoom := int(env.call("ZOOM", "0"))
	view.turns = int(env.call("TURN", "0"))
	if zoom > 0:
		view.focus_realm(env.call("FOCUS", "heart"), zoom)
	else:
		view.set_zoom(0)
	var frames := int(float(env.call("TIME", "1.5")) * 30.0)
	for i in maxi(4, frames):
		await process_frame
	print("triangles ", view.triangles, " draw calls ", view.draw_calls(), " rendered ",
		RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_PRIMITIVES_IN_FRAME), " prims ",
		RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_DRAW_CALLS_IN_FRAME), " calls")
	var img := root.get_texture().get_image()
	img.save_png(OS.get_environment("SHOT"))
	print("saved ", img.get_size())
	quit()
