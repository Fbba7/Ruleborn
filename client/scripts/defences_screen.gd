class_name DefencesScreen
extends Control
## The defence log (§13.2, §23.2, "Rehearsal and defence log"): the season's
## raids on the player, newest first, each held or leaked with its grade, the
## haul denied, how long the defence held, who was caught and the share
## earned; Watch replay while it is kept; and Trace where the server offers
## it. Reading it clears the raid badge.

var controller: DefencesController
var body: VBoxContainer
var header_label: Label
var status_label: Label


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
	column.add_child(UI.title(Strings.t("DEFENCES_TITLE")))
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
	var d := DefencesPresenter.screen(App.services.store.get_slice(DefencesState.DEFENCES))
	if d["error"] != "":
		UI.set_status(status_label, "alarm", d["error"])
	elif d["busy"] != "" or not d["ready"]:
		UI.set_status(status_label, "info", Strings.t("COMMON_LOADING"))
	else:
		UI.set_status(status_label, "info", "")
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
