class_name KitRule
extends Control
## The designs' gold rule under a title: two hairlines fading out from a
## small diamond in the middle.


func _draw() -> void:
	var gold := Tokens.color("gold")
	var mid := size * 0.5
	var d := UI.px(3.5)
	var line := maxf(1.0, UI.px(0.75))
	var steps := 12
	for side: int in [-1, 1]:
		for i: int in steps:
			var a := float(i) / steps
			var b := float(i + 1) / steps
			var from := mid + Vector2(side * (d * 1.8 + a * (mid.x - d * 1.8)), 0)
			var to := mid + Vector2(side * (d * 1.8 + b * (mid.x - d * 1.8)), 0)
			draw_line(from, to, Color(gold, 0.9 * (1.0 - a)), line, true)
	var diamond := PackedVector2Array([mid + Vector2(0, -d), mid + Vector2(d, 0), mid + Vector2(0, d),
		mid + Vector2(-d, 0)])
	draw_colored_polygon(diamond, gold)
	diamond.append(diamond[0])
	draw_polyline(diamond, Tokens.color("ink_line"), maxf(1.0, UI.px(0.5)), true)
