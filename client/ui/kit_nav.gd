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
	v.add_child(rule())
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


## The hub's segmented control: one segment per option, the chosen one in
## gold; `picked` is called with the chosen index.
static func segmented(options: Array, chosen: int, picked: Callable) -> PanelContainer:
	var p := PanelContainer.new()
	p.name = "Segments"
	p.add_theme_stylebox_override("panel", UI.clear_box(4, 4))
	UI.dress(p, "bar_track", 18)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", UI.px(4))
	p.add_child(row)
	var buttons: Array[Button] = []
	for i: int in options.size():
		var b := UI.action(str(options[i]), func() -> void: pass, "chip")
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		buttons.append(b)
		row.add_child(b)
	var choose := func(n: int) -> void:
		for j: int in buttons.size():
			UI.set_look(buttons[j], "chip_on" if j == n else "chip")
			buttons[j].set_meta("chosen", j == n)
	for i: int in buttons.size():
		buttons[i].pressed.connect(func() -> void:
			choose.call(i)
			picked.call(i))
	choose.call(chosen)
	return p


## The five tabs, `chosen` chosen, with badges ({"heist": 4}); the bar emits
## `picked(id)`.
static func tabs(chosen: String, badges := {}) -> KitTabs:
	return KitTabs.make(chosen, badges)
