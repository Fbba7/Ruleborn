class_name RealmKit
extends RefCounted
## A realm's ground and features in 3D, from the simulation's own grid
## (`RulebornReplay.features()`, `heights()`, `surfaces()`, `facings()`):
## the ground one painted surface at the tiles' heights (KitGround), every
## feature a piece from the kit on its tile (KitFeatures), every building
## footprint its building (BuildingKit). §21.10's hero features — the ones
## that change a route — are built apart so they carry the ink outline;
## ground features stay ground ("Tall grass, shade and cover are drawn as
## ground", §21.12).
##
## Layers, each one merged mesh (§21.3: under 150 draw calls): `ground` (the
## painted terrain, kit_ground.gdshader), `scatter` (grass tufts), `hero`
## (inked), `prop` (ambient features, not inked), `clear` (see-through),
## `water` and `lava`. `instances()` gives them as MeshInstance3Ds with the
## kit's own materials, which carry each piece's idle motion.
##
## Codes are `RulebornReplay.features()`'s: 0 open, 1 + sim::grid::Feature's
## index.

enum F { OPEN, ROCK_PILLAR, RUIN_WALL, FENCE, FOG_BANK, TALL_GRASS, VAULT, PYLON, BUILDING, CRYSTAL_WALL, HEDGE,
	TREE, BOULDER, STATUE, CRYSTAL_OUTCROP, LAVA_CRACK, STREAM, GRAVEL_PATH, THICKET, SHADE_CANOPY, BUSH, HOT_SPRING,
	LANTERN_POST, SCREE, EMBER_VENT, STATIC_STONE, ARCH, MARSH, FLOWER_MEADOW, ICE_SHEET, POND, BELL_POST,
	STEPPING_STONES, BOUNCE_MUSHROOM, UPDRAFT_VENT, PIT, RAMP, STAIRS, CLIMBING_VINES, WATERFALL, RAPIDS, TUNNEL }

## §21.10: features that change a route, outlined so they read as shapes.
const HERO := [F.ROCK_PILLAR, F.RUIN_WALL, F.FENCE, F.HEDGE, F.TREE, F.BOULDER, F.STATUE, F.CRYSTAL_OUTCROP,
	F.ARCH, F.BELL_POST, F.LANTERN_POST, F.STATIC_STONE, F.BUILDING, F.BOUNCE_MUSHROOM, F.SHADE_CANOPY]
## Water-like ground drawn by the water shader.
const WET := [F.STREAM, F.POND, F.MARSH, F.RAPIDS, F.HOT_SPRING, F.WATERFALL]
## The tint each kind of water takes.
const WATER_TINT := {F.MARSH: "#9CC48A", F.HOT_SPRING: "#C8FFF0", F.RAPIDS: "#D8F2FF"}

static var _shaders := {
	"toon": load("res://world/kit_toon.gdshader"), "outline": load("res://world/kit_outline.gdshader"),
	"clear": load("res://world/kit_clear.gdshader"), "ground": load("res://world/kit_ground.gdshader"),
	"water": load("res://world/water.gdshader"),
}

var size := Vector2i.ZERO
var features := PackedByteArray()
var heights := PackedByteArray()
var surfaces := PackedByteArray()
var facings := PackedByteArray()
var tunnels: Array[Vector2i] = []
var palette := RealmPalette.of("heart")
## §21.4's realm, read from the palette (KitStyle.realm_of).
var realm := "heart"
## The buildings standing, as `RulebornIsland.buildings()` gives them
## ([kind, x, y, side], optionally a level after), when a screen knows them;
## a footprint not listed is the Spire if 3 × 3, else a Hearth.
var buildings: Array = []
## The level a building is drawn at when its own is not given.
var level := 3
## The island's seed (WorldView's, as it gives T2's IslandBuilder), so the
## grid's ground takes the meadow's own colour; 0 when unknown.
var island_seed := 0
## The Vault's tile, which the worn trails lead to; (-1, -1) for none.
var vault_at := Vector2i(-1, -1)

var ground := Geo.new()
var scatter := Geo.new()
var hero := Geo.new()
var prop := Geo.new()
var clear := Geo.new()
var water := Geo.new()
var lava := Geo.new()
## The worn trails, kept for the ground shader (`instances`).
var _lanes: Array = []


func _init(r: RulebornReplay, colours: Dictionary) -> void:
	if r != null:
		size = r.size()
		features = r.features()
		heights = r.heights()
		surfaces = r.surfaces()
		facings = r.facings()
		tunnels = r.tunnels()
		var v: Dictionary = r.vault()
		if v.has("at"):
			vault_at = Vector2i(floori((v["at"] as Vector2).x), floori((v["at"] as Vector2).y))
	palette = colours
	realm = KitStyle.realm_of(colours)
	for g: Geo in [ground, scatter, hero, prop, clear, water, lava]:
		g.skip_down = true


## A kit for a grid given directly (the kit's own shots and tests).
static func of_grid(grid: Vector2i, codes: PackedByteArray, levels: PackedByteArray, ground_kinds: PackedByteArray,
		colours: Dictionary) -> RealmKit:
	var k := RealmKit.new(null, colours)
	k.size = grid
	k.features = codes
	k.heights = levels
	k.surfaces = ground_kinds
	return k


func inside(t: Vector2i) -> bool:
	return t.x >= 0 and t.y >= 0 and t.x < size.x and t.y < size.y


## The middle of tile `t` on the ground at its height.
func centre(t: Vector2i) -> Vector3:
	return Vector3(t.x - size.x / 2.0 + 0.5, height(t), t.y - size.y / 2.0 + 0.5)


func height(t: Vector2i) -> float:
	if not inside(t):
		return 0.0
	var i := t.y * size.x + t.x
	return (heights[i] if i < heights.size() else 0) * IslandBuilder.LEVEL


func code(t: Vector2i) -> int:
	if not inside(t):
		return 0
	var i := t.y * size.x + t.x
	return features[i] if i < features.size() else 0


## The way a directional tile faces, as a yaw: 0 north (−Z), then east,
## south, west; 0 for none.
func yaw(t: Vector2i) -> float:
	var i := t.y * size.x + t.x
	var f := facings[i] if i >= 0 and i < facings.size() else 255
	return 0.0 if f > 3 else -PI / 2.0 * f


## A seeded value in [0, 1) for a tile and a slot, so a tree or a stone
## looks the same on every phone.
static func jitter(t: Vector2i, slot: int) -> float:
	var h := (t.x * 92821) ^ (t.y * 68917) ^ (slot * 31337)
	h = (h ^ (h >> 13)) * 1274126177
	return float(posmod(h ^ (h >> 16), 10000)) / 10000.0


## Build every layer.
func build() -> void:
	var footprints := _footprints()
	var blocked := {}
	for fp: Array in footprints:
		for dy in int(fp[3]):
			for dx in int(fp[3]):
				blocked[Vector2i(fp[1] + dx, fp[2] + dy)] = true
	var kg := KitGround.new(size, heights, surfaces, features, blocked, WET, palette)
	kg.terrain = ground
	kg.water = water
	ground.painted = true
	water.painted = true
	kg.scatter = scatter
	if island_seed != 0:
		kg.island = IslandBuilder.new(size, island_seed, palette)
	kg.trails = _trails(footprints)
	_lanes = kg.trails
	for i in features.size():
		if features[i] in WATER_TINT:
			kg.tints[Vector2i(i % size.x, i / size.x)] = Color(WATER_TINT[features[i]])
	kg.build(func(t: Vector2i) -> bool: return code(t) == F.OPEN and not blocked.has(t))
	var kf := KitFeatures.new(self)
	var mouths := {}
	for m: Vector2i in tunnels:
		mouths[m] = true
	for y in size.y:
		for x in size.x:
			var t := Vector2i(x, y)
			var f := code(t)
			if f != F.OPEN and f != F.BUILDING and not mouths.has(t):
				kf.build(t, f)
	for fp: Array in footprints:
		var a := centre(Vector2i(fp[1], fp[2]))
		var side: int = fp[3]
		var mid := Vector3(a.x + (side - 1) / 2.0, a.y, a.z + (side - 1) / 2.0)
		var turn := 0.0 if fp[0] == "keeper_s_spire" else facing(Vector2i(fp[1], fp[2]), side)
		BuildingKit.build(hero, str(fp[0]), mid, side, int(fp[4]), palette, prop, clear, turn)
	for m: Vector2i in tunnels:
		_tunnel(m)
	# The realm's signature round its home (the Heart's walls, Skyfield's
	# windmills, …), just past the grid, where the Spire stands.
	if footprints.any(func(fp: Array) -> bool: return fp[0] == "keeper_s_spire"):
		KitSignature.build(hero, prop, realm, Vector2(size).length() / 2.0 + 0.5, palette)


## Worn trails joining the buildings' doors and the Vault, as the design's
## lanes join its houses: the shortest set of straight runs that links them
## all (a spanning tree), in tile space.
func _trails(footprints: Array) -> Array:
	var stops: Array[Vector2] = []
	for fp: Array in footprints:
		var side: int = fp[3]
		var mid := Vector2(fp[1], fp[2]) + Vector2(side, side) / 2.0
		var turn := 0.0 if fp[0] == "keeper_s_spire" else facing(Vector2i(fp[1], fp[2]), side)
		stops.append(mid + Vector2(sin(turn), cos(turn)) * (side / 2.0 + 0.45))
	if inside(vault_at):
		stops.append(Vector2(vault_at) + Vector2(0.5, 0.5))
	var out: Array = []
	if stops.size() < 2:
		return out
	var joined: Array[int] = [0]
	while joined.size() < stops.size():
		var best := INF
		var pair := Vector2i(-1, -1)
		for a: int in joined:
			for b in stops.size():
				if b in joined:
					continue
				var d := stops[a].distance_to(stops[b])
				if d < best:
					best = d
					pair = Vector2i(a, b)
		joined.append(pair.y)
		# A lane that bends round the corner of an elbow, as the design's
		# lanes curve between its houses: a quadratic curve in four runs.
		var a2 := stops[pair.x]
		var b2 := stops[pair.y]
		var corner := Vector2(b2.x, a2.y)
		var prev := a2
		for k in range(1, 5):
			var t := k / 4.0
			var p := a2.lerp(corner, t).lerp(corner.lerp(b2, t), t)
			out.append([prev, p])
			prev = p
	return out


## Every building: [kind, x, y, side, level], from `buildings` where a
## screen gave them, else from the Building tiles' footprints.
func _footprints() -> Array:
	var out: Array = []
	var seen := {}
	var given := {}
	for b: Array in buildings:
		if b.size() >= 4:
			given[Vector2i(int(b[1]), int(b[2]))] = b
	for y in size.y:
		for x in size.x:
			var t := Vector2i(x, y)
			if seen.has(t) or code(t) != F.BUILDING:
				continue
			var side := 1
			while x + side < size.x and y + side < size.y and code(Vector2i(x + side, y)) == F.BUILDING \
					and code(Vector2i(x, y + side)) == F.BUILDING:
				side += 1
			if given.has(t):
				side = int(given[t][3])
			for dy in side:
				for dx in side:
					seen[Vector2i(x + dx, y + dy)] = true
			var kind := "keeper_s_spire" if side >= 3 else "hearth"
			var lvl := level
			if given.has(t):
				kind = str(given[t][0])
				if (given[t] as Array).size() > 4:
					lvl = int(given[t][4])
			out.append([kind, x, y, side, lvl])
	return out


## Which way a building's door faces, as the design's houses face their
## lanes: toward the side of its footprint with the most path beside it
## (then the most open ground), south when none is better. A yaw from +Z.
func facing(nw: Vector2i, side: int) -> float:
	var best := -1.0
	var way := 0.0
	# South, east, north, west: the door's side and the yaw that turns +Z to it.
	for option: Array in [[Vector2i(0, 1), 0.0], [Vector2i(1, 0), PI / 2.0], [Vector2i(0, -1), PI],
			[Vector2i(-1, 0), -PI / 2.0]]:
		var d: Vector2i = option[0]
		var score := 0.0
		for k in side:
			var t := nw
			if d.y > 0:
				t = nw + Vector2i(k, side)
			elif d.y < 0:
				t = nw + Vector2i(k, -1)
			elif d.x > 0:
				t = nw + Vector2i(side, k)
			else:
				t = nw + Vector2i(-1, k)
			if not inside(t):
				continue
			var i := t.y * size.x + t.x
			var gravel := i < surfaces.size() and surfaces[i] == KitGround.GRAVEL
			if gravel or code(t) == F.GRAVEL_PATH:
				score += 1.0
			elif code(t) == F.OPEN:
				score += 0.1
		# A little for facing the first camera, so a tie stays south.
		score += 0.05 if d.y > 0 else 0.0
		if score > best:
			best = score
			way = option[1]
	return way


## A tunnel's mouth: a grassy mound with a dark arch toward its partner.
func _tunnel(m: Vector2i) -> void:
	var c := centre(m)
	var rock: Color = palette["rock"]
	hero.ball(Geo.place(c, 0.0, Vector3(1.0, 0.62, 1.0)), 0.44, rock.lightened(0.05), 4, 10, true)
	prop.ball(Geo.place(c + Vector3(0, 0.22, 0), 0.0, Vector3(1.0, 0.4, 1.0)), 0.36, palette["grass"].darkened(0.08), 3,
		10, true)
	prop.cyl(Transform3D(Basis(Vector3.RIGHT, PI / 2.0), c + Vector3(0, 0.0, 0.42)), 0.2, 0.2, 0.04,
		Palette.INK.lightened(0.05), 10)
	for k in 5:
		var a := PI * (k + 0.5) / 5.0
		hero.rbox(Geo.place(c + Vector3(cos(a) * 0.24, sin(a) * 0.24, 0.42)), Vector3(0.1, 0.1, 0.08),
			palette["stone"].darkened(0.05), 0.015)


## The layers as instances with the kit's materials: the painted ground,
## the inked heroes, the props and tufts, the see-through, water and lava.
func instances() -> Array[MeshInstance3D]:
	var out: Array[MeshInstance3D] = []
	var ground_mat := material("ground")
	ground_mat.set_shader_parameter("grid_offset", Vector2(0.5 * (size.x % 2), 0.5 * (size.y % 2)))
	ground_mat.set_shader_parameter("cobble", KitGround.earth(palette).lightened(0.18))
	ground_mat.set_shader_parameter("mortar", palette["soil"].lightened(0.15))
	# The trails, as world-space segments (xz of each end), for the shader to
	# draw crisp.
	var lanes := PackedVector4Array()
	var half := Vector2(size) / 2.0
	for seg: Array in _lanes.slice(0, KitGround.LANES):
		var a: Vector2 = (seg[0] as Vector2) - half
		var b: Vector2 = (seg[1] as Vector2) - half
		lanes.append(Vector4(a.x, a.y, b.x, b.y))
	ground_mat.set_shader_parameter("lane_count", lanes.size())
	if lanes.size() > 0:
		lanes.resize(KitGround.LANES)
		ground_mat.set_shader_parameter("lanes", lanes)
	ground_mat.set_shader_parameter("lane_earth", KitGround.earth(palette).lerp(palette["soil"], 0.2))
	var water_mat := material("water")
	water_mat.set_shader_parameter("bank", KitGround.earth(palette).lightened(0.2).lerp(palette["grass"], 0.2))
	var lava_mat := material("water")
	lava_mat.set_shader_parameter("deep", Color("#C8401E"))
	lava_mat.set_shader_parameter("foam", Color("#FFC24A"))
	lava_mat.set_shader_parameter("glowing", 0.8)
	for layer: Array in [[ground, ground_mat, true], [scatter, material("toon"), false],
			[hero, material("toon", true), true], [prop, material("toon"), true], [clear, material("clear"), false],
			[water, water_mat, false], [lava, lava_mat, false]]:
		var m := (layer[0] as Geo).mesh()
		if m == null:
			continue
		var mi := MeshInstance3D.new()
		mi.mesh = m
		mi.material_override = layer[1]
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON if layer[2] \
			else GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		out.append(mi)
	return out


## A kit material: `toon` (optionally inked), `clear`, `ground`, `water`.
static func material(kind: String, outlined := false) -> ShaderMaterial:
	var m := ShaderMaterial.new()
	m.shader = _shaders[kind]
	if outlined:
		var o := ShaderMaterial.new()
		o.shader = _shaders["outline"]
		m.next_pass = o
	return m
