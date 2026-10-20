class_name MapScreen
extends Control
## The Universe map (§23.2, "Home. See every realm and link at once."): the
## universe in 3D — every realm and its buildings, the links between them,
## the faults, what is ready and the alerts as pins (`UniverseView`) — and
## under it the same in words, which a screen reader reads and the player can
## scroll: each realm with its laws and the crown's, the strain band and open
## faults, resources and what each producer has ready, the alerts, and the
## way to a heist. A tap on a realm in the world brings its words into view.

const SLICES := [WeavingState.WEAVING, RosterState.ROSTER, ShopState.WALLET, DefencesState.DEFENCES,
	UniverseState.UNIVERSE]

var controller: MapController
var body: VBoxContainer
var header_label: Label
var status_label: Label
## The universe behind the words.
var world: UniverseView

var _top: Control
var _sheet: Control


func _ready() -> void:
	App.ready(self)
	controller = App.services.map_flow
	_build()
	App.services.store.changed.connect(_on_changed)
	_refresh()
	await controller.load_all()
	if is_inside_tree():
		await App.services.universe_flow.load_universe()


func _on_changed(slice: StringName) -> void:
	if slice in SLICES and is_inside_tree():
		_refresh()


func _build() -> void:
	var column := UI.frame(self)
	world = UniverseView.behind(self, column)
	world.next_chosen.connect(func() -> void: App.services.router.go(&"universe"))
	world.realm_chosen.connect(_show_realm)
	# The title, the header and the status on one plate at the top.
	var words := VBoxContainer.new()
	words.add_child(UI.title(Strings.t("MAP_TITLE")))
	header_label = UI.label("", UI.TEXT_POINTS, true)
	words.add_child(header_label)
	status_label = UI.status("info", "")
	words.add_child(status_label)
	var top := UI.plate(words)
	top.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_child(top)
	_top = top
	var room := UI.grow()
	room.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_child(room)
	body = UI.scroll(column)
	# The words take the lower part of the screen; the world, the rest.
	_sheet = body.get_parent() as Control
	_sheet.size_flags_stretch_ratio = 0.5
	var actions := UI.row(-1.0, true)
	actions.add_child(UI.button(Strings.t("COMMON_HOME"), func() -> void: App.services.router.go(&"home"), true))
	column.add_child(UI.narrow(actions))
	column.sort_children.connect(func() -> void: world.fit_between(_top, _sheet))


func _refresh() -> void:
	if not is_inside_tree():
		return
	var store := App.services.store
	var m := MapPresenter.screen(store.get_slice(WeavingState.WEAVING), store.get_slice(RosterState.ROSTER),
		store.get_slice(ShopState.WALLET), store.get_slice(DefencesState.DEFENCES))
	_draw_world()
	UI.set_status(status_label, "info", "" if m["ready"] else Strings.t("COMMON_LOADING"))
	status_label.visible = status_label.text != ""
	header_label.text = m.get("strain", "")
	for child in body.get_children():
		body.remove_child(child)
		child.queue_free()
	if not m["ready"]:
		return
	var alerts := VBoxContainer.new()
	for line: String in m["alerts"]:
		alerts.add_child(UI.label(line, UI.TEXT_POINTS, true))
	body.add_child(UI.plate(alerts))
	for r: Dictionary in m["realms"]:
		var box := VBoxContainer.new()
		var title := UI.label(r["title"], UI.TEXT_POINTS, true)
		title.set_meta("realm", r["realm"])
		box.add_child(title)
		box.add_child(UI.label(r["laws"], UI.TEXT_POINTS, true))
		box.add_child(RosterScreen.offer(r["open"], false, controller.services.realm_flow.open.bind(str(r["realm"]))))
		body.add_child(UI.plate(box))
	var held := VBoxContainer.new()
	for line: String in ([m["crown"], m["resources"]] + m["ready_lines"]) as Array:
		if str(line) != "":
			held.add_child(UI.label(str(line), UI.TEXT_POINTS, true))
	body.add_child(UI.plate(held))
	body.add_child(UI.plate(RosterScreen.offer(m["heist"], false, func() -> void:
		App.services.router.go(&"observatory"))))


## The universe in 3D, as the store holds it, and said in words.
func _draw_world() -> void:
	var store := App.services.store
	var view := UniverseStore.view(store)
	world.show_universe(view, UniverseStore.extras(store))
	world.accessibility_name = Strings.t("MAP_TITLE")
	world.accessibility_description = UniverseStore.spoken(view)


## A realm tapped in the world: its words scrolled into view.
func _show_realm(id: String) -> void:
	for l: Label in body.find_children("*", "Label", true, false):
		if str(l.get_meta("realm", "")) == id:
			(_sheet as ScrollContainer).ensure_control_visible(l)
			return
