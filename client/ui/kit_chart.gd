class_name KitChart
extends Control
## A line over time (19b Player stats' Renown): faint rules at `rules` with
## their values at the left, the area under the line in a gold that fades to
## nothing, the line in gold, and today's point as a cream dot on a dashed
## rule; the first and last days written under it. One control, drawn in a
## few calls (`KitTris` for the area); a screen reader hears `spoken` (§20.8:
## the numbers are said, never left to the line).

## The values, oldest first; the rules' values and their words ("1,450").
var values: Array[float] = []
var rules: Array[float] = []
var rule_words: Array[String] = []
## The words under the first and last day ("Sep 28", "Today").
var first_words := ""
var last_words := ""


## A chart of `points` with rules at `at` ([value, words] each, the words as
## the screen writes its numbers), labelled `from` and `to` beneath;
## `spoken` says what it shows.
static func make(points: Array, at: Array, from: String, to: String, spoken: String, height := 150.0) -> KitChart:
	var c := KitChart.new()
	c.name = "Chart"
	for v: Variant in points:
		c.values.append(float(v))
	for r: Variant in at:
		c.rules.append(float((r as Array)[0]))
		c.rule_words.append(str((r as Array)[1]))
	c.first_words = from
	c.last_words = to
	c.accessibility_name = spoken
	c.custom_minimum_size = Vector2(UI.px(200), UI.px(height) + UI.text_px(13) * 1.6)
	c.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return c


func _draw() -> void:
	if values.size() < 2:
		return
	var face := Tokens.font("ui", 700)
	var px := UI.text_px(13)
	var soft := Tokens.color("text_on_night_2")
	var gold := Tokens.color("gold")
	# Room for the rules' values at the left and the days beneath.
	var left := 0.0
	for words: String in rule_words:
		left = maxf(left, face.get_string_size(words, HORIZONTAL_ALIGNMENT_LEFT, -1, px).x)
	left += UI.px(8)
	var foot := px * 1.6
	var area := Rect2(left, UI.px(8), size.x - left - UI.px(10), size.y - foot - UI.px(8))
	var low := values.min() as float
	var high := values.max() as float
	for r: float in rules:
		low = minf(low, r)
		high = maxf(high, r)
	var span := maxf(high - low, 1.0)
	var at := func(i: int, v: float) -> Vector2:
		return Vector2(area.position.x + area.size.x * i / float(values.size() - 1),
			area.end.y - area.size.y * (v - low) / span)
	for k: int in rules.size():
		var y: float = (at.call(0, rules[k]) as Vector2).y
		draw_line(Vector2(area.position.x, y), Vector2(area.end.x, y), Color(soft, 0.18), maxf(1.0, UI.px(0.5)))
		draw_string(face, Vector2(0, y + face.get_ascent(px) * 0.4), rule_words[k], HORIZONTAL_ALIGNMENT_LEFT, -1, px,
			soft)
	# The area under the line, gold at the line fading to nothing at the
	# foot: one array of triangles.
	var fill := KitTris.new()
	var line := PackedVector2Array()
	for i: int in values.size():
		var p: Vector2 = at.call(i, values[i])
		line.append(p)
		fill.points.append(p)
		fill.colours.append(Color(gold, 0.28))
		fill.points.append(Vector2(p.x, area.end.y))
		fill.colours.append(Color(gold, 0.0))
	for i: int in values.size() - 1:
		var a := 2 * i
		fill.order.append_array([a, a + 2, a + 1, a + 1, a + 2, a + 3])
	fill.draw_on(get_canvas_item())
	draw_polyline(line, gold, maxf(2.0, UI.px(2.2)), true)
	var now := line[line.size() - 1]
	draw_dashed_line(Vector2(now.x, area.position.y - UI.px(6)), Vector2(now.x, area.end.y), Color(soft, 0.5),
		maxf(1.0, UI.px(0.6)), UI.px(3))
	draw_circle(now, UI.px(5.5), Tokens.color("ink_line"), true, -1.0, true)
	draw_circle(now, UI.px(4), Tokens.color("cream"), true, -1.0, true)
	var base := size.y - foot * 0.3
	draw_string(face, Vector2(area.position.x, base), first_words, HORIZONTAL_ALIGNMENT_LEFT, -1, px, soft)
	var w := face.get_string_size(last_words, HORIZONTAL_ALIGNMENT_LEFT, -1, px).x
	draw_string(face, Vector2(area.end.x - w, base), last_words, HORIZONTAL_ALIGNMENT_LEFT, -1, px, soft)

