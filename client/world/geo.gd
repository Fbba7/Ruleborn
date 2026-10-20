class_name Geo
extends RefCounted
## Chunky, toy-like shapes for the world (§21.1: "chunky, soft-edged,
## toy-like shapes"), written into one vertex-coloured mesh so a whole layer
## of the world is one draw call (§21.3: "under 150 draw calls"). Every shape
## takes a transform and a colour; a colour's alpha under 1 marks it to glow
## in its own colour (toon.gdshader's `glow_from_alpha`).

var st := SurfaceTool.new()
var triangles := 0


func _init() -> void:
	st.begin(Mesh.PRIMITIVE_TRIANGLES)


func tri(a: Vector3, b: Vector3, c: Vector3, col: Color, n := Vector3.ZERO) -> void:
	var normal := n if n != Vector3.ZERO else (b - a).cross(c - a).normalized()
	# Godot's front faces wind clockwise as seen from outside.
	for v: Vector3 in [a, c, b]:
		st.set_color(col)
		st.set_normal(normal)
		st.add_vertex(v)
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
	quad(p.call(-1, -1, -1), p.call(1, -1, -1), p.call(1, -1, 1), p.call(-1, -1, 1), col.darkened(0.2))
	quad(p.call(-1, -1, 1), p.call(1, -1, 1), p.call(1, 1, 1), p.call(-1, 1, 1), col)
	quad(p.call(1, -1, -1), p.call(-1, -1, -1), p.call(-1, 1, -1), p.call(1, 1, -1), side)
	quad(p.call(1, -1, 1), p.call(1, -1, -1), p.call(1, 1, -1), p.call(1, 1, 1), side)
	quad(p.call(-1, -1, -1), p.call(-1, -1, 1), p.call(-1, 1, 1), p.call(-1, 1, -1), col)


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
		if r1 > 0.0:
			tri(at * Vector3(0, height, 0), at * t1, at * t0, up)
		tri(at * Vector3.ZERO, at * b0, at * b1, col.darkened(0.2))


func _tri_n(a: Vector3, b: Vector3, c: Vector3, na: Vector3, nb: Vector3, nc: Vector3, col: Color,
		at: Transform3D) -> void:
	var basis := at.basis.inverse().transposed()
	for pair: Array in [[a, na], [c, nc], [b, nb]]:
		st.set_color(col)
		st.set_normal((basis * (pair[1] as Vector3)).normalized())
		st.add_vertex(pair[0])
	triangles += 1


## A smooth, low sphere (an ellipsoid when `at` scales it).
func ball(at: Transform3D, radius: float, col: Color, rings := 5, segments := 8) -> void:
	var basis := at.basis.inverse().transposed()
	var point := func(i: int, j: int) -> Vector3:
		var v := PI * i / rings
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
					st.set_color(col)
					st.set_normal((basis * v).normalized())
					st.add_vertex(at * (v * radius))
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


## The mesh so far, or null if nothing was drawn.
func mesh() -> ArrayMesh:
	if triangles == 0:
		return null
	return st.commit()


static func place(position: Vector3, yaw := 0.0, scale := Vector3.ONE) -> Transform3D:
	return Transform3D(Basis(Vector3.UP, yaw).scaled(scale), position)
