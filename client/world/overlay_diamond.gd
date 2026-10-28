class_name OverlayDiamond
extends Control
## The design's small gold diamond over a building on the realm view, with
## the building's level in it: a mark that reads at the home camera without
## covering the town as a round badge does.

const POINTS := 26.0

var words := ""


func _init(text: String) -> void:
	words = text
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	custom_minimum_size = Vector2.ONE * UI.px(POINTS)
	accessibility_name = text


func _draw() -> void:
	var c := size / 2.0
	var r := minf(size.x, size.y) / 2.0
	var pts := PackedVector2Array([c + Vector2(0, -r), c + Vector2(r, 0), c + Vector2(0, r), c + Vector2(-r, 0)])
	draw_colored_polygon(pts, Tokens.color("gold"))
	pts.append(pts[0])
	draw_polyline(pts, Tokens.color("ink_deep"), UI.px(2), true)
	var font := UI.bold_font()
	var px := UI.text_px(13)
	var w := font.get_string_size(words, HORIZONTAL_ALIGNMENT_LEFT, -1, px).x
	draw_string(font, c + Vector2(-w / 2.0, px * 0.36), words, HORIZONTAL_ALIGNMENT_LEFT, -1, px,
		Tokens.color("text_on_gold"))
