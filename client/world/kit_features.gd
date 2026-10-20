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
			for k in 4:
				var o := Vector3(RealmKit.jitter(t, k) - 0.5, 0, RealmKit.jitter(t, k + 5) - 0.5) * 0.5
				kit.clear.moving(Geo.Anim.BOB, c + o)
				kit.clear.ball(Geo.place(c + o + Vector3(0, 0.32 + 0.12 * (k % 2), 0), 0.0, Vector3(1.3, 0.62, 1.3)),
					0.32 + 0.1 * RealmKit.jitter(t, k + 9), Color("#F3EEFF"), 4, 9)
			kit.clear.still()
		RealmKit.F.TALL_GRASS:
			prop.moving(Geo.Anim.SHIVER, c)
			for k in 13:
				var p := c + Vector3(RealmKit.jitter(t, k) - 0.5, 0, RealmKit.jitter(t, k + 9) - 0.5) * 0.86
				prop.moving(Geo.Anim.SHIVER, p)
				prop.blade(p, 0.42 + 0.22 * RealmKit.jitter(t, k + 2), 0.045,
					plant.darkened(0.08 + 0.1 * (k % 3)).lerp(Color("#3E7A3A"), 0.25), 0.25, RealmKit.jitter(t, k + 3) * TAU)
			prop.still()
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
			hero.rock(Geo.place(c + Vector3(0, 0.24, 0), j * TAU, Vector3(1.0, 0.72, 0.92)), 0.4, rock.lightened(0.1),
				t.x * 13 + t.y)
			hero.rock(Geo.place(c + Vector3(0.3, 0.08, 0.18), j * 3.0, Vector3(1.0, 0.75, 1.0)), 0.16, rock, t.x + 5)
		RealmKit.F.STATUE:
			_statue(c, j, stone)
		RealmKit.F.CRYSTAL_OUTCROP:
			_crystals(t, c)
		RealmKit.F.LAVA_CRACK:
			_lava(t, c)
		RealmKit.F.GRAVEL_PATH:
			for k in 6:
				prop.rock(Geo.place(c + Vector3(RealmKit.jitter(t, k) - 0.5, 0.0, RealmKit.jitter(t, k + 6) - 0.5) * 0.8,
					0.0, Vector3(1, 0.5, 1)), 0.04 + 0.025 * RealmKit.jitter(t, k + 3), Palette.GRAVEL.darkened(0.12), k)
		RealmKit.F.THICKET:
			prop.moving(Geo.Anim.SWAY, c)
			for k in 6:
				var o := Vector3(RealmKit.jitter(t, k) - 0.5, 0, RealmKit.jitter(t, k + 3) - 0.5) * 0.62
				prop.ball(Geo.place(c + o + Vector3(0, 0.18 + 0.14 * RealmKit.jitter(t, k + 7), 0)),
					0.2 + 0.1 * RealmKit.jitter(t, k + 1), plant.darkened(0.3 + 0.08 * (k % 2)), 3, 7)
			prop.still()
		RealmKit.F.SHADE_CANOPY:
			_canopy(c, wood)
		RealmKit.F.BUSH:
			prop.moving(Geo.Anim.SWAY, c)
			prop.ball(Geo.place(c + Vector3(0, 0.22, 0), j, Vector3(1.0, 0.85, 1.0)), 0.3, plant.darkened(0.1), 4, 8)
			prop.ball(Geo.place(c + Vector3(0.24, 0.16, 0.12)), 0.22, plant.lightened(0.04), 3, 7)
			prop.ball(Geo.place(c + Vector3(-0.2, 0.13, 0.16)), 0.2, plant.darkened(0.02), 3, 7)
			prop.still()
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
			kit.clear.moving(Geo.Anim.BOB, c)
			kit.clear.ball(Geo.place(c + Vector3(0, 0.45, 0), 0.0, Vector3(1, 1.6, 1)), 0.1,
				Color(Palette.ENERGY.lightened(0.3), 0.2), 3, 6)
			kit.clear.still()
		RealmKit.F.STATIC_STONE:
			hero.rock(Geo.place(c + Vector3(0, 0.26, 0), j, Vector3(0.8, 1.3, 0.8)), 0.3, Color("#5A6A8A"), t.x + t.y)
			hero.moving(Geo.Anim.SPIN_Y, c)
			for k in 3:
				var a := TAU * k / 3.0
				hero.gem(Geo.place(c + Vector3(cos(a) * 0.36, 0.5 + 0.12 * k, sin(a) * 0.36), a), 0.05, 0.08,
					Color(Color("#7AE8FF"), 0.2), 4)
			hero.still()
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
			prop.still()
		RealmKit.F.FLOWER_MEADOW:
			var petals: Array[Color] = [Color("#FF8AB0"), Color("#FFE08A"), Color("#FFFFFF"), Color("#B79BFF")]
			for k in 22:
				var p := c + Vector3(RealmKit.jitter(t, k) - 0.5, 0.0, RealmKit.jitter(t, k + 9) - 0.5) * 0.9
				var stem := 0.07 + 0.08 * RealmKit.jitter(t, k + 40)
				prop.moving(Geo.Anim.SHIVER, p)
				prop.blade(p, stem, 0.012, plant.darkened(0.2))
				prop.ball(Geo.place(p + Vector3(0, stem, 0), 0.0, Vector3(1, 0.55, 1)), 0.05, petals[k % 4], 2, 6)
			prop.still()
		RealmKit.F.ICE_SHEET:
			kit.clear.rbox(Geo.place(c + Vector3(0, 0.025, 0)), Vector3(0.98, 0.05, 0.98), Color("#DDF4FF"), 0.02)
			for k in 3:
				prop.box(Geo.place(c + Vector3((RealmKit.jitter(t, k) - 0.5) * 0.5, 0.052, (k - 1) * 0.25),
					RealmKit.jitter(t, k + 3) * PI), Vector3(0.36, 0.006, 0.025), Color("#FFFFFF"))
		RealmKit.F.BELL_POST:
			_bell(c, j, wood)
		RealmKit.F.STEPPING_STONES:
			for k in 3:
				var p := c + Vector3(-0.3 + 0.3 * k, 0.1, (RealmKit.jitter(t, k) - 0.5) * 0.35)
				prop.moving(Geo.Anim.BOB, p)
				prop.cyl(Geo.place(p), 0.15, 0.17, 0.08, stone.darkened(0.04), 8, stone.lightened(0.06))
				prop.prism(Transform3D(Basis(Vector3.RIGHT, PI), p), 6, 0.15, 0.0, 0.14, kit.palette["rock"])
			prop.still()
		RealmKit.F.BOUNCE_MUSHROOM:
			_mushroom(t, c)
		RealmKit.F.UPDRAFT_VENT:
			prop.ring(Geo.place(c + Vector3(0, 0.02, 0)), 0.2, 0.38, rock.darkened(0.15), 14)
			for k in 4:
				prop.box(Geo.place(c + Vector3(0, 0.021, -0.15 + 0.1 * k)), Vector3(0.36, 0.01, 0.03), KitStyle.IRON)
			kit.clear.moving(Geo.Anim.SPIN_Y, c)
			kit.clear.cyl(Geo.place(c + Vector3(0, 0.02, 0)), 0.3, 0.42, 1.6, Color("#CFEFFF", 0.7), 10)
			kit.clear.still()
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
				prop.rbox(Geo.place(c + step + Vector3(0, hh / 2.0, 0), up), Vector3(0.78, hh, 0.25),
					steps.lightened(0.08 * (k % 2)), 0.02, steps.lightened(0.15))
			for sx: float in [-1.0, 1.0]:
				prop.rock(Geo.place(c + Vector3(sx * 0.44, 0.06, 0.3).rotated(Vector3.UP, up)), 0.09,
					kit.palette["rock"], t.x + int(sx))
		RealmKit.F.CLIMBING_VINES:
			_vines(t, c, plant)
		RealmKit.F.WATERFALL:
			_waterfall(t, c, rock)
		RealmKit.F.RAPIDS:
			for k in 3:
				kit.water.uv = Vector2(0.0, 0.0)
				kit.water.box(Geo.place(c + Vector3((k - 1) * 0.28, -KitGround.WATER_DROP + 0.012, (k - 1) * 0.2),
					kit.yaw(t) + 0.3 * k), Vector3(0.34, 0.01, 0.05), Color.WHITE)
				prop.rock(Geo.place(c + Vector3((RealmKit.jitter(t, k) - 0.5) * 0.7, -0.1, (k - 1) * 0.3)), 0.08, rock, k)
		RealmKit.F.POND:
			for k in 5:
				var a := TAU * k / 5.0 + 0.4
				prop.rock(Geo.place(c + Vector3(cos(a) * 0.46, -0.04, sin(a) * 0.46), a, Vector3(1, 0.7, 1)), 0.1,
					Color("#B0A898"), t.x + k)
			prop.cyl(Geo.place(c + Vector3(0.12, -KitGround.WATER_DROP + 0.005, -0.1)), 0.09, 0.09, 0.01,
				Color("#3F9A4A"), 8)
			prop.ball(Geo.place(c + Vector3(0.14, -KitGround.WATER_DROP + 0.03, -0.1)), 0.025, Color("#F7A6DA"), 2, 5)


func _pillar(c: Vector3, j: float, rock: Color) -> void:
	var hero := kit.hero
	hero.prism(Geo.place(c, j), 7, 0.34, 0.25, 1.0, rock, false, rock.lightened(0.12))
	for y: float in [0.3, 0.62]:
		hero.prism(Geo.place(c + Vector3(0, y, 0), j), 7, 0.33 - y * 0.09, 0.32 - y * 0.09, 0.05, rock.darkened(0.12))
	hero.prism(Geo.place(c + Vector3(0, 1.0, 0), j + 0.4), 7, 0.25, 0.18, 0.3, rock.darkened(0.06))
	hero.rock(Geo.place(c + Vector3(0, 1.38, 0), j, Vector3(1, 0.7, 1)), 0.2, rock.lightened(0.06), int(j * 100))
	kit.prop.rock(Geo.place(c + Vector3(0.32, 0.04, 0.22)), 0.08, rock.darkened(0.05), int(j * 50))


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
	kit.prop.still()


func _fence(t: Vector2i, c: Vector3) -> void:
	var yaw := _run_yaw(t, RealmKit.F.FENCE)
	var dir := Vector3.RIGHT.rotated(Vector3.UP, yaw)
	var wood := KitStyle.WOOD.lightened(0.15)
	for k in 3:
		var p := c + dir * (-0.38 + 0.38 * k)
		kit.hero.box(Geo.place(p + Vector3(0, 0.26, 0), yaw), Vector3(0.08, 0.52, 0.08), wood.darkened(0.1))
		kit.hero.prism(Geo.place(p + Vector3(0, 0.52, 0), yaw + PI / 4.0), 4, 0.057, 0.0, 0.08, wood.darkened(0.1))
	for y: float in [0.18, 0.38]:
		kit.hero.box(Geo.place(c + Vector3(0, y, 0), yaw), Vector3(1.0, 0.06, 0.04), wood)


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
	hero.still()


func _tree(t: Vector2i, c: Vector3, j: float, plant: Color) -> void:
	var hero := kit.hero
	var bark := KitStyle.WOOD.lightened(0.05)
	var kind: String = style["tree"]
	var tall := 0.9 + 0.25 * RealmKit.jitter(t, 21)
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
			hero.cyl(Geo.place(c), 0.12, 0.08, 0.63 * tall, bark, 7)
			for k in 2:
				var a := j * TAU + PI * k
				hero.box(Transform3D(Basis(Vector3(cos(a), 0, sin(a)).cross(Vector3.UP), 0.7),
					c + Vector3(cos(a) * 0.08, 0.45 * tall, sin(a) * 0.08)), Vector3(0.04, 0.22, 0.04), bark)
			hero.ball(Geo.place(c + Vector3(0, 0.85 * tall, 0), j, Vector3(1.0, 0.86, 1.0)), 0.47, plant.darkened(0.06),
				5, 10)
			hero.ball(Geo.place(c + Vector3(0.2, 1.08 * tall, 0.09), j), 0.31, plant.lightened(0.08), 4, 8)
			hero.ball(Geo.place(c + Vector3(-0.18, 1.12 * tall, -0.09), j), 0.27, plant.lightened(0.02), 4, 8)
			if kit.realm == "verdant" or kit.realm == "heart":
				var fruit: Color = Color("#E2536B") if kit.realm == "verdant" else Color("#F7A6DA")
				for k in 4:
					var a := TAU * k / 4.0 + j * 3.0
					hero.ball(Geo.place(c + Vector3(cos(a) * 0.42, (0.8 + 0.12 * (k % 2)) * tall, sin(a) * 0.42)), 0.045,
						fruit, 2, 5)
	hero.still()


func _statue(c: Vector3, j: float, stone: Color) -> void:
	var hero := kit.hero
	var s := stone.lightened(0.06)
	hero.rbox(Geo.place(c + Vector3(0, 0.11, 0)), Vector3(0.48, 0.22, 0.48), stone.darkened(0.08), 0.03)
	hero.rbox(Geo.place(c + Vector3(0, 0.25, 0)), Vector3(0.4, 0.06, 0.4), stone.darkened(0.02), 0.02)
	hero.cyl(Geo.place(c + Vector3(0, 0.28, 0)), 0.17, 0.12, 0.5, s, 8)
	hero.ball(Geo.place(c + Vector3(0, 0.88, 0)), 0.13, s, 4, 8)
	# Arms raised, holding up an orb.
	for sx: float in [-1.0, 1.0]:
		hero.box(Transform3D(Basis(Vector3.FORWARD, sx * 0.5), c + Vector3(sx * 0.15, 0.78, 0)),
			Vector3(0.06, 0.28, 0.06), s)
	hero.ball(Geo.place(c + Vector3(0, 1.12, 0)), 0.09, Color(KitStyle.GOLD, 0.6), 3, 7)
	kit.prop.moving(Geo.Anim.SHIVER, c)
	kit.prop.ball(Geo.place(c + Vector3(0.2, 0.25, 0.22), j, Vector3(1, 0.6, 1)), 0.08, kit.palette["plant"], 3, 6)
	kit.prop.still()


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
			kit.hero.still()
		kit.hero.gem(Transform3D(tilt.rotated(Vector3.UP, RealmKit.jitter(t, k)), p + Vector3(0, tall * 0.9, 0)),
			r * 0.62, tall, Color(colour.darkened(0.06 * k), 0.75), 5)
	kit.hero.still()
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


func _canopy(c: Vector3, wood: Color) -> void:
	var hero := kit.hero
	var cloth: Color = style["accent"].lightened(0.35)
	for p: Vector2 in [Vector2(-0.36, -0.36), Vector2(0.36, -0.36), Vector2(-0.36, 0.36), Vector2(0.36, 0.36)]:
		hero.cyl(Geo.place(c + Vector3(p.x, 0, p.y)), 0.035, 0.03, 0.92, wood, 5)
	hero.moving(Geo.Anim.SWAY, c)
	hero.prism(Geo.place(c + Vector3(0, 0.9, 0), PI / 4.0), 4, 0.66, 0.0, 0.26, cloth, false)
	for k in 4:
		var a := PI / 2.0 * k
		var o := Vector3(cos(a), 0, sin(a)) * 0.45
		hero.box(Geo.place(c + o + Vector3(0, 0.86, 0), a + PI / 2.0), Vector3(0.9, 0.09, 0.02), cloth.darkened(0.1))
	hero.still()
	hero.ball(Geo.place(c + Vector3(0, 1.18, 0)), 0.04, KitStyle.GOLD, 2, 5)


func _spring(t: Vector2i, c: Vector3, rock: Color) -> void:
	for k in 7:
		var a := TAU * k / 7.0
		kit.prop.rock(Geo.place(c + Vector3(cos(a) * 0.45, -0.05, sin(a) * 0.45), a), 0.09, rock.lightened(0.15), k)
	for k in 3:
		var p := c + Vector3(RealmKit.jitter(t, k) - 0.5, 0, RealmKit.jitter(t, k + 1) - 0.5) * 0.4
		kit.clear.moving(Geo.Anim.BOB, p + Vector3(0, k, 0))
		kit.clear.ball(Geo.place(p + Vector3(0, 0.2 + 0.22 * k, 0)), 0.12 + 0.05 * k, Color("#FFFFFF", 0.85), 3, 7)
	kit.clear.still()


func _lantern(c: Vector3) -> void:
	var hero := kit.hero
	var iron := KitStyle.IRON
	hero.cyl(Geo.place(c), 0.07, 0.05, 0.1, iron, 6)
	hero.cyl(Geo.place(c + Vector3(0, 0.1, 0)), 0.035, 0.028, 0.95, iron.lightened(0.1), 6)
	hero.box(Geo.place(c + Vector3(0, 1.05, 0)), Vector3(0.24, 0.025, 0.24), iron)
	hero.rbox(Geo.place(c + Vector3(0, 1.16, 0)), Vector3(0.17, 0.2, 0.17), Color(Color("#FFD27A"), 0.15), 0.02)
	hero.prism(Geo.place(c + Vector3(0, 1.26, 0), PI / 4.0), 4, 0.17, 0.0, 0.12, iron)
	# Its pool of light on the ground.
	kit.clear.ring(Geo.place(c + Vector3(0, 0.015, 0)), 0.0, 0.42, Color(Color("#FFC860"), 0.35), 14)


func _arch(t: Vector2i, c: Vector3, stone: Color) -> void:
	var hero := kit.hero
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
		hero.rbox(Transform3D(basis, p), Vector3(0.12, 0.16, 0.28), KitStyle.GOLD if k == 3 else stone.lightened(0.04),
			0.02)


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
	hero.still()


func _mushroom(t: Vector2i, c: Vector3) -> void:
	var hero := kit.hero
	var glows := kit.realm == "lanternvale"
	var cap := Color("#E2536B") if not glows else Color(Color("#7AD8C8"), 0.5)
	hero.cyl(Geo.place(c), 0.11, 0.08, 0.38, Color("#F3E6CC"), 8)
	hero.moving(Geo.Anim.BOB, c)
	hero.ball(Geo.place(c + Vector3(0, 0.34, 0), 0.0, Vector3(1, 0.62, 1)), 0.38, cap, 4, 12, true)
	hero.cyl(Geo.place(c + Vector3(0, 0.31, 0)), 0.36, 0.38, 0.04, Color("#F3E6CC"), 12)
	for k in 5:
		var a := TAU * k / 5.0 + RealmKit.jitter(t, 4)
		hero.ball(Geo.place(c + Vector3(cos(a) * 0.22, 0.52, sin(a) * 0.22), 0.0, Vector3(1, 0.5, 1)), 0.05,
			Color("#FFFFFF"), 2, 5)
	hero.still()


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
	var back := Vector3(0, 0, -0.5).rotated(Vector3.UP, up)
	var side := back.cross(Vector3.UP).normalized()
	var tall := maxf(IslandBuilder.LEVEL, 0.5)
	kit.prop.moving(Geo.Anim.SWAY, c)
	for k in 5:
		var p := c + back * 0.92 + side * (-0.36 + 0.18 * k)
		var reach := tall * (0.7 + 0.35 * RealmKit.jitter(t, k + 20))
		kit.prop.prism(Geo.place(p), 4, 0.02, 0.014, reach, plant.darkened(0.35))
		for m in 4:
			var y := reach * (m + 0.5) / 4.0
			kit.prop.ball(Geo.place(p + Vector3(0, y, 0) - back * 0.06 + side * (0.04 * (m % 2) - 0.02), 0.0,
				Vector3(1.2, 0.8, 0.5)), 0.06 + 0.02 * RealmKit.jitter(t, k * 4 + m),
				plant.darkened(0.06 * ((k + m) % 3)), 2, 5)
		if k % 2 == 0:
			kit.prop.ball(Geo.place(p + Vector3(0, reach * 0.6, 0) - back * 0.09), 0.03, Color("#F7A6DA"), 2, 4)
	kit.prop.still()


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
	kit.clear.still()
