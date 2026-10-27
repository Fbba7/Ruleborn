class_name ScreenBands
extends Control
## §5.5's seven stability bands as the design's gauge: a bar of seven cells
## in the bands' colours, Quiet to Breaking, with a marker over the strain.
## The band's name is always written beside it; this is never the only sign.

## The design's band colours (Screens v3), Quiet to Breaking.
const COLOURS := [Color("#7A6E86"), Color("#5CC46A"), Color("#3CC6D8"), Color("#E9B65C"), Color("#F07A3C"),
	Color("#E2536B"), Color("#9C2A4A")]

var band := 0
## Where the marker sits along the bar, 0..1.
var at := 0.0


static func make(b: int, strain: float) -> ScreenBands:
	var s := ScreenBands.new()
	s.band = b
	s.at = clampf(strain, 0.0, 1.0)
	s.custom_minimum_size = Vector2(UI.px(100), UI.px(24))
	s.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	s.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return s


func _draw() -> void:
	var d := ScreenDraw.new()
	var h := size.y * 0.5
	var top := size.y * 0.35
	var gap := UI.px(1.5)
	var w := (size.x - gap * 6.0) / 7.0
	var outline := Rect2(Vector2(-2, top - 2), Vector2(size.x + 4, h + 4))
	d.polygon(ScreenBox.outline(outline, (h + 4) * 0.5), Color("#1A0C14"))
	for i: int in 7:
		var r := Rect2(Vector2(i * (w + gap), top), Vector2(w, h))
		var c: Color = COLOURS[i]
		if i != band:
			c = c.darkened(0.45)
		d.polygon(ScreenBox.outline(r, minf(h * 0.5, UI.px(4))), c)
		d.polygon(ScreenBox.outline(Rect2(r.position + Vector2(2, 2), Vector2(w - 4, h * 0.3)), h * 0.15),
			Color(1, 1, 1, 0.25 if i == band else 0.08))
	var x := clampf(at * size.x, UI.px(4), size.x - UI.px(4))
	var m := PackedVector2Array([Vector2(x - UI.px(5), 0), Vector2(x + UI.px(5), 0), Vector2(x, top + UI.px(3))])
	d.outline(m, Color("#1A0C14"), UI.px(1.5))
	d.polygon(m, Color("#FFF3CC"))
	d.flush(get_canvas_item())
