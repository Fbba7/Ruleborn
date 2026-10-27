class_name UniverseCollect
extends Button
## The design's Collect over home's foot (§9.3): a gold pill, "COLLECT 3.4k",
## what every producer holds together, its icon on a dark disc at the left. It
## is drawn 40 points high inside its 48-point hit area (§21.1), as the
## design's 38-point pill sits over its tabs; a press sinks it onto its drop.

## The pill's drawn height, in points.
const PILL_POINTS := 40.0

## The words drawn, already in capitals.
var words := ""
var _tex: Texture2D


func _init() -> void:
	flat = true
	focus_mode = Control.FOCUS_ALL
	for state: String in ["normal", "hover", "pressed", "focus", "disabled", "hover_pressed"]:
		add_theme_stylebox_override(state, StyleBoxEmpty.new())
	_tex = Icons.texture("hud/collectall")
	resized.connect(queue_redraw)
	button_down.connect(queue_redraw)
	button_up.connect(queue_redraw)


## What the producers hold together; `spoken` says it resource by resource.
func show_amount(total: int, spoken: String) -> void:
	words = Strings.t("HOME_COLLECT_AMOUNT", UniverseHud.compact(total, 1000)).to_upper()
	accessibility_name = spoken
	var font := UniverseHud.words_font()
	var w := font.get_string_size(words, HORIZONTAL_ALIGNMENT_LEFT, -1, _px()).x
	custom_minimum_size = Vector2(w + _tall() + UI.px(22), maxf(UI.px(UI.CONTROL_POINTS), _tall() + UI.px(8)))
	queue_redraw()


func _px() -> int:
	return UI.text_px(13.0)


## The pill's height: 40 points, more where large text needs it.
func _tall() -> float:
	return maxf(UI.px(PILL_POINTS), _px() * 2.3)


func _draw() -> void:
	var h := _tall()
	var pill := Rect2(Vector2(0.0, (size.y - h) * 0.5 - UI.px(1.5)), Vector2(size.x, h))
	if is_pressed():
		pill.position.y += UI.px(2.0)
	var ci := get_canvas_item()
	# The gold body on its drop and glow, baked: one draw call.
	UniverseHud.gold_pill(h).draw(ci, pill)
	# The icon on its dark disc, then the words in dark ink.
	var inner := pill.grow(-UniverseHud.outline_px())
	var r := inner.size.y * 0.5 - UI.px(3)
	var c := Vector2(inner.position.x + UI.px(3) + r, inner.get_center().y)
	var dark := Color("#2A1622")
	UniverseHud.ball(self, c, r, [dark, dark, dark], Color(), false)
	if _tex != null:
		var s := r * 1.45
		draw_texture_rect(_tex, Rect2(c - Vector2(s, s) * 0.5, Vector2(s, s)), false)
	var font := UniverseHud.words_font()
	var px := _px()
	var x := c.x + r + UI.px(8)
	draw_string(font, Vector2(x, inner.get_center().y + font.get_ascent(px) * 0.36), words, HORIZONTAL_ALIGNMENT_LEFT,
		pill.end.x - x - UI.px(8), px, Color("#2A1A10"))
	if has_focus():
		draw_arc(c, r + UI.px(3), 0.0, TAU, 32, UniverseHud.WORDS, UI.px(2), true)
