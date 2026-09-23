class_name ResultScreen
extends Control
## What a heist came to (§23.2's result screen: "Grade, loot kept, … replay"),
## read from the check the server would make, never from what the device
## claims: the grade is the re-simulation's (§24.12).

var grade_label: Label
var detail_label: Label
var check_label: Label


func _ready() -> void:
	var column := UI.frame(self)
	column.add_child(UI.grow())
	var card := UI.panel()
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", UI.px(8))
	card.add_child(box)
	grade_label = UI.label("", UI.TITLE_POINTS)
	detail_label = UI.label("", UI.TEXT_POINTS, true)
	check_label = UI.label("", UI.TEXT_POINTS, true)
	box.add_child(grade_label)
	box.add_child(detail_label)
	box.add_child(check_label)
	column.add_child(card)
	column.add_child(UI.grow())
	var actions := UI.row()
	actions.add_child(UI.button("Watch it", func(): get_tree().change_scene_to_file("res://scenes/replay_screen.tscn"), true))
	actions.add_child(UI.button("Again", func(): get_tree().change_scene_to_file("res://scenes/heist_screen.tscn")))
	actions.add_child(UI.button("Home", func(): get_tree().change_scene_to_file("res://scenes/home.tscn")))
	column.add_child(actions)
	show_verdict(Session.verdict, Session.replay.size())


func show_verdict(v: Dictionary, replay_bytes: int) -> void:
	var by_server: bool = v.get("server", false)
	if v.get("ok", false):
		grade_label.text = str(v["grade"])
		if by_server:
			detail_label.text = "%d loot banked — the server minted %d (fee %d)" % [
				int(v["banked"]), int(v["haul"]), int(v["fee"])]
			check_label.text = "Re-simulated by the server: accepted\n%d-byte replay" % replay_bytes
		else:
			detail_label.text = "%d loot banked" % int(v["banked"])
			check_label.text = "Re-simulated as the server would: accepted\n%d-byte replay" % replay_bytes
		check_label.add_theme_color_override("font_color", Palette.SUCCESS.darkened(0.3))
	else:
		grade_label.text = "Not accepted"
		detail_label.text = str(v.get("refused", "no heist"))
		check_label.text = ("The server paid nothing for this replay" if by_server
			else "The server would pay nothing for this replay")
		check_label.add_theme_color_override("font_color", Palette.ALARM)
