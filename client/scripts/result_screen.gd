class_name ResultScreen
extends Control
## What a heist came to (§23.2's result screen: "Grade, loot kept, … replay"),
## read from the check the server would make, never from what the device
## claims: the grade is the re-simulation's (§24.12). A cleared rehearsal
## offers to publish the island (§18.6); a Workshop play, to rate it.

var grade_label: Label
var detail_label: Label
var check_label: Label
## A Workshop play's Again, which waits for the island's answer.
var again_button: Button


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
	var play: Dictionary = heist["workshop"]
	if heist["testing"]:
		actions.add_child(UI.button(Strings.t("RESULT_BUILDER"), func() -> void: App.services.router.go(&"builder")))
		# §18.6: a cleared rehearsal is the clear the Workshop publishes with.
		if WorkshopController.clears(heist["verdict"]) and not heist["published"]:
			actions.add_child(UI.button(Strings.t("RESULT_PUBLISH"), func() -> void:
				App.services.router.go(&"workshop", {"publish": true})))
	elif not play.is_empty():
		# §18.6: a play the server has checked may rate the island.
		var v: Dictionary = heist["verdict"]
		if v.get("ok", false) and v.get("server", false):
			actions.add_child(UI.button(Strings.t("RESULT_RATE"), func() -> void:
				App.services.router.go(&"workshop", {"rate": true})))
		again_button = UI.button(Strings.t("RESULT_AGAIN"), play_again.bind(str(play["id"])))
		actions.add_child(again_button)
	else:
		actions.add_child(UI.button(Strings.t("RESULT_AGAIN"), func() -> void:
			App.services.store.dispatch(&"heist_started", {})
			App.services.router.go(&"heist")))
	actions.add_child(UI.button(Strings.t("COMMON_HOME"), func() -> void: App.services.router.go(&"home")))
	column.add_child(UI.narrow(actions))
	show_verdict(heist["verdict"], (heist["replay"] as PackedByteArray).size())


## The Workshop island again, on a new play: the button waits for the answer,
## and a refusal (withdrawn since, no network) is said here, not lost.
func play_again(id: String) -> void:
	again_button.disabled = true
	var heist := await App.services.workshop_flow.play(id)
	if not is_inside_tree():
		return
	if heist.is_empty():
		again_button.disabled = false
		UI.set_status(check_label, "alarm", Errors.message("WORKSHOP_FAILED",
			str(App.services.store.get_slice(WorkshopState.WORKSHOP)["error"])))
		return
	App.services.workshop_flow.start(heist)


func show_verdict(v: Dictionary, replay_bytes: int) -> void:
	var by_server: bool = v.get("server", false)
	if v.get("ok", false):
		grade_label.text = Strings.term("GRADE", str(v["grade"]))
		if v.get("workshop", false):
			# A Workshop play banks nothing: it clears the island or not, and a
			# clear counts once a player (§18.7).
			detail_label.text = Strings.t("WORKSHOP_CLEARED" if WorkshopController.clears(v)
				else "WORKSHOP_NOT_CLEARED")
			if by_server and WorkshopController.clears(v):
				detail_label.text += "\n" + Strings.t("RESULT_COUNTED" if v.get("counted", false) else "RESULT_NOT_COUNTED")
			check_label.text = Strings.t("RESULT_CONFIRMING" if v.get("confirming", false)
				else "RESULT_ACCEPTED_SERVER", replay_bytes)
		elif v.get("confirming", false):
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
		# A Workshop play stakes and pays nothing: refused, it does not count.
		var nothing := "RESULT_PAID_NOTHING" if by_server else "RESULT_WOULD_PAY_NOTHING"
		UI.set_status(check_label, "alarm", Strings.t("RESULT_PLAY_NOT_COUNTED" if v.get("workshop", false) else nothing))
