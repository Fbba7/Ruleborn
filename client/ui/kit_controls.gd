class_name KitControls
## The kit's controls past UI.button: chips that turn on and off, round
## actions with a name plate (the designs' MAP, WEAVE and BUILD), icon
## buttons, and a toggle row for settings. Each is at least §21.1's 48
## points and squashes when pressed (§21.8).


## A chip: glass when off, gold when on. It is a control, so it is 48 points
## tall (§21.1), not the designs' 30. A `dot` in a state's colour leads its
## words and a `count` follows them on a dark disc (the Roster's filters).
static func chip(text: String, on: bool, pressed: Callable, count := "", dot := Color(0, 0, 0, 0)) -> Button:
	var b := UI.action(text, pressed, "chip_on" if on else "chip")
	b.name = "Chip"
	b.custom_minimum_size.y = UI.px(Tokens.number("size", "chip_height"))
	set_chip(b, on)
	if dot.a > 0.0 or count != "":
		var pad := UI.clear_box(9, 4)
		pad.content_margin_left = UI.px(9 + (16 if dot.a > 0.0 else 0))
		# Room for the count's disc at the chip's end, as wide as its figures
		# are at the player's text size.
		var disc := UI.text_px(13) * 0.62 * count.length() + UI.px(16)
		pad.content_margin_right = UI.px(9) + (disc if count != "" else 0.0)
		for state: String in ["normal", "hover", "pressed", "focus", "disabled", "hover_pressed"]:
			b.add_theme_stylebox_override(state, pad)
		b.custom_minimum_size.x = 0
	if dot.a > 0.0:
		var d := KitRing.new()
		d.dot = true
		d.fraction = 1.0
		d.tint = dot
		d.mouse_filter = Control.MOUSE_FILTER_IGNORE
		d.set_anchors_preset(Control.PRESET_CENTER_LEFT)
		d.offset_left = UI.px(10)
		d.offset_right = UI.px(22)
		d.offset_top = -UI.px(6)
		d.offset_bottom = UI.px(6)
		b.add_child(d)
	if count != "":
		var c := PanelContainer.new()
		c.add_theme_stylebox_override("panel", UI.clear_box(5, 0))
		UI.dress(c, "level_disc")
		c.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var n := UI.label(count, 13)
		n.theme_type_variation = "Number"
		n.set_meta("bold", true)
		c.add_child(n)
		c.set_anchors_preset(Control.PRESET_CENTER_RIGHT)
		c.grow_horizontal = Control.GROW_DIRECTION_BEGIN
		c.grow_vertical = Control.GROW_DIRECTION_BOTH
		c.offset_right = -UI.px(8)
		b.add_child(c)
	return b


## An action with a second line under its words (the Roster's "Level up"
## over "866 Essence"): what it does, and what it costs or needs.
static func action2(text: String, line: String, pressed: Callable, look := "gold", icon := "") -> Button:
	var b := UI.action("", pressed, look, "%s, %s" % [text, line] if line != "" else text)
	b.name = "Action"
	# Its words are drawn inside it, not laid out by it, so its height is
	# their two lines at the player's text size.
	var lines := UI.text_px(16) + (UI.text_px(13) if line != "" else 0)
	b.custom_minimum_size = Vector2(UI.px(120), maxf(UI.px(56), lines * 1.3 + UI.px(12)))
	var v := VBoxContainer.new()
	v.set_anchors_preset(Control.PRESET_FULL_RECT)
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	v.add_theme_constant_override("separation", -UI.px(2))
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var box := RbBox.of(b)
	var top: Control = v
	if icon != "":
		# A price: the currency's icon before its amount.
		var h := HBoxContainer.new()
		h.alignment = BoxContainer.ALIGNMENT_CENTER
		h.add_theme_constant_override("separation", UI.px(4))
		h.mouse_filter = Control.MOUSE_FILTER_IGNORE
		h.add_child(Icons.view(icon, 20))
		v.add_child(h)
		top = h
	var t := UI.label(text, 16)
	t.add_theme_font_override("font", UI.bold_font())
	t.add_theme_color_override("font_color", box.spec["text"])
	t.set_meta("bold", true)
	# A gold call to action is set in the designs' tracked capitals.
	if look == "gold":
		t.uppercase = true
		t.add_theme_font_override("font", Tokens.font("ui", 800, false, UI.px(1)))
	if box.spec.has("text_outline"):
		t.add_theme_color_override("font_outline_color", box.spec["text_outline"][0])
		t.add_theme_constant_override("outline_size", UI.px(box.spec["text_outline"][1]))
	top.add_child(t)
	if line == "":
		b.add_child(v)
		return b
	var s := UI.label(line, 13)
	s.add_theme_font_override("font", UI.bold_font())
	s.add_theme_color_override("font_color", box.spec["text_2"])
	s.set_meta("bold", true)
	if box.spec.has("text_outline"):
		s.add_theme_color_override("font_outline_color", box.spec["text_outline"][0])
		s.add_theme_constant_override("outline_size", UI.px(box.spec["text_outline"][1]))
	v.add_child(s)
	b.add_child(v)
	return b


## Dresses round button `b` as a disc `disc_points` across, centred in
## its hit area, which keeps its size; the disc grows with the button when
## `disc_points` is the button's own size or more.
static func small_disc(b: Button, disc_points: float) -> void:
	var box := RbBox.dress(b, str(b.get_meta("rb_material", "leather")), 999)
	var hit := func() -> void:
		box.inset = maxf(0.0, (minf(b.size.x, b.size.y) - UI.px(disc_points)) * 0.5)
	b.set_meta("disc_points", disc_points)
	if not b.resized.is_connected(hit):
		b.resized.connect(hit)
	hit.call()


## A chip turned on or off; "on" is said in the gold, the heavier edge and
## to a screen reader.
static func set_chip(b: Button, on: bool) -> void:
	UI.set_look(b, "chip_on" if on else "chip")
	b.toggle_mode = true
	b.set_pressed_no_signal(on)
	b.set_meta("chosen", on)


## A round button with an icon (the back arrow, a close cross), named for a
## screen reader. `disc_points` draws the disc smaller than the button (the
## designs' 36-point side balls) while the hit area stays `points`, never
## under §21.1's 48.
static func icon_button(icon: String, spoken: String, pressed: Callable, look := "leather", points := 48.0,
		icon_points := -1.0, disc_points := -1.0) -> Button:
	var b := UI.action("", pressed, look, spoken)
	b.name = "IconButton"
	var hit := maxf(points, UI.CONTROL_POINTS)
	b.custom_minimum_size = Vector2.ONE * UI.px(hit)
	b.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var disc := disc_points if disc_points > 0.0 else points
	small_disc(b, disc)
	var shown := icon_points if icon_points > 0.0 else disc * 0.5
	var i := Icons.view(icon, shown)
	# Centred at its size, however large the button grows.
	i.set_anchors_preset(Control.PRESET_CENTER)
	i.offset_left = -UI.px(shown) * 0.5
	i.offset_right = UI.px(shown) * 0.5
	i.offset_top = -UI.px(shown) * 0.5
	i.offset_bottom = UI.px(shown) * 0.5
	b.add_child(i)
	return b


## A round action with its name on a plate overlapping its foot (the realm
## view's MAP, WEAVE and BUILD): a disc in `tone` ("leather", "violet",
## "sky") in a gold ring on a dark plate, or, as the main one, gold on a
## leather plate; a badge's words ("1 free") ride its top right.
static func round_action(icon: String, words: String, pressed: Callable, main := false, points := 60.0,
		badge := "", tone := "leather", disc_points := -1.0) -> VBoxContainer:
	var v := VBoxContainer.new()
	v.name = "RoundAction"
	var hit := maxf(points, UI.CONTROL_POINTS)
	var disc := disc_points if disc_points > 0.0 else hit
	# The plate overlaps the disc's foot, not the hit area's.
	v.add_theme_constant_override("separation", -UI.px(minf(12.0, disc * 0.23) + (hit - disc) * 0.5))
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	var look := "gold_round" if main else ("leather" if tone == "leather" else "round_" + tone)
	var b := icon_button(icon, words, pressed, look, points, disc * 0.55, disc)
	b.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	v.add_child(b)
	if badge != "":
		var tag := KitStatus.badge(badge)
		tag.set_anchors_preset(Control.PRESET_TOP_RIGHT)
		tag.grow_horizontal = Control.GROW_DIRECTION_BEGIN
		# On the disc's shoulder, wherever the disc sits in its hit area.
		tag.position = Vector2(UI.px(2 - (hit - disc) * 0.5), -UI.px(4 - (hit - disc) * 0.5))
		b.add_child(tag)
	var plate := KitStatus.plate(words)
	UI.dress(plate, "plate_leather" if main or tone == "leather" else "plate_dark")
	plate.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	var l := plate.get_child(0) as Label
	l.theme_type_variation = "Kicker"
	l.uppercase = true
	v.add_child(plate)
	return v


## A settings row: an icon, a title and a line under it, and a switch that
## says On or Off in words; `toggled_to` is called with the new state.
static func toggle_row(icon: String, title: String, line: String, on: bool, toggled_to: Callable) -> PanelContainer:
	var p := UI.panel("card")
	p.name = "ToggleRow"
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", UI.px(10))
	if icon != "":
		row.add_child(Icons.view(icon, 28))
	var words := VBoxContainer.new()
	words.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	words.add_theme_constant_override("separation", 0)
	var t := UI.label(title, 16, true)
	t.theme_type_variation = "BodyBold"
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	t.set_meta("bold", true)
	words.add_child(t)
	if line != "":
		var s := UI.label(line, 13, true)
		s.theme_type_variation = "Secondary"
		s.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		words.add_child(s)
	row.add_child(words)
	var sw := KitSwitch.make(on, Strings.t("KIT_ON"), Strings.t("KIT_OFF"), title, toggled_to)
	sw.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(sw)
	p.add_child(row)
	return p


## A school's round filter: its mark on a dark disc ringed in the school's
## colour, gold-edged when chosen, named for a screen reader.
static func school_button(school: String, on: bool, pressed: Callable) -> Button:
	var b := icon_button("schools/" + school, Strings.t("SCHOOL_" + school.to_upper()), pressed, "ring_" + school,
		48.0, 26.0)
	b.name = "School"
	RbBox.of(b).set_chosen(on)
	b.set_meta("chosen", on)
	return b


## A search field: dark glass with the designs' magnifier before the words.
static func search(spoken: String) -> LineEdit:
	var f := UI.field(spoken)
	f.name = "Search"
	UI.dress(f, "field_glass", 12)
	for c: String in ["font_color", "caret_color"]:
		f.add_theme_color_override(c, Tokens.color("text_on_night"))
	f.add_theme_color_override("font_placeholder_color", Tokens.color("text_on_night_2"))
	f.right_icon = null
	var pad := UI.clear_box(10, 6)
	pad.content_margin_left = UI.px(40)
	for state: String in ["normal", "focus", "read_only"]:
		f.add_theme_stylebox_override(state, pad)
	var glass := Icons.view("generalui/search", 22)
	glass.set_anchors_preset(Control.PRESET_CENTER_LEFT)
	glass.position.x = UI.px(10)
	glass.grow_vertical = Control.GROW_DIRECTION_BOTH
	f.add_child(glass)
	return f


## A big square action with its icon over its words (the heist's Get out,
## red): 64 by 58 points as the designs draw it.
static func big_action(icon: String, words: String, pressed: Callable, look := "red") -> Button:
	var b := UI.action("", pressed, look, words)
	b.name = "BigAction"
	b.custom_minimum_size = Vector2(UI.px(76), UI.px(64))
	var v := VBoxContainer.new()
	v.set_anchors_preset(Control.PRESET_FULL_RECT)
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	v.add_theme_constant_override("separation", 0)
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_child(Icons.view(icon, 26))
	var box := RbBox.of(b)
	var l := UI.label(words, 14)
	l.add_theme_font_override("font", UI.bold_font())
	l.add_theme_color_override("font_color", box.spec["text"])
	l.set_meta("bold", true)
	if box.spec.has("text_outline"):
		l.add_theme_color_override("font_outline_color", box.spec["text_outline"][0])
		l.add_theme_constant_override("outline_size", UI.px(box.spec["text_outline"][1]))
	v.add_child(l)
	b.add_child(v)
	return b


## A big call to action with a price inside it (the Character screen's
## UPGRADE): its words in stroked capitals over a second line, and the
## price on a dark chip at its end with the currency's icon.
static func upgrade(text: String, line: String, icon: String, price: String, pressed: Callable,
		look := "green") -> Button:
	var b := action2(text, line, pressed, look)
	b.name = "Upgrade"
	b.accessibility_name = "%s, %s, %s" % [text, line, price]
	b.custom_minimum_size.y = UI.px(64)
	var v := b.get_child(0) as Control
	v.offset_right = -UI.px(96)
	(v.get_child(0) as Label).uppercase = true
	(v.get_child(0) as Label).add_theme_font_size_override("font_size", UI.text_px(20))
	(v.get_child(0) as Label).add_theme_font_override("font", Tokens.font("display"))
	var cost := PanelContainer.new()
	cost.add_theme_stylebox_override("panel", UI.clear_box(8, 3))
	UI.dress(cost, "price_chip")
	cost.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", UI.px(4))
	h.mouse_filter = Control.MOUSE_FILTER_IGNORE
	h.add_child(Icons.view(icon, 20))
	var n := UI.label(price, 16)
	n.theme_type_variation = "Number"
	n.set_meta("bold", true)
	h.add_child(n)
	cost.add_child(h)
	cost.set_anchors_preset(Control.PRESET_CENTER_RIGHT)
	cost.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	cost.grow_vertical = Control.GROW_DIRECTION_BOTH
	cost.offset_right = -UI.px(10)
	b.add_child(cost)
	return b
