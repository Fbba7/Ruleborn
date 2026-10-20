class_name IslandBuilder
extends RefCounted
## A realm's floating island, built around the simulation's square grid
## (§21.1: "The designs' round rock stays as art around 5.2's square grid";
## "Islands hang over the sky with roots and waterfalls beneath"). One tile
## is one metre, the grid centred on the origin, a height level half a tile
## (G65). Everything here is drawn from the grid's size and a seed, so the
## same island looks the same on every phone.

## §21.1 and G65: one height level is half a metre.
const LEVEL := 0.5
## The rock's top: the grid's ground sits at y = 0.
const TOP := 0.0

var size := Vector2i(12, 12)
var island_seed := 1
var palette := RealmPalette.of("heart")


func _init(grid: Vector2i, new_seed: int, colours: Dictionary) -> void:
	size = grid
	island_seed = new_seed
	palette = colours


## How far the round rock reaches: the grid's corners, and a rim beyond.
func radius() -> float:
	return Vector2(size).length() / 2.0 + 1.4


## The rock's edge at angle `a`: a few seeded waves, so no two islands share
## an outline.
func edge(a: float) -> float:
	var r := radius()
	var w := 0.0
	for k in 4:
		var f := float(k + 2)
		w += sin(a * f + float(island_seed % 97) * 0.37 * (k + 1)) * 0.22 / (k + 1)
	return r + w


## A seeded value in [0, 1) for `i`, the same everywhere.
func noise(i: int) -> float:
	var h := (island_seed * 73856093) ^ (i * 19349663)
	h = (h ^ (h >> 13)) * 1274126177
	return float(posmod(h ^ (h >> 16), 100000)) / 100000.0


## The island's rock and earth, one mesh: the grass top around the grid, the
## earth rim, and the inverted rock cone beneath in strata, with roots.
func rock() -> ArrayMesh:
	var g := Geo.new()
	var spokes := 72
	var rings := 6
	var grass: Color = palette["grass"]
	var soil: Color = palette["soil"]
	var stone: Color = palette["rock"]
	# The top: rings from the middle to the edge, a little lower at the rim.
	for i in rings:
		for k in spokes:
			var a0 := TAU * k / spokes
			var a1 := TAU * (k + 1) / spokes
			var f0 := float(i) / rings
			var f1 := float(i + 1) / rings
			var p := func(f: float, a: float) -> Vector3:
				var r := edge(a) * f
				return Vector3(cos(a) * r, TOP - 0.02 - pow(f, 6.0) * 0.12, sin(a) * r)
			var shade := grass.lightened(0.05 * noise(i * spokes + k)).darkened(0.04 * noise(k * 7 + i))
			g.quad(p.call(f0, a1), p.call(f1, a1), p.call(f1, a0), p.call(f0, a0), shade)
	# The earth rim, and the rock below it in bands narrowing to a point.
	# Cliffs first, steep enough to show from §21.1's pitches, then the
	# rock tapering to its point.
	var bands: Array = [[TOP - 0.14, 1.0, soil], [TOP - 0.7, 0.995, soil.darkened(0.1)],
		[TOP - 1.6, 0.97, stone], [TOP - 2.7, 0.93, stone.darkened(0.12)], [TOP - 3.9, 0.85, stone.darkened(0.04)],
		[TOP - 5.2, 0.68, stone.darkened(0.18)], [TOP - 6.6, 0.42, stone.darkened(0.08)],
		[TOP - 8.0, 0.08, stone.darkened(0.28)]]
	for b in range(bands.size() - 1):
		var top_y: float = bands[b][0]
		var low_y: float = bands[b + 1][0]
		for k in spokes:
			var a0 := TAU * k / spokes
			var a1 := TAU * (k + 1) / spokes
			var j0 := 1.0 + (noise(b * 131 + k) - 0.5) * 0.12
			var j1 := 1.0 + (noise(b * 131 + (k + 1) % spokes) - 0.5) * 0.12
			var r_top: float = bands[b][1]
			var r_low: float = bands[b + 1][1]
			var p := func(r: float, y: float, a: float, j: float) -> Vector3:
				return Vector3(cos(a) * edge(a) * r * j, y, sin(a) * edge(a) * r * j)
			var col: Color = bands[b][2]
			g.quad(p.call(r_top, top_y, a1, j1 if b > 0 else 1.0), p.call(r_low, low_y, a1, j1),
				p.call(r_low, low_y, a0, j0), p.call(r_top, top_y, a0, j0 if b > 0 else 1.0),
				col.darkened(0.05 * noise(k + b * 7)))
	# Hanging roots, and a few stones on the rim.
	for k in 9:
		var a := TAU * (k + noise(k * 3)) / 9.0
		var r := edge(a) * (0.78 + 0.1 * noise(k * 5))
		var base := Vector3(cos(a) * r * 1.05, TOP - 2.5 - noise(k) * 1.5, sin(a) * r * 1.05)
		var root := Transform3D(Basis(Vector3.RIGHT, PI), base)
		g.prism(root, 5, 0.12, 0.0, 1.4 + 1.6 * noise(k * 11), soil.darkened(0.25), true)
	for k in 14:
		var a := TAU * (k + noise(k * 13)) / 14.0
		var r := edge(a) * 0.93
		var at := Geo.place(Vector3(cos(a) * r, TOP - 0.05, sin(a) * r), a, Vector3(1.0, 0.7, 1.0))
		g.ball(at, 0.16 + 0.14 * noise(k * 17), stone.lightened(0.15), 3, 6)
	return g.mesh()


## Clouds drifting below the island and a few stones floating beside it
## (§21.1: "Islands hang over the sky"), one mesh.
func sky_dressing() -> ArrayMesh:
	var g := Geo.new()
	var r := radius()
	for k in 6:
		var a := TAU * (k + noise(k * 53)) / 6.0
		var d := r * (1.05 + 0.45 * noise(k * 59))
		var base := Vector3(cos(a) * d, -3.0 - 3.5 * noise(k * 61), sin(a) * d)
		for puff in 4:
			var o := Vector3((puff - 1.5) * 0.9, noise(k * 7 + puff) * 0.3, (noise(k * 3 + puff) - 0.5) * 0.8)
			g.ball(Geo.place(base + o, 0.0, Vector3(1.2, 0.7, 1.0)), 0.6 + 0.35 * noise(k + puff * 5), Color("#FFFFFF"),
				3, 7)
	for k in 5:
		var a := TAU * (k + 0.5 + noise(k * 67)) / 5.0
		var d := r * (1.12 + 0.2 * noise(k * 71))
		var at := Geo.place(Vector3(cos(a) * d, -0.6 - 1.4 * noise(k * 73), sin(a) * d), a)
		g.prism(at, 6, 0.32 + 0.2 * noise(k), 0.38, 0.22, palette["grass"])
		g.prism(Transform3D(Basis(Vector3.RIGHT, PI), at.origin), 6, 0.36, 0.0, 0.7 + 0.5 * noise(k * 79),
			palette["rock"])
	return g.mesh()


## Tufts of grass and flowers on the island's rim, off the grid (§21.4's
## plants), as one mesh.
func scatter() -> ArrayMesh:
	var g := Geo.new()
	var half := Vector2(size) / 2.0
	var plant: Color = palette["plant"]
	var accent: Color = palette["accent"]
	for k in 70:
		var a := TAU * noise(k * 29)
		var f := 0.62 + 0.34 * noise(k * 31)
		var r := edge(a) * f
		var p := Vector3(cos(a) * r, TOP - 0.03, sin(a) * r)
		# Never on the grid, where the realm's own ground and features are.
		if absf(p.x) < half.x + 0.2 and absf(p.z) < half.y + 0.2:
			continue
		if noise(k * 37) < 0.75:
			for blade in 3:
				var tilt := Basis(Vector3(noise(k + blade), 0, noise(k * 2 + blade)).normalized(), 0.35)
				g.prism(Transform3D(tilt, p + Vector3(0.06 * blade - 0.06, 0, 0.04 * blade)), 3, 0.05, 0.0,
					0.22 + 0.12 * noise(k * 41 + blade), plant.darkened(0.08 * blade))
		else:
			g.prism(Geo.place(p), 4, 0.02, 0.02, 0.16, plant.darkened(0.2))
			g.ball(Geo.place(p + Vector3(0, 0.2, 0)), 0.07, accent, 2, 5)
	return g.mesh()
