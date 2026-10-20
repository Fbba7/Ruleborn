class_name LookMesh
extends RefCounted
## A mesh of the island written face by face: positions, normals, vertex
## colours and UVs, committed as one surface so a whole part of the island is
## one draw call (§21.3). Faces are flat-shaded unless given their normals.
## A colour's alpha under 1 marks it to glow in its own colour, as in `Geo`.

## The faces of a unit icosahedron, by corner.
const ICO_FACES: Array[Vector3i] = [Vector3i(0, 11, 5), Vector3i(0, 5, 1), Vector3i(0, 1, 7), Vector3i(0, 7, 10),
	Vector3i(0, 10, 11), Vector3i(1, 5, 9), Vector3i(5, 11, 4), Vector3i(11, 10, 2), Vector3i(10, 7, 6),
	Vector3i(7, 1, 8), Vector3i(3, 9, 4), Vector3i(3, 4, 2), Vector3i(3, 2, 6), Vector3i(3, 6, 8), Vector3i(3, 8, 9),
	Vector3i(4, 9, 5), Vector3i(2, 4, 11), Vector3i(6, 2, 10), Vector3i(8, 6, 7), Vector3i(9, 8, 1)]

var verts := PackedVector3Array()
var normals := PackedVector3Array()
var colours := PackedColorArray()
var uvs := PackedVector2Array()
var triangles := 0


## A flat face turned toward `out` (any vector pointing away from the solid).
func tri(a: Vector3, b: Vector3, c: Vector3, col: Color, out: Vector3, ua := Vector2.ZERO, ub := Vector2.ZERO,
		uc := Vector2.ZERO) -> void:
	var n := (b - a).cross(c - a)
	if n.length_squared() < 1e-12:
		return
	n = n.normalized()
	if n.dot(out) < 0.0:
		n = -n
		var t := b
		b = c
		c = t
		var tu := ub
		ub = uc
		uc = tu
	# Godot's front faces wind clockwise as seen from outside.
	verts.append_array([a, c, b])
	normals.append_array([n, n, n])
	colours.append_array([col, col, col])
	uvs.append_array([ua, uc, ub])
	triangles += 1


## A face with a normal at each corner, wound as given (clockwise from the
## side the normals face): three points, their normals, their colours and,
## if given, their UVs.
func smooth(p: Array[Vector3], n: Array[Vector3], c: Array[Color], uv: Array[Vector2] = []) -> void:
	verts.append_array(p)
	normals.append_array(n)
	colours.append_array(c)
	uvs.append_array(uv if uv.size() == 3 else [Vector2.ZERO, Vector2.ZERO, Vector2.ZERO])
	triangles += 1


## A low, flat-shaded ball: an icosahedron of radius 1 placed by `at`.
func ico(at: Transform3D, col: Color, uv := Vector2.ZERO) -> void:
	var p := LookMesh.ico_points()
	for f: Vector3i in LookMesh.ICO_FACES:
		var a: Vector3 = at * p[f.x]
		var b: Vector3 = at * p[f.y]
		var c: Vector3 = at * p[f.z]
		tri(a, b, c, col, (a + b + c) / 3.0 - at.origin, uv, uv, uv)


## A diamond: an octahedron of radius 1 placed by `at`, flat-shaded; the
## cheapest round thing, for leaves, petals and specks.
func octa(at: Transform3D, col: Color) -> void:
	var ring: Array[Vector3] = [Vector3(1, 0, 0), Vector3(0, 0, 1), Vector3(-1, 0, 0), Vector3(0, 0, -1)]
	for i in 4:
		var a: Vector3 = at * ring[i]
		var b: Vector3 = at * ring[(i + 1) % 4]
		for tip: Vector3 in [at * Vector3.UP, at * Vector3.DOWN]:
			tri(a, b, tip, col, (a + b + tip) / 3.0 - at.origin)


## A smooth, low ball (an ellipsoid when `at` scales it): `rings` by
## `segments`, its normals round, for soft shapes like clouds.
func puff(at: Transform3D, col: Color, rings := 4, segments := 8) -> void:
	var nb := at.basis.inverse().transposed()
	for i in rings:
		for j in segments:
			var corners: Array[Vector3] = []
			for c: Vector2i in [Vector2i(i, j), Vector2i(i + 1, j), Vector2i(i + 1, j + 1), Vector2i(i, j + 1)]:
				var v := PI * c.x / rings
				var u := TAU * c.y / segments
				corners.append(Vector3(sin(v) * cos(u), cos(v), sin(v) * sin(u)))
			for idx: Vector3i in [Vector3i(0, 2, 1), Vector3i(0, 3, 2)]:
				var a := corners[idx.x]
				var b := corners[idx.y]
				var c := corners[idx.z]
				if a.distance_to(b) < 1e-4 or b.distance_to(c) < 1e-4 or a.distance_to(c) < 1e-4:
					continue
				smooth([at * a, at * b, at * c], [(nb * a).normalized(), (nb * b).normalized(), (nb * c).normalized()],
					[col, col, col])


## A tapering tube through `points`, radius `r0` at the first and `r1` at the
## last, `sides` round; UV.y is the distance along it, for the sway.
func tube(points: PackedVector3Array, r0: float, r1: float, sides: int, col: Color) -> void:
	var along := 0.0
	for i in points.size() - 1:
		var a := points[i]
		var b := points[i + 1]
		var d := (b - a).normalized()
		var side := d.cross(Vector3.UP if absf(d.y) < 0.95 else Vector3.RIGHT).normalized()
		var up := side.cross(d).normalized()
		var ra := lerpf(r0, r1, float(i) / (points.size() - 1))
		var rb := lerpf(r0, r1, float(i + 1) / (points.size() - 1))
		var next := along + a.distance_to(b)
		for k in sides:
			var a0 := TAU * k / sides
			var a1 := TAU * (k + 1) / sides
			var o0 := side * cos(a0) + up * sin(a0)
			var o1 := side * cos(a1) + up * sin(a1)
			var mid := (o0 + o1) * 0.5
			tri(a + o0 * ra, b + o0 * rb, b + o1 * rb, col, mid, Vector2(0, along), Vector2(0, next), Vector2(0, next))
			tri(a + o0 * ra, b + o1 * rb, a + o1 * ra, col, mid, Vector2(0, along), Vector2(0, next), Vector2(0, along))
		along = next


## The mesh so far, or null if nothing was drawn.
func mesh() -> ArrayMesh:
	if triangles == 0:
		return null
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = verts
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_COLOR] = colours
	arrays[Mesh.ARRAY_TEX_UV] = uvs
	var m := ArrayMesh.new()
	m.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return m


## The twelve corners of a unit icosahedron.
static func ico_points() -> PackedVector3Array:
	var t := (1.0 + sqrt(5.0)) / 2.0
	var out := PackedVector3Array()
	for v: Vector3 in [Vector3(-1, t, 0), Vector3(1, t, 0), Vector3(-1, -t, 0), Vector3(1, -t, 0), Vector3(0, -1, t),
			Vector3(0, 1, t), Vector3(0, -1, -t), Vector3(0, 1, -t), Vector3(t, 0, -1), Vector3(t, 0, 1),
			Vector3(-t, 0, -1), Vector3(-t, 0, 1)]:
		out.append(v.normalized())
	return out
