class_name LawFxBatch
extends RefCounted
## One layer of a law's signature written into one mesh, so the layer is one
## draw call (§21.3: "under 150 draw calls"): motes for law_fx_mote, ground
## marks for law_fx_decal, or solid pieces for law_fx_solid and law_fx_glass,
## each vertex carrying what its shader moves it by (CUSTOM0, CUSTOM1).

enum Kind { MOTES, DECALS, SOLIDS, THREADS }

const CORNERS: Array[Vector2] = [Vector2(-1, -1), Vector2(1, -1), Vector2(1, 1), Vector2(-1, -1), Vector2(1, 1),
	Vector2(-1, 1)]

var kind := Kind.MOTES
var st := SurfaceTool.new()
var triangles := 0


func _init(k: Kind) -> void:
	kind = k
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	st.set_custom_format(0, SurfaceTool.CUSTOM_RGBA_FLOAT)
	if k == Kind.MOTES:
		st.set_custom_format(1, SurfaceTool.CUSTOM_RGBA_FLOAT)


## A mote starting at `at`, moving at `velocity` metres a second for a loop
## of `period` seconds (0: it stays and twinkles), `phase` (0..1) into its
## loop, `radius` across, wobbling by `wobble`, drawn as `shape`
## (law_fx_mote's list) in `colour`, whose alpha is its strongest opacity.
func mote(at: Vector3, velocity: Vector3, period: float, phase: float, radius: float, wobble: float, shape: int,
		colour: Color) -> void:
	for c: Vector2 in CORNERS:
		st.set_color(colour)
		st.set_uv(c)
		st.set_custom(0, Color(velocity.x, velocity.y, velocity.z, period))
		st.set_custom(1, Color(phase, radius, wobble, float(shape)))
		st.add_vertex(at)
	triangles += 2


## A flat mark of `extent` (half-width, half-depth) lying at `at`, turned by
## `yaw`; `weight` is how strongly it shows, `local` what its pattern reads
## (a centre's x and z, a phase, a free value).
func decal(at: Vector3, extent: Vector2, weight: float, local := Vector4.ZERO, yaw := 0.0) -> void:
	var b := Basis(Vector3.UP, yaw)
	var pts: Array[Vector3] = []
	for c: Vector2 in CORNERS:
		pts.append(at + b * Vector3(c.x * extent.x, 0, c.y * extent.y))
	for k in pts.size():
		var p: Vector3 = pts[k]
		st.set_color(Color(1, 1, 1, weight))
		st.set_uv(Vector2(p.x, p.z))
		st.set_normal(Vector3.UP)
		st.set_custom(0, Color(local.x, local.y, local.z, local.w))
		st.add_vertex(p)
	triangles += 2


## A tile's mark: the whole tile at its height, a hair over the flagstones.
func tile(site: LawFxSite, t: Vector2i, weight := 1.0, local := Vector4.ZERO, lift := 0.02) -> void:
	var c := site.centre(t) + Vector3(0, lift, 0)
	if local == Vector4.ZERO:
		local = Vector4(c.x, c.z, RealmKit.jitter(t, 3), 0.0)
	decal(c, Vector2(0.5, 0.5), weight, local)


## A solid piece: every triangle of `piece` placed by `at`, moving about
## `pivot` (in the world) from `phase` by the shader's motion.
func solid(piece: ArrayMesh, at: Transform3D, pivot: Vector3, phase: float) -> void:
	if piece == null:
		return
	var arrays := piece.surface_get_arrays(0)
	var verts: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var normals: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL]
	var colours: PackedColorArray = arrays[Mesh.ARRAY_COLOR]
	var index: PackedInt32Array = arrays[Mesh.ARRAY_INDEX] if arrays[Mesh.ARRAY_INDEX] != null else PackedInt32Array()
	var order := index if index.size() > 0 else PackedInt32Array(range(verts.size()))
	var turn := at.basis.inverse().transposed()
	for i: int in order:
		st.set_color(colours[i] if i < colours.size() else Color.WHITE)
		st.set_normal((turn * normals[i]).normalized() if i < normals.size() else Vector3.UP)
		st.set_custom(0, Color(pivot.x, pivot.y, pivot.z, phase))
		st.add_vertex(at * verts[i])
	triangles += order.size() / 3


## A line through `points` for law_fx_thread, `kind` 0 a harmony's thread,
## 1 a dissonance's jagged line, 2 a chord's edge; its length runs from
## `from` to `to` of the whole (a chord's three edges share one loop).
func strip(points: Array[Vector3], colour: Color, line_kind: int, from := 0.0, to := 1.0) -> void:
	var n := points.size()
	for k in n - 1:
		var a: Vector3 = points[k]
		var b: Vector3 = points[k + 1]
		var d := (b - a).normalized()
		var ua := lerpf(from, to, float(k) / (n - 1))
		var ub := lerpf(from, to, float(k + 1) / (n - 1))
		var quad: Array = [[a, ua, -1.0], [b, ub, -1.0], [b, ub, 1.0], [a, ua, -1.0], [b, ub, 1.0], [a, ua, 1.0]]
		for v: Array in quad:
			st.set_color(colour)
			st.set_uv(Vector2(float(v[1]), float(v[2])))
			st.set_custom(0, Color(d.x, d.y, d.z, float(line_kind)))
			st.add_vertex(v[0])
		triangles += 2


## A hanging line from `a` to `b`, sagging `sag` metres in the middle (a
## negative sag arches up), in `segments` pieces.
static func sagging(a: Vector3, b: Vector3, sag: float, segments := 16) -> Array[Vector3]:
	var out: Array[Vector3] = []
	for k in segments + 1:
		var u := float(k) / segments
		out.append(a.lerp(b, u) - Vector3(0, sag * 4.0 * u * (1.0 - u), 0))
	return out


## A piece drawn with Geo, standing at `at` and moving about where it stands.
func geo(g: Geo, at: Vector3, phase: float, yaw := 0.0, scale := 1.0) -> void:
	solid(g.mesh(), Geo.place(at, yaw, Vector3.ONE * scale), at, phase)


func mesh() -> ArrayMesh:
	if triangles == 0:
		return null
	return st.commit()
