class_name ScreenBox
extends StyleBox
## One of the design's materials (§21.8) as a style box any control can wear:
## a vertical gradient of up to three stops, a soft shadow, a hard drop under
## it (the design's toy depth), an ink outline, an inner rim and a gloss along
## the top. StyleBoxFlat draws none of the gradient, the rim or the gloss, so
## this draws them itself, as untextured triangles that batch together.

const STEPS := 6

## The fill, top to bottom; `mid_at` is where the middle stop sits (0..1).
var top := Color("#261A4C")
var mid := Color()
var mid_at := 0.46
var bottom := Color("#1A1134")
## Corner radius in pixels; a negative radius is half the height (a pill).
var radius := 36.0
## The ink outline drawn round the outside.
var line := Color("#1A0C14")
var line_px := 0.0
## An inner rim, drawn inset by the outline's width.
var rim := Color(0, 0, 0, 0)
var rim_px := 0.0
## A second, inner rim inside the first (the active tab's gold-then-brown).
var rim2 := Color(0, 0, 0, 0)
var rim2_px := 0.0
## A light band along the top inside (the design's inset top highlight).
var gloss := Color(1, 1, 1, 0.0)
var gloss_px := 0.0
## The hard drop under the box, in pixels down, and its colour.
var drop_px := 0.0
var drop := Color("#0A0408")
## A soft shadow (or a glow, centred, when `shadow_y` is 0).
var shadow := Color(0, 0, 0, 0)
var shadow_px := 0.0
var shadow_y := 0.0
## Moves the whole box down, for a pressed control sinking onto its drop.
var sink_px := 0.0

var _pts := PackedVector2Array()
var _cols := PackedColorArray()
var _idx := PackedInt32Array()


func _draw(to_canvas_item: RID, rect: Rect2) -> void:
	_pts = PackedVector2Array()
	_cols = PackedColorArray()
	_idx = PackedInt32Array()
	var r := rect
	r.position.y += sink_px
	var rad := _radius(r)
	if shadow.a > 0.0 and shadow_px > 0.0:
		for i: int in 3:
			var grow := shadow_px * float(i + 1) / 3.0
			var c := Color(shadow, shadow.a * 0.4 * (1.0 - float(i) / 3.0))
			var sr := r.grow(grow)
			sr.position.y += shadow_y
			_fill(sr, rad + grow, c, c, c)
	if drop_px > sink_px:
		var dr := r
		dr.position.y += drop_px - sink_px
		_fill(dr.grow(line_px), rad + line_px, drop, drop, drop)
	if line_px > 0.0 and line.a > 0.0:
		_fill(r.grow(line_px), rad + line_px, line, line, line)
	_fill(r, rad, top, mid if mid.a > 0.0 else Color(0, 0, 0, 0), bottom)
	if gloss.a > 0.0 and gloss_px > 0.0:
		var g := Rect2(r.position + Vector2(rad * 0.5, maxf(rim_px, 1.0)), Vector2(r.size.x - rad, gloss_px))
		if g.size.x > 0.0:
			_fill(g, gloss_px * 0.5, gloss, gloss, Color(gloss, 0.0))
	if rim_px > 0.0 and rim.a > 0.0:
		_ring(r, rad, rim, rim_px)
	if rim2_px > 0.0 and rim2.a > 0.0:
		_ring(r.grow(-rim_px), maxf(rad - rim_px, 0.0), rim2, rim2_px)
	if not _idx.is_empty():
		RenderingServer.canvas_item_add_triangle_array(to_canvas_item, _idx, _pts, _cols)


func _get_draw_rect(rect: Rect2) -> Rect2:
	return rect.grow(line_px + shadow_px).grow_side(SIDE_BOTTOM, drop_px + shadow_y)


func _radius(r: Rect2) -> float:
	var most := minf(r.size.x, r.size.y) * 0.5
	return most if radius < 0.0 else minf(radius, most)


## The outline of a rounded rectangle, clockwise from the top left.
static func outline(r: Rect2, rad: float) -> PackedVector2Array:
	var pts := PackedVector2Array()
	var corners := [Vector2(r.position.x + rad, r.position.y + rad), Vector2(r.end.x - rad, r.position.y + rad),
		Vector2(r.end.x - rad, r.end.y - rad), Vector2(r.position.x + rad, r.end.y - rad)]
	for k: int in 4:
		var start := PI + k * PI * 0.5
		for s: int in STEPS + 1:
			var a := start + PI * 0.5 * float(s) / float(STEPS)
			pts.append((corners[k] as Vector2) + Vector2(cos(a), sin(a)) * rad)
	return pts


## A rounded rectangle filled with a vertical gradient, built as horizontal
## bands so the middle stop lands exactly where it is set.
func _fill(r: Rect2, rad: float, c0: Color, c1: Color, c2: Color) -> void:
	if r.size.x <= 0.0 or r.size.y <= 0.0 or c0.a <= 0.0 and c1.a <= 0.0 and c2.a <= 0.0:
		return
	rad = minf(rad, minf(r.size.x, r.size.y) * 0.5)
	var ys: Array[float] = []
	for s: int in STEPS + 1:
		var a := PI * 0.5 * float(s) / float(STEPS)
		ys.append(r.position.y + rad - sin(PI * 0.5 - a) * rad)
		ys.append(r.end.y - rad + sin(a) * rad)
	if c1.a > 0.0:
		ys.append(r.position.y + r.size.y * mid_at)
	ys.sort()
	var base := _pts.size()
	var last := -INF
	for y: float in ys:
		if y - last < 0.01:
			continue
		last = y
		var inset := 0.0
		if y < r.position.y + rad:
			var dy := r.position.y + rad - y
			inset = rad - sqrt(maxf(rad * rad - dy * dy, 0.0))
		elif y > r.end.y - rad:
			var dy2 := y - (r.end.y - rad)
			inset = rad - sqrt(maxf(rad * rad - dy2 * dy2, 0.0))
		var t := (y - r.position.y) / r.size.y
		var c := _at(t, c0, c1, c2)
		var n := _pts.size()
		_pts.append(Vector2(r.position.x + inset, y))
		_pts.append(Vector2(r.end.x - inset, y))
		_cols.append(c)
		_cols.append(c)
		if n - base >= 2:
			_idx.append_array([n - 2, n - 1, n, n - 1, n + 1, n])


func _at(t: float, c0: Color, c1: Color, c2: Color) -> Color:
	if c1.a <= 0.0:
		return c0.lerp(c2, clampf(t, 0.0, 1.0))
	if t <= mid_at:
		return c0.lerp(c1, clampf(t / mid_at, 0.0, 1.0))
	return c1.lerp(c2, clampf((t - mid_at) / (1.0 - mid_at), 0.0, 1.0))


## A line of `px` drawn just inside a rounded rectangle's edge, as a strip
## of quads between its outer and inner outlines.
func _ring(r: Rect2, rad: float, c: Color, px: float) -> void:
	var outer := outline(r, rad)
	var inner := outline(r.grow(-px), maxf(rad - px, 0.0))
	var base := _pts.size()
	var n := outer.size()
	for i: int in n:
		_pts.append(outer[i])
		_pts.append(inner[i])
		_cols.append(c)
		_cols.append(c)
	for i: int in n:
		var a := base + i * 2
		var b := base + ((i + 1) % n) * 2
		_idx.append_array([a, a + 1, b, a + 1, b + 1, b])
