class_name KitTicks
extends Control
## Segment ticks across a bar (the experience bar), as ink hairlines.

var count := 8


func _draw() -> void:
	var ink := Color(Tokens.color("ink_line"), 0.45)
	for i: int in range(1, count):
		var x := size.x * i / count
		draw_line(Vector2(x, size.y * 0.22), Vector2(x, size.y * 0.78), ink, maxf(1.0, UI.px(0.6)))
