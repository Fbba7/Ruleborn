class_name UniverseIsland
extends RefCounted
## One realm as the universe map draws it (§21.1: "Islands hang over the sky
## with roots and waterfalls beneath"; §21.4's realm looks): a floating rock
## in its type's palette, its buildings at their levels from `BuildingKit`,
## its type's dressing, and beneath it what the design hangs under every
## island on the map (realm_diorama.js :1138–1162): crystals glowing in the
## realm's school colour, a halo of that colour, falls of light and water,
## and the rim's bright edge. A far island is drawn with a light rock of its
## own (§21.3: "far islands use simplified rocks"), so a whole universe stays
## inside one realm's triangles.
##
## Everything is written into the map's shared layers — solids, inked
## solids, glows and light — so the whole universe is a few draw calls.

## What falls from an island's rim, by type (the design's `FALL`).
const FALL := {"skyfield": "#9FE6FF", "tidehold": "#8FF0F0", "verdant": "#A8F0FF", "emberreach": "#FF7A2C",
	"crystalline": "#C8B8FF", "lanternvale": "#FFD27A", "heart": "#F7B8FF"}
## The map's night colours for each realm (the design's `REALMS`, :60–67):
## deeper and more saturated than a realm seen by day, so the islands glow
## against the galaxy rather than wash out. Merged over `RealmPalette`.
const NIGHT := {
	"heart": {"grass": "#86C46B", "soil": "#9A6B4F", "rock": "#6A5C8C", "rock2": "#4B3F6E", "accent": "#E05CB4",
		"roof": "#9C3380", "wall": "#F6DDE6"},
	"skyfield": {"grass": "#B2DA6E", "soil": "#B9875C", "rock": "#9C8FB4", "rock2": "#746A92", "accent": "#F2B43C",
		"roof": "#C0502E", "wall": "#FFFFFF"},
	"crystalline": {"grass": "#9C9CCB", "soil": "#8C86B0", "rock": "#4F4C86", "rock2": "#37346A",
		"accent": "#8C6CF0", "roof": "#5A3FB0", "wall": "#D8D4F6", "stone": "#DCD8F0"},
	"tidehold": {"grass": "#74C49C", "soil": "#7C6A58", "rock": "#4E6D86", "rock2": "#375068", "accent": "#3CC6D8",
		"roof": "#1F7F95", "wall": "#E4F4F2"},
	"emberreach": {"grass": "#8C6552", "soil": "#5A3B34", "rock": "#3F2A30", "rock2": "#2B1C22", "accent": "#F07A3C",
		"roof": "#8A2F22", "wall": "#5A4448", "stone": "#A8928A"},
	"verdant": {"grass": "#5FBB5C", "soil": "#7A5A40", "rock": "#6B5846", "rock2": "#4F4034", "accent": "#5CC46A",
		"roof": "#B5533C", "wall": "#E8D2A8"},
	"lanternvale": {"grass": "#3F6D5B", "soil": "#4E3F4A", "rock": "#363160", "rock2": "#26224A", "accent": "#F2B43C",
		"roof": "#4B3C8A", "wall": "#6A5A78", "stone": "#C4BCD8"},
}
## How many peaks stand on each realm's rim (the design's three cones,
## :1146); the gentle realms have none.
const PEAKS := {"skyfield": 2, "crystalline": 3, "emberreach": 3, "lanternvale": 2}
## Path stones, by realm: the Heart's are the design's rose cobbles.
const PATH := {"heart": "#F0B8C8", "lanternvale": "#8E86B8", "emberreach": "#7A5A50"}
## Where buildings stand: the middle, then a ring, then the rim's ring, as
## fractions of the island's radius, and how many places each ring has.
const RINGS := [[0.0, 1], [0.44, 6], [0.7, 9]]
## The Heart's beam (the design's, :1140), in the Spirit pink.
const BEAM := Color("#F7A6DA")

var id := ""
var key := "heart"
var level := 1
## The Keeper's Spire's level, which the Heart's citadel shows.
var spire := 1
var palette := {}
var school := Color.WHITE
var radius := 10.0
var at := Vector3.ZERO
var island_seed := 1
## Each building's place on the map, by "kind:n": where its pin points.
var places := {}
## Ghost: a realm still to open, drawn as mist and outline only.
var ghost := false

## Soft shade on the ground under what stands on it (the map's shade layer).
var shades := UniversePaint.new()

## Where buildings stand, which the meadow keeps clear of.
var _used: Array[Vector3] = []


func _init(realm: Dictionary, where: Vector3) -> void:
	id = str(realm.get("realm", ""))
	key = UniverseLayout.type_key(str(realm.get("type", "Heart")))
	level = int(realm.get("level", 1))
	palette = RealmPalette.of(key)
	var night: Dictionary = NIGHT.get(key, {})
	for k: String in night:
		palette[k] = Color(night[k])
	school = Palette.SCHOOL.get(UniverseLayout.SCHOOLS[key], Palette.SPIRIT)
	radius = UniverseLayout.radius(UniverseLayout.grid(realm))
	at = where
	island_seed = hash(id + key) & 0x7fffffff
	ghost = bool(realm.get("ghost", false))


## A seeded value in [0, 1) for `i`: the same island looks the same on every
## phone.
func noise(i: int) -> float:
	var h := (island_seed * 73856093) ^ (i * 19349663)
	h = (h ^ (h >> 13)) * 1274126177
	return float(posmod(h ^ (h >> 16), 100000)) / 100000.0


## The rim's reach at angle `a`: a few seeded waves, so no two islands share
## an outline.
func edge(a: float) -> float:
	var w := 0.0
	for k in 4:
		w += sin(a * (k + 2) + float(island_seed % 97) * 0.37 * (k + 1)) * 0.3 / (k + 1)
	return radius + w


## A point on the island: `r` of the way out at angle `a`, `y` metres up.
func point(a: float, r: float, y := 0.0) -> Vector3:
	var reach := edge(a) * r
	return at + Vector3(cos(a) * reach, y, sin(a) * reach)


## The ground's height `f` of the way to the rim: a gentle dome.
static func dome(f: float) -> float:
	return 0.18 * (1.0 - f * f) - pow(f, 8.0) * 0.12


## The whole island into the map's layers.
func build(body: Geo, hero: Geo, glows: UniversePaint, light: UniversePaint, flow: UniversePaint,
		buildings: Array) -> void:
	if ghost:
		_ghost(glows, light)
		return
	_top(body)
	_rock(body, hero)
	_beneath(hero, glows, light, flow)
	_dress(hero, glows)
	_buildings(body, hero, glows, buildings)
	if key == "heart":
		light.beam(at + Vector3(0, 9.5, 0), 0.9, 3.0, 30.0, Color(BEAM, 0.22), 16)
		light.beam(at + Vector3(0, 9.5, 0), 0.3, 0.8, 20.0, Color(BEAM.lightened(0.4), 0.3), 10)
		glows.glow(at + Vector3(0, -4.0, 0), radius * 1.9, Color(BEAM, 0.22))


## The grass top: rings from the middle to the rim, shaded in soft patches
## by two noise fields (the design's, :953) so it reads as meadow, not felt,
## lighter at the lip.
func _top(g: Geo) -> void:
	var spokes := 48
	var rings := 7
	var grass: Color = palette["grass"]
	var plant: Color = palette["plant"]
	var accent: Color = palette["accent"]
	for i in rings:
		for k in spokes:
			var a0 := TAU * k / spokes
			var a1 := TAU * (k + 1) / spokes
			var f0 := pow(float(i) / rings, 0.8)
			var f1 := pow(float(i + 1) / rings, 0.8)
			var mid := point((a0 + a1) / 2.0, (f0 + f1) / 2.0)
			var shade := grass.darkened(0.12 + 0.3 * patch(mid)).lerp(plant, 0.25 * patch(mid * 1.7 + Vector3(9, 0, 4)))
			shade = shade.lerp(accent, 0.06 * maxf(0.0, patch(mid * 0.6 + Vector3(3, 0, 7)) - 0.5))
			if i == rings - 1:
				shade = shade.lightened(0.1)
			var p := func(f: float, a: float) -> Vector3: return point(a, f, dome(f))
			g.quad(p.call(f0, a1), p.call(f1, a1), p.call(f1, a0), p.call(f0, a0), shade)
	# A plaza in the middle, in the realm's ground.
	var plaza := 4.4 * UniverseCitadel.MAP_SCALE if key == "heart" else 2.0
	g.prism(Geo.place(at + Vector3(0, dome(0.0) - 0.06, 0)), 16, plaza, plaza * 0.98, 0.1, palette["ground"])
	if key == "heart":
		g.ring(Geo.place(at + Vector3(0, dome(0.0) + 0.05, 0)), plaza * 0.86, plaza * 0.98, palette["trim"], 24)


## A soft field in [0, 1] over the island: where grass grows darker, where
## flowers gather.
func patch(p: Vector3) -> float:
	var q := p - at
	var s := float(island_seed % 31)
	var v := sin(q.x * 0.42 + s) * cos(q.z * 0.37 - s * 0.5) + 0.6 * sin((q.x + q.z) * 0.8 + s * 1.3)
	return clampf(0.5 + v * 0.32, 0.0, 1.0)


## The earth rim and the rock beneath in strata, narrowing to a point, with
## roots, and three peaks on the rim (the design's, :1146).
func _rock(g: Geo, hero: Geo) -> void:
	var spokes := 36
	var soil: Color = palette["soil"]
	var rock: Color = palette["rock"]
	var dark: Color = palette.get("rock2", rock.darkened(0.22))
	var bands: Array = [[-0.04, 1.0, soil.lightened(0.06)], [-0.55, 1.0, soil], [-1.3, 0.95, soil.darkened(0.12)],
		[-2.4, 0.86, rock], [-3.8, 0.72, dark], [-5.4, 0.52, rock.darkened(0.06)], [-7.2, 0.28, dark],
		[-9.0, 0.04, dark.darkened(0.2)]]
	for b in range(bands.size() - 1):
		var y0: float = bands[b][0]
		var y1: float = bands[b + 1][0]
		var r0: float = bands[b][1]
		var r1: float = bands[b + 1][1]
		for k in spokes:
			var a0 := TAU * k / spokes
			var a1 := TAU * (k + 1) / spokes
			var j0 := 1.0 + (noise(b * 131 + k) - 0.5) * (0.0 if b == 0 else 0.16)
			var j1 := 1.0 + (noise(b * 131 + (k + 1) % spokes) - 0.5) * (0.0 if b == 0 else 0.16)
			var k0 := 1.0 + (noise((b + 1) * 131 + k) - 0.5) * 0.16
			var k1 := 1.0 + (noise((b + 1) * 131 + (k + 1) % spokes) - 0.5) * 0.16
			var col: Color = bands[b][2]
			col = col.darkened(0.08 * noise(k * 5 + b)).lightened(0.05 * noise(k * 3 + b * 11))
			g.quad(point(a1, r0 * j1, y0), point(a1, r1 * k1, y1), point(a0, r1 * k0, y1), point(a0, r0 * j0, y0), col)
	for k in 7:
		var a := TAU * (k + noise(k * 3)) / 7.0
		var base := point(a, 0.9, -1.0 - noise(k) * 1.2)
		g.prism(Transform3D(Basis(Vector3.RIGHT, PI), base), 5, 0.14, 0.0, 1.6 + 2.2 * noise(k * 11),
			soil.darkened(0.3), true)
	# Peaks on the rim, capped: snow, or embers in Emberreach, frost at night.
	var cap := Color("#FFFFFF")
	if key == "emberreach":
		cap = Color("#FF7A3C", 0.2)
	elif key == "lanternvale" or key == "crystalline":
		cap = Color("#D8CCFF")
	if not PEAKS.has(key):
		return
	for q in int(PEAKS[key]):
		var a := noise(77) * TAU + q * 2.1 + 0.6
		var h := 2.4 + q * 0.7
		var p := point(a, 0.8, dome(0.8) - 0.2)
		var rock_col: Color = rock.lerp(palette["grass"], 0.25)
		hero.prism(Geo.place(p, a), 7, 1.7 + q * 0.3, 0.55, h * 0.7, rock_col)
		_shade(p, 2.6 + q * 0.3, 0.4)
		hero.prism(Geo.place(p + Vector3(0, h * 0.7, 0), a), 7, 0.62, 0.0, h * 0.38, cap)


## Under the island: crystals in the school's colour on the rock, its halo,
## a falling stream of light from the tip, and falls from the rim.
func _beneath(hero: Geo, glows: UniversePaint, light: UniversePaint, flow: UniversePaint) -> void:
	var glow_col := Color(school, 0.15)
	for q in 6:
		var a := q / 6.0 * TAU + noise(q * 41) * 0.5
		var y := -3.0 - noise(q * 43) * 3.5
		var cone_r := 0.95 - (absf(y) / 9.0) * 0.95
		var p := point(a, cone_r * 0.95, y)
		var h := 1.4 + noise(q * 47) * 1.8
		var tilt := Basis(Vector3(sin(a), 0, -cos(a)), PI + (noise(q) - 0.5) * 0.5)
		hero.prism(Transform3D(tilt, p), 5, 0.4 + noise(q * 53) * 0.3, 0.0, h, glow_col)
		glows.glow(p + Vector3(0, -h * 0.6, 0), 2.4, Color(school.lightened(0.3), 0.5))
	glows.glow(at + Vector3(0, -7.0, 0), radius * 1.6, Color(school, 0.3))
	glows.glow(at + Vector3(0, -9.2, 0), 2.6, Color(school.lightened(0.4), 0.8))
	# A stream of light from the tip, and motes falling from the rim.
	for i in 14:
		var o := Vector3((noise(i * 7) - 0.5) * 2.4, -9.0 - noise(i * 9) * 1.5, (noise(i * 13) - 0.5) * 2.4)
		glows.glow(at + o, 0.32, Color(school.lightened(0.5), 0.9), 10.0 + noise(i) * 4.0)
	var fall := Color(FALL.get(key, "#FFFFFF"))
	var falls := 1 if key == "heart" else 2
	for f in falls:
		var a := noise(f * 211 + 5) * TAU
		_waterfall(flow, glows, a, fall)
		for i in 10:
			var p := point(a + (noise(i * 17 + f) - 0.5) * 0.12, 1.0, -0.3)
			glows.glow(p, 0.22, Color(fall.lightened(0.4), 0.9), 12.0 + noise(i * 19) * 6.0)
	# The rim's bright edge (the design's `edge` torus, :1148).
	var inner := PackedVector3Array()
	var outer := PackedVector3Array()
	for k in 73:
		var a := TAU * k / 72.0
		inner.append(point(a, 0.96, dome(0.96) + 0.04))
		outer.append(point(a, 1.06, -0.1))
	light.strip(inner, outer, Color(school.lerp(Color.WHITE, 0.45), 1.0), 1.0, true)


## A fall of water (or lava, or light) over the rim at `a`, down the rock.
func _waterfall(flow: UniversePaint, glows: UniversePaint, a: float, colour: Color) -> void:
	var left := PackedVector3Array()
	var right := PackedVector3Array()
	var side := Vector3(-sin(a), 0, cos(a)) * 0.65
	for k in 8:
		var f := k / 7.0
		var r := 1.0 + f * 0.06 - f * f * 0.12
		var p := point(a, r, -f * 7.5)
		left.append(p - side * (1.0 + f * 0.5))
		right.append(p + side * (1.0 + f * 0.5))
	flow.strip(left, right, Color(colour, 0.85), 3.0, true, true)
	glows.glow(point(a, 1.06, -7.5), 2.2, Color(colour.lightened(0.3), 0.45))


## The realm's own look (§21.4): trees, crystals, lanterns, lava, by type.
func _dress(hero: Geo, glows: UniversePaint) -> void:
	var plant: Color = palette["plant"]
	var accent: Color = palette["accent"]
	var n := 22
	for i in n:
		var a := TAU * (i + noise(i * 29) * 0.6) / n
		var f := 0.82 + 0.12 * noise(i * 31)
		var p := point(a, f, dome(f) - 0.04)
		var s := 0.8 + 0.5 * noise(i * 37)
		match key:
			"crystalline":
				for c in 3:
					var tilt := Basis(Vector3(cos(a + c), 0, sin(a + c)), 0.25 * (c - 1))
					hero.prism(Transform3D(tilt, p + Vector3(0.3 * (c - 1), 0, 0.2 * c)), 5, 0.22 * s, 0.0,
						(1.0 + 0.6 * c) * s, Color(accent.lerp(Color("#E6DCFF"), 0.3 * c), 0.55))
				glows.glow(p + Vector3(0, 1.0, 0), 1.1, Color(accent, 0.35))
			"emberreach":
				hero.prism(Geo.place(p, a), 5, 0.42 * s, 0.1, 1.8 * s, palette["rock"].darkened(0.1))
				if i % 2 == 0:
					hero.ring(Geo.place(p + Vector3(0.6, 0.05, 0.3)), 0.0, 0.35 * s, Color("#FF7A2C", 0.1), 8)
					glows.glow(p + Vector3(0.6, 0.3, 0.3), 0.9, Color("#FF8A3C", 0.6), -2.5)
			"lanternvale":
				if i % 3 == 0:
					hero.prism(Geo.place(p), 4, 0.05, 0.05, 1.3, Color("#3A2E4A"))
					hero.ball(Geo.place(p + Vector3(0, 1.4, 0)), 0.2, Color("#FFD27A", 0.1), 3, 6)
					glows.glow(p + Vector3(0, 1.4, 0), 1.3, Color("#FFC36A", 0.75))
				else:
					_pine(hero, p, s, Color("#2F5A4A"))
			"skyfield":
				if i % 4 == 0:
					_windmill(hero, p, s, a)
				else:
					for b in 3:
						hero.prism(Geo.place(p + Vector3(0.2 * b - 0.2, 0, 0.15 * b)), 3, 0.08, 0.0, 0.5 * s,
							plant.darkened(0.06 * b))
			"tidehold":
				if i % 3 == 0:
					hero.ring(Geo.place(p + Vector3(0, 0.03, 0)), 0.0, 0.7 * s, Color("#3CC6D8", 0.4), 10)
				else:
					for b in 3:
						hero.prism(Geo.place(p + Vector3(0.18 * b - 0.18, 0, 0.12 * b)), 4, 0.06, 0.02, 0.7 * s,
							plant.darkened(0.08 * b))
			"verdant":
				_tree(hero, p, s * 1.15, plant, i)
			_:
				if i % 2 == 0:
					_tree(hero, p, s, Color("#F2A6CF") if i % 4 == 0 else plant, i)
				else:
					hero.ball(Geo.place(p + Vector3(0, 0.15, 0)), 0.18, accent, 2, 5)


## Shade on the ground at `p`, `r` across, `dark` at its middle.
func _shade(p: Vector3, r: float, dark: float) -> void:
	shades.disc(p + Vector3(0.25, 0.05, 0.25), Vector3.UP, r, Color(0, 0, 0, minf(1.0, dark * 1.3)), 14)


func _tree(g: Geo, p: Vector3, s: float, crown: Color, i: int) -> void:
	_shade(p, 0.85 * s, 0.45)
	g.prism(Geo.place(p), 5, 0.13 * s, 0.09 * s, 0.7 * s, Palette.WOOD.darkened(0.25))
	g.ball(Geo.place(p + Vector3(0, 1.0 * s, 0)), 0.55 * s, crown, 3, 6)
	g.ball(Geo.place(p + Vector3(0.25 * s, 1.3 * s, 0.1 * s)), 0.36 * s, crown.lightened(0.12 + 0.04 * (i % 3)), 3, 6)


func _pine(g: Geo, p: Vector3, s: float, col: Color) -> void:
	g.prism(Geo.place(p), 4, 0.08 * s, 0.08 * s, 0.4 * s, Palette.WOOD.darkened(0.3))
	g.prism(Geo.place(p + Vector3(0, 0.3 * s, 0)), 6, 0.55 * s, 0.0, 1.0 * s, col)
	g.prism(Geo.place(p + Vector3(0, 0.85 * s, 0)), 6, 0.4 * s, 0.0, 0.8 * s, col.lightened(0.08))


func _windmill(g: Geo, p: Vector3, s: float, a: float) -> void:
	g.prism(Geo.place(p), 6, 0.35 * s, 0.22 * s, 1.6 * s, Palette.PAPER.darkened(0.06))
	g.prism(Geo.place(p + Vector3(0, 1.6 * s, 0)), 6, 0.3 * s, 0.0, 0.5 * s, Color("#C0502E"))
	var hub := p + Vector3(cos(a) * 0.3 * s, 1.35 * s, sin(a) * 0.3 * s)
	for b in 4:
		var turn := Basis(Vector3(cos(a), 0, sin(a)), b * PI / 2.0 + 0.4)
		g.box(Transform3D(turn, hub + turn * Vector3(0, 0.45 * s, 0)), Vector3(0.04, 0.9 * s, 0.22 * s),
			Palette.PAPER)


## The realm's buildings, each at its level, in rings from the middle; the
## Heart's middle is its Spire.
func _buildings(body: Geo, hero: Geo, glows: UniversePaint, buildings: Array) -> void:
	var spots := _spots()
	var next := 0
	var lit := key == "lanternvale" or key == "heart" or key == "crystalline"
	if key == "heart":
		# The citadel is the map's own piece, drawn larger than the realm's
		# buildings so the Heart reads from across the universe (the design's
		# Heart is half again the size of its realms).
		_shade(at, 6.2 * UniverseCitadel.MAP_SCALE, 0.55)
		places["keeper_s_spire:1"] = at + Vector3(0, 11.0, 0)
		next = 1
	for b: Dictionary in buildings:
		if next >= spots.size():
			break
		var kind := str(b.get("kind", ""))
		var spot: Vector3 = spots[next]
		next += 1
		var f := Vector2(spot.x - at.x, spot.z - at.z).length() / radius
		var mid := spot + Vector3(0, dome(f), 0)
		var lv := int(b.get("level", 1))
		_path(body, spot)
		_lamp(hero, glows, spot)
		_used.append(spot)
		_shade(mid, 2.1, 0.5)
		if kind == "ward":
			_ward(hero, glows, mid, lv)
		else:
			BuildingKit.build(hero, kind, mid, 4 if kind in ["vault", "keeper_s_spire"] else 3, lv, palette)
		places["%s:%d" % [kind, int(b.get("n", 1))]] = mid + Vector3(0, 2.2, 0)
		# Windows lit, more of them in the realms of night (§21.2: "lanterns
		# and glows carry the realm").
		glows.glow(mid + Vector3(0, 0.7, 0.9), 0.7 if lit else 0.45, Color("#FFC36A", 0.7 if lit else 0.4))


## Stepping stones from the plaza to a building's door.
func _path(g: Geo, to: Vector3) -> void:
	var from := Vector3(at.x, 0, at.z)
	var flat := Vector3(to.x - at.x, 0, to.z - at.z)
	var reach := flat.length()
	if reach < 3.0:
		return
	var dir := flat / reach
	var start := 4.4 * UniverseCitadel.MAP_SCALE if key == "heart" else 1.8
	var stone: Color = Color(PATH[key]) if PATH.has(key) else (palette["ground"] as Color).lightened(0.08)
	var n := int((reach - start - 1.3) / 0.55)
	for k in n:
		var d := start + k * 0.55
		var side := Vector3(-dir.z, 0, dir.x) * (0.12 if k % 2 == 0 else -0.12)
		var p := from + dir * d + side
		var f := d / radius
		g.prism(Geo.place(p + Vector3(0, at.y + dome(f) - 0.02, 0), k * 0.7), 6, 0.26, 0.24, 0.06,
			stone.darkened(0.06 * (k % 3)))


## A lamp where a building's path leaves the plaza: the realm's warm lights
## at night (§21.2: "lanterns and glows carry the realm").
func _lamp(hero: Geo, glows: UniversePaint, to: Vector3) -> void:
	var flat := Vector3(to.x - at.x, 0, to.z - at.z)
	if flat.length() < 3.0:
		return
	var dir := flat.normalized()
	var d := (4.4 * UniverseCitadel.MAP_SCALE if key == "heart" else 1.8) + 0.4
	var p := at + dir * d + Vector3(-dir.z, 0, dir.x) * 0.55
	p.y = at.y + dome(d / radius)
	var post := Color("#3A2E4A") if key in ["lanternvale", "crystalline"] else Palette.WOOD.darkened(0.35)
	hero.prism(Geo.place(p), 4, 0.06, 0.05, 1.15, post)
	hero.ball(Geo.place(p + Vector3(0, 1.22, 0)), 0.13, Color("#FFD27A", 0.1), 2, 5)
	glows.glow(p + Vector3(0, 1.22, 0), 0.95, Color("#FFC36A", 0.85))


## The meadow's tufts and flowers, never on a path or under a building:
## each [transform, colour], for the map's two scatter layers.
func scatter(tufts: Array, flowers: Array) -> void:
	if ghost:
		return
	var grass: Color = palette["grass"]
	var plant: Color = palette["plant"]
	var bloom: Array[Color] = [palette["accent"], Color("#FFFFFF"), Color("#F6D27A"), Color("#F2A6CF")]
	if key == "emberreach":
		bloom = [Color("#FF8A3C", 0.3), Color("#FFC24A", 0.3)]
	elif key == "lanternvale":
		bloom = [Color("#7AD8C8", 0.4), Color("#FFD27A", 0.4)]
	var placed := 0
	for i in 260:
		if placed >= 150:
			break
		var a := noise(i * 7 + 1) * TAU
		var f := sqrt(noise(i * 7 + 2)) * 0.93
		var p := point(a, f, dome(f) - 0.02)
		if f < (0.45 if key == "heart" else 0.17) or _crowded(p):
			continue
		placed += 1
		var turn := Basis(Vector3.UP, noise(i * 7 + 3) * TAU).scaled(Vector3.ONE * (0.7 + 0.6 * noise(i * 7 + 4)))
		if noise(i * 7 + 5) < 0.3 + 0.35 * patch(p * 1.3):
			var c: Color = bloom[int(noise(i * 7 + 6) * bloom.size()) % bloom.size()]
			flowers.append([Transform3D(turn, p), c])
		else:
			var c := grass.darkened(0.1 + 0.15 * noise(i * 11)).lerp(plant, 0.4 * noise(i * 13))
			tufts.append([Transform3D(turn, p), c])


func _crowded(p: Vector3) -> bool:
	for u: Vector3 in _used:
		if Vector2(p.x - u.x, p.z - u.z).length() < 1.7:
			return true
	return false


## A ward: a stone of its school's colour, glowing at its top.
func _ward(hero: Geo, glows: UniversePaint, mid: Vector3, lv: int) -> void:
	hero.prism(Geo.place(mid), 6, 0.42, 0.34, 0.25, palette["stone"])
	hero.prism(Geo.place(mid + Vector3(0, 0.25, 0)), 4, 0.2, 0.0, 1.1 + 0.08 * lv, Color(school, 0.5))
	glows.glow(mid + Vector3(0, 1.0, 0), 1.0, Color(school.lightened(0.3), 0.6))


## Where buildings may stand, from the middle outward, turned a little each
## island so no two realms are laid out alike.
func _spots() -> Array[Vector3]:
	var out: Array[Vector3] = []
	var turn := noise(5) * TAU
	for ring: Array in RINGS:
		var f: float = ring[0]
		var n: int = ring[1]
		if key == "heart" and f == 0.0:
			out.append(at)
			continue
		for k in n:
			var a := turn + TAU * k / n + (0.5 / n if f > 0.5 else 0.0)
			out.append(point(a, f) if f > 0.0 else at)
	return out


## A realm still to open: a faint ring of mist where it will hang.
func _ghost(glows: UniversePaint, light: UniversePaint) -> void:
	var inner := PackedVector3Array()
	var outer := PackedVector3Array()
	for k in 49:
		var a := TAU * k / 48.0
		inner.append(point(a, 0.9, 0.0))
		outer.append(point(a, 1.0, 0.0))
	light.strip(inner, outer, Color(school.lerp(Color.WHITE, 0.5), 0.35), 1.0, true)
	glows.glow(at + Vector3(0, -2.0, 0), radius * 1.4, Color(school, 0.14))
	for i in 10:
		var a := TAU * i / 10.0
		glows.glow(point(a, 0.6 + 0.3 * noise(i), 0.5), 0.5, Color(school.lightened(0.4), 0.5), -1.5)
