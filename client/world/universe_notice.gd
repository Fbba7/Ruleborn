class_name UniverseNotice
extends PanelContainer
## The raid notice over home's foot, as the designs raise theirs over Collect:
## a dark plum card edged in the alarm's red, the heist's mark on a red disc,
## a bold headline (how many raids came while the player was away) over a rose
## line saying where to see how the defence held, a gold See and a close mark.
## §21.8: a notice that carries information stays until the player dismisses
## it; it never clears itself. With large text (§20.8) the words take the
## card's whole width, the mark, See and the close control in a row beneath.

signal seen
signal dismissed

## The rose of the card's second line and its close mark, as the design's.
const ROSE := Color("#FFB3C0")

## The headline.
var words: Label
## The line under it.
var line: Label
var see_button: Button
var close_button: Button


func _init() -> void:
	var box := UniverseHud.plate(Color("#2C1028") if Settings.high_contrast else Color(0.2, 0.07, 0.16, 0.96),
		UI.px(16))
	box.border_color = UniverseHud.ALARM if Settings.high_contrast else Color(UniverseHud.ALARM, 0.6)
	box.set_border_width_all(UI.px(3.0) if Settings.high_contrast else maxi(2, UI.px(1.5)))
	box.shadow_color = Color(0, 0, 0, 0.5)
	box.shadow_size = UI.px(10)
	box.shadow_offset = Vector2(0, UI.px(6))
	box.set_content_margin_all(UI.px(6))
	box.content_margin_left = UI.px(8)
	add_theme_stylebox_override("panel", box)
	var large := Settings.text_scale >= 150
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", UI.px(8))
	row.add_child(_mark())
	var text := VBoxContainer.new()
	text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text.alignment = BoxContainer.ALIGNMENT_CENTER
	text.add_theme_constant_override("separation", 0)
	words = _label(14.0, UniverseHud.WORDS, large)
	line = _label(13.0, ROSE, large)
	line.text = Strings.t("HOME_RAID_LINE")
	text.add_child(words)
	text.add_child(line)
	if large:
		var stack := VBoxContainer.new()
		stack.add_theme_constant_override("separation", UI.px(6))
		stack.add_child(text)
		stack.add_child(row)
		add_child(stack)
		var room := Control.new()
		room.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		room.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.add_child(room)
	else:
		add_child(row)
		row.add_child(text)
	see_button = UI.button(Strings.t("HOME_RAIDED_SEE").to_upper(), func() -> void: seen.emit(), true)
	see_button.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(see_button)
	close_button = UI.action("×", func() -> void: dismissed.emit(), "ghost", Strings.t("HOME_RAIDED_CLOSE"))
	close_button.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	for state: String in ["normal", "hover", "pressed", "disabled"]:
		close_button.add_theme_stylebox_override(state, StyleBoxEmpty.new())
	var rb := RbBox.of(close_button)
	if rb != null:
		rb.visible = false
	close_button.add_theme_font_size_override("font_size", UI.text_px(20.0))
	for colour: String in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color",
			"font_disabled_color"]:
		close_button.add_theme_color_override(colour, ROSE)
	close_button.set_meta("text_bg", [box.bg_color])
	row.add_child(close_button)


## The raids not yet seen; none hides the notice.
## It arrives as the designs' banner does, growing into place as it fades in
## (§21.8: easing out, no overshoot); under reduced motion it only fades.
func show_raids(unseen: int) -> void:
	var was := visible
	visible = unseen > 0
	if visible and not was and is_inside_tree():
		Motion.pop(self)
	words.text = Strings.t("HOME_RAID_TITLE_ONE") if unseen == 1 else Strings.t("HOME_RAID_TITLE", unseen)
	accessibility_name = "%s. %s" % [words.text, line.text]


## The heist's mark on the design's red disc, ringed in rose.
static func _mark() -> Control:
	var disc := PanelContainer.new()
	var b := StyleBoxFlat.new()
	b.bg_color = Color("#B8304E")
	b.border_color = ROSE
	b.set_border_width_all(maxi(2, UI.px(1.5)))
	b.set_corner_radius_all(UI.px(20))
	b.set_content_margin_all(UI.px(6))
	b.anti_aliasing = true
	disc.add_theme_stylebox_override("panel", b)
	disc.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	disc.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var mark := TextureRect.new()
	mark.texture = Icons.texture("screens/heist")
	mark.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	mark.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	mark.custom_minimum_size = Vector2.ONE * UI.px(22)
	mark.mouse_filter = Control.MOUSE_FILTER_IGNORE
	disc.add_child(mark)
	return disc


## A line of the card's words: one line cut short with an ellipsis, as the
## design's, and said whole; wrapped where large text takes the card's width.
static func _label(points: float, colour: Color, wraps: bool) -> Label:
	var l := UI.label("", points, true)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	l.add_theme_font_override("font", UniverseHud.words_font())
	l.add_theme_color_override("font_color", colour)
	if wraps:
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	else:
		l.autowrap_mode = TextServer.AUTOWRAP_OFF
		l.clip_text = true
		l.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	return l
