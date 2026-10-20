class_name FxIcons
extends RefCounted
## The HUD's drawn icons (§21.8: "rounded shapes with a 2-point outline and
## the school shape where relevant … a three-stop gradient, a gloss and a soft
## drop shadow"), drawn in code on any canvas item: the alarm's bell, the
## guards' suspicion marks, knock-out stars, coins, a loot sack, a school's
## shape and a crew member's face. Each is a shape first, so it reads as a
## dark silhouette at 32 points (§21.1).

const INK := Color("#1A0C14")


static func _circle(ci: CanvasItem, c: Vector2, r: float, fill: Color, line := 2.0) -> void:
	ci.draw_circle(c, r + line, INK)
	ci.draw_circle(c, r, fill)


## A drop shadow under an icon, so it sits on the world.
static func shadow(ci: CanvasItem, c: Vector2, r: float) -> void:
	ci.draw_circle(c + Vector2(0, r * 0.18), r * 1.08, Color(0.05, 0.0, 0.1, 0.3))


## A bell: one segment of the alarm meter. `lit` fills it.
static func bell(ci: CanvasItem, c: Vector2, s: float, fill: Color, lit: bool) -> void:
	var pts := PackedVector2Array()
	var steps := 10
	for i in steps + 1:
		var a := PI + PI * float(i) / steps
		pts.append(c + Vector2(cos(a) * s * 0.36, sin(a) * s * 0.42 - s * 0.02))
	pts.append(c + Vector2(s * 0.42, s * 0.3))
	pts.append(c + Vector2(-s * 0.42, s * 0.3))
	var body := fill if lit else Color("#57497A")
	var outline := PackedVector2Array(pts)
	outline.append(pts[0])
	ci.draw_colored_polygon(pts, body)
	ci.draw_polyline(outline, INK, maxf(1.5, s * 0.08), true)
	ci.draw_circle(c + Vector2(0, s * 0.38), s * 0.1, INK)
	ci.draw_line(c + Vector2(-s * 0.18, -s * 0.22), c + Vector2(-s * 0.12, s * 0.12),
		Color(1, 1, 1, 0.55 if lit else 0.18), maxf(1.0, s * 0.07), true)
	if lit:
		ci.draw_circle(c + Vector2(0, -s * 0.5), s * 0.07, INK)


## Five points: a knock-out star, a loot sparkle.
static func star(ci: CanvasItem, c: Vector2, r: float, fill: Color, turn := 0.0) -> void:
	var pts := PackedVector2Array()
	for i in 10:
		var a := turn - PI / 2.0 + TAU * i / 10.0
		var d := r if i % 2 == 0 else r * 0.45
		pts.append(c + Vector2(cos(a), sin(a)) * d)
	var ring := PackedVector2Array(pts)
	ring.append(pts[0])
	ci.draw_colored_polygon(pts, fill)
	ci.draw_polyline(ring, INK, maxf(1.2, r * 0.16), true)


## A coin, edge-on enough to read as money.
static func coin(ci: CanvasItem, c: Vector2, r: float) -> void:
	_circle(ci, c, r, Color("#F2B43C"), maxf(1.0, r * 0.18))
	ci.draw_circle(c, r * 0.62, Color("#FFD872"))
	ci.draw_circle(c + Vector2(-r * 0.25, -r * 0.3), r * 0.18, Color(1, 1, 1, 0.8))


## The Vault's lock: shut, or with its shackle swung open.
static func lock(ci: CanvasItem, c: Vector2, s: float, open: bool) -> void:
	var w := maxf(1.5, s * 0.12)
	var top := c + Vector2(s * 0.12 if open else 0.0, -s * 0.12)
	ci.draw_arc(top + Vector2(0, -s * (0.12 if open else 0.0)), s * 0.2, PI, TAU, 10, INK, w * 1.6, true)
	ci.draw_arc(top + Vector2(0, -s * (0.12 if open else 0.0)), s * 0.2, PI, TAU, 10, Color("#C9C3D8"), w * 0.7, true)
	var body := Rect2(c + Vector2(-s * 0.3, -s * 0.12), Vector2(s * 0.6, s * 0.48))
	var box := StyleBoxFlat.new()
	box.bg_color = Color("#3FBF7F") if open else Color("#9B8CF0")
	box.border_color = INK
	box.set_border_width_all(maxi(1, int(w * 0.8)))
	box.set_corner_radius_all(int(s * 0.08))
	ci.draw_style_box(box, body)
	ci.draw_circle(body.get_center(), s * 0.06, INK)


## A loot sack, filled to `share`.
static func sack(ci: CanvasItem, c: Vector2, s: float, share: float) -> void:
	var body := c + Vector2(0, s * 0.12)
	_circle(ci, body, s * 0.36, Color("#C98A4A"), maxf(1.0, s * 0.07))
	ci.draw_circle(body + Vector2(-s * 0.1, -s * 0.1), s * 0.12, Color(1, 1, 1, 0.25))
	ci.draw_rect(Rect2(c + Vector2(-s * 0.12, -s * 0.34), Vector2(s * 0.24, s * 0.14)), INK)
	if share > 0.0:
		coin(ci, c + Vector2(0, -s * 0.38), s * 0.14 + s * 0.06 * clampf(share, 0, 1))


## A guard's suspicion mark (§12.16): "?" when it suspects, "!" when it is
## alerted, "z" asleep or out — drawn as shapes on a speech bubble, the bubble
## filled white, yellow or red with how aware the guard is (§21.6).
static func bubble(ci: CanvasItem, c: Vector2, s: float, mark: String, fill: Color) -> void:
	var r := s * 0.5
	shadow(ci, c, r)
	var tail := PackedVector2Array([c + Vector2(-r * 0.25, r * 0.7), c + Vector2(r * 0.15, r * 0.75),
		c + Vector2(-r * 0.05, r * 1.25)])
	ci.draw_colored_polygon(tail, INK)
	_circle(ci, c, r, fill, maxf(1.5, s * 0.07))
	ci.draw_colored_polygon(PackedVector2Array([tail[0] + Vector2(r * 0.08, -r * 0.1),
		tail[1] + Vector2(-r * 0.06, -r * 0.1), tail[2] + Vector2(0, -r * 0.24)]), fill)
	var w := maxf(2.0, s * 0.14)
	match mark:
		"!":
			ci.draw_line(c + Vector2(0, -r * 0.55), c + Vector2(0, r * 0.08), INK, w * 1.15, true)
			ci.draw_circle(c + Vector2(0, -r * 0.55), w * 0.58, INK)
			ci.draw_circle(c + Vector2(0, r * 0.5), w * 0.72, INK)
		"!!":
			for dx: float in [-r * 0.26, r * 0.26]:
				ci.draw_line(c + Vector2(dx, -r * 0.55), c + Vector2(dx, r * 0.12), INK, w, true)
				ci.draw_circle(c + Vector2(dx, r * 0.45), w * 0.65, INK)
		"?", "??":
			var dx := r * 0.24 if mark == "??" else 0.0
			for side: float in ([-1.0, 1.0] if mark == "??" else [0.0]):
				var o := c + Vector2(dx * side, 0)
				var arc := PackedVector2Array()
				for i in 9:
					var a := -PI * 1.05 + PI * 1.3 * i / 8.0
					arc.append(o + Vector2(cos(a), sin(a)) * r * (0.28 if mark == "??" else 0.38) + Vector2(0, -r * 0.22))
				arc.append(o + Vector2(0, r * 0.14))
				ci.draw_polyline(arc, INK, w * (0.6 if mark == "??" else 0.75), true)
				ci.draw_circle(o + Vector2(0, r * 0.47), w * 0.62, INK)
		"z":
			var z := PackedVector2Array([c + Vector2(-r * 0.3, -r * 0.35), c + Vector2(r * 0.3, -r * 0.35),
				c + Vector2(-r * 0.3, r * 0.35), c + Vector2(r * 0.3, r * 0.35)])
			ci.draw_polyline(z, INK, w, true)
		_:
			ci.draw_circle(c, w, INK)


## A school's shape (§21.2), filled in its colour and outlined in ink.
static func school(ci: CanvasItem, c: Vector2, s: float, name: String) -> void:
	var colour: Color = Palette.SCHOOL.get(name, Palette.STONE)
	shadow(ci, c, s * 0.5)
	_circle(ci, c, s * 0.5, Color("#261A4C"), maxf(1.0, s * 0.06))
	var pts := RealmView.shape_points(Tokens.shape(name), c, s * 0.3)
	if pts.size() >= 3:
		ci.draw_colored_polygon(pts, colour)
		var ring := PackedVector2Array(pts)
		ring.append(pts[0])
		ci.draw_polyline(ring, INK, maxf(1.0, s * 0.05), true)
	else:
		ci.draw_circle(c, s * 0.28, colour)


## A crew member's face for its portrait: the round chibi body, big eyes and
## its role's top (ActorBuilder's figure, drawn flat).
static func face(ci: CanvasItem, c: Vector2, r: float, body: Color, role: String, down := false) -> void:
	var line := maxf(1.5, r * 0.06)
	match role:
		"Scout":
			for side: float in [-1.0, 1.0]:
				ci.draw_colored_polygon(PackedVector2Array([c + Vector2(side * r * 0.25, -r * 0.55),
					c + Vector2(side * r * 0.62, -r * 1.05), c + Vector2(side * r * 0.65, -r * 0.35)]), body.darkened(0.2))
		"Breaker":
			ci.draw_colored_polygon(PackedVector2Array([c + Vector2(-r * 0.18, -r * 0.7), c + Vector2(0, -r * 1.12),
				c + Vector2(r * 0.18, -r * 0.7)]), Color("#EDE6F5"))
		"Warden":
			ci.draw_circle(c + Vector2(0, -r * 0.55), r * 0.5, Palette.STONE.darkened(0.25))
		"Mender":
			ci.draw_colored_polygon(PackedVector2Array([c + Vector2(r * 0.05, -r * 0.6), c + Vector2(r * 0.45, -r * 1.05),
				c + Vector2(r * 0.35, -r * 0.5)]), Palette.LIFE)
		"Carrier":
			ci.draw_circle(c + Vector2(r * 0.6, r * 0.1), r * 0.38, Palette.WOOD.lightened(0.1))
		"guard":
			ci.draw_colored_polygon(PackedVector2Array([c + Vector2(-r * 0.6, -r * 0.45), c + Vector2(0, -r * 1.15),
				c + Vector2(r * 0.6, -r * 0.45)]), Palette.MATTER)
	ci.draw_circle(c, r * 0.72 + line, INK)
	ci.draw_circle(c, r * 0.72, body)
	ci.draw_circle(c + Vector2(0, r * 0.28), r * 0.4, body.lightened(0.3))
	ci.draw_circle(c + Vector2(-r * 0.22, -r * 0.3), r * 0.18, Color(1, 1, 1, 0.3))
	for side: float in [-1.0, 1.0]:
		var e := c + Vector2(side * r * 0.26, -r * 0.05)
		if down:
			ci.draw_line(e + Vector2(-r * 0.1, -r * 0.1), e + Vector2(r * 0.1, r * 0.1), INK, line, true)
			ci.draw_line(e + Vector2(-r * 0.1, r * 0.1), e + Vector2(r * 0.1, -r * 0.1), INK, line, true)
		else:
			ci.draw_circle(e, r * 0.17, Color.WHITE)
			ci.draw_circle(e + Vector2(0, r * 0.03), r * 0.1, INK)
			ci.draw_circle(e + Vector2(r * 0.04, -r * 0.03), r * 0.035, Color.WHITE)


## A bar: a dark track, the fill, an ink rim; `tick` marks a target share.
static func bar(ci: CanvasItem, r: Rect2, share: float, fill: Color, tick := -1.0) -> void:
	var rad := int(r.size.y * 0.5)
	var track := StyleBoxFlat.new()
	track.bg_color = Color("#2A1E40")
	track.set_corner_radius_all(rad)
	track.border_color = INK
	track.set_border_width_all(maxi(1, int(r.size.y * 0.16)))
	ci.draw_style_box(track, r)
	var s := clampf(share, 0.0, 1.0)
	if s > 0.0:
		var inner := r.grow(-maxf(1.0, r.size.y * 0.16))
		inner.size.x = maxf(inner.size.y, inner.size.x * s)
		var f := StyleBoxFlat.new()
		f.bg_color = fill
		f.set_corner_radius_all(int(inner.size.y * 0.5))
		ci.draw_style_box(f, inner)
		var hi := Rect2(inner.position + Vector2(inner.size.y * 0.3, inner.size.y * 0.12),
			Vector2(maxf(0.0, inner.size.x - inner.size.y * 0.6), inner.size.y * 0.3))
		ci.draw_rect(hi, Color(1, 1, 1, 0.35))
	if tick >= 0.0:
		var x := r.position.x + r.size.x * clampf(tick, 0, 1)
		ci.draw_line(Vector2(x, r.position.y - 2), Vector2(x, r.end.y + 2), Color.WHITE, maxf(1.5, r.size.y * 0.18))
