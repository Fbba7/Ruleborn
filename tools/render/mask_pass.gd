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
## - `id.png`: every 3D thing a flat colour that codes what it is: red is
##   the class, green the index (a figure's number, or the tile's kind),
##   blue the side (crew or guard); each channel is n * 16 + 8.
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

vec3 lin(vec3 n) {
	vec3 c = (n * 16.0 + 8.0) / 255.0;
	return mix(c / 12.92, pow((c + 0.055) / 1.055, vec3(2.4)), step(vec3(0.04045), c));
}

void vertex() {
	wpos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	wnorm = normalize(mat3(MODEL_MATRIX) * NORMAL);
}

void fragment() {
	if (mode == 0) {
		ALBEDO = lin(code);
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
		ALBEDO = lin(vec3(cls, kind, 0.0));
	}
}
"""

var tree: SceneTree
var view: WorldView
var frame: Viewport
var out := ""
var _shader: Shader
var _tiles: ImageTexture
var _lanes := PackedVector4Array()
var _lane_count := 0
var _ui: Array = []


func run(on: SceneTree) -> void:
	tree = on
	out = OS.get_environment("MASK_OUT")
	DirAccess.make_dir_recursive_absolute(out)
	var found := tree.root.find_children("*", "WorldView", true, false)
	if found.is_empty():
		push_warning("mask: no WorldView in the shot")
		return
	view = found[0]
	frame = view.get_viewport()
	view.process_mode = Node.PROCESS_MODE_DISABLED
	for t in tree.get_processed_tweens():
		t.pause()
	await _save("beauty")
	_list_ui()
	var env := view.environment
	env.fog_enabled = false
	env.glow_enabled = false
	env.adjustment_enabled = false
	var hidden3d := _hide_3d(true)
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
	for a: Node3D in view._crew + view._guards:
		a.visible = false
	await _save("behind")
	for a: Node3D in view._crew + view._guards:
		a.visible = true
	view.container.modulate.a = 0.0
	view.anchors.visible = true
	(frame as SubViewport).transparent_bg = true
	await _save("markers")
	(frame as SubViewport).transparent_bg = false
	view.anchors.visible = false
	view.container.modulate.a = 1.0
	_write_json()
	_flatten()
	await _save("id")
	await _solos()


## Draw the frame and save it as `name`.png.
func _save(name: String) -> void:
	for i in 3:
		await tree.process_frame
	await RenderingServer.frame_post_draw
	frame.get_texture().get_image().save_png(out.path_join(name + ".png"))


## The frame's 2D items that are not the world view: the interface.
func _list_ui() -> void:
	for n in frame.find_children("*", "CanvasItem", true, false):
		var c := n as CanvasItem
		if c == view or view.is_ancestor_of(c):
			continue
		_ui.append([c, c.is_ancestor_of(view), c.modulate, c.self_modulate])


## The interface see-through (`shown` false) or back as it was.
func _set_ui(shown: bool) -> void:
	for e: Array in _ui:
		var c: CanvasItem = e[0]
		if e[1]:
			c.self_modulate = e[3] if shown else Color(1, 1, 1, 0)
		else:
			c.modulate = e[2] if shown else Color(1, 1, 1, 0)


## Hide every 3D thing under the world but the camera and the environment.
func _hide_3d(_all: bool) -> Array:
	var was: Array = []
	for n in view.world.get_children():
		if n is Node3D and n != view.camera and n.visible:
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
	_shader = Shader.new()
	_shader.code = SHADER
	_tile_texture()
	var env := view.environment
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color.BLACK
	env.tonemap_mode = Environment.TONE_MAPPER_LINEAR
	env.tonemap_exposure = 1.0
	env.tonemap_white = 1.0
	view.viewport.msaa_3d = Viewport.MSAA_DISABLED
	view.viewport.screen_space_aa = Viewport.SCREEN_SPACE_AA_DISABLED
	view.container.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
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


func _classify(g: GeometryInstance3D) -> void:
	g.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var cls := Vector3(-1, 0, 0)
	var mode := 0
	for k in view._crew.size():
		if view._crew[k] == g or view._crew[k].is_ancestor_of(g):
			cls = Vector3(SHADOW if _is_shadow(view._crew[k], g) else CREW, k, 0)
	for k in view._guards.size():
		if view._guards[k] == g or view._guards[k].is_ancestor_of(g):
			cls = Vector3(SHADOW if _is_shadow(view._guards[k], g) else GUARD, k, 1)
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
		):
			cls = Vector3(MARKER, 0, 0)
		elif m != null and m == view.look.sky_material:
			g.visible = false
			return
		elif shader_path.ends_with("water.gdshader"):
			cls = Vector3(WATER, 0, 0)
		elif shader_path.ends_with("kit_ground.gdshader"):
			mode = 1
		elif (
			shader_path.ends_with("kit_toon.gdshader")
			or shader_path.ends_with("kit_clear.gdshader")
		):
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
	g.material_override = _material(mode, cls)
	if g is MeshInstance3D:
		var mi := g as MeshInstance3D
		for s in mi.get_surface_override_material_count():
			mi.set_surface_override_material(s, null)


func _is_shadow(actor: Node3D, g: Node) -> bool:
	var low := str(g.name).to_lower()
	return low.contains("blob") or low.contains("shadow") or actor.get_node_or_null("Blob") == g


## Each figure alone, flat, for its whole outline.
func _solos() -> void:
	var all: Array = []
	for n in view.world.get_children():
		if n is Node3D and n != view.camera and n.visible:
			all.append(n)
	for n: Node3D in all:
		n.visible = false
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
	var inner := view.camera.unproject_position(p)
	var sz := Vector2(view.viewport.size)
	var local := inner * view.container.size / sz
	return view.container.get_global_transform_with_canvas() * local


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
	var world_data: Variant = control.world if control != null else null
	var crew: Array = world_data.crew() if world_data != null else []
	var guards: Array = world_data.guards() if world_data != null else []
	var figures: Array = []
	for k in view._crew.size():
		figures.append(_figure(view._crew[k], "crew", k, crew[k] if k < crew.size() else {}))
	for k in view._guards.size():
		figures.append(_figure(view._guards[k], "guard", k, guards[k] if k < guards.size() else {}))
	var d := {
		"frame": [frame.get_visible_rect().size.x, frame.get_visible_rect().size.y],
		"view_rect":
		[
			view.get_global_rect().position.x,
			view.get_global_rect().position.y,
			view.get_global_rect().size.x,
			view.get_global_rect().size.y
		],
		"figures": figures,
		"chosen": view.chosen,
		"zoom": view.zoom,
		"size": [view._size.x, view._size.y],
		"env": {},
	}
	if view._vault != null and view._vault.is_inside_tree():
		d["vault"] = _bounds_of(view._vault)
	if view._skiff != null and view._skiff.visible:
		d["exit"] = _bounds_of(view._skiff)
	if world_data != null and world_data.has_method("vault"):
		var v: Dictionary = world_data.vault()
		if v.has("at"):
			d["vault_at"] = [v["at"].x, v["at"].y]
	for key: String in ["MOMENT", "ZOOM", "HOUR", "HIDE", "ORTHO", "FRAME_H", "SHOT"]:
		d["env"][key] = OS.get_environment(key)
	var f := FileAccess.open(out.path_join("mask.json"), FileAccess.WRITE)
	f.store_string(JSON.stringify(d, "  "))
	f.close()


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
