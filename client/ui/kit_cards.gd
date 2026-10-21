class_name KitCards
## Cards that carry a law or a school: the law card in its rarity's frame
## (oak, silver, gold, prismatic) with an art window in its school's colours,
## its name in Marcellus on a parchment plate (§21.8: "a law's title on a
## light school colour sits on a plate"), its school's mark and name, and
## its rank; and the school chip, a school's mark beside its name, so a
## school never rests on colour (§20.8, §21.2).

const RARITY := {"common": "frame_oak", "uncommon": "frame_silver", "rare": "frame_gold", "deep": "frame_prismatic"}


## A school's mark and name on a glass pill.
static func school_chip(school: String) -> PanelContainer:
	var p := KitStatus.pill(Strings.t("SCHOOL_" + school.to_upper()), "schools/" + school)
	p.name = "School"
	return p


## A law card `points` wide: frame by rank ("common", "uncommon", "rare",
## "deep") with the rank also in words under its name beside the school's
## mark, and a tier ("III") on the window's corner plate if given; the law's icon in its school's window, its
## name and school, and a number on a disc in the window's corner if given
## (its stability cost, as the Codex shows).
static func law_card(icon: String, title: String, school: String, rarity: String, tier := "",
		points := 150.0, number := "") -> PanelContainer:
	var card := PanelContainer.new()
	card.name = "LawCard"
	card.add_theme_stylebox_override("panel", UI.clear_box(7, 7))
	UI.dress(card, str(RARITY.get(rarity, "frame_oak")))
	card.custom_minimum_size.x = UI.px(points)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", UI.px(6))
	var window := PanelContainer.new()
	window.name = "Window"
	window.add_theme_stylebox_override("panel", UI.clear_box(6, 6))
	UI.dress(window, "window_" + school)
	window.custom_minimum_size.y = UI.px(points * 0.62)
	# A plain stage inside the window, so the rank sits in its corner rather
	# than being laid out by the window.
	var stage := Control.new()
	stage.mouse_filter = Control.MOUSE_FILTER_IGNORE
	window.add_child(stage)
	var art := Icons.view(icon, points * 0.5)
	art.set_anchors_preset(Control.PRESET_FULL_RECT)
	stage.add_child(art)
	if tier != "":
		var tag := KitStatus.plate(tier)
		tag.set_anchors_preset(Control.PRESET_TOP_RIGHT)
		tag.grow_horizontal = Control.GROW_DIRECTION_BEGIN
		stage.add_child(tag)
	if number != "":
		var disc := PanelContainer.new()
		disc.add_theme_stylebox_override("panel", UI.clear_box(4, 0))
		UI.dress(disc, "disc")
		disc.custom_minimum_size = Vector2.ONE * UI.px(26)
		var n := UI.label(number, 13)
		n.theme_type_variation = "Number"
		n.set_meta("bold", true)
		n.add_theme_color_override("font_outline_color", Tokens.color("ink_line"))
		n.add_theme_constant_override("outline_size", UI.px(2))
		disc.add_child(n)
		stage.add_child(disc)
	v.add_child(window)
	var name_plate := UI.plate(_name(title), "parchment")
	v.add_child(name_plate)
	var mark := HBoxContainer.new()
	mark.alignment = BoxContainer.ALIGNMENT_CENTER
	mark.add_theme_constant_override("separation", UI.px(4))
	mark.add_child(Icons.view("schools/" + school, 20))
	# The school by its mark's shape, the rank by its frame and its word.
	var s := UI.label(Strings.t("LAW_RANK_" + rarity.to_upper()), 13)
	s.theme_type_variation = "Kicker"
	s.uppercase = true
	s.set_meta("bold", true)
	mark.add_child(s)
	v.add_child(mark)
	card.add_child(v)
	return card


static func _name(title: String) -> Label:
	var l := UI.label(title, 18, true)
	l.theme_type_variation = "Heading"
	return l


## A character's card on the Roster: the portrait filling a card in its
## school's colour, its level on a disc at the top left, a dot for its state
## at the top right (the state is in its spoken name and the screen's words
## too), its role on a disc at the bottom left, its name on a dark plate,
## and a gold edge when chosen. `pressed` makes it one button.
static func portrait(picture: Texture2D, name: String, level: int, school: String, state: Color, role_icon: String,
		pressed: Callable, chosen := false, spoken := "") -> Button:
	var b := UI.action("", pressed, "portrait_" + school, spoken if spoken != "" else name)
	b.name = "Portrait"
	b.custom_minimum_size = Vector2(UI.px(100), UI.px(128))
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	RbBox.of(b).set_chosen(chosen)
	var art := TextureRect.new()
	art.texture = picture
	art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	art.set_anchors_preset(Control.PRESET_FULL_RECT)
	art.offset_left = UI.px(2)
	art.offset_right = -UI.px(2)
	art.offset_top = UI.px(2)
	art.offset_bottom = -UI.px(26)
	art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	art.clip_contents = true
	b.add_child(art)
	var plate := PanelContainer.new()
	plate.add_theme_stylebox_override("panel", UI.clear_box(4, 2))
	UI.dress(plate, "name_plate")
	plate.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	plate.offset_top = -UI.px(26)
	plate.offset_left = UI.px(2)
	plate.offset_right = -UI.px(2)
	plate.offset_bottom = -UI.px(2)
	plate.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var n := UI.label(name, 14)
	n.theme_type_variation = "LabelText"
	n.set_meta("bold", true)
	n.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	n.clip_text = true
	plate.add_child(n)
	b.add_child(plate)
	var lv := PanelContainer.new()
	lv.add_theme_stylebox_override("panel", UI.clear_box(4, 0))
	UI.dress(lv, "level_disc")
	lv.custom_minimum_size = Vector2.ONE * UI.px(22)
	lv.position = Vector2(UI.px(5), UI.px(5))
	lv.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var l := UI.label(str(level), 13)
	l.theme_type_variation = "Number"
	l.set_meta("bold", true)
	lv.add_child(l)
	b.add_child(lv)
	var dot := KitRing.new()
	dot.dot = true
	dot.fraction = 1.0
	dot.tint = state
	dot.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	dot.offset_left = -UI.px(18)
	dot.offset_right = -UI.px(6)
	dot.offset_top = UI.px(6)
	dot.offset_bottom = UI.px(18)
	dot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.add_child(dot)
	if role_icon != "":
		var role := Icons.view(role_icon, 24)
		role.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
		role.offset_left = UI.px(5)
		role.offset_right = UI.px(29)
		role.offset_top = -UI.px(54)
		role.offset_bottom = -UI.px(30)
		b.add_child(role)
	return b
