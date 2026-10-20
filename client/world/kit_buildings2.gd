class_name KitBuildings2
extends RefCounted
## BuildingKit's other kinds, those that are not houses — the Spire's
## citadel, the Vault, the Anchor Stone, the Aether Spring, the Nursery, the
## Resonance Lab, the Observatory, the Beacon, the Visitor's Dock, the Law
## Pylon and the Ward — each by §21.5's silhouette, and every kind's §21.5
## crown at level 10. Drawn through BuildingKit's parts, in its units.


static func build(b: BuildingKit, kind: String) -> void:
	match kind:
		"keeper_s_spire":
			_citadel(b)
		"vault":
			_vault(b)
		"anchor_stone":
			_anchor(b)
		"aether_spring":
			_spring(b)
		"nursery":
			_nursery(b)
		"resonance_lab":
			_lab(b)
		"observatory":
			_observatory(b)
		"beacon":
			_beacon(b)
		"visitor_s_dock":
			_dock(b)
		"law_pylon":
			_pylon(b)
		"ward":
			_ward(b)
		_:
			b._hearth()


## The Keeper's Spire as the Heart's citadel (the design's `castle` and
## `spire`, :638–664, :826–846): a terrace, a curtain wall with four towers
## at the footprint's corners and a gate, and the Spire at the middle,
## "a tall tower wrapped in rings" that turn. In units of a third of the
## footprint, so the 3 × 3 citadel stands about six metres.
static func _citadel(b: BuildingKit) -> void:
	var u := b.unit
	b.unit = u / 3.0 * 1.55
	var acc: Color = b.style["accent"]
	var roof := b.roof_col if b.tier > 0 else Color(b.style["roof"])
	b.cyl(0.95, 1.0, 0.16, b.stone2, 0, 0, 0, 8)
	b.cyl(0.8, 0.86, 0.14, b.stone, 0, 0.16, 0, 8)
	# The curtain wall round the terrace, crenellated, with its gate south.
	var s := 0.86
	for side in 4:
		var yaw := PI / 2.0 * side
		var dir := Vector3(sin(yaw), 0, cos(yaw))
		for k in 5:
			var off := -0.68 + 0.34 * k
			if side == 0 and k == 2:
				continue
			var p := dir * s + dir.cross(Vector3.UP) * off
			b.box(0.36, 0.34, 0.1, b.stone, p.x, 0.3 + 0.17, p.z, yaw)
			b.box(0.1, 0.08, 0.11, b.stone2, p.x + dir.cross(Vector3.UP).x * 0.1, 0.68, p.z + dir.cross(Vector3.UP).z * 0.1,
				yaw)
	# The gatehouse.
	b.box(0.42, 0.5, 0.18, b.stone, 0, 0.55, s)
	b.g.gable(b.place(0, 0.8, s), 0.5 * b.unit, 0.16 * b.unit, 0.22 * b.unit, roof)
	b.door(0, 0.3, s + 0.09, 0, 1.3)
	for x: float in [-0.16, 0.16]:
		b.ball(0.035, KitStyle.lit(Color("#FFD27A"), 0.7), x, 0.62, s + 0.1, 1.0, 2, 5)
	# Four towers at the corners.
	for p: Vector2 in [Vector2(-s, -s), Vector2(s, -s), Vector2(-s, s), Vector2(s, s)]:
		var th := 1.1 if p.y < 0 else 0.95
		b.cyl(0.2, 0.2, th, b.stone, p.x, 0.3, p.y, 10)
		b.cyl(0.21, 0.21, 0.03, b.stone2, p.x, 0.3 + th * 0.5, p.y, 10)
		b.cyl(0.25, 0.22, 0.08, b.stone2, p.x, 0.3 + th, p.y, 10)
		b.cone(0.26, 0.5, roof, p.x, 0.38 + th, p.y, 10)
		b.cone(0.02, 0.15, KitStyle.GOLD, p.x, 0.88 + th, p.y, 6)
		b.window(p.x + 0.0, 0.3 + th * 0.65, p.y + 0.2, 0, 0.7, false)
	# The Spire.
	b.cyl(0.62, 0.7, 0.6, b.stone, 0, 0.3, 0, 8)
	for i in 4:
		var q := i * PI / 2.0 + PI / 8.0
		b.box(0.14, 0.7, 0.3, b.stone2, cos(q) * 0.66, 0.6, sin(q) * 0.66, -q)
	b.cyl(0.66, 0.66, 0.06, acc, 0, 0.9, 0, 8)
	var body := Color("#F4EEF8") if b.tier > 0 else b.stone.lightened(0.1)
	b.cyl(0.36, 0.3, 1.4, body, 0, 0.96, 0, 8)
	for i in 4:
		var q := i * PI / 2.0
		b.box(0.02, 0.34, 0.08, KitStyle.lit(Color("#FFE7F4"), 0.5), cos(q) * 0.33, 1.6, sin(q) * 0.33, -q)
	b.cyl(0.52, 0.44, 0.08, roof, 0, 2.36, 0, 8)
	b.cyl(0.3, 0.26, 0.5, body, 0, 2.44, 0, 8)
	for i in 4:
		var q := i * PI / 2.0 + PI / 4.0
		b.cone(0.05, 0.24, KitStyle.GOLD, cos(q) * 0.33, 2.84, sin(q) * 0.33, 4)
	b.cone(0.42, 1.0, roof, 0, 2.94, 0, 8)
	b.cone(0.04, 0.3, KitStyle.GOLD, 0, 3.92, 0, 6)
	# The rings wrapped round it, turning, and the orb above.
	var mid := b.at(0, 1.7, 0)
	b.move(Geo.Anim.SPIN_Y, mid)
	b.d.torus(Transform3D(Basis(Vector3.RIGHT, 0.25), mid), 0.52 * b.unit, 0.02 * b.unit, KitStyle.GOLD, 24, 4)
	b.d.torus(Transform3D(Basis(Vector3.BACK, -0.3), b.at(0, 1.3, 0)), 0.58 * b.unit, 0.018 * b.unit,
		KitStyle.lit(acc.lightened(0.3), 0.5), 24, 4)
	b.stop()
	var orb := b.at(0, 4.35, 0)
	b.move(Geo.Anim.BOB, orb)
	b.ball(0.16, KitStyle.lit(acc.lightened(0.4), 0.3), 0, 4.35, 0, 1.0, 4, 10)
	b.move(Geo.Anim.SPIN_Y, orb)
	b.d.torus(Transform3D(Basis(Vector3.RIGHT, 1.1), orb), 0.28 * b.unit, 0.014 * b.unit, KitStyle.GOLD, 20, 4)
	b.stop()
	# Pages fluttering round it, from the second look.
	if b.tier >= 1:
		b.move(Geo.Anim.SPIN_Y, b.at(0, 2.0, 0))
		for k in 5:
			var a := TAU * k / 5.0
			b.d.box(Geo.place(b.at(cos(a) * 0.7, 1.6 + 0.25 * k, sin(a) * 0.7), a), Vector3(0.09, 0.006, 0.07) * b.unit,
				Color("#FFF8E6"))
		b.stop()
	b.top = 4.0
	b.unit = u


## The Vault: "a round domed strongbox" of iron, brass and star rivets.
static func _vault(b: BuildingKit) -> void:
	b.unit *= 0.85
	b.box(1.02, 0.1, 0.86, b.stone2, 0, 0.05, 0)
	b.box(0.9, 0.5, 0.74, b.stone, 0, 0.35, 0)
	b.courses(0.9, 0.74, 0.1, 0.6, 3)
	for x: float in [-0.45, 0.45]:
		for z: float in [-0.37, 0.37]:
			b.box(0.13, 0.5, 0.13, b.stone2, x, 0.35, z)
	b.box(0.96, 0.05, 0.8, KitStyle.GOLD, 0, 0.62, 0)
	b.g.ball(Geo.place(b.at(0, 0.62, 0), 0.0, Vector3(1, 0.8, 0.88)), 0.42 * b.unit, Color("#D9A441"), 5, 12, true)
	for k in 8:
		var a := TAU * k / 8.0
		b.ball(0.025, KitStyle.lit(Color("#FFF1C4"), 0.6), cos(a) * 0.4, 0.66, sin(a) * 0.35, 1.0, 2, 4)
	b.ball(0.05, KitStyle.GOLD, 0, 0.98, 0, 1.0, 3, 6)
	b.door(0, 0.1, 0.375, 0, 1.3)
	b.g.cyl(Transform3D(Basis(Vector3.RIGHT, PI / 2.0), b.at(0, 0.38, 0.38)), 0.12 * b.unit, 0.12 * b.unit,
		0.03 * b.unit, KitStyle.lit(KitStyle.GOLD, 0.35), 14)
	b.top = 1.05
	b.unit /= 0.85


## The Anchor Stone: "a standing stone chained to the island's underside",
## grey stone and a school rune; the chains tighten when strain rises. A
## carved menhir on a paving of runes, chains running down from its iron
## collar to rings set in anchor blocks.
static func _anchor(b: BuildingKit) -> void:
	var rune: Color = b.style["accent"]
	var grey := Color("#9C98A8") if b.tier < 2 else Color("#E6E0FF")
	b.cyl(0.52, 0.54, 0.05, b.stone2, 0, 0, 0, 12)
	b.cyl(0.4, 0.4, 0.006, Color("#3A3350"), 0, 0.05, 0, 12)
	for i in 12:
		var q := TAU * i / 12.0
		b.fine(0.06, 0.008, 0.02, KitStyle.lit(rune, 0.5), cos(q) * 0.34, 0.056, sin(q) * 0.34, -q)
	b.g.prism(b.place(0, 0.05, 0, 0.3), 6, 0.22 * b.unit, 0.13 * b.unit, 1.1 * b.unit, grey, false, grey.lightened(0.1))
	b.g.prism(b.place(0, 1.15, 0, 0.3), 6, 0.13 * b.unit, 0.04 * b.unit, 0.16 * b.unit, grey.lightened(0.08))
	# The carved band and its glowing rune.
	b.cyl(0.2, 0.2, 0.05, b.stone2 if b.tier == 0 else KitStyle.GOLD, 0, 0.72, 0, 6)
	b.d.gem(Transform3D(Basis(Vector3.RIGHT, PI / 2.0), b.at(0, 0.5, 0.19)), 0.07 * b.unit, 0.015 * b.unit,
		KitStyle.lit(rune.lightened(0.2), 0.3), 4)
	if b.tier == 2:
		for k in 3:
			b.d.gem(Geo.place(b.at(0.08 * (k - 1), 0.3 + 0.25 * k, 0.17)), 0.025 * b.unit, 0.06 * b.unit,
				KitStyle.lit(Color("#C8B8FF"), 0.5), 4)
	b.torus_at(0.17, 0.03, KitStyle.IRON, 0, 0.42, 0)
	for k in 4:
		var a := TAU * k / 4.0 + PI / 4.0
		var top := Vector3(cos(a) * 0.17, 0.42, sin(a) * 0.17)
		var foot := Vector3(cos(a) * 0.5, 0.08, sin(a) * 0.5)
		for m in 6:
			var p := top.lerp(foot, (m + 0.5) / 6.0)
			p.y -= sin((m + 0.5) / 6.0 * PI) * 0.04
			var yaw := -a + (PI / 2.0 if m % 2 == 0 else 0.0)
			b.d.torus(Transform3D(Basis(Vector3.UP, yaw) * Basis(Vector3.RIGHT, PI / 2.0), b.at(p.x, p.y, p.z)),
				0.028 * b.unit, 0.009 * b.unit, KitStyle.IRON, 8, 3)
		b.box(0.12, 0.08, 0.12, b.stone2.darkened(0.1), foot.x, 0.04, foot.z, -a)
		b.torus_at(0.035, 0.01, KitStyle.IRON, foot.x, 0.09, foot.z)
	b.top = 1.3


## The Aether Spring: "a tiered fountain of glowing ink", teal stone and
## cyan ink; bubbling, ink ribbons rise. An eight-sided basin with scalloped
## rims, three tiers, ink falling from each, the spout's orb breathing and
## ribbons of ink turning up out of it.
static func _spring(b: BuildingKit) -> void:
	var teal := Color("#4E8E94").lerp(b.stone, 0.15)
	var rim := teal.lightened(0.15) if b.tier < 2 else KitStyle.GOLD
	var ink := KitStyle.lit(Color("#5FE6F0"), 0.6)
	var fall := Color(Color("#9BF4FA"), 0.5)
	b.g.prism(b.place(0, 0, 0, PI / 8.0), 8, 0.52 * b.unit, 0.5 * b.unit, 0.18 * b.unit, teal.darkened(0.1), false,
		teal)
	b.g.cyl(b.place(0, 0.18, 0), 0.45 * b.unit, 0.45 * b.unit, 0.008 * b.unit, ink, 12)
	for k in 16:
		var a := TAU * k / 16.0
		b.ball(0.035, rim, cos(a) * 0.5, 0.19, sin(a) * 0.5, 0.7, 2, 5)
	var tiers := [[0.32, 0.5], [0.2, 0.78]]
	b.cyl(0.08, 0.1, 0.62, teal, 0, 0.18, 0, 8)
	for tr: Array in tiers:
		var r: float = tr[0]
		var y: float = tr[1]
		b.cyl(r * 0.6, r, 0.08, teal, 0, y - 0.08, 0, 10)
		b.g.cyl(b.place(0, y, 0), r * 0.92 * b.unit, r * 0.92 * b.unit, 0.006 * b.unit, ink, 10)
		for k in 10:
			var a := TAU * k / 10.0
			b.ball(0.025, rim, cos(a) * r, y + 0.005, sin(a) * r, 0.7, 2, 4)
		# Ink falling from the tier's lip to the one below.
		for k in 4:
			var a := TAU * k / 4.0 + PI / 4.0
			b.glass.box(b.place(cos(a) * r, y - 0.14, sin(a) * r, -a), Vector3(0.05, 0.26, 0.008) * b.unit, fall)
	b.cyl(0.05, 0.03, 0.2, teal.lightened(0.1), 0, 0.78, 0, 8)
	b.move(Geo.Anim.BOB, b.at(0, 1.04, 0))
	b.ball(0.07, ink, 0, 1.04, 0, 1.2, 3, 8)
	b.stop()
	b.move(Geo.Anim.SPIN_Y, b.at(0, 1.1, 0))
	for k in 3:
		var a := TAU * k / 3.0
		for m in 5:
			var t := m / 5.0
			b.ball(0.026 - 0.003 * m, ink, cos(a + t * 2.4) * (0.1 + 0.06 * m), 1.1 + 0.11 * m, sin(a + t * 2.4) * 0.12,
				1.0, 2, 4)
	b.stop()
	if b.tier >= 1:
		for k in 4:
			var a := TAU * k / 4.0 + PI / 4.0
			b.cyl(0.04, 0.035, 0.32, b.stone, cos(a) * 0.62, 0, sin(a) * 0.62, 6)
			b.ball(0.04, KitStyle.lit(Color("#9BEAF3"), 0.4), cos(a) * 0.62, 0.36, sin(a) * 0.62, 1.0, 2, 5)
	b.top = 1.3


## The Nursery: "an egg-shaped greenhouse with nests", glass and wicker;
## the eggs wobble in the colours of what will hatch.
static func _nursery(b: BuildingKit) -> void:
	b.plinth(0.96, 0.96, 0.08)
	var pane := Color("#E2F6F0")
	var rib := KitStyle.WOOD if b.tier == 0 else (Color("#F6F2E8") if b.tier == 1 else KitStyle.GOLD)
	b.cyl(0.42, 0.42, 0.12, Color("#C49A5A"), 0, 0.08, 0, 12)
	b.glass.ball(Geo.place(b.at(0, 0.2, 0), 0.0, Vector3(1, 1.35, 1)), 0.4 * b.unit, pane, 5, 12, true)
	for k in 6:
		var a := TAU * k / 6.0
		b.d.torus(Transform3D(Basis(Vector3.UP, a) * Basis(Vector3.RIGHT, PI / 2.0), b.at(0, 0.2, 0)) \
			* Transform3D(Basis().scaled(Vector3(1, 1.35, 1)), Vector3.ZERO), 0.4 * b.unit, 0.012 * b.unit, rib, 16, 3)
	b.door(0, 0.08, 0.4, 0, 0.9)
	var eggs: Array[Color] = [Color("#F7A6DA"), Color("#9BEAF3"), Color("#FFE08F")]
	for k in 3:
		var a := TAU * k / 3.0 + 0.6
		var p := Vector3(cos(a) * 0.2, 0.2, sin(a) * 0.2)
		b.d.torus(Geo.place(b.at(p.x, p.y + 0.02, p.z)), 0.07 * b.unit, 0.025 * b.unit, Color("#A8804A"), 10, 4)
		b.move(Geo.Anim.SWING, b.at(p.x, p.y, p.z))
		b.ball(0.05, eggs[k], p.x, p.y + 0.06, p.z, 1.3, 3, 7)
		b.stop()
	b.ball(0.05, rib, 0, 0.75, 0, 1.0, 3, 6)
	b.top = 0.8


## The Resonance Lab: "a workshop with two glass spheres", brass and glass,
## sparks and threads between them.
static func _lab(b: BuildingKit) -> void:
	b.plinth(1.0, 0.8)
	b.box(0.7, 0.42, 0.56, b.stone if b.tier == 0 else b.wall, -0.1, 0.29, -0.06)
	b.frame(0.7, 0.42, 0.56, 0.08)
	var y := b.roof(0.7, 0.56, 0.5, 0.26, 0.07)
	b.door(-0.1, 0.08, 0.22, 0, 0.9)
	b.window(-0.36, 0.3, 0.22, 0, 0.8)
	b.window(0.255, 0.3, -0.06, PI / 2.0, 0.8, false)
	b.chimney(-0.3, y - 0.15, -0.2, 0.3)
	var brass := Color("#D4A04A")
	var spheres := [Vector3(0.36, 0, 0.2), Vector3(0.36, 0, -0.26)]
	if b.level >= 10:
		spheres.append(Vector3(0.1, 0, 0.38))
	for s: Vector3 in spheres:
		b.cyl(0.06, 0.08, 0.3, brass, s.x, 0.08, s.z, 8)
		b.glass.ball(Geo.place(b.at(s.x, 0.5, s.z)), 0.12 * b.unit, Color(Color("#DDF4FF"), 0.6), 4, 10)
		b.ball(0.04, KitStyle.lit(Palette.MOTION.lightened(0.3), 0.3), s.x, 0.5, s.z, 1.0, 2, 6)
		b.move(Geo.Anim.SPIN_Y, b.at(s.x, 0.5, s.z))
		b.d.torus(Transform3D(Basis(Vector3.RIGHT, 0.5), b.at(s.x, 0.5, s.z)), 0.15 * b.unit, 0.01 * b.unit, brass, 16, 3)
		b.stop()
	# A thread of light between the spheres.
	var a := b.at(0.36, 0.5, 0.2)
	var c := b.at(0.36, 0.5, -0.26)
	b.move(Geo.Anim.BOB, (a + c) / 2.0)
	b.d.box(Geo.place((a + c) / 2.0), Vector3(0.015 * b.unit, 0.015 * b.unit, a.distance_to(c)),
		KitStyle.lit(Palette.MOTION.lightened(0.3), 0.2))
	b.stop()
	b.top = y + 0.1


## The Observatory: "a domed telescope", copper and slate; the dome turns.
static func _observatory(b: BuildingKit) -> void:
	b.plinth(0.96, 0.96)
	b.cyl(0.42, 0.42, 0.5, b.stone, 0, 0.08, 0, 12)
	b.cyl(0.44, 0.44, 0.04, b.stone2, 0, 0.58, 0, 12)
	for k in 4:
		var a := TAU * k / 4.0 + 0.4
		b.window(cos(a) * 0.42, 0.34, sin(a) * 0.42, PI / 2.0 - a, 0.8, false)
	b.door(0, 0.08, 0.42, 0, 0.9)
	var slate := Color("#5E6A7A") if b.tier < 2 else Color("#B9A6F2")
	var copper := Color("#C87A4A") if b.tier < 2 else KitStyle.GOLD
	var hub := b.at(0, 0.62, 0)
	b.move(Geo.Anim.SPIN_Y, hub)
	b.g.ball(Geo.place(hub), 0.4 * b.unit, slate, 5, 12, true)
	b.d.box(Transform3D(Basis(Vector3.RIGHT, -0.6), b.at(0, 0.82, -0.12)), Vector3(0.1, 0.02, 0.5) * b.unit,
		slate.darkened(0.35))
	b.g.cyl(Transform3D(Basis(Vector3.RIGHT, -0.9), b.at(0, 0.8, -0.05)), 0.06 * b.unit, 0.08 * b.unit, 0.5 * b.unit,
		copper, 8)
	if b.level >= 10:
		b.g.cyl(Transform3D(Basis(Vector3.RIGHT, 0.9), b.at(0.15, 0.8, 0.05)), 0.04 * b.unit, 0.05 * b.unit,
			0.36 * b.unit, copper, 8)
	b.stop()
	b.ball(0.04, KitStyle.GOLD, 0, 1.03, 0, 1.0, 3, 6)
	b.top = 1.05


## The Beacon: "a tall lantern mast", iron and constellation colours; a
## beam of light into the sky. A stone foot, an iron lattice, the lantern
## room glazed and capped, its beam turning.
static func _beacon(b: BuildingKit) -> void:
	var iron := KitStyle.IRON if b.tier < 2 else KitStyle.GOLD
	var col: Color = b.style["accent"]
	b.plinth(0.8, 0.8)
	b.cyl(0.3, 0.26, 0.5, b.stone, 0, 0.08, 0, 10)
	b.cyl(0.31, 0.31, 0.04, b.stone2, 0, 0.56, 0, 10)
	b.door(0, 0.08, 0.27, 0, 0.8)
	var h := 1.55 + 0.15 * b.tier
	var y0 := 0.6
	for k in 4:
		var a := TAU * k / 4.0 + PI / 4.0
		var foot := Vector3(cos(a) * 0.22, y0, sin(a) * 0.22)
		var head := Vector3(cos(a) * 0.11, h, sin(a) * 0.11)
		var mid := (foot + head) / 2.0
		var span := foot.distance_to(head)
		var axis := Vector3(-sin(a), 0, cos(a))
		b.g.box(Transform3D(Basis(axis, -atan2(0.11, h - y0)), b.at(mid.x, mid.y, mid.z)),
			Vector3(0.045, span, 0.045) * b.unit, iron)
	# Cross braces between the legs, ring by ring.
	for r in 3:
		var t := (r + 0.5) / 3.0
		var rad := lerpf(0.22, 0.11, t) * 1.02
		var y := lerpf(y0, h, t)
		for k in 4:
			var a := TAU * k / 4.0
			b.fine(rad * 1.41, 0.025, 0.025, iron, cos(a) * rad * 0.71, y, sin(a) * rad * 0.71, -a + PI / 2.0)
	b.cyl(0.2, 0.2, 0.05, iron, 0, h, 0, 8)
	b.glass.cyl(b.place(0, h + 0.05, 0), 0.14 * b.unit, 0.14 * b.unit, 0.24 * b.unit, Color("#FFF4D0"), 8)
	b.ball(0.08, KitStyle.lit(Color("#FFE7A8"), 0.1), 0, h + 0.17, 0, 1.2, 3, 8)
	for k in 4:
		var a := TAU * k / 4.0 + PI / 8.0
		b.fine(0.02, 0.24, 0.02, iron, cos(a) * 0.14, h + 0.17, sin(a) * 0.14)
	b.cone(0.2, 0.18, b.roof_col, 0, h + 0.29, 0, 8)
	b.cone(0.02, 0.1, KitStyle.GOLD, 0, h + 0.47, 0, 6)
	# The beam, turning.
	b.move(Geo.Anim.SPIN_Y, b.at(0, h + 0.17, 0))
	b.glass.prism(Transform3D(Basis(Vector3.BACK, PI / 2.0), b.at(0.14, h + 0.17, 0)), 8, 0.05 * b.unit,
		0.18 * b.unit, 0.7 * b.unit, Color(col.lightened(0.5), 0.3))
	b.stop()
	b.top = h + 0.5


## The Visitor's Dock: "a pier with skiff moorings", wood and rope; the
## skiff bobs. A boathouse at the back, the pier running out front past
## its mooring posts, and the skiff tied up, its sail set.
static func _dock(b: BuildingKit) -> void:
	var plank := KitStyle.WOOD.lightened(0.3)
	b.box(0.62, 0.36, 0.44, KitStyle.WOOD.lightened(0.15) if b.tier == 0 else b.wall, -0.12, 0.26, -0.24)
	b.frame(0.62, 0.36, 0.44, 0.08)
	b.roof(0.62, 0.44, 0.44, 0.24, 0.06, 3)
	b.door(-0.12, 0.08, -0.01, 0, 0.9)
	b.window(-0.43, 0.3, -0.24, -PI / 2.0, 0.8, false)
	for k in 6:
		b.box(0.3, 0.035, 0.13, plank.darkened(0.06 * (k % 2)), 0.25, 0.1, -0.15 + 0.13 * k)
	for z: float in [0.0, 0.4, 0.62]:
		for x: float in [0.08, 0.42]:
			b.cyl(0.03, 0.03, 0.22, KitStyle.WOOD, x, 0, z, 6)
			b.d.torus(b.place(x, 0.18, z), 0.035 * b.unit, 0.008 * b.unit, Color("#D8C8A8"), 8, 3)
	# The skiff beside the pier, bobbing, its sail up.
	var at := b.at(-0.24, 0.06, 0.42)
	b.move(Geo.Anim.BOB, at)
	b.g.ball(Geo.place(at, 0.0, Vector3(0.7, 0.45, 1.6)), 0.17 * b.unit, Color("#8A5A3A"), 3, 10, true)
	b.d.box(Geo.place(at + Vector3(0, 0.02, 0) * b.unit), Vector3(0.18, 0.02, 0.4) * b.unit, plank)
	b.d.cyl(Geo.place(at), 0.01 * b.unit, 0.008 * b.unit, 0.55 * b.unit, KitStyle.WOOD_DARK, 4)
	var sail := Color("#F4EEDF")
	var mast := at + Vector3(0, 0.05, 0) * b.unit
	b.d.tri(mast + Vector3(0, 0.48, 0) * b.unit, mast + Vector3(0, 0.06, 0.22) * b.unit,
		mast + Vector3(0, 0.06, -0.02) * b.unit, sail)
	b.d.tri(mast + Vector3(0, 0.48, 0) * b.unit, mast + Vector3(0, 0.06, -0.02) * b.unit,
		mast + Vector3(0, 0.06, 0.22) * b.unit, sail.darkened(0.08))
	b.stop()
	b.flag(0.42, 0.22, 0.62, 0.4)
	b.top = 0.7


## A Law Pylon: "an obelisk topped with the school's shape".
static func _pylon(b: BuildingKit) -> void:
	b.g.prism(b.place(0, 0, 0, PI / 4.0), 4, 0.3 * b.unit, 0.26 * b.unit, 0.16 * b.unit, b.stone2)
	b.g.prism(b.place(0, 0.16, 0, PI / 4.0), 4, 0.15 * b.unit, 0.08 * b.unit, 0.9 * b.unit, b.stone)
	b.move(Geo.Anim.SPIN_Y, b.at(0, 1.2, 0))
	b.d.gem(Geo.place(b.at(0, 1.2, 0)), 0.1 * b.unit, 0.14 * b.unit, KitStyle.lit(b.style["accent"], 0.3), 4)
	b.stop()
	b.top = 1.3


## A Ward on its rune circle (the design's ward, :816–825).
static func _ward(b: BuildingKit) -> void:
	var acc: Color = b.style["accent"]
	b.cyl(0.45, 0.45, 0.04, Color("#2A2350"), 0, 0, 0, 16)
	for i in 10:
		var q := i * PI / 5.0
		b.box(0.1, 0.012, 0.03, KitStyle.lit(acc, 0.5), cos(q) * 0.33, 0.046, sin(q) * 0.33, -q + PI / 2.0)
	for i in 4:
		var q := i * PI / 2.0 + PI / 4.0
		var post := [Color("#8A7A6A"), b.stone2, Color("#E6E0FF")][b.tier] as Color
		b.g.prism(b.place(cos(q) * 0.36, 0, sin(q) * 0.36, -q), 4, 0.07 * b.unit, 0.045 * b.unit, 0.44 * b.unit, post)
		if b.tier >= 1:
			b.fine(0.06, 0.02, 0.06, KitStyle.GOLD, cos(q) * 0.36, 0.42, sin(q) * 0.36)
	b.move(Geo.Anim.SPIN_Y, b.at(0, 0.42, 0))
	b.d.gem(Geo.place(b.at(0, 0.42, 0)), 0.08 * b.unit, 0.08 * b.unit, KitStyle.lit(acc.lightened(0.3), 0.4), 4)
	b.d.torus(Transform3D(Basis(Vector3.RIGHT, 0.6), b.at(0, 0.42, 0)), 0.16 * b.unit, 0.012 * b.unit,
		KitStyle.lit(acc, 0.4), 16, 3)
	b.stop()
	b.top = 0.7


## §21.5's level-10 crown for each kind, above the building's top.
static func crown(b: BuildingKit, kind: String) -> void:
	var y := b.top
	var gold := KitStyle.GOLD
	var glow := KitStyle.lit(Color("#FFF1C4"), 0.3)
	match kind:
		"keeper_s_spire":
			# The Book of Laws, open at the top.
			var u := b.unit
			b.unit = u / 3.0 * 1.55
			var p := b.at(0, 4.62, 0)
			b.move(Geo.Anim.BOB, p)
			for s: float in [-1.0, 1.0]:
				b.d.box(Transform3D(Basis(Vector3.BACK, s * 0.25), p + Vector3(s * 0.11, 0, 0) * b.unit),
					Vector3(0.22, 0.02, 0.28) * b.unit, Color("#FFF8E6"))
			b.d.box(Geo.place(p + Vector3(0, -0.02, 0) * b.unit), Vector3(0.46, 0.02, 0.3) * b.unit, b.roof_col)
			b.stop()
			b.unit = u
		"vault":
			b.move(Geo.Anim.SPIN_Y, b.at(0, y, 0))
			b.d.torus(b.place(0, y + 0.05, 0), 0.3 * b.unit, 0.015 * b.unit, gold, 20, 3)
			for k in 6:
				var a := TAU * k / 6.0
				b.d.gem(Geo.place(b.at(cos(a) * 0.3, y + 0.05, sin(a) * 0.3)), 0.03 * b.unit, 0.03 * b.unit, glow, 4)
			b.stop()
		"hearth":
			# A tree-house wing.
			b.cyl(0.04, 0.03, 0.55, KitStyle.WOOD, -0.6, 0, 0.1, 6)
			b.ball(0.2, b.palette["plant"], -0.6, 0.7, 0.1, 0.9, 4, 8)
			b.box(0.2, 0.16, 0.2, KitStyle.WOOD.lightened(0.2), -0.6, 0.52, 0.1)
			b.cone(0.16, 0.12, b.roof_col, -0.6, 0.6, 0.1, 4)
		"garden":
			b.cyl(0.03, 0.025, 0.3, KitStyle.WOOD, 0, y, 0, 6)
			b.ball(0.14, KitStyle.lit(Color("#8CF0A0"), 0.6), 0, y + 0.36, 0, 0.9, 4, 8)
		"star_well":
			b.move(Geo.Anim.SPIN_Y, b.at(0, y, 0))
			for k in 6:
				var a := TAU * k / 6.0
				b.d.gem(Geo.place(b.at(cos(a) * 0.22, y + 0.1 + 0.08 * (k % 2), sin(a) * 0.22)), 0.03 * b.unit,
					0.05 * b.unit, glow, 4)
			b.stop()
		"storehouse":
			b.move(Geo.Anim.BOB, b.at(0, y + 0.3, 0))
			b.box(0.3, 0.16, 0.2, Color("#B88A5A"), 0, y + 0.3, 0)
			b.box(0.32, 0.03, 0.22, gold, 0, y + 0.39, 0)
			b.stop()
		"guardian_post":
			b.move(Geo.Anim.SWING, b.at(0, y + 0.05, 0))
			b.cyl(0.08, 0.04, 0.12, gold, 0, y - 0.12, 0, 8)
			b.stop()
		"library":
			var p := b.at(0, y + 0.25, 0)
			b.move(Geo.Anim.BOB, p)
			for s: float in [-1.0, 1.0]:
				b.d.box(Transform3D(Basis(Vector3.BACK, s * 0.3), p + Vector3(s * 0.08, 0, 0) * b.unit),
					Vector3(0.16, 0.015, 0.2) * b.unit, Color("#FFF8E6"))
			b.stop()
		"nursery":
			b.ball(0.12, KitStyle.lit(Color("#FFE7A8"), 0.5), 0, y + 0.08, 0, 1.0, 3, 8)
		"beacon", "anchor_stone", "law_pylon":
			b.move(Geo.Anim.SPIN_Y, b.at(0, y + 0.2, 0))
			b.d.torus(b.place(0, y + 0.2, 0), 0.18 * b.unit, 0.015 * b.unit, glow, 16, 3)
			b.d.gem(Geo.place(b.at(0, y + 0.2, 0)), 0.06 * b.unit, 0.08 * b.unit, glow, 5)
			b.stop()
		"visitor_s_dock":
			b.cyl(0.08, 0.06, 0.5, Color("#F4EEF8"), 0.4, 0.22, 0.4, 8)
			b.cyl(0.07, 0.07, 0.08, KitStyle.lit(Color("#FFE7A8"), 0.3), 0.4, 0.72, 0.4, 8)
			b.cone(0.09, 0.1, b.roof_col, 0.4, 0.8, 0.4, 8)
		_:
			b.move(Geo.Anim.SPIN_Y, b.at(0, y + 0.15, 0))
			b.d.gem(Geo.place(b.at(0, y + 0.15, 0)), 0.08 * b.unit, 0.12 * b.unit, glow, 5)
			b.stop()
