class_name ScoutScreen
extends Control
## The scout report (§12.4, §23.2, "Read their laws"): the chosen target's
## free facts — its laws, its guards by role, its wards by kind, its watch,
## one rough loot estimate, strain and faults — with nothing placed, and the
## button that raids it.

var controller: ObservatoryController
var body: VBoxContainer
var status_label: Label


func _ready() -> void:
	App.ready(self)
	controller = App.services.observatory_flow
	_build()
	App.services.store.changed.connect(_on_changed)
	_refresh()


func _on_changed(slice: StringName) -> void:
	if slice == ObservatoryState.OBSERVATORY and is_inside_tree():
		_refresh()


func _build() -> void:
	var column := UI.frame(self)
	column.add_child(UI.title(Strings.t("SCOUT_TITLE")))
	status_label = UI.status("info", "")
	column.add_child(UI.plate(status_label))
	body = UI.scroll(column)
	var actions := UI.row(-1.0, true)
	actions.add_child(UI.button(Strings.t("OBS_TITLE"), func() -> void: App.services.router.go(&"observatory")))
	actions.add_child(UI.button(Strings.t("COMMON_HOME"), func() -> void: App.services.router.go(&"home"), true))
	column.add_child(UI.narrow(actions))


func _refresh() -> void:
	if not is_inside_tree():
		return
	var s := ObservatoryPresenter.scout(App.services.store.get_slice(ObservatoryState.OBSERVATORY))
	for child in body.get_children():
		body.remove_child(child)
		child.queue_free()
	if not s["ready"]:
		UI.set_status(status_label, "info", Strings.t("SCOUT_NONE_CHOSEN"))
		return
	UI.set_status(status_label, "info", s["protected"])
	var box := VBoxContainer.new()
	box.add_child(UI.label(s["title"], UI.TEXT_POINTS, true))
	for line: String in s["facts"]:
		box.add_child(UI.label(line, UI.TEXT_POINTS, true))
	body.add_child(UI.plate(box))
	var realm := VBoxContainer.new()
	for line: String in s["lines"]:
		var l := UI.label(line, UI.TEXT_POINTS, true)
		l.set_meta("fact", true)
		realm.add_child(l)
	body.add_child(UI.plate(realm))
	body.add_child(RosterScreen.offer(s["raid"], false, controller.raid.bind(s["card"])))
