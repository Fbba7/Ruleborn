class_name Home
extends Control
## Where the app opens: play a heist, watch one, or change the settings.

func _ready() -> void:
	App.ready(self)
	Settings.restore()
	var column := UI.frame(self)
	column.add_child(UI.grow())
	column.add_child(UI.label(Strings.t("APP_NAME"), 48))
	column.add_child(UI.plate(UI.label(Strings.t("HOME_TAGLINE"), UI.TEXT_POINTS, true)))
	column.add_child(UI.grow())
	var actions := UI.row()
	actions.add_child(UI.button(Strings.t("HOME_PLAY"), _play, true))
	actions.add_child(UI.button(Strings.t("HOME_WATCH"), func() -> void: App.services.router.go(&"replay")))
	column.add_child(actions)
	var more := UI.row()
	more.add_child(UI.button(Strings.t("HOME_BUILD"), func() -> void: App.services.router.go(&"builder")))
	more.add_child(UI.button(Strings.t("HOME_SETTINGS"), func() -> void: App.services.router.go(&"settings")))
	column.add_child(UI.narrow(more))


## A heist on the fixture realm or a leased island: not the builder's test.
func _play() -> void:
	App.services.store.dispatch(&"heist_started", {})
	App.services.router.go(&"heist")
