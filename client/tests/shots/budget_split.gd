class_name BudgetSplit
extends RefCounted
## The shots' triangle budget, split the way the 3D quality plan measured it
## by hand: what the frame's renderer count is made of. The count is the sum of
##   mesh triangles: what the world views draw on screen with their outline
##     passes off
##   outline passes: what the inverted-hull passes (every next pass whose
##     shader culls front faces: the outlines and the law FX ink) draw on
##     screen a second time
##   shadows: what the world views draw into their shadow maps, outline
##     passes included
##   other views: everything else the frame draws (panels, small sub-views)
## `line` prints one `budget` line: the world views' triangles on screen (mesh
## plus outline passes), then in their shadow maps, then the world views' draw
## calls, then the other views' triangles and draw calls, then the frame's; the
## four triangle parts add up to the frame's total, which is the count the
## heist, replay and result shots printed before.
## The world views' draw calls are one figure, shadow passes included: the
## Compatibility renderer counts its shadow-map draw calls with the visible
## ones (a box casting a shadow adds one visible draw call, and the shadow
## draw-call count stays 0), while it counts their triangles apart.
## The split is found by hiding the outline passes for a frame and counting
## the world views' on-screen triangles again, so it is exact by construction,
## whatever the meshes are, and the shadow passes never land in it.


## The `budget` line of the frame as it stands, for every WorldView under `tree`.
## `label` names the shot. Returns the line's figures too.
static func line(tree: SceneTree, label: String) -> Dictionary:
	var views: Array = []
	for n: Node in tree.root.find_children("*", "WorldView", true, false):
		var v := n as WorldView
		if v != null and v.is_visible_in_tree():
			views.append([v.viewport, v.world])
	var s := split(await measure(tree, views))
	print(text(label, s))
	return s


## The renderer's counts for the frame as it stands, for `views`, each a pair
## [viewport, the 3D root its outline passes are found under]. All but
## `without` come from the same frame; `without` is the views' on-screen
## triangles in a frame with the outline passes cut out.
static func measure(tree: SceneTree, views: Array) -> Dictionary:
	await _settle(tree)
	const VISIBLE := Viewport.RENDER_INFO_TYPE_VISIBLE
	const SHADOW := Viewport.RENDER_INFO_TYPE_SHADOW
	const PRIMITIVES := Viewport.RENDER_INFO_PRIMITIVES_IN_FRAME
	const CALLS := Viewport.RENDER_INFO_DRAW_CALLS_IN_FRAME
	var m := {
		"frame": RenderingServer.get_rendering_info(
			RenderingServer.RENDERING_INFO_TOTAL_PRIMITIVES_IN_FRAME),
		"frame_calls": RenderingServer.get_rendering_info(
			RenderingServer.RENDERING_INFO_TOTAL_DRAW_CALLS_IN_FRAME),
		"with": _sum(views, VISIBLE, PRIMITIVES),
		"calls": _sum(views, VISIBLE, CALLS),
		"shadow": _sum(views, SHADOW, PRIMITIVES),
		"shadow_calls": _sum(views, SHADOW, CALLS),
	}
	m["without"] = m["with"]
	var held := _strip(views)
	if not held.is_empty():
		await _settle(tree)
		m["without"] = _sum(views, VISIBLE, PRIMITIVES)
		_restore(held)
		await _settle(tree)
	return m


## The split of `measure`'s counts: mesh + outline + shadow + other = total,
## and draw_calls (the world views', shadow passes included) + other_draw_calls
## = frame_draw_calls.
static func split(m: Dictionary) -> Dictionary:
	var mesh := int(m["without"])
	var outline := int(m["with"]) - mesh
	var shadow := int(m["shadow"])
	var calls := int(m["calls"]) + int(m["shadow_calls"])
	return {"total": int(m["frame"]), "mesh": mesh, "outline": outline, "shadow": shadow,
		"other": int(m["frame"]) - mesh - outline - shadow, "draw_calls": calls,
		"other_draw_calls": int(m["frame_calls"]) - calls, "frame_draw_calls": int(m["frame_calls"])}


## `split`'s figures as the `budget` line.
static func text(label: String, s: Dictionary) -> String:
	return "budget: %s: %d triangles (%d mesh + %d outline passes); %s; %s; %s; frame %s" % [
		label, s["mesh"] + s["outline"], s["mesh"], s["outline"],
		"%d triangles in shadows" % s["shadow"],
		"%d draw calls, shadow passes included" % s["draw_calls"],
		"%d triangles and %d draw calls in other views" % [s["other"], s["other_draw_calls"]],
		"%d triangles, %d draw calls" % [s["total"], s["frame_draw_calls"]]]


static func _sum(views: Array, type: Viewport.RenderInfoType, info: Viewport.RenderInfo) -> int:
	var n := 0
	for pair: Array in views:
		n += (pair[0] as Viewport).get_render_info(type, info)
	return n


static func _settle(tree: SceneTree) -> void:
	for i in 3:
		await tree.process_frame
	await RenderingServer.frame_post_draw


## Cuts every outline pass out of the views' materials; the pairs to put back.
static func _strip(views: Array) -> Array:
	var held: Array = []
	var seen := {}
	for pair: Array in views:
		var meshes: Array[Node] = (pair[1] as Node).find_children("*", "MeshInstance3D", true, false)
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
					if next != null and is_outline(next) and not seen.has(m):
						seen[m] = true
						held.append([m, next])
						m.next_pass = next.next_pass
					m = m.next_pass
	return held


static func _restore(held: Array) -> void:
	for h: Array in held:
		var m := h[0] as Material
		m.next_pass = h[1] as Material


## Whether `m` is an outline pass: an inverted hull, a shader that culls its
## front faces (outline, kit_outline, creature_outline, law_fx_ink).
static func is_outline(m: Material) -> bool:
	var s := m as ShaderMaterial
	if s == null or s.shader == null:
		return false
	var mode := RegEx.create_from_string("(?m)^\\s*render_mode\\s+([^;]*);").search(s.shader.code)
	return mode != null and "cull_front" in mode.get_string(1).replace(" ", "").split(",")
