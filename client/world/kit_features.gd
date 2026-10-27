class_name KitFeatures
extends RefCounted
## §6.2's terrain features on their tiles, each a small sculpt in the kit's
## chunky toy style, ported from the design's defence overlay (Screens v3,
## realm-diorama.js `feat`, :316–376) at its proportions (one of its cells is
## one tile here: its units × 0.45 m) and then pushed further: hedges, fences
## and ruins join their neighbours, trees grow by realm, water sits in a bed.
##
## §21.10: the features that change a route (`RealmKit.HERO`) go in the
## `hero` layer and are inked; the rest are ground texture (`prop`), never
## outlined. Each moves as the design's did — trees sway, bells swing,
## crystals turn, fog drifts, stones float — through the vertex's motion
## (Geo.Anim), so nothing runs per frame.

## The design's cell in metres: its units × K.
const K := 0.45

var kit: RealmKit
var style: Dictionary


func _init(owner: RealmKit) -> void:
	kit = owner
	style = KitStyle.of(owner.realm)


## Draw feature `f` on tile `t`.
func build(t: Vector2i, f: int) -> void:
	var c := kit.centre(t)
	for layer: Geo in [kit.hero, kit.prop, kit.clear]:
		layer.standing(c.y)
	var j := RealmKit.jitter(t, 1)
	var hero := kit.hero
	var prop := kit.prop
	var rock: Color = kit.palette["rock"]
	var plant: Color = kit.palette["plant"]
	var stone: Color = style["stone"]
	var wood := KitStyle.WOOD
	match f:
		RealmKit.F.ROCK_PILLAR:
			_pillar(c, j, rock)
		RealmKit.F.RUIN_WALL:
			_ruin(t, c)
		RealmKit.F.FENCE:
			_fence(t, c)
		RealmKit.F.FOG_BANK:
			# A low, wide drift of flattened puffs spilling past the tile, each
			# bobbing on its own.
			for k in 7:
				var a := TAU * k / 7.0 + RealmKit.jitter(t, k)
				var r := 0.12 + 0.3 * RealmKit.jitter(t, k + 5)
				var o := Vector3(cos(a) * r, 0.14 + 0.1 * RealmKit.jitter(t, k + 2), sin(a) * r)
				kit.clear.moving(Geo.Anim.BOB, c + o + Vector3(k * 3.0, 0, 0))
				kit.clear.ball(Geo.place(c + o, a, Vector3(1.5, 0.45, 1.2)), 0.2 + 0.08 * RealmKit.jitter(t, k + 9),
					Color("#F6F2FF"), 3, 8)
			kit.clear.moving(Geo.Anim.NONE, Vector3.ZERO)
		RealmKit.F.TALL_GRASS:
			_grass(t, c, plant)
		RealmKit.F.CRYSTAL_WALL:
			for k in 5:
				var x := -0.36 + 0.18 * k
				kit.clear.gem(Geo.place(c + Vector3(x, 0.45 + 0.1 * RealmKit.jitter(t, k), 0), k * 0.7),
					0.13 + 0.04 * RealmKit.jitter(t, k + 2), 0.42 + 0.16 * RealmKit.jitter(t, k + 4),
					Color(Palette.MATTER.lightened(0.35), 0.8), 5)
		RealmKit.F.HEDGE:
			_hedge(t, c, plant)
		RealmKit.F.TREE:
			_tree(t, c, j, plant)
		RealmKit.F.BOULDER:
			_boulder(t, c, j, rock)
		RealmKit.F.STATUE:
			_statue(c, j, stone)
		RealmKit.F.CRYSTAL_OUTCROP:
			_crystals(t, c)
		RealmKit.F.LAVA_CRACK:
			_lava(t, c)
		RealmKit.F.GRAVEL_PATH:
			pass  # The ground paints its stones (kit_ground.gdshader); loose grit read as dirt on them.
		RealmKit.F.THICKET:
			prop.moving(Geo.Anim.SWAY, c)
			for k in 6:
				var o := Vector3(RealmKit.jitter(t, k) - 0.5, 0, RealmKit.jitter(t, k + 3) - 0.5) * 0.62
				prop.ball(Geo.place(c + o + Vector3(0, 0.18 + 0.14 * RealmKit.jitter(t, k + 7), 0)),
					0.2 + 0.1 * RealmKit.jitter(t, k + 1), plant.darkened(0.3 + 0.08 * (k % 2)), 3, 7)
			prop.moving(Geo.Anim.NONE, Vector3.ZERO)
		RealmKit.F.SHADE_CANOPY:
			_canopy(c, wood)
		RealmKit.F.BUSH:
			_bush(t, c, j, plant)
		RealmKit.F.HOT_SPRING:
			_spring(t, c, rock)
		RealmKit.F.LANTERN_POST:
			_lantern(c)
		RealmKit.F.SCREE:
			for k in 9:
				prop.rock(Geo.place(c + Vector3(RealmKit.jitter(t, k) - 0.5, 0.03, RealmKit.jitter(t, k + 7) - 0.5) * 0.85,
					RealmKit.jitter(t, k) * TAU, Vector3(1, 0.7, 1)), 0.07 + 0.06 * RealmKit.jitter(t, k + 1),
					rock.lightened(0.08 * (k % 3)), t.x * 3 + k)
		RealmKit.F.EMBER_VENT:
			prop.cyl(Geo.place(c), 0.32, 0.16, 0.22, rock.darkened(0.25), 8)
			prop.rock(Geo.place(c + Vector3(0.22, 0.05, 0.1)), 0.1, rock.darkened(0.1), t.y)
			prop.ring(Geo.place(c + Vector3(0, 0.225, 0)), 0.0, 0.14, Color(Palette.ENERGY.lightened(0.15), 0.1), 10)
			# Sparks rising from the vent, each on its own beat.
			for k in 4:
				var sp := c + Vector3((RealmKit.jitter(t, k) - 0.5) * 0.12, 0.3, (RealmKit.jitter(t, k + 4) - 0.5) * 0.12)
				prop.moving(Geo.Anim.RISE, sp + Vector3(k * 1.7, 0, 0))
				prop.gem(Geo.place(sp), 0.025, 0.035, Color(Palette.ENERGY.lightened(0.3), 0.1), 4)
			prop.moving(Geo.Anim.NONE, Vector3.ZERO)
		RealmKit.F.STATIC_STONE:
			hero.rock(Geo.place(c + Vector3(0, 0.26, 0), j, Vector3(0.8, 1.3, 0.8)), 0.3, Color("#5A6A8A"), t.x + t.y)
			hero.moving(Geo.Anim.SPIN_Y, c)
			for k in 3:
				var a := TAU * k / 3.0
				hero.gem(Geo.place(c + Vector3(cos(a) * 0.36, 0.5 + 0.12 * k, sin(a) * 0.36), a), 0.05, 0.08,
					Color(Color("#7AE8FF"), 0.2), 4)
			hero.moving(Geo.Anim.NONE, Vector3.ZERO)
		RealmKit.F.ARCH:
			_arch(t, c, stone)
		RealmKit.F.MARSH:
			prop.moving(Geo.Anim.SHIVER, c)
			for k in 7:
				var p := c + Vector3(RealmKit.jitter(t, k) - 0.5, -0.12, RealmKit.jitter(t, k + 2) - 0.5) * 0.8
				prop.moving(Geo.Anim.SHIVER, p)
				prop.blade(p, 0.42 + 0.25 * RealmKit.jitter(t, k + 4), 0.03, Color("#6A8A3A"), 0.1, k)
				if k % 3 == 0:
					prop.cyl(Geo.place(p + Vector3(0, 0.28, 0)), 0.03, 0.03, 0.12, Color("#7A4A2A"), 5)
			prop.moving(Geo.Anim.NONE, Vector3.ZERO)
		RealmKit.F.FLOWER_MEADOW:
			var petals: Array[Color] = [Color("#FF8AB0"), Color("#FFE08A"), Color("#FFFFFF"), Color("#B79BFF")]
			var lighter := kit.detail == BuildingKit.MID
			for k in (12 if lighter else 22):
				var p := c + Vector3(RealmKit.jitter(t, k) - 0.5, 0.0, RealmKit.jitter(t, k + 9) - 0.5) * 0.9
				var stem := 0.07 + 0.08 * RealmKit.jitter(t, k + 40)
				prop.moving(Geo.Anim.SHIVER, p)
				prop.blade(p, stem, 0.012, plant.darkened(0.2))
				if lighter:
					# A flat flower head, three petals, at the mid detail.
					prop.gem(Geo.place(p + Vector3(0, stem, 0), RealmKit.jitter(t, k + 3) * TAU, Vector3(1, 0.3, 1)),
						0.06, 0.06, petals[k % 4], 3)
				else:
					prop.ball(Geo.place(p + Vector3(0, stem, 0), 0.0, Vector3(1, 0.55, 1)), 0.05, petals[k % 4], 2, 6)
			prop.moving(Geo.Anim.NONE, Vector3.ZERO)
		RealmKit.F.ICE_SHEET:
			# A frozen pool: an irregular sheet, pale at its rim, with a few
			# white cracks and frost tufts round it.
			var rim: Array[Vector3] = []
			for k in 12:
				var a := TAU * k / 12.0
				var r := 0.44 + 0.06 * (RealmKit.jitter(t, k + 50) - 0.5)
				rim.append(c + Vector3(cos(a) * r, 0.03, sin(a) * r))
			var mid := c + Vector3(0, 0.035, 0)
			for k in 12:
				prop.tri(mid, rim[(k + 1) % 12], rim[k], Color(Color("#BDEBFF"), 0.75))
			for k in 12:
				var a0 := rim[k]
				var a1 := rim[(k + 1) % 12]
				var o0 := (a0 - c) * 1.12 + c + Vector3(0, -0.03, 0)
				var o1 := (a1 - c) * 1.12 + c + Vector3(0, -0.03, 0)
				prop.quad(a0, a1, o1, o0, Color(Color("#F4FBFF"), 0.7))
			for k in 4:
				var a := RealmKit.jitter(t, k + 3) * PI
				prop.box(Geo.place(c + Vector3((RealmKit.jitter(t, k) - 0.5) * 0.4, 0.038, (k - 1.5) * 0.16), a),
					Vector3(0.22 + 0.1 * RealmKit.jitter(t, k + 9), 0.004, 0.012), Color("#FFFFFF"))
		RealmKit.F.BELL_POST:
			_bell(c, j, wood)
		RealmKit.F.STEPPING_STONES:
			for k in 3:
				var p := c + Vector3(-0.3 + 0.3 * k, 0.1, (RealmKit.jitter(t, k) - 0.5) * 0.35)
				prop.moving(Geo.Anim.BOB, p)
				prop.cyl(Geo.place(p), 0.15, 0.17, 0.08, stone.darkened(0.04), 8, stone.lightened(0.06))
				prop.prism(Transform3D(Basis(Vector3.RIGHT, PI), p), 6, 0.15, 0.0, 0.14, kit.palette["rock"])
			prop.moving(Geo.Anim.NONE, Vector3.ZERO)
		RealmKit.F.BOUNCE_MUSHROOM:
			_mushroom(t, c)
		RealmKit.F.UPDRAFT_VENT:
			prop.ring(Geo.place(c + Vector3(0, 0.02, 0)), 0.2, 0.38, rock.darkened(0.15), 14)
			for k in 4:
				prop.box(Geo.place(c + Vector3(0, 0.021, -0.15 + 0.1 * k)), Vector3(0.36, 0.01, 0.03), KitStyle.IRON)
			# Wind spiralling up out of it, and a leaf riding the air.
			kit.clear.moving(Geo.Anim.SPIN_Y, c)
			for s2 in 3:
				for m in 9:
					var a := TAU * s2 / 3.0 + m * 0.55
					var r := 0.18 + 0.025 * m
					kit.clear.box(Geo.place(c + Vector3(cos(a) * r, 0.12 + 0.14 * m, sin(a) * r), -a),
						Vector3(0.16, 0.012, 0.025), Color(Color("#F4FBFF"), 0.6))
			kit.clear.moving(Geo.Anim.NONE, Vector3.ZERO)
			prop.moving(Geo.Anim.SPIN_Y, c)
			prop.box(Geo.place(c + Vector3(0.24, 0.9, 0), 0.6), Vector3(0.07, 0.01, 0.04), kit.palette["plant"])
			prop.moving(Geo.Anim.NONE, Vector3.ZERO)
		RealmKit.F.PIT:
			prop.ring(Geo.place(c + Vector3(0, 0.01, 0)), 0.3, 0.44, kit.palette["soil"].darkened(0.1), 12)
			prop.ring(Geo.place(c + Vector3(0, 0.015, 0)), 0.0, 0.31, Palette.INK.lightened(0.04), 12)
			for k in 6:
				var a := TAU * (k + RealmKit.jitter(t, k)) / 6.0
				prop.rock(Geo.place(c + Vector3(cos(a), 0, sin(a)) * 0.38), 0.07, rock, k)
		RealmKit.F.RAMP:
			_ramp(t, c)
		RealmKit.F.STAIRS:
			var up := _toward(t, 1)
			var steps: Color = style["stone2"]
			for k in 4:
				var step := Vector3(0, 0, 0.375 - 0.25 * k).rotated(Vector3.UP, up)
				var hh := IslandBuilder.LEVEL * (k + 1) / 4.0
				# Dark risers under light treads, so each step reads.
				prop.rbox(Geo.place(c + step + Vector3(0, hh / 2.0, 0), up), Vector3(0.78, hh, 0.25),
					steps.darkened(0.18 - 0.05 * (k % 2)), 0.02, steps.lightened(0.14))
			for sx: float in [-1.0, 1.0]:
				prop.rock(Geo.place(c + Vector3(sx * 0.44, 0.06, 0.3).rotated(Vector3.UP, up)), 0.09,
					kit.palette["rock"], t.x + int(sx))
		RealmKit.F.CLIMBING_VINES:
			_vines(t, c, plant)
		RealmKit.F.WATERFALL:
			_waterfall(t, c, rock)
		RealmKit.F.RAPIDS:
			# White water breaking round rocks.
			for k in 4:
				var p := c + Vector3((RealmKit.jitter(t, k) - 0.5) * 0.7, -KitGround.WATER_DROP, (k - 1.5) * 0.22)
				prop.rock(Geo.place(p + Vector3(0, 0.02, 0)), 0.07 + 0.03 * RealmKit.jitter(t, k + 5), rock, k)
				prop.moving(Geo.Anim.BOB, p + Vector3(k, 0, 0))
				prop.ball(Geo.place(p + Vector3(0.08, 0.0, 0.03), 0.0, Vector3(1.6, 0.25, 1.0)), 0.07, Color("#F4FBFF"),
					2, 7)
				prop.moving(Geo.Anim.NONE, Vector3.ZERO)
		RealmKit.F.POND:
			for k in 5:
				var a := TAU * k / 5.0 + 0.4
				prop.rock(Geo.place(c + Vector3(cos(a) * 0.46, -0.04, sin(a) * 0.46), a, Vector3(1, 0.7, 1)), 0.1,
					Color("#B0A898"), t.x + k)
			prop.cyl(Geo.place(c + Vector3(0.12, -KitGround.WATER_DROP + 0.005, -0.1)), 0.09, 0.09, 0.01,
				Color("#3F9A4A"), 8)
			prop.ball(Geo.place(c + Vector3(0.14, -KitGround.WATER_DROP + 0.03, -0.1)), 0.025, Color("#F7A6DA"), 2, 5)


## A rock pillar by realm: banded stone; a glassy column in Crystalline;
## basalt columns in Emberreach; a mossy stack lit by mushrooms in Lantern
## Vale; a pale sea stack in Tidehold.
func _pillar(c: Vector3, j: float, rock: Color) -> void:
	var hero := kit.hero
	var seed_from := int(j * 100)
	match kit.realm:
		"crystalline":
			hero.gem(Geo.place(c + Vector3(0, 0.75, 0), j), 0.26, 0.75, Color(Palette.MATTER.lightened(0.4), 0.85), 6)
			hero.gem(Geo.place(c + Vector3(0.24, 0.35, 0.12), j + 1.0), 0.12, 0.35, Color(Palette.MATTER.lightened(0.3), 0.8),
				5)
			hero.rock(Geo.place(c + Vector3(0, 0.08, 0), j, Vector3(1.2, 0.5, 1.2)), 0.26, rock, seed_from)
			return
		"emberreach":
			var hs := [1.25, 0.95, 0.7, 1.1]
			for k in 4:
				var a := TAU * k / 4.0 + j
				var o := Vector3(cos(a), 0, sin(a)) * (0.0 if k == 0 else 0.2)
				hero.prism(Geo.place(c + o, j), 6, 0.14, 0.13, hs[k], rock.lightened(0.05 * k), false,
					rock.lightened(0.2))
			kit.prop.ring(Geo.place(c + Vector3(0.3, 0.012, -0.25)), 0.0, 0.07, Color(Palette.ENERGY, 0.2), 8)
			return
	var band := rock.darkened(0.12)
	var body := rock
	if kit.realm == "tidehold":
		body = rock.lightened(0.25)
		band = Color("#E8E2D0")
		hero.prism(Geo.place(c, j), 7, 0.34, 0.25, 1.0, body, false, body.lightened(0.12))
		for y: float in [0.3, 0.62]:
			hero.prism(Geo.place(c + Vector3(0, y, 0), j), 7, 0.33 - y * 0.09, 0.32 - y * 0.09, 0.05, band)
		hero.prism(Geo.place(c + Vector3(0, 1.0, 0), j + 0.4), 7, 0.25, 0.18, 0.3, body.darkened(0.06))
		hero.rock(Geo.place(c + Vector3(0, 1.38, 0), j, Vector3(1, 0.7, 1)), 0.2, body.lightened(0.06), seed_from)
	else:
		# Stones balanced one on another, each faceted and turned its own way
		# (the diorama's dodecahedron rocks), lighter toward the top, a cap of
		# moss on the highest: a toy cairn that blocks the way.
		var sway := Vector3(cos(j * 9.0), 0, sin(j * 9.0)) * 0.05
		hero.rock(Geo.place(c + Vector3(0, 0.24, 0), j, Vector3(1.05, 0.78, 1.05)), 0.36, body.darkened(0.04),
			seed_from)
		hero.rock(Geo.place(c + Vector3(0, 0.68, 0) + sway, j + 1.3, Vector3(1, 0.85, 1)), 0.28, body,
			seed_from + 1)
		hero.rock(Geo.place(c + Vector3(0, 1.04, 0) - sway, j + 2.1, Vector3(1, 0.9, 1)), 0.21, body.lightened(0.08),
			seed_from + 2)
		kit.prop.ball(Geo.place(c + Vector3(0, 1.18, 0) - sway, 0.0, Vector3(1, 0.45, 1)), 0.15,
			(kit.palette["plant"] as Color).darkened(0.1), 3, 7, true)
	kit.prop.rock(Geo.place(c + Vector3(0.32, 0.04, 0.22)), 0.08, rock.darkened(0.05), int(j * 50))
	if kit.realm == "lanternvale" or kit.realm == "verdant":
		kit.prop.ball(Geo.place(c + Vector3(-0.1, 0.55, 0.26), 0.0, Vector3(1.4, 0.7, 0.6)), 0.14,
			kit.palette["plant"].darkened(0.3), 3, 6)
		if kit.realm == "lanternvale":
			for k in 3:
				var a := TAU * k / 3.0 + j
				kit.prop.cyl(Geo.place(c + Vector3(cos(a) * 0.4, 0, sin(a) * 0.4)), 0.015, 0.015, 0.08, Color("#E8E0F0"), 4)
				kit.prop.ball(Geo.place(c + Vector3(cos(a) * 0.4, 0.09, sin(a) * 0.4), 0.0, Vector3(1, 0.6, 1)), 0.05,
					Color(Color("#7AD8C8"), 0.3), 2, 6)


## A boulder by realm: grey stone; crystal-studded in Crystalline; basalt
## with a glowing vein in Emberreach; a smooth pebble in Tidehold; mossy
## elsewhere green grows.
func _boulder(t: Vector2i, c: Vector3, j: float, rock: Color) -> void:
	var hero := kit.hero
	var body := rock.lightened(0.1)
	if kit.realm == "tidehold":
		hero.ball(Geo.place(c + Vector3(0, 0.2, 0), j, Vector3(1.0, 0.62, 0.85)), 0.36, rock.lightened(0.2), 4, 9)
		hero.ball(Geo.place(c + Vector3(0.3, 0.07, 0.2), j), 0.13, rock.lightened(0.3), 3, 7)
		return
	hero.rock(Geo.place(c + Vector3(0, 0.24, 0), j * TAU, Vector3(1.0, 0.72, 0.92)), 0.4, body, t.x * 13 + t.y)
	hero.rock(Geo.place(c + Vector3(0.3, 0.08, 0.18), j * 3.0, Vector3(1.0, 0.75, 1.0)), 0.16, rock, t.x + 5)
	match kit.realm:
		"crystalline":
			for k in 3:
				var a := TAU * k / 3.0 + j
				hero.gem(Transform3D(Basis(Vector3(cos(a), 0, sin(a)).cross(Vector3.UP), 0.5),
					c + Vector3(cos(a) * 0.18, 0.42, sin(a) * 0.15)), 0.06, 0.16, Color(Palette.MATTER.lightened(0.35), 0.7), 4)
		"emberreach":
			kit.prop.box(Geo.place(c + Vector3(0, 0.3, 0.33), j), Vector3(0.3, 0.035, 0.02), Color(Palette.ENERGY, 0.15))
		"verdant", "heart", "lanternvale":
			kit.prop.ball(Geo.place(c + Vector3(-0.05, 0.47, 0), j, Vector3(1.3, 0.35, 1.1)), 0.2,
				kit.palette["plant"].darkened(0.2), 3, 7)


## A bush by realm: leafy; dandelion puffs in Skyfield; frost moss in
## Crystalline; ember grass in Emberreach; berried in Verdant.
func _bush(t: Vector2i, c: Vector3, j: float, plant: Color) -> void:
	var prop := kit.prop
	prop.moving(Geo.Anim.SWAY, c)
	match kit.realm:
		"skyfield":
			prop.ball(Geo.place(c + Vector3(0, 0.1, 0), j, Vector3(1.2, 0.6, 1.2)), 0.22, plant.darkened(0.25), 3, 7)
			for k in 5:
				var a := TAU * k / 5.0 + j
				var p := c + Vector3(cos(a) * 0.18, 0, sin(a) * 0.18)
				prop.blade(p, 0.32 + 0.1 * RealmKit.jitter(t, k), 0.012, plant.darkened(0.3))
				prop.ball(Geo.place(p + Vector3(0, 0.36 + 0.1 * RealmKit.jitter(t, k), 0)), 0.06, Color("#FFFDF4"), 3, 6)
		"crystalline":
			for k in 4:
				var a := TAU * k / 4.0 + j
				prop.ball(Geo.place(c + Vector3(cos(a) * 0.16, 0.12, sin(a) * 0.16), 0.0, Vector3(1, 0.6, 1)), 0.18,
					Color("#BFE8F2").lerp(plant, 0.3), 3, 7)
			prop.gem(Geo.place(c + Vector3(0, 0.3, 0), j), 0.05, 0.12, Color(Color("#E6F8FF"), 0.6), 4)
		"emberreach":
			for k in 9:
				var a := TAU * k / 9.0 + j
				var p := c + Vector3(cos(a), 0, sin(a)) * 0.12 * (1 + k % 2)
				prop.blade(p, 0.3 + 0.12 * RealmKit.jitter(t, k), 0.03, plant.darkened(0.2), 0.35, a)
				prop.ball(Geo.place(p + Vector3(cos(a) * 0.1, 0.33, sin(a) * 0.1)), 0.025, Color(Palette.ENERGY, 0.3), 2, 4)
		_:
			prop.ball(Geo.place(c + Vector3(0, 0.22, 0), j, Vector3(1.0, 0.85, 1.0)), 0.3, plant.darkened(0.1), 4, 8)
			prop.ball(Geo.place(c + Vector3(0.24, 0.16, 0.12)), 0.22, plant.lightened(0.04), 3, 7)
			prop.ball(Geo.place(c + Vector3(-0.2, 0.13, 0.16)), 0.2, plant.darkened(0.02), 3, 7)
			if kit.realm == "verdant" or kit.realm == "heart":
				for k in 5:
					var a := TAU * k / 5.0 + j * 2.0
					prop.ball(Geo.place(c + Vector3(cos(a) * 0.27, 0.25 + 0.05 * (k % 2), sin(a) * 0.27)), 0.035,
						Color("#E2536B") if kit.realm == "verdant" else Color("#F7A6DA"), 2, 4)
	prop.moving(Geo.Anim.NONE, Vector3.ZERO)


## Tall grass by realm: long blades; golden wheat in Skyfield; ember grass
## with glowing tips in Emberreach and Lantern Vale; frosted in Crystalline.
func _grass(t: Vector2i, c: Vector3, plant: Color) -> void:
	var prop := kit.prop
	var wheat := kit.realm == "skyfield"
	var tips := kit.realm == "emberreach" or kit.realm == "lanternvale"
	var blade := plant.darkened(0.08).lerp(Color("#3E7A3A"), 0.25)
	if wheat:
		blade = Color("#E6C468")
	elif kit.realm == "crystalline":
		blade = Color("#CFE6F2")
	for k in 13:
		var p := c + Vector3(RealmKit.jitter(t, k) - 0.5, 0, RealmKit.jitter(t, k + 9) - 0.5) * 0.86
		var tall := 0.42 + 0.22 * RealmKit.jitter(t, k + 2)
		var lean := 0.25
		var dir := RealmKit.jitter(t, k + 3) * TAU
		prop.moving(Geo.Anim.SHIVER, p)
		prop.blade(p, tall, 0.04 if not wheat else 0.02, blade.darkened(0.1 * (k % 3)), lean, dir)
		var tip := p + Vector3(sin(lean) * cos(dir), cos(lean), sin(lean) * sin(dir)) * tall
		if wheat:
			prop.ball(Geo.place(tip, dir, Vector3(0.6, 1.6, 0.6)), 0.035, Color("#F2D27A"), 2, 5)
		elif tips and k % 3 == 0:
			var glow := Palette.ENERGY if kit.realm == "emberreach" else Color("#9BF0C8")
			prop.ball(Geo.place(tip), 0.025, Color(glow, 0.2), 2, 4)
	prop.moving(Geo.Anim.NONE, Vector3.ZERO)


## The yaw (local −Z) toward a neighbour standing `rise` levels above `t`
## (below when negative), as the design finds a ramp's way up; the tile's
## own facing when none does.
func _toward(t: Vector2i, rise: int) -> float:
	for d: Vector2i in [Vector2i(0, -1), Vector2i(1, 0), Vector2i(0, 1), Vector2i(-1, 0)]:
		var n := t + d
		if not kit.inside(n):
			continue
		var dh := roundi((kit.height(n) - kit.height(t)) / IslandBuilder.LEVEL)
		if (rise > 0 and dh == rise) or (rise < 0 and dh < 0):
			return atan2(-float(d.x), -float(d.y))
	return kit.yaw(t)


## Whether the neighbour of `t` toward `d` carries feature `f`.
func _joins(t: Vector2i, d: Vector2i, f: int) -> bool:
	return kit.code(t + d) == f and kit.height(t + d) == kit.height(t)


## Which way a run of `f` goes through `t`: 0 along x, PI/2 along z.
func _run_yaw(t: Vector2i, f: int) -> float:
	var x := int(_joins(t, Vector2i(1, 0), f)) + int(_joins(t, Vector2i(-1, 0), f))
	var z := int(_joins(t, Vector2i(0, 1), f)) + int(_joins(t, Vector2i(0, -1), f))
	return PI / 2.0 if z > x else 0.0


func _ruin(t: Vector2i, c: Vector3) -> void:
	var yaw := _run_yaw(t, RealmKit.F.RUIN_WALL)
	var dir := Vector3.RIGHT.rotated(Vector3.UP, yaw)
	var old: Color = (style["stone2"] as Color).lerp(kit.palette["rock"], 0.35)
	# Glassy in Crystalline, basalt in Emberreach, pale coral stone in Tidehold.
	match kit.realm:
		"crystalline":
			old = Color("#B8AEE0")
		"emberreach":
			old = Color("#4A3A3E")
		"tidehold":
			old = Color("#D8D0C0")
	var tall := [0.78, 0.46, 0.92, 0.3, 0.64]
	for k in 4:
		var x := -0.375 + 0.25 * k
		var h: float = tall[(k + t.x * 3 + t.y) % 5]
		var y := 0.0
		var row := 0
		while y < h:
			var bh := 0.15 + 0.05 * RealmKit.jitter(t, k * 9 + row)
			var off := (0.06 if row % 2 == 1 else -0.02) + (RealmKit.jitter(t, k * 5 + row) - 0.5) * 0.04
			var col := old.lightened(0.12 * RealmKit.jitter(t, k * 7 + row)).darkened(0.05 * (row % 2))
			kit.hero.rbox(Geo.place(c + dir * (x + off) + Vector3(0, y + bh / 2.0, 0),
				yaw + (RealmKit.jitter(t, k + row * 3) - 0.5) * 0.12), Vector3(0.24, bh - 0.01, 0.28), col, 0.035)
			y += bh
			row += 1
	# Fallen stones at its foot, and moss creeping up.
	var side := dir.rotated(Vector3.UP, PI / 2.0)
	for k in 2:
		kit.prop.rock(Geo.place(c + side * (0.28 + 0.06 * k) + dir * (0.2 - 0.4 * k) + Vector3(0, 0.05, 0)),
			0.08 + 0.03 * k, old.darkened(0.08), t.x + k)
	kit.prop.moving(Geo.Anim.SHIVER, c)
	for k in 3:
		kit.prop.ball(Geo.place(c + dir * (-0.3 + 0.3 * k) + side * 0.15 + Vector3(0, 0.08 + 0.12 * (k % 2), 0), 0.0,
			Vector3(1.2, 0.6, 0.7)), 0.09, kit.palette["plant"].darkened(0.25), 3, 6)
	kit.prop.moving(Geo.Anim.NONE, Vector3.ZERO)


## A fence by realm: a split-rail of timber; a white picket in Skyfield and
## Tidehold; crystal rails on lilac posts in Crystalline; black iron with
## spear points in Emberreach and Lantern Vale.
func _fence(t: Vector2i, c: Vector3) -> void:
	var yaw := _run_yaw(t, RealmKit.F.FENCE)
	var dir := Vector3.RIGHT.rotated(Vector3.UP, yaw)
	var post := KitStyle.WOOD.darkened(0.05)
	var rail := KitStyle.WOOD.lightened(0.15)
	var cap := "point"
	var n := 3
	match kit.realm:
		"skyfield", "tidehold":
			post = Color("#F4EEE2")
			rail = Color("#E8E0D2")
			n = 6
		"crystalline":
			post = Color("#C9C0E6")
			rail = Color(Palette.MATTER.lightened(0.35), 0.75)
			cap = "gem"
		"emberreach", "lanternvale":
			post = KitStyle.IRON
			rail = KitStyle.IRON.lightened(0.1)
			cap = "spear"
			n = 5
	for k in n:
		var p := c + dir * (-0.42 + 0.84 * k / (n - 1))
		var w := 0.08 if n == 3 else 0.05
		kit.hero.box(Geo.place(p + Vector3(0, 0.25, 0), yaw), Vector3(w, 0.5, w), post)
		match cap:
			"gem":
				kit.hero.gem(Geo.place(p + Vector3(0, 0.56, 0), yaw), 0.05, 0.07, Color(Palette.MATTER.lightened(0.4), 0.6), 4)
			"spear":
				kit.hero.prism(Geo.place(p + Vector3(0, 0.5, 0), yaw + PI / 4.0), 4, 0.03, 0.0, 0.1, post)
			_:
				kit.hero.prism(Geo.place(p + Vector3(0, 0.5, 0), yaw + PI / 4.0), 4, w * 0.71, 0.0, 0.08, post)
	for y: float in ([0.18, 0.38] if cap != "spear" else [0.12, 0.42]):
		kit.hero.box(Geo.place(c + Vector3(0, y, 0), yaw), Vector3(1.0, 0.05, 0.035), rail)


func _hedge(t: Vector2i, c: Vector3, plant: Color) -> void:
	var hero := kit.hero
	var clipped := kit.realm == "heart"
	var lo := Vector3(-0.42, 0, -0.32)
	var hi := Vector3(0.42, 0, 0.32)
	for d: Vector2i in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
		if _joins(t, d, RealmKit.F.HEDGE):
			if d.x > 0:
				hi.x = 0.5
			elif d.x < 0:
				lo.x = -0.5
			elif d.y > 0:
				hi.z = 0.5
			else:
				lo.z = -0.5
	var mid := (lo + hi) / 2.0
	var size := hi - lo
	if clipped or size.x > 0.9 or size.z > 0.9:
		hero.rbox(Geo.place(c + mid + Vector3(0, 0.34, 0)), Vector3(size.x, 0.68, size.z), plant.darkened(0.18), 0.1,
			plant.darkened(0.04))
	for k in 4:
		var o := Vector3(RealmKit.jitter(t, k) - 0.5, 0, RealmKit.jitter(t, k + 4) - 0.5) * 0.5
		var r := 0.2 + 0.08 * RealmKit.jitter(t, k + 8)
		hero.moving(Geo.Anim.SWAY, c)
		hero.ball(Geo.place(c + o + Vector3(0, 0.52 + 0.1 * RealmKit.jitter(t, k + 2), 0), 0.0, Vector3(1, 0.85, 1)),
			r, plant.darkened(0.12 - 0.05 * (k % 3)), 3, 7)
	hero.moving(Geo.Anim.NONE, Vector3.ZERO)
	# The realm's touch: flowers in Verdant and the Heart, frost in
	# Crystalline, thorns in Emberreach.
	var touch := Color.BLACK
	match kit.realm:
		"verdant":
			touch = Color("#F7A6DA")
		"heart":
			touch = Color("#FFFFFF")
		"crystalline":
			touch = Color("#EAF6FF")
		"emberreach":
			touch = Color("#E8C8A0")
	if touch != Color.BLACK:
		for k in 6:
			var o := Vector3(RealmKit.jitter(t, k + 20) - 0.5, 0, RealmKit.jitter(t, k + 26) - 0.5) * 0.7
			var p := c + o + Vector3(0, 0.62 + 0.12 * RealmKit.jitter(t, k + 32), 0)
			if kit.realm == "emberreach":
				kit.prop.prism(Geo.place(p, k), 3, 0.02, 0.0, 0.08, touch)
			else:
				kit.prop.ball(Geo.place(p, 0.0, Vector3(1, 0.6, 1)), 0.035, touch, 2, 5)


func _tree(t: Vector2i, c: Vector3, j: float, plant: Color) -> void:
	var hero := kit.hero
	var bark := KitStyle.WOOD.lightened(0.05)
	var kind: String = style["tree"]
	if kit.realm == "heart":
		# The Heart's trees are in blossom, pink puffs over the meadow, as the
		# design's heist draws them (02-heist).
		plant = Color("#F49CCB").lerp(plant, 0.08 * RealmKit.jitter(t, 23))
	var tall := (0.9 + 0.25 * RealmKit.jitter(t, 21)) * (1.25 if kit.realm == "verdant" else 1.0)
	hero.moving(Geo.Anim.SWAY, c)
	match kind:
		"pine":
			hero.cyl(Geo.place(c), 0.09, 0.06, 0.4 * tall, bark, 6)
			for k in 3:
				var y := (0.3 + 0.32 * k) * tall
				hero.prism(Geo.place(c + Vector3(0, y, 0), j + k), 8, (0.42 - 0.1 * k) * tall, 0.0,
					0.55 * tall, plant.darkened(0.12 - 0.06 * k), true)
		"willow":
			hero.cyl(Geo.place(c), 0.1, 0.07, 0.95 * tall, bark.darkened(0.15), 6)
			var crown := plant.darkened(0.25).lerp(Color("#2E6A5A"), 0.3)
			hero.ball(Geo.place(c + Vector3(0, 1.0 * tall, 0), j, Vector3(1.15, 0.6, 1.15)), 0.42, crown, 4, 9)
			for k in 11:
				var a := TAU * k / 11.0 + j
				var p := c + Vector3(cos(a) * 0.38, 0.98 * tall, sin(a) * 0.38)
				var hang := (0.55 + 0.2 * RealmKit.jitter(t, k + 30)) * tall
				hero.prism(Transform3D(Basis(Vector3.RIGHT, PI), p), 3, 0.05, 0.012, hang,
					crown.lightened(0.08 * (k % 3)).lerp(plant, 0.25))
			if kit.realm == "lanternvale":
				for k in 3:
					var a := TAU * k / 3.0 + j
					hero.ball(Geo.place(c + Vector3(cos(a) * 0.3, 0.55 * tall, sin(a) * 0.3)), 0.035,
						Color(Color("#FFE7A8"), 0.2), 2, 5)
		"birch":
			hero.cyl(Geo.place(c), 0.06, 0.045, 0.9 * tall, Color("#F2EEE4"), 6)
			for k in 3:
				hero.cyl(Geo.place(c + Vector3(0, 0.15 + 0.22 * k, 0)), 0.062, 0.062, 0.03, Palette.INK.lightened(0.2), 6)
			hero.ball(Geo.place(c + Vector3(0, 1.0 * tall, 0), j, Vector3(0.8, 1.15, 0.8)), 0.36, plant, 4, 8)
			hero.ball(Geo.place(c + Vector3(0.16, 1.18 * tall, 0.08), j), 0.22, plant.lightened(0.1), 3, 7)
		_:
			var crown := 1.25 if kit.realm == "verdant" else 1.0
			hero.cyl(Geo.place(c), 0.12 * crown, 0.08 * crown, 0.63 * tall, bark, 7)
			for k in 2:
				var a := j * TAU + PI * k
				hero.box(Transform3D(Basis(Vector3(cos(a), 0, sin(a)).cross(Vector3.UP), 0.7),
					c + Vector3(cos(a) * 0.08, 0.45 * tall, sin(a) * 0.08)), Vector3(0.04, 0.22, 0.04), bark)
			# Three shapes, chosen by the tile, so a grove never repeats: the
			# design's three-blob crown, a tall oval, and a two-tier crown.
			var shape := int(RealmKit.jitter(t, 22) * 3.0)
			if shape == 1:
				hero.ball(Geo.place(c + Vector3(0, 0.95 * tall, 0), j, Vector3(0.8, 1.25, 0.8)), 0.44 * crown,
					plant.darkened(0.08), 5, 10)
				hero.ball(Geo.place(c + Vector3(0.1, 1.2 * tall, 0.08) * Vector3(crown, 1, crown), j), 0.24 * crown,
					plant.lightened(0.06), 4, 8)
			elif shape == 2:
				hero.ball(Geo.place(c + Vector3(0, 0.78 * tall, 0), j, Vector3(1.1, 0.7, 1.1)), 0.46 * crown,
					plant.darkened(0.1), 5, 10)
				hero.ball(Geo.place(c + Vector3(0.04, 1.1 * tall, 0.02), j, Vector3(1.0, 0.75, 1.0)), 0.34 * crown,
					plant.lightened(0.04), 4, 9)
			else:
				hero.ball(Geo.place(c + Vector3(0, 0.85 * tall, 0), j, Vector3(1.0, 0.86, 1.0)), 0.47 * crown,
					plant.darkened(0.06), 5, 10)
				hero.ball(Geo.place(c + Vector3(0.2, 1.08 * tall, 0.09) * Vector3(crown, 1, crown), j), 0.31 * crown,
					plant.lightened(0.08), 4, 8)
				hero.ball(Geo.place(c + Vector3(-0.18, 1.12 * tall, -0.09) * Vector3(crown, 1, crown), j),
					0.27 * crown, plant.lightened(0.02), 4, 8)
			if kit.realm == "verdant" or kit.realm == "heart":
				var fruit: Color = Color("#E2536B") if kit.realm == "verdant" else Color("#FFE0F0")
				for k in 4:
					var a := TAU * k / 4.0 + j * 3.0
					hero.ball(Geo.place(c + Vector3(cos(a) * 0.42, (0.8 + 0.12 * (k % 2)) * tall, sin(a) * 0.42)), 0.045,
						fruit, 2, 5)
	hero.moving(Geo.Anim.NONE, Vector3.ZERO)


## A statue by realm on its plinth: a figure holding up an orb; in
## Skyfield a figure with wings spread; in Tidehold a great shell; in
## Verdant a mossy figure with a sapling; in Lantern Vale a hooded figure
## with a lantern; in Crystalline a faceted obelisk; in Emberreach a horned
## basalt head.
func _statue(c: Vector3, j: float, stone: Color) -> void:
	var hero := kit.hero
	var s := stone.lightened(0.06)
	hero.rbox(Geo.place(c + Vector3(0, 0.11, 0)), Vector3(0.48, 0.22, 0.48), stone.darkened(0.08), 0.03)
	hero.rbox(Geo.place(c + Vector3(0, 0.25, 0)), Vector3(0.4, 0.06, 0.4), stone.darkened(0.02), 0.02)
	match kit.realm:
		"crystalline":
			hero.gem(Geo.place(c + Vector3(0, 0.75, 0), j), 0.16, 0.47, Color(Color("#D8D0F8"), 0.85), 4)
		"tidehold":
			for k in 7:
				var a := -1.2 + 2.4 * k / 6.0
				hero.box(Transform3D(Basis(Vector3.BACK, a), c + Vector3(sin(a) * 0.12, 0.46 + cos(a) * 0.12, 0)),
					Vector3(0.08, 0.38, 0.12), Color("#F3E6D0").darkened(0.05 * (k % 2)))
			hero.ball(Geo.place(c + Vector3(0, 0.32, 0.02)), 0.07, Color("#F7C6D8"), 3, 6)
		"emberreach":
			hero.rock(Geo.place(c + Vector3(0, 0.55, 0), j, Vector3(1, 1.1, 0.9)), 0.22, Color("#3A2E34"), 7)
			for sx: float in [-1.0, 1.0]:
				hero.prism(Transform3D(Basis(Vector3.FORWARD, sx * 0.6), c + Vector3(sx * 0.16, 0.72, 0)), 5, 0.05, 0.0,
					0.22, Color("#E8D8C0"))
			for sx: float in [-1.0, 1.0]:
				hero.ball(Geo.place(c + Vector3(sx * 0.08, 0.58, 0.18)), 0.03, Color(Palette.ENERGY, 0.1), 2, 5)
		_:
			hero.cyl(Geo.place(c + Vector3(0, 0.28, 0)), 0.17, 0.12, 0.5, s, 8)
			var hood := kit.realm == "lanternvale"
			if hood:
				hero.prism(Geo.place(c + Vector3(0, 0.74, 0)), 8, 0.16, 0.0, 0.32, s.darkened(0.08))
			else:
				hero.ball(Geo.place(c + Vector3(0, 0.88, 0)), 0.13, s, 4, 8)
			match kit.realm:
				"skyfield":
					for sx: float in [-1.0, 1.0]:
						hero.box(Transform3D(Basis(Vector3.FORWARD, sx * 0.9), c + Vector3(sx * 0.26, 0.82, -0.05)),
							Vector3(0.05, 0.4, 0.16), s.lightened(0.05))
				"lanternvale":
					hero.box(Transform3D(Basis(Vector3.FORWARD, -0.4), c + Vector3(0.16, 0.66, 0.05)),
						Vector3(0.05, 0.24, 0.05), s)
					hero.rbox(Geo.place(c + Vector3(0.24, 0.56, 0.06)), Vector3(0.09, 0.11, 0.09),
						Color(Color("#FFD27A"), 0.15), 0.01)
				"verdant":
					hero.cyl(Geo.place(c + Vector3(0.14, 0.62, 0.06)), 0.015, 0.012, 0.3, KitStyle.WOOD, 4)
					hero.ball(Geo.place(c + Vector3(0.14, 0.95, 0.06)), 0.1, kit.palette["plant"], 3, 6)
					hero.ball(Geo.place(c + Vector3(0, 0.98, 0), 0.0, Vector3(1.1, 0.4, 1.1)), 0.13,
						kit.palette["plant"].darkened(0.2), 3, 6)
				_:
					for sx: float in [-1.0, 1.0]:
						hero.box(Transform3D(Basis(Vector3.FORWARD, sx * 0.5), c + Vector3(sx * 0.15, 0.78, 0)),
							Vector3(0.06, 0.28, 0.06), s)
					hero.ball(Geo.place(c + Vector3(0, 1.12, 0)), 0.09, Color(KitStyle.GOLD, 0.6), 3, 7)
	kit.prop.moving(Geo.Anim.SHIVER, c)
	kit.prop.ball(Geo.place(c + Vector3(0.2, 0.25, 0.22), j, Vector3(1, 0.6, 1)), 0.08, kit.palette["plant"], 3, 6)
	kit.prop.moving(Geo.Anim.NONE, Vector3.ZERO)


func _crystals(t: Vector2i, c: Vector3) -> void:
	var colour := Palette.MATTER.lightened(0.3)
	var spots := [[0.0, 0.0, 0.36, 0.0], [0.27, 0.13, 0.22, 0.3], [-0.22, 0.18, 0.2, -0.25], [0.05, -0.25, 0.15, 0.2]]
	for k in spots.size():
		var s: Array = spots[k]
		var p := c + Vector3(s[0], 0, s[1])
		var tilt := Basis(Vector3(s[0], 0, s[1]).normalized() if absf(s[0]) + absf(s[1]) > 0 else Vector3.RIGHT,
			float(s[3]) * 0.6)
		var r: float = s[2]
		var tall := r * 1.9
		if k == 0:
			kit.hero.moving(Geo.Anim.SPIN_Y, p)
		else:
			kit.hero.moving(Geo.Anim.NONE, Vector3.ZERO)
		kit.hero.gem(Transform3D(tilt.rotated(Vector3.UP, RealmKit.jitter(t, k)), p + Vector3(0, tall * 0.9, 0)),
			r * 0.62, tall, Color(colour.darkened(0.06 * k), 0.75), 5)
	kit.hero.moving(Geo.Anim.NONE, Vector3.ZERO)
	kit.prop.rock(Geo.place(c + Vector3(-0.1, 0.03, 0.2)), 0.09, kit.palette["rock"], t.y)


func _lava(t: Vector2i, c: Vector3) -> void:
	var lava := kit.lava
	var yaw := RealmKit.jitter(t, 2) * PI
	var pts: Array[Vector3] = []
	for k in 6:
		var x := -0.48 + 0.192 * k
		pts.append(c + Vector3(x, 0.006, (RealmKit.jitter(t, k + 30) - 0.5) * 0.3).rotated(Vector3.UP, 0.0))
	for k in 5:
		var a := pts[k].rotated(Vector3.UP, 0.0) - c
		var b := pts[k + 1] - c
		a = a.rotated(Vector3.UP, yaw) + c
		b = b.rotated(Vector3.UP, yaw) + c
		var w := 0.1 - 0.012 * absf(k - 2)
		var side := (b - a).cross(Vector3.UP).normalized() * w
		lava.quad(a - side, a + side, b + side, b - side, Color.WHITE)
	# A branch.
	var m := pts[2] - c
	var m2 := (m + Vector3(0.1, 0, 0.3)).rotated(Vector3.UP, yaw) + c
	var m1 := m.rotated(Vector3.UP, yaw) + c
	var sd := (m2 - m1).cross(Vector3.UP).normalized() * 0.05
	lava.quad(m1 - sd, m1 + sd, m2 + sd * 0.3, m2 - sd * 0.3, Color.WHITE)
	for k in 3:
		kit.prop.rock(Geo.place(c + Vector3(RealmKit.jitter(t, k + 40) - 0.5, 0.02, RealmKit.jitter(t, k + 43) - 0.5)
			* 0.8), 0.06, Color("#2B1C22"), k)


## A shade canopy: a striped awning peaked over four posts, its scalloped
## hem stirring in the wind.
func _canopy(c: Vector3, wood: Color) -> void:
	var hero := kit.hero
	var cloth: Color = (style["accent"] as Color).lightened(0.2)
	var stripe := Color("#FFF8EE")
	for p: Vector2 in [Vector2(-0.36, -0.36), Vector2(0.36, -0.36), Vector2(-0.36, 0.36), Vector2(0.36, 0.36)]:
		hero.cyl(Geo.place(c + Vector3(p.x, 0, p.y)), 0.035, 0.03, 0.88, wood, 5)
	hero.moving(Geo.Anim.SWAY, c)
	var peak := c + Vector3(0, 1.2, 0)
	var rim: Array[Vector3] = []
	for k in 8:
		var a := TAU * k / 8.0 + PI / 8.0
		rim.append(c + Vector3(cos(a) * 0.62, 0.86, sin(a) * 0.62))
	for k in 8:
		hero.tri(peak, rim[(k + 1) % 8], rim[k], cloth if k % 2 == 0 else stripe)
	# The scalloped hem hanging from the rim.
	for k in 8:
		var a0 := rim[k]
		var a1 := rim[(k + 1) % 8]
		var mid := (a0 + a1) / 2.0 + Vector3(0, -0.1, 0)
		kit.prop.moving(Geo.Anim.SWAY, c)
		kit.prop.tri(a0, a1, mid, cloth.darkened(0.08) if k % 2 == 0 else stripe.darkened(0.05))
		kit.prop.tri(a0, mid, a1, cloth.darkened(0.15))
	hero.moving(Geo.Anim.NONE, Vector3.ZERO)
	kit.prop.moving(Geo.Anim.NONE, Vector3.ZERO)
	hero.ball(Geo.place(peak + Vector3(0, 0.03, 0)), 0.045, KitStyle.GOLD, 2, 5)
	kit.prop.ring(Geo.place(c + Vector3(0, 0.012, 0)), 0.0, 0.5, Color(0, 0, 0, 1).lerp(kit.palette["grass"], 0.88), 10)


func _spring(t: Vector2i, c: Vector3, rock: Color) -> void:
	for k in 7:
		var a := TAU * k / 7.0
		kit.prop.rock(Geo.place(c + Vector3(cos(a) * 0.45, -0.05, sin(a) * 0.45), a), 0.09, rock.lightened(0.15), k)
	for k in 3:
		var p := c + Vector3(RealmKit.jitter(t, k) - 0.5, 0, RealmKit.jitter(t, k + 1) - 0.5) * 0.4
		kit.clear.moving(Geo.Anim.RISE, p + Vector3(k * 1.3, 0, 0))
		kit.clear.ball(Geo.place(p + Vector3(0, 0.2 + 0.22 * k, 0)), 0.12 + 0.05 * k, Color("#FFFFFF", 0.85), 3, 7)
	kit.clear.moving(Geo.Anim.NONE, Vector3.ZERO)


## A lantern post by realm: iron and a glass box; a gilded post in the
## Heart; a paper lantern hung from a crook in Lantern Vale; a brazier in
## Emberreach; a crystal on a post in Crystalline.
func _lantern(c: Vector3) -> void:
	var hero := kit.hero
	var iron := KitStyle.IRON
	match kit.realm:
		"lanternvale":
			hero.cyl(Geo.place(c), 0.04, 0.03, 1.1, KitStyle.WOOD_DARK, 6)
			hero.box(Geo.place(c + Vector3(0.14, 1.08, 0)), Vector3(0.3, 0.035, 0.035), KitStyle.WOOD_DARK)
			hero.moving(Geo.Anim.SWING, c + Vector3(0.26, 1.06, 0))
			hero.cyl(Geo.place(c + Vector3(0.26, 0.82, 0)), 0.09, 0.11, 0.2, Color(Color("#FF9A5C"), 0.15), 8)
			hero.cyl(Geo.place(c + Vector3(0.26, 1.02, 0)), 0.05, 0.05, 0.03, KitStyle.WOOD_DARK, 6)
			hero.moving(Geo.Anim.NONE, Vector3.ZERO)
		"emberreach":
			hero.cyl(Geo.place(c), 0.05, 0.04, 0.8, iron, 6)
			hero.cyl(Geo.place(c + Vector3(0, 0.8, 0)), 0.1, 0.16, 0.12, iron, 8)
			hero.moving(Geo.Anim.BOB, c + Vector3(0, 0.95, 0))
			hero.ball(Geo.place(c + Vector3(0, 0.97, 0), 0.0, Vector3(1, 1.4, 1)), 0.09, Color(Color("#FF8A3C"), 0.1), 3, 7)
			hero.moving(Geo.Anim.NONE, Vector3.ZERO)
		"crystalline":
			hero.cyl(Geo.place(c), 0.06, 0.04, 0.95, Color("#C9C0E6"), 6)
			hero.moving(Geo.Anim.SPIN_Y, c + Vector3(0, 1.15, 0))
			hero.gem(Geo.place(c + Vector3(0, 1.15, 0)), 0.09, 0.16, Color(Color("#C8B8FF"), 0.25), 5)
			hero.moving(Geo.Anim.NONE, Vector3.ZERO)
		_:
			var metal := KitStyle.GOLD if kit.realm == "heart" else iron
			hero.cyl(Geo.place(c), 0.07, 0.05, 0.1, metal.darkened(0.2), 6)
			hero.cyl(Geo.place(c + Vector3(0, 0.1, 0)), 0.035, 0.028, 0.95, metal, 6)
			hero.box(Geo.place(c + Vector3(0, 1.05, 0)), Vector3(0.24, 0.025, 0.24), metal.darkened(0.15))
			hero.rbox(Geo.place(c + Vector3(0, 1.16, 0)), Vector3(0.17, 0.2, 0.17), Color(Color("#FFD27A"), 0.15), 0.02)
			hero.prism(Geo.place(c + Vector3(0, 1.26, 0), PI / 4.0), 4, 0.17, 0.0, 0.12, metal.darkened(0.15))
	# Its pool of light on the ground.
	kit.clear.ring(Geo.place(c + Vector3(0, 0.015, 0)), 0.0, 0.26, Color(Color("#FFC860"), 0.2), 12)


## An arch by realm: dressed stone with a gold keystone; lilac stone and a
## crystal keystone in Crystalline; basalt with a glowing keystone in
## Emberreach; overgrown with vines in Verdant.
func _arch(t: Vector2i, c: Vector3, stone_in: Color) -> void:
	var hero := kit.hero
	var stone := stone_in
	var key := KitStyle.GOLD
	match kit.realm:
		"crystalline":
			stone = Color("#C9C0E6")
			key = Color(Color("#C8B8FF"), 0.4)
		"emberreach":
			stone = Color("#4A3A3E")
			key = Color(Palette.ENERGY, 0.3)
	var yaw := kit.yaw(t)
	var side := Vector3.RIGHT.rotated(Vector3.UP, yaw)
	for s: float in [-1.0, 1.0]:
		hero.rbox(Geo.place(c + side * s * 0.36 + Vector3(0, 0.45, 0), yaw), Vector3(0.2, 0.9, 0.28), stone, 0.03)
		hero.rbox(Geo.place(c + side * s * 0.36 + Vector3(0, 0.05, 0), yaw), Vector3(0.26, 0.1, 0.34),
			stone.darkened(0.1), 0.02)
	# The round arch, block by block, its keystone in gold.
	for k in 7:
		var a := PI * (k + 0.5) / 7.0
		var p := c + side * cos(a) * 0.32 + Vector3(0, 0.9 + sin(a) * 0.3, 0)
		var basis := Basis(Vector3.UP, yaw) * Basis(Vector3.BACK, a - PI / 2.0)
		hero.rbox(Transform3D(basis, p), Vector3(0.12, 0.16, 0.28), key if k == 3 else stone.lightened(0.04), 0.02)
	if kit.realm == "verdant" or kit.realm == "lanternvale":
		kit.prop.moving(Geo.Anim.SWAY, c)
		for k in 6:
			var a := PI * (k + 0.3) / 6.0
			kit.prop.ball(Geo.place(c + side * cos(a) * 0.36 + Vector3(0, 0.9 + sin(a) * 0.34, 0.12)), 0.06,
				kit.palette["plant"].darkened(0.1 * (k % 2)), 2, 5)
		for s2: float in [-1.0, 1.0]:
			kit.prop.prism(Geo.place(c + side * s2 * 0.42 + Vector3(0, 0.1, 0.1)), 4, 0.03, 0.02, 0.75,
				kit.palette["plant"].darkened(0.2))
		kit.prop.moving(Geo.Anim.NONE, Vector3.ZERO)


func _bell(c: Vector3, j: float, wood: Color) -> void:
	var hero := kit.hero
	var yaw := j * TAU
	var arm := Vector3.RIGHT.rotated(Vector3.UP, yaw)
	hero.cyl(Geo.place(c), 0.06, 0.045, 1.05, wood, 6)
	hero.box(Geo.place(c + Vector3(0, 1.0, 0) + arm * 0.16, yaw), Vector3(0.42, 0.06, 0.06), wood)
	var pivot := c + Vector3(0, 0.97, 0) + arm * 0.3
	hero.moving(Geo.Anim.SWING, pivot)
	hero.cyl(Geo.place(pivot + Vector3(0, -0.24, 0)), 0.14, 0.07, 0.22, KitStyle.GOLD, 10)
	hero.ball(Geo.place(pivot + Vector3(0, -0.02, 0)), 0.07, KitStyle.GOLD.darkened(0.1), 3, 7)
	hero.ball(Geo.place(pivot + Vector3(0, -0.27, 0)), 0.035, KitStyle.IRON, 2, 5)
	hero.moving(Geo.Anim.NONE, Vector3.ZERO)


func _mushroom(t: Vector2i, c: Vector3) -> void:
	var hero := kit.hero
	var glows := kit.realm == "lanternvale"
	var caps := {"skyfield": "#F2C84A", "crystalline": "#8FB8F0", "tidehold": "#3CC6D8", "emberreach": "#F07A3C",
		"verdant": "#E2536B", "heart": "#F27AB4"}
	var cap := Color(caps.get(kit.realm, "#E2536B")) if not glows else Color(Color("#7AD8C8"), 0.5)
	hero.cyl(Geo.place(c), 0.11, 0.08, 0.38, Color("#F3E6CC"), 8)
	hero.moving(Geo.Anim.BOB, c)
	hero.ball(Geo.place(c + Vector3(0, 0.34, 0), 0.0, Vector3(1, 0.62, 1)), 0.38, cap, 4, 12, true)
	hero.cyl(Geo.place(c + Vector3(0, 0.31, 0)), 0.36, 0.38, 0.04, Color("#F3E6CC"), 12)
	for k in 5:
		var a := TAU * k / 5.0 + RealmKit.jitter(t, 4)
		hero.ball(Geo.place(c + Vector3(cos(a) * 0.22, 0.52, sin(a) * 0.22), 0.0, Vector3(1, 0.5, 1)), 0.05,
			Color("#FFFFFF"), 2, 5)
	hero.moving(Geo.Anim.NONE, Vector3.ZERO)


func _ramp(t: Vector2i, c: Vector3) -> void:
	var yaw := _toward(t, 1)
	var soil: Color = kit.palette["soil"]
	kit.prop.wedge(Geo.place(c, yaw), Vector3(0.98, IslandBuilder.LEVEL, 1.0), soil.lightened(0.1))
	var plank := KitStyle.WOOD.lightened(0.25)
	var slope := atan2(IslandBuilder.LEVEL, 1.0)
	for k in 5:
		var u := (k + 0.5) / 5.0 - 0.5
		var p := c + Vector3(0, IslandBuilder.LEVEL * (0.5 - u) + 0.02, u).rotated(Vector3.UP, yaw)
		var basis := Basis(Vector3.UP, yaw) * Basis(Vector3.RIGHT, slope)
		kit.prop.box(Transform3D(basis, p), Vector3(0.8, 0.03, 0.18), plank.darkened(0.06 * (k % 2)))


## Vines climbing the face of the higher neighbour's cliff, leafy stems
## from the foot to the lip.
func _vines(t: Vector2i, c: Vector3, plant: Color) -> void:
	var up := _toward(t, 1)
	var cliff := false
	for d: Vector2i in [Vector2i(0, -1), Vector2i(1, 0), Vector2i(0, 1), Vector2i(-1, 0)]:
		cliff = cliff or kit.height(t + d) > kit.height(t) + 0.1
	if not cliff:
		# No cliff beside it: a trellis for the vines to climb.
		var side0 := Vector3.RIGHT.rotated(Vector3.UP, up)
		for s2: float in [-1.0, 1.0]:
			kit.hero.box(Geo.place(c + side0 * s2 * 0.38 + Vector3(0, 0.45, -0.3).rotated(Vector3.UP, up), up),
				Vector3(0.06, 0.9, 0.06), KitStyle.WOOD.lightened(0.15))
		for y: float in [0.3, 0.6, 0.88]:
			kit.prop.box(Geo.place(c + Vector3(0, y, -0.3).rotated(Vector3.UP, up), up), Vector3(0.8, 0.03, 0.03),
				KitStyle.WOOD.lightened(0.2))
	var back := Vector3(0, 0, -0.5 if cliff else -0.36).rotated(Vector3.UP, up)
	var side := back.cross(Vector3.UP).normalized()
	var tall := maxf(IslandBuilder.LEVEL, 0.5) if cliff else 0.85
	kit.prop.moving(Geo.Anim.SWAY, c)
	for k in 5:
		var p := c + back * (0.92 if cliff else 1.0) + side * (-0.36 + 0.18 * k)
		var reach := tall * (0.7 + 0.35 * RealmKit.jitter(t, k + 20))
		kit.prop.prism(Geo.place(p), 4, 0.02, 0.014, reach, plant.darkened(0.35))
		for m in 4:
			var y := reach * (m + 0.5) / 4.0
			kit.prop.ball(Geo.place(p + Vector3(0, y, 0) - back * 0.06 + side * (0.04 * (m % 2) - 0.02), 0.0,
				Vector3(1.2, 0.8, 0.5)), 0.06 + 0.02 * RealmKit.jitter(t, k * 4 + m),
				plant.darkened(0.06 * ((k + m) % 3)), 2, 5)
		if k % 2 == 0:
			kit.prop.ball(Geo.place(p + Vector3(0, reach * 0.6, 0) - back * 0.09), 0.03, Color("#F7A6DA"), 2, 4)
	kit.prop.moving(Geo.Anim.NONE, Vector3.ZERO)


func _waterfall(t: Vector2i, c: Vector3, rock: Color) -> void:
	var yaw := _toward(t, -1)
	var fwd := Vector3(0, 0, -1).rotated(Vector3.UP, yaw)
	var below := kit.height(t + Vector2i(roundi(fwd.x), roundi(fwd.z)))
	var drop := maxf(c.y - below, 0.3) + 0.1
	var lip := c + fwd * 0.5 + Vector3(0, -KitGround.WATER_DROP, 0)
	for s: float in [-1.0, 1.0]:
		kit.hero.rock(Geo.place(lip + fwd.cross(Vector3.UP) * s * 0.42 + Vector3(0, 0.08, 0)), 0.14, rock, t.x)
	var w := kit.water
	var across := fwd.cross(Vector3.UP).normalized() * 0.38
	for k in 3:
		var y0 := -drop * k / 3.0
		var y1 := -drop * (k + 1) / 3.0
		var o0 := fwd * (0.02 + 0.08 * k / 3.0)
		var o1 := fwd * (0.02 + 0.08 * (k + 1) / 3.0)
		w.uv = Vector2(0.35, 0)
		w.quad(lip + o0 + Vector3(0, y0, 0) - across, lip + o0 + Vector3(0, y0, 0) + across,
			lip + o1 + Vector3(0, y1, 0) + across, lip + o1 + Vector3(0, y1, 0) - across, Color.WHITE)
	for k in 3:
		var p := lip + fwd * 0.2 + Vector3((k - 1) * 0.2, -drop + 0.1, 0)
		kit.clear.moving(Geo.Anim.BOB, p)
		kit.clear.ball(Geo.place(p, 0.0, Vector3(1, 0.7, 1)), 0.14, Color("#FFFFFF", 0.9), 3, 6)
	kit.clear.moving(Geo.Anim.NONE, Vector3.ZERO)
