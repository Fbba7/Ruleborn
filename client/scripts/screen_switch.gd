class_name ScreenSwitch
extends Control
## The design's on/off switch, drawn: a pill track, green with its knob to
## the right when on, dark with the knob left when off, and a tick or a
## stroke on the knob so the state never rests on colour (§20.8).

var on := false


static func make(state: bool) -> ScreenSwitch:
	var s := ScreenSwitch.new()
	s.on = state
	s.custom_minimum_size = Vector2(UI.px(46), UI.px(28))
	s.mouse_filter = Control.MOUSE_FILTER_IGNORE
	s.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	return s


func _draw() -> void:
	var d := ScreenDraw.new()
	var r := Rect2(Vector2.ZERO, size)
	d.polygon(ScreenBox.outline(r.grow(1.0), size.y * 0.5 + 1.0), Color("#1A0C14"))
	d.polygon(ScreenBox.outline(r.grow(-UI.px(1)), size.y * 0.5 - UI.px(1)),
		Color("#3FBF7F") if on else Color("#2A1E52"))
	var k := size.y * 0.5 - UI.px(3)
	var c := Vector2(size.x - size.y * 0.5 if on else size.y * 0.5, size.y * 0.5)
	d.circle(c + Vector2(0, UI.px(1)), k, Color(0, 0, 0, 0.35))
	d.circle(c, k, Color("#FFF6DA"))
	var mark := Color("#0A3A20") if on else Color("#4A3A6A")
	if on:
		d.outline(PackedVector2Array([c + Vector2(-k * 0.45, 0), c + Vector2(-k * 0.1, k * 0.35),
			c + Vector2(k * 0.45, -k * 0.35)]), mark, UI.px(1.4))
	else:
		d.outline(PackedVector2Array([c + Vector2(-k * 0.4, 0), c + Vector2(k * 0.4, 0)]), mark, UI.px(1.4))
	d.flush(get_canvas_item())
