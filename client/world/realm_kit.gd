class_name RealmKit
extends RefCounted
## A realm's ground and features in 3D, from the simulation's own grid
## (`RulebornReplay.features()`, `heights()`, `surfaces()`, `facings()`):
## every tile a flagstone at its height, every feature a piece from this kit
## on its tile. §21.10's hero features — the ones that change a route — are
## built apart so they carry the ink outline; ground features stay ground
## ("Tall grass, shade and cover are drawn as ground", §21.12).
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

var size := Vector2i.ZERO
var features := PackedByteArray()
var heights := PackedByteArray()
var surfaces := PackedByteArray()
var facings := PackedByteArray()
var tunnels: Array[Vector2i] = []
var palette := RealmPalette.of("heart")

var ground := Geo.new()
var hero := Geo.new()
var clear := Geo.new()
var water := Geo.new()
var lava := Geo.new()


func _init(r: RulebornReplay, colours: Dictionary) -> void:
	size = r.size()
	features = r.features()
	heights = r.heights()
	surfaces = r.surfaces()
	facings = r.facings()
	tunnels = r.tunnels()
	palette = colours


## The middle of tile `t` on the ground at its height.
func centre(t: Vector2i) -> Vector3:
	return Vector3(t.x - size.x / 2.0 + 0.5, height(t), t.y - size.y / 2.0 + 0.5)


func height(t: Vector2i) -> float:
	var i := t.y * size.x + t.x
	return (heights[i] if i >= 0 and i < heights.size() else 0) * IslandBuilder.LEVEL


func code(t: Vector2i) -> int:
	var i := t.y * size.x + t.x
	return features[i] if i >= 0 and i < features.size() else 0


## The way a directional tile faces, as a yaw: 0 north (−Z), then east,
## south, west; 0 for none.
func yaw(t: Vector2i) -> float:
	var i := t.y * size.x + t.x
	var f := facings[i] if i < facings.size() else 255
	return 0.0 if f > 3 else -PI / 2.0 * f


## A seeded value in [0, 1) for a tile and a slot, so a tree or a stone
## looks the same on every phone.
static func jitter(t: Vector2i, slot: int) -> float:
	var h := (t.x * 92821) ^ (t.y * 68917) ^ (slot * 31337)
	h = (h ^ (h >> 13)) * 1274126177
	return float(posmod(h ^ (h >> 16), 10000)) / 10000.0


## Build every layer.
func build() -> void:
	for y in size.y:
		for x in size.x:
			var t := Vector2i(x, y)
			_tile(t)
			_feature(t, code(t))
	_buildings()
	for k in range(0, tunnels.size() - 1, 2):
		for m: Vector2i in [tunnels[k], tunnels[k + 1]]:
			var c := centre(m)
			ground.ring(Geo.place(c + Vector3(0, 0.03, 0)), 0.0, 0.34, palette["soil"].darkened(0.6), 14)
			hero.prism(Geo.place(c), 10, 0.42, 0.36, 0.22, palette["rock"])


## A flagstone at the tile's height: its surface's colour on top, the earth
## and stone of its levels down its sides.
func _tile(t: Vector2i) -> void:
	var i := t.y * size.x + t.x
	var h := height(t)
	var c := centre(t)
	var surface: int = surfaces[i] if i < surfaces.size() else 0
	var top: Color = palette["ground"]
	match surface:
		1:
			top = Palette.GRAVEL
		3:
			top = Color("#7FB069")
	# Every other flagstone a shade apart, so the grid reads in a still.
	top = top.darkened(0.035 * ((t.x + t.y) % 2) + 0.03 * jitter(t, 0))
	if surface == 2 or code(t) in WET:
		water.box(Geo.place(c + Vector3(0, -0.06, 0)), Vector3(1.0, 0.04, 1.0), Color.WHITE)
		ground.box(Geo.place(Vector3(c.x, (h - 0.12) / 2.0 - 0.06, c.z)), Vector3(1.0, h + 0.12, 1.0),
			palette["soil"])
		return
	var block := Vector3(0.98, h + 0.12, 0.98)
	ground.box(Geo.place(Vector3(c.x, (h - 0.12) / 2.0, c.z)), block, palette["stone"].darkened(0.12 + 0.05 * h), top)


func _feature(t: Vector2i, f: int) -> void:
	var c := centre(t)
	var j := jitter(t, 1)
	var rock: Color = palette["rock"]
	var plant: Color = palette["plant"]
	var wood := Palette.WOOD
	match f:
		F.ROCK_PILLAR:
			hero.prism(Geo.place(c, j), 6, 0.42, 0.34, 0.9, rock, false, rock.lightened(0.15))
			hero.prism(Geo.place(c + Vector3(0, 0.9, 0), j + 0.4), 6, 0.33, 0.2, 0.55, rock.darkened(0.08))
		F.RUIN_WALL:
			hero.box(Geo.place(c + Vector3(0, 0.35, 0), j * 0.2), Vector3(0.92, 0.7, 0.36), palette["stone"])
			hero.box(Geo.place(c + Vector3(-0.22, 0.82, 0), 0.0), Vector3(0.42, 0.24, 0.34), palette["stone"].darkened(0.06))
		F.FENCE:
			for k in 3:
				hero.box(Geo.place(c + Vector3(-0.38 + 0.38 * k, 0.3, 0)), Vector3(0.09, 0.6, 0.09), wood)
			for y: float in [0.2, 0.45]:
				hero.box(Geo.place(c + Vector3(0, y, 0)), Vector3(0.92, 0.07, 0.05), wood.lightened(0.08))
		F.FOG_BANK:
			for k in 4:
				clear.ball(Geo.place(c + Vector3(jitter(t, k) - 0.5, 0.35 + 0.15 * (k % 2), jitter(t, k + 5) - 0.5) * 0.6,
					0.0, Vector3(1.3, 0.75, 1.3)), 0.4, Color("#F3EEFF"), 4, 8)
		F.TALL_GRASS:
			for k in 7:
				var p := c + Vector3(jitter(t, k) - 0.5, 0, jitter(t, k + 9) - 0.5) * 0.8
				ground.prism(Transform3D(Basis(Vector3(1, 0, 0.3).normalized(), (jitter(t, k + 3) - 0.5) * 0.4), p),
					3, 0.08, 0.0, 0.55 + 0.25 * jitter(t, k + 2), plant.darkened(0.1 * (k % 3)))
		F.CRYSTAL_WALL:
			clear.box(Geo.place(c + Vector3(0, 0.55, 0)), Vector3(0.9, 1.1, 0.3), Palette.MATTER.lightened(0.3))
		F.HEDGE:
			hero.box(Geo.place(c + Vector3(0, 0.36, 0)), Vector3(0.94, 0.72, 0.62), plant.darkened(0.15),
				plant.lightened(0.05))
		F.TREE:
			hero.prism(Geo.place(c), 6, 0.12, 0.09, 0.85, wood.darkened(0.2))
			hero.ball(Geo.place(c + Vector3(0, 1.05, 0), j, Vector3(1.0, 0.85, 1.0)), 0.48, plant, 4, 8)
			hero.ball(Geo.place(c + Vector3(0.18, 1.35, 0.1), j), 0.3, plant.lightened(0.1), 3, 7)
		F.BOULDER:
			hero.ball(Geo.place(c + Vector3(0, 0.3, 0), j * TAU, Vector3(1.0, 0.75, 0.9)), 0.42, rock.lightened(0.05), 4, 7)
		F.STATUE:
			hero.box(Geo.place(c + Vector3(0, 0.12, 0)), Vector3(0.6, 0.24, 0.6), palette["stone"])
			hero.prism(Geo.place(c + Vector3(0, 0.24, 0)), 8, 0.2, 0.14, 0.6, palette["stone"].lightened(0.08), true)
			hero.ball(Geo.place(c + Vector3(0, 0.98, 0)), 0.17, palette["stone"].lightened(0.08), 3, 7)
		F.CRYSTAL_OUTCROP:
			for k in 4:
				var tilt := Basis(Vector3(jitter(t, k) - 0.5, 0, jitter(t, k + 4) - 0.5).normalized(), 0.3)
				hero.prism(Transform3D(tilt, c + Vector3(jitter(t, k + 1) - 0.5, 0, jitter(t, k + 2) - 0.5) * 0.5),
					6, 0.12, 0.0, 0.5 + 0.5 * jitter(t, k + 3), Palette.MATTER.lightened(0.35 - 0.1 * k))
		F.LAVA_CRACK:
			lava.box(Geo.place(c + Vector3(0, 0.005, 0), j), Vector3(0.8, 0.02, 0.18), Color.WHITE)
			lava.box(Geo.place(c + Vector3(0.15, 0.005, 0.1), j + 1.1), Vector3(0.45, 0.02, 0.14), Color.WHITE)
		F.GRAVEL_PATH:
			for k in 5:
				ground.ball(Geo.place(c + Vector3(jitter(t, k) - 0.5, 0.01, jitter(t, k + 6) - 0.5) * 0.8,
					0.0, Vector3(1, 0.4, 1)), 0.06, Palette.GRAVEL.darkened(0.15), 2, 5)
		F.THICKET:
			for k in 5:
				ground.ball(Geo.place(c + Vector3(jitter(t, k) - 0.5, 0.25, jitter(t, k + 3) - 0.5) * 0.7),
					0.26, plant.darkened(0.25), 3, 6)
		F.SHADE_CANOPY:
			for p: Vector2 in [Vector2(-0.4, -0.4), Vector2(0.4, -0.4), Vector2(-0.4, 0.4), Vector2(0.4, 0.4)]:
				hero.box(Geo.place(c + Vector3(p.x, 0.55, p.y)), Vector3(0.06, 1.1, 0.06), wood)
			hero.box(Geo.place(c + Vector3(0, 1.12, 0)), Vector3(1.0, 0.06, 1.0), palette["trim"].lightened(0.3))
		F.BUSH:
			ground.ball(Geo.place(c + Vector3(0, 0.22, 0), j, Vector3(1.0, 0.8, 1.0)), 0.3, plant.darkened(0.05), 3, 7)
		F.HOT_SPRING:
			for k in 3:
				clear.ball(Geo.place(c + Vector3(jitter(t, k) - 0.5, 0.35 + 0.25 * k, jitter(t, k + 1) - 0.5) * 0.5),
					0.16 + 0.05 * k, Color.WHITE, 3, 6)
		F.LANTERN_POST:
			hero.prism(Geo.place(c), 6, 0.06, 0.05, 1.2, Palette.INK.lightened(0.15))
			hero.box(Geo.place(c + Vector3(0, 1.28, 0)), Vector3(0.24, 0.26, 0.24), Color(palette["accent"], 0.0))
		F.SCREE:
			for k in 7:
				ground.ball(Geo.place(c + Vector3(jitter(t, k) - 0.5, 0.04, jitter(t, k + 7) - 0.5) * 0.85,
					jitter(t, k) * TAU), 0.08 + 0.05 * jitter(t, k + 1), rock.lightened(0.1), 2, 5)
		F.EMBER_VENT:
			ground.prism(Geo.place(c), 7, 0.4, 0.2, 0.3, rock.darkened(0.2))
			ground.ring(Geo.place(c + Vector3(0, 0.31, 0)), 0.0, 0.18, Color(Palette.ENERGY, 0.0), 10)
		F.STATIC_STONE:
			hero.prism(Geo.place(c, j), 5, 0.2, 0.14, 0.95, rock.lightened(0.2))
			hero.ring(Geo.place(c + Vector3(0, 0.96, 0)), 0.0, 0.12, Color(Palette.TIME, 0.0), 8)
		F.ARCH:
			for x: float in [-0.36, 0.36]:
				hero.box(Geo.place(c + Vector3(x, 0.55, 0), yaw(t)), Vector3(0.2, 1.1, 0.3), palette["stone"])
			hero.box(Geo.place(c + Vector3(0, 1.2, 0), yaw(t)), Vector3(0.96, 0.22, 0.34), palette["stone"].lightened(0.06))
		F.MARSH:
			for k in 5:
				ground.prism(Geo.place(c + Vector3(jitter(t, k) - 0.5, -0.05, jitter(t, k + 2) - 0.5) * 0.8), 3, 0.03, 0.0,
					0.45, plant.darkened(0.3))
		F.FLOWER_MEADOW:
			for k in 9:
				var p := c + Vector3(jitter(t, k) - 0.5, 0.02, jitter(t, k + 9) - 0.5) * 0.85
				var petal: Color = [Palette.SPIRIT, Palette.MOTION, Palette.PAPER][k % 3]
				ground.ball(Geo.place(p + Vector3(0, 0.08, 0)), 0.06, petal.lightened(0.2), 2, 5)
		F.ICE_SHEET:
			clear.box(Geo.place(c + Vector3(0, 0.02, 0)), Vector3(0.98, 0.05, 0.98), Color("#DDF4FF"))
		F.BELL_POST:
			hero.box(Geo.place(c + Vector3(0, 0.55, 0)), Vector3(0.1, 1.1, 0.1), wood)
			hero.box(Geo.place(c + Vector3(0.18, 1.08, 0)), Vector3(0.44, 0.07, 0.07), wood)
			hero.prism(Transform3D(Basis(Vector3.RIGHT, PI), c + Vector3(0.32, 1.04, 0)), 8, 0.0, 0.14, 0.24,
				palette["trim"], true)
		F.STEPPING_STONES:
			for k in 3:
				ground.prism(Geo.place(c + Vector3(-0.3 + 0.3 * k, -0.04, (jitter(t, k) - 0.5) * 0.4)), 7, 0.15, 0.14,
					0.1, rock.lightened(0.2))
		F.BOUNCE_MUSHROOM:
			hero.prism(Geo.place(c), 7, 0.1, 0.08, 0.4, Palette.PAPER)
			hero.ball(Geo.place(c + Vector3(0, 0.45, 0), 0.0, Vector3(1.0, 0.55, 1.0)), 0.36, Palette.SPIRIT.lightened(0.15),
				3, 9)
		F.UPDRAFT_VENT:
			ground.ring(Geo.place(c + Vector3(0, 0.02, 0)), 0.18, 0.42, rock.darkened(0.1), 14)
			ground.ring(Geo.place(c + Vector3(0, 0.03, 0)), 0.0, 0.18, Color(Palette.PAPER, 0.0), 10)
		F.PIT:
			ground.box(Geo.place(c + Vector3(0, 0.01, 0)), Vector3(0.84, 0.02, 0.84), Palette.INK.lightened(0.05))
		F.RAMP:
			ground.wedge(Geo.place(c + Vector3(0, 0.0, 0), yaw(t)), Vector3(0.96, IslandBuilder.LEVEL, 0.96),
				palette["stone"].lightened(0.05))
		F.STAIRS:
			for k in 3:
				var step := Vector3(0, 0, 0.32 - 0.32 * k).rotated(Vector3.UP, yaw(t))
				ground.box(Geo.place(c + step + Vector3(0, IslandBuilder.LEVEL * (k + 1) / 6.0, 0), yaw(t)),
					Vector3(0.9, IslandBuilder.LEVEL * (k + 1) / 3.0, 0.32), palette["stone"].lightened(0.08))
		F.CLIMBING_VINES:
			for k in 4:
				ground.prism(Geo.place(c + Vector3(-0.3 + 0.2 * k, 0, -0.45).rotated(Vector3.UP, yaw(t))), 4, 0.04, 0.02,
					0.8, plant.darkened(0.2))
		F.WATERFALL:
			clear.box(Geo.place(c + Vector3(0, 0.45, 0), yaw(t)), Vector3(0.9, 0.9, 0.08), Palette.WATER.lightened(0.2))
		F.RAPIDS:
			for k in 3:
				ground.box(Geo.place(c + Vector3(0, -0.03, -0.3 + 0.3 * k), yaw(t)), Vector3(0.6, 0.02, 0.06), Palette.PAPER)


## §10.1's buildings, each footprint of Building tiles one house: walls of
## dressed stone, a roof in the realm's trim, a door.
func _buildings() -> void:
	var seen := {}
	for y in size.y:
		for x in size.x:
			var t := Vector2i(x, y)
			if seen.has(t) or code(t) != F.BUILDING:
				continue
			# The footprint: the square of Building tiles from its north-west.
			var side := 1
			while x + side < size.x and y + side < size.y and code(Vector2i(x + side, y)) == F.BUILDING \
					and code(Vector2i(x, y + side)) == F.BUILDING:
				side += 1
			for dy in side:
				for dx in side:
					seen[Vector2i(x + dx, y + dy)] = true
			var a := centre(t)
			var mid := Vector3(a.x + (side - 1) / 2.0, a.y, a.z + (side - 1) / 2.0)
			var wall := Vector3(side - 0.3, 0.8 + 0.25 * side, side - 0.3)
			hero.box(Geo.place(mid + Vector3(0, wall.y / 2.0, 0)), wall, palette["stone"].lightened(0.08))
			var roof := Transform3D(Basis(Vector3.UP, PI / 4.0), mid + Vector3(0, wall.y, 0))
			hero.prism(roof, 4, wall.x * 0.78, 0.0, 0.45 + 0.3 * side, palette["trim"].darkened(0.1))
			hero.box(Geo.place(mid + Vector3(0, 0.28, wall.z / 2.0)), Vector3(0.3, 0.5, 0.04), Palette.WOOD.darkened(0.2))
