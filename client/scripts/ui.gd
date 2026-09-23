class_name UI
## The pieces every screen is built from, so §21.1's and §21.8's rules are
## applied in one place: a sky, a safe-area column, paper panels, labels and
## buttons of the stated sizes.

## §21.1: "Primary controls are at least 9 mm across — about 48 points". The
## base frame is 1080 pixels for a 360-point-wide phone, so 3 pixels a point.
const PX_PER_POINT := 3.0
const CONTROL_POINTS := 48.0
## §21.8: body text "at least 16 pixels", nothing smaller than 13 points.
const TEXT_POINTS := 16.0
const TITLE_POINTS := 32.0


static func px(points: float) -> int:
	return int(points * PX_PER_POINT)


## §21.2's day sky behind everything, and a column inside §21.1's safe areas:
## 44 points clear of the notch and the home bar.
static func frame(screen: Control) -> VBoxContainer:
	screen.set_anchors_preset(Control.PRESET_FULL_RECT)
	var sky := TextureRect.new()
	var gradient := Gradient.new()
	gradient.set_color(0, Palette.SKY_TOP)
	gradient.set_color(1, Palette.SKY_BOTTOM)
	var texture := GradientTexture2D.new()
	texture.gradient = gradient
	texture.fill_from = Vector2(0, 0)
	texture.fill_to = Vector2(0, 1)
	sky.texture = texture
	sky.stretch_mode = TextureRect.STRETCH_SCALE
	sky.set_anchors_preset(Control.PRESET_FULL_RECT)
	screen.add_child(sky)
	var safe := MarginContainer.new()
	safe.set_anchors_preset(Control.PRESET_FULL_RECT)
	safe.add_theme_constant_override("margin_top", px(44))
	safe.add_theme_constant_override("margin_bottom", px(44))
	safe.add_theme_constant_override("margin_left", px(16))
	safe.add_theme_constant_override("margin_right", px(16))
	screen.add_child(safe)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", px(8))
	safe.add_child(column)
	return column


## `wrap` only for a label with the width of its row to itself: a wrapping
## label inside a row asks for no width and so for one word a line.
static func label(text := "", points := TEXT_POINTS, wrap := false) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", px(points))
	l.add_theme_color_override("font_color", Palette.INK)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	if wrap:
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return l


## §21.8: "Ink #221C3A on paper panels at 85% opacity over the world".
static func panel() -> PanelContainer:
	var p := PanelContainer.new()
	var box := StyleBoxFlat.new()
	box.bg_color = Palette.PANEL
	box.set_corner_radius_all(px(12))
	box.set_content_margin_all(px(8))
	p.add_theme_stylebox_override("panel", box)
	return p


## §21.8: ink on paper, "gold for main actions".
static func button(text: String, pressed: Callable, main := false, fill := Color()) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2.ONE * CONTROL_POINTS * PX_PER_POINT
	b.add_theme_font_size_override("font_size", px(TEXT_POINTS))
	var base := fill if fill != Color() else (Palette.MOTION if main else Palette.PANEL)
	for state in ["normal", "hover", "pressed", "focus", "disabled"]:
		var box := StyleBoxFlat.new()
		box.bg_color = base
		if state == "pressed":
			box.bg_color = base.darkened(0.12)
		if state == "disabled":
			box.bg_color = Color(base, 0.45)
		box.set_corner_radius_all(px(12))
		box.border_color = Palette.INK
		box.set_border_width_all(px(1))
		box.set_content_margin_all(px(4))
		b.add_theme_stylebox_override(state, box)
	for colour in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color",
			"font_disabled_color"]:
		b.add_theme_color_override(colour, Palette.INK)
	b.pressed.connect(pressed)
	return b


## A centred row of controls, clear of the corners (§21.1).
static func row(separation := 12.0) -> HBoxContainer:
	var r := HBoxContainer.new()
	r.alignment = BoxContainer.ALIGNMENT_CENTER
	r.add_theme_constant_override("separation", px(separation))
	return r


static func grow() -> Control:
	var c := Control.new()
	c.size_flags_vertical = Control.SIZE_EXPAND_FILL
	return c
