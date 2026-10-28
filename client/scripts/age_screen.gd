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
	var top := Control.new()
	top.custom_minimum_size.y = UI.px(36 if Settings.text_scale <= 125 else 0)
	column.add_child(top)
	# The design's first launch: the gold logo, the line under it, then the
	# universe's mark with three of the ruleborn before it.
	var name := KitNav.logo(Strings.t("APP_NAME"))
	name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(name)
	var line := ScreenKit.text(Strings.t("SCREEN_TAGLINE"), 18.0, "name", "card", false, true)
	line.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(line)
	column.add_child(KitNav.rule())
	var stage := VBoxContainer.new()
	stage.alignment = BoxContainer.ALIGNMENT_CENTER
	stage.add_theme_constant_override("separation", -UI.px(16))
	stage.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var mark := ScreenKit.icon("screens", "universe", 150.0)
	mark.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	stage.add_child(mark)
	stage.add_child(_lineup())
	# At large text the question and its answers need the height.
	stage.visible = Settings.text_scale <= 125
	column.add_child(stage)
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


## Three of the ruleborn side by side, the middle one larger and in front,
## as the design gathers them under its title: a picture, said by the words.
static func _lineup() -> Control:
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", -UI.px(28))
	for k: Array in [["emberling", 108.0], ["mossbear", 136.0], ["rootrunner", 108.0]]:
		var face := TextureRect.new()
		face.texture = Portrait.of(str(k[0]))
		face.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		face.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		face.custom_minimum_size = Vector2.ONE * UI.px(float(k[1]))
		face.size_flags_vertical = Control.SIZE_SHRINK_END
		face.mouse_filter = Control.MOUSE_FILTER_IGNORE
		# The larger one in front of the two beside it.
		face.z_index = 1 if float(k[1]) > 108.0 else 0
		row.add_child(face)
	return row
