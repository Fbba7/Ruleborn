class_name RealmScreen
extends Control
## One realm (§23.2, "Build and shape one realm"), drawn as the diorama it is
## (§21.1) under the design's game interface (Screens v3's realm view): the
## realm's medallion with its level and name, its Starlight, the laws woven
## in it, and round keys to the map, the defence and the builder. The realm's
## facts — grid and terrain, wards and guard posts against their limits,
## buildings at their levels, who works where, the law pylons — sit on a
## glass tray as icons and counts, each saying its full sentence to a screen
## reader. Tapping a building or a pylon opens its card. The builder shapes
## the island; the Universe screen buys buildings.

const SLICES := [RealmState.REALM, UniverseState.UNIVERSE, WeavingState.WEAVING, RosterState.ROSTER]
## How many terrain kinds the tray names by icon before it sums the rest.
const TERRAIN_SHOWN := 4

var controller: RealmController
var body: VBoxContainer
var header_label: Label
var status_label: Label
var view: StageView
var town: StageTown
## The tapped building's card, over the tray.
var card: PanelContainer
var card_label: Label
var _sheet: ScrollContainer
var _keys: Control
var _top: Control
var _medal_holder: HBoxContainer
var _resources: HBoxContainer
var _laws: HBoxContainer
var _card_head: HBoxContainer
var _drawn_key := ""
var _screen := {}


func _ready() -> void:
	App.ready(self)
	controller = App.services.realm_flow
	_build()
	App.services.store.changed.connect(_on_changed)
	_refresh()
	await controller.load_realm()


func _on_changed(slice: StringName) -> void:
	if slice in SLICES and is_inside_tree():
		_refresh()


func _build() -> void:
	var column := UI.frame(self)
	view = StageScreen.mount(self, column)
	view.tapped.connect(func(at: Vector2) -> void: _on_tap(view.tile_at(at), at))
	view.fill = 0.6
	town = StageTown.new(view)
	column.add_child(_header())
	status_label = UI.status("info", "")
	column.add_child(UI.plate(status_label, "glass"))
	StageScreen.window(column, 1.6)
	card = UI.panel("card")
	var inside := VBoxContainer.new()
	_card_head = HBoxContainer.new()
	_card_head.add_theme_constant_override("separation", UI.px(8))
	inside.add_child(_card_head)
	card_label = UI.label("", UI.TEXT_POINTS, true)
	card_label.theme_type_variation = "Secondary"
	inside.add_child(card_label)
	card.add_child(inside)
	card.visible = false
	column.add_child(card)
	column.add_child(_tray())
	_sheet = StageScreen.sheet(body, 0.62)
	_keys = StageScreen.handle(column, _sheet)
	column.add_child(_dock())


## The realm's medallion and name at the top left, its Starlight at the top
## right, and the laws woven in it under the name.
func _header() -> Control:
	var top := VBoxContainer.new()
	top.add_theme_constant_override("separation", UI.px(4))
	var line := HBoxContainer.new()
	line.add_theme_constant_override("separation", UI.px(8))
	_medal_holder = HBoxContainer.new()
	line.add_child(_medal_holder)
	var names := VBoxContainer.new()
	names.add_theme_constant_override("separation", 0)
	names.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	names.alignment = BoxContainer.ALIGNMENT_CENTER
	var plate := UI.panel("glass")
	plate.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	var words := VBoxContainer.new()
	words.add_theme_constant_override("separation", 0)
	var title := UI.title(Strings.t("RV_TITLE"))
	title.add_theme_font_size_override("font_size", UI.text_px(22))
	title.set_meta("points", 22.0)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	title.autowrap_mode = TextServer.AUTOWRAP_OFF
	title.name = "RealmName"
	words.add_child(title)
	header_label = UI.label("", 13.0)
	header_label.theme_type_variation = "Kicker"
	header_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	words.add_child(header_label)
	plate.add_child(words)
	names.add_child(plate)
	line.add_child(names)
	_resources = HBoxContainer.new()
	_resources.alignment = BoxContainer.ALIGNMENT_END
	line.add_child(_resources)
	top.add_child(line)
	_laws = HBoxContainer.new()
	_laws.add_theme_constant_override("separation", UI.px(5))
	top.add_child(_laws)
	_top = top
	return top


## The realm's facts on a glass tray, in four sections of pills.
func _tray() -> ScrollContainer:
	var s := ScrollContainer.new()
	s.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	s.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var glass := UI.panel("glass")
	glass.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body = VBoxContainer.new()
	body.add_theme_constant_override("separation", UI.px(8))
	body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	glass.add_child(body)
	s.add_child(glass)
	return s


## The round keys above the home bar: the map, the defence, and the builder
## in gold as the screen's main action.
func _dock() -> Control:
	# A flow, so at §20.8's 200% the keys take two rows rather than widen.
	var row := HFlowContainer.new()
	row.alignment = FlowContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("h_separation", UI.px(18))
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(OverlayHud.key("screens/universe", Strings.t("RV_KEY_MAP"),
		func() -> void: App.services.router.go(&"map")))
	row.add_child(OverlayHud.key("planningactions/curatedefence", Strings.t("RV_KEY_DEFENCE"), func() -> void:
		App.services.curation_flow.open(str(App.services.store.get_slice(RealmState.REALM)["realm"]))))
	row.add_child(OverlayHud.key("realmactions/build", Strings.t("RV_KEY_BUILD"),
		func() -> void: App.services.router.go(&"builder"), "gold_round", OverlayHud.MAIN_KEY_POINTS))
	return row


func _refresh() -> void:
	if not is_inside_tree():
		return
	var store := App.services.store
	var universe: Dictionary = store.get_slice(UniverseState.UNIVERSE)
	var r := RealmPresenter.screen(store.get_slice(RealmState.REALM), universe,
		store.get_slice(WeavingState.WEAVING), store.get_slice(RosterState.ROSTER))
	_screen = r
	if r["error"] != "":
		UI.set_status(status_label, "alarm", r["error"])
	else:
		UI.set_status(status_label, "info", "" if r["ready"] else Strings.t("COMMON_LOADING"))
	(status_label.get_parent() as Control).visible = status_label.text != ""
	for child: Node in body.get_children():
		body.remove_child(child)
		child.queue_free()
	if not r["ready"]:
		return
	var id := str(store.get_slice(RealmState.REALM).get("realm", "heart"))
	var realm := RealmPresenter.realm_of(universe, id)
	_dress_header(realm, universe.get("view", {}), r)
	_fill_tray(realm, id, r)
	_draw_realm()


func _dress_header(realm: Dictionary, uv: Dictionary, r: Dictionary) -> void:
	var type := str(realm.get("type", "Heart"))
	var level := int(realm.get("level", 3))
	for c: Node in _medal_holder.get_children():
		c.queue_free()
	_medal_holder.add_child(OverlayHud.medallion(OverlayHud.realm_icon(type), level))
	var title := _top.find_child("RealmName", true, false) as Label
	title.text = UniversePresenter.realm_name(type)
	header_label.text = Strings.t("RV_LEVEL", level).to_upper()
	header_label.accessibility_name = r.get("title", "")
	for c: Node in _resources.get_children():
		c.queue_free()
	var starlight := int(uv.get("starlight", 0))
	_resources.add_child(OverlayHud.pill("resources/starlight", ShopPresenter.grouped(starlight),
		Strings.t("RV_STARLIGHT", ShopPresenter.grouped(starlight))))
	for c: Node in _laws.get_children():
		c.queue_free()
	var slots: Array = _slots()
	var woven := slots.filter(func(s: Dictionary) -> bool: return s.get("law") is String)
	_laws.add_child(OverlayHud.pill("hud/strain", Strings.t("RV_LAWS", [woven.size(), slots.size()]), "", "leather"))
	for i: int in slots.size():
		var s: Dictionary = slots[i]
		var line: String = (r["pylons"] as Array)[i] if i < (r["pylons"] as Array).size() else ""
		if s.get("law") is String:
			_laws.add_child(OverlayHud.pill(OverlayHud.law_icon(str(s["law"])), "", line))
		else:
			_laws.add_child(OverlayHud.pill("hud/plus", "", line))


## The realm's weaving slots, from the weaving slice.
func _slots() -> Array:
	var id := str(App.services.store.get_slice(RealmState.REALM).get("realm", "heart"))
	for wr: Dictionary in (App.services.store.get_slice(WeavingState.WEAVING).get("view", {}) as Dictionary) \
			.get("realms", []):
		if str(wr["realm"]) == id:
			return wr.get("slots", [])
	return []


func _fill_tray(realm: Dictionary, id: String, r: Dictionary) -> void:
	var island := RulebornIsland.new()
	var bytes: PackedByteArray = App.services.store.get_slice(RealmState.REALM).get("island", PackedByteArray())
	var have := not bytes.is_empty() and island.read(bytes)
	# Grid and terrain, and the defence against its limits.
	var sec := OverlayHud.section("island", Strings.t("RV_SECTION_ISLAND"))
	var row := OverlayHud.pills_of(sec)
	var lines: Array = r["island"]
	if have:
		row.add_child(OverlayHud.pill("hud/compass", "%d×%d" % [island.side(), island.side()], lines[0]))
		_terrain_pills(row, island, lines[1])
		var b: Dictionary = island.budget()
		row.add_child(OverlayHud.pill("hud/shield", "%d/%d" % [b["wards"][0], b["wards"][1]], lines[2]))
		row.add_child(OverlayHud.pill("crewroles/warden", "%d/%d" % [b["guards"][0], b["guards"][1]], lines[2]))
	else:
		row.add_child(OverlayHud.pill("generalui/info", lines[0], lines[0]))
	body.add_child(_held(sec))
	# Buildings at their levels; one not yet placed is drawn faint.
	sec = OverlayHud.section("buildings", Strings.t("RV_SECTION_BUILDINGS"))
	row = OverlayHud.pills_of(sec)
	var listed: Array = realm.get("buildings", [])
	for i: int in listed.size():
		var bd: Dictionary = listed[i]
		var p := OverlayHud.pill(OverlayHud.building_icon(str(bd["kind"])), str(int(bd["level"])),
			(r["buildings"] as Array)[i])
		if not (bd.get("at") is Dictionary):
			p.modulate.a = 0.6
		row.add_child(p)
	body.add_child(_held(sec))
	# Who works each producer.
	sec = OverlayHud.section("workers", Strings.t("RV_SECTION_WORKERS"))
	row = OverlayHud.pills_of(sec)
	var k := 0
	for p: Dictionary in (App.services.store.get_slice(RosterState.ROSTER).get("view", {}) as Dictionary) \
			.get("producers", []):
		if str(p["realm"]) != id:
			continue
		var n := (p.get("workers", []) as Array).size()
		row.add_child(OverlayHud.pill(OverlayHud.building_icon(str(p["kind"])), "×%d" % n,
			(r["workers"] as Array)[k] if k < (r["workers"] as Array).size() else ""))
		k += 1
	body.add_child(_held(sec))
	# The law pylons and what each holds.
	sec = OverlayHud.section("pylons", Strings.t("RV_SECTION_PYLONS"))
	row = OverlayHud.pills_of(sec)
	var slots := _slots()
	for i: int in slots.size():
		var s: Dictionary = slots[i]
		var line: String = (r["pylons"] as Array)[i] if i < (r["pylons"] as Array).size() else ""
		row.add_child(OverlayHud.pill(OverlayHud.law_icon(str(s["law"])), Strings.term("LAW", str(s["law"])), line)
			if s.get("law") is String else OverlayHud.pill("hud/plus", str(int(s["slot"])), line))
	body.add_child(_held(sec))


## A section in its own holder, as the tray's rows are counted.
static func _held(sec: Control) -> Control:
	var m := MarginContainer.new()
	m.mouse_filter = Control.MOUSE_FILTER_IGNORE
	m.add_child(sec)
	return m


## One pill a terrain kind, most-laid first, the rest summed on a last pill.
func _terrain_pills(row: HFlowContainer, island: RulebornIsland, spoken: String) -> void:
	var counts := {}
	for y: int in island.side():
		for x: int in island.side():
			var g := str(island.ground(x, y))
			if g != "" and g != "plain":
				counts[g] = int(counts.get(g, 0)) + 1
	var kinds := counts.keys()
	kinds.sort_custom(func(a: String, b: String) -> bool:
		return int(counts[a]) > int(counts[b]) or (counts[a] == counts[b] and a < b))
	var rest := 0
	for i: int in kinds.size():
		var g: String = kinds[i]
		if i < TERRAIN_SHOWN and Icons.has(OverlayHud.ground_icon(g)):
			row.add_child(OverlayHud.pill(OverlayHud.ground_icon(g), str(int(counts[g])),
				Strings.t("SCOUT_COUNT", [Strings.term("GROUND", g), int(counts[g])])))
		else:
			rest += int(counts[g])
	if rest > 0:
		row.add_child(OverlayHud.pill("realmactions/terrain", "+%d" % rest, spoken))


## The realm in 3D, rebuilt only when what it is drawn from changes.
func _draw_realm() -> void:
	var store := App.services.store
	var slice: Dictionary = store.get_slice(RealmState.REALM)
	var id := str(slice.get("realm", "heart"))
	var realm := RealmPresenter.realm_of(store.get_slice(UniverseState.UNIVERSE), id)
	var home: Dictionary = store.get_slice(RosterState.ROSTER).get("view", {})
	var bytes: PackedByteArray = slice.get("island", PackedByteArray())
	var key := "%s|%d|%s|%s" % [id, hash(bytes), hash(realm), hash(home.get("producers", []))]
	if key == _drawn_key:
		return
	_drawn_key = key
	var island := RulebornIsland.new()
	if bytes.is_empty() or not island.read(bytes):
		island.reset(clampi(int(realm.get("level", 3)), 1, 5))
	var buildings := StageRealm.buildings(island, realm.get("buildings", []))
	var replay := StageRealm.replay_of(StageRealm.without_buildings(island))
	if replay == null:
		return
	view.realm_type = StageRealm.realm_type(str(realm.get("type", "Heart")))
	view.show_replay(replay)
	var producers: Array = (home.get("producers", []) as Array).filter(func(p: Dictionary) -> bool:
		return str(p["realm"]) == id)
	var who := {}
	for c: Dictionary in home.get("characters", []):
		who[int(c["id"])] = {"kind": str(c.get("kind", "")), "role": str(c.get("role", ""))}
	town.build(buildings, RealmPalette.of(view.realm_type), producers, who)
	# Who lives here and is not at work: a realm's own Hearth, or the
	# Keeper's Spire for the Heart.
	var living: Array = (home.get("characters", []) as Array).filter(func(c: Dictionary) -> bool:
		var at := str(c.get("home", ""))
		return (at == id or (at == RosterPresenter.SPIRE and id == "heart")) \
			and str(c.get("state", "")) in ["idle", "resting"])
	town.residents(living)
	# The town, not the grid, at the middle of the screen: halfway to the
	# buildings' centre, so the island's edge still frames it.
	var middle := Vector3.ZERO
	for b: Dictionary in town.placed:
		middle += b["mid"]
	view.focus = (middle / maxf(1.0, town.placed.size()) * Vector3(0.5, 0.0, 0.5)) if not town.placed.is_empty() \
		else Vector3.ZERO
	_pin(replay)


## A level badge over each building and its law's mark over each pylon.
func _pin(replay: RulebornReplay) -> void:
	var pins := StageScreen.pins_of(view)
	pins.clear()
	for b: Dictionary in town.placed:
		var top := (b["mid"] as Vector3) + Vector3(0, 1.6 + 0.35 * int(b["side"]), 0)
		pins.pin(OverlayHud.badge(str(int(b["level"]))), top)
	for p: Dictionary in replay.pylons():
		pins.pin(OverlayHud.pill(OverlayHud.law_icon(str(p["law"])), Strings.term("LAW", str(p["law"]))),
			view.world_at(p["at"]) + Vector3(0, 2.0, 0))


## A tap on a building opens its card: its mark, name and level, its line
## and who works there; a tap on a pylon opens its law's; a tap elsewhere
## closes it.
func _on_tap(tile: Vector2i, _at: Vector2) -> void:
	var b := town.at_tile(tile)
	town.choose(b)
	card.visible = false
	if not _screen.get("ready", false):
		return
	for c: Node in _card_head.get_children():
		c.queue_free()
	for c: Node in _card_head.get_parent().get_children():
		if c is HFlowContainer:
			c.queue_free()
	var lines: Array[String] = []
	if not b.is_empty():
		var name := UniversePresenter.building_name(str(b["kind"]))
		for line: String in _screen["buildings"] + _screen["workers"]:
			if line.begins_with(name):
				lines.append(line)
		_head(OverlayHud.building_icon(str(b["kind"])), name, str(int(b["level"])))
		_card_pills(b)
	elif view.replay != null:
		# A law pylon: its line from the tray, the one naming its law.
		for p: Dictionary in view.replay.pylons():
			var at: Vector2 = p["at"]
			if Vector2i(floori(at.x), floori(at.y)) != tile:
				continue
			var law := Strings.term("LAW", str(p["law"]))
			for line: String in _screen["pylons"]:
				if line.ends_with(law):
					lines.append(line)
			_head(OverlayHud.law_icon(str(p["law"])), law, "")
			_card_head.get_parent().add_child(OverlayHud.row_of([OverlayHud.pill("hud/strain",
				", ".join(lines), ", ".join(lines))]))
	card_label.text = "\n".join(lines)
	# The card's lines are what a screen reader says; the pills show them.
	card_label.visible = false
	card.accessibility_name = card_label.text
	card.visible = not lines.is_empty()
	if card.visible:
		Motion.pop(card)


## A building card's pills: its tile, and each worker by name.
func _card_pills(b: Dictionary) -> void:
	var at: Vector2i = b.get("at", Vector2i(-1, -1))
	var pills: Array[Control] = []
	if at.x >= 0:
		pills.append(OverlayHud.pill("hud/compass", "%d, %d" % [at.x, at.y]))
	var home: Dictionary = App.services.store.get_slice(RosterState.ROSTER).get("view", {})
	var named := RosterPresenter.names(home.get("characters", []))
	var id := str(App.services.store.get_slice(RealmState.REALM).get("realm", "heart"))
	for p: Dictionary in home.get("producers", []):
		if str(p["realm"]) == id and str(p["kind"]) == str(b["kind"]):
			for w: Variant in p.get("workers", []):
				pills.append(OverlayHud.pill("characterstates/working", str(named.get(int(w), ""))))
	if not pills.is_empty():
		_card_head.get_parent().add_child(OverlayHud.row_of(pills))


## The card's head: a mark, a name in the title face, and a level badge.
func _head(icon: String, name: String, level: String) -> void:
	_card_head.add_child(Icons.view(icon, 40.0))
	var l := UI.label(name, 20.0)
	l.theme_type_variation = "Heading"
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_card_head.add_child(l)
	if level != "":
		_card_head.add_child(OverlayHud.badge(level))


func _process(_delta: float) -> void:
	if _sheet != null and view != null:
		view.cover_bottom = StageScreen.covered_below(view, _keys)
		view.cover_top = StageScreen.covered_above(view, _top)
