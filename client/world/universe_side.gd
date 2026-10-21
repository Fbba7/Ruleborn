class_name UniverseSide
extends Button
## A side button down home's edges (§21.8's home layout), as the designs draw
## them: a leather ball rimmed in bronze with the screen's icon, its name on a
## dark plate beneath, and a red count badge when there is something to see
## there, its number written so it never rests on colour alone (§20.8). It
## squashes slightly when pressed (§21.8's motion).

var icon_name := ""
var words := ""
## The badge's number or glyph; "" for none.
var count := ""
var _tex: Texture2D


func _init() -> void:
	flat = true
	focus_mode = Control.FOCUS_ALL
	for state: String in ["normal", "hover", "pressed", "focus", "disabled", "hover_pressed"]:
		add_theme_stylebox_override(state, StyleBoxEmpty.new())
	resized.connect(queue_redraw)
	button_down.connect(queue_redraw)
	button_up.connect(queue_redraw)


static func make(icon_file: String, name_text: String, pressed_call: Callable) -> UniverseSide:
	var b := UniverseSide.new()
	b.icon_name = icon_file
	b._tex = UniverseHud.icon(icon_file)
	b.relabel(name_text)
	b.pressed.connect(func() -> void: Haptics.play("tap"))
	b.pressed.connect(pressed_call)
	return b


## New words, and the size they need: the ball over its plate, 48 points or
## more each way (§21.1).
func relabel(name_text: String, badge_text := "") -> void:
	words = name_text
	count = badge_text
	accessibility_name = name_text if badge_text == "" else Strings.t("HOME_BADGE_SPOKEN", [name_text, badge_text])
	var w := UniverseHud.words_font().get_string_size(words, HORIZONTAL_ALIGNMENT_LEFT, -1, _px()).x + UI.px(14)
	custom_minimum_size = Vector2(maxf(UI.CONTROL_POINTS * UI.PX_PER_POINT, maxf(w, _ball() + UI.px(6))),
		_ball() + _px() * 1.45 + UI.px(4))
	queue_redraw()


func _ball() -> float:
	return UI.px(50)


func _px() -> int:
	return UI.text_px(13.0)


func _draw() -> void:
	var r := _ball() * 0.5
	var c := Vector2(size.x * 0.5, r + UI.px(1))
	var squash := 0.94 if is_pressed() else 1.0
	if is_pressed():
		c.y += UI.px(2)
	UniverseHud.drop(self, Vector2(size.x * 0.5, r + UI.px(1)), r)
	UniverseHud.ball(self, c, r * squash, UniverseHud.LEATHER, UniverseHud.LEATHER_RIM)
	draw_arc(c + Vector2(0, -r * 0.08), r * 0.72 * squash, PI * 1.12, PI * 1.88, 24, Color(1.0, 0.86, 0.7, 0.22),
		UI.px(3), true)
	var tex := _tex
	if tex != null:
		var s := r * 1.32 * squash
		draw_texture_rect(tex, Rect2(c - Vector2(s, s) * 0.5, Vector2(s, s)), false)
	# The name on its plate, across the ball's foot.
	var font := UniverseHud.words_font()
	var px := _px()
	var tw := font.get_string_size(words, HORIZONTAL_ALIGNMENT_LEFT, -1, px).x + UI.px(12)
	var plate := Rect2(Vector2((size.x - tw) * 0.5, c.y + r * 0.62), Vector2(tw, px * 1.4))
	UniverseHud.plate(UniverseHud.INK_LINE, UI.px(6)).draw(get_canvas_item(), plate)
	draw_string(font, Vector2(plate.position.x, plate.position.y + plate.size.y * 0.5 + font.get_ascent(px) * 0.36),
		words, HORIZONTAL_ALIGNMENT_CENTER, plate.size.x, px, UniverseHud.CREAM)
	if count != "":
		UniverseHud.badge(self, c + Vector2(r * 0.74, -r * 0.7), count)
	if has_focus():
		draw_arc(c, r + UI.px(3), 0.0, TAU, 48, UniverseHud.WORDS, UI.px(2), true)
