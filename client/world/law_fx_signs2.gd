class_name LawFxSigns2
extends RefCounted
## §21.7's world signatures for Energy, Life and Spirit, and the school's
## motes for a law not yet drawn (LawFxSigns has Motion, Matter and Time).

const INK := Color("#1A0C14")


static func build(fx: LawFx, sig: Node3D, law: String) -> void:
	match law:
		"glowing_dark":
			_glowing_dark(fx, sig)
		"aurora":
			_aurora(fx, sig)
		"chain_lightning":
			_chain_lightning(fx, sig)
		"static":
			_static(fx, sig)
		"bloom":
			_bloom(fx, sig)
		"kinship":
			_kinship(fx, sig)
		"thorns":
			_thorns(fx, sig)
		"regrowth":
			_regrowth(fx, sig)
		"whispers":
			_whispers(fx, sig)
		"echoes":
			_echoes(fx, sig)
		"sleepwalk":
			_sleepwalk(fx, sig)
		"soul_swap":
			_soul_swap(fx, sig)
		_:
			_school(fx, sig, law)


## Glowing dark: "A black realm lit by glowing mushrooms and runes." The
## realm's light falls to a glow and the screen's edges to black; glowing
## mushrooms crowd its plants and edges, rune rings pulse on the ground,
## fireflies drift. The sight overlay and the guards' marks keep their own
## light, so nothing a player must read goes dark.
static func _glowing_dark(fx: LawFx, sig: Node3D) -> void:
	var base := fx.light()
	if not base.is_empty():
		fx.sun.light_energy = float(base["sun"]) * 0.42
		fx.environment.ambient_light_energy = float(base["ambient"]) * 0.8
		fx.environment.ambient_light_color = Color("#3A3A8A")
	fx.tint(Color("#07041A"), 0.62, 0.06)
	var r := fx.site.rng("glowing_dark")
	var caps := LawFxBatch.new(LawFxBatch.Kind.SOLIDS)
	var spots := fx.site.tiles(LawFxSite.PLANTS + LawFxSite.WALLS)
	var edge: Array[Vector2i] = []
	for t: Vector2i in LawFxPaint.ground(fx.site):
		if t.x == 0 or t.y == 0 or t.x == fx.site.size.x - 1 or t.y == fx.site.size.y - 1:
			edge.append(t)
	spots.append_array(LawFxPaint.some(edge, 12))
	var hues: Array[Color] = [Color("#7AF0E0"), Color("#E07AF0"), Color("#9AE87A")]
	for t: Vector2i in LawFxPaint.some(spots, 22):
		for k in 2 + r.randi() % 2:
			var c := fx.site.centre(t) + Vector3(r.randf_range(-0.45, 0.45), 0, r.randf_range(-0.45, 0.45))
			var s := r.randf_range(0.7, 1.3)
			var g := Geo.new()
			g.prism(Geo.place(Vector3.ZERO), 5, 0.035 * s, 0.03 * s, 0.16 * s, Color("#E8E0D0"))
			g.ball(Geo.place(Vector3(0, 0.16 * s, 0), 0.0, Vector3(1, 0.55, 1)), 0.09 * s,
				Color(hues[(t.x + k) % hues.size()], 0.25), 3, 8)
			caps.geo(g, c, r.randf())
	fx.layer(sig, caps, fx.solid_material(4, 1.0), true)
	var runes: Array = []
	for t: Vector2i in LawFxPaint.some(LawFxPaint.ground(fx.site), 10):
		runes.append(fx.site.centre(t))
	LawFxPaint.rounds(fx, sig, runes, 0.5, 7, Color("#7AD8FF"))
	LawFxPaint.spray(fx, sig, "glowing_dark", {"n": 36, "shape": 0, "colour": Color("#D8FF7A", 0.95),
		"radius": [0.05, 0.09], "lift": [0.3, 1.8], "wobble": 0.4, "glow": 1.2})


## Aurora: "Ribbons of light sweep across the ground."
static func _aurora(fx: LawFx, sig: Node3D) -> void:
	var ground := fx.site.tiles(LawFxSite.GROUND + LawFxSite.PLANTS + LawFxSite.WATER)
	LawFxPaint.mark(fx, sig, ground, 5, Color("#5CF0B0"), Color("#C06CF0"))
	LawFxPaint.spray(fx, sig, "aurora", {"n": 30, "shape": 2, "colour": Color("#B8FFE0", 0.85),
		"colour_b": Color("#F0C0FF", 0.85), "radius": [0.05, 0.1], "lift": [0.1, 1.4], "vel": Vector3(0, 0.15, 0),
		"period": [4.0, 7.0], "glow": 0.8})


## Chain lightning: "Small arcs between metal props." Arcs jump, jagged and
## flickering, between each metal prop, ward and pylon and its nearest
## neighbour; sparks spit at each end.
static func _chain_lightning(fx: LawFx, sig: Node3D) -> void:
	var props: Array = []
	for t: Vector2i in fx.site.tiles(LawFxSite.METAL):
		props.append(fx.site.centre(t) + Vector3(0, 0.9, 0))
	for w: Vector3 in fx.site.wards:
		props.append(w + Vector3(0, 0.55, 0))
	for p: Dictionary in fx.site.pylons:
		props.append((p["at"] as Vector3) + Vector3(0, 1.3, 0))
	var arcs := LawFxBatch.new(LawFxBatch.Kind.THREADS)
	var done := {}
	for i in props.size():
		var best := -1
		var near := 7.0
		for j in props.size():
			var d := (props[i] as Vector3).distance_to(props[j])
			if j != i and d < near and not done.has(Vector2i(mini(i, j), maxi(i, j))):
				best = j
				near = d
		if best >= 0:
			done[Vector2i(mini(i, best), maxi(i, best))] = true
			arcs.strip(LawFxBatch.sagging(props[i], props[best], -0.35, 18), Color("#BFF4FF"), 1)
	if arcs.triangles > 0:
		fx.layer(sig, arcs, fx.thread_material(0.05))
	var sparks := LawFxBatch.new(LawFxBatch.Kind.MOTES)
	var r := fx.site.rng("chain_sparks")
	for p: Vector3 in props:
		for k in 4:
			sparks.mote(p, Vector3(r.randf_range(-0.4, 0.4), r.randf_range(0.1, 0.5), r.randf_range(-0.4, 0.4)), 0.6,
				r.randf(), 0.09, 0.0, 8, Color("#FFF6A0"))
	if sparks.triangles > 0:
		fx.layer(sig, sparks, fx.mote_material(1.0))


## Static: "Crackling motes over the ground." Little zigzags that blink on
## and off just over the ground, thin crackle lines that jump about it.
static func _static(fx: LawFx, sig: Node3D) -> void:
	var ground := LawFxPaint.ground(fx.site)
	LawFxPaint.mark(fx, sig, ground, 10, Color("#C8F4FF"))
	LawFxPaint.spray(fx, sig, "static", {"n": 70, "shape": 8, "colour": Color("#FFF0A0", 1.0),
		"colour_b": Color("#A8ECFF", 1.0), "radius": [0.06, 0.1], "tiles": ground, "lift": [0.05, 0.45],
		"glow": 1.0, "pace": 3.0})


## Bloom: "Hedges sprout back in time-lapse." On every hedge, leafy sprouts
## shoot up, flower and are cut back, over and over; petals drift. With no
## hedge, the sprouts ring the pylon.
static func _bloom(fx: LawFx, sig: Node3D) -> void:
	var r := fx.site.rng("bloom")
	var hedges := fx.site.tiles(LawFxSite.HEDGES)
	var spots: Array = []
	for t: Vector2i in hedges:
		spots.append(fx.site.centre(t) + Vector3(0, 0.75 if fx.site.code(t) == RealmKit.F.HEDGE else 0.3, 0))
	if spots.is_empty():
		var p := LawFxPaint.home(fx, "bloom")
		for k in 8:
			spots.append(p + Vector3(cos(k * TAU / 8.0) * 1.3, 0, sin(k * TAU / 8.0) * 1.3))
	var sprouts := LawFxBatch.new(LawFxBatch.Kind.SOLIDS)
	var petals: Array[Color] = [Color("#F7A6DA"), Color("#FFF2A0"), Color("#FFFFFF")]
	for c: Vector3 in spots:
		for k in 2:
			var at := c + Vector3(r.randf_range(-0.3, 0.3), 0, r.randf_range(-0.3, 0.3))
			var g := Geo.new()
			# A burst of pointed leaves, a stalk, and a five-petal flower.
			for blade in 5:
				var a := blade * TAU / 5.0 + r.randf() * 0.4
				var out := Vector3(cos(a), 0, sin(a))
				var lean := Basis(out.cross(Vector3.UP).normalized(), -0.55)
				g.prism(Transform3D(lean.scaled(Vector3(1.0, 1.0, 0.35)), out * 0.04), 4, 0.09, 0.0,
					r.randf_range(0.32, 0.46), Color("#4FB45A").darkened(r.randf() * 0.15))
			g.prism(Geo.place(Vector3.ZERO), 4, 0.03, 0.025, 0.5, Color("#3E8A44"))
			var bloom_col: Color = petals[r.randi() % petals.size()]
			for petal in 5:
				var a := petal * TAU / 5.0
				g.ball(Geo.place(Vector3(cos(a) * 0.09, 0.54, sin(a) * 0.09), a, Vector3(1.0, 0.45, 0.7)), 0.08,
					Color(bloom_col, 0.85), 3, 6)
			g.ball(Geo.place(Vector3(0, 0.56, 0)), 0.05, Color("#F6C453", 0.6), 2, 6)
			sprouts.geo(g, at, r.randf() * 0.3 + float(k) * 0.12)
	fx.layer(sig, sprouts, fx.solid_material(2, 1.0), true)
	LawFxPaint.spray(fx, sig, "bloom", {"n": 34, "shape": 5, "colour": Color("#F7A6DA", 0.95),
		"colour_b": Color("#FFF2A0", 0.95), "radius": [0.06, 0.09], "lift": [0.3, 1.8], "vel": Vector3(0.12, -0.08, 0.05),
		"period": [6.0, 9.0], "wobble": 0.25})


## Kinship: "Vines braid between neighbours." Twined vines run between
## neighbouring plants and walls; the crew, linked by a green thread.
static func _kinship(fx: LawFx, sig: Node3D) -> void:
	var r := fx.site.rng("kinship")
	var anchors := fx.site.tiles(LawFxSite.PLANTS + LawFxSite.WALLS)
	var vines := LawFxBatch.new(LawFxBatch.Kind.THREADS)
	var seen := {}
	for t: Vector2i in anchors:
		for n: Vector2i in [Vector2i(1, 0), Vector2i(0, 1), Vector2i(2, 0), Vector2i(0, 2), Vector2i(1, 1)]:
			var o := t + n
			if not anchors.has(o) or seen.has([t, o]) or r.randf() < 0.35:
				continue
			seen[[t, o]] = true
			var a := fx.site.centre(t) + Vector3(0, 0.45, 0)
			var b := fx.site.centre(o) + Vector3(0, 0.45, 0)
			for strand in 2:
				var pts := LawFxBatch.sagging(a, b, 0.2, 14)
				var side := (b - a).cross(Vector3.UP).normalized()
				for k in pts.size():
					var u := float(k) / (pts.size() - 1)
					pts[k] += side * sin(u * TAU * 2.0 + strand * PI) * 0.06
				vines.strip(pts, Color("#3E9B4A") if strand == 0 else Color("#7AD86A"), 0)
	if vines.triangles > 0:
		fx.layer(sig, vines, fx.thread_material(0.03))
	LawFxPaint.spray(fx, sig, "kinship", {"n": 26, "shape": 10, "colour": Color("#7AD86A", 1.0), "radius": [0.06, 0.08],
		"tiles": anchors, "lift": [0.4, 0.7], "wobble": 0.05})
	# The crew, shoulder to shoulder, each to the next by a green thread.
	var link := MeshInstance3D.new()
	link.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	link.material_override = fx.thread_material(0.035)
	link.extra_cull_margin = 40.0
	sig.add_child(link)
	fx.watch(func(crew: Array, _guards: Array) -> void:
		var b := LawFxBatch.new(LawFxBatch.Kind.THREADS)
		for k in crew.size() - 1:
			var a: Vector3 = crew[k]
			var c: Vector3 = crew[k + 1]
			if a.distance_to(c) < 4.5:
				b.strip(LawFxBatch.sagging(a + Vector3(0, 0.55, 0), c + Vector3(0, 0.55, 0), 0.15, 10),
					Color("#7AF08A"), 0)
		link.mesh = b.mesh())


## Thorns: "Thorny vines cover walls and hedges." Each wall and hedge wound
## with a dark vine and bristling with pale thorns, swaying a little.
static func _thorns(fx: LawFx, sig: Node3D) -> void:
	var r := fx.site.rng("thorns")
	var batch := LawFxBatch.new(LawFxBatch.Kind.SOLIDS)
	for t: Vector2i in fx.site.tiles(LawFxSite.WALLS + LawFxSite.HEDGES):
		var h := LawFxSigns.wall_height(fx.site.code(t))
		if LawFxSite.HEDGES.has(fx.site.code(t)) and fx.site.code(t) != RealmKit.F.HEDGE:
			h = 0.55
		var g := Geo.new()
		for ring in 2:
			var y := h * (0.35 + ring * 0.4)
			g.prism(Geo.place(Vector3(0, y, 0), ring * 0.4), 8, 0.56, 0.56, 0.07, Color("#2F6A35"))
		for k in 10:
			var a := r.randf() * TAU
			var y := r.randf_range(0.15, h)
			var out := Vector3(cos(a), 0, sin(a))
			var base := out * 0.54 + Vector3(0, y, 0)
			var b := Basis(out.cross(Vector3.UP).normalized(), -PI / 2.0) if out.cross(Vector3.UP).length() > 0.01 \
				else Basis.IDENTITY
			g.prism(Transform3D(b, base), 3, 0.045, 0.0, 0.2, Color("#EBDDB8") if k % 3 else Color("#C0392B"))
		batch.geo(g, fx.site.centre(t), r.randf())
	if batch.triangles > 0:
		fx.layer(sig, batch, fx.solid_material(5, 0.03), true)
	LawFxPaint.spray(fx, sig, "thorns", {"n": 14, "shape": 10, "colour": Color("#4E8A3E", 0.9), "radius": [0.06, 0.08],
		"tiles": fx.site.tiles(LawFxSite.WALLS + LawFxSite.HEDGES), "lift": [0.3, 1.0], "vel": Vector3(0, -0.12, 0),
		"period": [4.0, 6.0], "wobble": 0.2})


## Regrowth: "Moss creeps over everything." Moss spreads out over the ground
## and back, lumps of it swell on every wall, green motes of healing rise.
static func _regrowth(fx: LawFx, sig: Node3D) -> void:
	LawFxPaint.mark(fx, sig, LawFxPaint.ground(fx.site), 6, Color("#7CC456"), Color("#3E7A34"))
	var r := fx.site.rng("regrowth")
	var moss := LawFxBatch.new(LawFxBatch.Kind.SOLIDS)
	for t: Vector2i in fx.site.tiles(LawFxSite.WALLS):
		var h := LawFxSigns.wall_height(fx.site.code(t))
		for k in 3:
			var g := Geo.new()
			g.ball(Geo.place(Vector3.ZERO, 0.0, Vector3(1.3, 0.6, 1.1)), r.randf_range(0.12, 0.2), Color("#6CB84E"), 3, 7)
			var at := fx.site.centre(t) + Vector3(r.randf_range(-0.38, 0.38), h * r.randf_range(0.5, 1.0),
				r.randf_range(-0.38, 0.38))
			moss.geo(g, at, r.randf())
	if moss.triangles > 0:
		var m := fx.solid_material(2, 1.0, 0.35)
		fx.layer(sig, moss, m, true)
	LawFxPaint.spray(fx, sig, "regrowth", {"n": 30, "shape": 2, "colour": Color("#B8FFA8", 0.9), "radius": [0.05, 0.09],
		"lift": [0.1, 0.6], "vel": Vector3(0, 0.25, 0), "period": [3.0, 5.0], "glow": 0.7})


## Whispers: "Whispering wind lines drift between guards." Wisps carry from
## each guard's post to the next, in the realm's quiet magenta.
static func _whispers(fx: LawFx, sig: Node3D) -> void:
	var posts: Array = fx.site.posts.duplicate()
	if posts.size() < 2:
		var p := LawFxPaint.home(fx, "whispers")
		posts = [p + Vector3(-2, 0, -1), p + Vector3(2, 0, 1), p + Vector3(0, 0, 2.5)]
	var r := fx.site.rng("whispers")
	var b := LawFxBatch.new(LawFxBatch.Kind.MOTES)
	for i in posts.size():
		var a: Vector3 = posts[i]
		var c: Vector3 = posts[(i + 1) % posts.size()]
		var period := maxf(3.0, a.distance_to(c) / 1.2)
		for k in 9:
			var lift := Vector3(r.randf_range(-0.2, 0.2), 1.1 + r.randf_range(-0.25, 0.35), r.randf_range(-0.2, 0.2))
			b.mote(a + lift, (c - a) / period, period, float(k) / 9.0 + r.randf() * 0.05, r.randf_range(0.14, 0.22),
				0.12, 11, Color("#F6C8F0", 0.85))
	fx.layer(sig, b, fx.mote_material(0.6))
	LawFxPaint.spray(fx, sig, "whispers_lines", {"n": 18, "shape": 3, "colour": Color("#FFE6FA", 0.6),
		"radius": [0.04, 0.06], "lift": [0.8, 2.0], "vel": Vector3(0.8, 0, -0.4), "spread": Vector3(0.4, 0, 0.4),
		"period": [3.0, 5.0], "wobble": 0.2})


## Echoes: "Soft chimes; faint silhouettes." Clear figures stand about the
## realm, rising and settling, a chime ring blooming round each.
static func _echoes(fx: LawFx, sig: Node3D) -> void:
	var r := fx.site.rng("echoes")
	var ghosts := LawFxBatch.new(LawFxBatch.Kind.SOLIDS)
	var feet: Array = []
	for t: Vector2i in LawFxPaint.some(LawFxPaint.ground(fx.site), 7):
		var c := fx.site.centre(t) + Vector3(r.randf_range(-0.2, 0.2), 0, r.randf_range(-0.2, 0.2))
		var g := Geo.new()
		g.ball(Geo.place(Vector3(0, 0.36, 0), 0.0, Vector3(0.75, 1.0, 0.65)), 0.32, Color("#DDF4FF"), 4, 9)
		g.ball(Geo.place(Vector3(0, 0.82, 0)), 0.2, Color("#DDF4FF"), 4, 9)
		for side: float in [-1.0, 1.0]:
			g.ball(Geo.place(Vector3(side * 0.12, 1.0, 0), 0.0, Vector3(0.5, 1.0, 0.5)), 0.07, Color("#DDF4FF"), 2, 6)
		ghosts.geo(g, c, r.randf(), r.randf() * TAU)
		feet.append(c)
	fx.layer(sig, ghosts, fx.glass_material(Color("#8FD8FF"), 7, 1.0, 0.1))
	LawFxPaint.rounds(fx, sig, feet, 0.8, 12, Color("#8FD8FF"))
	LawFxPaint.rounds(fx, sig, feet, 1.1, 4, Color("#CDEBFF"), INK, 0.6)


## Sleepwalk: "Dreamy haze with drifting Z-shaped motes."
static func _sleepwalk(fx: LawFx, sig: Node3D) -> void:
	LawFxPaint.mark(fx, sig, fx.site.tiles(LawFxSite.GROUND + LawFxSite.PLANTS + LawFxSite.WATER), 9,
		Color("#D8C8FF"), Color("#F7C6E8"))
	LawFxPaint.spray(fx, sig, "sleepwalk", {"n": 28, "shape": 4, "colour": Color("#F3EEFF", 0.95),
		"radius": [0.1, 0.16], "lift": [0.4, 1.4], "vel": Vector3(0.05, 0.22, 0), "period": [5.0, 8.0], "wobble": 0.15,
		"glow": 0.3})
	fx.tint(Color("#6A4FC9"), 0.32)


## Soul swap: "Wisps orbit every character." Three magenta wisps circle
## each character the simulation draws, moved with it each tick.
static func _soul_swap(fx: LawFx, sig: Node3D) -> void:
	var b := LawFxBatch.new(LawFxBatch.Kind.SOLIDS)
	for k in 3:
		var g := Geo.new()
		g.ball(Geo.place(Vector3.ZERO, 0.0, Vector3(1.4, 1, 1)), 0.07, Color("#F07AD0", 0.2), 3, 6)
		g.ball(Geo.place(Vector3(-0.09, 0, 0)), 0.045, Color("#F7A6DA", 0.3), 2, 5)
		var a := k * TAU / 3.0
		var at := Vector3(cos(a) * 0.5, 0.5 + k * 0.15, sin(a) * 0.5)
		b.solid(g.mesh(), Geo.place(at, -a), Vector3.ZERO, float(k) / 3.0)
	fx.follow(sig, b, fx.solid_material(6, 1.8), "all")
	LawFxPaint.spray(fx, sig, "soul_swap", {"n": 20, "shape": 11, "colour": Color("#F07AD0", 0.7),
		"radius": [0.12, 0.18], "lift": [0.4, 1.6], "wobble": 0.3, "glow": 0.6})


## A law not yet drawn: its school's motes rise round its pylon over a pool
## of its colour, so the realm still shows a law is woven there.
static func _school(fx: LawFx, sig: Node3D, law: String) -> void:
	var p := LawFxPaint.home(fx, law)
	var col: Color = LawFxCrown.colours(LawFxLinks.school(law))[0]
	LawFxPaint.rounds(fx, sig, [p], 1.8, 8, col)
	LawFxPaint.spray(fx, sig, law, {"n": 24, "shape": 2, "colour": Color(col.lightened(0.3), 0.9),
		"radius": [0.06, 0.1], "at": p, "reach": 1.6, "lift": [0.1, 0.6], "vel": Vector3(0, 0.35, 0),
		"period": [3.0, 5.0], "glow": 0.6})
