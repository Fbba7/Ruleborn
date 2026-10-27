class_name UniverseStrain
extends Button
## Home's top right (§21.8): the universe's strain (§5.5) on a glass pill, a
## dot in its band's colour and the band named beside the number, so it never
## rests on colour alone (§20.8). It opens the weaving, where strain is
## changed. The pill is drawn smaller than its 48-point hit area (§21.1).
## Where one line will not fit beside the Keeper badge (large text, a long
## band name), the number sits over the band's name; where even that will not,
## home's top row puts the pill on a line of its own. The pill is drawn at the
## right of whatever width it is given.

var band := 0
var words := ""
## The number and the band's name on two lines.
var stacked := false
var _lines := PackedStringArray()
## The widest the pill may be; 0 for no limit.
var _room := 0.0


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
	_lines = PackedStringArray(["%d%%" % roundi(strain * 100.0), WeavingPresenter.band_name(band)])
	accessibility_name = Strings.t("HOME_STRAIN_SPOKEN", [WeavingPresenter.band_name(band), roundi(strain * 100.0)])
	_measure()


## The pill no wider than `room` if it can be: two lines where one will not do.
func fit(room: float) -> void:
	if absf(room - _room) < 0.5:
		return
	_room = room
	_measure()


func _measure() -> void:
	var font := UniverseHud.words_font()
	# The dot grows with the text: the words start past it, as _draw puts them.
	var pad := _px() * 1.9 * 0.92 + UI.px(18)
	var one := font.get_string_size(words, HORIZONTAL_ALIGNMENT_LEFT, -1, _px()).x + pad
	var two := 0.0
	for line: String in _lines:
		two = maxf(two, font.get_string_size(line, HORIZONTAL_ALIGNMENT_LEFT, -1, _px()).x + pad)
	var tall := UI.CONTROL_POINTS * UI.PX_PER_POINT
	stacked = _room > 0.0 and one > _room and two <= _room
	var want := Vector2(maxf(tall, two if stacked else one), maxf(tall, _px() * 3.0 if stacked else 0.0))
	if want != custom_minimum_size:
		custom_minimum_size = want
	queue_redraw()


## Only the pill and its 48-point hit area answer a tap, not the width the row
## gives it.
func _has_point(point: Vector2) -> bool:
	var w := minf(size.x, custom_minimum_size.x)
	return Rect2(Vector2(size.x - w, 0.0), Vector2(w, size.y)).has_point(point)


func _px() -> int:
	return UI.text_px(13.0)


func _draw() -> void:
	if words == "":
		return
	var h := maxf(UI.px(32), _px() * (2.9 if stacked else 1.9))
	var w := minf(size.x, custom_minimum_size.x) - UI.px(4)
	var pill := Rect2(Vector2(size.x - w - UI.px(2), (size.y - h) * 0.5), Vector2(w, h))
	if is_pressed():
		pill.position.y += UI.px(1.5)
	UniverseHud.glass(h * 0.5).draw(get_canvas_item(), pill)
	var dot := Vector2(pill.position.x + h * 0.5, pill.get_center().y)
	var colour: Color = UniverseHud.BANDS[band]
	var d := minf(h, _px() * 1.9)
	dot.x = pill.position.x + d * 0.5 + UI.px(4)
	draw_circle(dot, d * 0.3, Color(colour, 0.35), true, -1.0, true)
	draw_circle(dot, d * 0.2, colour, true, -1.0, true)
	draw_arc(dot, d * 0.2, 0.0, TAU, 24, UniverseHud.INK_LINE, UI.px(1.5), true)
	var font := UniverseHud.words_font()
	var x := dot.x + d * 0.42
	var base := pill.get_center().y + font.get_ascent(_px()) * 0.36
	if stacked:
		for i: int in _lines.size():
			draw_string(font, Vector2(x, base + (float(i) - 0.5) * _px() * 1.15), _lines[i],
				HORIZONTAL_ALIGNMENT_LEFT, -1, _px(), UniverseHud.WORDS)
	else:
		draw_string(font, Vector2(x, base), words, HORIZONTAL_ALIGNMENT_LEFT, -1, _px(), UniverseHud.WORDS)
	if has_focus():
		var ring := UniverseHud.glass(h * 0.5 + UI.px(3))
		ring.draw_center = false
		ring.border_color = UniverseHud.WORDS
		ring.shadow_size = 0
		ring.draw(get_canvas_item(), pill.grow(UI.px(3)))
