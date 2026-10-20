class_name LawFxHarmony
extends RefCounted
## §21.9's harmony, dissonance and chord effects (8, 4 and 12) and §7.5's
## three paradoxes, drawn as overlays that sit on the laws' own signatures
## (LawFxLinks draws the threads, lines and triangles themselves).


## §8.2's harmony effect of `n`, shared by the laws at `a` and `b`: "strengthens
## the shared kind of effect", drawn round both pylons.
static func note(fx: LawFx, into: Node3D, n: String, a: Vector3, b: Vector3) -> void:
	var col := LawFxLinks.note_colour(n)
	var slot := "harmony_%s_%d" % [n, hash(a) ^ hash(b)]
	match n:
		"flow":
			# Movement 25% stronger: wind lines run between the two.
			var period := maxf(2.0, a.distance_to(b) / 2.5)
			LawFxPaint.spray(fx, into, slot, {"n": 14, "shape": 3, "colour": Color(col.lightened(0.4), 0.8),
				"radius": [0.05, 0.08], "at": a, "reach": 0.8, "lift": [0.3, 1.0], "vel": (b - a) / period,
				"period": [period, period * 1.2]})
		"weight":
			# Slowing and pulling stronger: anchors of weight sink at both.
			for c: Vector3 in [a, b]:
				LawFxPaint.spray(fx, into, slot + str(c), {"n": 10, "shape": 9, "colour": Color(col, 0.9),
					"radius": [0.07, 0.1], "at": c, "reach": 1.2, "lift": [1.2, 1.8], "vel": Vector3(0, -0.4, 0),
					"period": [2.5, 3.5]})
		"glow":
			# Light reaches 2 tiles further: a pool of light round both.
			LawFxPaint.rounds(fx, into, [a, b], 2.6, 8, col.lightened(0.2))
		"hush":
			# Hiding works closer: a hush of shade pools round both.
			LawFxPaint.rounds(fx, into, [a, b], 1.9, 8, Color("#2A1F5A"))
			LawFxPaint.spray(fx, into, slot, {"n": 14, "shape": 0, "colour": Color(col, 0.6), "radius": [0.1, 0.16],
				"at": a.lerp(b, 0.5), "reach": a.distance_to(b) * 0.5, "lift": [0.2, 0.6], "wobble": 0.1})
		"bloom":
			# Regrowth stronger: leaves and petals spiral up round both.
			for c: Vector3 in [a, b]:
				LawFxPaint.spray(fx, into, slot + str(c), {"n": 12, "shape": 10, "colour": Color(col, 1.0),
					"colour_b": Color("#F7A6DA"), "radius": [0.06, 0.09], "at": c, "reach": 0.9, "lift": [0.1, 0.4],
					"vel": Vector3(0, 0.3, 0), "period": [3.0, 4.0], "wobble": 0.3})
		"spark":
			# Damage and stuns stronger: sparks spit at both.
			for c: Vector3 in [a, b]:
				LawFxPaint.spray(fx, into, slot + str(c), {"n": 12, "shape": 8, "colour": Color(col.lightened(0.3), 1.0),
					"radius": [0.07, 0.1], "at": c, "reach": 1.0, "lift": [0.2, 1.5], "glow": 0.9, "pace": 2.5})
		"echo":
			# Returns sooner: rings repeat round both.
			LawFxPaint.rounds(fx, into, [a, b], 1.6, 4, col.lightened(0.3))
		"veil":
			# Illusions last longer: a mask-like shimmer round both.
			for c: Vector3 in [a, b]:
				LawFxPaint.spray(fx, into, slot + str(c), {"n": 10, "shape": 7, "colour": Color(col.lightened(0.3), 0.7),
					"radius": [0.07, 0.11], "at": c, "reach": 1.1, "lift": [0.3, 1.6], "wobble": 0.2})


## §8.3's dissonance effect of `clash`, between the laws at `a` and `b`.
static func clash(fx: LawFx, into: Node3D, which: String, a: Vector3, b: Vector3) -> void:
	var slot := "clash_%s" % which
	match which:
		"flow":
			# Gusts and lulls: wind lines lurch one way and back.
			var h := fx.site.half()
			for dir: float in [1.0, -1.0]:
				LawFxPaint.spray(fx, into, slot + str(dir), {"n": 14, "shape": 3, "colour": Color("#E8F4FF", 0.75),
					"radius": [0.05, 0.08], "lift": [0.3, 1.8], "vel": Vector3(h.x * 0.9 * dir, 0, 0.4 * dir),
					"period": [1.6, 2.6]})
		"glow":
			# Flicker: light strobes across the island every 15 seconds for 3.
			var tint := fx.tint(Color("#0A0620"), 0.0)
			if tint != null:
				fx.every(func(s: float) -> void:
					var u := fmod(s, 15.0)
					var on := u > 12.0
					var beat := int(s * 8.0) % 2 == 0
					tint.set_shader_parameter("flash", 0.3 if on and beat else 0.0)
					tint.set_shader_parameter("wash", 0.35 if on and not beat else 0.0))
		"bloom":
			# Wildfire: small flames race through the greenery.
			var green := fx.site.tiles(LawFxSite.PLANTS)
			if green.is_empty():
				green = LawFxPaint.some(LawFxPaint.ground(fx.site), 8)
			LawFxPaint.spray(fx, into, slot, {"n": 40, "shape": 9, "colour": Color("#FFB040", 1.0),
				"colour_b": Color("#F05A2A", 1.0), "radius": [0.07, 0.12], "tiles": green, "lift": [0.05, 0.3],
				"vel": Vector3(0, 0.5, 0), "period": [0.6, 1.0], "glow": 1.2})
		"echo":
			# Déjà vu: a ghostly copy of a crew stands somewhere else.
			var r := fx.site.rng(slot)
			var batch := LawFxBatch.new(LawFxBatch.Kind.SOLIDS)
			var at := fx.site.anywhere(r).lerp(a.lerp(b, 0.5), 0.3)
			for k in 3:
				var g := Geo.new()
				g.ball(Geo.place(Vector3(0, 0.3, 0), 0.0, Vector3(0.8, 1.0, 0.7)), 0.28, Color("#F0C8FF"), 4, 8)
				g.ball(Geo.place(Vector3(0, 0.7, 0)), 0.18, Color("#F0C8FF"), 4, 8)
				batch.geo(g, at + Vector3(k * 0.55 - 0.55, 0, (k % 2) * 0.4), r.randf())
			fx.layer(into, batch, fx.glass_material(Color("#E05CB4"), 7, 1.0, 0.08))


## A chord's turning triangle of light between the three crowns `pts`, and
## §8.5's effect of `id` over the realm.
static func chord(fx: LawFx, into: Node3D, id: String, pts: Array[Vector3]) -> void:
	var want: Array = LawFxLinks.CHORDS[id]
	# A sheet of light spans the three crowns, each corner in its note's colour.
	var sheet := LawFxBatch.new(LawFxBatch.Kind.SOLIDS)
	var sg := Geo.new()
	var cs: Array[Color] = []
	for k in 3:
		cs.append(LawFxLinks.note_colour(want[k]).lightened(0.35))
	var mid0 := (pts[0] + pts[1] + pts[2]) / 3.0
	for k in 3:
		var c := cs[k].lerp(cs[(k + 1) % 3], 0.5)
		sg.tri(mid0, pts[k], pts[(k + 1) % 3], c, Vector3.UP)
		sg.tri(mid0, pts[(k + 1) % 3], pts[k], c, Vector3.DOWN)
	sheet.solid(sg.mesh(), Transform3D.IDENTITY, mid0, 0.0)
	var sm := fx.glass_material(Color.WHITE, 0, 1.0, 0.16)
	sm.set_shader_parameter("rim", 0.0)
	fx.layer(into, sheet, sm)
	var mid := (pts[0] + pts[1] + pts[2]) / 3.0 + Vector3(0, 0.5, 0)
	var tri := LawFxBatch.new(LawFxBatch.Kind.SOLIDS)
	var g := Geo.new()
	for k in 3:
		var a0 := k * TAU / 3.0
		var a1 := (k + 1) * TAU / 3.0
		var c0 := Color(LawFxLinks.note_colour(want[k]).lightened(0.3), 0.15)
		g.tri(Vector3.ZERO, Vector3(cos(a0) * 0.7, 0, sin(a0) * 0.7), Vector3(cos(a1) * 0.7, 0, sin(a1) * 0.7), c0,
			Vector3.UP)
		g.tri(Vector3.ZERO, Vector3(cos(a1) * 0.7, 0, sin(a1) * 0.7), Vector3(cos(a0) * 0.7, 0, sin(a0) * 0.7), c0,
			Vector3.DOWN)
		g.box(Geo.place(Vector3(cos(a0) * 0.7, 0, sin(a0) * 0.7)), Vector3.ONE * 0.12, c0)
	tri.solid(g.mesh(), Transform3D(Basis(Vector3.RIGHT, 0.5), mid), mid, 0.0)
	var m := fx.solid_material(6, 0.4)
	m.set_shader_parameter("glow", 1.3)
	fx.layer(into, tri, m)
	var slot := "chord_" + id
	var h := fx.site.half()
	match id:
		"tempest":
			LawFxPaint.spray(fx, into, slot, {"n": 24, "shape": 3, "colour": Color("#DDEBFF", 0.8), "radius": [0.05, 0.08],
				"lift": [1.0, 3.0], "vel": Vector3(h.x * 1.6, -0.5, h.y * 0.5), "period": [0.9, 1.4]})
			var tint := fx.tint(Color("#1A1433"), 0.15)
			if tint != null:
				fx.every(func(s: float) -> void:
					var u := fmod(s, 20.0)
					tint.set_shader_parameter("flash", 0.7 * (1.0 - u) if u < 1.0 else 0.0))
		"deep_sleep":
			LawFxPaint.spray(fx, into, slot, {"n": 16, "shape": 4, "colour": Color("#E8E0FF", 0.9), "radius": [0.1, 0.14],
				"at": mid, "reach": 3.0, "lift": [-0.5, 0.5], "vel": Vector3(0, 0.25, 0), "period": [4.0, 6.0]})
		"ghost_tide":
			LawFxPaint.spray(fx, into, slot, {"n": 20, "shape": 11, "colour": Color("#BDF4FA", 0.7),
				"radius": [0.14, 0.2], "lift": [0.3, 1.0], "vel": Vector3(-1.0, 0, 0.6), "period": [5.0, 7.0]})
		"fair_lights":
			LawFxPaint.spray(fx, into, slot, {"n": 16, "shape": 0, "colour": Color("#FFF2B0", 0.95),
				"colour_b": Color("#F7A6DA", 0.95), "radius": [0.14, 0.22], "lift": [0.6, 1.6], "wobble": 0.4, "glow": 1.0})
		"iron_bell":
			var at: Array = []
			for p: Vector3 in pts:
				at.append(p - Vector3(0, LawFxLinks.LIFT + 0.25, 0))
			LawFxPaint.rounds(fx, into, at, 2.2, 4, Color("#C9C4D8"))
		"mirage":
			LawFxPaint.spray(fx, into, slot, {"n": 24, "shape": 3, "colour": Color("#FFE6F0", 0.5), "radius": [0.04, 0.06],
				"lift": [0.1, 0.6], "vel": Vector3(0, 0.35, 0), "period": [1.2, 2.0], "wobble": 0.08})
		"clockwork":
			LawFxPaint.rounds(fx, into, [mid - Vector3(0, mid.y - fx.site.heart.y, 0)], 1.5, 14, Color("#E8D8B0"),
				Color("#6A4A2A"), 3.0)
		"wild_hunt":
			LawFxPaint.spray(fx, into, slot, {"n": 20, "shape": 3, "colour": Color("#3A2B6B", 0.7), "radius": [0.05, 0.08],
				"lift": [0.2, 0.8], "vel": Vector3(h.x * 1.2, 0, -h.y * 0.6), "period": [1.0, 1.5]})
		"hidden_garden":
			LawFxPaint.spray(fx, into, slot, {"n": 24, "shape": 10, "colour": Color("#4EA84E", 0.95),
				"radius": [0.07, 0.1], "lift": [0.05, 0.4], "wobble": 0.15})
		"lantern_festival":
			var r := fx.site.rng(slot)
			var lanterns := LawFxBatch.new(LawFxBatch.Kind.SOLIDS)
			for k in 10:
				var lg := Geo.new()
				lg.box(Geo.place(Vector3.ZERO), Vector3(0.16, 0.22, 0.16), Color("#FFC24A", 0.3))
				lg.box(Geo.place(Vector3(0, 0.13, 0)), Vector3(0.18, 0.04, 0.18), Color("#B04A1E"))
				lanterns.geo(lg, fx.site.anywhere(r, 1.4 + r.randf()), r.randf())
			var lm := fx.solid_material(1, 0.3, 0.6)
			fx.layer(into, lanterns, lm, true)
		"quicksand":
			LawFxPaint.spray(fx, into, slot, {"n": 30, "shape": 0, "colour": Color("#D8B878", 0.7), "radius": [0.04, 0.07],
				"lift": [0.02, 0.2], "wobble": 0.25, "pace": 0.6})
		"rebound":
			LawFxPaint.spray(fx, into, slot, {"n": 20, "shape": 6, "colour": Color("#FFE6A8", 0.85), "radius": [0.08, 0.12],
				"lift": [0.1, 1.2], "vel": Vector3(0, 0.6, 0), "period": [0.8, 1.2], "wobble": 0.3})


## §7.5's paradoxes: Reversal ("Everyone walks with a slight upside-down
## sway; hair points at the sky"), Twin suns ("Every character casts two
## shadows"), Unmaking ("rules blink in and out").
static func paradox(fx: LawFx, into: Node3D, id: String) -> void:
	match id:
		"reversal":
			# Dust falls up, and the sky's violet creeps in from the edges.
			LawFxPaint.spray(fx, into, "reversal", {"n": 70, "shape": 1, "colour": Color("#8C6CF0", 0.95),
				"colour_b": Color("#8A6A4E", 0.95), "radius": [0.06, 0.1], "lift": [0.0, 0.3], "vel": Vector3(0, 0.6, 0),
				"spread": Vector3(0.05, 0.2, 0.05), "period": [4.0, 6.0]})
			fx.tint(Color("#6A4FC9"), 0.25)
		"twin_suns":
			# Two suns in the sky behind the island. A second light would wash
			# the toon ramp out, so the doubling is drawn, not lit.
			var h := fx.site.half()
			var b := LawFxBatch.new(LawFxBatch.Kind.MOTES)
			var side := Vector3(1, 0, -1).normalized()
			for k in 2:
				var at := Vector3(-h.x * 0.6, 6.0 + k * 0.6, -h.y * 0.6) + side * (k * 2 - 1) * 2.4
				b.mote(at, Vector3.ZERO, 0.0, k * 0.5, 1.3, 0.0, 0, Color("#FFE07A", 1.0))
				b.mote(at, Vector3.ZERO, 0.0, k * 0.5, 0.55, 0.0, 0, Color("#FFFFFF", 1.0))
			fx.layer(into, b, fx.mote_material(1.0))
		"unmaking":
			# Torn scraps flutter; every signature stutters now and then.
			LawFxPaint.spray(fx, into, "unmaking", {"n": 50, "shape": 5, "colour": Color("#FCFBFF", 1.0),
				"radius": [0.08, 0.12], "lift": [0.2, 2.0], "vel": Vector3(0.2, -0.15, 0.1), "period": [5.0, 8.0],
				"wobble": 0.3})
			fx.every(func(s: float) -> void:
				var u := fmod(s, 20.0)
				var on := not (u < 1.2 and int(s * 10.0) % 3 == 0)
				for sig: Node in fx.signatures.values():
					(sig as Node3D).visible = on)
