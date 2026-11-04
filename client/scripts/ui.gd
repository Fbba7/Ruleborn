class_name UI
## The pieces every screen is built from, so §21.1's, §21.8's and §20.8's
## rules are applied in one place: the night backdrop, a safe-area column,
## the designs' surfaces (violet cards, leather, parchment, gold), labels and
## buttons in Manrope and Marcellus at the stated sizes, rows that wrap when
## the text is large, words that say what a colour says, banners, and a name
## for every control a screen reader reaches. Each surface is a material
## drawn by RbBox (ui/rb_box.gd); the type is RbTheme's. Richer pieces (tabs,
## headers, pills, chips, sheets) are in ui/kit_*.gd.

## What a status says, with the glyph that says it without colour (§20.8:
## "no information carried by colour alone").
const GLYPH := {"success": "✓", "alarm": "!", "info": "ⓘ", "confirming": "…"}
## §21.2's school shapes as glyphs, for words that name a school.
const SHAPE_GLYPH := {"chevron": "^", "cube": "■", "hourglass": "⧗", "bolt": "ϟ", "leaf": "❦", "eye": "◉"}
## kit-spec.md section 5 (`report.md` section 7's rule 2): words in their own z layer, one above the
## art they stand on, so the art batches apart from the words.
const WORDS_Z := 1
## A layer laid over the earlier children of its parent (a screen's column
## over its sky, a menu or dialog over the screen) stands this far above the
## sibling before it, so it covers that sibling's words as well as its art.
const OVERLAY_Z := 16

## §21.1: "Primary controls are at least 9 mm across — about 48 points". The
## base frame is 1080 pixels for a 360-point-wide phone, so 3 pixels a point.
static var PX_PER_POINT: float = Tokens.number("size", "px_per_point")
static var CONTROL_POINTS: float = Tokens.number("size", "control_points")
## §21.8: body text "at least 16 pixels", nothing smaller than 13 points.
static var TEXT_POINTS: float = Tokens.number("size", "body_points")
static var TITLE_POINTS: float = Tokens.number("size", "title_points")
static var _rooted := false



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


## §21.8's night backdrop behind everything ("menus stand on a night
## backdrop"), with its stars, and a column inside §21.1's safe areas: 44
## points clear of the notch and the home bar. The screen takes the dark
## family's type, so its words are light.
static func frame(screen: Control) -> VBoxContainer:
	screen.set_anchors_preset(Control.PRESET_FULL_RECT)
	root_theme()
	screen.theme = RbTheme.of("dark")
	var night := Tokens.material("night")
	screen.set_meta("text_bg", night["text_bg"])
	screen.set_meta("rb_family", "dark")
	# The backdrop is drawn by the kit's box behind a clear texture, so a
	# screen that paints its own sky (a galaxy, a dusk) lays it over the top.
	var sky := TextureRect.new()
	var clear := Gradient.new()
	clear.set_color(0, Color(0, 0, 0, 0))
	clear.set_color(1, Color(0, 0, 0, 0))
	var texture := GradientTexture2D.new()
	texture.gradient = clear
	texture.fill_from = Vector2(0, 0)
	texture.fill_to = Vector2(0, 1)
	texture.width = 4
	texture.height = 4
	sky.texture = texture
	sky.stretch_mode = TextureRect.STRETCH_SCALE
	sky.set_anchors_preset(Control.PRESET_FULL_RECT)
	sky.mouse_filter = Control.MOUSE_FILTER_IGNORE
	sky.name = "Sky"
	RbBox.dress(sky, "night", 0)
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
	f.add_theme_font_override("font", bold_font())
	var ink := Tokens.color("parchment_ink")
	f.add_theme_color_override("font_color", ink)
	f.add_theme_color_override("font_placeholder_color", Tokens.color("parchment_text_2"))
	f.add_theme_color_override("caret_color", ink)
	for state: String in ["normal", "focus", "read_only"]:
		f.add_theme_stylebox_override(state, clear_box(10, 6))
	var box := RbBox.dress(f, "parchment", Tokens.number("size", "radius_m"))
	# Where the words go: a gold edge while the field has the keyboard.
	f.focus_entered.connect(box.set_chosen.bind(true))
	f.focus_exited.connect(box.set_chosen.bind(false))
	f.set_meta("points", TEXT_POINTS)
	f.set_meta("bold", true)
	raise_words(f)
	return f


## `wraps` only for a label with the width of its row to itself: a wrapping
## label inside a row asks for no width and so for one word a line.
static func label(text := "", points := -1.0, wraps := false) -> Label:
	if points < 0:
		points = TEXT_POINTS
	root_theme()
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", text_px(points))
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.tree_entered.connect(RbTheme.adapt.bind(l))
	if wraps:
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.set_meta("points", points)
	raise_words(l)
	return l


## Puts control `c`'s words in the words' z layer (`WORDS_Z`, kit-spec.md
## section 7's rule 2): a label, a button or a field draws its words in its
## own canvas item, so the control rises and the kit's box behind it, if it
## has one, keeps the art's layer.
static func raise_words(c: CanvasItem) -> void:
	c.z_index = WORDS_Z
	c.set_meta("rb_words", true)
	var box := RbBox.of(c as Control) if c is Control else null
	if box != null:
		box.z_index = -WORDS_Z


## kit-spec.md section 5: a full-screen layer over earlier children of a
## parent that does not lay them out (a screen's column over its sky; a
## menu, a sheet or a dialog over the screen) stands `OVERLAY_Z` above the
## sibling before it, so the words below it, a layer up from their art, stay
## under it as they did when every control shared one z. The parent's layers
## are stacked again whenever its children are reordered, so a view a screen
## moves behind its column after adding it goes back under the column.
static func _layer(n: Node) -> void:
	var c := n as Control
	var parent := c.get_parent() as Control if c != null else null
	if parent == null or parent is Container or not _layered(c):
		return
	if not parent.has_meta("rb_stacked"):
		parent.set_meta("rb_stacked", true)
		parent.child_order_changed.connect(_restack.bind(parent))
	_lift(c)


## Stacks `parent`'s full-screen layers again, in their order.
static func _restack(parent: Control) -> void:
	if not is_instance_valid(parent) or parent.is_queued_for_deletion():
		return
	for n: Node in parent.get_children():
		if n is Control and _layered(n):
			_lift(n)


## Whether `c` is a full-screen layer the kit stacks: full rect, in the
## parent's z, and at the z the kit gave it (a control a screen gave its own
## z keeps it).
static func _layered(c: Control) -> bool:
	if c.top_level or not c.z_as_relative:
		return false
	if c.anchor_right < 1.0 or c.anchor_bottom < 1.0 or c.anchor_left > 0.0 or c.anchor_top > 0.0:
		return false
	return c.z_index == int(c.get_meta("rb_layer", WORDS_Z if c.has_meta("rb_words") else 0))


## Puts layer `c` `OVERLAY_Z` above the canvas item before it, or back at
## the parent's z when nothing is before it.
static func _lift(c: Control) -> void:
	var siblings := c.get_parent().get_children()
	var below: CanvasItem = null
	for i: int in range(siblings.find(c) - 1, -1, -1):
		if siblings[i] is CanvasItem:
			below = siblings[i]
			break
	var own := WORDS_Z if c.has_meta("rb_words") else 0
	var z := own
	if below != null:
		z = below.z_index - (WORDS_Z if below.has_meta("rb_words") else 0) + OVERLAY_Z + own
	c.z_index = mini(z, RenderingServer.CANVAS_ITEM_Z_MAX)
	c.set_meta("rb_layer", c.z_index)


## A screen's title in Marcellus (§21.8), with the designs' hard drop under
## it and their gold rule beneath.
static func title(text: String) -> Label:
	var l := label(text, TITLE_POINTS, true)
	l.theme_type_variation = "Title"
	l.accessibility_live = AccessibilityServer.LIVE_OFF
	var rule := KitNav.rule()
	rule.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	rule.grow_horizontal = Control.GROW_DIRECTION_BOTH
	rule.grow_vertical = Control.GROW_DIRECTION_BEGIN
	rule.position.y = -px(2)
	# The rule is art: back in the art's layer under its words.
	rule.z_index = -WORDS_Z
	l.add_child(rule, false, Node.INTERNAL_MODE_FRONT)
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
	# The family's shade for the status (§21.8: alarm and success words are
	# bold, deep on parchment and light on dark), from the theme around it.
	l.remove_theme_color_override("font_color")
	# A status carried on a fill draws none while it says nothing.
	if text == "":
		l.add_theme_stylebox_override("normal", StyleBoxEmpty.new())
	else:
		l.remove_theme_stylebox_override("normal")
	l.theme_type_variation = "Status" + kind.capitalize()
	l.set_meta("status", kind)
	l.set_meta("bold", kind == "alarm" or kind == "success")


## Words on their own card, so they read over anything (§21.8).
static func plate(words: Control, look := "card") -> PanelContainer:
	var p := panel(look)
	p.add_child(words)
	# A plate whose words are still empty is not drawn until they come.
	var box := RbBox.of(p)
	box.hide_empty = true
	words.minimum_size_changed.connect(box.queue_redraw)
	return p


## §21.8's surfaces: a violet card by default; "parchment", "glass" over the
## world, "leather", or any tokens.json `material`. The panel's words take
## the material's family of colours.
static func panel(look := "card") -> PanelContainer:
	root_theme()
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", clear_box(10, 8))
	dress(p, look)
	return p


## A control dressed in a material: its box behind it and its family's
## type for everything inside it.
static func dress(c: Control, look: String, radius := -1.0) -> RbBox:
	var box := RbBox.dress(c, look, radius)
	c.theme = RbTheme.of_material(look)
	# A box behind words is art: in the art's layer, under the words' one.
	if c.has_meta("rb_words"):
		box.z_index = -WORDS_Z
	return box


## A StyleBoxFlat that draws nothing, with content margins in points: the
## box a dressed control keeps, so scripts that round or edge a control's
## own box still find one.
static func clear_box(side_points: float, top_points: float) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = Color(0, 0, 0, 0)
	box.draw_center = false
	box.set_corner_radius_all(0)
	box.content_margin_left = px(side_points)
	box.content_margin_right = px(side_points)
	box.content_margin_top = px(top_points)
	box.content_margin_bottom = px(top_points)
	return box


## The kit's theme on the whole window, so any control a screen makes on its
## own is drawn in Manrope with light words, as the night backdrop wants.
static func root_theme() -> void:
	if _rooted:
		return
	var tree := Engine.get_main_loop() as SceneTree
	if tree != null and tree.root != null:
		tree.root.theme = RbTheme.of("dark")
		tree.node_added.connect(_layer)
		_rooted = true


## §21.8: "gold for main actions"; leather for the rest, red for an alarm
## fill and green for a success one. It squashes and sinks onto its drop
## when pressed. A screen reader says a button's text; `spoken` replaces it
## for a button whose text is a symbol ("+", "‹").
static func button(text: String, pressed: Callable, main := false, fill := Color(), spoken := "") -> Button:
	var look := "gold" if main else "leather"
	if fill != Color():
		look = "red" if fill.is_equal_approx(Palette.ALARM) or fill.is_equal_approx(Palette.ALARM_FILL) else \
			("green" if fill.is_equal_approx(Palette.SUCCESS) else look)
	return action(text, pressed, look, spoken)


## A button in any material (tokens.json `material`): "gold", "leather",
## "red", "green", "ghost", "parchment", "card"...
static func action(text: String, pressed: Callable, look := "leather", spoken := "") -> Button:
	root_theme()
	var b := Button.new()
	b.text = text
	b.accessibility_name = spoken
	b.custom_minimum_size = Vector2.ONE * CONTROL_POINTS * PX_PER_POINT
	b.add_theme_font_size_override("font_size", text_px(TEXT_POINTS))
	# A control's words are short and bold: APCA's level for them (Lc 60), as
	# body text on a panel carries Lc 75 (ui/colour_check.gd).
	b.add_theme_font_override("font", bold_font())
	b.set_meta("bold", true)
	for state: String in ["normal", "hover", "pressed", "focus", "disabled"]:
		b.add_theme_stylebox_override(state, clear_box(9, 4))
	set_look(b, look)
	raise_words(b)
	b.set_meta("points", TEXT_POINTS)
	fit(b)
	b.button_down.connect(Motion.press.bind(b, true))
	b.button_up.connect(Motion.press.bind(b, false))
	b.set_meta("kit_press", true)
	b.pressed.connect(func() -> void: Haptics.play("tap"))
	b.pressed.connect(pressed)
	return b


## A button's material changed, its words recoloured to suit (a chip
## turning on).
static func set_look(b: Button, look: String) -> void:
	var box := dress(b, look)
	var words: Color = box.spec["text"]
	for colour: String in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color",
			"font_hover_pressed_color"]:
		b.add_theme_color_override(colour, words)
	b.add_theme_color_override("font_disabled_color", Color(words, 0.55))
	if box.spec.has("text_outline"):
		b.add_theme_color_override("font_outline_color", box.spec["text_outline"][0])
		b.add_theme_constant_override("outline_size", px(box.spec["text_outline"][1]))
	else:
		b.remove_theme_constant_override("outline_size")
	# Light words on a dark or deep control stand on the designs' hard drop.
	if words.get_luminance() > 0.6:
		b.add_theme_color_override("font_shadow_color", Tokens.color("drop"))
		b.add_theme_constant_override("shadow_offset_x", 0)
		b.add_theme_constant_override("shadow_offset_y", maxi(2, px(0.75)))
		b.add_theme_constant_override("shadow_outline_size", px(box.spec["text_outline"][1]) if box.spec.has(
			"text_outline") else 0)
	else:
		b.remove_theme_color_override("font_shadow_color")


## Manrope at 800, as §21.8 draws 900: a control's words.
static func bold_font() -> Font:
	return Tokens.font("ui", 800)


## A button's width for its words: as wide as they are, up to the widest a
## control may be, past which they wrap onto more lines (§20.8's large text).
static func fit(b: Button) -> void:
	var font := b.get_theme_font("font")
	# The designs' chunky pills: 9 points of material either side of the words.
	var natural := font.get_string_size(b.text, HORIZONTAL_ALIGNMENT_LEFT, -1, b.get_theme_font_size("font_size")).x \
		+ px(18)
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
	var box := RbBox.of(b)
	if box != null:
		box.set_chosen(points > 1)
		return
	for state: String in ["normal", "hover", "pressed", "focus"]:
		var flat := b.get_theme_stylebox(state) as StyleBoxFlat
		if flat != null:
			flat.set_border_width_all(px(points))


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
	var p := panel("banner_" + kind if kind in ["alarm", "success"] else "banner_info")
	p.name = "Banner"
	var r := row()
	var words := status(kind, text)
	words.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	words.accessibility_live = AccessibilityServer.LIVE_ASSERTIVE if kind == "alarm" else AccessibilityServer.LIVE_POLITE
	r.add_child(words)
	# The designs' bare cross, a 48-point target all the same.
	var close := action("×", p.queue_free, "seg", Strings.t("COMMON_DISMISS"))
	close.add_theme_font_size_override("font_size", px(26))
	close.add_theme_color_override("font_color", Tokens.color("text_on_night_2"))
	r.add_child(close)
	p.add_child(r)
	p.ready.connect(func() -> void: Motion.pop(p))
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
