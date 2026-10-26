class_name ScreenThread
extends Control
## The design's thread between a tapestry's slots: a dashed gold line across
## the gems' middle, solid where both ends hold a law.

var solid := false
## Where the line runs, from the top, in pixels.
var at := 0.0


static func make(height: float, both_woven: bool) -> ScreenThread:
	var t := ScreenThread.new()
	t.solid = both_woven
	t.at = height * 0.5
	t.custom_minimum_size = Vector2(UI.px(12), height)
	t.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	t.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	t.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return t


func _draw() -> void:
	var gold := Color("#E9B65C")
	var w := maxf(1.0, UI.px(1.5))
	if solid:
		draw_line(Vector2(0, at), Vector2(size.x, at), gold, w)
		return
	var dash := UI.px(5)
	var x := 0.0
	while x < size.x:
		draw_line(Vector2(x, at), Vector2(minf(x + dash, size.x), at), Color(gold, 0.8), w)
		x += dash * 2.0
