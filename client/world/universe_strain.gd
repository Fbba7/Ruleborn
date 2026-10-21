class_name UniverseStrain
extends Button
## Home's top right (§21.8): the universe's strain (§5.5) on a glass pill, a
## dot in its band's colour and the band named beside the number, so it never
## rests on colour alone (§20.8). It opens the weaving, where strain is
## changed. The pill is drawn smaller than its 48-point hit area (§21.1).

var band := 0
var words := ""


func _init() -> void:
	flat = true
	focus_mode = Control.FOCUS_ALL
	for state: String in ["normal", "hover", "pressed", "focus", "disabled", "hover_pressed"]:
		add_theme_stylebox_override(state, StyleBoxEmpty.new())
	resized.connect(queue_redraw)
	accessibility_name = Strings.t("HOME_WEAVING")


## The strain as a share (0.82) and its band; `known` false hides the pill.
func show_strain(strain: float, band_index: int, known: bool) -> void:
	visible = known
	band = clampi(band_index, 0, UniverseHud.BANDS.size() - 1)
	words = "%d%% · %s" % [roundi(strain * 100.0), WeavingPresenter.band_name(band)]
	accessibility_name = Strings.t("HOME_STRAIN_SPOKEN", [WeavingPresenter.band_name(band), roundi(strain * 100.0)])
	var w := UniverseHud.words_font().get_string_size(words, HORIZONTAL_ALIGNMENT_LEFT, -1, _px()).x
	custom_minimum_size = Vector2(maxf(UI.CONTROL_POINTS * UI.PX_PER_POINT, w + UI.px(46)),
		UI.CONTROL_POINTS * UI.PX_PER_POINT)
	queue_redraw()


func _px() -> int:
	return UI.text_px(13.0)


func _draw() -> void:
	if words == "":
		return
	var h := maxf(UI.px(32), _px() * 1.9)
	var pill := Rect2(Vector2(UI.px(2), (size.y - h) * 0.5), Vector2(size.x - UI.px(4), h))
	if is_pressed():
		pill.position.y += UI.px(1.5)
	UniverseHud.glass(h * 0.5).draw(get_canvas_item(), pill)
	var dot := Vector2(pill.position.x + h * 0.5, pill.get_center().y)
	var colour: Color = UniverseHud.BANDS[band]
	draw_circle(dot, h * 0.3, Color(colour, 0.35), true, -1.0, true)
	draw_circle(dot, h * 0.2, colour, true, -1.0, true)
	draw_arc(dot, h * 0.2, 0.0, TAU, 24, UniverseHud.INK_LINE, UI.px(1.5), true)
	var font := UniverseHud.words_font()
	draw_string(font, Vector2(dot.x + h * 0.42, pill.get_center().y + font.get_ascent(_px()) * 0.36), words,
		HORIZONTAL_ALIGNMENT_LEFT, -1, _px(), UniverseHud.WORDS)
	if has_focus():
		var ring := UniverseHud.glass(h * 0.5 + UI.px(3))
		ring.draw_center = false
		ring.border_color = UniverseHud.WORDS
		ring.shadow_size = 0
		ring.draw(get_canvas_item(), pill.grow(UI.px(3)))
