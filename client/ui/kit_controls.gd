class_name KitControls
## The kit's controls past UI.button: chips that turn on and off, round
## actions with a name plate (the designs' MAP, WEAVE and BUILD), icon
## buttons, and a toggle row for settings. Each is at least §21.1's 48
## points and squashes when pressed (§21.8).


## A chip: glass when off, gold when on. It is a control, so it is 48 points
## tall (§21.1), not the designs' 30.
static func chip(text: String, on: bool, pressed: Callable) -> Button:
	var b := UI.action(text, pressed, "chip_on" if on else "chip")
	b.name = "Chip"
	b.custom_minimum_size.y = UI.px(Tokens.number("size", "chip_height"))
	set_chip(b, on)
	return b


## A chip turned on or off; "on" is said in the gold, the heavier edge and
## to a screen reader.
static func set_chip(b: Button, on: bool) -> void:
	UI.set_look(b, "chip_on" if on else "chip")
	b.toggle_mode = true
	b.set_pressed_no_signal(on)
	b.set_meta("chosen", on)


## A round button with an icon (the back arrow, a close cross), named for a
## screen reader.
static func icon_button(icon: String, spoken: String, pressed: Callable, look := "leather", points := 48.0,
		icon_points := -1.0) -> Button:
	var b := UI.action("", pressed, look, spoken)
	b.name = "IconButton"
	b.custom_minimum_size = Vector2.ONE * UI.px(maxf(points, UI.CONTROL_POINTS))
	b.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	RbBox.dress(b, look, 999)
	var shown := icon_points if icon_points > 0.0 else points * 0.5
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
		badge := "", tone := "leather") -> VBoxContainer:
	var v := VBoxContainer.new()
	v.name = "RoundAction"
	v.add_theme_constant_override("separation", -UI.px(12))
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	var look := "gold_round" if main else ("leather" if tone == "leather" else "round_" + tone)
	var b := icon_button(icon, words, pressed, look, points, points * 0.55)
	b.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	v.add_child(b)
	if badge != "":
		var tag := KitStatus.badge(badge)
		tag.set_anchors_preset(Control.PRESET_TOP_RIGHT)
		tag.grow_horizontal = Control.GROW_DIRECTION_BEGIN
		tag.position = Vector2(UI.px(2), -UI.px(4))
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
