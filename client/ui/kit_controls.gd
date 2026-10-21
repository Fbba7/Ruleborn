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
static func icon_button(icon: String, spoken: String, pressed: Callable, look := "leather", points := 48.0) -> Button:
	var b := UI.action("", pressed, look, spoken)
	b.name = "IconButton"
	b.custom_minimum_size = Vector2.ONE * UI.px(maxf(points, UI.CONTROL_POINTS))
	b.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	RbBox.dress(b, look, 999)
	var i := Icons.view(icon, points * 0.6)
	i.set_anchors_preset(Control.PRESET_FULL_RECT)
	b.add_child(i)
	return b


## A round action with its name on a plate beneath (the realm view's MAP,
## WEAVE and BUILD): leather, or gold round for the main one; a badge is
## written on it if given.
static func round_action(icon: String, words: String, pressed: Callable, main := false, points := 60.0,
		badge := "") -> VBoxContainer:
	var v := VBoxContainer.new()
	v.name = "RoundAction"
	v.add_theme_constant_override("separation", -UI.px(8))
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	var b := icon_button(icon, words, pressed, "gold_round" if main else "leather", points)
	b.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	v.add_child(b)
	if badge != "":
		var tag := KitStatus.badge(badge)
		tag.set_anchors_preset(Control.PRESET_TOP_RIGHT)
		tag.grow_horizontal = Control.GROW_DIRECTION_BEGIN
		tag.position.y = -UI.px(4)
		b.add_child(tag)
	var plate := KitStatus.plate(words)
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
