class_name ResultScreen
extends Control
## What a heist came to (§23.2's result screen: "Grade, loot kept, … replay"),
## read from the check the server would make, never from what the device
## claims: the grade is the re-simulation's (§24.12).

var grade_label: Label
var detail_label: Label
var check_label: Label


func _ready() -> void:
	App.ready(self)
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
	actions.add_child(UI.button(Strings.t("RESULT_WATCH"), func() -> void: App.services.router.go(&"replay"), true))
	var heist: Dictionary = App.services.store.get_slice(AppState.HEIST)
	if heist["testing"]:
		actions.add_child(UI.button(Strings.t("RESULT_BUILDER"), func() -> void: App.services.router.go(&"builder")))
	else:
		actions.add_child(UI.button(Strings.t("RESULT_AGAIN"), func() -> void:
			App.services.store.dispatch(&"heist_started", {})
			App.services.router.go(&"heist")))
	actions.add_child(UI.button(Strings.t("COMMON_HOME"), func() -> void: App.services.router.go(&"home")))
	column.add_child(UI.narrow(actions))
	show_verdict(heist["verdict"], (heist["replay"] as PackedByteArray).size())


func show_verdict(v: Dictionary, replay_bytes: int) -> void:
	var by_server: bool = v.get("server", false)
	if v.get("ok", false):
		grade_label.text = Strings.term("GRADE", str(v["grade"]))
		if v.get("confirming", false):
			detail_label.text = Strings.t("RESULT_BANKED", int(v["banked"]))
			check_label.text = Strings.t("RESULT_CONFIRMING", replay_bytes)
		elif by_server:
			detail_label.text = Strings.t("RESULT_BANKED_SERVER", [int(v["banked"]), int(v["haul"]), int(v["fee"])])
			check_label.text = Strings.t("RESULT_ACCEPTED_SERVER", replay_bytes)
		else:
			detail_label.text = Strings.t("RESULT_BANKED", int(v["banked"]))
			check_label.text = Strings.t("RESULT_ACCEPTED_LOCAL", replay_bytes)
		UI.set_status(check_label, "confirming" if v.get("confirming", false) else "success", check_label.text)
	else:
		grade_label.text = Strings.t("RESULT_NOT_ACCEPTED")
		detail_label.text = Errors.message("RESULT_REFUSED", str(v.get("refused", "")))
		UI.set_status(check_label, "alarm",
			Strings.t("RESULT_PAID_NOTHING" if by_server else "RESULT_WOULD_PAY_NOTHING"))
