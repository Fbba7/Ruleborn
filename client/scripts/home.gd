class_name Home
extends Control
## Where the app opens. Two ways in for now: play a heist, or watch one.

func _ready() -> void:
	var column := UI.frame(self)
	column.add_child(UI.grow())
	column.add_child(UI.label("Ruleborn", 48))
	column.add_child(UI.label("A heist on the fixture realm, played and checked on this phone.", UI.TEXT_POINTS, true))
	column.add_child(UI.grow())
	var actions := UI.row()
	actions.add_child(UI.button("Play a heist", func(): get_tree().change_scene_to_file("res://scenes/heist_screen.tscn"), true))
	actions.add_child(UI.button("Watch replays", func(): get_tree().change_scene_to_file("res://scenes/replay_screen.tscn")))
	column.add_child(actions)
