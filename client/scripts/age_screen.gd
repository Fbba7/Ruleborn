class_name AgeScreen
extends Control
## §20.1's age check at first launch, when the platform cannot say: four
## bands, none suggested, no birthdate. Under 13, the player is told the game
## is for 13 and up, and no account is made; the question is not asked again.

var question_label: Label
var answers: HFlowContainer


func _ready() -> void:
	App.ready(self)
	var column := UI.frame(self)
	column.add_child(UI.title(Strings.t("APP_NAME")))
	column.add_child(UI.grow())
	question_label = UI.label("", UI.TEXT_POINTS, true)
	column.add_child(UI.plate(question_label))
	column.add_child(UI.grow())
	answers = UI.row(-1.0, true)
	column.add_child(UI.narrow(answers))
	show_check()


func show_check() -> void:
	for c in answers.get_children():
		c.queue_free()
	var age: AgeCheck = App.services.age
	if age.band() == "under-13":
		question_label.text = Strings.t("AGE_TOO_YOUNG")
		return
	question_label.text = Strings.t("AGE_QUESTION")
	for band: String in AgeCheck.BANDS:
		answers.add_child(UI.button(Strings.t("AGE_" + band.replace("-", "_").replace("+", "_UP").to_upper()),
			choose.bind(band)))


## The player's answer: kept, and — 13 and over — on to the game.
func choose(band: String) -> void:
	App.services.age.answer(band)
	if App.services.age.allows_account():
		App.services.router.go(&"home")
	else:
		show_check()
