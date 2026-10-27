class_name OverlayLandingDeck
extends VBoxContainer
## The landing picker's deck (the design's "Landings"): a card for each
## island the crew can land on — across a universe each outer realm with a
## route to the Heart and each open fault, on one island that island — in a
## row that scrolls sideways. A card shows its island from above, its name,
## whether it has a covered spot (no guard hears the skiff) or only open
## ones, its noise, its clock and its hops to the Vault; the card on show is
## gold with a tick. A tap on a card puts its first spot on show, a covered
## one where it has one. Every fact is the controller's marks (§5.4, §23.2:
## "each spot marked covered or open from the terrain alone … the heist
## clock and depth for each choice").

const CARD_POINTS := 156.0
const PICTURE_POINTS := 84.0

var controller: HeistController
var thumbs: StageIslandThumbs
## Each card's key ("place:fault"), in the deck's order.
var keys: Array[String] = []
## The deck's heading row: its name, how to use it, and where in it the
## card on show is.
var head: HBoxContainer
## How to use the deck, in its heading.
var hint: Label
var _row: HBoxContainer
var _count: Label
var _scroll: ScrollContainer
var _drawn := ""


func _init(c: HeistController) -> void:
	controller = c
	name = "Deck"
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_theme_constant_override("separation", UI.px(6))
	head = HBoxContainer.new()
	head.name = "Head"
	head.mouse_filter = Control.MOUSE_FILTER_IGNORE
	head.add_theme_constant_override("separation", UI.px(10))
	var kicker := UI.label(Strings.t("LANDING_DECK"), 13.0)
	kicker.uppercase = true
	kicker.theme_type_variation = "Kicker"
	kicker.set_meta("bold", true)
	head.add_child(kicker)
	hint = UI.label(Strings.t("LANDING_DECK_HINT"), 13.0, true)
	hint.theme_type_variation = "Secondary"
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	hint.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(hint)
	_count = UI.label("", 13.0)
	_count.set_meta("bold", true)
	_count.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_count.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	head.add_child(_count)
	add_child(head)
	_scroll = ScrollContainer.new()
	_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_SHOW_NEVER
	_row = HBoxContainer.new()
	_row.add_theme_constant_override("separation", UI.px(10))
	_scroll.add_child(_row)
	add_child(_scroll)
	thumbs = StageIslandThumbs.new()
	add_child(thumbs)
	# A picture drawn: the deck again, with it.
	thumbs.drawn.connect(func(_key: String, _texture: Texture2D) -> void:
		_drawn = ""
		show_pick())


## The deck's cards: one a realm (and one a fault), in the marks' order.
static func choices(marks: Array) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	var seen := {}
	for i: int in marks.size():
		var m: Dictionary = marks[i]
		var key := "%s:%s" % [m.get("place", 0), m.get("fault", false)]
		if not seen.has(key):
			seen[key] = out.size()
			out.append({"key": key, "first": i, "spots": 0, "covered": 0, "mark": m})
		var c: Dictionary = out[seen[key]]
		c["spots"] = int(c["spots"]) + 1
		if m.get("covered", false):
			if int(c["covered"]) == 0:
				c["first"] = i
			c["covered"] = int(c["covered"]) + 1
	return out


## The deck drawn again when the choices or the one on show change.
func show_pick() -> void:
	var marks: Array = controller.marks
	if marks.is_empty():
		visible = false
		return
	visible = true
	var now: Dictionary = marks[clampi(controller.pick, 0, marks.size() - 1)]
	var on := "%s:%s" % [now.get("place", 0), now.get("fault", false)]
	var cards := choices(marks)
	var key := "%s|%d" % [on, marks.size()]
	if key == _drawn:
		return
	_drawn = key
	keys.clear()
	for child: Node in _row.get_children():
		_row.remove_child(child)
		child.queue_free()
	var at := 0
	for i: int in cards.size():
		var c: Dictionary = cards[i]
		keys.append(c["key"])
		if c["key"] == on:
			at = i
		_row.add_child(_card(c, c["key"] == on))
	_count.text = "%d / %d" % [at + 1, cards.size()]


## One island's card: its picture with its name and pill over it, then its
## noise, clock and hops on tiles, the chosen one gold with a tick.
func _card(c: Dictionary, chosen: bool) -> Control:
	var m: Dictionary = c["mark"]
	var fault: bool = m.get("fault", false)
	var covered := int(c["covered"]) > 0
	var card := UI.panel("parchment")
	card.custom_minimum_size.x = UI.px(CARD_POINTS)
	card.set_meta("chosen", chosen)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", UI.px(6))
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_child(_picture(c, chosen))
	var tiles := HBoxContainer.new()
	tiles.add_theme_constant_override("separation", UI.px(4))
	tiles.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var seconds := int(m.get("ticks", controller.world.ticks())) / RulebornReplay.ticks_per_second()
	tiles.add_child(_tile("heiststatus/heard", Strings.t("LANDING_SILENT") if covered
		else Strings.t("LANDING_HEARD_TILES", controller.world.landing_reach()), Strings.t("LANDING_TILE_NOISE"),
		covered))
	tiles.add_child(_tile("heiststatus/clock", "%ds" % seconds, Strings.t("LANDING_TILE_CLOCK"), false))
	v.add_child(tiles)
	var hops := int(m.get("links", 0))
	var words := Strings.t("LANDING_DECK_SPOTS", [int(c["spots"]), int(c["covered"])])
	if fault:
		words = Strings.t("LANDING_DECK_FAULT")
	elif hops == 1:
		words = Strings.t("LANDING_DECK_HOP", int(c["spots"]))
	elif hops > 1:
		words = Strings.t("LANDING_DECK_HOPS", [hops, int(c["spots"])])
	var foot := UI.label(words, 13.0, true)
	foot.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	foot.add_theme_color_override("font_color", Tokens.color("parchment_text_2"))
	v.add_child(foot)
	card.add_child(v)
	# The whole card is the key, named for a screen reader.
	var b := Button.new()
	b.flat = true
	b.custom_minimum_size = Vector2.ONE * UI.px(48)
	b.accessibility_name = "%s: %s" % [_name(m), foot.text]
	b.set_meta("choice", c["key"])
	var first: int = c["first"]
	b.pressed.connect(func() -> void:
		# Its choice on show, as the turn keys put one there.
		controller.pick = first
		controller.next_spot(0))
	card.add_child(b)
	if not chosen:
		return card
	# The card on show in the design's gold frame.
	var frame := UI.panel("frame_gold")
	frame.add_theme_stylebox_override("panel", UI.clear_box(4, 4))
	frame.set_meta("chosen", true)
	frame.add_child(card)
	return frame


## A card's name, as a title: its realm, its fault or this island.
func _name(m: Dictionary) -> String:
	var name := Strings.t("LANDING_DECK_ISLAND")
	if m.get("fault", false):
		name = Strings.t("LANDING_FAULT_NAME")
	elif m.has("code"):
		name = LandingPresenter.realm_name(int(m["code"]))
	return name.left(1).to_upper() + name.substr(1)


## The card's picture: the island from above (drawn once, offscreen), its
## name and the covered or open pill over it, and the tick when chosen.
func _picture(c: Dictionary, chosen: bool) -> Control:
	var m: Dictionary = c["mark"]
	var frame := UI.panel("plate_dark")
	frame.custom_minimum_size.y = UI.px(PICTURE_POINTS)
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	frame.clip_contents = true
	var island := _island_of(m)
	if not island.is_empty() and not m.get("fault", false):
		var shot := thumbs.picture({"bundle": "landing:%s" % c["key"], "island": island})
		if shot != null:
			var pic := TextureRect.new()
			pic.texture = shot
			pic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			pic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
			pic.mouse_filter = Control.MOUSE_FILTER_IGNORE
			frame.add_child(pic)
	var over := VBoxContainer.new()
	over.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var top := HBoxContainer.new()
	top.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if chosen:
		var tick := Icons.view("generalui/confirm", 22.0)
		top.add_child(tick)
	var gap := Control.new()
	gap.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	gap.mouse_filter = Control.MOUSE_FILTER_IGNORE
	top.add_child(gap)
	var covered := int(c["covered"]) > 0
	top.add_child(OverlayHud.badge(Strings.t("LANDING_PILL_COVERED" if covered else "LANDING_PILL_OPEN").to_upper(),
		"green" if covered else "gold_round", 13.0))
	over.add_child(top)
	var fill := Control.new()
	fill.size_flags_vertical = Control.SIZE_EXPAND_FILL
	fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	over.add_child(fill)
	var name := UI.label(_name(m), 16.0, true)
	name.add_theme_font_override("font", Tokens.font("display"))
	name.set_meta("bold", true)
	name.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	OverlayLanding.ink(name)
	over.add_child(name)
	frame.add_child(over)
	return frame


func _island_of(m: Dictionary) -> PackedByteArray:
	if m.has("place"):
		var place := int(m["place"])
		if place >= 0 and place < controller.realm_islands.size():
			return controller.realm_islands[place]
		return PackedByteArray()
	return controller.island


## A tile: its mark, its value large, its name small.
func _tile(icon: String, value: String, label: String, good: bool) -> Control:
	var tile := UI.panel("fact")
	tile.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tile.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 0)
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var mark := Icons.view(icon, 18.0)
	mark.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	box.add_child(mark)
	var v := UI.label(value, 17.0)
	v.add_theme_font_override("font", Tokens.font("display"))
	v.add_theme_color_override("font_color", Tokens.color("success_text" if good else "parchment_ink"))
	v.set_meta("bold", true)
	box.add_child(v)
	var n := UI.label(label.to_upper(), 13.0)
	n.add_theme_color_override("font_color", Tokens.color("parchment_text_2"))
	box.add_child(n)
	tile.add_child(box)
	return tile
