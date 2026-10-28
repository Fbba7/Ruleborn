extends SceneTree
## The universe map at a zoom level, saved as a still (tools/render/shoot.sh).
## SHOT is the file; ZOOM (0 the whole universe, 1 a realm, 2 a close-up),
## FOCUS (a realm id, "heart" by default), OUTER (outer realms, 6), TURN,
## TIME (seconds of animation before the still), and THEN and WIPE (a realm
## to swoop to next, caught that many seconds in) are optional. Prints the
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
	# THEN: a second realm to swoop to, through the cloud wipe, caught WIPE
	# seconds in.
	if env.call("THEN", "") != "":
		view.focus_realm(env.call("THEN", ""), maxi(1, zoom))
		var start := Time.get_ticks_msec()
		while Time.get_ticks_msec() - start < int(float(env.call("WIPE", "0.45")) * 1000.0):
			await process_frame
	print("triangles ", view.triangles, " drawn now ", view.drawn_triangles(), " draw calls ", view.draw_calls(),
		" rendered ",
		RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_PRIMITIVES_IN_FRAME), " prims ",
		RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_DRAW_CALLS_IN_FRAME), " calls")
	# The engine's own count by pass: the main pass, the sun's shadow, the 2D.
	var vp := view.camera.get_viewport().get_viewport_rid()
	var info := func(type: RenderingServer.ViewportRenderInfoType, what: RenderingServer.ViewportRenderInfo) -> int:
		return RenderingServer.viewport_get_render_info(vp, type, what)
	print("main ", info.call(RenderingServer.VIEWPORT_RENDER_INFO_TYPE_VISIBLE,
			RenderingServer.VIEWPORT_RENDER_INFO_DRAW_CALLS_IN_FRAME), " calls ",
		info.call(RenderingServer.VIEWPORT_RENDER_INFO_TYPE_VISIBLE,
			RenderingServer.VIEWPORT_RENDER_INFO_PRIMITIVES_IN_FRAME),
		" prims; shadow ", info.call(RenderingServer.VIEWPORT_RENDER_INFO_TYPE_SHADOW,
			RenderingServer.VIEWPORT_RENDER_INFO_DRAW_CALLS_IN_FRAME), " calls ",
		info.call(RenderingServer.VIEWPORT_RENDER_INFO_TYPE_SHADOW,
			RenderingServer.VIEWPORT_RENDER_INFO_PRIMITIVES_IN_FRAME),
		" prims; 2D ", info.call(RenderingServer.VIEWPORT_RENDER_INFO_TYPE_CANVAS,
			RenderingServer.VIEWPORT_RENDER_INFO_DRAW_CALLS_IN_FRAME), " calls")
	# PROBE: every mesh on show, by its parent, with what it draws.
	if env.call("PROBE", "") != "":
		var tally := {}
		for node in view.world.find_children("*", "GeometryInstance3D", true, false):
			var g := node as GeometryInstance3D
			if not g.is_visible_in_tree():
				continue
			var m := g.material_override as ShaderMaterial
			var key := "%s %s shadow=%s outline=%s tris=%d" % [view.world.get_path_to(g), g.get_class(),
				g.cast_shadow != 0, m != null and m.next_pass != null, UniverseBudget.count(g)]
			tally[key] = int(tally.get(key, 0)) + 1
		var out := FileAccess.open(env.call("PROBE", ""), FileAccess.WRITE)
		for key: String in tally:
			out.store_line("%d %s" % [tally[key], key])
	var img := root.get_texture().get_image()
	img.save_png(OS.get_environment("SHOT"))
	print("saved ", img.get_size())
	quit()
