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
const LEFT := [[&"defences", "defences", "HOME_SIDE_DEFENCE"], [&"lab", "lab", "HOME_SIDE_LAB"]]
const RIGHT := [[&"track", "track", "HOME_SIDE_SEASON"], [&"shop", "shop", "HOME_SIDE_SHOP"]]
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
var tabs: UniverseTabs
var menu: UniverseMenu
## The side buttons by route; the defence log's carries the raid badge (TD.66).
var sides := {}
var defences_button: UniverseSide
## The universe behind the interface.
var world: UniverseView
## The raid notice over the goal.
var notice: UniverseNotice

var _top: Control
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
	middle.add_child(_edge(LEFT))
	middle.add_child(_room())
	middle.add_child(_edge(RIGHT))
	column.add_child(middle)
	notice = UniverseNotice.new()
	notice.visible = false
	notice.seen.connect(func() -> void: App.services.router.go(&"defences"))
	notice.dismissed.connect(_dismiss)
	column.add_child(notice)
	goal = UniverseGoal.new()
	goal.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	goal.visible = false
	goal.pressed.connect(func() -> void: App.services.router.go(goal.goal.get("route", &"profile")))
	column.add_child(goal)
	tabs = UniverseTabs.new()
	tabs.chosen.connect(_on_tab)
	column.add_child(tabs)
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
	var top := HBoxContainer.new()
	top.mouse_filter = Control.MOUSE_FILTER_IGNORE
	keeper_plate = UniverseBadge.new()
	keeper_plate.visible = false
	keeper_plate.set_meta("frequent", false)
	keeper_plate.pressed.connect(func() -> void: Haptics.play("tap"))
	keeper_plate.pressed.connect(func() -> void: menu.open())
	top.add_child(keeper_plate)
	top.add_child(_room())
	strain = UniverseStrain.new()
	strain.visible = false
	strain.set_meta("frequent", false)
	strain.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	strain.pressed.connect(func() -> void: Haptics.play("tap"))
	strain.pressed.connect(func() -> void: App.services.router.go(&"weaving"))
	top.add_child(strain)
	column.add_child(top)
	purse = UniversePurse.new()
	column.add_child(purse)
	_top = purse


## A column of side buttons down one edge, in the middle of the screen.
func _edge(which: Array) -> VBoxContainer:
	var edge := VBoxContainer.new()
	edge.alignment = BoxContainer.ALIGNMENT_CENTER
	edge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	edge.add_theme_constant_override("separation", UI.px(10))
	for s: Array in which:
		var route: StringName = s[0]
		var b := UniverseSide.make(s[1], Strings.t(s[2]), func() -> void: App.services.router.go(route))
		sides[route] = b
		edge.add_child(b)
	defences_button = sides.get(&"defences", defences_button)
	return edge


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


## The universe framed into the room between the resources and what is over
## the tabs, its pins clear of the side buttons.
func _frame_world() -> void:
	var foot: Control = tabs
	if notice.visible:
		foot = notice
	elif goal.visible:
		foot = goal
	world.fit_between(_top, foot)
	var left: Control = sides[LEFT[0][0]]
	var right: Control = sides[RIGHT[0][0]]
	world.inset_x = Vector2(left.get_global_rect().end.x - world.global_position.x,
		world.global_position.x + world.size.x - right.get_global_rect().position.x)


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
	if unseen < _dismissed:
		_dismissed = 0
	notice.show_raids(unseen if unseen > _dismissed else 0)
	defences_button.relabel(Strings.t("HOME_SIDE_DEFENCE"), str(unseen) if unseen > 0 else "")
	var track := ShopPresenter.track(store.get_slice(ShopState.TRACK))
	(sides[&"track"] as UniverseSide).relabel(Strings.t("HOME_SIDE_SEASON"),
		"!" if bool(track.get("can_claim", false)) else "")
	# The Islands tab counts the producers that are full (§9.3).
	var full := 0
	for p: Dictionary in store.get_slice(RosterState.ROSTER).get("view", {}).get("producers", []):
		if int(p.get("holds", 0)) > 0 and float(p.get("stored", 0)) >= UniversePurse.FULL * int(p["holds"]):
			full += 1
	tabs.set_badge("islands", str(full) if full > 0 else "")


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
		column.move_child(banner, goal.get_index())
	return sent


## A heist on the fixture realm or a leased island: not the builder's test.
func _play() -> void:
	App.services.store.dispatch(&"heist_started", {})
	App.services.router.go(&"heist")
