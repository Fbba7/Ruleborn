extends SceneTree
## BudgetSplit's tests, on the real renderer, since the counts it splits are
## the renderer's (headless they all read 0):
##   bash tools/render/shoot.sh client/tests/shots/budget_split_tests.gd out.png 256 256
## A bare WorldView (its look, sun and camera, no realm) holds one box at a
## time, 12 triangles, with an inverted-hull pass behind it; the box's hull
## is 12 more. Prints `ok` or `not ok` per check and quits 1 on any failure.

const BOX := 12

var _failed := 0


func _initialize() -> void:
	_go()


func check(name: String, passed: bool, detail := "") -> void:
	if not passed:
		_failed += 1
	print("%s - %s%s" % ["ok" if passed else "not ok", name, "" if detail == "" else "  # " + detail])


func _go() -> void:
	_classifies()
	var view := WorldView.new()
	view.size = Vector2(256, 256)
	root.add_child(view)
	view.set_sky_hour(12)
	await process_frame
	view.camera.size = 6.0
	view.camera.look_at_from_position(Vector3(0, 6, 8), Vector3.ZERO)

	# The law FX ink hull (law_fx.gd's cull_front next pass) is an outline
	# pass, as the outline shaders are; the box casts no shadow here.
	var ink := _box(view, "res://world/law_fx_ink.gdshader", false)
	var s := await BudgetSplit.line(self, "ink hull")
	check("the law FX ink hull counts as an outline pass", s["outline"] == BOX, str(s))
	var bare_other: int = s["other"]
	ink.queue_free()

	# A hull behind a box that casts a shadow: the opaque hull is drawn into
	# the shadow map too, and those triangles are shadows, not outline passes.
	var box := _box(view, "res://world/outline.gdshader", true)
	s = await BudgetSplit.line(self, "outline hull, shadow on")
	check("the outline passes count only what is drawn on screen", s["outline"] == BOX, str(s))
	check("the shadow passes are reported as shadows", int(s.get("shadow", 0)) >= 2 * BOX, str(s))
	check("other views hold no shadow pass of a world view (the same as with no shadow)",
		s["other"] == bare_other, "%d, %d with no shadow; %s" % [s["other"], bare_other, s])
	check("mesh + outline + shadows + other views is the frame's total",
		s["mesh"] + s["outline"] + int(s.get("shadow", 0)) + s["other"] == s["total"], str(s))
	check("the world views' and other views' draw calls are the frame's",
		int(s["draw_calls"]) + int(s.get("other_draw_calls", -1))
			== int(s.get("frame_draw_calls", -2)), str(s))
	check("the line names the shadow figure as shadows", _has("text")
		and str(_split().call("text", "t", s)).contains("%d triangles in shadows" % s.get("shadow", -1)))
	box.queue_free()

	await process_frame
	view.viewport.get_texture().get_image().save_png(OS.get_environment("SHOT"))
	print("%d failed" % _failed)
	quit(1 if _failed > 0 else 0)


## Every inverted-hull shader in client/world (render_mode cull_front) is an
## outline pass; a lit surface's shader is not.
func _classifies() -> void:
	if not _has("is_outline"):
		check("BudgetSplit.is_outline exists", false)
		return
	var hulls := 0
	for f: String in DirAccess.get_files_at("res://world"):
		if not f.ends_with(".gdshader"):
			continue
		var sm := ShaderMaterial.new()
		sm.shader = load("res://world/" + f)
		var cull_front := RegEx.create_from_string("render_mode[^;]*cull_front")
		var hull := cull_front.search(sm.shader.code) != null
		hulls += int(hull)
		check("is_outline(%s) is %s" % [f, hull], _split().call("is_outline", sm) == hull)
	check("four hull shaders: outline, kit_outline, creature_outline, law_fx_ink",
		hulls == 4, str(hulls))
	check("a StandardMaterial3D is not an outline pass",
		not _split().call("is_outline", StandardMaterial3D.new()))


## BudgetSplit, called by name, so this file still runs against the version
## before is_outline and text existed (and fails there).
func _split() -> Script:
	return BudgetSplit


func _has(method: String) -> bool:
	for m: Dictionary in _split().get_script_method_list():
		if m["name"] == method:
			return true
	return false


func _box(view: WorldView, hull_shader: String, shadow: bool) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = BoxMesh.new()
	var lit := StandardMaterial3D.new()
	var hull := ShaderMaterial.new()
	hull.shader = load(hull_shader)
	lit.next_pass = hull
	mi.material_override = lit
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON if shadow \
		else GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	view.world.add_child(mi)
	return mi
