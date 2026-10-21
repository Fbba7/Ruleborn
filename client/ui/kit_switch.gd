class_name KitSwitch
extends Button
## An on/off switch that also says On or Off in words, so its state never
## rests on colour or the knob's place alone (§20.8): a pill track, green
## when on and glass when off, with a gold knob that slides across in
## §21.8's time (at once under reduced motion). It is a 48-point control.

var _knob := 0.0:
	set(v):
		_knob = v
		queue_redraw()
var _on_words := ""
var _off_words := ""


## A switch in state `on`, saying `on_words` or `off_words`; `toggled_to`
## is called with the new state.
static func make(on: bool, on_words: String, off_words: String, spoken: String, toggled_to: Callable) -> KitSwitch:
	var s := KitSwitch.new()
	s.name = "Switch"
	s._on_words = on_words
	s._off_words = off_words
	s.toggle_mode = true
	s.button_pressed = on
	s._knob = 1.0 if on else 0.0
	s.accessibility_name = spoken
	s.custom_minimum_size = Vector2(UI.px(92), UI.px(UI.CONTROL_POINTS))
	s.focus_mode = Control.FOCUS_ALL
	s.set_meta("points", UI.TEXT_POINTS)
	s.set_meta("bold", true)
	for state: String in ["normal", "hover", "pressed", "focus", "disabled", "hover_pressed"]:
		s.add_theme_stylebox_override(state, StyleBoxEmpty.new())
	s.toggled.connect(func(now: bool) -> void:
		Haptics.play("tap")
		s._slide(now)
		toggled_to.call(now))
	s._dress(on)
	return s


func _dress(on: bool) -> void:
	text = _on_words if on else _off_words
	var box := UI.dress(self, "green" if on else "chip", 999)
	# The words sit away from the knob.
	var words: Color = Tokens.color("text_on_green") if on else box.spec["text"]
	for colour: String in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color",
			"font_hover_pressed_color"]:
		add_theme_color_override(colour, words)
	add_theme_font_override("font", UI.bold_font())
	add_theme_font_size_override("font_size", UI.text_px(14))
	if on:
		add_theme_color_override("font_outline_color", Tokens.color("ink_line"))
		add_theme_constant_override("outline_size", UI.px(2))
	else:
		remove_theme_constant_override("outline_size")
	alignment = HORIZONTAL_ALIGNMENT_LEFT if on else HORIZONTAL_ALIGNMENT_RIGHT
	for state: String in ["normal", "hover", "pressed", "focus", "hover_pressed"]:
		var pad := StyleBoxEmpty.new()
		var near := float(UI.px(12))
		var far := maxf(size.y, near)
		pad.content_margin_left = near if on else far
		pad.content_margin_right = far if on else near
		add_theme_stylebox_override(state, pad)


func _slide(on: bool) -> void:
	_dress(on)
	if Settings.reduced_motion or not is_inside_tree():
		_knob = 1.0 if on else 0.0
		return
	create_tween().tween_property(self, "_knob", 1.0 if on else 0.0, Tokens.number("motion", "longest_ms") / 1000.0) \
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)


func _ready() -> void:
	resized.connect(func() -> void: _dress(button_pressed))
	_dress(button_pressed)


func _draw() -> void:
	var r := size.y * 0.5 - UI.px(5)
	var x := lerpf(size.y * 0.5, size.x - size.y * 0.5, _knob)
	var c := Vector2(x, size.y * 0.5)
	draw_circle(c + Vector2(0, UI.px(1.5)), r, Tokens.color("drop"), true, -1.0, true)
	draw_circle(c, r, Tokens.color("ink_line"), true, -1.0, true)
	draw_circle(c, r - UI.px(1.5), Tokens.color("gold"), true, -1.0, true)
	draw_circle(c - Vector2(0, r * 0.25), r * 0.55, Color(Tokens.color("gold_top"), 0.9), true, -1.0, true)
