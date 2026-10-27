class_name StageHeroHex
extends Control
## The design's level hexagon: a gold six-sided plate, outlined in ink with
## a brown inner rim and a hard lip beneath, a number in Lilita One over it
## and a small word above the number ("LV").

var number := ""
var word := ""
var fill := Color("#E9B65C")


static func make(text: String, above: String, points := 56.0, colour := Color("#E9B65C")) -> StageHeroHex:
	var x := StageHeroHex.new()
	x.number = text
	x.word = above
	x.fill = colour
	x.custom_minimum_size = Vector2(UI.px(points * 0.92), UI.px(points))
	x.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	x.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	x.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return x


func _hexagon(centre: Vector2, radius: float) -> PackedVector2Array:
	var out := PackedVector2Array()
	for i: int in 6:
		var a := TAU * float(i) / 6.0 + PI / 6.0
		out.append(centre + Vector2(cos(a) * radius * 0.92, sin(a) * radius))
	return out


func _draw() -> void:
	var lip := float(UI.px(3))
	var radius := (size.y - lip) / 2.0
	var c := Vector2(size.x / 2.0, radius)
	var line := float(StageHeroSkin.edge_px())
	draw_colored_polygon(_hexagon(c + Vector2(0, lip), radius), Color("#4A2A10"))
	draw_colored_polygon(_hexagon(c, radius), StageHeroSkin.OUTLINE)
	draw_colored_polygon(_hexagon(c, radius - line), Color("#6B4420"))
	var face := _hexagon(c, radius - line - UI.px(1.5))
	var colours := PackedColorArray()
	for p: Vector2 in face:
		colours.append(fill.lightened(0.35) if p.y < c.y else fill.darkened(0.12))
	draw_polygon(face, colours)
	var font := StageHeroSkin.numbers_font()
	var big := UI.text_px(radius / UI.PX_PER_POINT * 0.95)
	var small := maxi(UI.px(9), int(big * 0.36))
	var ink := Color("#3A200C")
	if word != "":
		draw_string(font, Vector2(0, c.y - radius * 0.28), word, HORIZONTAL_ALIGNMENT_CENTER, size.x, small, ink)
	var base := c.y + big * (0.5 if word != "" else 0.36)
	draw_string_outline(font, Vector2(0, base), number, HORIZONTAL_ALIGNMENT_CENTER, size.x, big, UI.px(2),
		Color("#FFF3CC"))
	draw_string(font, Vector2(0, base), number, HORIZONTAL_ALIGNMENT_CENTER, size.x, big, ink)
