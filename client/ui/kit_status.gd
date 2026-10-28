class_name KitStatus
## What a screen reports at a glance: count badges, pills (glass over the
## world, as the designs' strain pill), resource pills with their storage
## line and the FULL tag, level plates and progress bars. Every one writes
## its number or word; colour is never the only sign (§20.8).


## A count badge: white words with an ink outline on the designs' red,
## measured against the outline (§21.8). In another round material (a
## building's level on "gold_round", a post's number on "leather") its
## words take that material's ink, in the display face, `points` large.
static func badge(text: String, look := "badge", points := 13.0) -> PanelContainer:
	var p := PanelContainer.new()
	p.name = "Badge"
	p.add_theme_stylebox_override("panel", UI.clear_box(5, 0))
	var box := UI.dress(p, look, 99.0 if look != "badge" else -1.0)
	var side := float(UI.px(Tokens.number("size", "badge_points")))
	if look != "badge":
		side = maxf(side, UI.px(points + 10.0))
	p.custom_minimum_size = Vector2(side, side)
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	p.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	p.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	var l := UI.label(text, points)
	l.name = "Words"
	# A count grows with the text to half again its size, no further: at 200%
	# it would cover the icon it counts for (it is also said aloud).
	l.add_theme_font_size_override("font_size", mini(UI.text_px(points), UI.px(points * 1.5)))
	l.add_theme_font_override("font", UI.bold_font() if look == "badge" else Tokens.font("display"))
	l.add_theme_color_override("font_color", Tokens.color("on_alarm") if look == "badge" else box.spec["text"])
	if look == "badge" or box.spec["family"] == "dark":
		l.add_theme_color_override("font_outline_color", Tokens.color("ink_line"))
		l.add_theme_constant_override("outline_size", UI.px(2))
	l.set_meta("bold", true)
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	p.add_child(l)
	return p


## A pill of words, with an icon before them if named: glass over the world
## unless another material is given. Words wider than `widest` points (by
## default the phone less its margins) end in an ellipsis; the label keeps
## them all, and a screen reader says them all.
static func pill(text: String, icon := "", look := "glass", widest := 300.0) -> PanelContainer:
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


## A hint over the world (02-heist.png's "Tap crew, then ground · hold
## ground to sneak or run"): dark glass, its words whole and centred,
## wrapping onto a second line rather than ending in an ellipsis.
static func hint(text: String) -> PanelContainer:
	var p := PanelContainer.new()
	p.name = "Hint"
	p.add_theme_stylebox_override("panel", UI.clear_box(14, 5))
	UI.dress(p, "glass", 14)
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	p.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var l := UI.label(text, 15, true)
	l.name = "Words"
	l.theme_type_variation = "LabelText"
	l.set_meta("bold", true)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	p.add_child(l)
	return p


## A pill's new words, ellipsised past its widest.
static func set_pill(p: PanelContainer, text: String) -> void:
	var l := p.find_child("Words", true, false) as Label
	l.text = text
	var font := RbTheme.role_font("label")
	var natural := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1,
		l.get_theme_font_size("font_size") if l.is_inside_tree() else UI.text_px(14)).x + 2.0
	var cap := float(UI.px(float(l.get_meta("widest", 300.0))))
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
	# 6 points at the end (T4's measure): "FULL 142.0k" fits a third of the
	# phone at 100% text, as the design's "FULL 61.0k" does.
	pad.content_margin_right = UI.px(6)
	pad.content_margin_bottom = UI.px(1)
	p.add_theme_stylebox_override("panel", pad)
	UI.dress(p, "track", 999)
	p.custom_minimum_size.y = UI.px(Tokens.number("size", "pill_points"))
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 0)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", UI.px(3))
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


## A stat tile (the designs' profile and result tiles): an icon if named,
## a big number in Lilita One, and what it counts beneath, wrapping.
static func stat(number: String, words: String, icon := "", look := "card") -> PanelContainer:
	var p := UI.panel(look)
	p.name = "Stat"
	p.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 0)
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	if icon != "":
		var i := Icons.view(icon, 26)
		i.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		v.add_child(i)
	var n := UI.label(number, 24)
	n.theme_type_variation = "DisplayS"
	n.add_theme_font_size_override("font_size", UI.text_px(24))
	n.set_meta("points", 24.0)
	n.name = "Number"
	v.add_child(n)
	var w := UI.label(words, 13, true)
	w.theme_type_variation = "Secondary"
	w.add_theme_font_override("font", UI.bold_font())
	w.set_meta("bold", true)
	v.add_child(w)
	p.add_child(v)
	return p


## A sash across a card's top right corner (08-observatory.png's "TRACE ·
## 24 h"): bold capitals on a gold band at 45 degrees, cut by the card's
## edge. Add it to the card last (inside a container it fills the card); it
## lets taps through.
static func sash(text: String, points := 72.0) -> Control:
	var corner := Control.new()
	corner.name = "Sash"
	corner.set_anchors_preset(Control.PRESET_FULL_RECT)
	corner.clip_contents = true
	corner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var band := PanelContainer.new()
	band.add_theme_stylebox_override("panel", UI.clear_box(0, 2))
	UI.dress(band, "plate_gold", 0)
	band.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var l := UI.label(text, 13)
	l.uppercase = true
	l.theme_type_variation = "Kicker"
	l.set_meta("bold", true)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	band.add_child(l)
	corner.add_child(band)
	# Long enough to cross the corner at 45 degrees, centred on its diagonal,
	# wherever the card's right edge lands.
	var place := func() -> void:
		# The corner the band crosses is as large as its words need: across
		# it the band shows 0.85 of `side`.
		var side := maxf(UI.px(points), (l.get_combined_minimum_size().x + UI.px(16)) / 0.85)
		band.size = Vector2(side * 1.5, band.get_combined_minimum_size().y)
		band.pivot_offset = band.size * 0.5
		band.rotation = PI * 0.25
		band.position = Vector2(corner.size.x - side * 0.3, side * 0.3) - band.size * 0.5
	corner.resized.connect(place)
	band.minimum_size_changed.connect(place)
	return corner

