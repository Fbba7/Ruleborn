class_name CreatureGear
extends RefCounted
## What CreatureModel adds on top of the exported model, built in code
## (§21.11): the soft ground shadow, the Hush form's crescent charm, the Spark
## form's embers, and the guard form's sash and lantern (§21.6: "As guards,
## ruleborn add a sash and a small lantern"; the design draws no guard form,
## so this is ours). Gear is coloured by vertex, drawn with the character's own
## toon material, and sized by the kind's height and chest from the manifest.

const SASH := Color("#B8323C")
const SASH_TRIM := Color("#F2C25C")
const BRASS := Color("#C8963E")
const LANTERN_GLOW := Color("#FFD68A")
const MOON := Color("#DCE6FF")
const EMBER := Color("#FF8A2A")

static var _blob_shader: Shader = load("res://world/creature_blob.gdshader")
static var _shader: Shader = load("res://world/creature.gdshader")
static var _white: ImageTexture


## The ground shadow under `c`, scaled to its footprint.
static func blob(c: CreatureModel) -> MeshInstance3D:
	var q := QuadMesh.new()
	var r := float(c.info.get("radius", c.height() * 0.32)) * 2.3
	q.size = Vector2(r, r)
	q.orientation = PlaneMesh.FACE_Y
	var m := ShaderMaterial.new()
	m.shader = _blob_shader
	var mi := MeshInstance3D.new()
	mi.name = "blob"
	mi.mesh = q
	mi.material_override = m
	mi.position.y = 0.012
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return mi


## Hush: a small glowing crescent that hovers over the head and turns slowly.
static func hush_charm(c: CreatureModel) -> Node3D:
	var at := _anchor(c, &"head_top")
	var st := _tool()
	var h := c.height()
	var r := 0.075 * h / _scale(c)
	_crescent(st, r, r * 0.3, MOON, 1.0)
	var mi := _instance(st, "hush_charm")
	mi.position = Vector3(0, r * 1.6, 0)
	at.add_child(mi)
	var tw := mi.create_tween().set_loops()
	tw.tween_property(mi, "rotation:y", TAU, 6.0).from(0.0)
	return mi


## Gear hangs on sockets; the holder's "parts" meta lists the nodes to free with it.


## Spark: embers rising from the design's ember sockets (or the head).
static func embers(c: CreatureModel) -> Node3D:
	var holder := Node3D.new()
	holder.name = "spark_embers"
	var points: Array[Node3D] = []
	for s: Dictionary in c.info.get("sockets", []):
		if str(s.get("kind", "")) == "ember" and c.socket(StringName(str(s.get("name", "")))) != null:
			points.append(c.socket(StringName(str(s.get("name", "")))))
	if points.is_empty() and c.socket(&"head_top") != null:
		points.append(c.socket(&"head_top"))
	var h := c.height()
	var parts: Array = []
	for p: Node3D in points:
		var e := CPUParticles3D.new()
		e.amount = 10
		e.lifetime = 1.1
		e.local_coords = false
		e.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
		e.emission_sphere_radius = 0.03 * h
		e.direction = Vector3.UP
		e.spread = 25.0
		e.gravity = Vector3(0, 0.35 * h, 0)
		e.initial_velocity_min = 0.05 * h
		e.initial_velocity_max = 0.18 * h
		e.scale_amount_min = 0.5
		e.scale_amount_max = 1.0
		var ramp := Gradient.new()
		ramp.set_color(0, Color(1.0, 0.85, 0.45, 1.0))
		ramp.set_color(1, Color(EMBER, 0.0))
		e.color_ramp = ramp
		var q := QuadMesh.new()
		q.size = Vector2(0.035, 0.035) * h
		var m := StandardMaterial3D.new()
		m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		m.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
		m.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
		m.vertex_color_use_as_albedo = true
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		q.material = m
		e.mesh = q
		p.add_child(e)
		parts.append(e)
	holder.set_meta("parts", parts)
	c.add_child(holder)
	return holder


## The guard form: a sash over the left shoulder across the chest, with a gold
## trim and a knot, and a small lantern hanging from the right hand.
static func guard_kit(c: CreatureModel) -> Node3D:
	var holder := Node3D.new()
	holder.name = "guard_kit"
	var s := _scale(c)
	var chest := _anchor(c, &"chest")
	var rad := float(c.info.get("chest_radius", c.height() * 0.22 / s))
	var st := _tool()
	# The sash: a flat band round an ellipse tilted across the body.
	var n := 28
	var tilt := Basis(Vector3.BACK, 0.62)
	for i in n:
		var a0 := TAU * float(i) / float(n)
		var a1 := TAU * float(i + 1) / float(n)
		for band: Array in [[-0.5, 0.5, SASH, 0.0], [0.5, 0.62, SASH_TRIM, 0.4], [-0.62, -0.5, SASH_TRIM, 0.4]]:
			var w := rad * 0.32
			var p00 := tilt * Vector3(cos(a0) * rad * 1.08, float(band[0]) * w, sin(a0) * rad * 1.02)
			var p01 := tilt * Vector3(cos(a0) * rad * 1.08, float(band[1]) * w, sin(a0) * rad * 1.02)
			var p10 := tilt * Vector3(cos(a1) * rad * 1.08, float(band[0]) * w, sin(a1) * rad * 1.02)
			var p11 := tilt * Vector3(cos(a1) * rad * 1.08, float(band[1]) * w, sin(a1) * rad * 1.02)
			var n0 := (tilt * Vector3(cos(a0), 0, sin(a0))).normalized()
			var n1 := (tilt * Vector3(cos(a1), 0, sin(a1))).normalized()
			_quad(st, [p00, p10, p11, p01], [n0, n1, n1, n0], band[2] as Color, float(band[3]), 0.0)
	# A knot on the front.
	_ball(st, tilt * Vector3(rad * 0.25, -rad * 0.05, rad * 1.04), rad * 0.16, SASH.darkened(0.15), 0.0, 0.0)
	var sash := _instance(st, "sash")
	chest.add_child(sash)
	# The lantern at the right hand: brass cap and base, a glowing body, a ring.
	var hand := _anchor(c, &"hand_R")
	var lt := _tool()
	var lr := 0.055 * c.height() / s
	_ball(lt, Vector3(0, -lr * 1.9, 0), lr, LANTERN_GLOW, 0.0, 1.0)
	_cylinder(lt, Vector3(0, -lr * 0.95, 0), lr * 0.7, lr * 0.32, BRASS, 0.45)
	_cylinder(lt, Vector3(0, -lr * 2.85, 0), lr * 0.75, lr * 0.25, BRASS, 0.45)
	_ring(lt, Vector3(0, -lr * 0.45, 0), lr * 0.35, lr * 0.07, BRASS)
	var lantern := _instance(lt, "lantern")
	hand.add_child(lantern)
	holder.set_meta("parts", [sash, lantern])
	c.add_child(holder)
	return holder


static func _scale(c: CreatureModel) -> float:
	return maxf(0.0001, float(c.info.get("scale", 1.0)))


static func _anchor(c: CreatureModel, socket_name: StringName) -> Node3D:
	var s := c.socket(socket_name)
	return s if s != null else c


static func _tool() -> SurfaceTool:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	return st


static func _instance(st: SurfaceTool, node_name: String) -> MeshInstance3D:
	if _white == null:
		var img := Image.create(4, 4, false, Image.FORMAT_RGBA8)
		img.fill(Color.WHITE)
		_white = ImageTexture.create_from_image(img)
	var m := ShaderMaterial.new()
	m.shader = _shader
	m.set_shader_parameter("atlas", _white)
	var mi := MeshInstance3D.new()
	mi.name = node_name
	mi.mesh = st.commit()
	mi.material_override = m
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return mi


# Vertex colours are linear in the character material (as the glTF import keeps them).
static func _vertex(st: SurfaceTool, p: Vector3, n: Vector3, col: Color, gloss: float, glow: float) -> void:
	st.set_color(col.srgb_to_linear())
	st.set_normal(n)
	st.set_uv(Vector2(0.5, 0.5))
	st.set_uv2(Vector2(gloss * 0.45, glow))
	st.add_vertex(p)


static func _quad(st: SurfaceTool, p: Array, n: Array, col: Color, gloss: float, glow: float) -> void:
	for k: int in [0, 1, 2, 0, 2, 3]:
		_vertex(st, p[k] as Vector3, n[k] as Vector3, col, gloss, glow)


static func _ball(st: SurfaceTool, at: Vector3, r: float, col: Color, gloss: float, glow: float) -> void:
	var rings := 6
	var segs := 10
	for i in rings:
		for j in segs:
			var pts: Array = []
			var nrm: Array = []
			for k: Vector2i in [Vector2i(i, j), Vector2i(i, j + 1), Vector2i(i + 1, j + 1), Vector2i(i + 1, j)]:
				var th := PI * float(k.x) / float(rings)
				var ph := TAU * float(k.y) / float(segs)
				var d := Vector3(sin(th) * cos(ph), cos(th), sin(th) * sin(ph))
				pts.append(at + d * r)
				nrm.append(d)
			_quad(st, [pts[0], pts[3], pts[2], pts[1]], [nrm[0], nrm[3], nrm[2], nrm[1]], col, gloss, glow)


static func _cylinder(st: SurfaceTool, at: Vector3, r: float, h: float, col: Color, gloss: float) -> void:
	var segs := 10
	for j in segs:
		var a0 := TAU * float(j) / float(segs)
		var a1 := TAU * float(j + 1) / float(segs)
		var d0 := Vector3(cos(a0), 0, sin(a0))
		var d1 := Vector3(cos(a1), 0, sin(a1))
		var up := Vector3(0, h * 0.5, 0)
		_quad(st, [at + d0 * r - up, at + d0 * r + up, at + d1 * r + up, at + d1 * r - up], [d0, d0, d1, d1], col, gloss, 0.0)
		var nu: Array = [Vector3.UP, Vector3.UP, Vector3.UP, Vector3.UP]
		var nd: Array = [Vector3.DOWN, Vector3.DOWN, Vector3.DOWN, Vector3.DOWN]
		_quad(st, [at + up, at + up + d1 * r, at + up + d0 * r, at + up], nu, col, gloss, 0.0)
		_quad(st, [at - up, at - up + d0 * r, at - up + d1 * r, at - up], nd, col, gloss, 0.0)


static func _ring(st: SurfaceTool, at: Vector3, r: float, t: float, col: Color) -> void:
	var segs := 10
	var sides := 5
	for j in segs:
		for k in sides:
			var pts: Array = []
			var nrm: Array = []
			for q: Vector2i in [Vector2i(j, k), Vector2i(j + 1, k), Vector2i(j + 1, k + 1), Vector2i(j, k + 1)]:
				var a := TAU * float(q.x) / float(segs)
				var b := TAU * float(q.y) / float(sides)
				var centre := Vector3(cos(a) * r, sin(a) * r, 0)
				var d := (Vector3(cos(a), sin(a), 0) * cos(b) + Vector3(0, 0, sin(b))).normalized()
				pts.append(at + centre + d * t)
				nrm.append(d)
			_quad(st, pts, nrm, col, 0.45, 0.0)


# A crescent: a disc of radius r with a disc offset by `bite` cut out, as a thin slab.
static func _crescent(st: SurfaceTool, r: float, bite: float, col: Color, glow: float) -> void:
	var n := 18
	var depth := r * 0.18
	var outer: Array[Vector3] = []
	var inner: Array[Vector3] = []
	for i in n + 1:
		var a := lerpf(-PI * 0.42, PI * 1.42, float(i) / float(n))
		outer.append(Vector3(cos(a) * r, sin(a) * r, 0))
		var p := Vector3(cos(a) * r * 0.78 + bite, sin(a) * r * 0.78, 0)
		inner.append(p)
	for i in n:
		for side: float in [1.0, -1.0]:
			var z := Vector3(0, 0, depth * side)
			var f := Vector3(0, 0, side)
			var quad := [outer[i] + z, outer[i + 1] + z, inner[i + 1] + z, inner[i] + z]
			if side < 0.0:
				quad = [quad[0], quad[3], quad[2], quad[1]]
			_quad(st, quad, [f, f, f, f], col, 0.0, glow)
		var o0 := outer[i].normalized()
		var o1 := outer[i + 1].normalized()
		_quad(st, [outer[i] - Vector3(0, 0, depth), outer[i + 1] - Vector3(0, 0, depth), outer[i + 1] + Vector3(0, 0, depth),
			outer[i] + Vector3(0, 0, depth)], [o0, o1, o1, o0], col, 0.0, glow)
