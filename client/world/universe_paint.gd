class_name UniversePaint
extends RefCounted
## Light on the universe map, written into one mesh a layer: glows (stars,
## lanterns, windows, motes) for `universe_glow.gdshader`, and strips of
## light (beams, falls, running water, portals) for `universe_veil.gdshader`.
## `Geo` writes the solids; this writes what shines, with the UVs those
## shaders read. A whole layer is one draw call (§21.3).

var st := SurfaceTool.new()
var count := 0


func _init() -> void:
	st.begin(Mesh.PRIMITIVE_TRIANGLES)


## A glow of `radius` metres at `at`, in `colour`; its alpha is its strength.
## One that `falls` drops that many metres over and over, fading in and out
## (a mote, a drip of light under an island); a negative fall rises.
func glow(at: Vector3, radius: float, colour: Color, falls := 0.0) -> void:
	var corners: Array[Vector2] = [Vector2(0, 0), Vector2(1, 0), Vector2(1, 1), Vector2(0, 1)]
	for k: int in [0, 2, 1, 0, 3, 2]:
		st.set_color(colour)
		st.set_uv(corners[k])
		st.set_uv2(Vector2(radius, falls))
		st.add_vertex(at)
	count += 2


## A ribbon of light between two rails of points, `a` and `b`, the same
## length: UV.x runs along it (0 to `length_uv`), UV.y from `a` (0) to `b`
## (1), or along it when `along_fade`; `soft` fades its sides too.
func strip(a: PackedVector3Array, b: PackedVector3Array, colour: Color, length_uv := 1.0, soft := false,
		along_fade := false) -> void:
	var n := mini(a.size(), b.size())
	for k in n - 1:
		var u0 := length_uv * k / float(n - 1)
		var u1 := length_uv * (k + 1) / float(n - 1)
		var f0 := float(k) / float(n - 1) if along_fade else 0.0
		var f1 := float(k + 1) / float(n - 1) if along_fade else 0.0
		var quad := [[a[k], u0, f0, 0.0], [a[k + 1], u1, f1, 0.0], [b[k + 1], u1, f1 if along_fade else 1.0, 1.0],
			[b[k], u0, f0 if along_fade else 1.0, 1.0]]
		for i: int in [0, 1, 2, 0, 2, 3]:
			var v: Array = quad[i]
			st.set_color(colour)
			st.set_uv(Vector2(v[1], v[2]))
			st.set_uv2(Vector2(v[3], (1.0 if soft else 0.0) + (1.0 if soft and along_fade else 0.0)))
			st.add_vertex(v[0])
		count += 2


## An open cylinder of light standing on `at`: a beam (§21.1's Heart).
func beam(at: Vector3, r0: float, r1: float, height: float, colour: Color, sides := 14) -> void:
	for k in sides:
		var a0 := TAU * k / sides
		var a1 := TAU * (k + 1) / sides
		var lo := PackedVector3Array([at + Vector3(cos(a0) * r0, 0, sin(a0) * r0),
			at + Vector3(cos(a1) * r0, 0, sin(a1) * r0)])
		var hi := PackedVector3Array([at + Vector3(cos(a0) * r1, height, sin(a0) * r1),
			at + Vector3(cos(a1) * r1, height, sin(a1) * r1)])
		strip(lo, hi, colour)


## A flat disc of light facing `normal`, bright at its middle.
func disc(at: Vector3, normal: Vector3, radius: float, colour: Color, sides := 20) -> void:
	var side := normal.cross(Vector3.UP if absf(normal.y) < 0.9 else Vector3.RIGHT).normalized()
	var up := side.cross(normal).normalized()
	for k in sides:
		var a0 := TAU * k / sides
		var a1 := TAU * (k + 1) / sides
		var rim := PackedVector3Array([at + (side * cos(a0) + up * sin(a0)) * radius,
			at + (side * cos(a1) + up * sin(a1)) * radius])
		strip(PackedVector3Array([at, at]), rim, colour)


func mesh() -> ArrayMesh:
	if count == 0:
		return null
	return st.commit()
