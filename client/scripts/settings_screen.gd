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
	var column := UI.frame(self)
	var list := UI.scroll(column)
	list_scroll = list.get_parent() as ScrollContainer
	# The title on its plate and the tabs head the list and scroll with it,
	# so nothing fixed sits in the screen's top third (§21.1).
	list.add_child(_head())
	list.add_child(_tabs())

	# The design's tabs: all three are built, the one chosen is shown.
	var game := VBoxContainer.new()
	var access := VBoxContainer.new()
	var account := VBoxContainer.new()
	for tab: VBoxContainer in [game, access, account]:
		tab.add_theme_constant_override("separation", UI.px(Tokens.number("size", "gap_points")))
	list.add_child(game)
	list.add_child(access)
	list.add_child(account)
	game.visible = tab_shown == "game"
	access.visible = tab_shown == "access"
	account.visible = tab_shown == "account"

	var lang := UI.action(Strings.t("LANGUAGE_" + Settings.locale), next_language, "plate")
	_tag(lang, "language")
	game.add_child(KitPanels.row("settingsandwellbeing/language", Strings.t("SETTINGS_LANGUAGE"), "", lang))
	game.add_child(KitPanels.section(Strings.t("SCREEN_SETTINGS_SOUND")))
	var icons := {"music": "music", "effects": "effectsvolume", "alerts": "notifications"}
	var sound := UI.panel("card")
	sound.add_theme_stylebox_override("panel", UI.clear_box(12, 10))
	var volumes := VBoxContainer.new()
	volumes.add_theme_constant_override("separation", UI.px(12))
	sound.add_child(volumes)
	for bus: String in Settings.VOLUMES:
		var name := Strings.t("SETTINGS_" + bus.to_upper(), Settings.volume[bus])
		var l := _words(name)
		volume_labels[bus] = l
		volumes.add_child(_stepper(icons.get(bus, "music"), l, step.bind(bus, -1), step.bind(bus, 1),
			Strings.t("SETTINGS_QUIETER", name), Strings.t("SETTINGS_LOUDER", name), bus,
			float(Settings.volume[bus]) / float(Settings.VOLUME_STEPS)))
	game.add_child(sound)
	game.add_child(KitPanels.section(Strings.t("SCREEN_SETTINGS_PLAY")))
	game.add_child(_toggle("slow_rehearsals", "SETTINGS_SLOW_REHEARSALS", "playtimereminder"))

	# Key frame 05: the text size and the schools' marks, then "Seeing and
	# comfort", each switch a whole row framed on parchment.
	access.add_child(KitPanels.section(Strings.t("SCREEN_SETTINGS_ACCESS")))
	access.add_child(_text_card())
	access.add_child(_shapes())
	access.add_child(KitPanels.section(Strings.t("SCREEN_SETTINGS_COMFORT")))
	for toggle: Array in [
			["high_contrast", "SETTINGS_CONTRAST", "accessibility"], ["reduced_motion", "SETTINGS_MOTION", "reducedmotion"],
			["haptics", "SETTINGS_HAPTICS", "haptics"], ["left_handed", "SETTINGS_LEFT_HANDED", "lefthanded"],
			["banners_stay", "SETTINGS_BANNERS_STAY", "notifications"],
			["camera_buttons", "SETTINGS_CAMERA_BUTTONS", "accessibility"]]:
		access.add_child(_toggle(toggle[0], toggle[1], toggle[2]))
	# And "Controls and pace": how long a hold is.
	access.add_child(KitPanels.section(Strings.t("SCREEN_SETTINGS_PACE")))
	var hold_name := Strings.t("SETTINGS_HOLD", seconds(Settings.hold_ms))
	var holds := Settings.hold_steps()
	var pace := UI.panel("card")
	pace.add_theme_stylebox_override("panel", UI.clear_box(12, 10))
	pace.add_child(_stepper("remindertime", _words(hold_name), hold_step.bind(-1), hold_step.bind(1),
		Strings.t("SETTINGS_SHORTER", hold_name), Strings.t("SETTINGS_LONGER", hold_name), "hold",
		float(holds.find(Settings.hold_ms)) / float(maxi(holds.size() - 1, 1))))
	access.add_child(pace)

	# The account: signing in and out, devices, ways to sign in (auth_panel.gd,
	# T11), with the profile row and the privacy note under it (ScreenAccount).
	account.add_child(AuthPanel.new())
	account.add_child(ScreenAccount.profile_row())
	account.add_child(ScreenAccount.privacy_note())
	column.add_child(_bottom())


## The title on its plate: the settings mark and SETTINGS_TITLE in Marcellus.
func _head() -> Control:
	var plate := PanelContainer.new()
	plate.name = "Head"
	plate.add_theme_stylebox_override("panel", UI.clear_box(16, 7))
	UI.dress(plate, "plate_dark")
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", UI.px(10))
	var mark := Icons.view("generalui/settings", 28)
	mark.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(mark)
	var t := UI.label(Strings.t("SETTINGS_TITLE"), Tokens.type_role("title")["points"], true)
	t.name = "Title"
	t.theme_type_variation = "Title"
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	t.add_theme_stylebox_override("normal", StyleBoxEmpty.new())
	t.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(t)
	plate.add_child(row)
	return plate


## The tabs as key frame 05 has them: one strip of parchment, the open tab on
## gold. Where an icon and its word do not fit a third of the strip (large
## text, a long word), the closed tabs keep their icon alone and the open one
## its word alone, twice as wide; a screen reader still hears every word.
func _tabs() -> Control:
	var strip := PanelContainer.new()
	strip.name = "Segments"
	strip.add_theme_stylebox_override("panel", UI.clear_box(2, 2))
	UI.dress(strip, "parchment")
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", UI.px(4))
	strip.add_child(row)
	var tabs := [["game", "SCREEN_SETTINGS_GAME", "generalui/settings"],
		["access", "SCREEN_SETTINGS_ACCESS", "settingsandwellbeing/accessibility"],
		["account", "SCREEN_SETTINGS_ACCOUNT", "settingsandwellbeing/account"]]
	var share := UI.px((KitNav.PHONE_POINTS - 2.0 * Tokens.number("size", "safe_side_points") - 4.0 - 8.0) / 3.0)
	var compact := Settings.text_scale > KitLayout.SIDE_BY_SIDE_UP_TO
	for tab: Array in tabs:
		var wide := UI.bold_font().get_string_size(Strings.t(tab[1]), HORIZONTAL_ALIGNMENT_LEFT, -1, UI.text_px(14)).x
		compact = compact or wide + UI.px(22 + 4 + 18 + 2) > share
	for tab: Array in tabs:
		var key: String = tab[0]
		var words := Strings.t(tab[1])
		var open := key == tab_shown
		var b := UI.action(words, func() -> void:
			tab_shown = key
			_build(), "gold" if open else "seg_light", words)
		b.add_theme_font_size_override("font_size", UI.text_px(14))
		b.set_meta("points", 14.0)
		b.set_meta("chosen", open)
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.custom_minimum_size = Vector2(UI.px(UI.CONTROL_POINTS), UI.px(60 if compact else 48))
		b.autowrap_mode = TextServer.AUTOWRAP_OFF
		if compact and open:
			b.size_flags_stretch_ratio = 2.0
			b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		else:
			b.icon = Icons.texture(tab[2])
			b.expand_icon = true
			b.add_theme_constant_override("icon_max_width", UI.px(32 if compact else 22))
			b.add_theme_constant_override("h_separation", UI.px(4))
			if compact:
				b.text = ""
				b.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
		row.add_child(_tag(b, "tab_" + key))
	return strip


## A setting's words on a card: bold, to the left, wrapping.
func _words(text: String) -> Label:
	var l := UI.label(text, 16, true)
	l.theme_type_variation = "BodyBold"
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	l.set_meta("bold", true)
	return l


## A setting with steps: its icon in a well, its words over a bar of where it
## stands, and − and + on leather at its end.
func _stepper(icon: String, words: Label, down: Callable, up: Callable, spoken_down: String, spoken_up: String,
		tag: String, share: float) -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", UI.px(8))
	var well := PanelContainer.new()
	well.add_theme_stylebox_override("panel", UI.clear_box(7, 7))
	UI.dress(well, "well")
	well.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	well.add_child(Icons.view("settingsandwellbeing/" + icon, 26))
	row.add_child(well)
	var mid := VBoxContainer.new()
	mid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	mid.alignment = BoxContainer.ALIGNMENT_CENTER
	mid.add_theme_constant_override("separation", UI.px(6))
	mid.add_child(words)
	mid.add_child(KitBar.make(share, Color(), 8))
	row.add_child(mid)
	for b: Button in [_tag(UI.action("−", down, "leather", spoken_down), tag + "-"),
			_tag(UI.action("+", up, "leather", spoken_up), tag + "+")]:
		b.add_theme_font_size_override("font_size", UI.text_px(24))
		b.set_meta("points", 24.0)
		b.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		row.add_child(b)
	return row


## A switch as a whole row framed on parchment: the setting's icon, its words
## (which say On or Off), and the switch at its end; the row is the one
## control.
func _toggle(setting: String, words: String, icon: String) -> Control:
	var on := Settings.flag(setting)
	var b := UI.action(Strings.t(words + ("_ON" if on else "_OFF")), flip.bind(setting), "parchment")
	b.alignment = HORIZONTAL_ALIGNMENT_LEFT
	b.icon = Icons.texture("settingsandwellbeing/" + icon)
	b.expand_icon = true
	b.add_theme_constant_override("icon_max_width", UI.px(28))
	b.add_theme_constant_override("h_separation", UI.px(10))
	b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	b.custom_minimum_size = Vector2(0, UI.px(52))
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	for state: String in ["normal", "hover", "pressed", "focus", "disabled"]:
		var box := UI.clear_box(12, 7)
		box.content_margin_right = UI.px(12 + 46 + 10)
		b.add_theme_stylebox_override(state, box)
	var sw := ScreenSwitch.make(on)
	sw.anchor_left = 1.0
	sw.anchor_right = 1.0
	sw.anchor_top = 0.5
	sw.anchor_bottom = 0.5
	sw.offset_left = -UI.px(58)
	sw.offset_right = -UI.px(12)
	sw.offset_top = -UI.px(14)
	sw.offset_bottom = UI.px(14)
	b.add_child(sw)
	b.set_meta("on", on)
	return _tag(b, setting)


## §20.8's text size as key frame 05's card: a small A and a large A on gold
## either side of the size in large figures over a dot a step, and a law's
## card in the size chosen, to read before leaving.
func _text_card() -> Control:
	var steps := Settings.text_steps()
	var at := steps.find(Settings.text_scale)
	var size_name := Strings.t("SETTINGS_TEXT_SIZE", Settings.text_scale)
	var large := Settings.text_scale > KitLayout.SIDE_BY_SIDE_UP_TO
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", UI.px(8))
	var mid := VBoxContainer.new()
	mid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	mid.alignment = BoxContainer.ALIGNMENT_CENTER
	mid.add_theme_constant_override("separation", UI.px(6))
	text_label = UI.label("%d%%" % Settings.text_scale, 34)
	text_label.theme_type_variation = "Display"
	text_label.accessibility_name = size_name
	mid.add_child(text_label)
	var dots := HBoxContainer.new()
	dots.alignment = BoxContainer.ALIGNMENT_CENTER
	dots.add_theme_constant_override("separation", UI.px(5))
	for i: int in steps.size():
		var dot := Control.new()
		dot.mouse_filter = Control.MOUSE_FILTER_IGNORE
		dot.custom_minimum_size = Vector2(UI.px(22 if i == at else 9), UI.px(9))
		UI.dress(dot, "gold" if i == at else "plate_dark", 999)
		dots.add_child(dot)
	mid.add_child(dots)
	for side: Array in [[-1, 14.0, "text-", "SETTINGS_SMALLER"], [1, 26.0, "text+", "SETTINGS_LARGER"]]:
		var a := UI.action(Strings.t("SCREEN_TEXT_A"), text_step.bind(side[0]), "gold",
			Strings.t(side[3], size_name))
		a.add_theme_font_size_override("font_size", UI.text_px(side[1]))
		a.set_meta("points", side[1])
		a.custom_minimum_size = Vector2(UI.px(76 if large else 64), UI.px(76 if large else 56))
		a.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		_tag(a, side[2])
		row.add_child(a)
		if side[0] < 0:
			row.add_child(mid)
	var sample := PanelContainer.new()
	var room := UI.clear_box(14, 10)
	room.content_margin_bottom = UI.px(12)
	sample.add_theme_stylebox_override("panel", room)
	UI.dress(sample, "parchment")
	var line := HBoxContainer.new()
	line.add_theme_constant_override("separation", UI.px(10))
	var mark := Icons.view("laws/stillness", 40)
	mark.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	line.add_child(mark)
	var words := VBoxContainer.new()
	words.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	words.alignment = BoxContainer.ALIGNMENT_CENTER
	words.add_theme_constant_override("separation", 0)
	var heading := UI.label(Strings.term("LAW", "stillness"), Tokens.type_role("heading")["points"], true)
	heading.theme_type_variation = "Heading"
	heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	words.add_child(heading)
	var rule := UI.label(Strings.t("LAW_RULE_STILLNESS"), Tokens.type_role("caption")["points"], true)
	rule.theme_type_variation = "Caption"
	rule.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	words.add_child(rule)
	line.add_child(words)
	sample.add_child(line)
	var card := PanelContainer.new()
	card.add_theme_stylebox_override("panel", UI.clear_box(14, 14))
	UI.dress(card, "card")
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", UI.px(12))
	box.add_child(row)
	box.add_child(sample)
	card.add_child(box)
	return card


## The design's colour-blind card, as the game has it: no mode to choose,
## since each school keeps its own shape in every light (§20.8); the six
## marks on their coins with their names, and that said.
func _shapes() -> Control:
	var card := PanelContainer.new()
	card.add_theme_stylebox_override("panel", UI.clear_box(12, 12))
	UI.dress(card, "card")
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", UI.px(8))
	card.add_child(box)
	var grid := GridContainer.new()
	grid.add_theme_constant_override("h_separation", UI.px(4))
	grid.add_theme_constant_override("v_separation", UI.px(8))
	var schools := ["time", "motion", "matter", "energy", "life", "spirit"]
	# Six a row where every name fits a sixth of the card; three where one
	# does not (Portuguese "Movimento", French "Mouvement") or at large text.
	var widest := 0.0
	for school: String in schools:
		widest = maxf(widest, UI.bold_font().get_string_size(Strings.t("SCHOOL_" + school.to_upper()),
			HORIZONTAL_ALIGNMENT_LEFT, -1, UI.text_px(13)).x)
	var room := UI.px(KitNav.PHONE_POINTS - 2.0 * Tokens.number("size", "safe_side_points") - 24.0)
	grid.columns = 6
	while grid.columns > 1 and widest * grid.columns + UI.px(4) * (grid.columns - 1) > room:
		grid.columns = 3 if grid.columns == 6 else (2 if grid.columns == 3 else 1)
	for school: String in schools:
		var col := VBoxContainer.new()
		col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		col.add_theme_constant_override("separation", UI.px(2))
		var coin := PanelContainer.new()
		coin.add_theme_stylebox_override("panel", UI.clear_box(4, 4))
		UI.dress(coin, "window_" + school, 999)
		coin.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		coin.add_child(Icons.view("schools/" + school, 24))
		col.add_child(coin)
		var name := UI.label(Strings.t("SCHOOL_" + school.to_upper()), Tokens.type_role("caption")["points"])
		name.theme_type_variation = "Caption"
		name.add_theme_font_override("font", UI.bold_font())
		name.set_meta("bold", true)
		col.add_child(name)
		grid.add_child(col)
	box.add_child(grid)
	var said := UI.label(Strings.t("SCREEN_SETTINGS_SHAPES"), Tokens.type_role("caption")["points"], true)
	said.theme_type_variation = "Caption"
	said.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	box.add_child(said)
	return card


## Back home, on the glass bar at the foot of the screen, lifted off its
## corner (ScreenNav.CORNER_LIFT_POINTS).
func _bottom() -> Control:
	var dock := MarginContainer.new()
	dock.name = "Dock"
	dock.add_theme_constant_override("margin_bottom", UI.px(ScreenNav.CORNER_LIFT_POINTS))
	var bar := PanelContainer.new()
	bar.add_theme_stylebox_override("panel", UI.clear_box(10, 10))
	UI.dress(bar, "glass", 22)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", UI.px(10))
	if Settings.left_handed:
		row.layout_direction = Control.LAYOUT_DIRECTION_RTL
	var back := UI.action(Strings.t("SCREEN_BACK"), func() -> void: App.services.router.go(&"home"), "parchment")
	back.icon = Icons.texture("generalui/back")
	back.expand_icon = true
	back.add_theme_constant_override("icon_max_width", UI.px(28))
	back.add_theme_constant_override("h_separation", UI.px(8))
	back.custom_minimum_size = Vector2(maxf(back.custom_minimum_size.x + UI.px(28 + 8 + 12), UI.px(120)), UI.px(56))
	for state: String in ["normal", "hover", "pressed", "focus", "disabled"]:
		var box := UI.clear_box(12, 0)
		box.content_margin_right = UI.px(18)
		box.content_margin_bottom = UI.px(2)
		back.add_theme_stylebox_override(state, box)
	back.set_meta("back", true)
	back.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	row.add_child(back)
	bar.add_child(row)
	dock.add_child(bar)
	return dock


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
