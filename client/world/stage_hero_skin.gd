class_name StageHeroSkin
extends RefCounted
## §21.8's two families of surface for the character screens: menus on the
## night backdrop, dark violet cards with light words, parchment plates with
## brown ink, each outlined in ink; gold for the main action and leather for
## the rest; Lilita One for numbers that do not change, Marcellus for names.
## The words are the screens' own; this only dresses them.

## §21.2: "Menus stand on a night backdrop (#171046 to #2C3AA8)".
const NIGHT_TOP := Color("#171046")
const NIGHT_BOTTOM := Color("#2C3AA8")
## §21.8: "a violet card from #261A4C to #1A1134 … with light text #F3EEFF".
const CARD := Color("#241848")
const CARD_EDGE := Color("#3A2A6E")
const LIGHT := Color("#F3EEFF")
## §21.8: secondary words on a dark surface are no darker than #B8A8D8.
const LIGHT_SOFT := Color("#DCD2F2")
## §21.8: "Parchment: #FFFBF0 to #F1E3C4 with brown ink #2A1A10".
const PARCHMENT := Color("#F8EEDA")
const PARCHMENT_EDGE := Color("#E6D3AC")
const BROWN := Color("#2A1A10")
## §21.8: "Each family is outlined in ink #1A0C14".
const OUTLINE := Color("#1A0C14")
## Leather, for a control that is not the main action on a dark surface.
const LEATHER := Color("#7A4E36")
const GOLD := Color("#F2B43C")

static var _numbers: FontFile = null
static var _names: FontFile = null


## The night backdrop behind a screen built by UI.frame.
static func night(screen: Control) -> void:
	var sky := screen.get_node_or_null("Sky") as TextureRect
	if sky == null:
		return
	# What words drawn straight on the night sit on, for the contrast checks.
	screen.set_meta("behind", [NIGHT_TOP, NIGHT_BOTTOM] as Array[Color])
	var gradient := Gradient.new()
	gradient.set_color(0, NIGHT_TOP)
	gradient.set_color(1, NIGHT_BOTTOM)
	(sky.texture as GradientTexture2D).gradient = gradient


## An outline's width in pixels: 1 point, 3 in high contrast (§21.8).
static func edge_px() -> int:
	return UI.px(3 if Settings.high_contrast else 1)


static func box(fill: Color, corner_points := 14.0, shadow := true) -> StyleBoxFlat:
	var b := StyleBoxFlat.new()
	b.bg_color = fill
	b.border_color = OUTLINE
	b.set_border_width_all(edge_px())
	b.set_corner_radius_all(UI.px(corner_points))
	b.set_content_margin_all(UI.px(10))
	if shadow:
		b.shadow_color = Color(0.04, 0.0, 0.1, 0.45)
		b.shadow_size = UI.px(2)
		b.shadow_offset = Vector2(0, UI.px(2))
	return b


## A parchment plate (`dark` false) or a violet card (`dark` true) holding
## `words`; every label in it takes the family's ink.
static func plate(words: Control, dark := false) -> PanelContainer:
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", box(CARD if dark else PARCHMENT))
	p.add_child(words)
	ink(p, dark)
	return p


## Gives every label under `node` the family's ink, keeping a status's own
## alarm or success colour on parchment.
static func ink(node: Node, dark: bool) -> void:
	for l: Label in node.find_children("*", "Label", true, false):
		var kind := str(l.get_meta("status", ""))
		if not dark and kind in ["alarm", "success"] or l.has_meta("own_ink"):
			continue
		l.add_theme_color_override("font_color", LIGHT if dark else BROWN)


## A screen's title on its dark pill, in Marcellus.
static func title(label: Label) -> PanelContainer:
	label.add_theme_font_override("font", names_font())
	var p := plate(label, true)
	var b := p.get_theme_stylebox("panel") as StyleBoxFlat
	b.set_corner_radius_all(UI.px(24))
	b.content_margin_top = UI.px(4)
	b.content_margin_bottom = UI.px(6)
	return p


## A name in Marcellus, as §21.8 sets names.
static func named(label: Label) -> Label:
	label.add_theme_font_override("font", names_font())
	return label


## A number that does not change, in Lilita One (§21.8), on a round badge
## in `fill`.
static func badge(text: String, fill: Color, points := 18.0) -> PanelContainer:
	var l := UI.label(text, points)
	l.add_theme_font_override("font", numbers_font())
	l.add_theme_color_override("font_color", LIGHT if fill.get_luminance() < 0.5 else BROWN)
	l.set_meta("own_ink", true)
	l.add_theme_color_override("font_outline_color", OUTLINE)
	l.add_theme_constant_override("outline_size", UI.px(1))
	var p := PanelContainer.new()
	var b := box(fill, 99.0, false)
	b.set_content_margin_all(UI.px(3))
	b.content_margin_left = UI.px(8)
	b.content_margin_right = UI.px(8)
	p.add_theme_stylebox_override("panel", b)
	p.add_child(l)
	p.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	p.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	return p


## Dresses a UI.button: gold with brown ink for the main action, leather with
## light words otherwise, with a darker lip beneath and a slight squash when
## pressed (§21.8: "buttons squash slightly when pressed").
static func button(b: Button, main := false) -> Button:
	var fill := GOLD if main else LEATHER
	var words := BROWN if main else LIGHT
	for state: String in ["normal", "hover", "pressed", "focus", "disabled"]:
		var s := box(fill, 12.0, false)
		s.set_content_margin_all(UI.px(6))
		s.border_width_bottom = edge_px() + UI.px(2)
		match state:
			"hover":
				s.bg_color = fill.lightened(0.06)
			"pressed":
				s.bg_color = fill.lightened(0.12)
				s.border_width_bottom = edge_px()
			"focus":
				s.border_width_left = edge_px() + UI.px(1)
				s.border_width_right = edge_px() + UI.px(1)
				s.border_width_top = edge_px() + UI.px(1)
			"disabled":
				s.bg_color = Color(fill.darkened(0.3), 0.6)
		b.add_theme_stylebox_override(state, s)
	for colour: String in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		b.add_theme_color_override(colour, words)
	b.add_theme_color_override("font_disabled_color", Color(LIGHT, 0.75))
	b.button_down.connect(func() -> void: _squash(b, 0.95))
	b.button_up.connect(func() -> void: _squash(b, 1.0))
	return b


## A control that reads as a name on its card: the card's own fill, brown ink in
## Marcellus, an ink underline, a full outline only when focused.
static func flat(b: Button, points := 22.0) -> Button:
	for state: String in ["normal", "hover", "pressed", "focus", "disabled"]:
		var s := StyleBoxFlat.new()
		s.bg_color = PARCHMENT if state != "pressed" else PARCHMENT_EDGE
		s.border_color = OUTLINE
		s.border_width_bottom = edge_px()
		if state == "focus":
			s.set_border_width_all(edge_px() + UI.px(1))
		s.set_corner_radius_all(UI.px(8))
		s.set_content_margin_all(UI.px(4))
		b.add_theme_stylebox_override(state, s)
	for colour: String in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		b.add_theme_color_override(colour, BROWN)
	b.add_theme_font_override("font", names_font())
	b.add_theme_font_size_override("font_size", UI.text_px(points))
	b.set_meta("bold", false)
	b.set_meta("points", points)
	return b


static func _squash(b: Button, to: float) -> void:
	if not b.is_inside_tree() or Settings.reduced_motion:
		return
	b.pivot_offset = b.size / 2.0
	var t := b.create_tween()
	t.set_ease(Tween.EASE_OUT)
	t.set_trans(Tween.TRANS_QUAD)
	t.tween_property(b, "scale", Vector2(to, to), 0.12)


static func numbers_font() -> Font:
	if _numbers == null:
		_numbers = load("res://world/stage_hero_numbers.woff2") as FontFile
		if _numbers != null:
			_numbers.fallbacks = [ThemeDB.fallback_font]
	return _numbers if _numbers != null else ThemeDB.fallback_font


static func names_font() -> Font:
	if _names == null:
		_names = load("res://world/stage_hero_names.woff2") as FontFile
		if _names != null:
			_names.fallbacks = [ThemeDB.fallback_font]
	return _names if _names != null else ThemeDB.fallback_font


## A portrait on its school's ground (§21.2): a rounded tile in the school's
## colour, lighter where the character stands, the portrait rendered from its
## model over it (Portrait). `side_points` is its height.
static func portrait_tile(kind: String, look := "", side_points := 104.0) -> PanelContainer:
	var school := StageHeroFigure.school(StageHeroFigure.key(kind))
	var main: Color = Palette.SCHOOL.get(school, Palette.MOTION)
	# The tile: an outer holder that badges pin to, and inside it a rounded,
	# clipped frame with the ground and the portrait, so badges stay unclipped.
	var tile := PanelContainer.new()
	tile.add_theme_stylebox_override("panel", StyleBoxEmpty.new())
	var holder := Control.new()
	holder.custom_minimum_size = Vector2(UI.px(48), UI.px(side_points))
	holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tile.add_child(holder)
	var frame := Panel.new()
	var b := box(main.darkened(0.35), 12.0, false)
	frame.add_theme_stylebox_override("panel", b)
	frame.clip_children = CanvasItem.CLIP_CHILDREN_AND_DRAW
	frame.set_anchors_preset(Control.PRESET_FULL_RECT)
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	holder.add_child(frame)
	var glow := TextureRect.new()
	var tex := GradientTexture2D.new()
	tex.fill = GradientTexture2D.FILL_RADIAL
	tex.fill_from = Vector2(0.5, 0.42)
	tex.fill_to = Vector2(1.05, 0.42)
	var grad := Gradient.new()
	grad.set_color(0, main.lightened(0.35) if look != "shadow" else Color("#5A4A8A"))
	grad.set_color(1, main.darkened(0.3) if look != "shadow" else Color("#2A1E52"))
	tex.gradient = grad
	glow.texture = tex
	glow.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	glow.stretch_mode = TextureRect.STRETCH_SCALE
	glow.set_anchors_preset(Control.PRESET_FULL_RECT)
	glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	frame.add_child(glow)
	var picture := TextureRect.new()
	picture.texture = Portrait.of(kind, look)
	picture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	picture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	picture.set_anchors_preset(Control.PRESET_FULL_RECT)
	picture.mouse_filter = Control.MOUSE_FILTER_IGNORE
	picture.name = "Portrait"
	frame.add_child(picture)
	tile.set_meta("kind", kind)
	return tile


## A badge pinned to a corner of a tile (`corner` one of Control's
## PRESET_TOP_LEFT and the like).
static func pin(tile: Control, what: Control, corner: int) -> void:
	var holder := tile.get_child(0) as Control
	var m := MarginContainer.new()
	m.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	m.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for side: String in ["margin_left", "margin_right", "margin_top", "margin_bottom"]:
		m.add_theme_constant_override(side, UI.px(4))
	what.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN if corner in [Control.PRESET_TOP_LEFT,
		Control.PRESET_BOTTOM_LEFT] else Control.SIZE_SHRINK_END
	what.size_flags_vertical = Control.SIZE_SHRINK_BEGIN if corner in [Control.PRESET_TOP_LEFT,
		Control.PRESET_TOP_RIGHT] else Control.SIZE_SHRINK_END
	m.add_child(what)
	holder.add_child(m)


## How many cards a row holds at this width and text size: two on a phone,
## one at large text, three on a wide frame.
static func columns(screen: Control, card_points := 150.0) -> int:
	var wide := screen.get_viewport_rect().size.x if screen.is_inside_tree() else 1080.0
	var usable := wide / UI.PX_PER_POINT - 40.0
	var per := card_points * maxf(1.0, Settings.text_scale / 100.0)
	return clampi(int(usable / per), 1, 3)


## Caps every button under `node` at `wide` pixels, its words wrapping, so
## a card never asks for more than its column.
static func cap_buttons(node: Node, wide: float) -> void:
	for b: Button in node.find_children("*", "Button", true, false):
		if b.custom_minimum_size.x > wide:
			b.custom_minimum_size.x = wide
			b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART


## Words on a stage (§21.8's dark glass pill over the world): a rounded
## dark card with light words, its name in Marcellus when `named`.
static func pill(text: String, named_words := false, points := -1.0) -> PanelContainer:
	var l := UI.label(text, points if points > 0.0 else UI.TEXT_POINTS)
	if named_words:
		l.add_theme_font_override("font", names_font())
	var p := plate(l, true)
	var b := p.get_theme_stylebox("panel") as StyleBoxFlat
	b.set_corner_radius_all(UI.px(99))
	b.content_margin_top = UI.px(3)
	b.content_margin_bottom = UI.px(4)
	b.content_margin_left = UI.px(12)
	b.content_margin_right = UI.px(12)
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return p


## Pins `what` to a stage's edge (`corner` as Control's presets: top-right,
## bottom-centre …), above the 3D, clear of its edge by 8 points. Returns the
## holder, which a refresh frees.
static func on_stage(stage: Control, what: Control, corner: int) -> Control:
	var m := MarginContainer.new()
	m.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	m.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for side: String in ["margin_left", "margin_right", "margin_top", "margin_bottom"]:
		m.add_theme_constant_override(side, UI.px(8))
	var right := corner in [Control.PRESET_TOP_RIGHT, Control.PRESET_BOTTOM_RIGHT, Control.PRESET_CENTER_RIGHT]
	var centre := corner in [Control.PRESET_CENTER_TOP, Control.PRESET_CENTER_BOTTOM]
	what.size_flags_horizontal = Control.SIZE_SHRINK_END if right else (Control.SIZE_SHRINK_CENTER if centre
		else Control.SIZE_SHRINK_BEGIN)
	what.size_flags_vertical = Control.SIZE_SHRINK_END if corner in [Control.PRESET_BOTTOM_LEFT,
		Control.PRESET_BOTTOM_RIGHT, Control.PRESET_CENTER_BOTTOM] else (Control.SIZE_SHRINK_CENTER if corner in [
		Control.PRESET_CENTER_LEFT, Control.PRESET_CENTER_RIGHT] else Control.SIZE_SHRINK_BEGIN)
	m.add_child(what)
	stage.add_child(m)
	return m
