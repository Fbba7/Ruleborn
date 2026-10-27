class_name ScreenMeter
extends Control
## A progress bar or ring in the design's look (§21.8): a dark well, a fill
## that runs light to deep in its colour, an ink edge, and for a ring the
## count in its middle. The fill moves to a new value in 200 ms, easing out,
## or at once under reduced motion. The count is always written beside or in
## it, so the amount never rests on the fill alone.

## "bar" or "ring".
var kind := "bar"
var value := 0.0
var most := 1.0
var colour := Color("#E9B65C")
## The words in a ring's middle.
var middle := ""
var middle_points := 15.0
var _shown := 0.0


static func bar(v: float, m: float, c: Color, points := 10.0) -> ScreenMeter:
	var s := ScreenMeter.new()
	s.value = v
	s.most = maxf(m, 0.0001)
	s.colour = c
	s.custom_minimum_size = Vector2(UI.px(24), UI.px(points))
	s.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	s.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	s._shown = s.value
	s.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return s


static func ring(v: float, m: float, c: Color, points := 56.0, words := "") -> ScreenMeter:
	var s := bar(v, m, c, points)
	s.kind = "ring"
	s.middle = words
	s.custom_minimum_size = Vector2.ONE * UI.px(points)
	s.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	return s


func set_value(v: float) -> void:
	value = v
	if not is_inside_tree() or Settings.reduced_motion:
		_shown = v
		queue_redraw()
		return
	var t := create_tween()
	t.set_ease(Tween.EASE_OUT)
	t.set_trans(Tween.TRANS_CUBIC)
	t.tween_method(func(x: float) -> void:
		_shown = x
		queue_redraw(), _shown, v, 0.2)


func _draw() -> void:
	var f := clampf(_shown / most, 0.0, 1.0)
	if kind == "ring":
		_draw_ring(f)
		return
	var h := size.y
	var r := Rect2(Vector2.ZERO, size)
	var b := ScreenBox.new()
	b.top = Color("#0A0618")
	b.bottom = Color("#1E1440")
	b.radius = -1.0
	b.line = Color("#1A0C14")
	b.line_px = maxf(1.0, UI.px(0.7))
	b.draw(get_canvas_item(), r)
	if f <= 0.0:
		return
	var fill := ScreenBox.new()
	fill.top = colour.lightened(0.35)
	fill.mid = colour
	fill.mid_at = 0.45
	fill.bottom = colour.darkened(0.25)
	fill.radius = -1.0
	fill.gloss = Color(1, 1, 1, 0.35)
	fill.gloss_px = maxf(1.0, h * 0.18)
	fill.draw(get_canvas_item(), Rect2(Vector2.ZERO, Vector2(maxf(h, size.x * f), h)))


func _draw_ring(f: float) -> void:
	var c := size / 2.0
	var w := maxf(UI.px(5), size.x * 0.12)
	var r := size.x / 2.0 - 1.0
	var d := ScreenDraw.new()
	d.circle(c, r, Color("#1A0C14"), 40)
	d.arc(c, r - w - 2.0, r - 2.0, 0, TAU, Color("#2A1E52"), 40)
	if f > 0.0:
		var n := maxi(6, int(48 * f))
		d.arc(c, r - w - 2.0, r - 2.0, -PI / 2.0, -PI / 2.0 + TAU * f, colour, n)
		d.arc(c, r - w * 0.45, r - 2.0, -PI / 2.0, -PI / 2.0 + TAU * f, colour.lightened(0.4), n)
	d.circle(c, r - w - 2.0, Color("#1A1134"), 40)
	d.flush(get_canvas_item())
	if middle != "":
		var font := ScreenKit.font("number")
		var fs := UI.text_px(middle_points)
		var sz := font.get_string_size(middle, HORIZONTAL_ALIGNMENT_CENTER, -1, fs)
		var at := Vector2(c.x - sz.x / 2.0, c.y + font.get_ascent(fs) * 0.5 - font.get_descent(fs) * 0.2)
		draw_string(font, at, middle, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color("#F3EEFF"))
