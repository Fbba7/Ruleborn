class_name Home
extends Control
## Where the app opens: play a heist, watch one, or change the settings.

func _ready() -> void:
	Settings.restore()
	var column := UI.frame(self)
	column.add_child(UI.grow())
	column.add_child(UI.label(Strings.t("APP_NAME"), 48))
	column.add_child(UI.label(Strings.t("HOME_TAGLINE"), UI.TEXT_POINTS, true))
	column.add_child(UI.grow())
	var actions := UI.row()
	actions.add_child(UI.button(Strings.t("HOME_PLAY"), func(): get_tree().change_scene_to_file("res://scenes/heist_screen.tscn"), true))
	actions.add_child(UI.button(Strings.t("HOME_WATCH"), func(): get_tree().change_scene_to_file("res://scenes/replay_screen.tscn")))
	column.add_child(actions)
	var more := UI.row()
	more.add_child(UI.button(Strings.t("HOME_SETTINGS"), func(): get_tree().change_scene_to_file("res://scenes/settings.tscn")))
	column.add_child(more)
