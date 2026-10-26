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
## unless another material is given. Words wider than `widest` points (at
## large text) end in an ellipsis; the label keeps them all, and a screen
## reader says them all.
static func pill(text: String, icon := "", look := "glass", widest := 240.0) -> PanelContainer:
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
	l.set_meta("widest", widest)
	row.add_child(l)
	p.add_child(row)
	set_pill(p, text)
	return p


## A pill's new words, ellipsised past its widest.
static func set_pill(p: PanelContainer, text: String) -> void:
	var l := p.find_child("Words", true, false) as Label
	l.text = text
	var font := RbTheme.role_font("label")
	var natural := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1,
		l.get_theme_font_size("font_size") if l.is_inside_tree() else UI.text_px(14)).x + 2.0
	var cap := float(UI.px(float(l.get_meta("widest", 240.0))))
	# A label that may trim asks for no width at all, so it trims only
	# when the words pass the cap, and then holds the cap.
	l.clip_text = natural > cap
	l.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS if natural > cap else TextServer.OVERRUN_NO_TRIMMING
	l.custom_minimum_size.x = cap if natural > cap else 0.0


## A resource with its storage (§21.8's home layout: "resources with storage
## bars"): its icon in a dark disc, the amount in tabular figures at the
## pill's end, FULL written in gold before it when the store is nine-tenths
## full or more, and the share of storage as a line glowing along the
## pill's foot.
static func resource(icon: String, amount: String, fraction: float, tone: Color) -> PanelContainer:
	var p := PanelContainer.new()
	p.name = "Resource"
	var pad := UI.clear_box(3, 2)
	pad.content_margin_right = UI.px(10)
	pad.content_margin_bottom = UI.px(1)
	p.add_theme_stylebox_override("panel", pad)
	UI.dress(p, "track", 999)
	p.custom_minimum_size.y = UI.px(Tokens.number("size", "pill_points"))
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 0)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", UI.px(4))
	row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var disc := PanelContainer.new()
	disc.add_theme_stylebox_override("panel", UI.clear_box(2, 2))
	UI.dress(disc, "icon_disc")
	disc.add_child(Icons.view(icon, 22))
	disc.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(disc)
	var full := UI.label(Strings.t("KIT_FULL"), 13)
	full.theme_type_variation = "Kicker"
	full.uppercase = true
	full.add_theme_color_override("font_color", Tokens.color("gold_top"))
	full.set_meta("bold", true)
	full.name = "Full"
	var room := Control.new()
	room.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	room.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(room)
	row.add_child(full)
	var l := UI.label(amount, 16)
	l.theme_type_variation = "Number"
	l.set_meta("bold", true)
	l.name = "Amount"
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	row.add_child(l)
	v.add_child(row)
	var bar := KitBar.make(fraction, tone, 4)
	bar.name = "Storage"
	bar.inset_points = 0.0
	RbBox.dress(bar, "icon_disc")
	RbBox.dress(bar.fill, "bar_line")
	bar.colour(tone.lightened(0.15))
	var inset := MarginContainer.new()
	inset.add_theme_constant_override("margin_left", UI.px(14))
	inset.add_theme_constant_override("margin_right", UI.px(4))
	inset.add_child(bar)
	v.add_child(inset)
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


## The universe's stability (§5.5) on a glass pill: a dot in its band's
## colour and the share and band in words ("82% · Humming"), so the band
## never rests on its colour.
static func strain(words: String, band: String) -> PanelContainer:
	var p := pill(words)
	p.name = "Strain"
	var dot := KitRing.new()
	dot.dot = true
	dot.fraction = 1.0
	dot.tint = Tokens.color("band_" + band)
	dot.custom_minimum_size = Vector2.ONE * UI.px(14)
	dot.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var row := p.get_child(0) as HBoxContainer
	row.add_child(dot)
	row.move_child(dot, 0)
	return p


## An island's label over the map: a cream pill with the realm's icon, its
## name in Marcellus and its level on a dark disc.
static func island_label(icon: String, name: String, level: int) -> PanelContainer:
	var p := PanelContainer.new()
	p.name = "IslandLabel"
	p.add_theme_stylebox_override("panel", UI.clear_box(5, 2))
	UI.dress(p, "island_label")
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", UI.px(5))
	if icon != "":
		row.add_child(Icons.view(icon, 22))
	var n := UI.label(name, 16)
	n.theme_type_variation = "Heading"
	n.add_theme_font_size_override("font_size", UI.text_px(16))
	row.add_child(n)
	var disc := PanelContainer.new()
	disc.add_theme_stylebox_override("panel", UI.clear_box(4, 0))
	UI.dress(disc, "level_disc")
	disc.custom_minimum_size = Vector2.ONE * UI.px(22)
	var l := UI.label(str(level), 13)
	l.theme_type_variation = "Number"
	l.set_meta("bold", true)
	disc.add_child(l)
	disc.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(disc)
	p.add_child(row)
	return p


## A ribbon tag on a card's corner (FEATURED SET, EMOTE): small capitals on
## gold, or on a dark plate.
static func tag(text: String, dark := false) -> PanelContainer:
	var p := PanelContainer.new()
	p.name = "Tag"
	p.add_theme_stylebox_override("panel", UI.clear_box(7, 1))
	UI.dress(p, "tag_dark" if dark else "tag")
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	p.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	var l := UI.label(text, 13)
	l.theme_type_variation = "Kicker"
	l.uppercase = true
	l.set_meta("bold", true)
	p.add_child(l)
	return p


## Experience toward the next level (the Character screen): a green bar
## cut into segments with its figures written inside it ("588 / 600 XP").
static func xp(done: float, of: float, words: String, segments := 8) -> Control:
	var bar := KitBar.make(0.0 if of <= 0.0 else done / of, Tokens.color("green_bar"), 22)
	bar.name = "Experience"
	var ticks := KitTicks.new()
	ticks.count = segments
	ticks.set_anchors_preset(Control.PRESET_FULL_RECT)
	ticks.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bar.add_child(ticks)
	var l := UI.label(words, 13)
	l.theme_type_variation = "Number"
	l.set_anchors_preset(Control.PRESET_FULL_RECT)
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	l.add_theme_color_override("font_color", Tokens.color("text_on_night"))
	l.add_theme_color_override("font_outline_color", Tokens.color("ink_line"))
	l.add_theme_constant_override("outline_size", UI.px(2))
	l.set_meta("bold", true)
	bar.add_child(l)
	return bar
