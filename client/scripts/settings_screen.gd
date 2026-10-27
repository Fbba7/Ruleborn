class_name SettingsScreen
extends Control
## §20.6's settings and §20.8's accessibility set: the language, a volume
## each for music, effects and alerts, text size, high contrast, reduced
## motion, haptics, left-handed controls, the rehearsal pace and banners that
## stay. Every change is applied and saved as it is made; there is no Save
## button to forget. The screen is built again after each, so what it shows
## is always what the setting does.

var volume_labels := {}
var text_label: Label
var list_scroll: ScrollContainer
## The tab on show: "game" (language, sound, play), "access" or "account".
var tab_shown := "game"


func _ready() -> void:
	App.ready(self)
	Settings.restore()
	_build()


## Built again after each change, keeping where the list was scrolled to and
## which control had focus, so a player at large text or on a screen reader
## is not sent back to the top by every tap.
func _build() -> void:
	var scrolled := list_scroll.scroll_vertical if list_scroll != null else 0
	var focused := get_viewport().gui_get_focus_owner() if is_inside_tree() else null
	var focus_name := str(focused.get_meta("setting", "")) if focused != null else ""
	for c in get_children():
		remove_child(c)
		c.queue_free()
	_layout()
	if is_inside_tree():
		await get_tree().process_frame
		list_scroll.scroll_vertical = scrolled
		if focus_name != "":
			for b: Button in find_children("*", "Button", true, false):
				if b.get_meta("setting", "") == focus_name:
					b.grab_focus()


func _layout() -> void:
	var column := ScreenKit.frame(self)
	column.add_child(ScreenNav.header(Strings.t("SETTINGS_TITLE")))
	var list := UI.scroll(column)
	list_scroll = list.get_parent() as ScrollContainer

	# The design's tabs, as a strip at the head of the list: both are built,
	# the one chosen is shown.
	var game := VBoxContainer.new()
	var access := VBoxContainer.new()
	var account := VBoxContainer.new()
	for tab: VBoxContainer in [game, access, account]:
		tab.add_theme_constant_override("separation", UI.px(Tokens.number("size", "gap_points")))
	list.add_child(ScreenParts.segmented([
		{"text": Strings.t("SCREEN_SETTINGS_GAME"), "key": "game", "on": tab_shown == "game",
			"icon": "generalui/settings"},
		{"text": Strings.t("SCREEN_SETTINGS_ACCESS"), "key": "access", "on": tab_shown == "access",
			"icon": "settingsandwellbeing/accessibility"},
		{"text": Strings.t("SCREEN_SETTINGS_ACCOUNT"), "key": "account", "on": tab_shown == "account",
			"icon": "settingsandwellbeing/account"}],
		func(key: String) -> void:
			tab_shown = key
			_build()))
	list.add_child(game)
	list.add_child(access)
	list.add_child(account)
	game.visible = tab_shown == "game"
	access.visible = tab_shown == "access"
	account.visible = tab_shown == "account"
	var lang := ScreenKit.button(Strings.t("LANGUAGE_" + Settings.locale), next_language, "cream", "", 14.0)
	game.add_child(ScreenParts.item("settingsandwellbeing", "language", Strings.t("SETTINGS_LANGUAGE"), "",
		_tag(lang, "language")))

	game.add_child(ScreenParts.section(Strings.t("SCREEN_SETTINGS_SOUND")))
	var icons := {"music": "music", "effects": "effectsvolume", "alerts": "notifications"}
	# The volumes as rows of one card, as the design groups a section.
	var sound := VBoxContainer.new()
	sound.add_theme_constant_override("separation", 0)
	for bus: String in Settings.VOLUMES:
		var name := Strings.t("SETTINGS_" + bus.to_upper(), Settings.volume[bus])
		var l := ScreenKit.text(name, 15.0, "words", "card")
		volume_labels[bus] = l
		if sound.get_child_count() > 0:
			sound.add_child(_divider())
		sound.add_child(_stepper(icons.get(bus, "sound"), l, step.bind(bus, -1), step.bind(bus, 1),
			Strings.t("SETTINGS_QUIETER", name), Strings.t("SETTINGS_LOUDER", name), bus,
			float(Settings.volume[bus]) / float(Settings.VOLUME_STEPS), true))
	game.add_child(ScreenKit.panel("card", sound, 18.0, 4.0))

	game.add_child(ScreenParts.section(Strings.t("SCREEN_SETTINGS_PLAY")))
	game.add_child(_toggle("slow_rehearsals", "SETTINGS_SLOW_REHEARSALS", "playtimereminder"))
	# The account: signing in and out, devices, ways to sign in (auth_panel.gd, T11).
	account.add_child(AuthPanel.new())

	access.add_child(ScreenParts.section(Strings.t("SCREEN_SETTINGS_ACCESS")))
	access.add_child(_text_card())
	var hold_name := Strings.t("SETTINGS_HOLD", seconds(Settings.hold_ms))
	var holds := Settings.hold_steps()
	access.add_child(_stepper("remindertime", ScreenKit.text(hold_name, 15.0, "words", "card"), hold_step.bind(-1),
		hold_step.bind(1), Strings.t("SETTINGS_SHORTER", hold_name), Strings.t("SETTINGS_LONGER", hold_name), "hold",
		float(holds.find(Settings.hold_ms)) / float(maxi(holds.size() - 1, 1))))
	# The design's "Seeing and comfort": the switches as rows of one card.
	var comfort := VBoxContainer.new()
	comfort.add_theme_constant_override("separation", 0)
	for toggle: Array in [
			["high_contrast", "SETTINGS_CONTRAST", "accessibility"], ["reduced_motion", "SETTINGS_MOTION", "reducedmotion"],
			["haptics", "SETTINGS_HAPTICS", "haptics"], ["left_handed", "SETTINGS_LEFT_HANDED", "lefthanded"],
			["banners_stay", "SETTINGS_BANNERS_STAY", "notifications"],
			["camera_buttons", "SETTINGS_CAMERA_BUTTONS", "accessibility"]]:
		if comfort.get_child_count() > 0:
			comfort.add_child(_divider())
		comfort.add_child(_toggle(toggle[0], toggle[1], toggle[2], true))
	access.add_child(ScreenKit.panel("card", comfort, 18.0, 4.0))
	# The profile row and the privacy note under T11's panel (ScreenAccount).
	account.add_child(ScreenAccount.profile_row())
	account.add_child(ScreenAccount.privacy_note())
	column.add_child(ScreenNav.dock(&"home"))


## A setting with steps: its icon, its words over a bar of where it stands,
## and − and + either side.
func _stepper(icon: String, words: Label, down: Callable, up: Callable, spoken_down: String, spoken_up: String,
		tag: String, share: float, in_card := false) -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", UI.px(8))
	row.add_child(ScreenKit.panel("well", ScreenKit.icon("settingsandwellbeing", icon, 26.0), -1.0, 4.0))
	var mid := VBoxContainer.new()
	mid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	mid.alignment = BoxContainer.ALIGNMENT_CENTER
	mid.add_theme_constant_override("separation", UI.px(4))
	words.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	mid.add_child(words)
	mid.add_child(ScreenMeter.bar(share, 1.0, Color("#8C6CF0"), 8.0))
	row.add_child(mid)
	for b: Button in [_tag(ScreenKit.button("−", down, "leather", spoken_down, -1.0), tag + "-"),
			_tag(ScreenKit.button("+", up, "leather", spoken_up, -1.0), tag + "+")]:
		b.add_theme_font_size_override("font_size", UI.text_px(24))
		b.set_meta("points", 24.0)
		row.add_child(b)
	if in_card:
		var pad := MarginContainer.new()
		for side: String in ["left", "right", "top", "bottom"]:
			pad.add_theme_constant_override("margin_" + side, UI.px(8))
		pad.add_child(row)
		return pad
	return ScreenKit.panel("card", row, 16.0, 8.0)


## A switch as a whole row: the setting's icon, its words, and the switch
## drawn at its end; the row is the one control, framed, or a row of a card.
func _toggle(setting: String, words: String, icon: String, in_card := false) -> Control:
	var on := Settings.flag(setting)
	var b := ScreenKit.button(Strings.t(words + ("_ON" if on else "_OFF")), flip.bind(setting), "card", "", 16.0)
	# A row of a card: the card's fill behind it, no frame of its own.
	if in_card and RbBox.of(b) != null:
		RbBox.of(b).visible = false
	b.alignment = HORIZONTAL_ALIGNMENT_LEFT
	var tex := ScreenKit.icon_texture("settingsandwellbeing", icon)
	if tex != null:
		b.icon = tex
		b.expand_icon = true
		b.add_theme_constant_override("icon_max_width", UI.px(28))
		b.add_theme_constant_override("h_separation", UI.px(10))
	b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	b.custom_minimum_size.x = 0
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var normal := b.get_theme_stylebox("normal") as StyleBox
	normal.content_margin_right = UI.px(64)
	for state: String in ["hover", "pressed", "disabled"]:
		(b.get_theme_stylebox(state) as StyleBox).content_margin_right = UI.px(64)
	var sw := ScreenSwitch.make(on)
	sw.set_anchors_preset(Control.PRESET_CENTER_RIGHT)
	sw.position = Vector2(-UI.px(56), -UI.px(14))
	b.add_child(sw)
	b.set_meta("on", on)
	return _tag(b, setting)


## §20.8's text size as the design's card: a small A and a large A either
## side of the size in large figures over a dot a step, and a law's card in
## the size chosen, to read before leaving.
func _text_card() -> Control:
	var steps := Settings.text_steps()
	var at := steps.find(Settings.text_scale)
	var size_name := Strings.t("SETTINGS_TEXT_SIZE", Settings.text_scale)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", UI.px(8))
	var smaller := _tag(ScreenKit.button(Strings.t("SCREEN_TEXT_A"), text_step.bind(-1), "leather",
		Strings.t("SETTINGS_SMALLER", size_name), 14.0), "text-")
	smaller.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(smaller)
	var mid := VBoxContainer.new()
	mid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	mid.add_theme_constant_override("separation", UI.px(6))
	text_label = ScreenKit.inked(ScreenKit.text("%d%%" % Settings.text_scale, 34.0, "number", "card"), 2.0)
	text_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	text_label.accessibility_name = size_name
	mid.add_child(text_label)
	var dots := HBoxContainer.new()
	dots.alignment = BoxContainer.ALIGNMENT_CENTER
	dots.add_theme_constant_override("separation", UI.px(5))
	for i: int in steps.size():
		var dot := ScreenKit.panel("gold" if i == at else "well", null, -1.0, 0.0)
		dot.custom_minimum_size = Vector2(UI.px(22 if i == at else 9), UI.px(9))
		dots.add_child(dot)
	mid.add_child(dots)
	row.add_child(mid)
	var larger := _tag(ScreenKit.button(Strings.t("SCREEN_TEXT_A"), text_step.bind(1), "leather",
		Strings.t("SETTINGS_LARGER", size_name), 14.0), "text+")
	larger.add_theme_font_size_override("font_size", UI.text_px(26))
	larger.set_meta("points", 26.0)
	larger.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(larger)
	var sample := HBoxContainer.new()
	sample.add_theme_constant_override("separation", UI.px(10))
	var mark := ScreenKit.icon("laws", "stillness", 40.0)
	mark.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	sample.add_child(mark)
	var words := VBoxContainer.new()
	words.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	words.add_theme_constant_override("separation", 0)
	words.add_child(ScreenKit.text(Strings.term("LAW", "stillness"), 20.0, "name", "parchment", false, true))
	words.add_child(ScreenKit.text(Strings.t("LAW_RULE_STILLNESS"), 13.0, "body", "parchment", false, true))
	sample.add_child(words)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", UI.px(12))
	box.add_child(row)
	box.add_child(ScreenKit.panel("parchment", sample, 14.0, 10.0))
	return ScreenKit.panel("card", box, 18.0, 12.0)


## A hairline between a card's rows.
static func _divider() -> Control:
	var line := ColorRect.new()
	line.color = Color(1, 1, 1, 0.08)
	line.custom_minimum_size.y = maxf(1.0, UI.px(1))
	line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return line


func _tag(b: Button, setting: String) -> Button:
	b.set_meta("setting", setting)
	return b


func step(bus: String, by: int) -> void:
	Settings.change(func() -> void: Settings.volume[bus] = clampi(Settings.volume[bus] + by, 0, Settings.VOLUME_STEPS))
	_build()


func text_step(by: int) -> void:
	var steps := Settings.text_steps()
	var i := clampi(steps.find(Settings.text_scale) + by, 0, steps.size() - 1)
	Settings.change(func() -> void: Settings.text_scale = int(steps[i]))
	_build()


## §20.8's hold time, one step shorter or longer.
func hold_step(by: int) -> void:
	var steps := Settings.hold_steps()
	var i := clampi(steps.find(Settings.hold_ms) + by, 0, steps.size() - 1)
	Settings.change(func() -> void: Settings.hold_ms = int(steps[i]))
	_build()


## Milliseconds as seconds in the language's numbers: 0.5, 1, 1.5.
static func seconds(ms: int) -> String:
	var tenths := roundi(ms / 100.0)
	if tenths % 10 == 0:
		return str(tenths / 10)
	return "%d%s%d" % [tenths / 10, Strings.t("NUMBER_DECIMAL"), tenths % 10]


func flip(setting: String) -> void:
	Settings.change(func() -> void: Settings.set_flag(setting, not Settings.flag(setting)))
	_build()


func next_language() -> void:
	var i := Strings.LOCALES.find(Settings.locale)
	Settings.change(func() -> void: Settings.locale = Strings.LOCALES[(i + 1) % Strings.LOCALES.size()])
	_build()
