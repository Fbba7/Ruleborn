class_name SettingsScreen
extends Control
## §20.6's settings: the language, a volume each for music, effects and
## alerts, reduced motion and haptics. Every change is applied and saved as it
## is made; there is no Save button to forget.

var volume_labels := {}
var language_button: Button
var motion_button: Button
var haptics_button: Button


func _ready() -> void:
	App.ready(self)
	Settings.restore()
	_build()


## Built again on every change of language, so every word follows it.
func _build() -> void:
	for c in get_children():
		remove_child(c)
		c.queue_free()
	var column := UI.frame(self)
	column.add_child(UI.label(Strings.t("SETTINGS_TITLE"), UI.TITLE_POINTS))
	column.add_child(UI.grow())

	var language := UI.row()
	language.add_child(UI.label(Strings.t("SETTINGS_LANGUAGE")))
	language_button = UI.button(Strings.t("LANGUAGE_" + Settings.locale), next_language)
	language.add_child(language_button)
	column.add_child(language)

	for bus: String in Settings.VOLUMES:
		var r := UI.row()
		r.add_child(UI.button("−", step.bind(bus, -1)))
		var l := UI.label()
		l.custom_minimum_size.x = UI.px(160)
		volume_labels[bus] = l
		r.add_child(l)
		r.add_child(UI.button("+", step.bind(bus, 1)))
		column.add_child(r)

	var toggles := UI.row()
	motion_button = UI.button("", func() -> void:
		Settings.change(func() -> void: Settings.reduced_motion = not Settings.reduced_motion)
		_refresh())
	haptics_button = UI.button("", func() -> void:
		Settings.change(func() -> void: Settings.haptics = not Settings.haptics)
		_refresh())
	toggles.add_child(motion_button)
	toggles.add_child(haptics_button)
	column.add_child(toggles)

	var back := UI.row()
	back.add_child(UI.button(Strings.t("COMMON_HOME"), func() -> void: App.services.router.go(&"home"), true))
	column.add_child(back)
	_refresh()


func _refresh() -> void:
	for bus: String in Settings.VOLUMES:
		volume_labels[bus].text = Strings.t("SETTINGS_" + bus.to_upper(), Settings.volume[bus])
	var motion_key := "SETTINGS_REDUCED_MOTION_ON" if Settings.reduced_motion else "SETTINGS_REDUCED_MOTION_OFF"
	motion_button.text = Strings.t(motion_key)
	haptics_button.text = Strings.t("SETTINGS_HAPTICS_ON" if Settings.haptics else "SETTINGS_HAPTICS_OFF")


func step(bus: String, by: int) -> void:
	Settings.change(func() -> void: Settings.volume[bus] = clampi(Settings.volume[bus] + by, 0, Settings.VOLUME_STEPS))
	_refresh()


func next_language() -> void:
	var i := Strings.LOCALES.find(Settings.locale)
	Settings.change(func() -> void: Settings.locale = Strings.LOCALES[(i + 1) % Strings.LOCALES.size()])
	_build()
