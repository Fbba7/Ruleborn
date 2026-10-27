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
	var sink := float(UI.px(2.0)) if is_pressed() else 0.0
	var ci := get_canvas_item()
	# Its warm glow and hard drop on the world, then the gold body in ink.
	var glow := UniverseHud.plate(Color(0, 0, 0, 0), h * 0.5)
	glow.border_color = Color(0, 0, 0, 0)
	glow.shadow_color = Color(UniverseHud.GOLD[1], 0.0 if Settings.high_contrast else 0.4)
	glow.shadow_size = UI.px(9)
	glow.shadow_offset = Vector2.ZERO
	glow.draw(ci, pill)
	pill.position.y += sink
	var body := UniverseHud.plate(UniverseHud.GOLD[1], h * 0.5, UniverseHud.GOLD_DROP)
	body.shadow_offset = Vector2(0, UI.px(3.0) - sink)
	body.draw(ci, pill)
	# The design's light from above and shade below: a cream crown and a
	# deeper foot inside the ink.
	var inner := pill.grow(-UniverseHud.outline_px())
	var crown := StyleBoxFlat.new()
	crown.bg_color = Color(UniverseHud.GOLD[0], 0.55)
	crown.set_corner_radius_all(int(inner.size.y * 0.5))
	crown.anti_aliasing = true
	crown.draw(ci, Rect2(inner.position + Vector2(inner.size.y * 0.3, UI.px(1.5)),
		Vector2(inner.size.x - inner.size.y * 0.6, inner.size.y * 0.42)))
	draw_line(Vector2(inner.position.x + inner.size.y * 0.45, inner.end.y - UI.px(2)),
		Vector2(inner.end.x - inner.size.y * 0.45, inner.end.y - UI.px(2)), Color(0.55, 0.28, 0.04, 0.35), UI.px(3))
	# The icon on its dark disc, then the words in dark ink.
	var r := inner.size.y * 0.5 - UI.px(3)
	var c := Vector2(inner.position.x + UI.px(3) + r, inner.get_center().y)
	draw_circle(c, r, Color("#2A1622"), true, -1.0, true)
	if _tex != null:
		var s := r * 1.45
		draw_texture_rect(_tex, Rect2(c - Vector2(s, s) * 0.5, Vector2(s, s)), false)
	var font := UniverseHud.words_font()
	var px := _px()
	var x := c.x + r + UI.px(8)
	draw_string(font, Vector2(x, inner.get_center().y + font.get_ascent(px) * 0.36), words, HORIZONTAL_ALIGNMENT_LEFT,
		pill.end.x - x - UI.px(8), px, Color("#2A1A10"))
	if has_focus():
		var ring := UniverseHud.glass(h * 0.5 + UI.px(3))
		ring.draw_center = false
		ring.border_color = UniverseHud.WORDS
		ring.shadow_size = 0
		ring.draw(ci, pill.grow(UI.px(3)))
