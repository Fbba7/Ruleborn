class_name UniverseNotice
extends PanelContainer
## The raid notice over home's goal, as the designs raise theirs over the tab
## bar: a dark card edged in the alarm's red with the design's raided icon,
## how many raids came while the player was away, a way to the defence log,
## and a close control. §21.8: a notice that carries information stays until
## the player dismisses it; it never clears itself. With large text (§20.8)
## the words take the card's whole width, the mark, See and the close control
## in a row beneath, so the card stays a few lines high.

signal seen
signal dismissed

var words: Label
var see_button: Button
var close_button: Button


func _init() -> void:
	var box := UniverseHud.plate(UniverseHud.CARD[0], UI.px(16))
	box.border_color = UniverseHud.ALARM
	box.set_content_margin_all(UI.px(8))
	box.content_margin_left = UI.px(10)
	add_theme_stylebox_override("panel", box)
	var large := Settings.text_scale >= 150
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", UI.px(8))
	var mark := TextureRect.new()
	mark.texture = UniverseHud.icon("alert_raided")
	mark.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	mark.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	mark.custom_minimum_size = Vector2.ONE * UI.px(40)
	mark.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(mark)
	words = UI.label("", 14.0, true)
	words.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	words.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	words.add_theme_font_override("font", UniverseHud.words_font())
	words.add_theme_color_override("font_color", UniverseHud.WORDS)
	if large:
		words.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		var stack := VBoxContainer.new()
		stack.add_theme_constant_override("separation", UI.px(6))
		stack.add_child(words)
		stack.add_child(row)
		add_child(stack)
		var room := Control.new()
		room.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		room.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.add_child(room)
	else:
		add_child(row)
		row.add_child(words)
	see_button = UI.button(Strings.t("HOME_RAIDED_SEE"), func() -> void: seen.emit(), true)
	row.add_child(see_button)
	close_button = UI.button("×", func() -> void: dismissed.emit(), false, UniverseHud.CARD[1],
		Strings.t("HOME_RAIDED_CLOSE"))
	for colour: String in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color",
			"font_disabled_color"]:
		close_button.add_theme_color_override(colour, UniverseHud.WORDS)
	row.add_child(close_button)

## The raids not yet seen; none hides the notice.
func show_raids(unseen: int) -> void:
	visible = unseen > 0
	words.text = Strings.t("HOME_RAIDED_ONE") if unseen == 1 else Strings.t("HOME_RAIDED", unseen)
