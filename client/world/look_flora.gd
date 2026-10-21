class_name LookFlora
extends RefCounted
## Each realm's plants on the meadow off the grid (§21.4's "Plants" column),
## as the design's realm view draws them (art/design/stills/screens/
## 04-realm-view.png): fallen petals scattered over the grass and round
## flowering bushes standing in it. The Heart's pale pink petals and
## blossom bushes, Verdant's leafy bushes and yellow flowers, Skyfield's
## dandelion puffs, Tidehold's reeds, Crystalline's frost moss, Emberreach's
## ember grass; Lantern Vale's glowing caps are its signature already.
## Three MultiMeshes a realm, in IslandBuilder.scatter's form.

## Per realm: petal colours, bush body and bloom colours, and how many of
## each on a 12 by 12 grid's island (the lighter level takes fewer).
const KINDS := {
	"heart": {"petals": ["#F8C8DA", "#F0B0CC", "#FFE8F0"], "bush": "#E596BE", "bloom": "#FFD8EA", "n_petals": 320,
		"n_bushes": 22},
	"verdant": {"petals": ["#FFE58A", "#FFFFFF", "#F7C6E0"], "bush": "#5CA850", "bloom": "#FFE27A", "n_petals": 220,
		"n_bushes": 26},
	"skyfield": {"petals": ["#FFFFFF", "#FFF4C8"], "bush": "#C8D07A", "bloom": "#FFFFFF", "n_petals": 160,
		"n_bushes": 18},
	"tidehold": {"petals": ["#F3E6C0", "#BFE8E0"], "bush": "#3E7A5E", "bloom": "#7CC8A0", "n_petals": 120,
		"n_bushes": 16},
	"crystalline": {"petals": ["#E6E2F8", "#C8C0F0"], "bush": "#8E88C0", "bloom": "#D8D2F4", "n_petals": 140,
		"n_bushes": 14},
	"emberreach": {"petals": ["#E0A04A", "#B86A3A"], "bush": "#6A4034", "bloom": "#E07A3C", "n_petals": 90,
		"n_bushes": 10},
}


## The petals and the bushes for `b`'s realm, or nothing for a realm
## without its own plants here.
static func parts(b: IslandBuilder) -> Array:
	if not KINDS.has(b.kind):
		return []
	var k: Dictionary = KINDS[b.kind]
	var rng := RandomNumberGenerator.new()
	rng.seed = b.island_seed * 31 + 7
	var out := []
	var share := 0.45 if b.light else 1.0
	# As many on a bigger island as on a 12 by 12 one (§21.3's budget).
	var area := minf(1.0, (b.radius() * b.radius()) / (8.6 * 8.6))
	# Petals: small ovals lying flat in the grass, turned every way.
	var spots := b.meadow_spots(roundi(int(k["n_petals"]) * share * area), 0.05)
	var at: Array[Transform3D] = []
	var cols: Array[Color] = []
	var petal_cols: Array = k["petals"]
	for p: Vector3 in spots:
		var sz := 0.13 + rng.randf() * 0.09
		var tilt := Basis(Vector3(rng.randf() - 0.5, 0, rng.randf() - 0.5).normalized(), rng.randf() * 0.25)
		at.append(Transform3D(tilt * Basis(Vector3.UP, rng.randf() * TAU).scaled(Vector3(sz, 1.0, sz)),
			p + Vector3(0, 0.025, 0)))
		cols.append(Color(petal_cols[rng.randi() % petal_cols.size()]))
	out.append([petal_mesh(), at, cols, 0.0, 0.0])
	# Bushes: round puffs with blooms on top, the blooms their own instances
	# (in the Compatibility renderer an instance's colour takes the place of
	# the mesh's own, so each part carries its colour there).
	var bush_at: Array[Transform3D] = []
	var bush_cols: Array[Color] = []
	var bloom_cols: Array[Color] = []
	var body := Color(k["bush"])
	var bloom := Color(k["bloom"])
	for p: Vector3 in b.meadow_spots(roundi(int(k["n_bushes"]) * share * area), 0.4):
		var sz := (0.28 + rng.randf() * 0.2) * (1.3 if b.light else 1.0)
		bush_at.append(Transform3D(Basis(Vector3.UP, rng.randf() * TAU).scaled(Vector3(sz, sz * 0.85, sz)), p))
		bush_cols.append(body.lerp(body.darkened(0.2), rng.randf()))
		bloom_cols.append(bloom.lerp(Color.WHITE, rng.randf() * 0.4))
	out.append([bush_mesh(), bush_at, bush_cols, 0.06, 0.0])
	out.append([bloom_mesh(), bush_at.duplicate(), bloom_cols, 0.06, 0.0])
	return out


## A petal: a flat rhombus of two triangles, 1 m long before scaling; at
## its size on screen it reads as an oval.
static func petal_mesh() -> ArrayMesh:
	var m := LookMesh.new()
	var a := Vector3(-0.5, 0, 0)
	var b := Vector3(0, 0, -0.32)
	var c := Vector3(0.5, 0, 0)
	var d := Vector3(0, 0, 0.32)
	m.tri(a, b, c, Color.WHITE, Vector3.UP)
	m.tri(a, c, d, Color.WHITE, Vector3.UP)
	return m.mesh()


## A bush: a round body of leaves, 1 m across before scaling.
static func bush_mesh() -> ArrayMesh:
	var m := LookMesh.new()
	m.puff(Transform3D(Basis().scaled(Vector3(1.0, 0.8, 1.0)), Vector3(0, 0.38, 0)), Color.WHITE, 3, 7)
	m.puff(Transform3D(Basis().scaled(Vector3.ONE * 0.62), Vector3(0.38, 0.28, 0.1)), Color.WHITE, 3, 6)
	return soft(m)


## The blooms on a bush's top: three round flowers, placed as the bush is.
static func bloom_mesh() -> ArrayMesh:
	var m := LookMesh.new()
	for i in 3:
		var a := TAU * i / 3.0 + 0.4
		m.puff(Transform3D(Basis().scaled(Vector3.ONE * 0.34), Vector3(cos(a) * 0.3, 0.7, sin(a) * 0.3)),
			Color.WHITE, 2, 5)
	return soft(m)


## `m` with its normals bent upward, as foliage is lit in a picture book: a
## small round puff would otherwise stand mostly in the toon ramp's two dark
## steps and read as a dark blot at the home camera's zoom.
static func soft(m: LookMesh) -> ArrayMesh:
	for i in m.normals.size():
		m.normals[i] = (m.normals[i] + Vector3.UP * 1.3).normalized()
	return m.mesh()
