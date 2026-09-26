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
	var column := UI.frame(self)
	column.add_child(UI.title(Strings.t("SETTINGS_TITLE")))
	var list := UI.scroll(column)
	list_scroll = list.get_parent() as ScrollContainer

	var language := UI.row()
	language.add_child(UI.plate(UI.label(Strings.t("SETTINGS_LANGUAGE"))))
	language.add_child(_tag(UI.button(Strings.t("LANGUAGE_" + Settings.locale), next_language), "language"))
	list.add_child(language)

	for bus: String in Settings.VOLUMES:
		var r := UI.row()
		var name := Strings.t("SETTINGS_" + bus.to_upper(), Settings.volume[bus])
		r.add_child(_tag(UI.button("−", step.bind(bus, -1), false, Color(), Strings.t("SETTINGS_QUIETER", name)),
			bus + "-"))
		var l := UI.label(name)
		l.custom_minimum_size.x = UI.px(120)
		volume_labels[bus] = l
		r.add_child(UI.plate(l))
		r.add_child(_tag(UI.button("+", step.bind(bus, 1), false, Color(), Strings.t("SETTINGS_LOUDER", name)),
			bus + "+"))
		list.add_child(r)

	var size := UI.row()
	var size_name := Strings.t("SETTINGS_TEXT_SIZE", Settings.text_scale)
	size.add_child(_tag(UI.button("−", text_step.bind(-1), false, Color(), Strings.t("SETTINGS_SMALLER", size_name)),
		"text-"))
	text_label = UI.label(size_name)
	size.add_child(UI.plate(text_label))
	size.add_child(_tag(UI.button("+", text_step.bind(1), false, Color(), Strings.t("SETTINGS_LARGER", size_name)),
		"text+"))
	list.add_child(size)

	for toggle: Array in [
			["high_contrast", "SETTINGS_CONTRAST"], ["reduced_motion", "SETTINGS_MOTION"],
			["haptics", "SETTINGS_HAPTICS"], ["left_handed", "SETTINGS_LEFT_HANDED"],
			["slow_rehearsals", "SETTINGS_SLOW_REHEARSALS"], ["banners_stay", "SETTINGS_BANNERS_STAY"]]:
		var r := UI.row()
		var on := Settings.flag(toggle[0])
		r.add_child(_tag(UI.button(Strings.t(toggle[1] + ("_ON" if on else "_OFF")), flip.bind(toggle[0])), toggle[0]))
		list.add_child(r)

	var back := UI.row(-1.0, true)
	back.add_child(UI.button(Strings.t("COMMON_HOME"), func() -> void: App.services.router.go(&"home"), true))
	column.add_child(UI.narrow(back))


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


func flip(setting: String) -> void:
	Settings.change(func() -> void: Settings.set_flag(setting, not Settings.flag(setting)))
	_build()


func next_language() -> void:
	var i := Strings.LOCALES.find(Settings.locale)
	Settings.change(func() -> void: Settings.locale = Strings.LOCALES[(i + 1) % Strings.LOCALES.size()])
	_build()
