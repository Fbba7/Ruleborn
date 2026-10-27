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
	focus_entered.connect(queue_redraw)
	focus_exited.connect(queue_redraw)


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
	# Drawn by `draw_all` on a layer over every side button; only the focus
	# ring is the button's own.
	if has_focus():
		var c := _centre()
		draw_arc(c, UI.px(BALL_POINTS) * 0.5 + UI.px(3), 0.0, TAU, 48, UniverseHud.WORDS, UI.px(2), true)


func _centre() -> Vector2:
	var c := Vector2(size.x * 0.5, UI.px(UI.CONTROL_POINTS) * 0.5)
	if is_pressed():
		c.y += UI.px(2.0)
	return c


## Every side button in `sides` drawn on `layer`, each kind of mark in one run
## across them all (balls, icons, plates, badges, then the words), so four
## buttons cost the frame a handful of draw calls, not four each (§21.3).
static func draw_all(layer: CanvasItem, sides: Array[UniverseSide]) -> void:
	var shown: Array[UniverseSide] = []
	for b: UniverseSide in sides:
		if is_instance_valid(b) and b.is_visible_in_tree() and not b.is_queued_for_deletion():
			shown.append(b)
	var r := UI.px(BALL_POINTS) * 0.5
	var at := func(b: UniverseSide) -> Vector2:
		return b.global_position - (layer as Control).global_position + b._centre()
	for b: UniverseSide in shown:
		UniverseHud.ball(layer, at.call(b), r, UniverseHud.LEATHER, UniverseHud.LEATHER_RIM, true, true)
	for b: UniverseSide in shown:
		if b._tex != null:
			var s := r * 1.05
			layer.draw_texture_rect(b._tex, Rect2(at.call(b) - Vector2(s, s) * 0.5, Vector2(s, s)), false)
	var plate := UniverseHud.baked_plate(Color("#2A1622"), UI.px(6))
	for b: UniverseSide in shown:
		plate.draw(layer.get_canvas_item(), b._plate_rect(at.call(b)))
	var tags := {}
	for b: UniverseSide in shown:
		if b.badge != "":
			tags[b] = UniverseHud.badge_box(layer, at.call(b) + Vector2(r * 0.78, -r * 0.72), b.badge)
	var font := UniverseHud.words_font()
	var px := UI.text_px(13.0)
	for b: UniverseSide in shown:
		var p: Rect2 = b._plate_rect(at.call(b))
		layer.draw_string(font, Vector2(p.position.x, p.get_center().y + font.get_ascent(px) * 0.36), b.words,
			HORIZONTAL_ALIGNMENT_CENTER, p.size.x, px, Color("#F6E6C8"))
	for b: UniverseSide in tags:
		UniverseHud.badge_words(layer, tags[b], b.badge)


## The name's plate under a ball centred at `c`.
func _plate_rect(c: Vector2) -> Rect2:
	var ps := _plate_size()
	return Rect2(Vector2(c.x - ps.x * 0.5, c.y + UI.px(BALL_POINTS) * 0.5 - UI.px(OVERLAP_POINTS)), ps)
