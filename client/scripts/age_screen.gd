class_name AgeScreen
extends Control
## §20.1's age check at first launch, when the platform cannot say: four
## bands, none suggested, no birthdate. Under 13, the player is told the game
## is for 13 and up, and no account is made; the question is not asked again.

var question_label: Label
var answers: HFlowContainer


func _ready() -> void:
	App.ready(self)
	var column := ScreenKit.frame(self)
	column.add_child(UI.grow())
	var mark := ScreenKit.icon("screens", "universe", 120.0)
	mark.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	column.add_child(mark)
	var name := ScreenKit.inked(ScreenKit.text(Strings.t("APP_NAME"), 44.0, "name", "card"), 2.0)
	name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(name)
	column.add_child(KitNav.rule())
	column.add_child(UI.grow())
	question_label = ScreenKit.text("", 20.0, "words", "parchment", false, true)
	question_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(ScreenKit.panel("parchment", question_label, 18.0, 16.0))
	answers = UI.row(10.0, true)
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
		# Four bands, none suggested: every answer in the same material.
		var b := ScreenKit.button(Strings.t("AGE_" + band.replace("-", "_").replace("+", "_UP").to_upper()),
			choose.bind(band), "leather")
		b.custom_minimum_size.x = maxf(b.custom_minimum_size.x, UI.px(110))
		answers.add_child(b)


## The player's answer: kept, and — 13 and over — on to the game.
func choose(band: String) -> void:
	App.services.age.answer(band)
	if App.services.age.allows_account():
		App.services.router.go(&"home")
	else:
		show_check()
