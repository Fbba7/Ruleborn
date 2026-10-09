class_name UI
## The pieces every screen is built from, so §21.1's, §21.8's and §20.8's
## rules are applied in one place: a sky, a safe-area column, paper panels,
## labels and buttons of the stated sizes, rows that wrap when the text is
## large, words that say what a colour says, banners, and a name for every
## control a screen reader reaches. Claude Design's components replace these;
## the screens call them by the same names.

## What a status says, with the glyph that says it without colour (§20.8:
## "no information carried by colour alone").
const GLYPH := {"success": "✓", "alarm": "!", "info": "ⓘ", "confirming": "…"}
## §21.2's school shapes as glyphs, for words that name a school.
const SHAPE_GLYPH := {"chevron": "^", "cube": "■", "hourglass": "⧗", "bolt": "ϟ", "leaf": "❦", "eye": "◉"}

## §21.1: "Primary controls are at least 9 mm across — about 48 points". The
## base frame is 1080 pixels for a 360-point-wide phone, so 3 pixels a point.
static var PX_PER_POINT: float = Tokens.number("size", "px_per_point")
static var CONTROL_POINTS: float = Tokens.number("size", "control_points")
## §21.8: body text "at least 16 pixels", nothing smaller than 13 points.
static var TEXT_POINTS: float = Tokens.number("size", "body_points")
static var TITLE_POINTS: float = Tokens.number("size", "title_points")
static var _bold: FontVariation = null



static func px(points: float) -> int:
	return int(points * PX_PER_POINT)


## Text's pixels: §20.8's text size, up to 200%, applies to words only, so
## a control grows with its label and never shrinks below §21.1's size. Body
## text scales in full; larger text grows only until body text reaches it,
## as the phones' own large-text settings do, so a title never outgrows the
## screen.
static func text_px(points: float) -> int:
	var scale := Settings.text_scale / 100.0
	var shown := points * scale if points <= TEXT_POINTS else maxf(points, TEXT_POINTS * scale)
	return int(shown * PX_PER_POINT)


## §20.8's reduced motion: a movement of `ms` takes none.
static func motion_ms(ms: float) -> float:
	return 0.0 if Settings.reduced_motion else ms


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
	sky.name = "Sky"
	screen.add_child(sky)
	var safe := MarginContainer.new()
	safe.set_anchors_preset(Control.PRESET_FULL_RECT)
	safe.add_theme_constant_override("margin_top", px(Tokens.number("size", "safe_top_points")))
	safe.add_theme_constant_override("margin_bottom", px(Tokens.number("size", "safe_top_points")))
	safe.add_theme_constant_override("margin_left", px(Tokens.number("size", "safe_side_points")))
	safe.add_theme_constant_override("margin_right", px(Tokens.number("size", "safe_side_points")))
	screen.add_child(safe)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", px(Tokens.number("size", "gap_points")))
	safe.add_child(column)
	return column


## A scrolling body for a screen that is a list, filling the frame's column
## above whatever is added after it — the fixed controls, which stay in the
## thumb's reach while the list moves (§21.1).
## `plated` puts the list on paper: its words are body text (§21.8).
static func scroll(column: VBoxContainer, plated := false) -> VBoxContainer:
	var s := ScrollContainer.new()
	s.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	s.size_flags_vertical = Control.SIZE_EXPAND_FILL
	column.add_child(s)
	var body := VBoxContainer.new()
	body.add_theme_constant_override("separation", px(Tokens.number("size", "gap_points")))
	body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	if plated:
		var p := panel()
		p.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		p.add_child(body)
		s.add_child(p)
	else:
		s.add_child(body)
	return body


## A line of text the player types — a code, a name — with what it is for
## said to a screen reader and shown until something is typed.
static func field(spoken: String) -> LineEdit:
	var f := LineEdit.new()
	f.placeholder_text = spoken
	f.accessibility_name = spoken
	f.custom_minimum_size = Vector2(px(160), CONTROL_POINTS * PX_PER_POINT)
	f.add_theme_font_size_override("font_size", text_px(TEXT_POINTS))
	f.add_theme_color_override("font_color", Palette.INK)
	f.add_theme_color_override("font_placeholder_color", Palette.INK)
	var box := StyleBoxFlat.new()
	box.bg_color = Palette.PAPER
	box.border_color = Palette.INK
	box.set_border_width_all(px(1))
	box.set_corner_radius_all(px(Tokens.number("size", "corner_points")))
	box.set_content_margin_all(px(6))
	for state: String in ["normal", "focus", "read_only"]:
		f.add_theme_stylebox_override(state, box)
	f.set_meta("points", TEXT_POINTS)
	return f


## `wraps` only for a label with the width of its row to itself: a wrapping
## label inside a row asks for no width and so for one word a line.
static func label(text := "", points := -1.0, wraps := false) -> Label:
	if points < 0:
		points = TEXT_POINTS
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", text_px(points))
	l.add_theme_color_override("font_color", Palette.INK)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	if wraps:
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.set_meta("points", points)
	return l


static func title(text: String) -> Label:
	var l := label(text, TITLE_POINTS, true)
	l.accessibility_live = AccessibilityServer.LIVE_OFF
	return l


## Words that report an outcome — "success", "alarm", "info" or
## "confirming" — led by a glyph, so the colour is never the only sign.
static func status(kind: String, text: String, wraps := true) -> Label:
	var l := label("", TEXT_POINTS, wraps)
	set_status(l, kind, text)
	return l


static func set_status(l: Label, kind: String, text: String) -> void:
	assert(GLYPH.has(kind), "no status %s" % kind)
	l.text = "%s %s" % [GLYPH.get(kind, ""), text] if text != "" else ""
	var colour := Palette.INK
	match kind:
		"success":
			colour = Palette.SUCCESS_TEXT
		"alarm":
			colour = Palette.ALARM_TEXT
	l.add_theme_color_override("font_color", colour)
	l.set_meta("status", kind)


## Body text on its own paper plate: the sky is too light behind body text for
## APCA's Lc 75 at its top (Lc 63), so words sit on paper, as §21.8 puts them.
static func plate(words: Control) -> PanelContainer:
	var p := panel()
	p.add_child(words)
	return p


## §21.8: "Ink #221C3A on paper panels at 85% opacity over the world".
static func panel() -> PanelContainer:
	var p := PanelContainer.new()
	var box := StyleBoxFlat.new()
	box.bg_color = Palette.PANEL
	box.set_corner_radius_all(px(Tokens.number("size", "corner_points")))
	box.set_content_margin_all(px(Tokens.number("size", "gap_points")))
	p.add_theme_stylebox_override("panel", box)
	return p


## §21.8: ink on paper, "gold for main actions". A screen reader says a
## button's text; `spoken` replaces it for a button whose text is a symbol
## ("+", "‹").
static func button(text: String, pressed: Callable, main := false, fill := Color(), spoken := "") -> Button:
	var b := Button.new()
	b.text = text
	b.accessibility_name = spoken
	b.custom_minimum_size = Vector2.ONE * CONTROL_POINTS * PX_PER_POINT
	b.add_theme_font_size_override("font_size", text_px(TEXT_POINTS))
	# A control's words are short and bold: APCA's level for them (Lc 60), as
	# body text on a panel carries Lc 75 (ui/colour_check.gd).
	b.add_theme_font_override("font", bold_font())
	b.set_meta("bold", true)
	var base := fill if fill != Color() else (Palette.MOTION if main else Palette.PANEL)
	for state: String in ["normal", "hover", "pressed", "focus", "disabled"]:
		var box := StyleBoxFlat.new()
		box.bg_color = base
		# Pressed lightens, so its words keep their contrast (ink is dark).
		if state == "pressed":
			box.bg_color = base.lightened(0.15)
		if state == "disabled":
			box.bg_color = Color(base, 0.45)
		box.set_corner_radius_all(px(Tokens.number("size", "corner_points")))
		box.border_color = Palette.INK
		box.set_border_width_all(px(1))
		box.set_content_margin_all(px(4))
		b.add_theme_stylebox_override(state, box)
	for colour: String in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color",
			"font_disabled_color"]:
		b.add_theme_color_override(colour, Palette.INK)
	b.set_meta("points", TEXT_POINTS)
	fit(b)
	b.pressed.connect(func() -> void: Haptics.play("tap"))
	b.pressed.connect(pressed)
	return b


## The client's font, emboldened: a control's words.
static func bold_font() -> FontVariation:
	if _bold == null:
		_bold = FontVariation.new()
		_bold.base_font = ThemeDB.fallback_font
		_bold.variation_embolden = 0.7
	return _bold


## A button's width for its words: as wide as they are, up to the widest a
## control may be, past which they wrap onto more lines (§20.8's large text).
static func fit(b: Button) -> void:
	var font := b.get_theme_font("font")
	var natural := font.get_string_size(b.text, HORIZONTAL_ALIGNMENT_LEFT, -1, b.get_theme_font_size("font_size")).x \
		+ px(12)
	var most := px(Tokens.number("size", "widest_control_points"))
	b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART if natural > most else TextServer.AUTOWRAP_OFF
	b.custom_minimum_size.x = maxf(CONTROL_POINTS * PX_PER_POINT, minf(natural, most))


## New words on a button, and its width fitted to them. `keep` keeps a width
## set by `fit_to`, so a control whose words change does not move its row.
static func relabel(b: Button, text: String, keep := false) -> void:
	b.text = text
	if not keep:
		fit(b)


## A button as wide as the widest of the words it may show.
static func fit_to(b: Button, words: Array) -> void:
	var was := b.text
	var widest := 0.0
	for w: String in words + [was]:
		b.text = w
		fit(b)
		widest = maxf(widest, b.custom_minimum_size.x)
	b.text = was
	b.custom_minimum_size.x = widest


## A button's border, in points: a chosen one is drawn heavier (§20.8: never
## by colour or fading alone).
static func set_outline(b: Button, points: int) -> void:
	for state: String in ["normal", "hover", "pressed", "focus"]:
		var box := b.get_theme_stylebox(state) as StyleBoxFlat
		if box != null:
			box.set_border_width_all(px(points))


## The lowest row of a screen, kept clear of the bottom corners (§21.1), where
## it wraps rather than reach them when the text is large.
static func narrow(lowest: Control) -> MarginContainer:
	var m := MarginContainer.new()
	m.add_child(lowest)
	# 15% of the frame's width, whatever the phone's shape: a wider frame
	# (§23.3 shows more sky) moves the corners out with it.
	var clear := func() -> void:
		var wide := m.get_viewport_rect().size.x if m.is_inside_tree() else 360.0 * PX_PER_POINT
		var side := maxf(px(Tokens.number("size", "corner_clear_points")) * wide / (360.0 * PX_PER_POINT),
			px(Tokens.number("size", "corner_clear_points"))) - px(Tokens.number("size", "safe_side_points"))
		m.add_theme_constant_override("margin_left", int(side))
		m.add_theme_constant_override("margin_right", int(side))
	m.tree_entered.connect(clear)
	m.resized.connect(clear)
	clear.call()
	return m


## A centred row of controls, clear of the corners (§21.1), that wraps onto
## a second line when §20.8's large text makes it too wide. `thumb` marks a
## row of the hand's controls, which §20.8 mirrors for left-handed play.
static func row(separation := -1.0, thumb := false) -> HFlowContainer:
	if separation < 0:
		separation = Tokens.number("size", "row_gap_points")
	var r := HFlowContainer.new()
	r.alignment = FlowContainer.ALIGNMENT_CENTER
	r.add_theme_constant_override("h_separation", px(separation))
	r.add_theme_constant_override("v_separation", px(separation))
	if thumb and Settings.left_handed:
		r.layout_direction = Control.LAYOUT_DIRECTION_RTL
	r.set_meta("thumb", thumb)
	return r


static func grow() -> Control:
	var c := Control.new()
	c.size_flags_vertical = Control.SIZE_EXPAND_FILL
	return c


## A banner: news the player may need, led by its glyph, with a button that
## dismisses it. It goes by itself after a while, unless the player keeps
## banners until dismissed (§20.8: "no reading speed requirements on
## banners"). A screen reader announces it as it appears.
static func banner(kind: String, text: String, ms := -1.0) -> PanelContainer:
	if ms < 0:
		ms = Tokens.number("motion", "banner_ms")
	var p := panel()
	p.name = "Banner"
	var r := row()
	var words := status(kind, text)
	words.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	words.accessibility_live = AccessibilityServer.LIVE_ASSERTIVE if kind == "alarm" else AccessibilityServer.LIVE_POLITE
	r.add_child(words)
	r.add_child(button("×", p.queue_free, false, Color(), Strings.t("COMMON_DISMISS")))
	p.add_child(r)
	if not Settings.banners_stay:
		var tree := Engine.get_main_loop() as SceneTree
		if tree != null:
			tree.create_timer(ms / 1000.0).timeout.connect(func() -> void:
				if is_instance_valid(p):
					p.queue_free())
	return p


## A school's mark: its shape's name as a glyph and the school's name, so a
## school reads without its colour (§21.2, §20.8).
static func school_mark(school: String) -> String:
	return "%s %s" % [SHAPE_GLYPH.get(Tokens.shape(school), "?"), Strings.t("SCHOOL_" + school.to_upper())]
