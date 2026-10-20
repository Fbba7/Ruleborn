class_name DefencesScreen
extends Control
## The defence log (§13.2, §23.2, "Rehearsal and defence log"): the season's
## raids on the player, newest first, each held or leaked with its grade, the
## haul denied, how long the defence held, who was caught and the share
## earned; Watch replay while it is kept; and Trace where the server offers
## it. Reading it clears the raid badge.
##
## Behind the log stands the defence it records: the player's own island with
## the defence overlay (`OverlayDefence`), its posts numbered and its wards
## marked, from the curation draft, the realm view's island or the builder's
## draft, whichever the phone holds. A tap on a post shows its guard's sight.

var controller: DefencesController
var body: VBoxContainer
var header_label: Label
var status_label: Label
var view: StageView
var defence: OverlayDefence
var _sheet: ScrollContainer
var _keys: Control
var _top: Control
var _drawn_key := ""
var _island: RulebornIsland


func _ready() -> void:
	App.ready(self)
	controller = App.services.defences_flow
	_build()
	App.services.store.changed.connect(_on_changed)
	_refresh()
	await controller.load_log()


func _on_changed(slice: StringName) -> void:
	if slice == DefencesState.DEFENCES and is_inside_tree():
		_refresh()


func _build() -> void:
	var column := UI.frame(self)
	view = StageScreen.mount(self, column)
	view.fill = 0.86
	defence = OverlayDefence.new(view)
	view.tapped.connect(func(at: Vector2) -> void: _on_tap(view.tile_at(at)))
	header_label = UI.label("", UI.TEXT_POINTS, true)
	_top = OverlaySheet.ribbon(UI.title(Strings.t("DEFENCES_TITLE")), header_label)
	column.add_child(_top)
	status_label = UI.status("info", "")
	column.add_child(UI.plate(status_label))
	StageScreen.window(column, 1.2)
	body = UI.scroll(column)
	_sheet = StageScreen.sheet(body, 0.62)
	var actions := UI.row(-1.0, true)
	actions.add_child(UI.button(Strings.t("COMMON_HOME"), func() -> void: App.services.router.go(&"home"), true))
	_keys = StageScreen.handle(column, _sheet)
	column.add_child(UI.narrow(OverlaySheet.dock(actions)))
	OverlaySheet.dress(self)
	_draw_world()


func _refresh() -> void:
	if not is_inside_tree():
		return
	var d := DefencesPresenter.screen(App.services.store.get_slice(DefencesState.DEFENCES))
	if d["error"] != "":
		UI.set_status(status_label, "alarm", d["error"])
	elif d["busy"] != "" or not d["ready"]:
		UI.set_status(status_label, "info", Strings.t("COMMON_LOADING"))
	else:
		UI.set_status(status_label, "info", "")
	(status_label.get_parent() as Control).visible = status_label.text != ""
	header_label.text = d.get("header", "")
	for child in body.get_children():
		body.remove_child(child)
		child.queue_free()
	if not d["ready"]:
		return
	var busy: bool = d["busy"] != ""
	if d.has("empty"):
		body.add_child(UI.plate(UI.label(d["empty"], UI.TEXT_POINTS, true)))
	for r: Dictionary in d["raids"]:
		body.add_child(_raid(r, busy))
	OverlaySheet.dress(body)
	OverlaySheet.unsqueeze(body)


func _raid(r: Dictionary, busy: bool) -> Control:
	var box := VBoxContainer.new()
	var title := UI.label(r["title"] + (Strings.t("DEFENCES_NEW") if r["new"] else ""), UI.TEXT_POINTS, true)
	title.set_meta("heist", r["heist"])
	box.add_child(title)
	for line: String in r["lines"]:
		box.add_child(UI.label(line, UI.TEXT_POINTS, true))
	if not (r["watch"] as Dictionary).is_empty():
		box.add_child(RosterScreen.offer(r["watch"], busy, controller.watch.bind(r["raid"])))
	if not (r["trace"] as Dictionary).is_empty():
		box.add_child(RosterScreen.offer(r["trace"], busy, controller.trace.bind(r["raid"])))
	return UI.plate(box)


## The island the phone holds for the player's own defence: the curation
## draft, else the realm view's island, else the builder's draft.
static func own_island() -> PackedByteArray:
	var store := App.services.store
	for bytes: Variant in [store.get_slice(CurationState.CURATION).get("draft", PackedByteArray()),
			store.get_slice(RealmState.REALM).get("island", PackedByteArray()), Draft.island()]:
		if bytes is PackedByteArray and not (bytes as PackedByteArray).is_empty():
			return bytes
	return PackedByteArray()


## The player's defence in 3D, with its overlay.
func _draw_world() -> void:
	var bytes := own_island()
	var key := str(hash(bytes))
	if key == _drawn_key:
		return
	_drawn_key = key
	var island := RulebornIsland.new()
	if bytes.is_empty() or not island.read(bytes):
		island.reset(3)
	var replay := StageRealm.replay_of(island.bytes())
	if replay == null:
		return
	view.show_replay(replay)
	_island = island
	defence.draw(island, replay, CurationState.NO_POST, {})


## A tap on a post shows that guard's sight (§21.12), a tap elsewhere the
## first guard's: the defence the log records, read post by post.
func _on_tap(tile: Vector2i) -> void:
	if _island == null or view.replay == null:
		return
	var post := tile if str(_island.occupant(tile.x, tile.y)).begins_with("guard:") else CurationState.NO_POST
	defence.draw(_island, view.replay, post, {})


func _process(_delta: float) -> void:
	if _sheet != null and view != null:
		view.cover_bottom = StageScreen.covered_below(view, _keys)
		view.cover_top = StageScreen.covered_above(view, _top)
