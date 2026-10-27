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

## The unseen raids the player dismissed the notice for: it returns only when
## more come.
static var _dismissed := 0

## The Keeper badge at the top left; hidden until the server has answered.
var keeper_plate: UniverseBadge
var strain: UniverseStrain
var purse: UniversePurse
var goal: UniverseGoal
## The UI kit's five tabs (`KitTabs`), Islands chosen.
var tabs: KitTabs
var menu: UniverseMenu
## The side buttons by route (the kit's round actions); the defence log's
## carries the raid badge (TD.66).
var sides := {}
## The universe behind the interface.
var world: UniverseView
## The raid notice over the goal.
var notice: UniverseNotice
## The design's "COLLECT 3.4k" over the foot, while any producer holds
## something (§9.3); the goal shows in its place while nothing waits.
var collect_button: UniverseCollect

var _top: Control
## The two edges of side buttons.
var _edges: Array[Control] = []
var _foot: HFlowContainer
## Each side button's badge as last drawn, so a button is rebuilt only when
## its badge changes.
var _badges := {}
var _tab_badges := {}
## The realm the world is closed in on: one more tap there opens it.
var _close := ""


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
	column.add_theme_constant_override("separation", UI.px(6))
	world = UniverseView.behind(self, column)
	world.next_chosen.connect(func() -> void: App.services.router.go(&"universe"))
	world.realm_chosen.connect(_on_realm)
	_shade(true)
	_shade(false)
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
	# waits, as the design's lone pill, else the nearest goal; the raid notice
	# in their place while it shows, as the designs raise their raid banner
	# over Collect.
	_foot = HFlowContainer.new()
	_foot.alignment = FlowContainer.ALIGNMENT_CENTER
	_foot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_foot.add_theme_constant_override("separation", UI.px(8))
	goal = UniverseGoal.new()
	goal.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	goal.visible = false
	goal.pressed.connect(func() -> void: App.services.router.go(goal.goal.get("route", &"profile")))
	_foot.add_child(goal)
	collect_button = UniverseCollect.new()
	collect_button.pressed.connect(_collect)
	collect_button.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	collect_button.visible = false
	_foot.add_child(collect_button)
	column.add_child(_foot)
	notice = UniverseNotice.new()
	notice.visible = false
	_foot.visible = true
	notice.seen.connect(func() -> void: App.services.router.go(&"defences"))
	notice.dismissed.connect(_dismiss)
	column.add_child(notice)
	_build_tabs({})
	menu = UniverseMenu.make(PLACES, WORDS)
	menu.picked.connect(func(route: StringName) -> void: App.services.router.go(route))
	add_child(menu)
	column.sort_children.connect(_frame_world)
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
	strain = UniverseStrain.new()
	strain.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	strain.visible = false
	strain.set_meta("frequent", false)
	strain.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	strain.pressed.connect(func() -> void: Haptics.play("tap"))
	strain.pressed.connect(func() -> void: App.services.router.go(&"weaving"))
	top.add_child(strain)
	column.add_child(top)
	# Strain fits beside the badge on the screen's own width, never the row's,
	# which a pill too wide would stretch.
	top.pre_sort_children.connect(func() -> void:
		var frame := column.get_parent() as MarginContainer
		var room := get_viewport_rect().size.x - frame.get_theme_constant("margin_left") \
			- frame.get_theme_constant("margin_right")
		strain.fit(room - keeper_plate.get_combined_minimum_size().x - top.get_theme_constant("h_separation")))
	purse = UniversePurse.new()
	column.add_child(purse)
	_top = purse


## A column of side buttons down one edge, in the middle of the screen.
func _edge(which: Array) -> VBoxContainer:
	# High on each edge, beside the top row of islands, as the designs place
	# them: secondary places, not the thumb's (§21.1 binds frequent controls).
	var edge := VBoxContainer.new()
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
	var action := UniverseSide.make(s[1], Strings.t(s[2]), badge)
	action.pressed.connect(func() -> void: App.services.router.go(route))
	action.set_meta("frequent", false)
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


## Where large text would cut the other tabs' names short ("ISLA…"), they show
## their icons alone, each still named aloud; the chosen tab keeps its name if
## it fits. A word in pieces reads worse than none.
func _fit_tab_words() -> void:
	var words := {}
	var cut := false
	for key: String in tabs.buttons:
		for l: Label in (tabs.buttons[key] as Button).find_children("*", "Label", true, false):
			if l.get_parent() is VBoxContainer:
				words[key] = l
				var w := l.get_theme_font("font").get_string_size(l.text.to_upper(), HORIZONTAL_ALIGNMENT_LEFT, -1,
					l.get_theme_font_size("font_size")).x
				l.set_meta("cut", w > l.size.x + 0.5)
				cut = cut or (key != tabs.active and l.get_meta("cut"))
	for key: String in words:
		var l: Label = words[key]
		l.visible = not (l.get_meta("cut") or (cut and key != tabs.active))


## A night tint over the world behind the top's or the foot's interface, so
## its words read over any island (§21.8: the HUD is checked over the sky); a
## screen-space gradient, not a pass over the frame (§21.3).
func _shade(top: bool) -> void:
	var g := Gradient.new()
	var night := UniverseHud.CARD[1]
	g.set_color(0, Color(night, 0.78 if top else 0.0))
	g.set_color(1, Color(night, 0.0 if top else 0.85))
	var tex := GradientTexture2D.new()
	tex.gradient = g
	tex.fill_from = Vector2(0, 0)
	tex.fill_to = Vector2(0, 1)
	var rect := TextureRect.new()
	rect.texture = tex
	rect.stretch_mode = TextureRect.STRETCH_SCALE
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rect.set_anchors_preset(Control.PRESET_TOP_WIDE if top else Control.PRESET_BOTTOM_WIDE)
	var tall := float(UI.px(150 if top else 190))
	rect.offset_top = 0.0 if top else -tall
	rect.offset_bottom = tall if top else 0.0
	add_child(rect)
	move_child(rect, world.get_index() + 1)


static func _room() -> Control:
	var room := UI.grow()
	room.mouse_filter = Control.MOUSE_FILTER_IGNORE
	room.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return room


func _on_tab(key: String) -> void:
	if key == "islands":
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


## The universe framed into the whole room between the resources and the
## tabs, as the designs fill it; the goal, Collect and the raid notice float
## over its foot, as the designs' Collect and raid banner do. Its pins keep
## clear of the side buttons.
## The side buttons give way where the screen has no height for them (text at
## 200% on a shorter phone): every place they lead to is on the badge's menu,
## and the raids are on the notice.
func _fit_edges(column: VBoxContainer, middle: Control) -> void:
	var frame := column.get_parent() as MarginContainer
	var room := get_viewport_rect().size.y - frame.get_theme_constant("margin_top") \
		- frame.get_theme_constant("margin_bottom")
	var need := 0.0
	var shown := 0
	for c: Control in column.get_children():
		if c.visible and c != middle:
			need += c.get_combined_minimum_size().y
			shown += 1
	need += column.get_theme_constant("separation") * shown
	var tall := 0.0
	for edge: Control in _edges:
		for holder: Control in edge.get_children():
			tall += holder.get_combined_minimum_size().y + edge.get_theme_constant("separation")
	tall = tall / maxf(1.0, float(_edges.size()))
	var fits := need + tall <= room
	for edge: Control in _edges:
		if edge.visible != fits:
			edge.visible = fits


func _frame_world() -> void:
	world.fit_between(_top, tabs)
	var clear: Array[Rect2] = []
	for route: StringName in sides:
		if not (sides[route] as Control).is_visible_in_tree():
			continue
		var r := (sides[route] as Control).get_global_rect()
		clear.append(Rect2(r.position - world.global_position, r.size))
	world.keep_clear = clear


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
	strain.show_strain(float(stability.get("strain", 0.0)), int(stability.get("band", 0)), stability.has("strain"))
	purse.show_purse(UniverseStore.purse(store))
	var nearest := UniverseGoal.goals(store.get_slice(KeeperState.KEEPER), store.get_slice(ShopState.TRACK))
	goal.show_goal(nearest[0] if not nearest.is_empty() else {})
	var unseen := int(store.get_slice(DefencesState.DEFENCES).get("unseen", 0))
	_side(sides[&"defences"], str(unseen) if unseen > 0 else "")
	if unseen < _dismissed:
		_dismissed = 0
	notice.show_raids(unseen if unseen > _dismissed else 0)
	_foot.visible = not notice.visible
	var track := ShopPresenter.track(store.get_slice(ShopState.TRACK))
	_side(sides[&"track"], "!" if bool(track.get("can_claim", false)) else "")
	# The Islands tab counts the producers that are full (§9.3); Collect shows
	# while any holds something, what each resource has waiting said aloud.
	var full := 0
	var ready := {}
	for p: Dictionary in store.get_slice(RosterState.ROSTER).get("view", {}).get("producers", []):
		if int(p.get("holds", 0)) > 0 and float(p.get("stored", 0)) >= UniversePurse.FULL * int(p["holds"]):
			full += 1
		var kind: String = UniverseStore.PRODUCES.get(str(p.get("kind", "")), "")
		if kind != "" and int(p.get("stored", 0)) > 0:
			ready[kind] = int(ready.get(kind, 0)) + int(p["stored"])
	var was := collect_button.visible
	collect_button.visible = not ready.is_empty() and str(store.get_slice(RosterState.ROSTER)["busy"]) == ""
	if collect_button.visible and not was:
		Motion.pop.call_deferred(collect_button)
	goal.visible = goal.visible and not collect_button.visible
	var waiting := PackedStringArray()
	var total := 0
	for kind: String in UniversePurse.ORDER:
		if ready.has(kind):
			waiting.append("%s %s" % [UniverseHud.grouped(ready[kind]), Strings.t("HOME_RES_" + kind.to_upper())])
			total += int(ready[kind])
	collect_button.show_amount(total, Strings.t("HOME_COLLECT_SPOKEN", ", ".join(waiting)))
	_build_tabs({"islands": full} if full > 0 else {})


## Every producer collected (§9.3), the amounts flying into their bars.
func _collect() -> void:
	collect_button.disabled = true
	var paid: Dictionary = await App.services.roster_flow.collect_all()
	if not is_inside_tree():
		return
	collect_button.disabled = false
	UniverseReward.fly(self, collect_button, purse, paid)
	_show_hud()


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
