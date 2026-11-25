class_name BudgetSplit
extends RefCounted
## The shots' triangle budget, split the way the 3D quality plan measured it
## by hand: what the frame's renderer count is made of. The count is the sum of
##   mesh triangles: what the world views draw with their outline passes off
##   outline passes: what the outline passes draw a second time
##   other views: everything else the frame draws (panels, small sub-views)
## `line` prints one `budget` line: the world views' triangles and draw calls
## (mesh plus outline passes), then the other views', then the frame's; the
## three parts add up to the frame's total, which is the count the heist,
## replay and result shots printed before.
## The split is found by hiding the outline passes for a frame, so it is exact
## by construction, whatever the meshes are.


## The `budget` line of the frame as it stands, for every WorldView under `tree`.
## `label` names the shot. Returns the line's figures too.
static func line(tree: SceneTree, label: String) -> Dictionary:
	var views: Array[WorldView] = []
	for n: Node in tree.root.find_children("*", "WorldView", true, false):
		var v := n as WorldView
		if v != null and v.is_visible_in_tree():
			views.append(v)
	var total := await _frame(tree)
	var mesh_with := 0
	for v: WorldView in views:
		mesh_with += _view(v)
	var held := _strip(views)
	var mesh := 0
	if not held.is_empty():
		var without := await _frame(tree)
		mesh = mesh_with - (total - without)
		_restore(held)
		await _frame(tree)
	else:
		mesh = mesh_with
	var outline := mesh_with - mesh
	var frame_calls := RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_DRAW_CALLS_IN_FRAME)
	var calls := 0
	var shadow := 0
	for v: WorldView in views:
		calls += v.viewport.get_render_info(Viewport.RENDER_INFO_TYPE_VISIBLE, Viewport.RENDER_INFO_DRAW_CALLS_IN_FRAME)
		shadow += v.viewport.get_render_info(Viewport.RENDER_INFO_TYPE_SHADOW, Viewport.RENDER_INFO_DRAW_CALLS_IN_FRAME)
	var other := total - mesh - outline
	var world := "%d triangles (%d mesh + %d outline passes), %d draw calls (+%d in shadows)" % [
		mesh + outline, mesh, outline, calls, shadow]
	var rest := "%d triangles and %d draw calls in other views" % [other, frame_calls - calls]
	print("budget: %s: %s; %s; frame %d triangles, %d draw calls" % [
		label, world, rest, total, frame_calls])
	return {"total": total, "mesh": mesh, "outline": outline, "other": other,
			"draw_calls": calls, "frame_draw_calls": frame_calls}


static func _view(v: WorldView) -> int:
	return v.viewport.get_render_info(Viewport.RENDER_INFO_TYPE_VISIBLE, Viewport.RENDER_INFO_PRIMITIVES_IN_FRAME)


static func _frame(tree: SceneTree) -> int:
	for i in 3:
		await tree.process_frame
	await RenderingServer.frame_post_draw
	return RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_PRIMITIVES_IN_FRAME)


## Cuts every outline pass out of the views' materials; the pairs to put back.
static func _strip(views: Array[WorldView]) -> Array:
	var held: Array = []
	var seen := {}
	for v: WorldView in views:
		var meshes: Array[Node] = v.world.find_children("*", "MeshInstance3D", true, false)
		for n: Node in meshes:
			var mi := n as MeshInstance3D
			var mats: Array[Material] = [mi.material_override]
			if mi.mesh != null:
				for s in mi.mesh.get_surface_count():
					mats.append(mi.get_surface_override_material(s))
					mats.append(mi.mesh.surface_get_material(s))
			for m: Material in mats:
				while m != null:
					var next := m.next_pass
					if next != null and _is_outline(next) and not seen.has(m):
						seen[m] = true
						held.append([m, next])
						m.next_pass = next.next_pass
					m = m.next_pass
	return held


static func _restore(held: Array) -> void:
	for h: Array in held:
		var m := h[0] as Material
		m.next_pass = h[1] as Material


static func _is_outline(m: Material) -> bool:
	var s := m as ShaderMaterial
	return s != null and s.shader != null and s.shader.resource_path.ends_with("outline.gdshader")
