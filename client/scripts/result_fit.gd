class_name ResultFit
extends RefCounted
## How the result screen (`ResultScreen`) fits large text and long languages
## to the phone: the reward tiles as rows or columns, the multipliers' pill on
## one line, Home as its icon, and the measures the raid bar is fitted by.
## A helper of its own so result_screen.gd stays within gdlint's file length.


## The column a page's content has across a phone `width` wide: the width
## less the safe side on each edge.
static func column(width: float) -> float:
	return width - 2.0 * UI.px(Tokens.number("size", "safe_side_points"))


## With large text, one reward tile laid as a row rather than a column, as
## 03-result_text200_pt_BR: its icon, its number and its name side by side
## from the left, so the three stand under the time line. The number is
## still the box's second child and the box the tile's only one
## (`ResultScreen._reward_tile`).
static func tile_row(tile: PanelContainer) -> void:
	if Settings.text_scale <= KitLayout.SIDE_BY_SIDE_UP_TO:
		return
	var col := tile.get_child(0) as VBoxContainer
	var row := HBoxContainer.new()
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_theme_constant_override("separation", UI.px(10))
	row.alignment = BoxContainer.ALIGNMENT_BEGIN
	for c: Node in col.get_children():
		col.remove_child(c)
		row.add_child(c)
		(c as Control).size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var icon := row.get_child(0) as Control
	icon.custom_minimum_size = Vector2.ONE * UI.px(26)
	var words := row.get_child(2) as Label
	words.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	words.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tile.remove_child(col)
	col.queue_free()
	tile.add_child(row)
	tile.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tile.custom_minimum_size.x = 0
	# A row needs less height than the tile's column: the key frame's rows
	# are a line of the number deep, so the third clears the dock.
	tile.add_theme_stylebox_override("panel", UI.clear_box(10, 3))


## With large text, the reward rows (`labels`, each tile's number, in
## `rows`) while each one's icon, number and name fit across a phone `width`
## wide; when one does not (German's "Sternenlicht" beside its number), every
## tile goes back to the design's column, one above another, rather than
## break a word by its letters.
static func reward_rows(rows: BoxContainer, labels: Dictionary, width: float) -> void:
	if Settings.text_scale <= KitLayout.SIDE_BY_SIDE_UP_TO:
		return
	var room := column(width) - 2.0 * UI.px(10) - 2.0
	var fits := true
	for kind: String in labels:
		var row := (labels[kind] as Label).get_parent() as BoxContainer
		var wide := float(UI.px(26)) + 2.0 * row.get_theme_constant("separation")
		for l: Label in [row.get_child(1), row.get_child(2)]:
			wide += l.get_theme_font("font").get_string_size(l.text, HORIZONTAL_ALIGNMENT_LEFT, -1,
				l.get_theme_font_size("font_size")).x
		fits = fits and wide <= room
	if fits:
		return
	rows.add_theme_constant_override("separation", UI.px(8))
	for kind: String in labels:
		tile_column((labels[kind] as Label).get_parent().get_parent() as PanelContainer)


## A reward tile back from a row to the design's column: its icon, its
## number and its name centred one above another (KitCards.reward's).
static func tile_column(tile: PanelContainer) -> void:
	var row := tile.get_child(0) as HBoxContainer
	var col := VBoxContainer.new()
	col.mouse_filter = Control.MOUSE_FILTER_IGNORE
	col.add_theme_constant_override("separation", 0)
	col.alignment = BoxContainer.ALIGNMENT_CENTER
	for c: Node in row.get_children():
		row.remove_child(c)
		col.add_child(c)
		(c as Control).size_flags_vertical = Control.SIZE_FILL
	var icon := col.get_child(0) as Control
	icon.custom_minimum_size = Vector2.ONE * UI.px(34)
	var words := col.get_child(2) as Label
	words.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	words.size_flags_horizontal = Control.SIZE_FILL
	tile.remove_child(row)
	row.queue_free()
	tile.add_child(col)
	tile.add_theme_stylebox_override("panel", UI.clear_box(10, 8))


## Large text: the multipliers' pill (`chip`, its words `label`) on one line
## while it fits the column of a phone `width` wide (AD's S1-R24): at its own
## size, then with its gaps narrowed (the pill's padding, thin spaces round
## its dots), then one size down. False when none fits (a long language);
## the pill then wraps at its dots.
static func chip_on_one_line(chip: PanelContainer, label: Label, width: float) -> bool:
	var font := RbTheme.role_font("label")
	var room := column(width) - UI.px(4)
	var words := label.text
	var narrow := words.replace(" · ", " · ")
	for step: Array in [[words, 10.0, 14.0], [narrow, 6.0, 14.0], [narrow, 6.0, 12.0]]:
		var size := UI.text_px(float(step[2]))
		var wide := font.get_string_size(str(step[0]), HORIZONTAL_ALIGNMENT_LEFT, -1, size).x + 2.0
		if wide + 2.0 * UI.px(float(step[1])) <= room:
			chip.add_theme_stylebox_override("panel", UI.clear_box(float(step[1]), 4))
			label.add_theme_font_size_override("font_size", size)
			label.text = str(step[0])
			label.clip_text = false
			label.text_overrun_behavior = TextServer.OVERRUN_NO_TRIMMING
			label.custom_minimum_size.x = 0
			return true
	return false


## Home as its icon alone, on a square of the control's height, its name
## spoken (the raid bar's large-text form, `ResultScreen._fit_raid`).
static func home_square(home: Button) -> void:
	home.accessibility_name = home.text
	home.tooltip_text = home.text
	home.text = ""
	home.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	home.custom_minimum_size = Vector2.ONE * UI.px(UI.CONTROL_POINTS + 8.0)
	home.size_flags_vertical = Control.SIZE_SHRINK_CENTER


## Whether each word of each label in `words` fits `room`.
static func words_fit(words: Array[Node], room: float) -> bool:
	for l: Label in words:
		var font := l.get_theme_font("font")
		var text := l.text.to_upper() if l.uppercase else l.text
		for word: String in text.split(" ", false):
			if font.get_string_size(word, HORIZONTAL_ALIGNMENT_LEFT, -1, l.get_theme_font_size("font_size")).x > room:
				return false
	return true


## How many lines `l`'s words take wrapped between words within `room`.
static func lines(l: Label, room: float) -> int:
	var font := l.get_theme_font("font")
	var font_px := l.get_theme_font_size("font_size")
	var text := l.text.to_upper() if l.uppercase else l.text
	var n := 1
	var line := ""
	for word: String in text.split(" ", false):
		var next := word if line == "" else line + " " + word
		if line != "" and font.get_string_size(next, HORIZONTAL_ALIGNMENT_LEFT, -1, font_px).x > room:
			n += 1
			line = word
		else:
			line = next
	return n


## Whether each word on `b` fits the room its padding and icon leave.
static func word_fits(b: Button) -> bool:
	var room := b.size.x - b.get_theme_stylebox("normal").get_minimum_size().x
	if b.icon != null:
		room -= UI.px(24) + b.get_theme_constant("h_separation")
	var font := b.get_theme_font("font")
	var font_px := b.get_theme_font_size("font_size")
	for word: String in b.text.split(" ", false):
		if font.get_string_size(word, HORIZONTAL_ALIGNMENT_LEFT, -1, font_px).x > room:
			return false
	return true
