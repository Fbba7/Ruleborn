class_name Geo
extends RefCounted
## Chunky, toy-like shapes for the world (§21.1: "chunky, soft-edged,
## toy-like shapes"), written into one vertex-coloured mesh so a whole layer
## of the world is one draw call (§21.3: "under 150 draw calls"). Every shape
## takes a transform and a colour; a colour's alpha under 1 marks it to glow
## in its own colour (toon.gdshader's `glow_from_alpha`).
##
## Every vertex also carries `anim` in CUSTOM0: a pivot (xyz) and a motion
## kind (w, one of `Anim`), which the kit's shaders (kit_anim.gdshaderinc)
## turn into idle motion with no node and no script per piece: trees sway,
## wheels turn, flags flutter, stones bob.

## The kit's idle motions, as CUSTOM0.w.
enum Anim { NONE, SWAY, SPIN_Y, SPIN_X, SPIN_Z, BOB, FLAG, SWING, SHIVER }

var st := SurfaceTool.new()
var triangles := 0
## The motion every shape drawn from now on takes: pivot and kind.
var anim := Color(0, 0, 0, 0)
## Paint channels for the ground (kit_ground.gdshader): written to UV and
## UV2 on every vertex once `painted` is set, before the first shape.
var painted := false
var uv := Vector2.ZERO
var uv2 := Vector2.ZERO


func _init() -> void:
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	st.set_custom_format(0, SurfaceTool.CUSTOM_RGBA_FLOAT)


## Shapes drawn after this move by `kind` about `pivot`, until `still()`.
func moving(kind: Anim, pivot: Vector3) -> void:
	anim = Color(pivot.x, pivot.y, pivot.z, float(kind))


func still() -> void:
	anim = Color(0, 0, 0, 0)


func _vertex(v: Vector3, n: Vector3, col: Color) -> void:
	st.set_color(col)
	st.set_normal(n)
	st.set_custom(0, anim)
	if painted:
		st.set_uv(uv)
		st.set_uv2(uv2)
	st.add_vertex(v)


func tri(a: Vector3, b: Vector3, c: Vector3, col: Color, n := Vector3.ZERO) -> void:
	var normal := n if n != Vector3.ZERO else (b - a).cross(c - a).normalized()
	# Godot's front faces wind clockwise as seen from outside.
	for v: Vector3 in [a, c, b]:
		_vertex(v, normal, col)
	triangles += 1


## A triangle with a colour and a normal at each corner, for painted,
## smooth-shaded ground.
## `paint` gives each corner's UV and UV2 as a Vector4 (painted geos only).
func tri_painted(p: Array[Vector3], n: Array[Vector3], c: Array[Color], paint: Array[Vector4] = []) -> void:
	for k: int in [0, 2, 1]:
		if not paint.is_empty():
			uv = Vector2(paint[k].x, paint[k].y)
			uv2 = Vector2(paint[k].z, paint[k].w)
		_vertex(p[k], n[k], c[k])
	triangles += 1


func quad(a: Vector3, b: Vector3, c: Vector3, d: Vector3, col: Color) -> void:
	tri(a, b, c, col)
	tri(a, c, d, col)


## A box of `size` centred on `at`'s origin, turned and placed by `at`; the
## top face may take its own colour.
func box(at: Transform3D, size: Vector3, col: Color, top := Color(0, 0, 0, 0)) -> void:
	var h := size / 2.0
	var p := func(x: float, y: float, z: float) -> Vector3: return at * Vector3(x * h.x, y * h.y, z * h.z)
	var up: Color = top if top.a > 0.0 else col
	var side := col.darkened(0.06)
	quad(p.call(-1, 1, -1), p.call(-1, 1, 1), p.call(1, 1, 1), p.call(1, 1, -1), up)
	# §21.1's cameras are always above, so a face turned down is never seen.
	if _faces_up(at, Vector3.DOWN):
		quad(p.call(-1, -1, -1), p.call(1, -1, -1), p.call(1, -1, 1), p.call(-1, -1, 1), col.darkened(0.2))
	quad(p.call(-1, -1, 1), p.call(1, -1, 1), p.call(1, 1, 1), p.call(-1, 1, 1), col)
	quad(p.call(1, -1, -1), p.call(-1, -1, -1), p.call(-1, 1, -1), p.call(1, 1, -1), side)
	quad(p.call(1, -1, 1), p.call(1, -1, -1), p.call(1, 1, -1), p.call(1, 1, 1), side)
	quad(p.call(-1, -1, -1), p.call(-1, -1, 1), p.call(-1, 1, 1), p.call(-1, 1, -1), col)


## A flat panel `w` × `h` facing `at`'s +Z: a window pane, a shutter, a
## mullion — two triangles where a box would take twelve.
func panel(at: Transform3D, w: float, h: float, col: Color) -> void:
	var a := at * Vector3(-w / 2.0, -h / 2.0, 0)
	var b := at * Vector3(w / 2.0, -h / 2.0, 0)
	var c := at * Vector3(w / 2.0, h / 2.0, 0)
	var d := at * Vector3(-w / 2.0, h / 2.0, 0)
	quad(a, b, c, d, col)


## A box with its edges chamfered by `bevel`, so it catches the light on
## every edge and reads soft, like a toy (§21.1). 44 triangles.
func rbox(at: Transform3D, size: Vector3, col: Color, bevel := 0.04, top := Color(0, 0, 0, 0)) -> void:
	var h := size / 2.0
	var b := minf(bevel, minf(h.x, minf(h.y, h.z)) * 0.9)
	var up: Color = top if top.a > 0.0 else col
	# Corner (sx, sy, sz) of the inner box pushed out along one axis.
	var c := func(sx: float, sy: float, sz: float, ax: int) -> Vector3:
		var v := Vector3(sx * (h.x - b), sy * (h.y - b), sz * (h.z - b))
		v[ax] += [sx, sy, sz][ax] * b
		return at * v
	var face_col := func(ax: int, s: float) -> Color:
		if ax == 1:
			return up if s > 0 else col.darkened(0.2)
		return col if (ax == 2 and s > 0) or (ax == 0 and s < 0) else col.darkened(0.06)
	# The six faces.
	for ax in 3:
		for s: float in [-1.0, 1.0]:
			var u := (ax + 1) % 3
			var w := (ax + 2) % 3
			var corner := func(a: float, d: float) -> Vector3:
				var sv := [0.0, 0.0, 0.0]
				sv[ax] = s
				sv[u] = a
				sv[w] = d
				return c.call(sv[0], sv[1], sv[2], ax)
			var p0: Vector3 = corner.call(-1.0, -1.0)
			var p1: Vector3 = corner.call(1.0, -1.0)
			var p2: Vector3 = corner.call(1.0, 1.0)
			var p3: Vector3 = corner.call(-1.0, 1.0)
			var normal := Vector3.ZERO
			normal[ax] = s
			if _faces_up(at, normal):
				_outward(p0, p1, p2, p3, face_col.call(ax, s), at.origin)
	# The twelve chamfers, between two faces along the third axis.
	for ax in 3:
		var u := (ax + 1) % 3
		var w := (ax + 2) % 3
		for su: float in [-1.0, 1.0]:
			for sw: float in [-1.0, 1.0]:
				var sv0 := [0.0, 0.0, 0.0]
				sv0[ax] = -1.0
				sv0[u] = su
				sv0[w] = sw
				var sv1 := sv0.duplicate()
				sv1[ax] = 1.0
				var a0: Vector3 = c.call(sv0[0], sv0[1], sv0[2], u)
				var a1: Vector3 = c.call(sv1[0], sv1[1], sv1[2], u)
				var b0: Vector3 = c.call(sv0[0], sv0[1], sv0[2], w)
				var b1: Vector3 = c.call(sv1[0], sv1[1], sv1[2], w)
				var ec: Color = col.lightened(0.06) if (u == 1 and su > 0) or (w == 1 and sw > 0) else col.darkened(0.1)
				_outward(a0, a1, b1, b0, ec, at.origin)
	# The eight corners.
	for sx: float in [-1.0, 1.0]:
		for sy: float in [-1.0, 1.0]:
			for sz: float in [-1.0, 1.0]:
				var p0: Vector3 = c.call(sx, sy, sz, 0)
				var p1: Vector3 = c.call(sx, sy, sz, 1)
				var p2: Vector3 = c.call(sx, sy, sz, 2)
				var n := (p1 - p0).cross(p2 - p0)
				var cc: Color = col.lightened(0.04) if sy > 0 else col.darkened(0.12)
				if n.dot((p0 + p1 + p2) / 3.0 - at.origin) > 0:
					tri(p0, p1, p2, cc)
				else:
					tri(p0, p2, p1, cc)


## A quad wound to face away from `centre`.
func _outward(a: Vector3, b: Vector3, c: Vector3, d: Vector3, col: Color, centre: Vector3) -> void:
	if (b - a).cross(c - a).dot((a + b + c + d) / 4.0 - centre) >= 0.0:
		quad(a, b, c, d, col)
	else:
		quad(a, d, c, b, col)


## A prism or frustum standing on its base at `at`'s origin: `sides` faces,
## radius `r0` at the bottom and `r1` at height `height`; a cone when `r1`
## is 0. Smooth-shaded sides when `smooth`.
func prism(at: Transform3D, sides: int, r0: float, r1: float, height: float, col: Color, smooth := false,
		top := Color(0, 0, 0, 0)) -> void:
	var up: Color = top if top.a > 0.0 else col
	for k in sides:
		var a0 := TAU * k / sides
		var a1 := TAU * (k + 1) / sides
		var b0 := Vector3(cos(a0) * r0, 0, sin(a0) * r0)
		var b1 := Vector3(cos(a1) * r0, 0, sin(a1) * r0)
		var t0 := Vector3(cos(a0) * r1, height, sin(a0) * r1)
		var t1 := Vector3(cos(a1) * r1, height, sin(a1) * r1)
		if smooth:
			var slope := (r0 - r1) / maxf(height, 0.001)
			var n0 := Vector3(cos(a0), slope, sin(a0)).normalized()
			var n1 := Vector3(cos(a1), slope, sin(a1)).normalized()
			_tri_n(at * b0, at * t1, at * b1, n0, n1, n0, col, at)
			if r1 > 0.0:
				_tri_n(at * b0, at * t0, at * t1, n0, n0, n1, col, at)
		else:
			tri(at * b0, at * t1, at * b1, col)
			if r1 > 0.0:
				tri(at * b0, at * t0, at * t1, col)
		if r1 > 0.0 and _faces_up(at, Vector3.UP * signf(height)):
			tri(at * Vector3(0, height, 0), at * t1, at * t0, up)
		if _faces_up(at, Vector3.DOWN * signf(height)):
			tri(at * Vector3.ZERO, at * b0, at * b1, col.darkened(0.2))


## A blade of grass or a reed: a thin three-sided spike with no base,
## leaning by `lean` (radians) toward `toward` — three triangles.
func blade(base: Vector3, height: float, width: float, col: Color, lean := 0.0, toward := 0.0) -> void:
	var tip := base + Vector3(sin(lean) * cos(toward), cos(lean), sin(lean) * sin(toward)) * height
	var corners: Array[Vector3] = []
	for k in 3:
		var a := TAU * k / 3.0 + toward
		corners.append(base + Vector3(cos(a), 0, sin(a)) * width)
	for k in 3:
		var a := corners[k]
		var b := corners[(k + 1) % 3]
		tri(a, b, tip, col.lightened(0.06 * k))


## A smooth-sided cylinder (or frustum) standing on `at`'s origin.
func cyl(at: Transform3D, r0: float, r1: float, height: float, col: Color, sides := 10,
		top := Color(0, 0, 0, 0)) -> void:
	prism(at, sides, r0, r1, height, col, true, top)


func _tri_n(a: Vector3, b: Vector3, c: Vector3, na: Vector3, nb: Vector3, nc: Vector3, col: Color,
		at: Transform3D) -> void:
	var basis := at.basis.inverse().transposed()
	for pair: Array in [[a, na], [c, nc], [b, nb]]:
		_vertex(pair[0], (basis * (pair[1] as Vector3)).normalized(), col)
	triangles += 1


## A smooth, low sphere (an ellipsoid when `at` scales it); `upper` keeps
## only the top half, a dome.
func ball(at: Transform3D, radius: float, col: Color, rings := 5, segments := 8, upper := false) -> void:
	var basis := at.basis.inverse().transposed()
	var point := func(i: int, j: int) -> Vector3:
		var v := PI * i / rings * (0.5 if upper else 1.0)
		var u := TAU * j / segments
		return Vector3(sin(v) * cos(u), cos(v), sin(v) * sin(u))
	for i in rings:
		for j in segments:
			var corners: Array[Vector3] = [point.call(i, j), point.call(i + 1, j), point.call(i + 1, j + 1),
				point.call(i, j + 1)]
			for idx: Array in [[0, 1, 2], [0, 2, 3]]:
				var a: Vector3 = corners[idx[0]]
				var b: Vector3 = corners[idx[1]]
				var c: Vector3 = corners[idx[2]]
				if (a - b).length() < 0.0001 or (b - c).length() < 0.0001 or (a - c).length() < 0.0001:
					continue
				for v: Vector3 in [a, b, c]:
					_vertex(at * (v * radius), (basis * v).normalized(), col)
				triangles += 1


## A faceted stone: an icosahedron with its corners pushed in and out by
## `seed`, flat-shaded so each facet reads (the diorama's dodecahedron rocks).
func rock(at: Transform3D, radius: float, col: Color, seed_from: int = 0) -> void:
	var t := (1.0 + sqrt(5.0)) / 2.0
	var vs: Array[Vector3] = [Vector3(-1, t, 0), Vector3(1, t, 0), Vector3(-1, -t, 0), Vector3(1, -t, 0),
		Vector3(0, -1, t), Vector3(0, 1, t), Vector3(0, -1, -t), Vector3(0, 1, -t), Vector3(t, 0, -1), Vector3(t, 0, 1),
		Vector3(-t, 0, -1), Vector3(-t, 0, 1)]
	for k in vs.size():
		var j := 0.82 + 0.3 * _hash01(seed_from * 31 + k)
		vs[k] = at * (vs[k].normalized() * radius * j)
	var faces := [[0, 11, 5], [0, 5, 1], [0, 1, 7], [0, 7, 10], [0, 10, 11], [1, 5, 9], [5, 11, 4], [11, 10, 2],
		[10, 7, 6], [7, 1, 8], [3, 9, 4], [3, 4, 2], [3, 2, 6], [3, 6, 8], [3, 8, 9], [4, 9, 5], [2, 4, 11], [6, 2, 10],
		[8, 6, 7], [9, 8, 1]]
	for f: Array in faces:
		var a: Vector3 = vs[f[0]]
		var b: Vector3 = vs[f[1]]
		var c: Vector3 = vs[f[2]]
		var n := (b - a).cross(c - a)
		var up := n.normalized().y
		var shade := col.lightened(0.08 * maxf(up, 0.0)).darkened(0.1 * maxf(-up, 0.0))
		if n.dot((a + b + c) / 3.0 - at.origin) < 0:
			tri(a, c, b, shade)
		else:
			tri(a, b, c, shade)


## A double cone: a crystal or a gem (the diorama's octahedron), `sides`
## faces round, half-height `tall`.
func gem(at: Transform3D, radius: float, tall: float, col: Color, sides := 4) -> void:
	for k in sides:
		var a0 := TAU * k / sides
		var a1 := TAU * (k + 1) / sides
		var p0 := at * Vector3(cos(a0) * radius, 0, sin(a0) * radius)
		var p1 := at * Vector3(cos(a1) * radius, 0, sin(a1) * radius)
		tri(at * Vector3(0, tall, 0), p1, p0, col.lightened(0.12))
		tri(at * Vector3(0, -tall, 0), p0, p1, col.darkened(0.08))


## A ring of tube lying in `at`'s XZ plane: radius `r`, thickness `t`.
func torus(at: Transform3D, r: float, t: float, col: Color, segments := 16, sides := 5) -> void:
	var basis := at.basis.inverse().transposed()
	for i in segments:
		for j in sides:
			var pts: Array[Vector3] = []
			var nrm: Array[Vector3] = []
			for d: Vector2i in [Vector2i(0, 0), Vector2i(1, 0), Vector2i(1, 1), Vector2i(0, 1)]:
				var u := TAU * (i + d.x) / segments
				var v := TAU * (j + d.y) / sides
				var centre := Vector3(cos(u) * r, 0, sin(u) * r)
				var n := Vector3(cos(u) * cos(v), sin(v), sin(u) * cos(v))
				pts.append(at * (centre + n * t))
				nrm.append((basis * n).normalized())
			for idx: Array in [[0, 2, 1], [0, 3, 2]]:
				for k: int in idx:
					_vertex(pts[k], nrm[k], col)
				triangles += 1


## A flat ring or disc lying on the ground at `at`.
func ring(at: Transform3D, r_in: float, r_out: float, col: Color, segments := 20) -> void:
	for k in segments:
		var a0 := TAU * k / segments
		var a1 := TAU * (k + 1) / segments
		var o0 := Vector3(cos(a0) * r_out, 0, sin(a0) * r_out)
		var o1 := Vector3(cos(a1) * r_out, 0, sin(a1) * r_out)
		var i0 := Vector3(cos(a0) * r_in, 0, sin(a0) * r_in)
		var i1 := Vector3(cos(a1) * r_in, 0, sin(a1) * r_in)
		if r_in > 0.0:
			quad(at * i0, at * i1, at * o1, at * o0, col)
		else:
			tri(at * Vector3.ZERO, at * o1, at * o0, col)


## A wedge rising along local -Z from `at`'s origin: a ramp of `size`.
func wedge(at: Transform3D, size: Vector3, col: Color) -> void:
	var h := size / 2.0
	var p := func(x: float, y: float, z: float) -> Vector3: return at * Vector3(x * h.x, y, z * h.z)
	var a: Vector3 = p.call(-1, 0, 1)
	var b: Vector3 = p.call(1, 0, 1)
	var c: Vector3 = p.call(1, size.y, -1)
	var d: Vector3 = p.call(-1, size.y, -1)
	var e: Vector3 = p.call(1, 0, -1)
	var f: Vector3 = p.call(-1, 0, -1)
	quad(a, b, c, d, col)
	tri(b, e, c, col.darkened(0.08))
	tri(a, d, f, col.darkened(0.08))
	quad(f, d, c, e, col.darkened(0.12))


## A gable roof's end wall: a triangle of `w` wide and `rise` high, `d`
## deep, on `at`'s origin (the diorama's `prism`).
func gable(at: Transform3D, w: float, rise: float, d: float, col: Color) -> void:
	var p := func(x: float, y: float, z: float) -> Vector3: return at * Vector3(x, y, z)
	var hz := d / 2.0
	var hw := w / 2.0
	tri(p.call(-hw, 0, hz), p.call(hw, 0, hz), p.call(0, rise, hz), col)
	tri(p.call(hw, 0, -hz), p.call(-hw, 0, -hz), p.call(0, rise, -hz), col.darkened(0.06))
	quad(p.call(-hw, 0, -hz), p.call(-hw, 0, hz), p.call(0, rise, hz), p.call(0, rise, -hz), col.darkened(0.04))
	quad(p.call(hw, 0, hz), p.call(hw, 0, -hz), p.call(0, rise, -hz), p.call(0, rise, hz), col.darkened(0.04))


## Everything drawn into `other`, moved by `xform` into this one, its
## motion's pivots moved with it (a turn about X or Z trades axes when the
## piece is turned a quarter).
func absorb(other: Geo, xform: Transform3D) -> void:
	if other.triangles == 0:
		return
	var arrays := other.st.commit_to_arrays()
	var verts: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var normals: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL]
	var cols: PackedColorArray = arrays[Mesh.ARRAY_COLOR]
	var customs: PackedFloat32Array = arrays[Mesh.ARRAY_CUSTOM0]
	var quarter := absf(xform.basis.x.z) > 0.7
	var keep := anim
	for i in verts.size():
		var kind := customs[i * 4 + 3]
		if kind > 0.5:
			var pivot := xform * Vector3(customs[i * 4], customs[i * 4 + 1], customs[i * 4 + 2])
			if quarter and int(kind + 0.5) in [Anim.SPIN_X, Anim.SPIN_Z]:
				kind = float(Anim.SPIN_Z if int(kind + 0.5) == Anim.SPIN_X else Anim.SPIN_X)
			anim = Color(pivot.x, pivot.y, pivot.z, kind)
		else:
			anim = Color(0, 0, 0, 0)
		_vertex(xform * verts[i], (xform.basis * normals[i]).normalized(), cols[i])
	triangles += other.triangles
	anim = keep


## The mesh so far, or null if nothing was drawn.
func mesh() -> ArrayMesh:
	if triangles == 0:
		return null
	return st.commit()


## Whether a face whose local normal is `n` can face a camera above: false
## only for a face turned straight down.
static func _faces_up(at: Transform3D, n: Vector3) -> bool:
	return (at.basis * n).normalized().y > -0.9


static func place(position: Vector3, yaw := 0.0, scale := Vector3.ONE) -> Transform3D:
	return Transform3D(Basis(Vector3.UP, yaw).scaled(scale), position)


static func _hash01(i: int) -> float:
	var h := i * 374761393 + 668265263
	h = (h ^ (h >> 13)) * 1274126177
	return float(posmod(h ^ (h >> 16), 10000)) / 10000.0
