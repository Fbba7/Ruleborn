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

	var lang := ScreenKit.button(Strings.t("LANGUAGE_" + Settings.locale), next_language, "cream", "", 14.0)
	list.add_child(ScreenParts.item("settingsandwellbeing", "language", Strings.t("SETTINGS_LANGUAGE"), "",
		_tag(lang, "language")))

	list.add_child(ScreenParts.section(Strings.t("SCREEN_SETTINGS_SOUND")))
	var icons := {"music": "music", "effects": "effectsvolume", "alerts": "notifications"}
	for bus: String in Settings.VOLUMES:
		var name := Strings.t("SETTINGS_" + bus.to_upper(), Settings.volume[bus])
		var l := ScreenKit.text(name, 15.0, "words", "card")
		volume_labels[bus] = l
		list.add_child(_stepper(icons.get(bus, "sound"), l, step.bind(bus, -1), step.bind(bus, 1),
			Strings.t("SETTINGS_QUIETER", name), Strings.t("SETTINGS_LOUDER", name), bus,
			float(Settings.volume[bus]) / float(Settings.VOLUME_STEPS)))

	list.add_child(ScreenParts.section(Strings.t("SCREEN_SETTINGS_ACCESS")))
	var size_name := Strings.t("SETTINGS_TEXT_SIZE", Settings.text_scale)
	text_label = ScreenKit.text(size_name, 15.0, "words", "card")
	var steps := Settings.text_steps()
	list.add_child(_stepper("textsize", text_label, text_step.bind(-1), text_step.bind(1),
		Strings.t("SETTINGS_SMALLER", size_name), Strings.t("SETTINGS_LARGER", size_name), "text",
		float(steps.find(Settings.text_scale)) / float(maxi(steps.size() - 1, 1))))
	var hold_name := Strings.t("SETTINGS_HOLD", seconds(Settings.hold_ms))
	var holds := Settings.hold_steps()
	list.add_child(_stepper("remindertime", ScreenKit.text(hold_name, 15.0, "words", "card"), hold_step.bind(-1),
		hold_step.bind(1), Strings.t("SETTINGS_SHORTER", hold_name), Strings.t("SETTINGS_LONGER", hold_name), "hold",
		float(holds.find(Settings.hold_ms)) / float(maxi(holds.size() - 1, 1))))
	for toggle: Array in [
			["high_contrast", "SETTINGS_CONTRAST", "accessibility"], ["reduced_motion", "SETTINGS_MOTION", "reducedmotion"],
			["haptics", "SETTINGS_HAPTICS", "haptics"], ["left_handed", "SETTINGS_LEFT_HANDED", "lefthanded"],
			["banners_stay", "SETTINGS_BANNERS_STAY", "notifications"],
			["camera_buttons", "SETTINGS_CAMERA_BUTTONS", "accessibility"]]:
		list.add_child(_toggle(toggle[0], toggle[1], toggle[2]))
	list.add_child(ScreenParts.section(Strings.t("SCREEN_SETTINGS_PLAY")))
	list.add_child(_toggle("slow_rehearsals", "SETTINGS_SLOW_REHEARSALS", "playtimereminder"))

	var profile := ScreenKit.button(Strings.t("HOME_PROFILE"), func() -> void: App.services.router.go(&"profile"),
		"leather")
	column.add_child(ScreenNav.dock(&"home", [profile]))


## A setting with steps: its icon, its words over a bar of where it stands,
## and − and + either side.
func _stepper(icon: String, words: Label, down: Callable, up: Callable, spoken_down: String, spoken_up: String,
		tag: String, share: float) -> Control:
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
	row.add_child(_tag(ScreenKit.button("−", down, "leather", spoken_down, -1.0), tag + "-"))
	row.add_child(_tag(ScreenKit.button("+", up, "leather", spoken_up, -1.0), tag + "+"))
	return ScreenKit.panel("card", row, 16.0, 8.0)


## A switch as a whole row: the setting's icon, its words, and the switch
## drawn at its end; the row is the one control.
func _toggle(setting: String, words: String, icon: String) -> Control:
	var on := Settings.flag(setting)
	var b := ScreenKit.button(Strings.t(words + ("_ON" if on else "_OFF")), flip.bind(setting), "card", "", 16.0)
	b.alignment = HORIZONTAL_ALIGNMENT_LEFT
	var path := ScreenKit.icon_path("settingsandwellbeing", icon)
	if path != "":
		b.icon = load(path)
		b.expand_icon = true
		b.add_theme_constant_override("icon_max_width", UI.px(28))
		b.add_theme_constant_override("h_separation", UI.px(10))
	b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	b.custom_minimum_size.x = 0
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var normal := b.get_theme_stylebox("normal") as ScreenBox
	normal.content_margin_right = UI.px(64)
	for state: String in ["hover", "pressed", "disabled"]:
		(b.get_theme_stylebox(state) as ScreenBox).content_margin_right = UI.px(64)
	var sw := ScreenSwitch.make(on)
	sw.set_anchors_preset(Control.PRESET_CENTER_RIGHT)
	sw.position = Vector2(-UI.px(56), -UI.px(14))
	b.add_child(sw)
	b.set_meta("on", on)
	return _tag(b, setting)


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
