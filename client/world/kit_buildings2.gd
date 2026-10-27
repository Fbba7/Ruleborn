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


## The Keeper's Spire as the realm view draws it (the design's `spire`,
## :842–846, which its realm view stands alone on the Spire's footprint):
## a stepped octagonal terrace, buttresses round a lit base, a slim banded
## tower "wrapped in rings" that turn, and an orb above. In units of about
## half a tile, so the Spire stands about seven metres, the realm's tallest.
static func _citadel(b: BuildingKit) -> void:
	var u := b.unit
	b.unit = u / 3.0 * 1.75
	var acc: Color = b.style["accent"]
	var roof := b.roof_col if b.tier > 0 else Color(b.style["roof"])
	b.cyl(0.95, 1.0, 0.16, b.stone2, 0, 0, 0, 8)
	b.cyl(0.8, 0.86, 0.14, b.stone, 0, 0.16, 0, 8)
	# Steps up to the door, south.
	for k in 3:
		b.box(0.5 - 0.08 * k, 0.1, 0.16, b.stone2, 0, 0.05 + 0.1 * k, 1.0 - 0.1 * k)
	b.door(0, 0.3, 0.7, 0, 1.2)
	# A balustrade round the terrace's edge, open at the steps, and urns of
	# flowers by them: close-up detail, left out at the mid detail.
	for k in 16:
		var a := TAU * (k + 0.5) / 16.0
		if absf(wrapf(a - PI / 2.0, -PI, PI)) < 0.3:
			continue
		b.fine(0.035, 0.12, 0.035, b.stone, cos(a) * 0.78, 0.36, sin(a) * 0.78)
	if not b.lighter:
		b.d.torus(b.place(0, 0.43, 0), 0.78 * b.unit, 0.018 * b.unit, b.stone2, 24, 4)
		for x: float in [-0.3, 0.3]:
			b.cyl(0.06, 0.045, 0.1, b.stone2, x, 0.3, 0.86, 8)
			b.ball(0.06, Color("#F7A6DA"), x, 0.43, 0.86, 0.8, 3, 6)
	# The Spire.
	b.cyl(0.62, 0.7, 0.6, b.stone, 0, 0.3, 0, 8)
	for i in 4:
		var q := i * PI / 2.0 + PI / 8.0
		b.box(0.14, 0.7, 0.3, b.stone2, cos(q) * 0.66, 0.6, sin(q) * 0.66, -q)
		if i > 0:
			var w := q + PI / 4.0
			b.box(0.02, 0.2, 0.12, KitStyle.lit(Color("#FFE7F4"), 0.5), cos(w) * 0.66, 0.62, sin(w) * 0.66, -w)
	b.cyl(0.66, 0.66, 0.06, acc, 0, 0.9, 0, 8)
	var body := Color("#F4EEF8") if b.tier > 0 else b.stone.lightened(0.1)
	b.cyl(0.36, 0.3, 1.4, body, 0, 0.96, 0, 8)
	for i in 4:
		var q := i * PI / 2.0
		b.box(0.02, 0.34, 0.08, KitStyle.lit(Color("#FFE7F4"), 0.5), cos(q) * 0.33, 1.6, sin(q) * 0.33, -q)
	b.cyl(0.52, 0.44, 0.08, roof, 0, 2.36, 0, 8)
	b.cyl(0.3, 0.26, 0.5, body, 0, 2.44, 0, 8)
	for i in (0 if b.lighter else 4):
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
	if b.tier >= 1 and not b.lighter:
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
	# A portico before the door, as the design's map vault (:847-866): four
	# white columns, an entablature and a pediment, a broad step below.
	var white := Color("#F4EEF8")
	for x: float in [-0.36, -0.14, 0.14, 0.36]:
		b.cyl(0.04, 0.045, 0.46, white, x, 0.1, 0.52, 6)
	b.fine(0.92, 0.06, 0.2, b.stone2, 0, 0.6, 0.52)
	b.g.gable(b.place(0, 0.63, 0.52), 0.94 * b.unit, 0.18 * b.unit, 0.2 * b.unit, b.stone)
	b.fine(0.98, 0.05, 0.3, b.stone2, 0, 0.075, 0.55)
	# Braziers at the corners of the step.
	for x: float in [-0.52, 0.52]:
		b.cyl(0.05, 0.07, 0.18, b.stone2, x, 0.1, 0.66, 5)
		b.ball(0.04, KitStyle.lit(Color("#FFB040"), 0.2), x, 0.31, 0.66, 1.2, 2, 5)
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
	b._torus_at(0.17, 0.03, KitStyle.IRON, 0, 0.42, 0)
	for k in 4:
		var a := TAU * k / 4.0 + PI / 4.0
		var top := Vector3(cos(a) * 0.17, 0.42, sin(a) * 0.17)
		var foot := Vector3(cos(a) * 0.5, 0.08, sin(a) * 0.5)
		if b.lighter:
			# The chain as one dark bar at the mid detail.
			var run := b.at(foot.x, foot.y, foot.z) - b.at(top.x, top.y, top.z)
			b.d.box(Transform3D(Basis.looking_at(run.normalized()), b.at(top.x, top.y, top.z) + run / 2.0),
				Vector3(0.02 * b.unit, 0.02 * b.unit, run.length()), KitStyle.IRON)
		for m in (0 if b.lighter else 6):
			var p := top.lerp(foot, (m + 0.5) / 6.0)
			p.y -= sin((m + 0.5) / 6.0 * PI) * 0.04
			var yaw := -a + (PI / 2.0 if m % 2 == 0 else 0.0)
			b.d.torus(Transform3D(Basis(Vector3.UP, yaw) * Basis(Vector3.RIGHT, PI / 2.0), b.at(p.x, p.y, p.z)),
				0.028 * b.unit, 0.009 * b.unit, KitStyle.IRON, 8, 3)
		b.box(0.12, 0.08, 0.12, b.stone2.darkened(0.1), foot.x, 0.04, foot.z, -a)
		b._torus_at(0.035, 0.01, KitStyle.IRON, foot.x, 0.09, foot.z)
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
	for k in range(0, 16, 2 if b.lighter else 1):
		var a := TAU * k / 16.0
		b.ball(0.035, rim, cos(a) * 0.5, 0.19, sin(a) * 0.5, 0.7, 2, 5)
	var tiers := [[0.32, 0.5], [0.2, 0.78]]
	b.cyl(0.08, 0.1, 0.62, teal, 0, 0.18, 0, 8)
	for tr: Array in tiers:
		var r: float = tr[0]
		var y: float = tr[1]
		b.cyl(r * 0.6, r, 0.08, teal, 0, y - 0.08, 0, 10)
		b.g.cyl(b.place(0, y, 0), r * 0.92 * b.unit, r * 0.92 * b.unit, 0.006 * b.unit, ink, 10)
		for k in (0 if b.lighter else 10):
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
	# Ink droplets rising from the spout and bubbles from the basin.
	for k in 4:
		var a := TAU * k / 4.0
		var p := b.at(cos(a) * 0.05, 1.05, sin(a) * 0.05)
		b.move(Geo.Anim.RISE, p + Vector3(k * 0.9, 0, 0))
		b.d.ball(Geo.place(p), 0.02 * b.unit, KitStyle.lit(Color("#9BF4FA"), 0.4), 2, 5)
		var q := b.at(cos(a + 0.6) * 0.3, 0.18, sin(a + 0.6) * 0.3)
		b.move(Geo.Anim.RISE, q + Vector3(k * 1.3, 0, 0))
		b.d.ball(Geo.place(q), 0.015 * b.unit, Color("#E8FCFF"), 2, 4)
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
	b.window(-0.1, 0.3, -0.34, PI, 0.8)
	b.window(-0.455, 0.3, -0.06, -PI / 2.0, 0.8, false)
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
## A stone drum with a timber gallery round it, the dome ribbed in copper
## with its slit open and the telescope reaching out of it, a lit star on
## a vane at the top. Slate under copper ribs at the first look, a copper
## dome at the second, lilac and gold at the third.
static func _observatory(b: BuildingKit) -> void:
	b.plinth(0.96, 0.96)
	b.cyl(0.42, 0.4, 0.46, b.stone, 0, 0.08, 0, 12)
	b.courses(0.84, 0.84, 0.08, 0.54, 3)
	for k in 4:
		var a := TAU * k / 4.0 + 0.4
		b.window(cos(a) * 0.41, 0.3, sin(a) * 0.41, PI / 2.0 - a, 0.8, false)
	b.door(0, 0.08, 0.41, 0, 0.9)
	# The gallery: a timber walk round the drum, posts and a rail.
	var wood := KitStyle.WOOD if b.tier < 2 else KitStyle.GOLD
	b.cyl(0.5, 0.48, 0.04, KitStyle.WOOD.lightened(0.1), 0, 0.54, 0, 12)
	for k in 12:
		var a := TAU * k / 12.0
		b.fine(0.02, 0.1, 0.02, wood, cos(a) * 0.48, 0.63, sin(a) * 0.48)
	if not b.lighter:
		b.d.torus(b.place(0, 0.68, 0), 0.48 * b.unit, 0.01 * b.unit, wood, 16, 3)
	var dome: Color = [Color("#5A6B8C"), Color("#C8804A"), Color("#B9A6F2")][b.tier]
	var rib: Color = [Color("#D08850"), Color("#6A4A3A"), KitStyle.GOLD][b.tier]
	var copper := Color("#C87A4A") if b.tier < 2 else KitStyle.GOLD
	var hub := b.at(0, 0.58, 0)
	b.move(Geo.Anim.SPIN_Y, hub)
	b.g.ball(Geo.place(hub), 0.4 * b.unit, dome, 5, 14, true)
	# Copper ribs over the dome, meridian by meridian.
	for k in (2 if b.lighter else 4):
		var turn := Basis(Vector3.UP, PI / 4.0 * k + PI / 8.0) * Basis(Vector3.RIGHT, PI / 2.0)
		b.d.torus(Transform3D(turn, hub), 0.405 * b.unit, 0.012 * b.unit, rib, 16, 3)
	# The slit, dark, from the crown down the front, and the telescope out of it.
	var slit := Basis(Vector3.RIGHT, -0.55)
	b.d.box(Transform3D(slit, b.at(0, 0.88, 0.2)), Vector3(0.12, 0.02, 0.36) * b.unit, Color("#20182E"))
	var tube := Basis(Vector3.RIGHT, -0.95)
	b.g.cyl(Transform3D(tube, b.at(0, 0.78, 0.0)), 0.075 * b.unit, 0.09 * b.unit, 0.58 * b.unit, copper, 10)
	var mouth := b.at(0, 0.78, 0.0) + tube * Vector3(0, 0.58, 0) * b.unit
	b.d.torus(Transform3D(tube, mouth), 0.09 * b.unit, 0.015 * b.unit, KitStyle.GOLD, 10, 3)
	b.d.cyl(Transform3D(tube, mouth - tube * Vector3(0, 0.01, 0) * b.unit), 0.075 * b.unit, 0.075 * b.unit,
		0.01 * b.unit, KitStyle.lit(Color("#BFE4FF"), 0.5), 10)
	if b.level >= 10:
		var second := Basis(Vector3.UP, 1.2) * Basis(Vector3.RIGHT, -0.8)
		b.g.cyl(Transform3D(second, b.at(0.1, 0.78, 0.0)), 0.05 * b.unit, 0.06 * b.unit, 0.42 * b.unit, copper, 8)
	# The vane and its star.
	b.cyl(0.01, 0.008, 0.2, KitStyle.IRON, 0, 0.96, 0, 4)
	b.d.gem(Geo.place(b.at(0, 1.18, 0)), 0.05 * b.unit, 0.06 * b.unit, KitStyle.lit(Color("#FFE7A8"), 0.3), 4)
	b.stop()
	b.top = 1.1


## The Beacon: "a tall lantern mast", iron and constellation colours; a
## beam of light into the sky. A banded tower tapering up from a stone
## foot to a railed gallery, the glazed lantern room lit gold, its cap and
## gold spike, a beam turning round it and a column of light rising from it.
static func _beacon(b: BuildingKit) -> void:
	var iron := KitStyle.IRON if b.tier < 2 else KitStyle.GOLD
	var col: Color = b.style["accent"]
	var body := b.stone.lightened(0.08) if b.tier == 0 else (b.wall if b.tier == 1 else Color("#F4EEF8"))
	b.plinth(0.8, 0.8)
	b.cyl(0.32, 0.3, 0.3, b.stone2, 0, 0.08, 0, 10)
	b.door(0, 0.08, 0.3, 0, 0.8)
	var h := 1.6 + 0.15 * b.tier
	var y0 := 0.38
	b.cyl(0.25, 0.15, h - y0, body, 0, y0, 0, 10)
	# Bands up the tower in the realm's colour, as a lighthouse's.
	for k in 3:
		var t0 := 0.2 + 0.27 * k
		var y := lerpf(y0, h, t0)
		var r := lerpf(0.25, 0.15, t0) + 0.006
		b.cyl(r, r - 0.012, 0.09, col if k % 2 == 0 else iron, 0, y, 0, 10)
	for k in 2:
		b.window(0, lerpf(y0, h, 0.38 + 0.3 * k), lerpf(0.25, 0.15, 0.38 + 0.3 * k) + 0.005, 0, 0.6, false)
	# The gallery and its rail.
	b.cyl(0.26, 0.24, 0.05, iron, 0, h, 0, 10)
	for k in 10:
		var a := TAU * k / 10.0
		b.fine(0.015, 0.1, 0.015, iron, cos(a) * 0.24, h + 0.1, sin(a) * 0.24)
	if not b.lighter:
		b.d.torus(b.place(0, h + 0.15, 0), 0.24 * b.unit, 0.008 * b.unit, iron, 14, 3)
	b.glass.cyl(b.place(0, h + 0.05, 0), 0.15 * b.unit, 0.15 * b.unit, 0.26 * b.unit, Color("#FFF4D0"), 8)
	b.g.ball(Geo.place(b.at(0, h + 0.18, 0), 0.0, Vector3(1, 1.2, 1)), 0.1 * b.unit, KitStyle.lit(Color("#FFE7A8"), 0.1),
		3, 8)
	for k in 4:
		var a := TAU * k / 4.0 + PI / 8.0
		b.fine(0.02, 0.26, 0.02, iron, cos(a) * 0.15, h + 0.18, sin(a) * 0.15)
	b.cone(0.21, 0.2, b.roof_col, 0, h + 0.31, 0, 8)
	b.cone(0.025, 0.14, KitStyle.GOLD, 0, h + 0.5, 0, 6)
	# The beam, turning, and the light rising into the sky.
	b.move(Geo.Anim.SPIN_Y, b.at(0, h + 0.18, 0))
	b.glass.prism(Transform3D(Basis(Vector3.BACK, PI / 2.0), b.at(0.15, h + 0.18, 0)), 8, 0.05 * b.unit,
		0.2 * b.unit, 0.8 * b.unit, Color(col.lightened(0.5), 0.3))
	b.stop()
	b.glass.prism(b.place(0, h + 0.62, 0), 8, 0.06 * b.unit, 0.16 * b.unit, 1.2 * b.unit,
		Color(Color("#FFE9A8"), 0.12))
	# Constellation stars round the lantern room, turning slowly.
	b.move(Geo.Anim.SPIN_Y, b.at(0, h + 0.2, 0))
	for k in 5:
		var a := TAU * k / 5.0
		b.d.gem(Geo.place(b.at(cos(a) * 0.34, h + 0.12 + 0.1 * (k % 2), sin(a) * 0.34)), 0.035 * b.unit,
			0.05 * b.unit, KitStyle.lit(col.lightened(0.4), 0.3), 4)
	b.stop()
	b.top = h + 0.6


## The Visitor's Dock: "a pier with skiff moorings", wood and rope; the
## skiffs bob. A stone quay with a boathouse at the back, the pier running
## out to the front between rope-railed posts to a lamp at its end, and the
## skiff tied up beside it, afloat on the air, its sail set in the realm's
## colour; crates and a coil of rope on the quay.
static func _dock(b: BuildingKit) -> void:
	var plank := KitStyle.WOOD.lightened(0.3)
	var acc: Color = b.style["accent"]
	b.box(1.0, 0.1, 0.42, b.stone2, 0, 0.05, -0.28)
	b.box(0.44, 0.34, 0.32, KitStyle.WOOD.lightened(0.15) if b.tier == 0 else b.wall, 0.24, 0.27, -0.3)
	b.frame(0.44, 0.34, 0.32, 0.1)
	b.roof(0.44, 0.32, 0.44, 0.22, 0.06, 3)
	b.door(0.24, 0.1, -0.13, 0, 0.8)
	b.window(0.465, 0.28, -0.3, PI / 2.0, 0.75, false)
	# The pier: planks out to the footprint's front, on posts, rope between.
	for k in 7:
		b.box(0.26, 0.035, 0.11, plank.darkened(0.06 * (k % 2)), 0.12, 0.11, -0.08 + 0.11 * k)
	for z: float in [-0.04, 0.26, 0.58]:
		for x: float in [-0.02, 0.26]:
			b.cyl(0.026, 0.026, 0.26, KitStyle.WOOD, x, 0, z, 6)
			b.ball(0.032, KitStyle.WOOD_DARK, x, 0.27, z, 0.6, 2, 6)
	for x: float in [-0.02, 0.26]:
		b.fine(0.012, 0.012, 0.62, Color("#D8C8A8"), x, 0.22, 0.27)
	# The lamp at the pier's end.
	b.cyl(0.016, 0.014, 0.42, KitStyle.WOOD_DARK, 0.26, 0.13, 0.62, 5)
	b.box(0.07, 0.08, 0.07, KitStyle.lit(Color("#FFD27A"), 0.6), 0.26, 0.58, 0.62)
	b.cone(0.06, 0.05, KitStyle.WOOD_DARK, 0.26, 0.62, 0.62, 4)
	# Crates, a barrel and a coil of rope on the quay.
	b.box(0.13, 0.13, 0.13, Color("#B88A5A"), -0.36, 0.165, -0.38, 0.3)
	b.box(0.1, 0.1, 0.1, Color("#C89A6A"), -0.22, 0.15, -0.36, -0.2)
	b.cyl(0.06, 0.06, 0.15, KitStyle.WOOD.lightened(0.2), -0.4, 0.1, -0.2, 8)
	b._torus_at(0.05, 0.018, Color("#D8C8A8"), -0.12, 0.12, -0.2)
	# The skiff moored beside the pier, bobbing on the air, its sail set
	# across it toward the camera.
	var at := b.at(-0.3, 0.22, 0.24)
	b.move(Geo.Anim.BOB, at)
	b.g.ball(Geo.place(at, 0.0, Vector3(0.8, 0.55, 1.7)), 0.2 * b.unit, Color("#8A5A3A"), 3, 10, true)
	b.d.box(Geo.place(at + Vector3(0, 0.02, 0) * b.unit), Vector3(0.22, 0.02, 0.5) * b.unit, plank)
	b.d.torus(Transform3D(Basis().scaled(Vector3(0.8, 1, 1.7)), at + Vector3(0, 0.005, 0) * b.unit), 0.2 * b.unit,
		0.016 * b.unit, KitStyle.GOLD if b.tier >= 2 else KitStyle.WOOD_DARK, 12, 3)
	var mast := at + Vector3(0, 0.02, 0) * b.unit
	b.g.cyl(Geo.place(mast), 0.016 * b.unit, 0.012 * b.unit, 0.68 * b.unit, KitStyle.WOOD_DARK, 5)
	var sail := Color("#F4EEDF") if b.tier == 0 else acc.lightened(0.25)
	var top := mast + Vector3(0, 0.62, 0.01) * b.unit
	var foot_l := mast + Vector3(-0.17, 0.12, 0.01) * b.unit
	var foot_r := mast + Vector3(0.17, 0.12, 0.01) * b.unit
	b.g.tri(top, foot_l, foot_r, sail)
	b.g.tri(top, foot_r, foot_l, sail.darkened(0.08))
	b.d.tri(top + Vector3(0, 0.08, 0) * b.unit, top + Vector3(0.13, 0.04, 0) * b.unit, top, acc)
	b.d.tri(top + Vector3(0, 0.08, 0) * b.unit, top, top + Vector3(0.13, 0.04, 0) * b.unit, acc.darkened(0.1))
	b.stop()
	# A glow under the skiff where it rides the air.
	b.glass.ring(b.place(-0.3, 0.015, 0.24), 0.0, 0.24 * b.unit, Color(Color("#BFE4FF"), 0.3), 10)
	b.flag(-0.44, 0.1, -0.44, 0.4)
	b.top = 0.85


## A Law Pylon: "an obelisk topped with the school's shape", stone and the
## school's colour; it pulses in the law's rhythm. A two-step base turned
## to the diagonal, the obelisk with runes glowing up its faces and a band
## of colour, its pyramidion capped in gold from the second look, the shape
## turning over it in its ring, and a rune circle on the ground.
static func _pylon(b: BuildingKit) -> void:
	var col: Color = b.style["accent"]
	var stone := b.stone if b.tier < 2 else Color("#F2EEF8")
	b.g.cyl(b.place(0, 0, 0), 0.5 * b.unit, 0.5 * b.unit, 0.02 * b.unit, Color("#3A3350"), 16)
	if not b.lighter:
		b.d.torus(b.place(0, 0.025, 0), 0.42 * b.unit, 0.012 * b.unit, KitStyle.lit(col, 0.45), 20, 3)
		for i in 8:
			var q := TAU * i / 8.0
			b.fine(0.07, 0.006, 0.025, KitStyle.lit(col, 0.5), cos(q) * 0.46, 0.026, sin(q) * 0.46, -q)
	b.g.rbox(b.place(0, 0.08, 0, PI / 4.0), Vector3(0.52, 0.12, 0.52) * b.unit, b.stone2, 0.02)
	b.g.rbox(b.place(0, 0.18, 0, PI / 4.0), Vector3(0.38, 0.08, 0.38) * b.unit, b.stone2.lightened(0.08), 0.015)
	if b.tier >= 1:
		for i in 4:
			var q := i * PI / 2.0
			b.cone(0.05, 0.16, b.trim, cos(q) * 0.28, 0.14, sin(q) * 0.28, 4)
	b.g.prism(b.place(0, 0.22, 0, PI / 4.0), 4, 0.15 * b.unit, 0.085 * b.unit, 0.95 * b.unit, stone)
	b.g.prism(b.place(0, 1.17, 0, PI / 4.0), 4, 0.085 * b.unit, 0.0, 0.14 * b.unit,
		KitStyle.GOLD if b.tier >= 1 else stone.lightened(0.1))
	b.cyl(0.13, 0.125, 0.06, col, 0, 0.4, 0, 4)
	# Runes up each face in the school's colour, breathing.
	for f in 4:
		var yaw := PI / 2.0 * f
		var out := Vector3(0, 0, 1).rotated(Vector3.UP, yaw)
		for k in (2 if b.lighter else 3):
			var y := 0.58 + 0.18 * k
			var inset := lerpf(0.15, 0.085, (y - 0.22) / 0.95) / 1.414 + 0.004
			b._pane(Transform3D(Basis(Vector3.UP, yaw), b.at(0, y, 0) + out * inset * b.unit), 0.045 * b.unit,
				0.06 * b.unit, KitStyle.lit(col.lightened(0.2), 0.4))
	var crest := b.at(0, 1.55, 0)
	b.move(Geo.Anim.SPIN_Y, crest)
	b.g.gem(Geo.place(crest), 0.11 * b.unit, 0.15 * b.unit, KitStyle.lit(col.lightened(0.15), 0.3), 4)
	b.d.torus(Transform3D(Basis(Vector3.RIGHT, 0.4), crest), 0.17 * b.unit, 0.01 * b.unit, KitStyle.GOLD, 16, 3)
	b.stop()
	b.top = 1.65


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
	# The floating crowns drawn half as big again, so level 10 reads at the
	# home camera; those standing beside the building keep its scale.
	var keep := b.unit
	if not kind in ["keeper_s_spire", "hearth", "garden", "guardian_post", "visitor_s_dock"]:
		b.unit *= 1.5
	var y := b.top * keep / b.unit + 0.05
	var gold := KitStyle.GOLD
	var glow := KitStyle.lit(Color("#FFF1C4"), 0.3)
	_crown(b, kind, y, gold, glow)
	b.unit = keep


static func _crown(b: BuildingKit, kind: String, y: float, gold: Color, glow: Color) -> void:
	match kind:
		"keeper_s_spire":
			# The Book of Laws, open at the top.
			var u := b.unit
			b.unit = u / 3.0 * 1.55
			var p := b.at(0, 4.75, 0)
			b.move(Geo.Anim.BOB, p)
			for s: float in [-1.0, 1.0]:
				b.d.box(Transform3D(Basis(Vector3.BACK, s * 0.25), p + Vector3(s * 0.17, 0, 0) * b.unit),
					Vector3(0.34, 0.025, 0.42) * b.unit, Color("#FFF8E6"))
			b.d.box(Geo.place(p + Vector3(0, -0.03, 0) * b.unit), Vector3(0.7, 0.03, 0.45) * b.unit, b.roof_col)
			b.d.ball(Geo.place(p + Vector3(0, 0.12, 0) * b.unit), 0.1 * b.unit, KitStyle.lit(Color("#FFF1C4"), 0.3), 3, 8)
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
