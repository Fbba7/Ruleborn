class_name HarmonyScreen
extends Control
## The Harmony view (§23.2, "See how laws combine"): the universe's strain,
## then each realm's laws with their notes, and the harmonies, clashes,
## resonances and chords they make, each with what it does to its laws'
## cost. It changes nothing; Weaving does.

var controller: HarmonyController
var body: VBoxContainer
var header_label: Label
var status_label: Label


func _ready() -> void:
	App.ready(self)
	controller = App.services.harmony_flow
	_build()
	App.services.store.changed.connect(_on_changed)
	_refresh()
	await controller.load_harmony()


func _on_changed(slice: StringName) -> void:
	if slice == HarmonyState.HARMONY and is_inside_tree():
		_refresh()


func _build() -> void:
	var column := UI.frame(self)
	column.add_child(UI.title(Strings.t("HARMONY_TITLE")))
	header_label = UI.label("", UI.TEXT_POINTS, true)
	column.add_child(UI.plate(header_label))
	status_label = UI.status("info", "")
	column.add_child(UI.plate(status_label))
	body = UI.scroll(column)
	var actions := UI.row(-1.0, true)
	actions.add_child(UI.button(Strings.t("HOME_WEAVING"), func() -> void: App.services.router.go(&"weaving")))
	actions.add_child(UI.button(Strings.t("COMMON_HOME"), func() -> void: App.services.router.go(&"home"), true))
	column.add_child(UI.narrow(actions))


func _refresh() -> void:
	if not is_inside_tree():
		return
	var h := HarmonyPresenter.screen(App.services.store.get_slice(HarmonyState.HARMONY))
	if h["error"] != "":
		UI.set_status(status_label, "alarm", h["error"])
	elif h["busy"] or not h["ready"]:
		UI.set_status(status_label, "info", Strings.t("COMMON_LOADING"))
	else:
		UI.set_status(status_label, "info", "")
	header_label.text = h.get("header", "")
	for child in body.get_children():
		body.remove_child(child)
		child.queue_free()
	if not h["ready"]:
		return
	for r: Dictionary in h["realms"]:
		var box := VBoxContainer.new()
		var title := UI.label(r["title"], UI.TEXT_POINTS, true)
		title.set_meta("realm", r["realm"])
		box.add_child(title)
		for line: String in r["laws"]:
			box.add_child(UI.label(line, UI.TEXT_POINTS, true))
		for line: String in r["lines"]:
			var l := UI.label(line, UI.TEXT_POINTS, true)
			l.set_meta("combination", true)
			box.add_child(l)
		body.add_child(UI.plate(box))
