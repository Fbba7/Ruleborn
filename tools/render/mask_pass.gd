extends RefCounted
## The mask pass (3D0-M2-mask-tool): run by tools/render/mask.py after a
## shot script has drawn its still, in place of the shot's own quit(). It
## draws the same frame again several ways and writes each to MASK_OUT:
##
## - `beauty.png`: the frame as the shot left it.
## - `ui_a.png`, `ui_b.png`: the frame with the 3D world replaced by flat red,
##   then flat green; where the two agree, the interface covers the world.
## - `world.png`: the 3D world alone, no interface and no 2D markers.
## - `behind.png`: the same without the figures: the ground behind them.
## - `markers.png`: the 2D markers alone (FxAnchors), on a clear background.
## - `id.png`: every 3D thing a flat colour that codes what it is: red and
##   green the class (class // 4 and class % 4, each n * 64 + 32), blue the
##   index (a figure's number, or the tile's kind; n * 28 + 14), written as
##   they are (no sRGB step), so each arrives within a few levels. A figure
##   keeps its ink outline, drawn in its own code.
## - `marks3d.png`: the 3D markers alone (rings, sight edge, overlay,
##   effects) in their own look, on black.
## - `solo_c<i>.png`, `solo_g<i>.png`: each figure alone, flat, for its
##   whole outline even where something hides it.
## - `mask.json`: the frame's size, each figure's projected bounds, head,
##   feet and tile, the vault, the exit and the shot's settings.
##
## tools/render/measure.py reads them. docs/art/3d-quality/mask.md is the
## method and its checks.

## The classes of `id.png`, as measure.py reads them.
const BACKGROUND := 0
const CREW := 1
const GUARD := 2
const VAULT := 3
const EXIT := 4
const MARKER := 5
const SHADOW := 6
const WALKABLE := 7
const PATH := 8
const GROUND_OTHER := 9
const CLIFF := 10
const WATER := 11
const DECORATION := 12
const BUILDING := 13
const PIECE := 14
const GUARD_SHADOW := 15

## The tile kinds the green channel carries on the statics.
const T_OUTSIDE := 0
const T_OPEN := 1
const T_WATER := 2
const T_BUILDING := 3
const T_BLOCKED := 4
const T_COVER := 5
const T_VAULT := 6
const T_GRAVEL := 7

## Features a figure walks through (RealmKit.F), drawn on walkable ground.
const COVER := [
	RealmKit.F.FOG_BANK,
	RealmKit.F.TALL_GRASS,
	RealmKit.F.FLOWER_MEADOW,
	RealmKit.F.SCREE,
	RealmKit.F.STEPPING_STONES,
	RealmKit.F.SHADE_CANOPY,
	RealmKit.F.ICE_SHEET,
	RealmKit.F.RAMP,
	RealmKit.F.STAIRS,
]

## The kit's own materials: buildings and dressing.
const KIT := ["kit_toon.gdshader", "kit_clear.gdshader"]
const TINTS := ["look_cloud.gdshader", "look_mist.gdshader", "law_fx_tint.gdshader"]

const SHADER := """
shader_type spatial;
render_mode unshaded, cull_disabled, shadows_disabled, fog_disabled, depth_draw_opaque;
uniform int mode = 0;
uniform vec3 code = vec3(0.0);
uniform sampler2D tiles : filter_nearest;
uniform vec2 grid = vec2(1.0);
uniform vec4 lanes[48];
uniform int lane_count = 0;
varying vec3 wpos;
varying vec3 wnorm;

// Class c and index i as a colour far from every other code: red and green
// carry c in steps of 64, blue i in steps of 28 (see measure.py's decode).
vec3 id_colour(float c, float i) {
	// The id viewport writes ALBEDO as it is, with no sRGB step on output.
	return vec3(floor(c / 4.0) * 64.0 + 32.0, mod(c, 4.0) * 64.0 + 32.0, i * 28.0 + 14.0) / 255.0;
}

void vertex() {
	wpos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	wnorm = normalize(mat3(MODEL_MATRIX) * NORMAL);
}

void fragment() {
	if (mode == 0) {
		ALBEDO = id_colour(code.x, code.y);
	} else {
		vec2 t = floor(wpos.xz + grid * 0.5);
		float kind = 0.0;
		if (t.x >= 0.0 && t.y >= 0.0 && t.x < grid.x && t.y < grid.y) {
			kind = floor(texture(tiles, (t + 0.5) / grid).r * 255.0 + 0.5);
		}
		float up = abs(wnorm.y);
		float cls;
		if (mode == 1) {
			// Ground: a cliff where it faces sideways, a path on a lane.
			cls = 9.0;
			if (up < 0.6) {
				cls = 10.0;
			} else if (kind == 7.0) {
				cls = 8.0;
			} else if (kind == 1.0 || kind == 5.0) {
				cls = 7.0;
				float best = 9.0;
				for (int i = 0; i < 48; i++) {
					if (i >= lane_count) {
						break;
					}
					vec2 a = lanes[i].xy;
					vec2 b = lanes[i].zw;
					vec2 ab = b - a;
					float h = clamp(dot(wpos.xz - a, ab) / max(dot(ab, ab), 1e-5), 0.0, 1.0);
					best = min(best, length(wpos.xz - a - ab * h));
				}
				if (best < 0.42) {
					cls = 8.0;
				}
			}
		} else {
			// The kit's pieces: a building on a building's tiles, else decoration.
			cls = kind == 3.0 ? 13.0 : 12.0;
		}
		ALBEDO = id_colour(cls, kind);
	}
}
"""

var tree: SceneTree
var view: WorldView
var frame: Viewport
var out := ""
## What the pass draws through, whichever view the screen shows: a heist or
## realm `WorldView`, a character screen's `StageHero` or a `UniverseView`.
var holder: Control
var vp: SubViewport
var cont: SubViewportContainer
var cam: Camera3D
var w3d: Node3D
## The kind of screen (measure.py's SCREENS): heist, realm, character,
## universe, or none when the screen draws no 3D world view.
var screen := "heist"
var _shader: Shader
var _tiles: ImageTexture
var _lanes := PackedVector4Array()
var _lane_count := 0
var _ui: Array = []
var _marks3d: Array = []
var _ink_shaders := {}
## A stage's figures: [solo name, figure, the table it stands on].
var _stage_figs: Array = []
## Whether the world view draws its crew and guards: a realm screen hides
## them (RealmScreen), and then the frame has no figures to measure.
var _figs_drawn := true
## A stage's own 2D children but its viewport: [item, visible].
var _own2d: Array = []
## The nodes a universe screen's rated island is drawn under.
var _home_roots: Array = []


func run(on: SceneTree) -> void:
	tree = on
	out = OS.get_environment("MASK_OUT")
	DirAccess.make_dir_recursive_absolute(out)
	for t in tree.get_processed_tweens():
		t.pause()
	# A view counts only when it is drawn: an offscreen one (the
	# Observatory's card pictures) is not the screen's world.
	var drawn := _drawn("WorldView")
	if drawn != null:
		await _run_world(drawn as WorldView)
		return
	drawn = _drawn("StageHero")
	if drawn != null:
		await _run_stage(drawn, "character")
		return
	drawn = _drawn("UniverseView")
	if drawn != null:
		await _run_stage(drawn, "universe")
		return
	await _run_none()


## The largest shown view of class `type` in the shot, or null.
func _drawn(type: String) -> Control:
	var best: Control = null
	for n in tree.root.find_children("*", type, true, false):
		var c := n as Control
		if c == null or not c.is_visible_in_tree():
			continue
		if best == null or c.get_global_rect().get_area() > best.get_global_rect().get_area():
			best = c
	return best


## A heist or realm screen: the world view's grid, kit and figures.
func _run_world(v: WorldView) -> void:
	view = v
	holder = v
	vp = v.viewport
	cont = v.container
	cam = v.camera
	w3d = v.world
	screen = "heist" if v.heist else "realm"
	_figs_drawn = v.actors.is_visible_in_tree()
	frame = view.get_viewport()
	view.process_mode = Node.PROCESS_MODE_DISABLED
	if OS.get_environment("TILES") != "":
		# A camera between zoom levels (the plan's 11 tiles): zoom 1 frames
		# FOLLOW_TILES across, zoom 2 CLOSE_TILES, and the view lerps between.
		var near := WorldView.CLOSE_TILES
		var far := WorldView.FOLLOW_TILES
		var tiles := clampf(float(OS.get_environment("TILES")), near, far)
		view._zoom_f = 1.0 + (far - tiles) / (far - near)
		view._frame_camera()
	await _save("beauty")
	_list_ui()
	var env := view.environment
	env.fog_enabled = false
	env.glow_enabled = false
	env.adjustment_enabled = false
	var hidden3d := _hide_3d()
	view.anchors.visible = false
	var keep_bg := [env.background_mode, env.background_color]
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(1, 0, 0)
	await _save("ui_a")
	env.background_color = Color(0, 1, 0)
	await _save("ui_b")
	env.background_mode = keep_bg[0]
	env.background_color = keep_bg[1]
	_unhide(hidden3d)
	_set_ui(false)
	await _save("world")
	var seen := {}
	for a: Node3D in view._crew + view._guards:
		seen[a] = a.visible
		a.visible = false
	await _save("behind")
	for a: Node3D in view._crew + view._guards:
		a.visible = seen[a]
	view.container.modulate.a = 0.0
	view.anchors.visible = true
	frame.transparent_bg = true
	await _save("markers")
	frame.transparent_bg = false
	view.anchors.visible = false
	view.container.modulate.a = 1.0
	_write_json()
	_flatten()
	await _save("id")
	await _marks_alone()
	await _solos()


## The 3D markers alone, in their own look.
func _marks_alone() -> void:
	var shown: Array = []
	for n in w3d.find_children("*", "GeometryInstance3D", true, false):
		if n.visible and not (n in _marks3d):
			shown.append(n)
			n.visible = false
	for g: GeometryInstance3D in _marks3d:
		g.visible = true
	await _save("marks3d")
	for g: GeometryInstance3D in _marks3d:
		g.visible = false
	for n: GeometryInstance3D in shown:
		n.visible = true


## Draw the frame and save it as `name`.png.
func _save(name: String) -> void:
	for i in 3:
		await tree.process_frame
	await RenderingServer.frame_post_draw
	var img := frame.get_texture().get_image()
	# A shot on the root window is drawn at the window's size, which
	# project.godot halves; the masks keep the frame's own units (as a
	# heist shot's SubViewport does), scaled with no blending so the id
	# colours stay exact.
	var want := Vector2i(frame.get_visible_rect().size)
	if img.get_size() != want:
		img.resize(want.x, want.y, Image.INTERPOLATE_NEAREST)
	img.save_png(out.path_join(name + ".png"))
	print("mask: saved ", name)


## The frame's 2D items that are not the world view: the interface.
func _list_ui() -> void:
	for n in frame.find_children("*", "CanvasItem", true, false):
		var c := n as CanvasItem
		if c == holder or holder.is_ancestor_of(c):
			continue
		_ui.append([c, c.is_ancestor_of(holder), c.modulate, c.self_modulate])


## The interface see-through (`shown` false) or back as it was.
func _set_ui(shown: bool) -> void:
	for e: Array in _ui:
		var c: CanvasItem = e[0]
		if e[1]:
			c.self_modulate = e[3] if shown else Color(1, 1, 1, 0)
		else:
			c.modulate = e[2] if shown else Color(1, 1, 1, 0)


## Hide every 3D thing under the world but the camera and the environment.
func _hide_3d() -> Array:
	var was: Array = []
	for n in w3d.get_children():
		if n is Node3D and n != cam and n.visible:
			was.append(n)
			(n as Node3D).visible = false
	return was


func _unhide(nodes: Array) -> void:
	for n: Node3D in nodes:
		n.visible = true


func _material(m: int, c: Vector3) -> ShaderMaterial:
	var mat := ShaderMaterial.new()
	mat.shader = _shader
	mat.set_shader_parameter("mode", m)
	mat.set_shader_parameter("code", c)
	if m != 0:
		mat.set_shader_parameter("tiles", _tiles)
		mat.set_shader_parameter("grid", Vector2(view._size))
		mat.set_shader_parameter("lane_count", _lane_count)
		if _lane_count > 0:
			mat.set_shader_parameter("lanes", _lanes)
	return mat


## Each tile's kind, as the statics' material reads it.
func _tile_texture() -> void:
	var size: Vector2i = view._size
	var img := Image.create(maxi(1, size.x), maxi(1, size.y), false, Image.FORMAT_R8)
	for y in size.y:
		for x in size.x:
			img.set_pixel(x, y, Color(_tile_kind(Vector2i(x, y)) / 255.0, 0, 0))
	_tiles = ImageTexture.create_from_image(img)


func _tile_kind(t: Vector2i) -> int:
	var i: int = t.y * view._size.x + t.x
	var f: int = view._features[i] if i < view._features.size() else 0
	var s: int = view._surfaces[i] if i < view._surfaces.size() else 0
	var kind := T_BLOCKED
	if f in COVER:
		kind = T_COVER
	elif f == RealmKit.F.OPEN:
		kind = T_OPEN
	if f == RealmKit.F.GRAVEL_PATH:
		kind = T_GRAVEL
	if f in RealmKit.WET or s == KitGround.WATER:
		kind = T_WATER
	if f == RealmKit.F.VAULT:
		kind = T_VAULT
	if f == RealmKit.F.BUILDING:
		kind = T_BUILDING
	return kind


## Every 3D thing a flat colour by what it is; no sky, fog, outlines or
## edge smoothing.
func _flatten() -> void:
	_tile_texture()
	_flat_env(view.environment)
	for n in view.world.find_children("*", "GeometryInstance3D", true, false):
		var g := n as GeometryInstance3D
		var m := g.material_override as ShaderMaterial
		if (
			m != null
			and m.shader != null
			and m.shader.resource_path.ends_with("kit_ground.gdshader")
		):
			var lanes: Variant = m.get_shader_parameter("lanes")
			var count: Variant = m.get_shader_parameter("lane_count")
			_lanes = lanes if lanes != null else _lanes
			_lane_count = int(count) if count != null else 0
	for n in view.world.find_children("*", "GeometryInstance3D", true, false):
		_classify(n as GeometryInstance3D)


## A woven law's signature (LawFx), which a stage view hangs under its
## world, not under an `effects` node: a marker, like T5's effects.
func _in_law_fx(g: Node) -> bool:
	var n := g.get_parent()
	while n != null and not n is LawFx:
		n = n.get_parent()
	return n != null


func _classify(g: GeometryInstance3D) -> void:
	g.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var cls := Vector3(-1, 0, 0)
	var mode := 0
	for k in view._crew.size():
		if view._crew[k] == g or view._crew[k].is_ancestor_of(g):
			cls = Vector3(SHADOW if _is_shadow(view._crew[k], g) else CREW, k, 0)
	for k in view._guards.size():
		if view._guards[k] == g or view._guards[k].is_ancestor_of(g):
			cls = Vector3(GUARD_SHADOW if _is_shadow(view._guards[k], g) else GUARD, k, 1)
	if cls.x < 0:
		var path := str(view.world.get_path_to(g))
		var shader_path := ""
		var m := g.material_override as ShaderMaterial
		if m != null and m.shader != null:
			shader_path = m.shader.resource_path
		if g == view._vault:
			cls = Vector3(VAULT, 0, 0)
		elif g == view._skiff:
			cls = Vector3(EXIT, 0, 0)
		elif g == view._pieces or g == view._walls:
			cls = Vector3(PIECE, 0, 0)
		elif (
			g == view.overlay
			or g == view.marks_node
			or g == view.sight_edge
			or g == view._rings
			or view.effects.is_ancestor_of(g)
			or view.actors.is_ancestor_of(g)
			or _in_law_fx(g)
		):
			# 3D markers keep their own look for marks3d.png; not in id.png.
			_marks3d.append(g)
			g.visible = false
			return
		elif _town_building(g):
			# The town's houses (StageTown) stand on open tiles round the
			# island: buildings by what they are, not by the tile below.
			cls = Vector3(BUILDING, 0, 0)
		elif _town_figure(g):
			# The town's residents and workers (StageTown): life in the
			# realm, not figures the player steers; their blobs with them.
			cls = Vector3(DECORATION, 0, 0)
		elif _in_layers(g) and not shader_path.get_file() in KIT:
			# A screen's own layer over the realm (tiles, ghosts, the scout's
			# mist, the town's smoke and chosen ring): markers, not world.
			_marks3d.append(g)
			g.visible = false
			return
		elif (m != null and m == view.look.sky_material) or shader_path.get_file() in TINTS:
			# The sky, its clouds, the mist under the island, a law's tint.
			g.visible = false
			return
		elif shader_path.get_file() in ["water.gdshader", "look_fall.gdshader"]:
			cls = Vector3(WATER, 0, 0)
		elif shader_path.ends_with("kit_ground.gdshader"):
			mode = 1
		elif shader_path.get_file() in KIT:
			mode = 2
		elif view.statics.is_ancestor_of(g):
			# The island round the grid (WorldLook): ground by its normal.
			mode = 1
		else:
			print("mask: unclassed ", path, " ", shader_path)
			cls = Vector3(MARKER, 0, 0)
	if g is Label3D or g is SpriteBase3D:
		# Words and sprites in the world take no flat colour; left out.
		g.visible = false
		return
	var ink := _outline_of(g) if cls.x == CREW or cls.x == GUARD else null
	g.material_override = _material(mode, cls)
	if ink != null:
		# The figure's ink line is part of what the player sees of it: drawn
		# in the figure's own id colour, so heights and covering include it.
		ink.set_shader_parameter("ink", _id_colour(int(cls.x), int(cls.y)))
		(g.material_override as ShaderMaterial).next_pass = ink
	g.material_overlay = null
	if g is MeshInstance3D:
		var mi := g as MeshInstance3D
		for s in mi.get_surface_override_material_count():
			mi.set_surface_override_material(s, null)


## Whether `g` is under the screen's layers over the realm (StageView).
func _in_layers(g: Node) -> bool:
	var layers: Variant = view.get("layers")
	return layers is Node and (layers as Node).is_ancestor_of(g)


## Whether `g` is a town's houses or their trim (StageTown's own meshes).
func _town_building(g: Node) -> bool:
	var town := g.get_parent()
	return _in_layers(g) and town is StageTown and g in [town.get("houses"), town.get("trim")]


## Whether `g` is part of a town's resident or worker (StageTown).
func _town_figure(g: Node) -> bool:
	if not _in_layers(g):
		return false
	var n := g.get_parent()
	while n != null and n != view.get("layers"):
		if n.get_script() != null and str(n.get_script().get_global_name()) == "StageTown":
			break
		if (
			n.has_meta("model")
			or n.name == &"Body"
			or n.find_child("Skeleton3D", true, false) != null
		):
			return true
		n = n.get_parent()
	return false


## A copy of the ink-outline pass on `g`'s own materials, its colour taken
## as written (no sRGB step), or null when it has none.
func _outline_of(g: GeometryInstance3D) -> ShaderMaterial:
	var mats: Array = [g.material_override]
	if g is MeshInstance3D:
		var mi := g as MeshInstance3D
		for s in mi.get_surface_override_material_count():
			mats.append(mi.get_surface_override_material(s))
		if mi.mesh != null:
			for s in mi.mesh.get_surface_count():
				mats.append(mi.mesh.surface_get_material(s))
	for m0: Variant in mats:
		var m := m0 as Material
		while m != null:
			var sm := m as ShaderMaterial
			if sm != null and sm.shader != null and sm.shader.resource_path.contains("outline"):
				var src := sm.shader.resource_path
				if not _ink_shaders.has(src):
					var sh := Shader.new()
					sh.code = sm.shader.code.replace(
						"uniform vec4 ink : source_color", "uniform vec4 ink"
					)
					_ink_shaders[src] = sh
				var o := sm.duplicate() as ShaderMaterial
				o.shader = _ink_shaders[src]
				for u: String in ["width_px", "far_ppm", "far_width", "depth_push", "smooth_push"]:
					var v: Variant = sm.get_shader_parameter(u)
					if v != null:
						o.set_shader_parameter(u, v)
				o.next_pass = null
				return o
			m = m.next_pass
	return null


## The id colour of class `c`, index `i`, as the shader writes it.
func _id_colour(c: int, i: int) -> Color:
	return Color(((c / 4) * 64 + 32) / 255.0, ((c % 4) * 64 + 32) / 255.0, (i * 28 + 14) / 255.0)


func _is_shadow(actor: Node3D, g: Node) -> bool:
	var low := str(g.name).to_lower()
	return low.contains("blob") or low.contains("shadow") or actor.get_node_or_null("Blob") == g


## Each figure alone, flat, for its whole outline.
func _solos() -> void:
	if not _figs_drawn:
		return
	_hide_3d()
	view.actors.visible = true
	var figures: Array = []
	for k in view._crew.size():
		figures.append(["c%d" % k, view._crew[k]])
	for k in view._guards.size():
		figures.append(["g%d" % k, view._guards[k]])
	var shown := {}
	for c in view.actors.get_children():
		shown[c] = (c as Node3D).visible
		(c as Node3D).visible = false
	for f: Array in figures:
		var a: Node3D = f[1]
		if not shown.get(a, false):
			continue
		a.visible = true
		var shadows: Array = []
		for g in a.find_children("*", "GeometryInstance3D", true, false):
			if _is_shadow(a, g) and (g as Node3D).visible:
				shadows.append(g)
				(g as Node3D).visible = false
		await _save("solo_" + f[0])
		_unhide(shadows)
		a.visible = false


## Where a world point lands on the frame.
func _on_frame(p: Vector3) -> Vector2:
	var inner := cam.unproject_position(p)
	var sz := Vector2(vp.size)
	var local := inner * cont.size / sz
	return cont.get_global_transform_with_canvas() * local


func _bounds(a: Node3D) -> Dictionary:
	var lo := Vector2(INF, INF)
	var hi := Vector2(-INF, -INF)
	var lo_y := INF
	var hi_y := -INF
	for n in a.find_children("*", "VisualInstance3D", true, false):
		var g := n as VisualInstance3D
		if _is_shadow(a, g) or not g.is_visible_in_tree():
			continue
		var box: AABB = g.global_transform * g.get_aabb()
		lo_y = minf(lo_y, box.position.y)
		hi_y = maxf(hi_y, box.end.y)
		for i in 8:
			var s := _on_frame(box.get_endpoint(i))
			lo = lo.min(s)
			hi = hi.max(s)
	if lo.x == INF:
		return {}
	return {"rect": [lo.x, lo.y, hi.x - lo.x, hi.y - lo.y], "world_low": lo_y, "world_high": hi_y}


func _figure(a: Node3D, kind: String, k: int, data: Dictionary) -> Dictionary:
	var d := _bounds(a)
	d["kind"] = kind
	d["index"] = k
	d["visible"] = a.visible
	d["role"] = str(a.get_meta("role", "guard"))
	d["feet"] = _v(_on_frame(a.global_position))
	d["head"] = _v(_on_frame(a.global_position + Vector3(0, float(a.get_meta("head", 1.0)), 0)))
	d["world"] = [a.global_position.x, a.global_position.y, a.global_position.z]
	if d.has("world_high"):
		# The bounds' height stood up at the figure's spot, facing the camera:
		# the plan's "projected bounds" height, with neither the box's depth
		# nor the camera's pitch in it.
		var foot := Vector3(a.global_position.x, d["world_low"], a.global_position.z)
		var up := cam.global_transform.basis.y.normalized()
		var top := foot + up * (float(d["world_high"]) - float(d["world_low"]))
		d["span"] = _on_frame(foot).distance_to(_on_frame(top))
	for key: String in ["at", "down", "state", "hp"]:
		if data.has(key):
			d[key] = data[key] if not (data[key] is Vector2i) else [data[key].x, data[key].y]
	return d


func _v(p: Vector2) -> Array:
	return [p.x, p.y]


func _write_json() -> void:
	var w: Node = view.get_parent()
	while w != null and not ("controller" in w):
		w = w.get_parent()
	var control: Variant = w.get("controller") if w != null else null
	# A realm's controller holds no heist world.
	var world_data: Variant = null
	if control is Object and "world" in control:
		world_data = control.get("world")
	var heist_world: bool = world_data is Object and world_data.has_method("crew")
	var crew: Array = world_data.crew() if heist_world else []
	var guards: Array = world_data.guards() if heist_world else []
	var figures: Array = []
	for k in view._crew.size() if _figs_drawn else 0:
		figures.append(_figure(view._crew[k], "crew", k, crew[k] if k < crew.size() else {}))
	for k in view._guards.size() if _figs_drawn else 0:
		figures.append(_figure(view._guards[k], "guard", k, guards[k] if k < guards.size() else {}))
	var r := view.get_global_rect()
	var d := {
		"screen": screen,
		"frame": [frame.get_visible_rect().size.x, frame.get_visible_rect().size.y],
		"view_rect": [r.position.x, r.position.y, r.size.x, r.size.y],
		"figures": figures,
		"chosen": view.chosen,
		"zoom": view.zoom,
		"zoom_f": view._zoom_f,
		"size": [view._size.x, view._size.y],
		"env": _env_keys(),
	}
	if view._vault != null and view._vault.is_inside_tree():
		d["vault"] = _bounds_of(view._vault)
	if view._skiff != null and view._skiff.visible:
		d["exit"] = _bounds_of(view._skiff)
	if world_data is Object and world_data.has_method("vault"):
		var v: Dictionary = world_data.vault()
		if v.has("at"):
			d["vault_at"] = [v["at"].x, v["at"].y]
	_store(d)


func _bounds_of(g: VisualInstance3D) -> Dictionary:
	var lo := Vector2(INF, INF)
	var hi := Vector2(-INF, -INF)
	var box: AABB = g.global_transform * g.get_aabb()
	for i in 8:
		var s := _on_frame(box.get_endpoint(i))
		lo = lo.min(s)
		hi = hi.max(s)
	return {
		"rect": [lo.x, lo.y, hi.x - lo.x, hi.y - lo.y], "centre": _v(_on_frame(box.get_center()))
	}


## A character or universe screen: a stage's own viewport, no grid. Its
## figures are classed crew (kind "character"), their shadow discs shadow,
## everything else ground, kit buildings and the universe's movers flat.
func _run_stage(v: Control, kind: String) -> void:
	screen = kind
	holder = v
	vp = v.get("viewport")
	cont = v.get("container")
	cam = v.get("camera")
	w3d = v.get("world")
	frame = v.get_viewport()
	v.process_mode = Node.PROCESS_MODE_DISABLED
	if kind == "character":
		var figs: Array = v.get("figures")
		var tables: Array = v.get("tables")
		for k in figs.size():
			_stage_figs.append(["h%d" % k, figs[k], tables[k] if k < tables.size() else figs[k]])
	for c in v.get_children():
		if c is CanvasItem and c != cont:
			_own2d.append([c, (c as CanvasItem).visible])
	await _save("beauty")
	_list_ui()
	var env := _env_of()
	if env != null:
		env.fog_enabled = false
		env.glow_enabled = false
		env.adjustment_enabled = false
	# The universe's pins are its interface (they stay over the cover);
	# a stage's foot fade is its world (hidden, the cover stands for it).
	_own_2d(kind == "universe")
	var cover := ColorRect.new()
	cover.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	cover.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cont.add_child(cover)
	cover.color = Color(1, 0, 0)
	await _save("ui_a")
	cover.color = Color(0, 1, 0)
	await _save("ui_b")
	cont.remove_child(cover)
	cover.free()
	_set_ui(false)
	_own_2d(kind == "character")
	await _save("world")
	for f: Array in _stage_figs:
		(f[1] as Node3D).visible = false
	await _save("behind")
	for f: Array in _stage_figs:
		(f[1] as Node3D).visible = true
	_own_2d(false)
	cont.modulate.a = 0.0
	frame.transparent_bg = true
	await _save("markers")
	frame.transparent_bg = false
	cont.modulate.a = 1.0
	_write_stage_json()
	_flatten_stage(env)
	await _save("id")
	await _marks_alone()
	await _solos_stage()


## A screen with no 3D world view drawn: the whole frame is interface.
func _run_none() -> void:
	screen = "none"
	frame = tree.root
	await _save("beauty")
	var beauty := Image.load_from_file(out.path_join("beauty.png"))
	for name: String in ["ui_a", "ui_b"]:
		beauty.save_png(out.path_join(name + ".png"))
	var size := beauty.get_size()
	var black := Image.create(size.x, size.y, false, Image.FORMAT_RGBA8)
	black.fill(Color.BLACK)
	for name: String in ["world", "behind", "id"]:
		black.save_png(out.path_join(name + ".png"))
	var clear := Image.create(size.x, size.y, false, Image.FORMAT_RGBA8)
	clear.fill(Color(0, 0, 0, 0))
	clear.save_png(out.path_join("markers.png"))
	var d := {
		"screen": screen,
		"frame": [size.x, size.y],
		"view_rect": [0, 0, 0, 0],
		"figures": [],
		"chosen": -1,
		"zoom": 0,
		"env": _env_keys()
	}
	_store(d)
	print("mask: no 3D world view drawn; screen none")


## The stage's environment, or null.
func _env_of() -> Environment:
	var e: Variant = holder.get("environment")
	if e is Environment:
		return e
	for n in w3d.find_children("*", "WorldEnvironment", true, false):
		return (n as WorldEnvironment).environment
	return null


## The stage's own 2D children shown as they were (`shown`) or hidden.
func _own_2d(shown: bool) -> void:
	for e: Array in _own2d:
		(e[0] as CanvasItem).visible = e[1] if shown else false


## The id frame's settings: the flat shader, black behind, no tone curve
## and no edge smoothing.
func _flat_env(env: Environment) -> void:
	_shader = Shader.new()
	_shader.code = SHADER
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color.BLACK
	env.tonemap_mode = Environment.TONE_MAPPER_LINEAR
	env.tonemap_exposure = 1.0
	env.tonemap_white = 1.0
	vp.msaa_3d = Viewport.MSAA_DISABLED
	vp.screen_space_aa = Viewport.SCREEN_SPACE_AA_DISABLED
	cont.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST


func _flatten_stage(env: Environment) -> void:
	if env == null:
		env = Environment.new()
		var node := WorldEnvironment.new()
		node.environment = env
		w3d.add_child(node)
	_flat_env(env)
	vp.transparent_bg = false
	RenderingServer.set_default_clear_color(Color.BLACK)
	_own_2d(false)
	if screen == "universe":
		_home_roots = _universe_home()
	for n in w3d.find_children("*", "GeometryInstance3D", true, false):
		_classify_stage(n as GeometryInstance3D)


## The island a universe screen's Q11 rates (`_home_id`), drawn with index
## 1. Over the whole universe the view draws merged copies (UniverseWhole):
## hidden, and the meshes they stand for shown, so its own can be told apart.
func _universe_home() -> Array:
	var u := holder as UniverseView
	var home := _home_id()
	if u.zoom == 0 and not u._whole.is_empty():
		for n in u.statics.find_children("*", "MeshInstance3D", true, false):
			if n.has_meta("whole"):
				n.visible = false
			elif UniverseWhole.LAYERS.any(n.has_meta):
				n.visible = true
	var citadel := u.statics.get_node_or_null("Citadel") if home == "heart" else null
	var roots: Array = [u._rocks.get(home), u._close.get(home), citadel]
	roots.append_array(u._lods.get(home, []))
	return roots.filter(func(r: Variant) -> bool: return r != null)


## The focused island's id when the view has one, else the Heart's.
func _home_id() -> String:
	var u := holder as UniverseView
	return u.focus_id if u.islands.has(u.focus_id) else "heart"


func _in_home(g: Node) -> bool:
	return _home_roots.any(func(r: Node) -> bool: return r == g or r.is_ancestor_of(g))


func _classify_stage(g: GeometryInstance3D) -> void:
	g.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	if g is Label3D or g is SpriteBase3D or not g.is_visible_in_tree():
		g.visible = false
		return
	var cls := Vector3(GROUND_OTHER, 0, 0)
	var shader_path := ""
	var m := g.material_override as ShaderMaterial
	if m != null and m.shader != null:
		shader_path = m.shader.resource_path
	var figure := false
	for k in _stage_figs.size():
		var fig: Node3D = _stage_figs[k][1]
		var table: Node3D = _stage_figs[k][2]
		if fig == g or fig.is_ancestor_of(g):
			figure = true
			cls = Vector3(SHADOW if _is_shadow(fig, g) else CREW, k, 0)
		elif (
			g.get_parent() == table
			and g is MeshInstance3D
			and (g as MeshInstance3D).mesh is PlaneMesh
		):
			# The stage's shadow disc (StageHeroFigure.shadow_disc): a quad
			# whose radial fade is near clear past 0.4 of its size; drawn
			# flat as the disc that shows.
			figure = true
			cls = Vector3(SHADOW, k, 0)
			var disc := CylinderMesh.new()
			disc.top_radius = 0.4
			disc.bottom_radius = 0.4
			disc.height = 0.002
			(g as MeshInstance3D).mesh = disc
	if not figure:
		var movers: Variant = holder.get("movers")
		var people := w3d.get_node_or_null("Characters")
		if (
			shader_path.ends_with("universe_dome.gdshader")
			or shader_path.ends_with("universe_veil.gdshader")
			or shader_path.ends_with("universe_glow.gdshader")
			or shader_path.ends_with("universe_galaxy.gdshader")
			or shader_path.ends_with("look_cloud.gdshader")
			or shader_path.ends_with("stage_mist.gdshader")
		):
			# Glass, veils, glows, clouds and the galaxy behind the
			# universe (StarSky): light and sky, not things.
			g.visible = false
			return
		var moving := movers is Node and (movers as Node).is_ancestor_of(g)
		if moving or (people != null and people.is_ancestor_of(g)):
			cls = Vector3(DECORATION, 0, 0)
		elif shader_path.get_file() in KIT:
			cls = Vector3(BUILDING, 0, 0)
		if _in_home(g):
			cls.y = 1
	var ink := _outline_of(g) if cls.x == CREW else null
	g.material_override = _material(0, cls)
	if ink != null:
		ink.set_shader_parameter("ink", _id_colour(int(cls.x), int(cls.y)))
		(g.material_override as ShaderMaterial).next_pass = ink
	g.material_overlay = null
	if g is MeshInstance3D:
		var mi := g as MeshInstance3D
		for s in mi.get_surface_override_material_count():
			mi.set_surface_override_material(s, null)


## Each figure of a stage alone, flat, without its table or shadow.
func _solos_stage() -> void:
	var all := _hide_3d()
	for f: Array in _stage_figs:
		var fig: Node3D = f[1]
		var table: Node3D = f[2]
		var off: Array = []
		if table != fig:
			for c in table.get_children():
				if c is Node3D and c != fig and (c as Node3D).visible:
					off.append(c)
					(c as Node3D).visible = false
		table.visible = true
		for g in fig.find_children("*", "GeometryInstance3D", true, false):
			if _is_shadow(fig, g) and (g as Node3D).visible:
				off.append(g)
				(g as Node3D).visible = false
		await _save("solo_" + str(f[0]))
		_unhide(off)
		table.visible = false
	_unhide(all)


func _write_stage_json() -> void:
	var figures: Array = []
	for k in _stage_figs.size():
		var fig: Node3D = _stage_figs[k][1]
		var d := _figure(fig, "character", k, {})
		d["role"] = str(fig.get_meta("kind", "character"))
		figures.append(d)
	var r := holder.get_global_rect()
	var z: Variant = holder.get("zoom")
	# A stage chooses none of its characters (Q11 rates each); a universe
	# screen names the island Q11 rates.
	_store(
		{
			"screen": screen,
			"frame": [frame.get_visible_rect().size.x, frame.get_visible_rect().size.y],
			"view_rect": [r.position.x, r.position.y, r.size.x, r.size.y],
			"figures": figures,
			"chosen": -1,
			"zoom": int(z) if z != null else 0,
			"island": _home_id() if screen == "universe" else "",
			"env": _env_keys(),
		}
	)


func _env_keys() -> Dictionary:
	var e := {}
	for key: String in [
		"MOMENT", "ZOOM", "HOUR", "HIDE", "ORTHO", "FRAME_H", "SHOT", "TAB", "SCREEN"
	]:
		e[key] = OS.get_environment(key)
	return e


func _store(d: Dictionary) -> void:
	var f := FileAccess.open(out.path_join("mask.json"), FileAccess.WRITE)
	f.store_string(JSON.stringify(d, "  "))
	f.close()
