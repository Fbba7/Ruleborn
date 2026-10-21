class_name FxPen
extends RefCounted
## The HUD's shapes in one draw call (§21.3: "under 150 draw calls"). On the
## phone renderer every circle, arc, line and polygon a canvas item draws is
## its own call, so a meter of six bells cost 36. Between `begin(ci)` and
## `end(ci)` the shapes drawn through this pen are kept as triangles with a
## colour on every corner, in the order they were drawn, and sent as one
## triangle array: the painter's order holds inside it. Words and pictures
## are drawn by the canvas as before; the triangles gathered so far go first,
## so nothing changes place in the stack.
##
## Edges are feathered by a pixel, which stands in for the canvas's
## antialiasing. Outside a `begin` every call draws straight on the canvas
## item, as it did before.

## The soft edge, in pixels.
const FEATHER := 1.0

static var _open := {}

var points := PackedVector2Array()
var colours := PackedColorArray()
var indices := PackedInt32Array()


static func begin(ci: CanvasItem) -> void:
	_open[ci.get_instance_id()] = FxPen.new()


static func end(ci: CanvasItem) -> void:
	flush(ci)
	_open.erase(ci.get_instance_id())


## Sends what is gathered for `ci` as one call.
static func flush(ci: CanvasItem) -> void:
	var pen: FxPen = _open.get(ci.get_instance_id())
	if pen == null or pen.indices.is_empty():
		return
	RenderingServer.canvas_item_add_triangle_array(ci.get_canvas_item(), pen.indices, pen.points, pen.colours)
	pen.points = PackedVector2Array()
	pen.colours = PackedColorArray()
	pen.indices = PackedInt32Array()


## How many triangles are gathered for `ci` and not yet sent; -1 when no
## pen is open on it.
static func gathered(ci: CanvasItem) -> int:
	var pen := _pen(ci)
	return -1 if pen == null else pen.indices.size() / 3


static func _pen(ci: CanvasItem) -> FxPen:
	return _open.get(ci.get_instance_id())


# -- the canvas's own calls, kept or gathered -----------------------------

static func circle(ci: CanvasItem, c: Vector2, r: float, colour: Color, filled := true, width := -1.0,
		_smooth := true) -> void:
	var pen := _pen(ci)
	if pen == null:
		ci.draw_circle(c, r, colour, filled, width, true)
		return
	if filled:
		pen.disc(c, r, colour)
	else:
		pen.stroke(ring(c, r, 0.0, TAU, _steps(r)), colour, width, true)


static func arc(ci: CanvasItem, c: Vector2, r: float, from: float, to: float, count: int, colour: Color,
		width := -1.0, _smooth := true) -> void:
	var pen := _pen(ci)
	if pen == null:
		ci.draw_arc(c, r, from, to, count, colour, width, true)
		return
	var whole := absf(to - from) >= TAU - 0.001
	var pts := ring(c, r, from, to, maxi(count, int(_steps(r) * absf(to - from) / TAU)))
	if whole:
		pts.remove_at(pts.size() - 1)
	pen.stroke(pts, colour, width, whole)


static func line(ci: CanvasItem, a: Vector2, b: Vector2, colour: Color, width := -1.0, _smooth := true) -> void:
	var pen := _pen(ci)
	if pen == null:
		ci.draw_line(a, b, colour, width, true)
		return
	pen.stroke(PackedVector2Array([a, b]), colour, width, false)


static func polyline(ci: CanvasItem, pts: PackedVector2Array, colour: Color, width := -1.0, _smooth := true) -> void:
	var pen := _pen(ci)
	if pen == null:
		ci.draw_polyline(pts, colour, width, true)
		return
	var closed := pts.size() > 2 and pts[0].distance_to(pts[pts.size() - 1]) < 0.01
	var path := PackedVector2Array(pts)
	if closed:
		path.remove_at(path.size() - 1)
	pen.stroke(path, colour, width, closed)


static func polygon(ci: CanvasItem, pts: PackedVector2Array, colour: Color) -> void:
	var pen := _pen(ci)
	if pen == null:
		ci.draw_colored_polygon(pts, colour)
		return
	pen.fill(pts, colour)


static func rect(ci: CanvasItem, r: Rect2, colour: Color, filled := true, width := -1.0) -> void:
	var pen := _pen(ci)
	if pen == null:
		ci.draw_rect(r, colour, filled, width)
		return
	var pts := PackedVector2Array([r.position, Vector2(r.end.x, r.position.y), r.end, Vector2(r.position.x, r.end.y)])
	if filled:
		pen._quad(pts, colour)
	else:
		pen.stroke(pts, colour, width, true)


## A box: a `StyleBoxFlat`'s shadow, border and fill as triangles; any other
## box is drawn by the canvas.
static func style_box(ci: CanvasItem, box: StyleBox, r: Rect2) -> void:
	var pen := _pen(ci)
	var flat := box as StyleBoxFlat
	if pen == null or flat == null:
		flush(ci)
		ci.draw_style_box(box, r)
		return
	var radius := float(flat.corner_radius_top_left)
	if flat.shadow_size > 0 and flat.shadow_color.a > 0.0:
		var s := float(flat.shadow_size)
		pen.soft(rounded(Rect2(r.position + flat.shadow_offset, r.size), radius), flat.shadow_color, s)
	var bw := float(flat.border_width_top)
	if bw > 0.0 and flat.border_color.a > 0.0:
		pen.fill(rounded(r, radius), flat.border_color)
		pen.fill(rounded(r.grow(-bw), maxf(0.0, radius - bw)), flat.bg_color)
	else:
		pen.fill(rounded(r, radius), flat.bg_color)


static func string(ci: CanvasItem, font: Font, at: Vector2, text: String, align := HORIZONTAL_ALIGNMENT_LEFT,
		width := -1.0, px := 16, colour := Color.WHITE) -> void:
	flush(ci)
	ci.draw_string(font, at, text, align, width, px, colour)


static func string_outline(ci: CanvasItem, font: Font, at: Vector2, text: String, align := HORIZONTAL_ALIGNMENT_LEFT,
		width := -1.0, px := 16, size := 1, colour := Color.WHITE) -> void:
	flush(ci)
	ci.draw_string_outline(font, at, text, align, width, px, size, colour)


static func texture_rect(ci: CanvasItem, texture: Texture2D, r: Rect2, _tile := false, colour := Color.WHITE) -> void:
	flush(ci)
	ci.draw_texture_rect(texture, r, false, colour)


# -- shapes as points ------------------------------------------------------

static func _steps(r: float) -> int:
	return clampi(int(r * 0.7), 12, 72)


## Points round a circle from `from` to `to`, both ends kept.
static func ring(c: Vector2, r: float, from: float, to: float, count: int) -> PackedVector2Array:
	var pts := PackedVector2Array()
	var n := maxi(2, count)
	for i in n + 1:
		var a := from + (to - from) * float(i) / n
		pts.append(c + Vector2(cos(a), sin(a)) * r)
	return pts


## A rounded rectangle's outline, clockwise on screen.
static func rounded(r: Rect2, radius: float) -> PackedVector2Array:
	var k := minf(radius, minf(r.size.x, r.size.y) * 0.5)
	if k < 0.5:
		return PackedVector2Array([r.position, Vector2(r.end.x, r.position.y), r.end, Vector2(r.position.x, r.end.y)])
	var pts := PackedVector2Array()
	var n := clampi(int(k * 0.5), 3, 10)
	var corners: Array[Vector2] = [Vector2(r.end.x - k, r.position.y + k), Vector2(r.end.x - k, r.end.y - k),
		Vector2(r.position.x + k, r.end.y - k), Vector2(r.position.x + k, r.position.y + k)]
	for q in 4:
		var start := -PI / 2.0 + q * PI / 2.0
		for i in n + 1:
			var a := start + PI / 2.0 * float(i) / n
			pts.append(corners[q] + Vector2(cos(a), sin(a)) * k)
	return pts


# -- gathering triangles ---------------------------------------------------

func _add(p: Vector2, colour: Color) -> int:
	points.append(p)
	colours.append(colour)
	return points.size() - 1


func _tri(a: int, b: int, c: int) -> void:
	indices.append(a)
	indices.append(b)
	indices.append(c)


func _quad(pts: PackedVector2Array, colour: Color) -> void:
	var i := _add(pts[0], colour)
	_add(pts[1], colour)
	_add(pts[2], colour)
	_add(pts[3], colour)
	_tri(i, i + 1, i + 2)
	_tri(i, i + 2, i + 3)


func disc(c: Vector2, r: float, colour: Color) -> void:
	var pts := ring(c, r, 0.0, TAU, _steps(r))
	pts.remove_at(pts.size() - 1)
	fill(pts, colour)


## A filled outline, feathered outward by a pixel.
func fill(pts: PackedVector2Array, colour: Color) -> void:
	var n := pts.size()
	if n < 3:
		return
	var tris := Geometry2D.triangulate_polygon(pts)
	var base := points.size()
	for p in pts:
		_add(p, colour)
	if tris.is_empty():
		for i in range(1, n - 1):
			_tri(base, base + i, base + i + 1)
	else:
		for t in tris:
			indices.append(base + t)
	_feather(pts, base, colour, FEATHER)


## A soft shape: filled, with an edge `spread` wide fading to nothing.
func soft(pts: PackedVector2Array, colour: Color, spread: float) -> void:
	var base := points.size()
	var inner := _offset(pts, -spread * 0.5)
	for p in inner:
		_add(p, colour)
	var tris := Geometry2D.triangulate_polygon(inner)
	for t in tris:
		indices.append(base + t)
	_feather(inner, base, colour, spread)


## An edge of `width` along `pts` from the outline whose points start at
## `base`, its colour falling to clear.
func _feather(pts: PackedVector2Array, base: int, colour: Color, width: float) -> void:
	var n := pts.size()
	var out := _offset(pts, width)
	var clear := Color(colour, 0.0)
	var o := points.size()
	for p in out:
		_add(p, clear)
	for i in n:
		var j := (i + 1) % n
		_tri(base + i, base + j, o + j)
		_tri(base + i, o + j, o + i)


## The outline moved `by` pixels outward (inward when negative), by the
## normal at each corner.
static func _offset(pts: PackedVector2Array, by: float) -> PackedVector2Array:
	var n := pts.size()
	var area := 0.0
	for i in n:
		area += pts[i].cross(pts[(i + 1) % n])
	var sign_out := 1.0 if area > 0.0 else -1.0
	var out := PackedVector2Array()
	for i in n:
		var a := pts[(i - 1 + n) % n]
		var b := pts[i]
		var c := pts[(i + 1) % n]
		var n1 := (b - a).orthogonal().normalized() * -sign_out
		var n2 := (c - b).orthogonal().normalized() * -sign_out
		var m := (n1 + n2)
		if m.length_squared() < 0.0001:
			m = n1
		m = m.normalized()
		var k := clampf(1.0 / maxf(0.25, m.dot(n1)), 1.0, 3.0)
		out.append(b + m * by * k)
	return out


## A line `width` wide along `pts` (closed when asked), mitred at corners and
## feathered on both sides.
func stroke(pts: PackedVector2Array, colour: Color, width: float, closed: bool) -> void:
	var n := pts.size()
	if n < 2:
		return
	var h := maxf(0.5, (width if width > 0.0 else 1.0) * 0.5)
	var clear := Color(colour, 0.0)
	var base := points.size()
	for i in n:
		var b := pts[i]
		var dir_in := Vector2.ZERO
		var dir_out := Vector2.ZERO
		if i > 0 or closed:
			dir_in = (b - pts[(i - 1 + n) % n]).normalized()
		if i < n - 1 or closed:
			dir_out = (pts[(i + 1) % n] - b).normalized()
		var d := dir_in + dir_out
		if d.length_squared() < 0.0001:
			d = dir_out if dir_out != Vector2.ZERO else dir_in
		d = d.normalized()
		var normal := d.orthogonal()
		var k := 1.0
		if dir_in != Vector2.ZERO and dir_out != Vector2.ZERO:
			k = clampf(1.0 / maxf(0.3, normal.dot(dir_in.orthogonal())), 1.0, 2.5)
		_add(b + normal * (h + FEATHER) * k, clear)
		_add(b + normal * h * k, colour)
		_add(b - normal * h * k, colour)
		_add(b - normal * (h + FEATHER) * k, clear)
	var segments := n if closed else n - 1
	for i in segments:
		var a := base + i * 4
		var b := base + ((i + 1) % n) * 4
		for s in 3:
			_tri(a + s, b + s, b + s + 1)
			_tri(a + s, b + s + 1, a + s + 1)
