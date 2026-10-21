class_name KitNav
## Moving between screens: a screen's header (kicker, title and the gold
## rule under it), the back button, the hub's segmented control and the
## five tabs (KitTabs). §21.1 keeps every frequently used control in the
## lower two-thirds, so the header carries no button: the back button is
## made for the screen's lowest row.


## A screen's header: an optional kicker in capitals above its title in
## Marcellus, and the designs' gold rule with its diamond beneath.
static func header(title: String, kicker := "") -> VBoxContainer:
	var v := VBoxContainer.new()
	v.name = "Header"
	v.add_theme_constant_override("separation", UI.px(2))
	if kicker != "":
		var k := UI.label(kicker, 13)
		k.theme_type_variation = "Kicker"
		k.uppercase = true
		k.add_theme_color_override("font_color", Tokens.color("gold"))
		k.set_meta("bold", true)
		v.add_child(k)
	v.add_child(UI.title(title))
	return v


## The gold rule with a diamond in its middle, under a title.
static func rule() -> Control:
	var r := KitRule.new()
	r.custom_minimum_size = Vector2(UI.px(160), UI.px(10))
	r.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return r


## The back button: a round leather button with the designs' back arrow,
## named for a screen reader.
static func back(pressed: Callable) -> Button:
	return KitControls.icon_button("generalui/back", Strings.t("KIT_BACK"), pressed)


## The hub's segmented control (the designs' sub-tab strip): a dark track
## with a brown-gold edge, the chosen segment a gold tab inside it; an
## option is its words, or [words, icon] for an icon over them. `picked` is
## called with the chosen index.
static func segmented(options: Array, chosen: int, picked: Callable) -> PanelContainer:
	var p := PanelContainer.new()
	p.name = "Segments"
	p.add_theme_stylebox_override("panel", UI.clear_box(4, 4))
	UI.dress(p, "seg_track")
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", UI.px(2))
	p.add_child(row)
	var buttons: Array[Button] = []
	for i: int in options.size():
		var option: Variant = options[i]
		var words := str(option[0]) if option is Array else str(option)
		var b := UI.action(words if not option is Array else "", func() -> void: pass, "seg", words)
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		if option is Array:
			b.custom_minimum_size.y = UI.px(56)
			var v := VBoxContainer.new()
			v.set_anchors_preset(Control.PRESET_FULL_RECT)
			v.alignment = BoxContainer.ALIGNMENT_CENTER
			v.add_theme_constant_override("separation", 0)
			v.mouse_filter = Control.MOUSE_FILTER_IGNORE
			v.add_child(Icons.view(str(option[1]), 24))
			# 13 points, the floor (§21.8), in plain case: the designs' 9-pixel
			# capitals do not fit a quarter of the strip at 13.
			var l := UI.label(words, 13)
			l.theme_type_variation = "Tab"
			l.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
			l.clip_text = true
			l.set_meta("bold", true)
			l.mouse_filter = Control.MOUSE_FILTER_IGNORE
			v.add_child(l)
			b.add_child(v)
		buttons.append(b)
		row.add_child(b)
	var choose := func(n: int) -> void:
		for j: int in buttons.size():
			UI.set_look(buttons[j], "seg_on" if j == n else "seg")
			buttons[j].set_meta("chosen", j == n)
			for l: Node in buttons[j].find_children("*", "Label", true, false):
				(l as Label).add_theme_color_override("font_color", Tokens.color("text_on_gold" if j == n
					else "text_on_night"))
	for i: int in buttons.size():
		buttons[i].pressed.connect(func() -> void:
			choose.call(i)
			picked.call(i))
	choose.call(chosen)
	return p


## The designs' sub-screen header: a round back button, the title in
## Marcellus to its right, and a pill at the far end (`chip`, if given).
## §21.1 keeps frequently used controls in the lower two-thirds and the
## layout check holds every fixed button to it, so a screen puts this at
## its top only where the owner allows the back button there (finding H in
## docs/analysis/screens-v3/screens-home-realm-shell.md); otherwise it uses
## `header` and `back` in its lowest row.
static func top_bar(title: String, back_call: Callable, chip := "") -> HBoxContainer:
	var row := HBoxContainer.new()
	row.name = "TopBar"
	row.add_theme_constant_override("separation", UI.px(10))
	row.add_child(back(back_call))
	var t := UI.label(title, 26)
	t.theme_type_variation = "Title"
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	t.add_theme_stylebox_override("normal", StyleBoxEmpty.new())
	t.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(t)
	if chip != "":
		var c := KitStatus.pill(chip)
		c.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		row.add_child(c)
	return row


## The five tabs, `chosen` chosen, with badges ({"heist": 4}); the bar emits
## `picked(id)`.
static func tabs(chosen: String, badges := {}) -> KitTabs:
	return KitTabs.make(chosen, badges)
