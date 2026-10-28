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
	# A card three to a row (under 130 points) sets its name smaller and its
	# school's mark over its rank's word, so neither widens it past its row.
	var compact := points < 130.0
	var name_plate := UI.plate(_name(title, _fit(title, points - 22.0) if compact else 18.0), "parchment")
	if compact:
		name_plate.add_theme_stylebox_override("panel", UI.clear_box(4, 6))
	v.add_child(name_plate)
	var mark: BoxContainer = HBoxContainer.new()
	if compact:
		mark = VBoxContainer.new()
	mark.alignment = BoxContainer.ALIGNMENT_CENTER
	mark.add_theme_constant_override("separation", UI.px(0 if compact else 4))
	var shape := Icons.view("schools/" + school, 20)
	shape.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	mark.add_child(shape)
	# The school by its mark's shape, the rank by its frame and its word.
	var s := UI.label(Strings.t("LAW_RANK_" + rarity.to_upper()), 13)
	s.theme_type_variation = "Kicker"
	s.uppercase = true
	s.set_meta("bold", true)
	mark.add_child(s)
	v.add_child(mark)
	card.add_child(v)
	return card


## A law in a Codex album (13-law-codex.png): its rank's frame round its
## school's window (number on a disc, tier in the corner, as `law_card`),
## then a cream foot with its name, its rank in words, and where it lives on
## a leather plate ("In Skyfield"); "" leaves the plate off.
static func album_card(icon: String, title: String, school: String, rarity: String, where := "", number := "",
		tier := "", points := 96.0) -> PanelContainer:
	var card := law_card(icon, title, school, rarity, tier, points, number)
	card.name = "AlbumCard"
	var v := card.get_child(0) as VBoxContainer
	# The foot replaces law_card's name plate and mark.
	for i: int in [2, 1]:
		var old := v.get_child(i)
		v.remove_child(old)
		old.queue_free()
	var foot := PanelContainer.new()
	foot.name = "Foot"
	foot.add_theme_stylebox_override("panel", UI.clear_box(3, 4))
	UI.dress(foot, "parchment", 10)
	foot.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var words := VBoxContainer.new()
	words.add_theme_constant_override("separation", UI.px(2))
	words.alignment = BoxContainer.ALIGNMENT_CENTER
	words.add_child(_name(title, _fit(title, points - 18.0)))
	var rank := UI.label(Strings.t("LAW_RANK_" + rarity.to_upper()), 13)
	rank.theme_type_variation = "Kicker"
	rank.uppercase = true
	rank.set_meta("bold", true)
	words.add_child(rank)
	if where != "":
		var at := KitStatus.plate(where)
		UI.dress(at, "plate_leather")
		at.size_flags_horizontal = Control.SIZE_FILL
		# A long place wraps inside the card rather than widening it.
		at.add_theme_stylebox_override("panel", UI.clear_box(3, 1))
		var l := at.get_child(0) as Label
		l.autowrap_mode = TextServer.AUTOWRAP_WORD
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		words.add_child(at)
	foot.add_child(words)
	v.add_child(foot)
	return card


## Something for sale (18-shop.png's daily picks): a gold-edged card, its
## picture filling the top with a dark ribbon tag in its corner ("EMOTE"),
## its name, and its price on a pill that buys it: violet for a price in
## gems (`look` "round_violet"), gold for money ("gold").
static func product(picture: Texture2D, tag: String, title: String, price: String, pressed: Callable,
		look := "round_violet", points := 128.0) -> PanelContainer:
	var card := PanelContainer.new()
	card.name = "Product"
	card.add_theme_stylebox_override("panel", UI.clear_box(7, 6))
	UI.dress(card, "card_gold")
	card.custom_minimum_size.x = UI.px(points)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", UI.px(6))
	var stage := PanelContainer.new()
	stage.name = "Picture"
	stage.add_theme_stylebox_override("panel", UI.clear_box(0, 0))
	UI.dress(stage, "well", 12)
	stage.custom_minimum_size.y = UI.px(points * 0.9)
	stage.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var art := TextureRect.new()
	art.texture = picture
	art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stage.add_child(art)
	if tag != "":
		var corner := Control.new()
		corner.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var ribbon := KitStatus.plate(tag)
		UI.dress(ribbon, "tag_dark")
		var words := ribbon.get_child(0) as Label
		words.theme_type_variation = "Kicker"
		words.uppercase = true
		ribbon.position = Vector2(UI.px(4), UI.px(4))
		corner.add_child(ribbon)
		stage.add_child(corner)
	v.add_child(stage)
	var name_label := UI.label(title, 15, true)
	name_label.theme_type_variation = "BodyBold"
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	name_label.set_meta("bold", true)
	v.add_child(name_label)
	var buy := UI.action(price, pressed, look, "%s, %s" % [title, price])
	buy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	v.add_child(buy)
	card.add_child(v)
	return card


## The largest size from 15 points down to §21.8's 13 at which the name's
## longest word fits `room` points, so it wraps between words, not in one.
static func _fit(title: String, room: float) -> float:
	var face := RbTheme.role_font("heading")
	var longest := ""
	for word: String in title.split(" "):
		if word.length() > longest.length():
			longest = word
	for size: float in [15.0, 14.0]:
		if face.get_string_size(longest, HORIZONTAL_ALIGNMENT_LEFT, -1, UI.text_px(size)).x <= UI.px(room):
			return size
	return 13.0


static func _name(title: String, points: float) -> Label:
	var l := UI.label(title, points, true)
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
	b.custom_minimum_size = Vector2(UI.px(100), UI.px(140))
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


## A reward tile on the result (07-heist-result.png): parchment edged in the
## reward's colour ("gold", "green", "pink", "sky"), its icon, the amount in
## Manrope 800 with tabular figures (as the design's, not the display face)
## and what it is in words.
static func reward(icon: String, amount: String, words: String, tone := "gold") -> PanelContainer:
	var p := UI.panel("reward_" + tone)
	p.name = "Reward"
	p.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 0)
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	v.add_child(Icons.view(icon, 34))
	var n := UI.label(amount, 24)
	n.theme_type_variation = "DisplayS"
	n.add_theme_font_override("font", Tokens.font("ui", 800, true))
	n.add_theme_font_size_override("font_size", UI.text_px(24))
	n.set_meta("points", 24.0)
	v.add_child(n)
	var w := UI.label(words, 13, true)
	w.theme_type_variation = "Secondary"
	w.set_meta("bold", true)
	w.add_theme_font_override("font", UI.bold_font())
	v.add_child(w)
	p.add_child(v)
	return p


## A law's chip (the heist's "Laws here"): its icon and name on a leather
## pill, so a law is always named, never only drawn (§20.8).
static func law_chip(icon: String, title: String) -> PanelContainer:
	var p := KitStatus.pill(title, icon, "leather")
	p.name = "Law"
	return p


## A fact tile (the Character screen's Carrier, Resists, Traits, At home):
## its icon on a disc, a kicker in capitals and a bold line. With a `tone`
## (a school's name) the disc is lit from white to that school's light and
## the kicker is in its deep shade, as the design tells the four facts apart;
## the kicker's words say which fact it is, so the tone is never alone.
static func fact(icon: String, kicker: String, words: String, tone := "") -> PanelContainer:
	var p := UI.panel("fact")
	p.name = "Fact"
	p.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", UI.px(8))
	var disc := PanelContainer.new()
	disc.add_theme_stylebox_override("panel", UI.clear_box(6, 6))
	var lit := UI.dress(disc, "icon_disc")
	if tone != "":
		lit.tint(Color.WHITE, Tokens.color(tone + "_light"))
	disc.add_child(Icons.view(icon, 24))
	disc.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(disc)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 0)
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var k := UI.label(kicker, 13, true)
	k.theme_type_variation = "Kicker"
	k.uppercase = true
	k.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	k.add_theme_color_override("font_color", tone_ink(tone) if tone != "" else Tokens.color("parchment_text_2"))
	k.set_meta("bold", true)
	v.add_child(k)
	var w := UI.label(words, 14, true)
	w.theme_type_variation = "BodyBold"
	w.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	w.set_meta("bold", true)
	v.add_child(w)
	row.add_child(v)
	p.add_child(row)
	return p


## A season reward (17-season.png): its rank on a band across the top, its
## icon, its amount on a plate, and CLAIM when it can be taken; a locked one
## is hatched with its lock and says so in its spoken name.
static func season_reward(rank: String, icon: String, amount: String, claim: Callable, locked := false,
		claim_words := "") -> PanelContainer:
	var p := UI.panel("locked" if locked else "parchment")
	p.name = "SeasonReward"
	p.add_theme_stylebox_override("panel", UI.clear_box(0, 0))
	p.custom_minimum_size = Vector2(UI.px(96), UI.px(124))
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", UI.px(4))
	var band := PanelContainer.new()
	band.add_theme_stylebox_override("panel", UI.clear_box(4, 1))
	if not locked:
		UI.dress(band, "tier_band", 10)
	var r := UI.label(rank, 13)
	r.theme_type_variation = "Kicker"
	r.uppercase = true
	r.set_meta("bold", true)
	band.add_child(r)
	v.add_child(band)
	# A locked reward still shows what it is, dimmed under the hatching,
	# with a small lock in its corner (the design's), not a lock alone.
	var art := Icons.view(icon if icon != "" else "generalui/lock", 36 if icon != "" else 28)
	if locked:
		art.self_modulate = Color(0.62, 0.62, 0.7)
	# At its own size in the room left, never swelling to fill it.
	var room := CenterContainer.new()
	room.size_flags_vertical = Control.SIZE_EXPAND_FILL
	room.mouse_filter = Control.MOUSE_FILTER_IGNORE
	room.add_child(art)
	v.add_child(room)
	if amount != "":
		var plate := KitStatus.plate(amount)
		UI.dress(plate, "plate_dark")
		plate.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		v.add_child(plate)
	if claim.is_valid() and not locked:
		var b := UI.action(claim_words, claim, "green")
		b.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		v.add_child(b)
	var m := MarginContainer.new()
	m.add_theme_constant_override("margin_bottom", UI.px(6))
	m.add_child(v)
	p.add_child(m)
	if locked and icon != "":
		var badge := PanelContainer.new()
		badge.name = "Lock"
		badge.add_theme_stylebox_override("panel", UI.clear_box(3, 3))
		UI.dress(badge, "icon_disc", 999)
		badge.add_child(Icons.view("generalui/lock", 16))
		badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var corner := Control.new()
		corner.mouse_filter = Control.MOUSE_FILTER_IGNORE
		corner.add_child(badge)
		badge.position = Vector2(UI.px(66), UI.px(24))
		p.add_child(corner)
	return p


## A school's deep shade, darkened only as far as bold 13-point words need
## to read on parchment's darker stop (§21.8: 4.5:1 and APCA Lc 60).
static func tone_ink(school: String) -> Color:
	var ink := Tokens.color(school + "_shadow")
	var under := Tokens.color("parchment_bottom")
	for i: int in 20:
		if ColourCheck.readable(ink, under, 13.0, true):
			break
		ink = ink.darkened(0.08)
	return ink


## A character's ability (11-character.png): a plum card, the ability's
## icon on a square in its school's colours, a gold kicker ("Ability") with
## its tag ("Once a heist"), the name in Marcellus and the rule beneath it.
static func ability(icon: String, school: String, kicker: String, tag: String, title: String,
		rule: String) -> PanelContainer:
	var p := UI.panel("ability")
	p.name = "Ability"
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", UI.px(12))
	var square := PanelContainer.new()
	square.add_theme_stylebox_override("panel", UI.clear_box(10, 10))
	UI.dress(square, "window_" + school, 16)
	square.add_child(Icons.view(icon, 40))
	square.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(square)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", UI.px(2))
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var head := KitLayout.flow(6)
	var k := UI.label(kicker, 13)
	k.theme_type_variation = "Kicker"
	k.uppercase = true
	k.add_theme_color_override("font_color", Tokens.color("gold"))
	k.set_meta("bold", true)
	head.add_child(k)
	if tag != "":
		head.add_child(KitStatus.tag(tag, true))
	v.add_child(head)
	var t := UI.label(title, 20, true)
	t.theme_type_variation = "Heading"
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	v.add_child(t)
	var r := UI.label(rule, 14, true)
	r.theme_type_variation = "Secondary"
	r.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	v.add_child(r)
	row.add_child(v)
	p.add_child(row)
	return p
