class_name StageHeroKit
extends RefCounted
## The design's small pieces for the character screens (§21.8), on
## StageHeroMaterial's materials: kickers, chips, tabs, cards with a kicker,
## stat rows and the round arrow. Information is shown as the design shows
## it — a word on a chip, a number on a bar — never as a sentence listing it.

## A kicker's tracking, as the design spaces its small capitals.
static var _tracked: FontVariation = null


## Words in the client's bold face, in `colour`, edged in ink when `edged`
## so they hold on any fill.
static func words(text: String, points: float, colour: Color, edged := false) -> Label:
	var l := UI.label(text, points)
	l.add_theme_font_override("font", UI.bold_font())
	l.add_theme_color_override("font_color", colour)
	l.set_meta("own_ink", true)
	l.set_meta("bold", true)
	if edged:
		l.add_theme_color_override("font_outline_color", Color("#120C2A"))
		l.add_theme_constant_override("outline_size", UI.px(1.5))
	return l


## A kicker: a card's small capital heading, tracked wide, in gold.
static func kicker(text: String, colour := Color("#E9B65C")) -> Label:
	if _tracked == null:
		_tracked = FontVariation.new()
		_tracked.base_font = ThemeDB.fallback_font
		_tracked.variation_embolden = 0.8
		_tracked.spacing_glyph = 2
	var l := UI.label(text.to_upper(), 13.0)
	l.add_theme_font_override("font", _tracked)
	l.add_theme_color_override("font_color", colour)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	l.set_meta("own_ink", true)
	l.set_meta("bold", true)
	return l


## A chip: a glyph and a word on a pill of `kind` (a material or a colour);
## its words wrap when `wraps`, for a chip that may hold a phrase.
static func chip(text: String, kind := "glass", glyph := "", wraps := false) -> PanelContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", UI.px(4))
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	var ink := StageHeroMaterial.ink(kind)
	if glyph != "":
		row.add_child(words(glyph, 14.0, ink))
	var said := words(text, 14.0, ink)
	# At §20.8's larger text every chip may wrap, so none outgrows the phone.
	wraps = wraps or Settings.text_scale > 100
	if wraps:
		said.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		said.custom_minimum_size.x = UI.px(60)
		said.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(said)
	var p := StageHeroMaterial.panel(kind, row, 12.0, 9.0)
	var b := p.get_theme_stylebox("panel") as StyleBoxTexture
	b.content_margin_top = UI.px(4)
	b.content_margin_bottom = UI.px(5) + int(b.texture_margin_bottom - b.texture_margin_top)
	p.size_flags_horizontal = Control.SIZE_FILL if wraps else Control.SIZE_SHRINK_BEGIN
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return p


## A card on the night: a kicker and what it heads, in a dark violet card
## with a gold rim (§21.8).
static func card(heading: String, body: Control, kind := "card") -> PanelContainer:
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", UI.px(4))
	if heading != "":
		v.add_child(kicker(heading))
	v.add_child(body)
	var p := StageHeroMaterial.panel(kind, v, 16.0, 12.0)
	p.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return p


## A paragraph on a card, left-aligned and wrapping.
static func para(words_shown: String, points := 16.0, colour := Color("#F3EEFF")) -> Label:
	var l := UI.label(words_shown, points, true)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	l.add_theme_color_override("font_color", colour)
	l.set_meta("own_ink", true)
	l.custom_minimum_size.x = UI.px(60)
	return l


## A segmented control: one button a name, the chosen one on the design's
## periwinkle tab material, the rest on a dark well. `pick` takes the index.
static func tabs(names: Array, chosen: int, pick: Callable) -> PanelContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", UI.px(4))
	for i: int in names.size():
		var b := UI.button(str(names[i]), pick.bind(i))
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.toggle_mode = true
		b.button_pressed = i == chosen
		b.set_meta("item", "tab:%d" % i)
		b.accessibility_name = Strings.t("WORKSHOP_TAB_SHOWN" if i == chosen else "WORKSHOP_TAB_SHOW", str(names[i]))
		if i == chosen:
			StageHeroMaterial.button(b, "tab", 12.0)
			b.add_theme_color_override("font_outline_color", Color("#120C2A"))
			b.add_theme_constant_override("outline_size", UI.px(3))
		else:
			for state: String in ["normal", "hover", "pressed", "disabled", "focus"]:
				b.add_theme_stylebox_override(state, StyleBoxEmpty.new())
			for c: String in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color",
					"font_hover_pressed_color"]:
				b.add_theme_color_override(c, StageHeroSkin.LIGHT_SOFT)
		row.add_child(b)
	var p := StageHeroMaterial.panel("well", row, 16.0, 3.0)
	p.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return p


## A stat as the design draws one: its name and number above a bar filled to
## `fraction` in `colour`; read aloud as name and number.
static func stat(name: String, number: String, fraction: float, colour: Color, glyph := "") -> Control:
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", UI.px(3))
	var top := HBoxContainer.new()
	if glyph != "":
		top.add_child(words(glyph, 15.0, colour))
	var n := words(name, 15.0, StageHeroSkin.LIGHT_SOFT)
	n.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	n.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(n)
	var value := words(number, 20.0, Color("#FFF3CC"))
	value.add_theme_font_override("font", StageHeroSkin.numbers_font())
	top.add_child(value)
	v.add_child(top)
	v.add_child(StageHeroBar.make(fraction, colour, "", 12.0))
	v.accessibility_name = Strings.t("CHARACTER_STAT_SPOKEN", [name, number])
	return v


## Two columns of cards that fall to one at large text (§20.8).
static func grid(cells: Array, screen: Control) -> GridContainer:
	var g := GridContainer.new()
	g.columns = 1 if StageHeroSkin.columns(screen, 150.0) < 2 else 2
	g.add_theme_constant_override("h_separation", UI.px(8))
	g.add_theme_constant_override("v_separation", UI.px(8))
	g.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	for c: Control in cells:
		c.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		g.add_child(c)
	return g


## The design's round arrow on a stage: a leather disc with a light chevron.
static func arrow(back: bool, spoken: String, go: Callable) -> Button:
	var b := UI.button("‹" if back else "›", go, false, Color(), spoken)
	StageHeroMaterial.button(b, "leather", 20.0)
	b.add_theme_font_size_override("font_size", UI.text_px(30))
	b.add_theme_font_override("font", StageHeroSkin.numbers_font())
	b.set_meta("points", 30.0)
	b.custom_minimum_size = Vector2.ONE * UI.px(48)
	return b


## A character's name plate: the name in Marcellus, light, edged in ink; and
## under it its school on a chip in the school's colour with its shape
## (§21.2), and `sub` (its kind and role).
static func name_plate(name: Label, school: String, sub: String) -> Control:
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", UI.px(4))
	StageHeroSkin.named(name)
	name.add_theme_font_size_override("font_size", UI.text_px(32))
	name.set_meta("points", 32.0)
	name.add_theme_color_override("font_color", StageHeroSkin.LIGHT)
	name.add_theme_color_override("font_outline_color", Color("#120C2A"))
	name.add_theme_constant_override("outline_size", UI.px(2))
	name.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	name.set_meta("own_ink", true)
	v.add_child(name)
	var line := HFlowContainer.new()
	line.add_theme_constant_override("h_separation", UI.px(8))
	var colour: Color = Palette.SCHOOL.get(school, Palette.MOTION)
	line.add_child(chip(Strings.t("SCHOOL_" + school.to_upper()).to_upper(),
		"#" + colour.darkened(0.55).to_html(false), UI.SHAPE_GLYPH.get(Tokens.shape(school), "")))
	var under := words(sub, 16.0, StageHeroSkin.LIGHT_SOFT)
	under.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	line.add_child(under)
	v.add_child(line)
	return v


## The level on a gold hexagon, a bar of the levels its home allows, and its
## health on a chip (none when `health` is negative).
static func level_row(level: int, top: int, health := -1) -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", UI.px(10))
	top = maxi(1, top)
	row.add_child(StageHeroHex.make(str(level), Strings.t("CHARACTER_LEVEL_SHORT"), 58.0))
	var v := VBoxContainer.new()
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	v.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	v.add_theme_constant_override("separation", UI.px(4))
	var said := words(Strings.t("CHARACTER_LEVEL_OF", [level, top]), 15.0, StageHeroSkin.LIGHT_SOFT)
	said.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	v.add_child(said)
	v.add_child(StageHeroBar.make(float(level) / float(top), Color("#E9B65C"), "", 14.0))
	row.add_child(v)
	if health >= 0:
		var heart := chip("%d" % health, "card", "♥")
		heart.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		heart.accessibility_name = Strings.t("CHARACTER_STAT_SPOKEN", [Strings.t("CHARACTER_STAT_HEALTH"), str(health)])
		row.add_child(heart)
	return row
