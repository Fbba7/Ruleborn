class_name RealmScreen
extends Control
## One realm (§23.2, "Build and shape one realm"), drawn as the diorama it is
## (§21.1): the realm's published island in 3D, each building on its tile at
## its level, who works where standing at their producers, and the law
## pylons with their laws named over them. Tapping a building opens its
## card. The same facts stay in words on the sheet below — its grid and
## terrain, wards and guard posts against its limits, buildings, workers and
## pylons — which is what a screen reader reads. The builder shapes the
## island; the Universe screen buys buildings.

const SLICES := [RealmState.REALM, UniverseState.UNIVERSE, WeavingState.WEAVING, RosterState.ROSTER]

var controller: RealmController
var body: VBoxContainer
var header_label: Label
var status_label: Label
var view: StageView
var town: StageTown
## The tapped building's card, over the sheet.
var card: PanelContainer
var card_label: Label
var _sheet: ScrollContainer
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
	view.tapped.connect(_on_tap)
	view.fill = 0.82
	town = StageTown.new(view)
	var top := VBoxContainer.new()
	top.add_child(OverlaySheet.ribbon(UI.title(Strings.t("RV_TITLE"))))
	header_label = UI.label("", UI.TEXT_POINTS, true)
	top.add_child(UI.plate(header_label))
	column.add_child(top)
	status_label = UI.status("info", "")
	column.add_child(UI.plate(status_label))
	StageScreen.window(column, 1.6)
	card_label = UI.label("", UI.TEXT_POINTS, true)
	card = UI.plate(card_label)
	card.visible = false
	column.add_child(card)
	body = UI.scroll(column)
	_sheet = StageScreen.sheet(body, 0.55)
	var actions := UI.row(-1.0, true)
	actions.add_child(UI.button(Strings.t("HOME_MAP"), func() -> void: App.services.router.go(&"map"), true))
	actions.add_child(UI.button(Strings.t("RV_CURATE"), func() -> void:
		App.services.curation_flow.open(str(App.services.store.get_slice(RealmState.REALM)["realm"]))))
	actions.add_child(UI.button(Strings.t("HOME_BUILD"), func() -> void: App.services.router.go(&"builder")))
	column.add_child(UI.narrow(OverlaySheet.dock(actions)))
	OverlaySheet.dress(self)


func _refresh() -> void:
	if not is_inside_tree():
		return
	var store := App.services.store
	var r := RealmPresenter.screen(store.get_slice(RealmState.REALM), store.get_slice(UniverseState.UNIVERSE),
		store.get_slice(WeavingState.WEAVING), store.get_slice(RosterState.ROSTER))
	_screen = r
	if r["error"] != "":
		UI.set_status(status_label, "alarm", r["error"])
	else:
		UI.set_status(status_label, "info", "" if r["ready"] else Strings.t("COMMON_LOADING"))
	(status_label.get_parent() as Control).visible = status_label.text != ""
	header_label.text = r.get("title", "")
	for child in body.get_children():
		body.remove_child(child)
		child.queue_free()
	if not r["ready"]:
		return
	for key: String in ["island", "buildings", "workers", "pylons"]:
		var box := VBoxContainer.new()
		box.set_meta("section", key)
		box.add_child(UI.label(Strings.t("RV_SECTION_" + key.to_upper()), UI.TEXT_POINTS, true))
		for line: String in r[key]:
			box.add_child(UI.label(line, UI.TEXT_POINTS, true))
		body.add_child(UI.plate(box))
	OverlaySheet.dress(body)
	OverlaySheet.unsqueeze(body)
	_draw_realm()


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
	var roles := {}
	for c: Dictionary in home.get("characters", []):
		roles[int(c["id"])] = str(c.get("role", ""))
	town.build(buildings, RealmPalette.of(view.realm_type), producers, roles)
	_pin(replay)


## A level badge over each building and its law's name over each pylon.
func _pin(replay: RulebornReplay) -> void:
	var pins := StageScreen.pins_of(view)
	pins.clear()
	for b: Dictionary in town.placed:
		var top := (b["mid"] as Vector3) + Vector3(0, 1.6 + 0.35 * int(b["side"]), 0)
		pins.pin(OverlaySheet.chip(str(int(b["level"])), Palette.MOTION), top)
	for p: Dictionary in replay.pylons():
		pins.pin(OverlaySheet.chip(Strings.term("LAW", str(p["law"])), Color(), UI.TEXT_POINTS),
			view.world_at(p["at"]) + Vector3(0, 2.0, 0))


## A tap on a building opens its card: its line from the sheet, and who
## works there; a tap elsewhere closes it.
func _on_tap(tile: Vector2i, _at: Vector2) -> void:
	var b := town.at_tile(tile)
	if b.is_empty() or not _screen.get("ready", false):
		card.visible = false
		return
	var name := UniversePresenter.building_name(str(b["kind"]))
	var lines: Array[String] = []
	for line: String in _screen["buildings"] + _screen["workers"]:
		if line.begins_with(name):
			lines.append(line)
	card_label.text = "\n".join(lines)
	card.visible = not lines.is_empty()


func _process(_delta: float) -> void:
	if _sheet != null and view != null:
		view.cover_bottom = StageScreen.covered_below(view, _sheet)
		view.cover_top = StageScreen.covered_above(view, header_label)
