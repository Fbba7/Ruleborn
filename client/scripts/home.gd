class_name Home
extends Control
## Where the app opens, once §20.1's age check has answered (§23.2: "Home.
## See every realm and link at once"): the player's universe in 3D behind
## everything, and over it §21.8's home layout, as the designs arrange it —
## the Keeper's level and Renown at the top left, strain at the top right,
## the resources with their bars in a full-width row beneath, side buttons
## down both edges, and §14.8's nearest goal above five tabs with the Heist
## in the centre. Every other screen is on the menu the Keeper badge opens.

## The screens a player goes to from home's menu, in the order they are listed.
const PLACES := [&"map", &"observatory", &"defences", &"universe", &"weaving", &"codex", &"lab", &"roster", &"hatch",
	&"sages", &"forms", &"builder", &"workshop", &"replay", &"profile", &"share", &"track", &"shop", &"social",
	&"friends", &"settings"]
const WORDS := {&"map": "HOME_MAP", &"observatory": "HOME_OBSERVATORY", &"defences": "HOME_DEFENCES",
	&"universe": "HOME_UNIVERSE", &"weaving": "HOME_WEAVING", &"codex": "HOME_CODEX", &"lab": "HOME_LAB",
	&"roster": "HOME_ROSTER", &"hatch": "HOME_HATCH", &"sages": "HOME_SAGES", &"forms": "HOME_FORMS",
	&"builder": "HOME_BUILD", &"workshop": "HOME_WORKSHOP", &"replay": "HOME_WATCH", &"profile": "HOME_PROFILE",
	&"share": "HOME_SHARE", &"track": "HOME_TRACK", &"shop": "HOME_SHOP", &"social": "HOME_SOCIAL",
	&"friends": "HOME_FRIENDS", &"settings": "HOME_SETTINGS"}
## The side buttons: the left edge's and the right's (the designs' four).
const LEFT := [[&"defences", "realmactions/defence", "HOME_SIDE_DEFENCE"],
	[&"lab", "screens/resonancelab", "HOME_SIDE_LAB"]]
const RIGHT := [[&"track", "screens/season", "HOME_SIDE_SEASON"], [&"shop", "screens/shop", "HOME_SIDE_SHOP"]]
## Where each tab goes; the Islands tab is home itself.
const TAB_ROUTES := {"laws": &"codex", "crew": &"roster", "friends": &"friends"}
## Each strain band's colour in the kit (§5.5's seven bands, in order).
const BAND_KEYS := ["quiet", "steady", "humming", "brimming", "strained", "cracking", "breaking"]
## The goals' icons in the kit's set, by `UniverseGoal.goals`' names.
const GOAL_ICONS := {"levelup": "generalui/levelup", "track": "screens/season"}
## The narrowest the goal card goes beside Collect, in points: its picture and
## three short lines of words.
const GOAL_NARROWEST := 150.0
## The widest it goes, in points: two lines of its words beside Collect.
const GOAL_WIDEST := 230.0
## The goal's words, in points: a point under the kit's goal card, as the key
## frame draws them smaller than Collect's.
const GOAL_POINTS := 13.0
## How much closer the goal's lines stand at large text, in points.
const GOAL_LINE_TIGHTER := 3.0
## The goal card's padding above and below its words at large text, in points
## (the kit's card keeps 8), and the gap between Collect and the goal there (6
## at 100%): the realms' chips keep two rows over the raid notice.
const GOAL_PAD_LARGE := 4.0
const FOOT_GAP_LARGE := 3.0
## Collect's gold either side of its picture and words, in points together.
const COLLECT_PAD := 16.0
## The smallest the other tabs' names go, in points at 100% text, before they
## give way to their icons alone.
const TAB_WORD_LEAST := 11.0
## The least share of its size strain's words take to keep the purse's fourth
## place at large text.
const STRAIN_LEAST := 0.8
## The gap between the purse's pills, in points, and the least it closes to
## (_fit_purse) before the row wraps.
const PURSE_GAP := 6.0
const PURSE_GAP_LEAST := 3.0
## The least share of their size the purse's amounts take at large text to
## keep the purse to two rows (`_fit_amounts`).
const AMOUNT_LEAST := 0.85

## The unseen raids the player dismissed the notice for: it returns only when
## more come.
static var _dismissed := 0

## The Keeper badge at the top left; hidden until the server has answered.
var keeper_plate: UniverseBadge
## Strain at the top right: the kit's glass pill (`KitStatus.strain`), drawn at
## the right of the width the top row gives it; hidden until it is known.
var strain: HBoxContainer
## The resources in a full-width row: the kit's resource pills
## (`KitStatus.resource`), by kind in `UniversePurse.ORDER` in `pills`.
var purse: HFlowContainer
var pills := {}
## The nearest goal (§14.8) on the kit's goal card (`KitHud.goal`), as `goal`
## (`UniverseGoal.goals`) has it, beside Collect or beneath it.
var goal_card: Control
var goal := {}
## The UI kit's five tabs (`KitTabs`), Islands chosen.
var tabs: KitTabs
var menu: UniverseMenu
## The side buttons by route (the kit's round actions); the defence log's
## carries the raid badge (TD.66).
var sides := {}
## The universe behind the interface.
var world: UniverseView
## The raid notice over the foot, from the kit's alarm banner; it stays until
## the player dismisses it.
var notice: PanelContainer
## The design's "COLLECT 3.4k" over the foot, the kit's gold action, while any
## producer holds something (§9.3); the goal stands beside it or beneath it.
var collect_button: Button

var _top: Control
## The two edges of side buttons.
var _edges: Array[Control] = []
## At large text, the side buttons gave way because a realm's pin found no
## room beside them; until the foot's room changes (the raid notice comes or
## goes).
var _edges_yield := false
var _foot: HFlowContainer
## Each side button's badge as last drawn, so a button is rebuilt only when
## its badge changes.
var _badges := {}
var _tab_badges := {}
## The realm the world is closed in on: one more tap there opens it.
var _close := ""
## Strain as last shown: its share and band in words, on one line and on two.
var _strain_lines := PackedStringArray()
## The strain pill now shown (KitStatus.strain), inside its tap area.
var _strain_pill: PanelContainer
var _strain_room := 0.0
var _full := {}
var _raids: HomeParts.Raids
## Where rewards fly: a full-screen layer, so the kit stacks it over the
## column's words (kit-spec.md section 5).
var _flights: Control


func _ready() -> void:
	App.ready(self)
	Settings.restore()
	# TD.26: the first launch's beats come first, the age check among them
	# (§20.1); nothing else until they are done.
	if not App.services.first.done():
		App.services.router.go.call_deferred(&"first")
		return
	if not App.services.age.allows_account():
		App.services.router.go.call_deferred(&"age")
		return
	var column := UI.frame(self)
	# Closer at large text (§20.8), where the world's room between the purse
	# and the foot is what the realms' chips stand in.
	column.add_theme_constant_override("separation", UI.px(4 if Settings.text_scale >= 150 else 6))
	world = UniverseView.behind(self, column)
	world.next_chosen.connect(func() -> void: App.services.router.go(&"universe"))
	world.realm_chosen.connect(_on_realm)
	# The game's name and what it is, said aloud; the world shows the rest.
	accessibility_name = Strings.t("APP_NAME")
	accessibility_description = Strings.t("HOME_TAGLINE")
	_build_top(column)
	var middle := HBoxContainer.new()
	middle.size_flags_vertical = Control.SIZE_EXPAND_FILL
	middle.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_edges = [_edge(LEFT), _edge(RIGHT)]
	middle.add_child(_edges[0])
	middle.add_child(_room())
	middle.add_child(_edges[1])
	column.add_child(middle)
	column.pre_sort_children.connect(_fit_edges.bind(column, middle))
	for edge: Control in _edges:
		edge.item_rect_changed.connect(_frame_world, CONNECT_DEFERRED)
	# The foot over the world, just above the tabs: Collect while anything
	# waits, as the design's gold pill, and the nearest goal beside it where
	# both fit, else the goal alone; the raid notice above them while it
	# shows, as the designs raise their raid banner, never in Collect's place.
	_foot = HFlowContainer.new()
	_foot.alignment = FlowContainer.ALIGNMENT_CENTER
	_foot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_foot.add_theme_constant_override("h_separation", UI.px(8))
	_foot.add_theme_constant_override("v_separation", UI.px(FOOT_GAP_LARGE if Settings.text_scale >= 150 else 6.0))
	goal_card = CenterContainer.new()
	goal_card.name = "Goal"
	goal_card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	goal_card.visible = false
	_foot.add_child(goal_card)
	collect_button = KitControls.action2(Strings.t("HOME_COLLECT_AMOUNT", "0"), "", _collect, "gold", "hud/collectall")
	collect_button.name = "Collect"
	collect_button.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	collect_button.visible = false
	# The screen's one primary action carries the kit's idle shine (report.md
	# step 10): a soft band across its face once a period while it waits;
	# none under reduced motion or in high contrast.
	Motion.shine(collect_button)
	_foot.add_child(collect_button)
	_foot.pre_sort_children.connect(_fit_foot)
	_raids = HomeParts.Raids.new(_across, _dismiss)
	notice = _raids.panel
	notice.visible = false
	column.add_child(notice)
	column.add_child(_foot)
	_build_tabs({})
	menu = UniverseMenu.make(PLACES, WORDS)
	menu.picked.connect(func(route: StringName) -> void: App.services.router.go(route))
	add_child(menu)
	_flights = Control.new()
	_flights.name = "Flights"
	_flights.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_flights.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_flights)
	column.sort_children.connect(_frame_world)
	for c: Control in [goal_card, collect_button, notice]:
		c.visibility_changed.connect(_frame_world, CONNECT_DEFERRED)
	notice.visibility_changed.connect(func() -> void:
		_edges_yield = false
		column.queue_sort())
	App.services.store.changed.connect(_on_changed)
	show_keeper()
	_show_hud()
	_draw_world()
	# Home opens on the whole universe, every realm and link at once (§23.2),
	# as the designs' home does; a tap or a pinch goes closer (§21.1).
	await send_waiting(column)
	await _load()


## Everything home shows, asked of the server afresh.
func _load() -> void:
	var services: Services = App.services
	for step: Callable in [services.keeper_flow.load_keeper, services.map_flow.load_all,
			services.universe_flow.load_universe, services.social_flow.load_league, services.shop_flow.load_track]:
		if not (services.api.online() and is_inside_tree()):
			return
		await step.call()


## The Keeper badge at the top left, strain at the top right, and the
## resources in a full-width row beneath.
func _build_top(column: VBoxContainer) -> void:
	# A flow, so strain goes to a line of its own when the two will not fit
	# side by side (large text, long words).
	var top := HFlowContainer.new()
	top.mouse_filter = Control.MOUSE_FILTER_IGNORE
	keeper_plate = UniverseBadge.new()
	keeper_plate.visible = false
	keeper_plate.set_meta("frequent", false)
	keeper_plate.pressed.connect(func() -> void: Haptics.play("tap"))
	keeper_plate.pressed.connect(func() -> void: menu.open())
	top.add_child(keeper_plate)
	strain = HBoxContainer.new()
	strain.name = "StrainHolder"
	strain.alignment = BoxContainer.ALIGNMENT_END
	strain.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	strain.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	strain.mouse_filter = Control.MOUSE_FILTER_IGNORE
	strain.visible = false
	top.add_child(strain)
	column.add_child(top)
	# Strain fits beside the badge on the screen's own width, never the row's,
	# which a pill too wide would stretch.
	top.pre_sort_children.connect(func() -> void:
		if strain.get_parent() != top:
			return
		var frame := column.get_parent() as MarginContainer
		var room := get_viewport_rect().size.x - frame.get_theme_constant("margin_left") \
			- frame.get_theme_constant("margin_right")
		_fit_strain(room - keeper_plate.get_combined_minimum_size().x - top.get_theme_constant("h_separation")))
	purse = HFlowContainer.new()
	purse.name = "Purse"
	purse.mouse_filter = Control.MOUSE_FILTER_IGNORE
	purse.add_theme_constant_override("h_separation", UI.px(PURSE_GAP))
	# Large text closes the rows up, the world keeping the height (S2-R20).
	purse.add_theme_constant_override("v_separation", UI.px(PURSE_GAP_LEAST if Settings.text_scale >= 150 else PURSE_GAP))
	for k: String in UniversePurse.ORDER:
		var pill := KitStatus.resource("resources/" + k, "–", 0.0, Tokens.color(k))
		pill.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		pill.mouse_filter = Control.MOUSE_FILTER_IGNORE
		# The counts are the screen's headline figures: the kit's display face,
		# ink-outlined with a hard drop, as the design draws them (S2-R12 asks
		# K1 to make it the resource part's own).
		home_figure(pill.find_child("Amount", true, false) as Label, 18)
		HomeParts.hang_full(pill)
		pills[k] = pill
		purse.add_child(pill)
	purse.pre_sort_children.connect(_fit_purse)
	column.add_child(purse)
	_top = purse
	# Large text (§20.8): strain takes the purse's fourth place, beside the
	# last resource, as the key frame at 200% sets it, rather than a line of
	# its own over the purse; the world keeps that line.
	if Settings.text_scale >= 150:
		strain.reparent(purse, false)


## A column of side buttons down one edge, in the middle of the screen.
func _edge(which: Array) -> BoxContainer:
	# High on each edge, beside the top row of islands, as the designs place
	# them: secondary places, not the thumb's (§21.1 binds frequent controls).
	# A box whose way can turn: one above the other, else side by side.
	var edge := BoxContainer.new()
	edge.vertical = true
	edge.alignment = BoxContainer.ALIGNMENT_BEGIN
	edge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	edge.add_theme_constant_override("separation", UI.px(14))
	for s: Array in which:
		var holder := CenterContainer.new()
		holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
		holder.set_meta("side", s)
		edge.add_child(holder)
		sides[s[0]] = holder
		# The pins keep clear of where the button is now, not where it was
		# when the column last sorted.
		holder.item_rect_changed.connect(_frame_world, CONNECT_DEFERRED)
		_side(holder, "")
	return edge


## A side button in `holder`, with `badge` on it ("" for none).
func _side(holder: CenterContainer, badge: String) -> void:
	if _badges.get(holder, null) == badge and holder.get_child_count() > 0:
		return
	_badges[holder] = badge
	for c: Node in holder.get_children():
		c.queue_free()
	var s: Array = holder.get_meta("side")
	var route: StringName = s[0]
	var action := KitControls.round_action(s[1], Strings.t(s[2]), func() -> void: App.services.router.go(route), false,
		52.0, badge, "sky")
	# Large text (§20.8): the disc alone, its badge kept and its name still
	# spoken; a word plate at 200% outgrows the edge and covers the islands.
	if Settings.text_scale >= 150 and action.get_child_count() > 1:
		(action.get_child(1) as Control).visible = false
	_secondary(action)
	holder.add_child(action)


## The kit's five tabs, rebuilt when a badge changes.
func _build_tabs(badges: Dictionary) -> void:
	if tabs != null and badges == _tab_badges:
		return
	_tab_badges = badges
	var at := -1
	if tabs != null:
		at = tabs.get_index()
		tabs.queue_free()
	tabs = KitTabs.make("islands", badges)
	tabs.picked.connect(_on_tab)
	var column := _foot.get_parent()
	column.add_child(tabs)
	if at >= 0:
		column.move_child(tabs, at)
	# The chosen tab's name with an ink outline wide enough to be measured
	# against (§21.8: 1.5 points or 12% of its size), over the periwinkle.
	var chosen := tabs.buttons["islands"] as Button
	for l: Label in chosen.find_children("*", "Label", true, false):
		l.add_theme_constant_override("outline_size", maxi(UI.px(2), ceili(l.get_theme_font_size("font_size") * 0.13)))
	for b: Button in tabs.buttons.values():
		b.resized.connect(_fit_tab_words, CONNECT_DEFERRED)
	tabs.resized.connect(_fit_tab_words, CONNECT_DEFERRED)
	var lift := func() -> void: HomeParts.reserve_lift(tabs, column.get_theme_constant("separation"))
	(chosen.find_child("Tile", true, false) as Control).item_rect_changed.connect(lift, CONNECT_DEFERRED)
	_raise_heist()


## The Heist leads the bar, as the design raises it: its tile risen above the
## others by most of the chosen tab's rise and its picture larger, its head over
## the tile's top edge, on the kit's gold Heist look. The kit sets every tab
## afresh when one is chosen; home is left only through the Heist and the others.
func _raise_heist() -> void:
	if tabs.active == "heist" or not tabs.buttons.has("heist"):
		return
	var b := tabs.buttons["heist"] as Button
	b.custom_minimum_size.y = UI.px(Tokens.number("size", "tab_height") + KitTabs.RISE * 0.75)
	var icon := b.find_children("*", "TextureRect", true, false)
	if icon.is_empty():
		return
	var picture := icon[0] as TextureRect
	picture.custom_minimum_size = Vector2.ONE * UI.px(50)
	(picture.get_parent() as Control).offset_top = -float(UI.px(8))


## The tabs' words, after the kit has fitted them (P2-K1-tabs owns KitTabs).
## The others' names show, smaller where one would be cut, never under
## TAB_WORD_LEAST: below that (large text) their icons alone, each named aloud,
## as the key frame at 200% does. The chosen tab's name always shows (board 3's
## objection C), as large as fits inside its tile.
func _fit_tab_words() -> void:
	if tabs == null or not is_instance_valid(tabs):
		return
	var words := {}
	for key: String in tabs.buttons:
		for l: Label in (tabs.buttons[key] as Button).find_children("*", "Label", true, false):
			if l.get_parent() is VBoxContainer:
				words[key] = l
	var again := false
	var at := float(UI.text_px(13))
	for key: String in words:
		if key == tabs.active:
			continue
		var l: Label = words[key]
		var room := (tabs.buttons[key] as Button).size.x - UI.px(2)
		var whole := _tab_word(l, UI.text_px(13))
		if whole > room:
			at = minf(at, floorf(UI.text_px(13) * room / maxf(whole, 1.0)))
	var others := at >= UI.text_px(TAB_WORD_LEAST)
	for key: String in words:
		var l: Label = words[key]
		var b := tabs.buttons[key] as Button
		if key != tabs.active:
			if others and l.get_theme_font_size("font_size") != int(at):
				l.add_theme_font_size_override("font_size", int(at))
			l.visible = others
			continue
		var px := l.get_theme_font_size("font_size")
		var fit := px
		var room := b.size.x - UI.px(KitTabs.RIM)
		var wide := _tab_word(l, px)
		if wide > room:
			fit = floori(px * room / maxf(wide, 1.0))
		if l.is_visible_in_tree() and l.size.y > 0.0:
			var over := l.get_global_rect().end.y - b.get_global_rect().end.y
			if over > 0.5:
				fit = mini(fit, floori(px * (l.size.y - over) / l.size.y))
		fit = maxi(fit, UI.px(15))
		if fit < px:
			l.add_theme_font_size_override("font_size", fit)
			again = true
		l.visible = true
	if again:
		_fit_tab_words.call_deferred()


## The width `l`'s word takes in capitals at `px`, its stroke included.
static func _tab_word(l: Label, px: int) -> float:
	return l.get_theme_font("font").get_string_size(l.text.to_upper(), HORIZONTAL_ALIGNMENT_LEFT, -1, px).x \
		+ l.get_theme_constant("outline_size")


static func _room() -> Control:
	var room := UI.grow()
	room.mouse_filter = Control.MOUSE_FILTER_IGNORE
	room.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return room


func _on_tab(key: String) -> void:
	if key == "islands":
		_raise_heist()
		world.show_whole()
	elif key == "heist":
		_play()
	elif TAB_ROUTES.has(key):
		App.services.router.go(TAB_ROUTES[key])


## A realm tapped in the world: closer, and once close, its realm view.
func _on_realm(id: String) -> void:
	if _close == id:
		_close = ""
		App.services.realm_flow.open(id)
		return
	_close = id if world.zoom == 2 else ""


## The realms' pins follow the world's zoom and the room.
func _process(_delta: float) -> void:
	if world != null:
		_fit_pins()


## The universe framed between the resources and its foot (the raid notice,
## the goal and Collect), every realm and pin clear of them (board 3's B).
## Collect and the goal always keep their place (A). The side buttons stand in
## columns where the room is tall enough, else side by side, discs alone at
## large text (C); only where that row leaves the realms no room, or at large
## text where a realm's pin finds none beside them, do they give way: each
## place is on the badge's menu, and the raids on the notice.
func _fit_edges(column: VBoxContainer, middle: Control) -> void:
	var frame := column.get_parent() as MarginContainer
	var room := get_viewport_rect().size.y - frame.get_theme_constant("margin_top") \
		- frame.get_theme_constant("margin_bottom")
	var gap := column.get_theme_constant("separation")
	var need := 0.0
	for c: Control in column.get_children():
		if c.visible and c != middle:
			need += c.get_combined_minimum_size().y + gap
	# Columns, else a row with a row's height left for the chips, else none.
	var tall := 0.0
	var row := 0.0
	for edge: Control in _edges:
		var column_tall := 0.0
		for holder: Control in edge.get_children():
			var h := holder.get_combined_minimum_size().y
			column_tall += h + edge.get_theme_constant("separation")
			row = maxf(row, h)
		tall = maxf(tall, column_tall - edge.get_theme_constant("separation"))
	var band := room - need
	var upright := tall <= band
	var fits := not _edges_yield and (upright or row * 2.0 <= band)
	for edge: Control in _edges:
		if edge.visible != fits:
			edge.visible = fits
		var box := edge as BoxContainer
		if fits and box.vertical != upright:
			box.vertical = upright


func _frame_world() -> void:
	world.fit_between(_top, _floor())
	var clear: Array[Rect2] = []
	for route: StringName in sides:
		if not (sides[route] as Control).is_visible_in_tree():
			continue
		# The button with what hangs off it: its badge past its rim, its plate.
		var r := _reach(sides[route] as Control)
		clear.append(Rect2(r.position - world.global_position, r.size))
	# And of what floats over the foot: Collect or the goal, or the raid card.
	for c: Control in [collect_button, goal_card, notice]:
		if c.is_visible_in_tree():
			var r := c.get_global_rect()
			clear.append(Rect2(r.position - world.global_position, r.size))
	world.keep_clear = clear


## Where `c` and everything shown inside it reach on the screen: a side
## button's badge stands past the button's own rect.
static func _reach(c: Control) -> Rect2:
	var r := c.get_global_rect()
	for d: Node in c.find_children("*", "Control", true, false):
		var k := d as Control
		if k.is_visible_in_tree() and k.size.x > 0.0 and k.size.y > 0.0:
			r = r.merge(k.get_global_rect())
	return r


## The universe's floor: the top of the raid notice while it shows, else of the
## goal and Collect, so the islands and pins fit above them (board 3's B); the
## tabs only while nothing stands there.
func _floor() -> Control:
	var over: Control = _foot
	if notice.visible:
		over = notice
	if tabs == null or over.size.y <= 0.0 or not over.is_visible_in_tree():
		return tabs
	return over


## The goal beside Collect where the two fit on one line, as the design sets
## them; else each on its own line, Collect first and the goal wrapping beneath
## it, as the key frame at 200% stacks them. The goal is never dropped (C).
func _fit_foot() -> void:
	var across := _across()
	var natural: float = collect_button.get_meta("natural", collect_button.custom_minimum_size.x)
	var stacked := false
	if not goal.is_empty() and goal_card.get_child_count() > 0:
		var card := goal_card.get_child(goal_card.get_child_count() - 1) as Control
		var widest := minf(UI.px(GOAL_WIDEST), across)
		var room := across - _foot.get_theme_constant("h_separation") - natural
		# Beside Collect only where its words take two lines at most (board 3's
		# objection B): a third would stand the goal taller than Collect.
		stacked = collect_button.visible and room + 0.5 < maxf(UI.px(GOAL_NARROWEST), _two_lines(card))
		var wide := widest
		if stacked:
			wide = across
		elif collect_button.visible:
			wide = clampf(floorf(room), UI.px(GOAL_NARROWEST), widest)
		if not is_equal_approx(card.custom_minimum_size.x, wide):
			card.custom_minimum_size.x = wide
		HomeParts.break_goal(card, str(goal.get("text", "")), wide)
	var collect_wide := across if stacked else natural
	if not is_equal_approx(collect_button.custom_minimum_size.x, collect_wide):
		collect_button.custom_minimum_size.x = collect_wide
	var at := 0 if stacked else _foot.get_child_count() - 1
	if collect_button.get_index() != at:
		_foot.move_child(collect_button, at)


## The goal card's width with its words in two lines at most: the narrowest
## break between two words that leaves both halves shortest (a line breaks
## between words, as the label wraps them), with the card's picture and padding
## beside them.
func _two_lines(card: Control) -> float:
	var l := HomeParts.goal_words(card)
	if l == null:
		return 0.0
	var font := l.get_theme_font("font")
	var points: int = l.get_meta("px", l.get_theme_font_size("font_size"))
	var text := str(goal.get("text", ""))
	var words := text.split(" ", false)
	var narrowest := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, points).x
	for i in range(1, words.size()):
		var first := font.get_string_size(" ".join(words.slice(0, i)), HORIZONTAL_ALIGNMENT_LEFT, -1, points).x
		var second := font.get_string_size(" ".join(words.slice(i)), HORIZONTAL_ALIGNMENT_LEFT, -1, points).x
		narrowest = minf(narrowest, maxf(first, second))
	# A pixel over each half's own width, so the label's wrap keeps the break.
	return ceilf(narrowest + 2.0 + HomeParts.goal_beside(card, l))


## The foot's width: the frame's inside, which the foot fills. Its own size
## is the one it last had while it is hidden, and none before its first sort.
func _across() -> float:
	var frame := _foot.get_parent().get_parent() as MarginContainer
	return get_viewport_rect().size.x - frame.get_theme_constant("margin_left") \
		- frame.get_theme_constant("margin_right")


## Over the whole universe every realm is named, or none is. Where the room is
## short (§20.8's large text) the realms' pins first shrink to their icons and
## levels together (UniversePins); where even then one finds no room, the pins
## give way together rather than leave some realms unnamed. Each realm is still
## said aloud with the world, and each island still takes its tap.
func _fit_pins() -> void:
	var pins := world.pins
	var whole := true
	if world.zoom == 0:
		for id: String in world.islands:
			var pin := pins.realm_pin(id)
			if pin != null and not pin.visible:
				whole = false
				break
	if pins.short() and not _edges_yield and Settings.text_scale >= 150 and _edges[0].visible:
		# Only where even the numbered chips find no place, laid each failing
		# realm first, do the side buttons give way (AD's objection (g) on
		# S2-R27): each place is on the badge's menu.
		_edges_yield = true
		(_foot.get_parent() as Control).queue_sort()
		return
	if pins.visible != whole:
		pins.visible = whole


func _on_changed(slice: StringName) -> void:
	if not is_inside_tree():
		return
	if slice == KeeperState.KEEPER or slice == SocialState.LEAGUE:
		show_keeper()
	if slice in [DefencesState.DEFENCES, WeavingState.WEAVING, ShopState.WALLET, ShopState.TRACK, RosterState.ROSTER,
			CodexState.CODEX, KeeperState.KEEPER, UniverseState.UNIVERSE]:
		_show_hud()
	if slice in UniverseStore.SLICES:
		_draw_world()


## The universe as the store has it, and said in words.
func _draw_world() -> void:
	var store := App.services.store
	var view := UniverseStore.view(store)
	# Strain is the HUD's, at the top right, so the Heart carries no pin of it.
	var extras := UniverseStore.extras(store)
	extras.erase("strain")
	extras["quiet"] = true
	world.show_universe(view, extras)
	world.accessibility_name = Strings.t("HOME_MAP")
	world.accessibility_description = UniverseStore.spoken(view)


## Strain, the resources, the goal and the badges, from what the store holds.
func _show_hud() -> void:
	var store := App.services.store
	var weaving: Dictionary = store.get_slice(WeavingState.WEAVING).get("view", {})
	var stability: Dictionary = weaving.get("stability", {})
	_show_strain(float(stability.get("strain", 0.0)), int(stability.get("band", 0)), stability.has("strain"))
	_show_purse(UniverseStore.purse(store))
	var nearest := UniverseGoal.goals(store.get_slice(KeeperState.KEEPER), store.get_slice(ShopState.TRACK))
	_show_goal(nearest[0] if not nearest.is_empty() else {})
	var unseen := int(store.get_slice(DefencesState.DEFENCES).get("unseen", 0))
	_side(sides[&"defences"], str(unseen) if unseen > 0 else "")
	if unseen < _dismissed:
		_dismissed = 0
	_raids.show_raids(unseen if unseen > _dismissed else 0)
	var track := ShopPresenter.track(store.get_slice(ShopState.TRACK))
	_side(sides[&"track"], "!" if bool(track.get("can_claim", false)) else "")
	# Collect shows while any producer holds something (§9.3), what each
	# resource has waiting said aloud. The pills say which are full, so the
	# Islands tab carries no count of its own, as the design draws it.
	var ready := {}
	for p: Dictionary in store.get_slice(RosterState.ROSTER).get("view", {}).get("producers", []):
		var kind: String = UniverseStore.PRODUCES.get(str(p.get("kind", "")), "")
		if kind != "" and int(p.get("stored", 0)) > 0:
			ready[kind] = int(ready.get(kind, 0)) + int(p["stored"])
	var was := collect_button.visible
	collect_button.visible = not ready.is_empty() and str(store.get_slice(RosterState.ROSTER)["busy"]) == ""
	if collect_button.visible and not was:
		Motion.pop.call_deferred(collect_button)
	goal_card.visible = not goal.is_empty()
	_foot.queue_sort()
	var waiting := PackedStringArray()
	var total := 0
	for kind: String in UniversePurse.ORDER:
		if ready.has(kind):
			waiting.append("%s %s" % [UniverseHud.grouped(ready[kind]), Strings.t("HOME_RES_" + kind.to_upper())])
			total += int(ready[kind])
	var words := collect_button.find_children("*", "Label", true, false)[0] as Label
	words.text = Strings.t("HOME_COLLECT_AMOUNT", UniverseHud.compact(total, 1000))
	# "Collect 3.4k" as the design writes it, not the gold's capitals.
	words.uppercase = false
	# The button grows to the amount, its picture and padding; wider than the
	# screen (200%, long languages), its picture gives way first.
	var inside := words.get_parent() as Control
	var picture := inside.get_child(0) as Control
	var most := _across()
	picture.visible = true
	# The words at the kit's own size first, the amount being new.
	if not words.has_meta("px"):
		words.set_meta("px", words.get_theme_font_size("font_size"))
	words.add_theme_font_size_override("font_size", int(words.get_meta("px")))
	var need := inside.get_combined_minimum_size().x + UI.px(COLLECT_PAD)
	if need > most and picture != words:
		picture.visible = false
		need = inside.get_combined_minimum_size().x + UI.px(COLLECT_PAD)
	# Still wider (German at 200%, "3,4 Tsd. einsammeln"): the words a little
	# smaller, so they stay inside the gold at the screen's width.
	# A point at a time, as the words' width is not quite in step with their
	# size, until COLLECT_PAD is left beside them (AD's objection (e) on S2-R22).
	var px := int(words.get_meta("px"))
	while need > most and px > UI.px(12):
		px -= 1
		words.add_theme_font_size_override("font_size", px)
		need = inside.get_combined_minimum_size().x + UI.px(COLLECT_PAD)
	collect_button.set_meta("natural", clampf(need, UI.px(120), maxf(UI.px(120), most)))
	collect_button.custom_minimum_size.x = collect_button.get_meta("natural")
	collect_button.accessibility_name = Strings.t("HOME_COLLECT_SPOKEN", ", ".join(waiting))
	_build_tabs({})


## Every producer collected (§9.3), the amounts flying into their bars.
func _collect() -> void:
	collect_button.disabled = true
	var paid: Dictionary = await App.services.roster_flow.collect_all()
	if not is_inside_tree():
		return
	collect_button.disabled = false
	# The reward flies to the kit's pills (S2-R5).
	UniverseReward.fly(_flights, collect_button, pills, paid)
	_show_hud()


## Strain as a share (0.82) and its band; `known` false hides the pill.
func _show_strain(share: float, band: int, known: bool) -> void:
	strain.visible = known
	band = clampi(band, 0, UniverseHud.BANDS.size() - 1)
	var named := WeavingPresenter.band_name(band)
	var pct := roundi(share * 100.0)
	var lines := PackedStringArray(["%d%% · %s" % [pct, named], "%d%%\n%s" % [pct, named]])
	var key := "%d" % band
	if lines == _strain_lines and strain.get_child_count() > 0 and strain.get_child(0).get_meta("band", "") == key:
		return
	_strain_lines = lines
	for c: Node in strain.get_children():
		c.queue_free()
	var pill := KitStatus.strain(lines[0], BAND_KEYS[band])
	pill.custom_minimum_size.y = UI.px(UI.CONTROL_POINTS)
	var tap := KitLayout.tap(pill, func() -> void: App.services.router.go(&"weaving"),
		Strings.t("HOME_STRAIN_SPOKEN", [named, pct]))
	# Inside the pill the tap would stand within its padding, short of §21.1's
	# 48 points; over a holder of the pill's own size it is the whole pill.
	var hit := MarginContainer.new()
	hit.set_meta("band", key)
	hit.size_flags_horizontal = Control.SIZE_SHRINK_END
	hit.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	if Settings.text_scale >= 150:
		HomeParts.large_strain(pill, pct, named)
		# The purse's fourth place, as tall as the pill beside it.
		hit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		hit.size_flags_vertical = Control.SIZE_FILL
	hit.add_child(pill)
	tap.reparent(hit, false)
	_secondary(hit)
	strain.add_child(hit)
	_strain_pill = pill
	_strain_room = 0.0


## The strain pill no wider than `room` if it can be: the number over the
## band's name where one line will not do, its words a little smaller where two
## lines are a hair too wide (Portuguese at large text); past that, a line alone.
func _fit_strain(room: float) -> void:
	if strain.get_child_count() == 0 or _strain_lines.is_empty() or absf(room - _strain_room) < 0.5:
		return
	_strain_room = room
	var pill := _strain_pill
	var band := pill.find_child("Band", true, false) as Label
	if band != null:
		# The large form's band name a little smaller where it is a hair too
		# wide, never under STRAIN_LEAST; past that it wraps.
		# Back to its own size first: the theme's is not scaled by large text.
		var px := int(band.get_meta("px"))
		band.add_theme_font_size_override("font_size", px)
		band.autowrap_mode = TextServer.AUTOWRAP_OFF
		band.custom_minimum_size.x = 0.0
		# Its width measured from its font: the label's own size is the last
		# frame's until its theme settles.
		var wide := band.get_theme_font("font").get_string_size(band.text, HORIZONTAL_ALIGNMENT_LEFT, -1, px).x
		var over := pill.get_combined_minimum_size().x - band.get_combined_minimum_size().x + wide - room
		if over > 0.5:
			var shrunk := floori(px * (wide - over) / maxf(1.0, wide))
			if shrunk >= ceili(px * STRAIN_LEAST):
				band.add_theme_font_size_override("font_size", shrunk)
			else:
				band.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
				band.custom_minimum_size.x = maxf(0.0, wide - over)
		return
	var l := pill.find_child("Words", true, false) as Label
	l.remove_theme_font_size_override("font_size")
	var font := l.get_theme_font("font")
	var points := l.get_theme_font_size("font_size")
	var rest := pill.get_combined_minimum_size().x - l.get_combined_minimum_size().x
	var one := font.get_string_size(_strain_lines[0], HORIZONTAL_ALIGNMENT_LEFT, -1, points).x + rest
	var two_words := font.get_multiline_string_size(_strain_lines[1], HORIZONTAL_ALIGNMENT_LEFT, -1, points).x
	var stacked := one > room and two_words + rest <= room
	var shrunk := floori(points * (room - rest) / maxf(1.0, two_words))
	if one > room and not stacked and shrunk >= ceili(points * STRAIN_LEAST):
		stacked = true
		l.add_theme_font_size_override("font_size", shrunk)
	var text := _strain_lines[1] if stacked else _strain_lines[0]
	if l.text != text:
		l.text = text
		l.clip_text = false
		l.text_overrun_behavior = TextServer.OVERRUN_NO_TRIMMING
		l.custom_minimum_size.x = 0.0


## What the store holds (UniverseStore.purse): each amount (past 10,000 in
## thousands, "142.0k"; said in full) and how full its producers are (§9.3),
## Full on a red tag once nearly full. An amount not given is a dash, never a guess.
func _show_purse(rows: Dictionary) -> void:
	var said := PackedStringArray()
	for k: String in UniversePurse.ORDER:
		var r: Dictionary = rows.get(k, {})
		var amount := int(r.get("amount", -1))
		var holds := int(r.get("holds", 0))
		var share := clampf(float(r.get("ready", 0)) / holds, 0.0, 1.0) if holds > 0 else 0.0
		_full[k] = share >= UniversePurse.FULL
		KitStatus.set_resource(pills[k], UniverseHud.compact(amount) if amount >= 0 else "–", share)
		said.append(Strings.t("HOME_PURSE_SPOKEN", [Strings.t("HOME_RES_" + k.to_upper()),
			UniverseHud.grouped(amount) if amount >= 0 else Strings.t("HOME_UNKNOWN"),
			UniverseHud.grouped(int(r.get("ready", 0)))]))
	purse.accessibility_name = Strings.t("HOME_PURSE")
	purse.accessibility_description = "\n".join(said)
	purse.queue_sort()


## Full on its red tag (`HomeParts.hang_full`) wherever a pill's producers are nearly
## full, at every size and in every language (S2-R20's third objection); the
## kit's gold word in the pill's row stays hidden, as it took the width the
## three pills need to share a line. Past that the row wraps.
func _fit_purse() -> void:
	for k: String in UniversePurse.ORDER:
		((pills[k] as Control).find_child("Full", true, false) as Control).visible = false
		var tag := (pills[k] as Control).find_child("FullTag", true, false) as Control
		if tag != null and tag.visible != _full.get(k, false):
			tag.visible = _full.get(k, false)
	# The gaps between the three pills close a little, to PURSE_GAP_LEAST,
	# before the third goes to a row of its own (Portuguese at 100% is four
	# pixels over at the full gap).
	var need := 0.0
	for k: String in UniversePurse.ORDER:
		need += (pills[k] as Control).get_combined_minimum_size().x
	var gaps := UniversePurse.ORDER.size() - 1.0
	var gap := clampf(floorf((purse.size.x - need) / gaps), UI.px(PURSE_GAP_LEAST), UI.px(PURSE_GAP))
	if purse.size.x > 0.0 and purse.get_theme_constant("h_separation") != int(gap):
		purse.add_theme_constant_override("h_separation", int(gap))
	_fit_amounts()
	if strain.get_parent() == purse:
		var last := pills[UniversePurse.ORDER[UniversePurse.ORDER.size() - 1]] as Control
		_fit_strain(purse.size.x - last.get_combined_minimum_size().x - purse.get_theme_constant("h_separation"))


## The purse in one row at 100% text, in two with large text (§20.8). Where
## the pills of a row cannot share it (German's "142,0 Tsd."), all three
## amounts are a little smaller, never under AMOUNT_LEAST: at 100% so Essence
## does not drop to a row alone (AD's objection (c) on S2-R22), with large text
## so the third row stays the realms' chips.
func _fit_amounts() -> void:
	var amounts: Array[Label] = []
	for k: String in UniversePurse.ORDER:
		var l := (pills[k] as Control).find_child("Amount", true, false) as Label
		if l != null and l.has_meta("points"):
			amounts.append(l)
	var share := 1.0
	var large := Settings.text_scale >= 150
	var row := 2 if large else 3
	if amounts.size() >= row:
		# The row's pills' widths with their amounts at full size, read from
		# the face, not from the labels as they are now.
		var words := 0.0
		var rest := 0.0
		for i in row:
			var l := amounts[i]
			var full := UI.text_px(float(l.get_meta("points")))
			words += l.get_theme_font("font").get_string_size(l.text, HORIZONTAL_ALIGNMENT_LEFT, -1, full).x
			rest += (pills[UniversePurse.ORDER[i]] as Control).get_combined_minimum_size().x - l.get_combined_minimum_size().x
		var gap := float(purse.get_theme_constant("h_separation")) if large else UI.px(PURSE_GAP_LEAST) * (row - 1.0)
		var over := words + rest + gap - purse.size.x
		if over > 0.5:
			var shrunk := (words - over - 1.0) / maxf(words, 1.0)
			if shrunk >= AMOUNT_LEAST:
				share = shrunk
	for l: Label in amounts:
		var px := floori(UI.text_px(float(l.get_meta("points"))) * share)
		if l.get_theme_font_size("font_size") != px:
			l.add_theme_font_size_override("font_size", px)


## The nearest goal on the kit's goal card, its words and a gold bar of the
## share done; a tap opens where it is worked on.
func _show_goal(g: Dictionary) -> void:
	if g == goal and goal_card.get_child_count() > 0:
		return
	goal = g
	for c: Node in goal_card.get_children():
		c.queue_free()
	if g.is_empty():
		goal_card.visible = false
		return
	var card := KitHud.goal(GOAL_ICONS.get(str(g["icon"]), ""), str(g["text"]), float(g["share"]), 1.0, "")
	# The words say what is left; the bar shows the share, never a number.
	for l: Label in card.find_child("Progress", true, false).find_children("*", "Label", true, false):
		l.visible = false
	# Its words a point under the kit's, as the key frame sets them under
	# Collect's: two lines of them stand beside Collect at 100% (S2-R20's second
	# objection), leaving the world the foot's second line.
	for l: Label in card.find_children("*", "Label", true, false):
		if l.visible and l.text == str(g["text"]):
			l.set_meta("goal_words", true)
			l.set_meta("points", GOAL_POINTS)
			l.add_theme_font_size_override("font_size", UI.text_px(GOAL_POINTS))
			l.set_meta("px", UI.text_px(GOAL_POINTS))
			if Settings.text_scale >= 150:
				# Its lines as close as the key frame at 200% sets them, the bar
				# tucked under the last one's figures, so three lines leave the
				# realms' chips their room (S2-R20's fourth objection).
				l.add_theme_constant_override("line_spacing", -int(UI.px(GOAL_LINE_TIGHTER)))
				# Its last line loses that closeness too, which the bar gives back.
				(l.get_parent() as BoxContainer).add_theme_constant_override("separation",
						-int(HomeParts.below(l) - UI.px(GOAL_LINE_TIGHTER)))
	if Settings.text_scale >= 150:
		card.add_theme_stylebox_override("panel", UI.clear_box(10, GOAL_PAD_LARGE))
	card.custom_minimum_size.x = minf(UI.px(GOAL_WIDEST), _across())
	var route: StringName = g.get("route", &"profile")
	KitLayout.tap(card, func() -> void: App.services.router.go(route), Strings.t("HOME_GOAL_SPOKEN", str(g["text"])))
	_secondary(card)
	goal_card.add_child(card)


func _dismiss() -> void:
	_dismissed = int(App.services.store.get_slice(DefencesState.DEFENCES).get("unseen", 0))
	notice.visible = false


## The Keeper's level, the way to the next, and Renown, once the server has
## said where the player stands (§14.2).
func show_keeper() -> void:
	var store := App.services.store
	var keeper: Dictionary = store.get_slice(KeeperState.KEEPER)
	var b := KeeperPresenter.bar(keeper)
	keeper_plate.visible = b["ready"]
	if not b["ready"]:
		return
	var v: Dictionary = keeper.get("view", {})
	var need := int(v.get("toNext", 0)) if v.get("toNext") != null else 0
	b["level"] = int(v.get("level", 1))
	var league: Dictionary = store.get_slice(SocialState.LEAGUE).get("view", {})
	var renown := UniverseHud.grouped(int(league["renown"])) if league.get("renown") != null else ""
	keeper_plate.show_keeper(b, float(v.get("xp", 0)) / need if need > 0 else 1.0, renown)


## G41: what was played offline goes by itself once the network is back, and
## the player is told. Returns how many were sent.
func send_waiting(column: VBoxContainer) -> int:
	var services: Services = App.services
	if not services.api.online() or services.outbox.pending() == 0:
		return 0
	if not (await services.sign_in()):
		return 0
	var sent := await services.outbox.flush(services.api)
	if sent > 0 and is_inside_tree():
		var banner := UI.banner("success", Strings.t("OFFLINE_SENT", sent))
		column.add_child(banner)
		column.move_child(banner, _foot.get_index())
	return sent


## A heist on the fixture realm or a leased island: not the builder's test.
func _play() -> void:
	App.services.store.dispatch(&"heist_started", {})
	App.services.router.go(&"heist")


## `l` in the kit's display role (tokens.json "display": its face, heavier ink
## and hard drop) at `points`, for home's figures and names, which the small
## role's thinner line leaves flat over the starfield (cycle 77's gate).
static func home_figure(l: Label, points: float) -> void:
	if l == null:
		return
	l.theme_type_variation = "Display"
	l.add_theme_font_size_override("font_size", UI.text_px(points))
	l.set_meta("points", points)


## A secondary place (§21.1 binds only the frequently used controls to the
## thumb zone): `top` and every button in it, the kit's tap areas included.
static func _secondary(top: Control) -> void:
	top.set_meta("frequent", false)
	for b: Node in top.find_children("*", "Button", true, false):
		b.set_meta("frequent", false)

