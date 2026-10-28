class_name OverlayLanding
extends VBoxContainer
## §5.4's landing picker as the design draws it (Screens v3's "Choose a
## landing"): a header over the world with the picker's title and how to
## choose; at the bottom the spot on show by its name in large gold words with
## a pill saying covered or open, its sentence on glass, a card of its noise,
## clock and count turned by round keys either side, and the gold Land key
## with the heist clock under it. The heist screen fills the lines it reads by
## name (`spot_line`, `count_line`, `clock_line`, `realm_line`,
## `across_line`); `show_pick` dresses the rest from the controller.

var controller: HeistController
## Over the world at the top: the title and the hint, shown while choosing.
var header: VBoxContainer
var spot_line: Label
var count_line: Label
var clock_line: Label
var realm_line: Label
var across_line: Label
var next_realm: Button
## The deck of islands to land on.
var deck: OverlayLandingDeck
var _name: Label
var _kicker: Label
var _pill_holder: HBoxContainer


func _init(c: HeistController) -> void:
	controller = c
	name = "Landing"
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_theme_constant_override("separation", UI.px(8))
	_build_header()
	# At §20.8's large text the spot's words and card scroll above the Land
	# key, so the picker never takes more of the phone than it has.
	var middle: Container = self
	if Settings.text_scale >= 150:
		var scroll := ScrollContainer.new()
		scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
		scroll.custom_minimum_size.y = UI.px(300)
		middle = VBoxContainer.new()
		middle.add_theme_constant_override("separation", UI.px(8))
		middle.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		scroll.add_child(middle)
		add_child(scroll)
		(header.get_child(1) as Control).visible = false
	_build_hero(middle)
	_build_words(middle)
	_build_deck(middle)
	add_child(_land_key())
	visibility_changed.connect(func() -> void: header.visible = visible)


func _build_header() -> void:
	header = VBoxContainer.new()
	header.mouse_filter = Control.MOUSE_FILTER_IGNORE
	header.add_theme_constant_override("separation", 0)
	var title := UI.label(Strings.t("LANDING_TITLE"), 26.0, true)
	title.add_theme_font_override("font", Tokens.font("display"))
	title.set_meta("bold", true)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	ink(title)
	header.add_child(title)
	var hint := UI.label(Strings.t("LANDING_HINT"), 14.0, true)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	ink(hint)
	header.add_child(hint)


## The spot's name large, where it is under it, its pill at the end.
func _build_hero(into: Container) -> void:
	var hero := HBoxContainer.new()
	hero.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hero.add_theme_constant_override("separation", UI.px(10))
	var medal := OverlayHud.medallion("planningactions/landing", -1, 50.0)
	medal.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	hero.add_child(medal)
	var names := VBoxContainer.new()
	names.add_theme_constant_override("separation", 0)
	names.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	names.alignment = BoxContainer.ALIGNMENT_CENTER
	_name = UI.label("", 28.0, true)
	_name.add_theme_font_override("font", Tokens.font("display"))
	_name.set_meta("bold", true)
	_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	_name.add_theme_color_override("font_color", Tokens.color("gold"))
	ink(_name)
	names.add_child(_name)
	_kicker = UI.label("", 13.0, true)
	_kicker.theme_type_variation = "Kicker"
	_kicker.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	ink(_kicker)
	names.add_child(_kicker)
	hero.add_child(names)
	_pill_holder = HBoxContainer.new()
	_pill_holder.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	hero.add_child(_pill_holder)
	into.add_child(hero)


## The spot's sentence and, across a universe, its realm and the choices.
func _build_words(into: Container) -> void:
	var glass := UI.panel("glass")
	var words := VBoxContainer.new()
	words.add_theme_constant_override("separation", UI.px(2))
	for i: int in 4:
		var l := UI.label("", 14.0, true)
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		words.add_child(l)
	realm_line = words.get_child(0) as Label
	across_line = words.get_child(1) as Label
	spot_line = words.get_child(2) as Label
	count_line = words.get_child(3) as Label
	count_line.theme_type_variation = "Secondary"
	glass.add_child(words)
	into.add_child(glass)


## The keys that turn to the spot before and after either side of the
## words, then the deck: a card for each island (`OverlayLandingDeck`); the
## next realm's key under it, across a universe.
func _build_deck(into: Container) -> void:
	var glass := into.get_child(into.get_child_count() - 1) as Control
	var turns := HBoxContainer.new()
	turns.mouse_filter = Control.MOUSE_FILTER_IGNORE
	turns.add_theme_constant_override("separation", UI.px(8))
	into.remove_child(glass)
	glass.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	turns.add_child(_turn(-1))
	turns.add_child(glass)
	turns.add_child(_turn(1))
	into.add_child(turns)
	deck = OverlayLandingDeck.new(controller)
	# On the design's dark sheet.
	var sheet := UI.panel("sheet")
	sheet.mouse_filter = Control.MOUSE_FILTER_IGNORE
	sheet.add_child(deck)
	deck.visibility_changed.connect(func() -> void: sheet.visible = deck.visible)
	into.add_child(sheet)
	next_realm = UI.action(Strings.t("LANDING_NEXT_REALM"), controller.next_realm, "leather")
	next_realm.icon = Icons.texture("realms/theheart")
	next_realm.add_theme_constant_override("icon_max_width", UI.px(20))
	next_realm.size_flags_horizontal = Control.SIZE_SHRINK_END
	# In the deck's heading; at large text on a row of its own under it.
	if Settings.text_scale >= 150:
		next_realm.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		into.add_child(next_realm)
	else:
		deck.head.add_child(next_realm)
	# Across a universe the next realm's key takes the hint's room.
	next_realm.visibility_changed.connect(func() -> void: deck.hint.visible = not next_realm.visible)


func _turn(step: int) -> Button:
	var b := UI.action("", controller.next_spot.bind(step), "leather",
		Strings.t("LANDING_NEXT" if step > 0 else "LANDING_PREV"))
	b.custom_minimum_size = Vector2.ONE * UI.px(48)
	UI.dress(b, "leather", 24.0)
	var middle := CenterContainer.new()
	middle.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	middle.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var mark := Icons.view("generalui/back", 24.0)
	mark.flip_h = step > 0
	middle.add_child(mark)
	b.add_child(middle)
	b.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	b.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	b.tooltip_text = b.accessibility_name
	return b


## The gold Land key, as the design's: its mark and words at the left, the
## heist clock on a dark chip at its right.
func _land_key() -> Button:
	var land := UI.action(Strings.t("LANDING_HERE"), controller.land_here, "gold")
	land.icon = Icons.texture("planningactions/landing")
	land.add_theme_constant_override("icon_max_width", UI.px(34))
	land.add_theme_font_override("font", Tokens.font("display"))
	land.add_theme_font_size_override("font_size", UI.text_px(22))
	land.set_meta("points", 22.0)
	land.set_meta("bold", true)
	land.alignment = HORIZONTAL_ALIGNMENT_LEFT
	land.custom_minimum_size.y = UI.px(68)
	var chip := UI.panel("plate_dark")
	chip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	chip.anchor_left = 1.0
	chip.anchor_right = 1.0
	chip.anchor_top = 0.5
	chip.anchor_bottom = 0.5
	chip.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	chip.grow_vertical = Control.GROW_DIRECTION_BOTH
	chip.offset_right = -UI.px(10)
	clock_line = UI.label("", 14.0)
	clock_line.set_meta("bold", true)
	clock_line.add_theme_font_override("font", UI.bold_font())
	chip.add_child(clock_line)
	# At large text the chip would cover the key's words: it stands over
	# the key instead.
	if Settings.text_scale >= 150:
		chip.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
		chip.size_flags_horizontal = Control.SIZE_SHRINK_END
		add_child(chip)
	else:
		land.add_child(chip)
	return land


## The spot on show, from the controller's marks: its name, its place among
## the spots, covered or open, and its noise and clock on the card.
func show_pick() -> void:
	var marks: Array = controller.marks
	if marks.is_empty():
		return
	var at := clampi(controller.pick, 0, marks.size() - 1)
	var m: Dictionary = marks[at]
	var fault: bool = m.get("fault", false)
	var side: int = int(m["side"]) if m.has("side") else controller.world.size().x
	var covered: bool = m.get("covered", false)
	var edge := Strings.t("LANDING_FAULT_NAME")
	if not fault:
		var p := LandingPresenter.place(Vector2i(m["at"]), side)
		edge = Strings.t("LANDING_EDGE_NAME", Strings.t("LANDING_" + str(p[0])))
	_name.text = edge
	_kicker.text = Strings.t("LANDING_SPOT_OF", [at + 1, marks.size()]).to_upper()
	# Across a universe the realm is the name, as the design's ("Lantern
	# Vale"), and the edge and spot its kicker.
	if m.has("code"):
		var realm := LandingPresenter.realm_name(int(m["code"]))
		_name.text = realm.left(1).to_upper() + realm.substr(1)
		_kicker.text = ("%s · %s" % [edge, _kicker.text]).to_upper()
	for c: Node in _pill_holder.get_children():
		c.queue_free()
	_pill_holder.add_child(OverlayHud.badge(Strings.t("LANDING_PILL_COVERED" if covered else "LANDING_PILL_OPEN")
		.to_upper(), "green_muted" if covered else "red", 15.0))
	# The deck says each island's realm, links and spots: the glass keeps
	# the realm and the spot on show.
	across_line.visible = false
	count_line.visible = false
	# Across a universe the deck says how to choose: the hint gives it the
	# room.
	(header.get_child(1) as Control).visible = controller.universe.is_empty() and Settings.text_scale < 150
	deck.show_pick()


## Words straight over the world, inked so they read over any island.
static func ink(l: Label) -> void:
	l.add_theme_color_override("font_outline_color", Tokens.color("ink_deep"))
	l.add_theme_constant_override("outline_size", UI.px(3))
