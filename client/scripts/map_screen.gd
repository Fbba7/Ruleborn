class_name MapScreen
extends Control
## The Universe map (§23.2, "Home. See every realm and link at once."), in
## words until the world draws it (TD.19): each realm with its laws and the
## crown's, the strain band and open faults, resources and what each
## producer has ready, the alerts, and the way to a heist.

const SLICES := [WeavingState.WEAVING, RosterState.ROSTER, ShopState.WALLET, DefencesState.DEFENCES]

var controller: MapController
var body: VBoxContainer
var header_label: Label
var status_label: Label


func _ready() -> void:
	App.ready(self)
	controller = App.services.map_flow
	_build()
	App.services.store.changed.connect(_on_changed)
	_refresh()
	await controller.load_all()


func _on_changed(slice: StringName) -> void:
	if slice in SLICES and is_inside_tree():
		_refresh()


func _build() -> void:
	var column := UI.frame(self)
	column.add_child(UI.title(Strings.t("MAP_TITLE")))
	header_label = UI.label("", UI.TEXT_POINTS, true)
	column.add_child(UI.plate(header_label))
	status_label = UI.status("info", "")
	column.add_child(UI.plate(status_label))
	body = UI.scroll(column)
	var actions := UI.row(-1.0, true)
	actions.add_child(UI.button(Strings.t("COMMON_HOME"), func() -> void: App.services.router.go(&"home"), true))
	column.add_child(UI.narrow(actions))


func _refresh() -> void:
	if not is_inside_tree():
		return
	var store := App.services.store
	var m := MapPresenter.screen(store.get_slice(WeavingState.WEAVING), store.get_slice(RosterState.ROSTER),
		store.get_slice(ShopState.WALLET), store.get_slice(DefencesState.DEFENCES))
	UI.set_status(status_label, "info", "" if m["ready"] else Strings.t("COMMON_LOADING"))
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
