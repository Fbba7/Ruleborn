class_name KitHex
extends Control
## A gold hexagon with words in it (the Character screen's level badge,
## "LV 5"): a small kicker over a big number, the hexagon edged in ink.

var kicker := ""
var number := ""


## A hexagon `points` tall saying `kicker` over `number`.
static func make(kicker_words: String, number_words: String, points := 52.0) -> KitHex:
	var h := KitHex.new()
	h.name = "Hex"
	h.kicker = kicker_words
	h.number = number_words
	h.custom_minimum_size = Vector2(UI.px(points * 0.88), UI.px(points))
	h.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return h


func _draw() -> void:
	var c := size * 0.5
	var r := minf(size.x / 1.732, size.y * 0.5)
	var pts := PackedVector2Array()
	for i: int in 6:
		var a := PI / 3.0 * i - PI / 2.0
		pts.append(c + Vector2(cos(a), sin(a)) * r)
	var drop := PackedVector2Array()
	for p: Vector2 in pts:
		drop.append(p + Vector2(0, UI.px(2)))
	draw_colored_polygon(drop, Tokens.color("gold_drop"))
	draw_colored_polygon(pts, Tokens.color("ink_line"))
	var inner := PackedVector2Array()
	var colours := PackedColorArray()
	for p: Vector2 in pts:
		inner.append(c + (p - c) * (1.0 - UI.px(1.5) / r))
		colours.append(Tokens.color("gold_top").lerp(Tokens.color("gold_bottom"), (p.y - (c.y - r)) / (2.0 * r)))
	draw_polygon(inner, colours)
	var font := Tokens.font("ui", 800)
	var ink := Tokens.color("text_on_gold")
	var k := UI.text_px(11)
	var n := UI.text_px(22)
	draw_string(font, Vector2(0, c.y - n * 0.35), kicker, HORIZONTAL_ALIGNMENT_CENTER, size.x, k, ink)
	draw_string(Tokens.font("display"), Vector2(0, c.y + n * 0.55), number, HORIZONTAL_ALIGNMENT_CENTER, size.x, n, ink)
