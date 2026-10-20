class_name FxSkin
extends RefCounted
## §21.8's two families of surface for the HUD over the world, and its type:
## dark glass pills and violet cards with light text #F3EEFF, parchment with
## brown ink #2A1A10, each outlined in ink #1A0C14; gold for main actions and
## red #E2536B for alarms. Lilita One carries big numbers that do not change
## their width much (the clock, pop-up loot), Manrope the words. High
## contrast (§20.8) makes every surface opaque and every outline 3 points.
##
## The fonts are the designs' own (SIL Open Font License, in fx_fonts/),
## Latin subsets with the client's own font behind them for anything else.

const INK_LINE := Color("#1A0C14")
const ON_DARK := Color("#F3EEFF")
## §21.8: secondary words on a dark surface are no darker than this.
const ON_DARK_SOFT := Color("#C9BCE8")
const CARD_TOP := Color("#261A4C")
const CARD_BOTTOM := Color("#1A1134")
const GLASS := Color("#140A16")
const PARCH_TOP := Color("#FFFBF0")
const PARCH_BOTTOM := Color("#F1E3C4")
const PARCH_INK := Color("#2A1A10")
const GOLD := Color("#F2B43C")
const GOLD_DEEP := Color("#C97F12")
const ALARM := Color("#E2536B")
const ALARM_DEEP := Color("#B3203A")
## §21.8: red words on a dark surface.
const ALARM_ON_DARK := Color("#FF9AAA")
const SUCCESS := Color("#3FBF7F")
const LEATHER := Color("#5A3A2A")
const LEATHER_DEEP := Color("#3A2418")

static var _fonts := {}


static func _font(file: String, bold := 0.0) -> Font:
	var key := "%s:%s" % [file, bold]
	if _fonts.has(key):
		return _fonts[key]
	var f := FontVariation.new()
	var base: Font = load("res://world/fx_fonts/%s" % file) if ResourceLoader.exists("res://world/fx_fonts/%s" % file) \
		else ThemeDB.fallback_font
	if base != ThemeDB.fallback_font:
		base.fallbacks = [ThemeDB.fallback_font]
	f.base_font = base
	f.variation_embolden = bold
	_fonts[key] = f
	return f


## Lilita One: big numbers and short titles.
static func numbers() -> Font:
	return _font("lilita_one.woff2")


## Manrope at 800, drawn at 800 as §21.8 has 900 drawn: the HUD's words.
static func words() -> Font:
	return _font("manrope_800.woff2")


## Manrope at 600: secondary words.
static func soft_words() -> Font:
	return _font("manrope_600.woff2")


static func _outline_points() -> float:
	return 3.0 if Settings.high_contrast else 1.5


## A box with §21.8's corner, ink outline and soft drop shadow.
static func _box(fill: Color, radius_points: float, pad_points: float) -> StyleBoxFlat:
	var b := StyleBoxFlat.new()
	b.bg_color = fill
	b.border_color = INK_LINE
	b.set_border_width_all(maxi(2, UI.px(_outline_points())))
	b.set_corner_radius_all(UI.px(radius_points))
	b.set_content_margin_all(UI.px(pad_points))
	b.content_margin_top = UI.px(pad_points * 0.6)
	b.content_margin_bottom = UI.px(pad_points * 0.6)
	b.shadow_color = Color(0.05, 0.02, 0.08, 0.35)
	b.shadow_size = UI.px(2)
	b.shadow_offset = Vector2(0, UI.px(2))
	b.anti_aliasing = true
	return b


## Dark glass at 78% for pills over the world; opaque in high contrast.
static func glass(radius_points := 14.0, pad_points := 8.0) -> StyleBoxFlat:
	return _box(Color(GLASS, 1.0 if Settings.high_contrast else 0.78), radius_points, pad_points)


## The violet card.
static func card(radius_points := 12.0, pad_points := 10.0) -> StyleBoxFlat:
	return _box(CARD_TOP, radius_points, pad_points)


static func parchment(radius_points := 12.0, pad_points := 10.0) -> StyleBoxFlat:
	return _box(PARCH_TOP, radius_points, pad_points)


## A panel of one family: "glass", "card" or "parchment". It lets taps through
## to the world beneath, as the HUD over the world must.
static func panel(kind := "glass", radius_points := 14.0, pad_points := 8.0) -> PanelContainer:
	var p := PanelContainer.new()
	var box: StyleBoxFlat
	match kind:
		"card":
			box = card(radius_points, pad_points)
		"parchment":
			box = parchment(radius_points, pad_points)
		_:
			box = glass(radius_points, pad_points)
	p.add_theme_stylebox_override("panel", box)
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	p.set_meta("surface", kind)
	return p


## Words on a surface: light on the dark family, brown ink on parchment.
static func label(text: String, points: float, on := "glass", big := false) -> Label:
	var l := UI.label(text, points)
	l.add_theme_font_override("font", numbers() if big else words())
	l.add_theme_color_override("font_color", PARCH_INK if on == "parchment" else ON_DARK)
	l.add_theme_color_override("font_outline_color", INK_LINE)
	if big and on != "parchment":
		# An ink outline all round (§21.8): the words read on any sky.
		l.add_theme_constant_override("outline_size", maxi(4, UI.px(1.6)))
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	l.set_meta("bold", true)
	return l


## A button of the HUD's own: "leather" (the dark family's), "gold" (a main
## action), "alarm" (leaving) or "parchment". Its words keep §21.8's contrast
## on its fill in every state; a press squashes it a little (§21.8).
static func style_button(b: Button, kind := "leather", radius_points := 16.0) -> void:
	var fill := LEATHER
	var ink := ON_DARK
	match kind:
		"gold":
			fill = GOLD
			ink = INK_LINE
		"alarm":
			fill = ALARM_DEEP
			ink = ON_DARK
		"parchment":
			fill = PARCH_TOP
			ink = PARCH_INK
		"card":
			fill = CARD_TOP
	for state: String in ["normal", "hover", "pressed", "focus", "disabled"]:
		var box := _box(fill, radius_points, 6.0)
		if state == "pressed":
			# Pressed lightens, so the words keep their contrast.
			box.bg_color = fill.lightened(0.12)
			box.shadow_offset = Vector2.ZERO
		elif state == "hover":
			box.bg_color = fill.lightened(0.04)
		elif state == "focus":
			box.border_color = ON_DARK if kind in ["leather", "alarm", "card"] else INK_LINE
			box.set_border_width_all(UI.px(_outline_points() + 1.0))
		elif state == "disabled":
			box.bg_color = Color(fill.darkened(0.3), 0.9)
		b.add_theme_stylebox_override(state, box)
	for colour: String in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color",
			"font_disabled_color"]:
		b.add_theme_color_override(colour, ink)
	b.add_theme_color_override("font_outline_color", INK_LINE)
	b.add_theme_font_override("font", words())
	b.set_meta("surface", kind)
	if not b.has_meta("gloss"):
		var g := FxGloss.new()
		g.radius = UI.px(radius_points)
		b.add_child(g)
		b.set_meta("gloss", true)
		b.button_down.connect(func() -> void: b.pivot_offset = b.size / 2.0; b.scale = Vector2(1.04, 0.94))
		b.button_up.connect(func() -> void: b.scale = Vector2.ONE)


## The HUD's frame over a full-screen world (§21.1's safe areas): a column at
## the top for what is read and a column at the bottom, growing upward, for
## the hand's controls, so large text (§20.8) never pushes a control off the
## screen. Both let taps fall through to the world. Returns [top, bottom].
static func frame(screen: Control) -> Array[VBoxContainer]:
	var out: Array[VBoxContainer] = []
	var gap := UI.px(Tokens.number("size", "gap_points"))
	for at_top: bool in [true, false]:
		var safe := MarginContainer.new()
		safe.mouse_filter = Control.MOUSE_FILTER_IGNORE
		safe.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE if at_top else Control.PRESET_BOTTOM_WIDE)
		safe.grow_vertical = Control.GROW_DIRECTION_END if at_top else Control.GROW_DIRECTION_BEGIN
		safe.add_theme_constant_override("margin_top" if at_top else "margin_bottom",
			UI.px(Tokens.number("size", "safe_top_points")))
		for side: String in ["left", "right"]:
			safe.add_theme_constant_override("margin_" + side, UI.px(Tokens.number("size", "safe_side_points")))
		var column := VBoxContainer.new()
		column.mouse_filter = Control.MOUSE_FILTER_IGNORE
		column.add_theme_constant_override("separation", gap)
		safe.add_child(column)
		screen.add_child(safe)
		out.append(column)
	return out


## §21.1's switch: when the player asks for them in Settings, buttons that
## turn the view a quarter either way and step its zoom, so no action needs
## two fingers (§20.8). Each is drawn as its arrow or sign and named in words.
static func camera_row(view: WorldView) -> HFlowContainer:
	var r := UI.row(6.0, true)
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	r.alignment = FlowContainer.ALIGNMENT_BEGIN
	r.visible = Settings.camera_buttons
	for spec: Array in [["turn", -1, "CAMERA_TURN_LEFT"], ["turn", 1, "CAMERA_TURN_RIGHT"],
			["zoom", -1, "CAMERA_ZOOM_OUT"], ["zoom", 1, "CAMERA_ZOOM_IN"]]:
		var kind: String = spec[0]
		var by: int = spec[1]
		var act := func() -> void:
			if kind == "turn":
				view.turn(by)
			else:
				view.set_zoom(view.zoom + by)
		var b := UI.button("", act, false, Color(), Strings.t(spec[2]))
		style_button(b, "card", 24.0)
		b.add_child(FxDraw.new(func(ci: Control) -> void: _camera_icon(ci, kind, by)))
		(b.get_child(b.get_child_count() - 1) as Control).set_anchors_preset(Control.PRESET_FULL_RECT)
		r.add_child(b)
	return r


static func _camera_icon(ci: Control, kind: String, by: int) -> void:
	var c := ci.size / 2.0
	var s := minf(ci.size.x, ci.size.y) * 0.26
	var w := maxf(3.0, s * 0.22)
	if kind == "zoom":
		ci.draw_line(c - Vector2(s, 0), c + Vector2(s, 0), ON_DARK, w)
		if by > 0:
			ci.draw_line(c - Vector2(0, s), c + Vector2(0, s), ON_DARK, w)
		return
	var start := -PI * 0.85 if by > 0 else -PI * 0.15
	var end := PI * 0.35 if by > 0 else -PI * 1.35
	ci.draw_arc(c, s, start, end, 20, ON_DARK, w, true)
	var tip := c + Vector2(cos(end), sin(end)) * s
	var along := Vector2(-sin(end), cos(end)) * (1.0 if by > 0 else -1.0)
	var out := Vector2(cos(end), sin(end))
	ci.draw_colored_polygon(PackedVector2Array([tip + along * s * 0.55, tip + out * s * 0.4 - along * s * 0.1,
		tip - out * s * 0.4 - along * s * 0.1]), ON_DARK)


## Space under the lowest controls, so none sits in a bottom corner (§21.1).
static func corner_clear() -> Control:
	var c := Control.new()
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	c.custom_minimum_size.y = UI.px(Tokens.number("size", "corner_points") + 10.0)
	return c


## Words that report an outcome on the dark family, led by their glyph
## (`UI.set_status`'s): red words in §21.8's #FF9AAA, the others light, the
## glyph saying which they are.
static func set_status(l: Label, kind: String, text: String) -> void:
	UI.set_status(l, kind, text)
	l.add_theme_color_override("font_color", ALARM_ON_DARK if kind == "alarm" else ON_DARK)


## The colour words take on a surface.
static func ink_on(kind: String) -> Color:
	return INK_LINE if kind == "gold" else (PARCH_INK if kind == "parchment" else ON_DARK)
