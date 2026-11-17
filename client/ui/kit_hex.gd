class_name KitHex
extends Control
## A gold hexagon with words in it (the Character screen's level badge,
## "LV 5"): a small kicker over a big number, the hexagon edged in ink.

## The height, in points, a hexagon's 11- and 22-point words are set for at
## 100% text.
const WORDS_POINTS := 52.0

var kicker := ""
var number := ""


## A hexagon `points` tall saying `kicker` over `number`. It grows with the
## player's text as its words do (S3-R12), so "LV", "NV" and "ST" stay inside
## it at 200%: `points` at 100%, and never less than the 52 points its words
## are set for, scaled, so a caller that grows it itself is not grown twice.
static func make(kicker_words: String, number_words: String, points := 52.0) -> KitHex:
	var h := KitHex.new()
	h.name = "Hex"
	h.kicker = kicker_words
	h.number = number_words
	var grown := maxf(points, minf(points, WORDS_POINTS) * float(UI.text_px(22)) / UI.px(22))
	h.custom_minimum_size = Vector2(UI.px(grown * 0.88), UI.px(grown))
	h.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return h


## Whether the kicker's and the number's lines lie inside the hexagon at its
## size: each line, as wide as its words, within the hexagon's width at the
## top and the foot of its letters' ink.
func words_inside() -> bool:
	var c := size * 0.5
	var r := minf(size.x / 1.732, size.y * 0.5)
	var k := UI.text_px(11)
	var n := UI.text_px(22)
	var lines := [[Tokens.font("ui", 800), kicker, k, c.y - n * 0.35], [Tokens.font("display"), number, n,
		c.y + n * 0.55]]
	for line: Array in lines:
		var font := line[0] as Font
		var points := int(line[2])
		var words := str(line[1])
		var wide := font.get_string_size(words, HORIZONTAL_ALIGNMENT_LEFT, -1, points).x
		var ink := _ink(font, words, points)
		for y: float in [float(line[3]) + ink.x, float(line[3]) + ink.y]:
			if wide > _width_at(absf(y - c.y), r):
				return false
	return true


## How far above (negative) and below its baseline `words`' ink reaches in
## `font` at `points` pixels: [top, foot].
static func _ink(font: Font, words: String, points: int) -> Vector2:
	var ts := TextServerManager.get_primary_interface()
	var ink := Vector2(INF, -INF)
	var rid: RID = font.get_rids()[0]
	for ch: String in words:
		var glyph := ts.font_get_glyph_index(rid, points, ch.unicode_at(0), 0)
		var top := ts.font_get_glyph_offset(rid, Vector2i(points, 0), glyph).y
		ink = Vector2(minf(ink.x, top), maxf(ink.y, top + ts.font_get_glyph_size(rid, Vector2i(points, 0), glyph).y))
	return ink if ink.x <= ink.y else Vector2.ZERO


## The pointed-top hexagon's width `dy` from its centre, its corners `r` out.
static func _width_at(dy: float, r: float) -> float:
	if dy >= r:
		return 0.0
	return 1.732 * r if dy <= r * 0.5 else 2.0 * 1.732 * (r - dy)


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
