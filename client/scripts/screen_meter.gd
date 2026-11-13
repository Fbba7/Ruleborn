class_name ScreenMeter
extends Control
## A progress bar or ring in the design's look (§21.8). A bar is the kit's
## `KitBar` (its track and fill drawn from the atlas), so the menu screens'
## bars match the heist's; a ring is a dark well, a fill that runs light to
## deep in its colour, an ink edge and the count in its middle. The fill
## moves to a new value easing out (`Motion.fill` for a bar, 200 ms for a
## ring), or at once under reduced motion. The count is always written
## beside or in it, so the amount never rests on the fill alone.

## "bar" or "ring".
var kind := "bar"
var value := 0.0
var most := 1.0
var colour := Color("#E9B65C")
## The words in a ring's middle.
var middle := ""
var middle_points := 15.0
var _shown := 0.0
## The kit's bar a bar is drawn with; null for a ring.
var _kit: KitBar = null


static func bar(v: float, m: float, c: Color, points := 10.0) -> ScreenMeter:
	var s := _made(v, m, c, points)
	# Gold is the kit's own fill, untinted.
	s._kit = KitBar.make(s._fraction(s.value), Color() if c == Tokens.color("gold") else c, points)
	s._kit.custom_minimum_size = Vector2.ZERO
	s._kit.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	s.add_child(s._kit)
	return s


static func ring(v: float, m: float, c: Color, points := 56.0, words := "") -> ScreenMeter:
	var s := _made(v, m, c, points)
	s.kind = "ring"
	s.middle = words
	s.custom_minimum_size = Vector2.ONE * UI.px(points)
	s.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	return s


static func _made(v: float, m: float, c: Color, points: float) -> ScreenMeter:
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


func _fraction(v: float) -> float:
	return clampf(v / maxf(most, 0.0001), 0.0, 1.0)


func set_value(v: float) -> void:
	value = v
	if _kit != null:
		Motion.fill(_kit, _fraction(v))
		return
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
	if kind == "ring":
		_draw_ring(clampf(_shown / most, 0.0, 1.0))


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
