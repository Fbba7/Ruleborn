class_name UniverseSide
extends Button
## One of home's side buttons as the design draws it: a 42-point leather ball
## in a gold ring, the place's icon on it, its name on a small dark plate over
## the ball's foot and a count badge on its shoulder. The ball is drawn smaller
## than the button, which keeps §21.1's 48-point hit area and takes the plate's
## width too. (The kit's round action draws its disc at the full hit area.)

## The ball's drawn size, in points.
const BALL_POINTS := 42.0
## How far the plate rises over the ball's foot, in points.
const OVERLAP_POINTS := 9.0

## The name on the plate, in capitals.
var words := ""
## The badge's words ("" for none).
var badge := ""
var _tex: Texture2D


## A side button to `icon` named `name`, with `count` on its badge.
static func make(icon: String, name: String, count: String) -> UniverseSide:
	var b := UniverseSide.new()
	b._tex = Icons.texture(icon)
	b.words = name.to_upper()
	b.badge = count
	b.accessibility_name = name if count == "" else Strings.t("HOME_BADGE_SPOKEN", [name, count])
	b._fit()
	b.pressed.connect(Haptics.play.bind("tap"))
	return b


func _init() -> void:
	flat = true
	focus_mode = Control.FOCUS_ALL
	for state: String in ["normal", "hover", "pressed", "focus", "disabled", "hover_pressed"]:
		add_theme_stylebox_override(state, StyleBoxEmpty.new())
	resized.connect(queue_redraw)
	button_down.connect(queue_redraw)
	button_up.connect(queue_redraw)


func _px() -> int:
	return UI.text_px(13.0)


func _plate_size() -> Vector2:
	var font := UniverseHud.words_font()
	var w := font.get_string_size(words, HORIZONTAL_ALIGNMENT_LEFT, -1, _px()).x
	return Vector2(w + UI.px(12), _px() * 1.45)


func _fit() -> void:
	var plate := _plate_size()
	var hit := float(UI.px(UI.CONTROL_POINTS))
	custom_minimum_size = Vector2(maxf(hit, plate.x), hit + plate.y - UI.px(OVERLAP_POINTS + 3.0))


func _draw() -> void:
	var ci := get_canvas_item()
	var hit := float(UI.px(UI.CONTROL_POINTS))
	var r := UI.px(BALL_POINTS) * 0.5
	var c := Vector2(size.x * 0.5, hit * 0.5)
	if is_pressed():
		c.y += UI.px(2.0)
	UniverseHud.drop(self, c, r)
	UniverseHud.ball(self, c, r, UniverseHud.LEATHER, UniverseHud.LEATHER_RIM)
	if _tex != null:
		var s := r * 1.05
		draw_texture_rect(_tex, Rect2(c - Vector2(s, s) * 0.5, Vector2(s, s)), false)
	var ps := _plate_size()
	var plate := Rect2(Vector2((size.x - ps.x) * 0.5, c.y + r - UI.px(OVERLAP_POINTS)), ps)
	UniverseHud.plate(Color("#2A1622"), UI.px(6)).draw(ci, plate)
	var font := UniverseHud.words_font()
	var px := _px()
	draw_string(font, Vector2(plate.position.x, plate.get_center().y + font.get_ascent(px) * 0.36), words,
		HORIZONTAL_ALIGNMENT_CENTER, plate.size.x, px, Color("#F6E6C8"))
	if badge != "":
		UniverseHud.badge(self, c + Vector2(r * 0.78, -r * 0.72), badge)
	if has_focus():
		draw_arc(c, r + UI.px(3), 0.0, TAU, 48, UniverseHud.WORDS, UI.px(2), true)
