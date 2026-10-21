class_name IslandBuilder
extends RefCounted
## A realm's floating island, built around the simulation's square grid
## (§21.1: "The designs' round rock stays as art around 5.2's square grid";
## "Islands hang over the sky with roots and waterfalls beneath"). One tile
## is one metre, the grid centred on the origin, a height level half a tile
## (G65). Everything here is drawn from the grid's size and a seed, so the
## same island looks the same on every phone.
##
## The method and the numbers are the Screens v3 diorama's (`makeIsland`,
## realm-diorama.js:945–977, and `detail`, :881–911), scaled from its rock
## of radius 12.7 to the grid's: a polar meadow with a noisy edge, painted
## from two noise fields with a swell toward the rim and an accent tint; a
## grass lip, three earth bands and an inverted, jittered rock cone in
## strata; roots, fringes, rocks and vines along the rim; and the meadow's
## tufts, pebbles and flowers drawn as instances. The grid sits in the
## meadow's flat middle, so its tiles meet the grass without a seam.

## §21.1 and G65: one height level is half a metre.
const LEVEL := 0.5
## The meadow's top: the grid's ground sits at y = 0, the grass just under it.
const TOP := 0.0
## The diorama's rock radius, which its numbers are written for.
const DESIGN_R := 12.7
## The meadow's rings and spokes (§21.3: the island stays a small share of
## a realm's 25,000–40,000 triangles).
const RINGS := 12
const SPOKES := 100
## Metres from the grid's edge over which the meadow turns from the grid
## ground's colour and brush to its own painted texture.
const GRID_BLEND := 2.5

var size := Vector2i(12, 12)
var island_seed := 1
var palette := RealmPalette.of("heart")
## The realm type, for the few things only one realm has.
var kind := "heart"
## The lighter level (WorldLook.Detail.LIGHT): fewer, larger pieces.
var light := false
var _phase := 0.0
var _rng := RandomNumberGenerator.new()


func _init(grid: Vector2i, new_seed: int, colours: Dictionary, type := "") -> void:
	size = grid
	island_seed = new_seed
	palette = colours
	kind = type if type != "" else _kind_of(colours)
	_rng.seed = new_seed
	_phase = float(posmod(new_seed, 1000)) / 100.0


## The realm a palette is, when the caller gave only its colours.
static func _kind_of(colours: Dictionary) -> String:
	for k: String in RealmPalette.TYPES:
		if RealmPalette.of(k)["grass"] == colours.get("grass"):
			return k
	return "heart"


## How far the round rock reaches: the grid's corners, and a rim beyond.
## The meadow's spokes, which the rim's lip follows so the two meet.
func _spokes() -> int:
	return SPOKES if not light else 64


## `n` pieces, or their `share` at the lighter level.
func _few(n: int, share: float) -> int:
	return n if not light else maxi(1, roundi(n * share))


func radius() -> float:
	return Vector2(size).length() / 2.0 + 1.4


## The rock's scale against the diorama's.
func scale_k() -> float:
	return radius() / DESIGN_R


## The diorama's edge noise (`EF`, :948): five sines, so no two islands
## share an outline.
func ef(a: float) -> float:
	var s := _phase
	return sin(a * 3 + s) * 0.5 + sin(a * 7 + s * 1.7) * 0.3 + sin(a * 13 + s * 0.3) * 0.22 \
		+ sin(a * 23 + s * 2.1) * 0.12 + sin(a * 37 - s) * 0.07


## The rock's edge at angle `a`.
func edge(a: float) -> float:
	return radius() + 0.4 * ef(a)


## A seeded value in [0, 1) for `i`, the same everywhere.
func noise(i: int) -> float:
	var h := (island_seed * 73856093) ^ (i * 19349663)
	h = (h ^ (h >> 13)) * 1274126177
	return float(posmod(h ^ (h >> 16), 100000)) / 100000.0


## The diorama's soft noise field (`n2`, :951), about 0.5.
func n2(x: float, z: float) -> float:
	var s := _phase
	return 0.5 + 0.25 * sin(x * 1.7 + s) * sin(z * 1.3 - s) + 0.15 * sin(x * 3.1 + z * 2.3 + s) \
		+ 0.1 * sin(x * 5.7 - z * 4.9)


## A smooth 3D hash in [0, 1) (`n3`, :93).
static func n3(x: float, y: float, z: float) -> float:
	var s := sin(x * 12.9898 + y * 78.233 + z * 37.719) * 43758.5453
	return s - floorf(s)


## How far a point lies outside the grid, in metres; 0 on it.
func off_grid(x: float, z: float) -> float:
	var half := Vector2(size) / 2.0
	return Vector2(maxf(absf(x) - half.x, 0.0), maxf(absf(z) - half.y, 0.0)).length()


## The meadow's height: flat under the grid, swelling into a soft bank
## between the grid and the rim, rolling down at the edge (`hAt`, :952).
func height(x: float, z: float) -> float:
	var r := Vector2(x, z).length()
	var e := edge(atan2(z, x))
	var bank := smoothstep(0.5, 2.2, off_grid(x, z)) * (1.0 - smoothstep(e - 0.75, e - 0.1, r))
	return TOP - 0.02 + bank * (0.12 + 0.45 * n2(x * 0.66, z * 0.66))


## A colour darkened by multiplying, as three.js's `multiplyScalar`, still
## opaque.
static func _dim(c: Color, f: float) -> Color:
	return Color(c.r * f, c.g * f, c.b * f, 1.0)


## A colour moved in hue, saturation and lightness, as three.js's
## `offsetHSL` moves it.
static func hsl(c: Color, dh: float, ds: float, dl: float) -> Color:
	var mx := maxf(c.r, maxf(c.g, c.b))
	var mn := minf(c.r, minf(c.g, c.b))
	var l := (mx + mn) / 2.0
	var s := 0.0
	if mx != mn:
		s = (mx - mn) / (2.0 - mx - mn) if l > 0.5 else (mx - mn) / (mx + mn)
	var h := c.h
	h = fposmod(h + dh, 1.0)
	s = clampf(s + ds, 0.0, 1.0)
	l = clampf(l + dl, 0.0, 1.0)
	var q := l * (1.0 + s) if l < 0.5 else l + s - l * s
	var p := 2.0 * l - q
	return Color(_hue(p, q, h + 1.0 / 3.0), _hue(p, q, h), _hue(p, q, h - 1.0 / 3.0), c.a)


static func _hue(p: float, q: float, t: float) -> float:
	t = fposmod(t, 1.0)
	if t < 1.0 / 6.0:
		return p + (q - p) * 6.0 * t
	if t < 0.5:
		return q
	if t < 2.0 / 3.0:
		return p + (q - p) * (2.0 / 3.0 - t) * 6.0
	return p


## The meadow: a polar grid from the middle to the edge, its rings closer
## toward the rim where the bank and the colour change; vertex colour from
## the diorama's two noise fields, lighter on the bank, a touch of the
## realm's accent, darker at the rim. Smooth-shaded; painted by the shader.
func meadow() -> ArrayMesh:
	var m := LookMesh.new()
	var grass: Color = palette["grass"]
	var gc := hsl(grass, 0.0, -0.08, -0.03)
	var lt := hsl(gc, 0.015, 0.02, 0.06)
	var dk := hsl(gc, -0.01, 0.02, -0.1)
	var accent: Color = palette["accent"]
	var pts: Array[PackedVector3Array] = []
	var nrm: Array[PackedVector3Array] = []
	var col: Array[PackedColorArray] = []
	var off: Array[PackedFloat32Array] = []
	var rings := RINGS if not light else 8
	var spokes := _spokes()
	for i in rings + 1:
		var f := 1.0 - pow(1.0 - float(i) / rings, 1.7)
		var row := PackedVector3Array()
		var nrow := PackedVector3Array()
		var crow := PackedColorArray()
		var orow := PackedFloat32Array()
		for j in spokes:
			var a := TAU * j / spokes
			var e := edge(a)
			var r := f * e
			var x := cos(a) * r
			var z := sin(a) * r
			var h := height(x, z)
			row.append(Vector3(x, h, z))
			var dx := height(x + 0.05, z) - height(x - 0.05, z)
			var dz := height(x, z + 0.05) - height(x, z - 0.05)
			nrow.append(Vector3(-dx / 0.1, 1.0, -dz / 0.1).normalized())
			var nn := n2(x * 0.42 + 3.0, z * 0.42 - 2.0)
			var c := gc.lerp(lt if nn > 0.55 else dk, minf(1.0, absf(nn - 0.55) * 1.8))
			if h > 0.05:
				c = c.lerp(lt, minf(0.8, h * 1.4))
			var w := n2(x * 0.22 + 9.0, z * 0.22 - 4.0)
			if w > 0.62:
				c = c.lerp(accent, minf(0.22, (w - 0.62) * 0.9))
			if w < 0.36:
				c = hsl(c, 0.02, 0.06, 0.02)
			if kind == "tidehold":
				# A beach of sand round the rim (:889).
				c = c.lerp(Color("#E8D9B0"), smoothstep(e - 1.9, e - 1.2, r) * 0.85)
			c = c.lerp(dk, smoothstep(e - 0.7, e, r) * 0.45)
			# Next to the grid, the grid ground's own colour (KitGround paints
			# the grass `grass`), so the meadow runs on under the tiles.
			var beside := off_grid(x, z)
			c = c.lerp(grass, 1.0 - smoothstep(0.0, GRID_BLEND, beside))
			crow.append(c)
			orow.append(beside)
		pts.append(row)
		nrm.append(nrow)
		col.append(crow)
		off.append(orow)
	for i in rings:
		for j in spokes:
			var j1 := (j + 1) % spokes
			var a := pts[i][j]
			var b := pts[i][j1]
			var c := pts[i + 1][j]
			var d := pts[i + 1][j1]
			var ua := Vector2(off[i][j], 0)
			var ub := Vector2(off[i][j1], 0)
			var uc := Vector2(off[i + 1][j], 0)
			var ud := Vector2(off[i + 1][j1], 0)
			m.smooth([a, c, b], [nrm[i][j], nrm[i + 1][j], nrm[i][j1]], [col[i][j], col[i + 1][j], col[i][j1]],
				[ua, uc, ub])
			m.smooth([b, c, d], [nrm[i][j1], nrm[i + 1][j], nrm[i + 1][j1]], [col[i][j1], col[i + 1][j],
				col[i + 1][j1]], [ub, uc, ud])
	return m.mesh()


## A band of the rim, or the cone beneath: rings of (radius, height) round
## the edge, pushed out by the edge noise `amt` and jittered by `jit`
## (`jr`, :944) except on the top ring, flat-shaded in strata UV.
func _lathe(m: LookMesh, rings: Array[Vector2], segs: int, amt: float, jit: float, cols: Array[Color],
		v_scale: float, salt: int) -> void:
	var grid: Array[PackedVector3Array] = []
	for i in rings.size():
		var row := PackedVector3Array()
		for j in segs:
			var a := TAU * j / segs
			var r := rings[i].x + amt * ef(a) * signf(rings[i].x)
			var y := rings[i].y
			if i > 0 and r > 0.01:
				var px := cos(a) * r
				var pz := sin(a) * r
				var nr := n3(snappedf(px, 0.02) + salt, snappedf(y, 0.02), snappedf(pz, 0.02)) - 0.5
				var ny := n3(snappedf(pz, 0.02), snappedf(px, 0.02) + salt, snappedf(y, 0.02)) - 0.5
				r += nr * jit * 2.0
				y += ny * jit * 0.6
			row.append(Vector3(cos(a) * maxf(r, 0.0), y, sin(a) * maxf(r, 0.0)))
		grid.append(row)
	var reps := 10.0
	for i in rings.size() - 1:
		var base: Color = cols[mini(i, cols.size() - 1)]
		for j in segs:
			var j1 := (j + 1) % segs
			var a := grid[i][j]
			var b := grid[i][j1]
			var c := grid[i + 1][j]
			var d := grid[i + 1][j1]
			var u0 := reps * j / segs
			var u1 := reps * (j + 1) / segs
			var out := Vector3(cos(TAU * (j + 0.5) / segs), -0.25, sin(TAU * (j + 0.5) / segs))
			var shade := base.darkened(0.08 * noise(salt * 977 + i * 131 + j))
			m.tri(a, b, d, shade, out, Vector2(u0, -a.y * v_scale), Vector2(u1, -b.y * v_scale),
				Vector2(u1, -d.y * v_scale))
			m.tri(a, d, c, shade, out, Vector2(u0, -a.y * v_scale), Vector2(u1, -d.y * v_scale),
				Vector2(u0, -c.y * v_scale))


## The rim and the rock beneath, one mesh in strata: the grass lip, the
## three earth bands (:958), the inverted rock cone (:960), a second cone
## hanging off-centre (:961) and a ring of hanging spikes (:962).
func cliffs() -> ArrayMesh:
	var m := LookMesh.new()
	var s := scale_k()
	var grass: Color = palette["grass"]
	var dirt: Color = palette["dirt"]
	var cliff: Color = palette["cliff"]
	var deep: Color = palette["cliff_deep"]
	var e := radius()
	var lip: Array[Vector2] = [Vector2(e + 0.05, -0.02), Vector2(e + 0.08, -0.12), Vector2(e - 0.02, -0.36)]
	_lathe(m, lip, _spokes(), 0.4, 0.0, [_dim(grass, 0.92), _dim(grass, 0.8)], 2.2, 1)
	var bands: Array[Vector2] = [Vector2(e - 0.02, -0.36), Vector2(e - 0.2 * s - 0.02, -0.82),
		Vector2(e - 0.58 * s, -1.24), Vector2(e - 1.04 * s, -1.74)]
	var dirt_dark := _dim(dirt, 0.76)
	_lathe(m, bands, 96 if not light else 56, 0.4, 0.05, [dirt, dirt_dark, cliff.lerp(dirt, 0.35)], 2.2, 2)
	var cone: Array[Vector2] = []
	var top_r := e - 1.04 * s
	# The diorama's cone is 10 deep, stretched 1.45 times when the camera
	# looks down on the whole island (realm-diorama.js:963), so it shows
	# below the rim from the home camera's 35°.
	var depth := 13.0 * s
	for i in 9:
		var f := float(i) / 8.0
		cone.append(Vector2(top_r * (1.0 - f) * (1.0 - 0.15 * f * (1.0 - f)), -1.74 - depth * f))
	# Darker than the sky behind it, so the rock reads under the island.
	_lathe(m, cone, 30 if not light else 20, 0.3, 0.6 * s + 0.15, [cliff.lerp(deep, 0.7).darkened(0.12)], 0.9, 3)
	# A second, smaller cone off-centre, so the rock is not a spinning top.
	var off := Vector3(2.3, 0, -1.3) * s
	var sub := LookMesh.new()
	var sub_rings: Array[Vector2] = [Vector2(5.4 * s, 0.0), Vector2(3.6 * s, -1.8 * s), Vector2(1.8 * s, -3.6 * s),
		Vector2(0.0, -5.4 * s)]
	_lathe(sub, sub_rings, 12, 0.0, 0.5 * s, [deep], 0.9, 4)
	var drop := Vector3(off.x, -1.74 - depth * 0.62, off.z)
	for i in sub.verts.size() / 3:
		m.tri(sub.verts[i * 3] + drop, sub.verts[i * 3 + 2] + drop, sub.verts[i * 3 + 1] + drop, sub.colours[i * 3],
			sub.normals[i * 3], sub.uvs[i * 3], sub.uvs[i * 3 + 2], sub.uvs[i * 3 + 1])
	# Hanging spikes of the deeper rock under the rim.
	for i in 12:
		var h := 1.6 + _rng.randf() * 2.6
		var a := _rng.randf() * TAU
		var r := (7.3 + _rng.randf() * 2.4) * s
		var w := (0.6 + _rng.randf() * 0.7) * maxf(s, 0.7)
		var tip := Vector3(cos(a) * r, -1.5 - h, sin(a) * r)
		for kk in 6:
			var a0 := TAU * kk / 6.0
			var a1 := TAU * (kk + 1) / 6.0
			var p0 := Vector3(cos(a) * r + cos(a0) * w, -1.5, sin(a) * r + sin(a0) * w)
			var p1 := Vector3(cos(a) * r + cos(a1) * w, -1.5, sin(a) * r + sin(a1) * w)
			var mid := (p0 + p1) / 2.0 - Vector3(cos(a) * r, -1.5, sin(a) * r)
			m.tri(p0, p1, tip, deep.darkened(0.06 * (kk % 2)), mid, Vector2(kk * 0.3, 1.5 * 0.9),
				Vector2(kk * 0.3 + 0.3, 1.5 * 0.9), Vector2(kk * 0.3 + 0.15, (1.5 + h) * 0.9))
	return m.mesh()


## Roots hanging from under the rim and curtains of them off the rock
## (§21.1; `detail`, :885), with vines and their leaves swaying (:900).
## Two meshes: the roots, still; the vines, which the shader sways by the
## distance along each (UV.y).
func roots() -> Array[ArrayMesh]:
	var m := LookMesh.new()
	var vines := LookMesh.new()
	var s := scale_k()
	var dirt: Color = palette["dirt"]
	var root_col := _dim(dirt, 0.7)
	var count := _few(22 if kind != "emberreach" else 10, 0.55)
	for i in count:
		var q := _rng.randf() * TAU
		var e := edge(q) - 0.3
		var pts := PackedVector3Array()
		var x := cos(q) * e
		var z := sin(q) * e
		var y := -0.4
		var steps := 5 + _rng.randi() % 4
		for kk in steps:
			pts.append(Vector3(x, y, z))
			x += cos(q) * 0.12 + (_rng.randf() - 0.5) * 0.25
			z += sin(q) * 0.12 + (_rng.randf() - 0.5) * 0.25
			y -= 0.35 + _rng.randf() * 0.25
		m.tube(pts, 0.1, 0.03, 3, root_col)
	# Curtains: long roots off the cone's flank, deeper under the island.
	for i in _few(16 if kind != "emberreach" else 6, 0.5):
		var q := TAU * (i + _rng.randf() * 0.6) / 16.0
		var r := (radius() - 1.3 * s) * (0.75 + 0.15 * _rng.randf())
		var pts := PackedVector3Array()
		var y := -1.9 - _rng.randf() * 1.2
		var x := cos(q) * r
		var z := sin(q) * r
		for kk in 6:
			pts.append(Vector3(x, y, z))
			x += cos(q) * 0.08 + (_rng.randf() - 0.5) * 0.18
			z += sin(q) * 0.08 + (_rng.randf() - 0.5) * 0.18
			y -= 0.7 + _rng.randf() * 0.5
		m.tube(pts, 0.09, 0.025, 3, root_col.darkened(0.1))
	var vine_col := Color("#3F8A45")
	match kind:
		"emberreach":
			vine_col = Color("#5A3A30")
		"crystalline":
			vine_col = Color("#6A5FA8")
		"lanternvale":
			vine_col = Color("#2F6A5A")
	for i in _few(24, 0.5):
		var q := _rng.randf() * TAU
		var r := edge(q) - 0.45
		var top := Vector3(cos(q) * r, -0.5 - _rng.randf() * 0.6, sin(q) * r)
		var length := 1.2 + _rng.randf() * 3.0
		var pts := PackedVector3Array([top, top + Vector3(cos(q) * 0.1, -length * 0.5, sin(q) * 0.1),
			top + Vector3(cos(q) * 0.12, -length, sin(q) * 0.12)])
		vines.tube(pts, 0.03, 0.015, 3, vine_col)
		for leaf in 3:
			var at := pts[0].lerp(pts[2], (leaf + 1) / 3.0)
			var side := 0.07 if leaf % 2 == 0 else -0.07
			var p := at + Vector3(-sin(q) * side, 0, cos(q) * side)
			var before := vines.uvs.size()
			vines.octa(Transform3D(Basis().scaled(Vector3(0.08, 0.05, 0.08)), p), vine_col.lightened(0.12))
			for u in range(before, vines.uvs.size()):
				vines.uvs[u] = Vector2(0, length * (leaf + 1) / 3.0)
	return [m.mesh(), vines.mesh()]


## The scatter: each kind one MultiMesh (§21.3: few draw calls), placed by
## the seed. Returns [mesh, transforms, colours, sway, drift] for each kind:
## grass tufts and pebbles and flowers on the meadow off the grid (:907–911),
## and along the rim the grass fringe, the hanging fringe and rocks (:883–885).
func scatter() -> Array:
	var out := []
	var grass: Color = palette["grass"]
	var gc := Color(grass)
	var tuft_cols: Array[Color] = [hsl(gc, 0.0, 0.05, -0.08), hsl(gc, 0.02, 0.05, 0.04)]
	var accent: Color = palette["accent"]
	var bloom: Color = palette["bloom"]
	var rock: Color = palette["cliff"]
	var stone: Color = palette["stone"]
	match kind:
		"emberreach":
			tuft_cols = [Color("#8A5A48"), Color("#9A6A50")]
		"crystalline":
			tuft_cols = [Color("#A8A2D8"), Color("#E6E2F8")]
	# The lighter level: a third of the tufts, half as large again.
	var tufts := _meadow_spots(_few(270 if kind != "emberreach" else 90, 0.36), 0.15)
	var grow := 1.0 if not light else 1.5
	out.append([_tuft_mesh(), _spin_all(tufts, 0.8 * grow, 1.3 * grow), _pick(tufts.size(), tuft_cols), 0.25, 0.0])
	var pebbles := _meadow_spots(_few(70, 0.4), 0.1)
	out.append([_octa_mesh(), _spin_all(pebbles, 0.04, 0.09, 0.6), _pick(pebbles.size(), [stone, rock]), 0.0, 0.0])
	if kind != "emberreach" and kind != "crystalline":
		var flowers := _meadow_spots(_few(130, 0.4), 0.1)
		var fc: Array[Color] = [accent, Color.WHITE, Color("#FFE08F"), bloom]
		out.append([_flower_mesh(), _spin_all(flowers, 0.8, 1.4), _pick(flowers.size(), fc), 0.12, 0.0])
	elif kind == "crystalline":
		var shards := _meadow_spots(_few(70, 0.5), 0.1)
		var glowing := Color("#BFAEFF")
		glowing.a = 0.6
		out.append([_shard_mesh(), _spin_all(shards, 0.7, 1.6), _pick(shards.size(), [glowing]), 0.0, 0.0])
	else:
		# Glowing lava runnels in the rust ground, as Emberreach's land still
		# shows them: long, thin and few, with short cracks between.
		var embers := _meadow_spots(_few(40, 0.6), 0.3)
		var hot := Color("#FF8A3C")
		hot.a = 0.0
		var melt := Color("#FFB04A")
		melt.a = 0.0
		var runs: Array[Transform3D] = []
		for i in embers.size():
			var long := 2.2 + _rng.randf() * 2.0 if i % 3 == 0 else 0.8 + _rng.randf() * 0.7
			var wide := 1.4 if i % 3 == 0 else 1.0
			runs.append(Transform3D(Basis(Vector3.UP, _rng.randf() * TAU).scaled(Vector3(long, 1.0, wide)), embers[i]))
		out.append([_ember_mesh(), runs, _pick(runs.size(), [hot, melt]), 0.0, 0.0])
	# The rim's grass fringe: soft flattened lumps along the edge.
	if kind != "emberreach":
		var bumps: Array[Transform3D] = []
		var bump_cols: Array[Color] = []
		var gc2 := hsl(gc, 0.0, 0.08, -0.07)
		var gap := 0.62 if not light else 0.9
		var n := int(TAU * radius() / gap)
		for i in n:
			var q := TAU * i / n + _rng.randf() * 0.02
			var e := edge(q)
			var sz := (0.3 + _rng.randf() * 0.18) * gap / 0.62
			var at := Vector3(cos(q) * (e - 0.05), -0.1 - _rng.randf() * 0.08, sin(q) * (e - 0.05))
			bumps.append(Transform3D(Basis(Vector3.UP, _rng.randf() * TAU).scaled(Vector3(1.1, 0.55, 1.1) * sz), at))
			bump_cols.append(gc2.lerp(hsl(gc, 0.0, 0.05, -0.14), _rng.randf() * 0.6))
		out.append([_puff_mesh(), bumps, bump_cols, 0.0, 0.0])
	# The hanging fringe: grass cones pointing down under the lip.
	var cones: Array[Transform3D] = []
	var cone_cols: Array[Color] = []
	var fringe := _few(110 if kind != "emberreach" else 50, 0.55)
	for i in fringe:
		var q := TAU * i / fringe + _rng.randf() * 0.05
		var hh := 0.18 + _rng.randf() * 0.4
		var r := edge(q) - 0.06
		var w := (0.1 + _rng.randf() * 0.09) * (1.0 if not light else 1.4)
		cones.append(Transform3D(Basis().scaled(Vector3(w, hh, w)), Vector3(cos(q) * r, -0.3, sin(q) * r)))
		var hang: Color = _dim(grass, 0.85) if kind != "emberreach" else palette["dirt"]
		cone_cols.append(hang.lerp(grass, _rng.randf() * 0.3))
	out.append([_hang_mesh(), cones, cone_cols, 0.0, 0.0])
	# Rocks on the rim, in small clusters.
	var rocks: Array[Transform3D] = []
	var rock_cols: Array[Color] = []
	rock = rock.lerp(palette["dirt"], 0.3)
	var mixed := rock.lerp(palette["dirt"], 0.5)
	for i in _few(20, 0.5):
		var q := _rng.randf() * TAU
		var e := edge(q) - 0.1
		var n := 2 + _rng.randi() % 3
		for kk in n:
			var sz := 0.18 + _rng.randf() * 0.26
			var p := Vector3(cos(q) * e + (_rng.randf() - 0.5) * 0.5, -0.06 + _rng.randf() * 0.16,
				sin(q) * e + (_rng.randf() - 0.5) * 0.5)
			rocks.append(Transform3D(Basis(Vector3(_rng.randf(), 1, _rng.randf()).normalized(), _rng.randf() * TAU)
				.scaled(Vector3(1.0, 0.75, 1.0) * sz), p))
			rock_cols.append(rock if kk % 2 == 1 else mixed)
	out.append([ico_mesh(), rocks, rock_cols, 0.0, 0.0])
	out.append_array(signature())
	if kind != "emberreach" and kind != "lanternvale":
		# Fireflies for the night (§21.2: at night "lanterns and glows carry the
		# realm"), shown by the hour.
		var spots := _meadow_spots(_few(64, 0.4), -10.0)
		var flies: Array[Transform3D] = []
		for p in spots:
			flies.append(Transform3D(Basis().scaled(Vector3.ONE * (0.05 + _rng.randf() * 0.04)),
				p + Vector3(0, 0.25 + _rng.randf() * 1.2, 0)))
		var fly := Color("#E8FF9A") if kind != "crystalline" else Color("#BFEAFF")
		fly.a = 0.0
		out.append([_octa_mesh(), flies, _pick(flies.size(), [fly, Color(1.0, 0.86, 0.5, 0.0)]), 0.0, 0.25, "night"])
		var pools := _glows(_few(18, 0.5), [Color("#D8FF9A"), Color("#FFD27A")], 0.7, 1.3)
		pools[5] = "night glow"
		out.append(pools)
		var birds: Array[Transform3D] = []
		for i in 9:
			var a := TAU * i / 9.0 + _rng.randf() * 0.4
			var d := radius() + 0.5 + _rng.randf() * 3.0
			var face := Basis(Vector3.UP, -a)
			birds.append(Transform3D(face.scaled(Vector3.ONE * (2.0 + _rng.randf() * 0.8)),
				Vector3(cos(a) * d, 1.6 + _rng.randf() * 2.4, sin(a) * d)))
		out.append([_bird_mesh(), birds, _pick(birds.size(), [Color.WHITE]), 0.0, 0.0, "bird"])
	return out


## A bird: a V of two wings, 0.36 m across, flying along -Z.
static func _bird_mesh() -> ArrayMesh:
	var m := LookMesh.new()
	var body := Vector3(0, 0, 0)
	var nose := Vector3(0, 0, -0.06)
	m.tri(body, nose, Vector3(-0.18, 0.02, 0.03), Color.WHITE, Vector3.UP)
	m.tri(body, nose, Vector3(0.18, 0.02, 0.03), Color.WHITE, Vector3.UP)
	return m.mesh()


## Each realm's own dressing off the grid (§21.4's "Signature terrain and
## props", "Plants" and "Sky and particles"; the diorama's `deco`,
## :891–899): Crystalline's crystal spires round the rim, Skyfield's fence
## of posts, Lantern Vale's fireflies and glowing caps, the Heart's golden
## motes, Emberreach's sparks, Verdant's pollen. Same form as `scatter`, with
## a fifth value, how far each drifts on the wind, and an optional sixth:
## how far each rises before it starts again, "glow" for pools of light,
## "bird" for the flock, "butterfly", "streak" for wind streaks (no mesh),
## "twinkle" for glowing pieces that sparkle, "night" for what shows only
## after dark, or "night glow" for pools of light that do.
func signature() -> Array:
	var out := []
	var accent: Color = palette["accent"]
	match kind:
		"crystalline":
			var spires: Array[Transform3D] = []
			var cols: Array[Color] = []
			var n := _few(40, 0.6)
			for i in n:
				var q := TAU * i / n + _rng.randf() * 0.08
				var r := edge(q) - 0.35 - _rng.randf() * 0.5
				var sz := 0.22 + _rng.randf() * 0.24
				var tilt := Basis(Vector3(_rng.randf() - 0.5, 0, _rng.randf() - 0.5).normalized(), _rng.randf() * 0.4)
				spires.append(Transform3D(tilt * Basis(Vector3.UP, _rng.randf() * TAU).scaled(
					Vector3(sz, sz * (2.0 + _rng.randf() * 1.8), sz)), Vector3(cos(q) * r, height(cos(q) * r, sin(q) * r)
					+ 0.1, sin(q) * r)))
				var c := Color("#BFAEFF") if i % 2 == 0 else Color("#9BEAF3")
				c.a = 0.75
				cols.append(c)
			out.append([_octa_mesh(), spires, cols, 0.0, 0.0, "twinkle"])
		"skyfield":
			var one: Array[Transform3D] = [Transform3D()]
			var cream: Array[Color] = [Color("#F6EBD6")]
			out.append([_fence_mesh(), one, cream, 0.0, 0.0])
			var streaks: Array[Transform3D] = []
			for i in 8:
				var a := TAU * i / 8.0 + _rng.randf() * 0.5
				var d := radius() * (0.6 + _rng.randf() * 0.9)
				streaks.append(Transform3D(Basis().scaled(Vector3(3.0 + _rng.randf() * 3.0, 0.09, 1.0)),
					Vector3(cos(a) * d, 1.5 + _rng.randf() * 4.0, sin(a) * d)))
			out.append([null, streaks, _pick(streaks.size(), [Color.WHITE]), 0.0, 0.0, "streak"])
		"lanternvale":
			var flies := _meadow_spots(_few(60, 0.5), 0.0)
			var at: Array[Transform3D] = []
			for p in flies:
				at.append(Transform3D(Basis().scaled(Vector3.ONE * (0.035 + _rng.randf() * 0.03)),
					p + Vector3(0, 0.3 + _rng.randf() * 1.4, 0)))
			var glow := Color("#C8FF96")
			glow.a = 0.0
			out.append([_octa_mesh(), at, _pick(at.size(), [glow, Color(1.0, 0.85, 0.45, 0.0)]), 0.0, 0.25])
			var caps := _meadow_spots(_few(32, 0.6), 0.2)
			var cap_cols: Array[Color] = []
			for i in caps.size():
				var c := Color("#7AD8C8") if i % 3 else Color("#E05CB4")
				c.a = 0.45
				cap_cols.append(c)
			out.append([_mushroom_mesh(), _spin_all(caps, 0.8, 1.5), cap_cols, 0.0, 0.0])
			out.append(_glows(_few(22, 0.6), [Color("#B4FF8C"), Color("#FFD27A"), Color("#7AD8C8")], 0.45, 0.9))
		"heart", "verdant", "emberreach":
			if kind == "verdant":
				var wings: Array[Transform3D] = []
				for p in _meadow_spots(16, 0.5):
					wings.append(Transform3D(Basis(Vector3.UP, _rng.randf() * TAU).scaled(Vector3.ONE * 0.45),
						p + Vector3(0, 0.5 + _rng.randf() * 0.6, 0)))
				var hues: Array[Color] = [Color("#FFE07A"), Color("#F7A6DA"), Color("#FFFFFF"), Color("#9ADFE8")]
				out.append([_bird_mesh(), wings, _pick(wings.size(), hues), 0.0, 0.0, "butterfly"])
			if kind == "emberreach":
				out.append(_glows(12, [Color("#FF6A1C"), Color("#FF9A3C")], 0.5, 1.0))
			var motes := _meadow_spots(_few(60 if kind != "emberreach" else 50, 0.5), -10.0)
			var at: Array[Transform3D] = []
			for p in motes:
				at.append(Transform3D(Basis().scaled(Vector3.ONE * (0.025 + _rng.randf() * 0.025)),
					p + Vector3(0, 0.4 + _rng.randf() * 2.2, 0)))
			var c := Color("#FFD27A") if kind == "heart" else (Color("#FFF6B0") if kind == "verdant" else Color("#FF8A3C"))
			c.a = 0.0
			out.append([_octa_mesh(), at, _pick(at.size(), [c, c.lerp(accent, 0.4)]), 0.0, 0.3,
				2.5 if kind == "emberreach" else 0.8])
	return out


## Pools of light on the meadow off the grid (the grid is the simulation's),
## `lo` to `hi` metres across,
## drawn by look_glow.gdshader (the sixth value "glow").
func _glows(n: int, cols: Array[Color], lo: float, hi: float) -> Array:
	var spots := _meadow_spots(n, 0.3)
	var at: Array[Transform3D] = []
	for p in spots:
		var sz := lerpf(lo, hi, _rng.randf())
		at.append(Transform3D(Basis().scaled(Vector3(sz, 1.0, sz)), p + Vector3(0, 0.02, 0)))
	return [_flat_quad(), at, _pick(at.size(), cols), 0.0, 0.0, "glow"]


## A unit square lying flat, centred, with its UV.
static func _flat_quad() -> ArrayMesh:
	var m := LookMesh.new()
	var a := Vector3(-0.5, 0, -0.5)
	var b := Vector3(0.5, 0, -0.5)
	var c := Vector3(0.5, 0, 0.5)
	var d := Vector3(-0.5, 0, 0.5)
	m.tri(a, b, c, Color.WHITE, Vector3.UP, Vector2(0, 0), Vector2(1, 0), Vector2(1, 1))
	m.tri(a, c, d, Color.WHITE, Vector3.UP, Vector2(0, 0), Vector2(1, 1), Vector2(0, 1))
	return m.mesh()


## A crystal: an octahedron of radius 1, standing on its lower point.
static func _octa_mesh() -> ArrayMesh:
	var m := LookMesh.new()
	var pts := [Vector3(1, 0, 0), Vector3(0, 0, 1), Vector3(-1, 0, 0), Vector3(0, 0, -1)]
	for i in 4:
		var a: Vector3 = pts[i]
		var b: Vector3 = pts[(i + 1) % 4]
		m.tri(a, b, Vector3(0, 1, 0), Color.WHITE, (a + b) / 2.0 + Vector3(0, 0.5, 0))
		m.tri(a, b, Vector3(0, -1, 0), Color.WHITE, (a + b) / 2.0 - Vector3(0, 0.5, 0))
	return m.mesh()


## A glowing mushroom: a short stem under a round cap.
static func _mushroom_mesh() -> ArrayMesh:
	var m := LookMesh.new()
	m.octa(Transform3D(Basis().scaled(Vector3(0.025, 0.06, 0.025)), Vector3(0, 0.05, 0)), Color("#E8E0F0"))
	m.puff(Transform3D(Basis().scaled(Vector3(0.07, 0.04, 0.07)), Vector3(0, 0.11, 0)), Color.WHITE, 3, 6)
	return m.mesh()


## Skyfield's fence: posts and a rail round the rim (:896).
func _fence_mesh() -> ArrayMesh:
	var m := LookMesh.new()
	var n := 56
	for i in n:
		var q := TAU * i / n
		var r := edge(q) - 0.7
		var p := Vector3(cos(q) * r, height(cos(q) * r, sin(q) * r), sin(q) * r)
		_post(m, p, Vector3(0.05, 0.34, 0.05))
		var q2 := TAU * (i + 1) / n
		var r2 := edge(q2) - 0.7
		var p2 := Vector3(cos(q2) * r2, height(cos(q2) * r2, sin(q2) * r2), sin(q2) * r2)
		for y: float in [0.16, 0.27]:
			var a := p + Vector3(0, y, 0)
			var b := p2 + Vector3(0, y, 0)
			var side := (b - a).cross(Vector3.UP).normalized() * 0.018
			m.tri(a - side, b - side, b + side + Vector3(0, 0.03, 0), Color.WHITE, Vector3.UP)
			m.tri(a - side, b + side + Vector3(0, 0.03, 0), a + side + Vector3(0, 0.03, 0), Color.WHITE, Vector3.UP)
			m.tri(a - side, b - side, b - side + Vector3(0, 0.04, 0), Color.WHITE, -side)
			m.tri(a - side, b - side + Vector3(0, 0.04, 0), a - side + Vector3(0, 0.04, 0), Color.WHITE, -side)
	return m.mesh()


## A box post standing on `p`, `box` wide, tall and deep.
static func _post(m: LookMesh, p: Vector3, box: Vector3) -> void:
	var h := Vector3(box.x / 2.0, 0, box.z / 2.0)
	var c: Array[Vector3] = [p + Vector3(-h.x, 0, -h.z), p + Vector3(h.x, 0, -h.z), p + Vector3(h.x, 0, h.z),
		p + Vector3(-h.x, 0, h.z)]
	var up := Vector3(0, box.y, 0)
	for i in 4:
		var a := c[i]
		var b := c[(i + 1) % 4]
		m.tri(a, b, b + up, Color.WHITE, (a + b) / 2.0 - p)
		m.tri(a, b + up, a + up, Color.WHITE, (a + b) / 2.0 - p)
	m.tri(c[0] + up, c[1] + up, c[2] + up, Color.WHITE, Vector3.UP)
	m.tri(c[0] + up, c[2] + up, c[3] + up, Color.WHITE, Vector3.UP)


## Spots on the meadow, off the grid by `margin`, as (x, y, z).
func _meadow_spots(n: int, margin: float) -> PackedVector3Array:
	var out := PackedVector3Array()
	var tries := 0
	while out.size() < n and tries < n * 8:
		tries += 1
		var q := _rng.randf() * TAU
		var r := sqrt(_rng.randf()) * (edge(q) - 0.35)
		var x := cos(q) * r
		var z := sin(q) * r
		if off_grid(x, z) < margin:
			continue
		out.append(Vector3(x, height(x, z), z))
	return out


## A transform for each spot, turned at random and sized from `lo` to `hi`;
## `squash` flattens them.
func _spin_all(spots: PackedVector3Array, lo: float, hi: float, squash := 1.0) -> Array[Transform3D]:
	var out: Array[Transform3D] = []
	for p in spots:
		var sz := lerpf(lo, hi, _rng.randf())
		out.append(Transform3D(Basis(Vector3.UP, _rng.randf() * TAU).scaled(Vector3(sz, sz * squash, sz)), p))
	return out


func _pick(n: int, cols: Array[Color]) -> Array[Color]:
	var out: Array[Color] = []
	for i in n:
		out.append(cols[_rng.randi() % cols.size()])
	return out


## A tuft of three blades leaning out (:907's cones, made a clump).
static func _tuft_mesh() -> ArrayMesh:
	var m := LookMesh.new()
	for b in 3:
		var a := TAU * b / 3.0
		var lean := Vector3(cos(a) * 0.05, 0.0, sin(a) * 0.05)
		var base := Vector3(cos(a) * 0.025, 0, sin(a) * 0.025)
		var tip := base + lean + Vector3(0, 0.15 + 0.04 * b, 0)
		for side in 3:
			var s0 := TAU * side / 3.0
			var s1 := TAU * (side + 1) / 3.0
			var p0 := base + Vector3(cos(s0), 0, sin(s0)) * 0.028
			var p1 := base + Vector3(cos(s1), 0, sin(s1)) * 0.028
			m.tri(p0, p1, tip, Color.WHITE, (p0 + p1) / 2.0 - base + Vector3(0, 0.3, 0))
	return m.mesh()


## A soft lump with round normals, for the rim's grass fringe.
static func _puff_mesh() -> ArrayMesh:
	var m := LookMesh.new()
	m.puff(Transform3D(), Color.WHITE, 3, 5)
	return m.mesh()


## A unit icosahedron, for pebbles, stones and specks of light.
static func ico_mesh() -> ArrayMesh:
	var m := LookMesh.new()
	m.ico(Transform3D(), Color.WHITE)
	return m.mesh()


## A flower: a head of petals on a short stem.
static func _flower_mesh() -> ArrayMesh:
	var m := LookMesh.new()
	m.tri(Vector3(-0.008, 0, 0), Vector3(0.008, 0, 0), Vector3(0, 0.07, 0), Color("#4E9A40"), Vector3(0, 0, 1))
	m.octa(Transform3D(Basis().scaled(Vector3(0.045, 0.03, 0.045)), Vector3(0, 0.075, 0)), Color.WHITE)
	return m.mesh()


## A crystal shard standing up, for Crystalline's meadow (:910).
static func _shard_mesh() -> ArrayMesh:
	var m := LookMesh.new()
	var tip := Vector3(0, 0.16, 0)
	var foot := Vector3(0, -0.02, 0)
	for i in 4:
		var a0 := TAU * i / 4.0
		var a1 := TAU * (i + 1) / 4.0
		var p0 := Vector3(cos(a0), 0.04, sin(a0)) * 0.045
		var p1 := Vector3(cos(a1), 0.04, sin(a1)) * 0.045
		p0.y = 0.03
		p1.y = 0.03
		m.tri(p0, p1, tip, Color.WHITE, (p0 + p1) / 2.0)
		m.tri(p0, p1, foot, Color.WHITE, (p0 + p1) / 2.0 - Vector3(0, 0.05, 0))
	return m.mesh()


## A glowing ember crack, for Emberreach's ground (:911).
static func _ember_mesh() -> ArrayMesh:
	var m := LookMesh.new()
	var a := Vector3(-0.15, 0.012, -0.015)
	var b := Vector3(0.15, 0.012, -0.015)
	var c := Vector3(0.15, 0.012, 0.015)
	var d := Vector3(-0.15, 0.012, 0.015)
	m.tri(a, b, c, Color.WHITE, Vector3.UP)
	m.tri(a, c, d, Color.WHITE, Vector3.UP)
	return m.mesh()


## A cone of radius 1 and height 1 hanging point down from its base.
static func _hang_mesh() -> ArrayMesh:
	var m := LookMesh.new()
	var tip := Vector3(0, -1, 0)
	for i in 5:
		var a0 := TAU * i / 5.0
		var a1 := TAU * (i + 1) / 5.0
		var p0 := Vector3(cos(a0), 0, sin(a0))
		var p1 := Vector3(cos(a1), 0, sin(a1))
		m.tri(p0, p1, tip, Color.WHITE, (p0 + p1) / 2.0)
	return m.mesh()


## Where the waterfalls leave the rim: off the middles of the grid's sides,
## where the meadow is widest, toward the camera's usual side; Tidehold has
## one off every side (§21.4: "waterfalls off the edges").
func fall_angles() -> PackedFloat32Array:
	match kind:
		"crystalline":
			return PackedFloat32Array()
		"tidehold":
			return PackedFloat32Array([0.15, PI / 2.0 - 0.2, PI + 0.1, PI * 1.5 + 0.2])
		"heart":
			return PackedFloat32Array([0.18, PI / 2.0 - 0.15, PI * 1.25])
	return PackedFloat32Array([0.2 + _rng.randf() * 0.2, PI / 2.0 - 0.1 - _rng.randf() * 0.2])


## The waterfalls (`islandFX`, :1004): a pool on the meadow, a ribbon over
## the lip and down past the rock, widening as it falls. Returns [ribbons,
## pools, feet, stones]: the feet are where the mist gathers, the stones
## ring the pools.
func waterfalls() -> Array:
	var ribbons := LookMesh.new()
	var pools := LookMesh.new()
	var feet := PackedVector3Array()
	var stones: Array[Transform3D] = []
	var s := scale_k()
	for a in fall_angles():
		var e := edge(a)
		var ca := cos(a)
		var sa := sin(a)
		var pool_r := e - 1.2
		var pool_c := Vector3(ca * pool_r, height(ca * pool_r, sa * pool_r) + 0.03, sa * pool_r)
		for i in 20:
			var a0 := TAU * i / 20.0
			var a1 := TAU * (i + 1) / 20.0
			# UV.x is how far from the shore, as the water shader reads it.
			pools.tri(pool_c, pool_c + Vector3(cos(a0), 0, sin(a0)) * 0.8, pool_c + Vector3(cos(a1), 0, sin(a1)) * 0.8,
				Color.WHITE, Vector3.UP, Vector2(1, 0), Vector2.ZERO, Vector2.ZERO)
		for st in 9:
			var sa2 := TAU * (st + _rng.randf() * 0.4) / 9.0
			var sp := pool_c + Vector3(cos(sa2), -0.02, sin(sa2)) * (0.8 + _rng.randf() * 0.1)
			var sz := 0.09 + _rng.randf() * 0.07
			stones.append(Transform3D(Basis(Vector3.UP, _rng.randf() * TAU).scaled(Vector3(1.0, 0.6, 1.0) * sz), sp))
		var lip_y := height(ca * (e - 0.3), sa * (e - 0.3)) + 0.03
		var prof: Array[Vector2] = [Vector2(e - 1.2, pool_c.y), Vector2(e - 0.2, lip_y),
			Vector2(e + 0.15, -0.25), Vector2(e + 0.35, -1.4), Vector2(e + 0.5, -3.2), Vector2(e + 0.5, -5.4 * s),
			Vector2(e + 0.4, -7.6 * s)]
		var n := 36
		var prev_l := Vector3.ZERO
		var prev_r := Vector3.ZERO
		for i in n + 1:
			var u := float(i) / n
			var p := _catmull(prof, u)
			var w := 0.55 * (1.0 + u * 0.4)
			var centre := Vector3(ca * p.x, p.y, sa * p.x)
			var side := Vector3(-sa, 0, ca) * w
			var l := centre - side
			var r := centre + side
			if i > 0:
				var u0 := float(i - 1) / n
				var out := Vector3(ca, 0.3, sa)
				ribbons.tri(prev_l, prev_r, r, Color.WHITE, out, Vector2(0, u0), Vector2(1, u0), Vector2(1, u))
				ribbons.tri(prev_l, r, l, Color.WHITE, out, Vector2(0, u0), Vector2(1, u), Vector2(0, u))
			prev_l = l
			prev_r = r
		feet.append(Vector3(ca * (e + 0.4), -7.2 * s, sa * (e + 0.4)))
	return [ribbons.mesh(), pools.mesh(), feet, stones]


## A point `u` of the way along a Catmull-Rom curve through `pts`.
static func _catmull(pts: Array[Vector2], u: float) -> Vector2:
	var n := pts.size() - 1
	var f := clampf(u, 0.0, 1.0) * n
	var i := mini(int(f), n - 1)
	var t := f - i
	var p0 := pts[maxi(i - 1, 0)]
	var p1 := pts[i]
	var p2 := pts[i + 1]
	var p3 := pts[mini(i + 2, n)]
	var t2 := t * t
	var t3 := t2 * t
	return 0.5 * ((2.0 * p1) + (-p0 + p2) * t + (2.0 * p0 - 5.0 * p1 + 4.0 * p2 - p3) * t2
		+ (-p0 + 3.0 * p1 - 3.0 * p2 + p3) * t3)


## Small islets floating beside the island, with a grass cap and, on most,
## a bush (`islandFX`, :1007), one mesh; and where the clouds float at the
## island's level and below (`cloud`, :940), drawn as painted sprites.
func sky_dressing() -> Array:
	var m := LookMesh.new()
	var clouds: Array[Transform3D] = []
	var r := radius()
	var grass: Color = palette["grass"]
	var cliff: Color = palette["cliff"]
	var plant: Color = palette["plant"]
	for i in 4:
		var a := TAU * i / 4.0 + 0.6 + _rng.randf() * 0.6
		var d := r + 2.6 + _rng.randf() * 2.4
		var y := -1.5 + _rng.randf() * 3.0
		var c := Vector3(cos(a) * d, y, sin(a) * d)
		var sz := 0.85 + _rng.randf() * 0.5
		var rim: Array[Vector2] = [Vector2(sz * 1.02, 0.06), Vector2(sz * 0.95, -0.1)]
		var cone: Array[Vector2] = [Vector2(sz * 0.95, -0.1), Vector2(sz * 0.5, -sz * 1.0), Vector2(0.0, -sz * 2.1)]
		var piece := LookMesh.new()
		_lathe(piece, rim, 9, 0.0, 0.0, [_dim(grass, 0.9)], 2.2, 7 + i)
		_lathe(piece, cone, 7, 0.0, 0.08, [cliff], 0.9, 11 + i)
		for t in 9:
			var a0 := TAU * t / 9.0
			var a1 := TAU * (t + 1) / 9.0
			piece.tri(Vector3(0, 0.06, 0), Vector3(cos(a0), 0, sin(a0)) * sz * 1.02 + Vector3(0, 0.06, 0),
				Vector3(cos(a1), 0, sin(a1)) * sz * 1.02 + Vector3(0, 0.06, 0), grass, Vector3.UP)
		if kind != "emberreach" and _rng.randf() < 0.75:
			# A little round tree, as the diorama's islets carry (:1007).
			var trunk := PackedVector3Array([Vector3(0, 0.05, 0), Vector3(0.02, sz * 0.45, 0)])
			piece.tube(trunk, sz * 0.07, sz * 0.05, 4, Palette.WOOD.darkened(0.2))
			piece.puff(Transform3D(Basis().scaled(Vector3(1.0, 0.85, 1.0) * sz * 0.38), Vector3(0, sz * 0.62, 0)),
				plant, 3, 6)
			piece.puff(Transform3D(Basis().scaled(Vector3.ONE * sz * 0.24), Vector3(sz * 0.18, sz * 0.82, 0.04)),
				plant.lightened(0.12), 3, 5)
		elif kind == "crystalline":
			# A crystal standing on it (read from above, a dark boulder looked
			# like a hole).
			piece.octa(Transform3D(Basis().scaled(Vector3(0.22, 0.6, 0.22) * sz), Vector3(0, sz * 0.5, 0)),
				Color("#BFAEFF"))
		else:
			piece.ico(Transform3D(Basis().scaled(Vector3(1, 0.7, 1) * sz * 0.35), Vector3(sz * 0.2, 0.15, 0)),
				(palette["cliff"] as Color).lightened(0.25))
		# Two roots dangling from the islet's point.
		for rt in 2:
			var ra := _rng.randf() * TAU
			var start := Vector3(cos(ra) * sz * 0.3, -sz * 0.9, sin(ra) * sz * 0.3)
			piece.tube(PackedVector3Array([start, start + Vector3(cos(ra) * 0.08, -0.35, sin(ra) * 0.08),
				start + Vector3(cos(ra) * 0.05, -0.7 - _rng.randf() * 0.4, sin(ra) * 0.05)]), 0.04, 0.012, 3,
				_dim(palette["dirt"], 0.7))
		for v in piece.verts.size() / 3:
			m.tri(piece.verts[v * 3] + c, piece.verts[v * 3 + 2] + c, piece.verts[v * 3 + 1] + c, piece.colours[v * 3],
				piece.normals[v * 3], piece.uvs[v * 3], piece.uvs[v * 3 + 2], piece.uvs[v * 3 + 1])
	# Clouds at the island's level and below, a few in front of the rim:
	# each a centre and its width (scale x) and height (scale y).
	for i in 7:
		var a := TAU * (i + _rng.randf() * 0.7) / 7.0
		var d := r + 1.0 + _rng.randf() * 5.5
		var w := 2.2 + _rng.randf() * 2.4
		clouds.append(Transform3D(Basis().scaled(Vector3(w, w * (0.42 + _rng.randf() * 0.12), 1.0)),
			Vector3(cos(a) * d, -2.5 + _rng.randf() * 4.5 - (3.0 if i % 3 == 0 else 0.0), sin(a) * d)))
	if kind == "skyfield":
		# §21.4: Skyfield's "High clouds": a few more, wide and high.
		# Beyond the rim, so none hides the realm.
		for i in 4:
			var a := TAU * (i + 0.5 + _rng.randf() * 0.5) / 4.0
			var d := r * (1.05 + _rng.randf() * 0.5)
			var w := 3.5 + _rng.randf() * 2.5
			clouds.append(Transform3D(Basis().scaled(Vector3(w, w * 0.36, 1.0)),
				Vector3(cos(a) * d, 5.0 + _rng.randf() * 3.0, sin(a) * d)))
	return [m.mesh(), clouds]
