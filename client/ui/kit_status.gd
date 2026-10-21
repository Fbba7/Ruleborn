class_name KitStatus
## What a screen reports at a glance: count badges, pills (glass over the
## world, as the designs' strain pill), resource pills with their storage
## line and the FULL tag, level plates and progress bars. Every one writes
## its number or word; colour is never the only sign (§20.8).


## A count badge: white words with an ink outline on the designs' red,
## measured against the outline (§21.8).
static func badge(text: String) -> PanelContainer:
	var p := PanelContainer.new()
	p.name = "Badge"
	p.add_theme_stylebox_override("panel", UI.clear_box(5, 0))
	UI.dress(p, "badge")
	var size := UI.px(Tokens.number("size", "badge_points"))
	p.custom_minimum_size = Vector2(size, size)
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var l := UI.label(text, 13)
	l.add_theme_font_override("font", UI.bold_font())
	l.add_theme_color_override("font_color", Tokens.color("on_alarm"))
	l.add_theme_color_override("font_outline_color", Tokens.color("ink_line"))
	l.add_theme_constant_override("outline_size", UI.px(2))
	l.set_meta("bold", true)
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	p.add_child(l)
	return p


## A pill of words, with an icon before them if named: glass over the world
## unless another material is given.
static func pill(text: String, icon := "", look := "glass") -> PanelContainer:
	var p := PanelContainer.new()
	p.name = "Pill"
	p.add_theme_stylebox_override("panel", UI.clear_box(10, 4))
	UI.dress(p, look, 999)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", UI.px(6))
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	if icon != "":
		row.add_child(Icons.view(icon, 22))
	var l := UI.label(text, 14)
	l.theme_type_variation = "LabelText"
	l.set_meta("bold", true)
	l.name = "Words"
	row.add_child(l)
	p.add_child(row)
	return p


## A resource with its storage (§21.8's home layout: "resources with storage
## bars"): its icon on a disc, the amount in tabular figures, and the share
## of storage as a line along the pill's foot, with FULL written when the
## store is nine-tenths full or more.
static func resource(icon: String, amount: String, fraction: float, tone: Color) -> PanelContainer:
	var p := PanelContainer.new()
	p.name = "Resource"
	p.add_theme_stylebox_override("panel", UI.clear_box(4, 3))
	UI.dress(p, "track", 999)
	p.custom_minimum_size.y = UI.px(Tokens.number("size", "pill_points"))
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", UI.px(1))
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", UI.px(4))
	row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	row.add_child(Icons.view(icon, 26))
	var l := UI.label(amount, 16)
	l.theme_type_variation = "Number"
	l.set_meta("bold", true)
	l.name = "Amount"
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(l)
	var full := badge(Strings.t("KIT_FULL"))
	full.name = "Full"
	row.add_child(full)
	v.add_child(row)
	var bar := KitBar.make(fraction, tone, 4)
	bar.name = "Storage"
	v.add_child(bar)
	p.add_child(v)
	set_resource(p, amount, fraction)
	return p


## A resource pill's new amount and share of storage.
static func set_resource(p: PanelContainer, amount: String, fraction: float) -> void:
	(p.find_child("Amount", true, false) as Label).text = amount
	Motion.fill(p.find_child("Storage", true, false) as KitBar, clampf(fraction, 0.0, 1.0))
	(p.find_child("Full", true, false) as Control).visible = fraction >= 0.9


## A small plate for a level or a count on a portrait ("LV 5"): parchment
## with ink figures.
static func plate(text: String) -> PanelContainer:
	var p := PanelContainer.new()
	p.name = "Plate"
	p.add_theme_stylebox_override("panel", UI.clear_box(6, 1))
	UI.dress(p, "plate")
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var l := UI.label(text, 13)
	l.theme_type_variation = "Number"
	l.set_meta("bold", true)
	p.add_child(l)
	return p


## A progress bar with its number written beside it ("3 / 5"), in `colour`
## (gold if none).
static func progress(done: float, of: float, words: String, tone := Color()) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.name = "Progress"
	row.add_theme_constant_override("separation", UI.px(8))
	var bar := KitBar.make(0.0 if of <= 0.0 else done / of, tone)
	bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(bar)
	var l := UI.label(words, 14)
	l.theme_type_variation = "Number"
	l.set_meta("bold", true)
	row.add_child(l)
	return row
