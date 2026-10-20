class_name LawFxSigns
extends RefCounted
## §21.7's world signatures, "how its realm looks", one per law: Motion's,
## Matter's and Time's here, Energy's, Life's and Spirit's in LawFxSigns2.
## Each paints its law into `sig` from the realm's own grid (LawFxSite), so
## a Glass realm's clear walls are its walls and a Slow rivers realm's syrup
## is its water. Laws not yet drawn get their school's motes round the pylon.
## The diorama's nine (Screens v3's lawFX) are ported and pushed further.

const INK := Color("#1A0C14")


static func build(fx: LawFx, sig: Node3D, law: String) -> void:
	match law:
		"bounce":
			_bounce(fx, sig)
		"half_gravity":
			_half_gravity(fx, sig)
		"current":
			_current(fx, sig)
		"frictionless":
			_frictionless(fx, sig)
		"inward_pull":
			_inward_pull(fx, sig)
		"brittle_stone":
			_brittle_stone(fx, sig)
		"glass":
			_glass(fx, sig)
		"density":
			_density(fx, sig)
		"honeycomb":
			_honeycomb(fx, sig)
		"slow_rivers":
			_slow_rivers(fx, sig)
		"stillness":
			_stillness(fx, sig)
		"delay":
			_delay(fx, sig)
		"haste":
			_haste(fx, sig)
		"day_and_night":
			_day_and_night(fx, sig)
		_:
			LawFxSigns2.build(fx, sig, law)


## How tall a wall-like feature stands, for what a law lays over it: the
## realm kit's pieces (RealmKit's `_feature`), measured.
static func wall_height(code: int) -> float:
	return wall_size(code).y


## A wall-like feature's footprint and height, as the realm kit builds it.
static func wall_size(code: int) -> Vector3:
	match code:
		RealmKit.F.ROCK_PILLAR:
			return Vector3(0.84, 1.45, 0.84)
		RealmKit.F.BUILDING:
			return Vector3(1.0, 1.7, 1.0)
		RealmKit.F.BOULDER:
			return Vector3(0.84, 0.62, 0.76)
		RealmKit.F.STATUE:
			return Vector3(0.6, 1.15, 0.6)
		RealmKit.F.FENCE:
			return Vector3(0.94, 0.62, 0.14)
		RealmKit.F.RUIN_WALL:
			return Vector3(0.94, 0.94, 0.38)
		RealmKit.F.HEDGE:
			return Vector3(0.96, 0.74, 0.64)
		RealmKit.F.CRYSTAL_WALL:
			return Vector3(0.92, 1.1, 0.32)
	return Vector3(0.9, 0.8, 0.9)


## Bounce: "Walls wobble like jelly when touched." Every wall wears a coat
## of clear jelly that shivers now and then, a springy ring at its foot.
static func _bounce(fx: LawFx, sig: Node3D) -> void:
	var walls := fx.site.tiles(LawFxSite.WALLS)
	var jelly := LawFxBatch.new(LawFxBatch.Kind.SOLIDS)
	var feet: Array = []
	for t: Vector2i in walls:
		var c := fx.site.centre(t)
		var w := wall_size(fx.site.code(t)) + Vector3(0.14, 0.12, 0.14)
		var h := w.y
		var g := Geo.new()
		g.ball(Geo.place(Vector3(0, h * 0.5, 0), 0.0, Vector3(w.x * 0.58, h * 0.56, w.z * 0.62)), 1.0,
			Color("#FF7AC8"), 5, 10)
		jelly.geo(g, c, RealmKit.jitter(t, 1))
		feet.append(c)
	if jelly.triangles > 0:
		fx.layer(sig, jelly, fx.glass_material(Color("#C0287A"), 3, 1.0, 0.5))
	LawFxPaint.rounds(fx, sig, LawFxPaint.some_points(feet, 24), 1.0, 4, Color("#E05CB4"))
	LawFxPaint.spray(fx, sig, "bounce", {"n": 22, "shape": 1, "colour": Color("#FF7AC8", 0.95),
		"radius": [0.07, 0.11], "tiles": LawFxPaint.ground(fx.site), "lift": [0.15, 0.9], "wobble": 0.3,
		"glow": 0.3})


## Half gravity: "Pebbles hover a hand above the ground; dust falls slowly."
## The diorama's floating islets too, each with its shadow below.
static func _half_gravity(fx: LawFx, sig: Node3D) -> void:
	var r := fx.site.rng("half_gravity")
	var stones := LawFxBatch.new(LawFxBatch.Kind.SOLIDS)
	var under: Array = []
	var ground := LawFxPaint.ground(fx.site)
	for t: Vector2i in LawFxPaint.some(ground, 34):
		var c := fx.site.centre(t) + Vector3(r.randf_range(-0.3, 0.3), 0.0, r.randf_range(-0.3, 0.3))
		var g := Geo.new()
		var s := r.randf_range(0.1, 0.17)
		g.ball(Geo.place(Vector3.ZERO, 0.0, Vector3(1.2, 0.8, 1.0)), s, Color("#C9BCAA").darkened(r.randf() * 0.2), 3, 6)
		stones.geo(g, c + Vector3(0, 0.06, 0), r.randf())
		under.append(c)
	fx.layer(sig, stones, fx.solid_material(1, 0.16), true)
	LawFxPaint.shadows(fx, sig, under, 0.22)
	# The diorama's islets: a rock cone under a turf cap, a bush on some.
	var isles := LawFxBatch.new(LawFxBatch.Kind.SOLIDS)
	var isle_shadows: Array = []
	for k in 5:
		var c := fx.site.anywhere(r) + Vector3(0, 1.2 + r.randf() * 0.9, 0)
		var g := Geo.new()
		var w := r.randf_range(0.26, 0.42)
		g.prism(Geo.place(Vector3(0, -0.04, 0)), 7, w * 0.25, w, 0.0, Color("#9C8A7A"))
		g.prism(Geo.place(Vector3(0, -0.5, 0)), 7, 0.02, w, 0.46, Color("#9C8A7A"))
		g.prism(Geo.place(Vector3(0, -0.04, 0)), 7, w * 1.02, w * 1.02, 0.1, Color("#8FCB6A"))
		if k % 2 == 0:
			g.ball(Geo.place(Vector3(0.05, 0.18, 0)), 0.15, Color("#5CA453"), 3, 7)
		isles.geo(g, c, r.randf())
		isle_shadows.append(Vector3(c.x, fx.site.centre(Vector2i(int(c.x + fx.site.half().x),
			int(c.z + fx.site.half().y))).y, c.z))
	fx.layer(sig, isles, fx.solid_material(1, 0.35), true)
	LawFxPaint.shadows(fx, sig, isle_shadows, 0.5)
	LawFxPaint.spray(fx, sig, "half_gravity_dust", {"n": 60, "shape": 0, "colour": Color("#FFF4E0", 0.75),
		"radius": [0.04, 0.08], "lift": [1.4, 3.2], "vel": Vector3(0, -0.12, 0), "spread": Vector3(0.04, 0.03, 0.04),
		"period": [9.0, 14.0], "wobble": 0.1})


## Current: "Grass waves and leaves stream in one direction." The diorama's
## streaks, with leaves carried along in them.
static func _current(fx: LawFx, sig: Node3D) -> void:
	var h := fx.site.half()
	LawFxPaint.spray(fx, sig, "current", {"n": 26, "shape": 3, "colour": Color("#FFFFFF", 0.7),
		"radius": [0.06, 0.1], "lift": [0.5, 2.6], "vel": Vector3(h.x * 0.55, 0, 0.3), "period": [3.0, 4.0],
		"wobble": 0.12})
	LawFxPaint.spray(fx, sig, "current_leaves", {"n": 30, "shape": 10, "colour": Color("#7CC46A", 0.95),
		"colour_b": Color("#E8C04A", 0.95), "radius": [0.07, 0.1], "lift": [0.2, 1.4], "vel": Vector3(1.8, 0, 0.2),
		"spread": Vector3(0.3, 0.05, 0.2), "period": [4.0, 6.0], "wobble": 0.2})


## Frictionless: "Glossy ground with reflections." The ground glazed like
## ice, light sliding over it, glints that wink.
static func _frictionless(fx: LawFx, sig: Node3D) -> void:
	var ground := LawFxPaint.ground(fx.site)
	LawFxPaint.mark(fx, sig, ground, 0, Color("#BFE8F8"), Color("#5A7AB8"))
	LawFxPaint.spray(fx, sig, "frictionless", {"n": 40, "shape": 2, "colour": Color("#FFFFFF", 0.95),
		"radius": [0.07, 0.14], "tiles": LawFxPaint.some(ground, 40), "lift": [0.05, 0.12], "glow": 0.6})


## Inward pull: "Faint spiral streaks lead toward the Heart." Streaks on the
## ground wind in, and dust drifts in along them.
static func _inward_pull(fx: LawFx, sig: Node3D) -> void:
	LawFxPaint.mark(fx, sig, LawFxPaint.ground(fx.site), 3, Color("#D8901E"), Color("#5A3FB0"))
	var r := fx.site.rng("inward_pull")
	var b := LawFxBatch.new(LawFxBatch.Kind.MOTES)
	var heart := fx.site.heart
	for k in 40:
		var a := r.randf() * TAU
		var d := r.randf_range(3.0, fx.site.half().length())
		var at := heart + Vector3(cos(a) * d, r.randf_range(0.1, 0.6), sin(a) * d)
		var inward := (heart - at)
		inward.y = 0
		var swirl := Vector3(-inward.z, 0, inward.x).normalized() * 0.5
		var period := r.randf_range(4.0, 6.0)
		b.mote(at, inward / period * 0.8 + swirl, period, r.randf(), r.randf_range(0.05, 0.08), 0.0, 3,
			Color("#B8741E", 0.8))
	fx.layer(sig, b, fx.mote_material(0.4))


## Brittle stone: "Hairline cracks everywhere; crumbs fall from walls."
static func _brittle_stone(fx: LawFx, sig: Node3D) -> void:
	LawFxPaint.mark(fx, sig, LawFxPaint.ground(fx.site), 2, Color("#F4ECDC"), Color("#2A1A24"))
	var r := fx.site.rng("brittle_stone")
	var crumbs := LawFxBatch.new(LawFxBatch.Kind.SOLIDS)
	for t: Vector2i in fx.site.tiles(LawFxSite.WALLS):
		var top := wall_height(fx.site.code(t))
		for k in 3:
			var c := fx.site.centre(t) + Vector3(r.randf_range(-0.42, 0.42), top * r.randf_range(0.55, 0.95),
				r.randf_range(-0.42, 0.42))
			var g := Geo.new()
			g.box(Geo.place(Vector3.ZERO, r.randf() * TAU), Vector3.ONE * r.randf_range(0.05, 0.09), Color("#A89A8C"))
			crumbs.geo(g, c, r.randf())
	if crumbs.triangles > 0:
		fx.layer(sig, crumbs, fx.solid_material(9, 0.8))
	LawFxPaint.spray(fx, sig, "brittle_dust", {"n": 30, "shape": 0, "colour": Color("#E8DCCB", 0.6),
		"radius": [0.05, 0.1], "tiles": fx.site.tiles(LawFxSite.WALLS), "lift": [0.4, 1.0],
		"vel": Vector3(0, -0.25, 0), "period": [2.5, 4.0], "wobble": 0.05})


## Glass: "Walls turn clear with coloured edges." Every wall cased in clear
## glass whose edges glow in a run of colours, a sheen crossing it.
static func _glass(fx: LawFx, sig: Node3D) -> void:
	var shell := LawFxBatch.new(LawFxBatch.Kind.SOLIDS)
	var edges := LawFxBatch.new(LawFxBatch.Kind.SOLIDS)
	var hues: Array[Color] = [Color("#8C6CF0"), Color("#3CC6D8"), Color("#E05CB4"), Color("#F2B43C")]
	for t: Vector2i in fx.site.tiles(LawFxSite.WALLS):
		var c := fx.site.centre(t)
		var w := wall_size(fx.site.code(t)) + Vector3(0.08, 0.08, 0.08)
		var h := w.y
		var g := Geo.new()
		g.box(Geo.place(Vector3(0, h / 2.0, 0)), w, Color("#E6F4FF"))
		shell.geo(g, c, RealmKit.jitter(t, 2))
		var e := Geo.new()
		var hue: Color = hues[(t.x + t.y) % hues.size()]
		var glow := Color(hue.lightened(0.25), 0.25)
		var hx := w.x / 2.0
		var hz := w.z / 2.0
		for sx: float in [-hx, hx]:
			for sz: float in [-hz, hz]:
				e.box(Geo.place(Vector3(sx, h / 2.0, sz)), Vector3(0.07, h, 0.07), glow)
			e.box(Geo.place(Vector3(sx, h, 0)), Vector3(0.07, 0.07, w.z + 0.04), glow)
		for sz: float in [-hz, hz]:
			e.box(Geo.place(Vector3(0, h, sz)), Vector3(w.x + 0.04, 0.07, 0.07), glow)
		edges.geo(e, c, 0.0)
	if shell.triangles > 0:
		fx.layer(sig, shell, fx.glass_material(Color("#8C6CF0"), 0, 1.0, 0.4))
		var m := fx.solid_material(0)
		m.set_shader_parameter("glow", 1.4)
		fx.layer(sig, edges, m)
	LawFxPaint.spray(fx, sig, "glass", {"n": 24, "shape": 2, "colour": Color("#FFFFFF", 0.9), "radius": [0.06, 0.12],
		"tiles": fx.site.tiles(LawFxSite.WALLS), "lift": [0.3, 1.2], "glow": 0.6})


## Density: "Grass and props look slightly oversized." Tufts of grass a
## head too tall, pebbles the size of loaves, swaying heavily.
static func _density(fx: LawFx, sig: Node3D) -> void:
	var r := fx.site.rng("density")
	var tufts := LawFxBatch.new(LawFxBatch.Kind.SOLIDS)
	var ground := LawFxPaint.ground(fx.site)
	for t: Vector2i in LawFxPaint.some(ground, 56):
		var c := fx.site.centre(t) + Vector3(r.randf_range(-0.4, 0.4), 0, r.randf_range(-0.4, 0.4))
		var g := Geo.new()
		if r.randf() < 0.7:
			for k in 4:
				var a := k * TAU / 4.0 + r.randf()
				var lean := Basis(Vector3(cos(a), 0, sin(a)).cross(Vector3.UP).normalized(), 0.3)
				g.prism(Transform3D(lean, Vector3(cos(a) * 0.05, 0, sin(a) * 0.05)), 3, 0.06, 0.0,
					r.randf_range(0.6, 0.95), Color("#3E7A30").lightened(r.randf() * 0.15))
		else:
			g.ball(Geo.place(Vector3(0, 0.13, 0), 0.0, Vector3(1.3, 0.8, 1.0)), 0.27, Color("#D8CFC2"), 3, 7)
		tufts.geo(g, c, r.randf())
	fx.layer(sig, tufts, fx.solid_material(5, 0.12, 0.5), true)


## Honeycomb: "A golden hexagon sheen covers the ground." Honey drips from
## walls, hexagon flecks float.
static func _honeycomb(fx: LawFx, sig: Node3D) -> void:
	LawFxPaint.mark(fx, sig, LawFxPaint.ground(fx.site), 1, Color("#F6C453"), Color("#B8741E"))
	var r := fx.site.rng("honeycomb")
	var drips := LawFxBatch.new(LawFxBatch.Kind.SOLIDS)
	for t: Vector2i in fx.site.tiles(LawFxSite.WALLS):
		for k in 2:
			var c := fx.site.centre(t) + Vector3(r.randf_range(-0.45, 0.45), wall_height(fx.site.code(t)) * 0.9,
				r.randf_range(-0.45, 0.45))
			var g := Geo.new()
			g.ball(Geo.place(Vector3.ZERO, 0.0, Vector3(1, 1.5, 1)), 0.06, Color("#F6B42C", 0.6), 3, 6)
			drips.geo(g, c, r.randf())
	if drips.triangles > 0:
		fx.layer(sig, drips, fx.solid_material(9, 0.7, 0.6))
	LawFxPaint.spray(fx, sig, "honeycomb", {"n": 22, "shape": 7, "colour": Color("#FFD24A", 0.9),
		"radius": [0.07, 0.11], "lift": [0.2, 1.5], "wobble": 0.15, "glow": 0.4})


## Slow rivers: "Water flows like syrup; drops hang in the air." Thick slow
## rings on every water tile, and drops hanging over it.
static func _slow_rivers(fx: LawFx, sig: Node3D) -> void:
	var wet := fx.site.tiles(LawFxSite.WATER)
	var near := wet
	if wet.is_empty():
		# No water in the realm: the drops hang round the pylon instead.
		var p := LawFxPaint.home(fx, "slow_rivers")
		LawFxPaint.rounds(fx, sig, [p], 1.8, 4, Color("#1F8499"), INK, 0.3)
		near = []
	else:
		LawFxPaint.mark(fx, sig, wet, 16, Color("#3CC6D8"), Color("#1F6A99"))
	var r := fx.site.rng("slow_rivers")
	var drops := LawFxBatch.new(LawFxBatch.Kind.SOLIDS)
	for k in 30:
		var c: Vector3
		if near.is_empty():
			var a := r.randf() * TAU
			c = LawFxPaint.home(fx, "slow_rivers") + Vector3(cos(a) * 1.4, 0, sin(a) * 1.4)
		else:
			c = fx.site.centre(near[k % near.size()]) + Vector3(r.randf_range(-0.4, 0.4), 0, r.randf_range(-0.4, 0.4))
		var g := Geo.new()
		g.ball(Geo.place(Vector3.ZERO, 0.0, Vector3(1, 1.45, 1)), r.randf_range(0.08, 0.13), Color("#5CD8EA", 0.7), 3, 7)
		drops.geo(g, c + Vector3(0, r.randf_range(0.3, 1.1), 0), r.randf())
	fx.layer(sig, drops, fx.solid_material(1, 0.04, 0.15), true)


## Stillness: "The air is calm; not a leaf moves." The diorama's clock face
## laid round the pylon, hands held still, a ring of drops hanging in the
## air round it, calm spreading in rings; motes that do not drift.
static func _stillness(fx: LawFx, sig: Node3D) -> void:
	var p := LawFxPaint.home(fx, "stillness")
	LawFxPaint.rounds(fx, sig, [p], 2.6, 14, Color("#EFE3F4"), Color("#6A4A8A"))
	var r := fx.site.rng("stillness")
	var drops := LawFxBatch.new(LawFxBatch.Kind.SOLIDS)
	for k in 22:
		var a := k * TAU / 22.0
		var d := 2.1 + r.randf() * 0.4
		var g := Geo.new()
		g.ball(Geo.place(Vector3.ZERO, 0.0, Vector3(1, 1.4, 1)), r.randf_range(0.06, 0.1), Color("#9BEAF3", 0.5), 3, 7)
		drops.geo(g, p + Vector3(cos(a) * d, 0.7 + r.randf() * 1.6, sin(a) * d), r.randf())
	fx.layer(sig, drops, fx.solid_material(1, 0.02, 0.1), true)
	LawFxPaint.spray(fx, sig, "stillness", {"n": 50, "shape": 2, "colour": Color("#9BEAF3", 0.8),
		"radius": [0.04, 0.08], "lift": [0.3, 2.8], "glow": 0.5})


## Delay: "Ripples linger around anything triggered." Rings spread, each a
## beat behind the last, round every pylon, ward and the Vault.
static func _delay(fx: LawFx, sig: Node3D) -> void:
	var at: Array = [fx.site.heart]
	for p: Dictionary in fx.site.pylons:
		at.append(p["at"])
	at.append_array(fx.site.wards)
	at.append_array(fx.site.posts)
	for t: Vector2i in fx.site.tiles(LawFxSite.METAL + LawFxSite.LIGHTS):
		at.append(fx.site.centre(t))
	LawFxPaint.rounds(fx, sig, at, 1.9, 4, Color("#1F8499"))
	LawFxPaint.spray(fx, sig, "delay", {"n": 26, "shape": 6, "colour": Color("#1F8499", 0.8), "radius": [0.08, 0.14],
		"lift": [0.2, 1.6], "vel": Vector3(0, 0.08, 0), "period": [5.0, 8.0]})


## Haste: "Clouds race overhead; plants sway quickly." Cloud shadows race
## over the ground, wind lines whip past, leaves whirl.
static func _haste(fx: LawFx, sig: Node3D) -> void:
	LawFxPaint.mark(fx, sig, fx.site.tiles(LawFxSite.GROUND + LawFxSite.PLANTS + LawFxSite.WATER), 15,
		Color("#6A5AD8"))
	var h := fx.site.half()
	LawFxPaint.spray(fx, sig, "haste", {"n": 30, "shape": 3, "colour": Color("#4A5AC8", 0.75), "radius": [0.05, 0.08],
		"lift": [0.3, 2.0], "vel": Vector3(h.x * 1.4, 0, h.y * 0.4), "period": [1.2, 1.8]})
	# Clouds racing past the island's edge, in the sky round it.
	var r := fx.site.rng("haste_clouds")
	var clouds := LawFxBatch.new(LawFxBatch.Kind.MOTES)
	for k in 10:
		var z := r.randf_range(-h.y - 6.0, -h.y - 2.0) if k % 2 == 0 else r.randf_range(h.y + 1.0, h.y + 4.0)
		var at := Vector3(-h.x - 8.0, r.randf_range(2.0, 4.0), z)
		for puff in 3:
			clouds.mote(at + Vector3(puff * 0.7, sin(puff) * 0.2, 0), Vector3(h.x * 1.6, 0, 0), 2.2, k * 0.1,
				r.randf_range(0.5, 0.8), 0.0, 0, Color("#FFFFFF", 0.9))
	fx.layer(sig, clouds, fx.mote_material(0.2))
	LawFxPaint.spray(fx, sig, "haste_leaves", {"n": 16, "shape": 10, "colour": Color("#7CC46A", 0.95),
		"radius": [0.06, 0.09], "tiles": fx.site.tiles(LawFxSite.PLANTS), "lift": [0.3, 1.2], "wobble": 0.35,
		"pace": 2.2})


## Day and night: "The sky flips between day and night." The diorama's
## thirty-second day: the sun and the shade dim and brighten, a dusk wash
## falls over the screen in the dark phase, lanterns glow up.
static func _day_and_night(fx: LawFx, sig: Node3D) -> void:
	var lights := fx.site.tiles(LawFxSite.LIGHTS)
	var pools: Array = []
	for t: Vector2i in lights:
		pools.append(fx.site.centre(t))
	pools.append(LawFxPaint.home(fx, "day_and_night"))
	var pool := LawFxPaint.rounds(fx, sig, pools, 1.6, 8, Color("#FFD27A"))
	var pool_mat := pool.material_override as ShaderMaterial
	var tint := fx.tint(Color("#1A1433"), 0.0, 0.0)
	fx.every(func(s: float) -> void:
		var d := sin(s * TAU / 30.0) * 0.5 + 0.5
		fx.set_light(0.3 + 0.7 * d, 0.55 + 0.45 * d)
		fx.set_sky(1.0 - d, (1.0 - d) * 0.45)
		if tint != null:
			tint.set_shader_parameter("wash", (1.0 - d) * 0.28)
			tint.set_shader_parameter("edge", (1.0 - d) * 0.5)
		pool_mat.set_shader_parameter("strength", 0.25 + (1.0 - d) * 1.2))
