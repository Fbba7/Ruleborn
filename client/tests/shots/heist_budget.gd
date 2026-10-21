extends SceneTree
## §21.3's budgets on the heist screen, measured on the renderer
## (tools/render/shoot.sh): the frame's draw calls and triangles, the world's
## split into its colour pass, its shadow pass and the HUD's canvas, then what
## each part of the world costs, found by hiding it for a frame. SCREEN picks
## the screen: "heist" (default, at MOMENT's moment as screen_heist sets it),
## "replay" or "result". LAWS weaves laws (comma-separated) into the island.

const HeistShot := preload("res://tests/shots/screen_heist.gd")
const LawShot := preload("res://tests/shots/law_heist.gd")

var _frame: SubViewport


func _initialize() -> void:
	_go()


func _go() -> void:
	HeistShot.cast()
	WorldView.heist_perspective = OS.get_environment("ORTHO") == ""
	_frame = SubViewport.new()
	_frame.size = Vector2i(1080, 2340)
	_frame.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(_frame)
	App.services = Fixtures.answered(Services.build(_frame, "", null, "user://outbox-shot.json"))
	Settings.apply()
	var island := WorldTests.island()
	if OS.get_environment("LAWS") != "":
		island = LawShot.island(Array(OS.get_environment("LAWS").split(",")))
	App.services.store.dispatch(&"heist_started", {"island": island, "testing": true})
	var screen: HeistScreen = load("res://scenes/heist_screen.tscn").instantiate()
	_frame.add_child(screen)
	await process_frame
	var view := screen.view
	view.set_sky_hour(12)
	screen.controller.land_here()
	var to: Array = [[4, 9], [3, 10], [4, 11]]
	for i in to.size():
		var t: Array = to[i]
		screen.controller.world.give(i, HeistController.Kind.MOVE_TO, int(t[0]) * 256 + 128, int(t[1]) * 256 + 128)
	for k in 15:
		screen.controller.advance(10)
		screen._refresh()
		view._process(1.0 / 3.0)
	view.set_zoom(1)
	screen.set_process(false)
	screen._refresh()
	for i in 30:
		await process_frame
	await _report("whole", view)
	var parts: Array[Node] = []
	for n: Node in [view.statics, view.actors, view.effects, view.overlay, view.marks_node, view.sight_edge,
			view._rings]:
		parts.append(n)
	for n: Node in parts:
		var n3 := n as Node3D
		if n3 == null or not n3.visible:
			continue
		n3.visible = false
		await _report("  without %s" % _named(n3), view)
		n3.visible = true
	# The HUD's canvas, part by part.
	var huds: Array[CanvasItem] = [view.anchors]
	for c: Node in screen.find_children("*", "Control", true, false):
		if c is Control and not view.is_ancestor_of(c) and (c as Control).is_visible_in_tree() \
				and c.get_child_count() <= 1 and c is not Container:
			huds.append(c as CanvasItem)
	for c: CanvasItem in huds:
		c.visible = false
		await _report("  without %s %s" % [c.get_class(), c.name], view)
		c.visible = true
	view.anchors.visible = false
	screen.hud.visible = false
	for c: Node in screen.get_children():
		if c is Control and c != view:
			(c as Control).visible = false
	await _report("  without the HUD", view)
	quit()


func _named(n: Node) -> String:
	var mi := n as MeshInstance3D
	if mi != null and mi.mesh != null:
		return "%s (%s, %d surfaces)" % [n.name, mi.mesh.get_class(), mi.mesh.get_surface_count()]
	return "%s (%d children)" % [n.name, n.get_child_count()]


func _report(what: String, view: WorldView) -> void:
	for i in 3:
		await process_frame
	await RenderingServer.frame_post_draw
	var vp := view.viewport
	print("%s: frame %d calls %d prims | world colour %d shadow %d canvas %d | prims %d" % [what,
		RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_DRAW_CALLS_IN_FRAME),
		RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_PRIMITIVES_IN_FRAME),
		vp.get_render_info(Viewport.RENDER_INFO_TYPE_VISIBLE, Viewport.RENDER_INFO_DRAW_CALLS_IN_FRAME),
		vp.get_render_info(Viewport.RENDER_INFO_TYPE_SHADOW, Viewport.RENDER_INFO_DRAW_CALLS_IN_FRAME),
		_frame.get_render_info(Viewport.RENDER_INFO_TYPE_CANVAS, Viewport.RENDER_INFO_DRAW_CALLS_IN_FRAME),
		vp.get_render_info(Viewport.RENDER_INFO_TYPE_VISIBLE, Viewport.RENDER_INFO_PRIMITIVES_IN_FRAME)])
