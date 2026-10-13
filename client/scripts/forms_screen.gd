class_name FormsScreen
extends Control
## The Forms album (§23.2, "The creature collection"): how many of the 54
## forms the player has hatched; each note's look, quirk, symbol and the
## launch laws that hatch it; each kind's three forms and its outfit; each
## note's skiff sail; and "Show mine". Trades come with version 1.1 (§11.10).
## It draws the store; Services' `forms_flow` asks.

var controller: FormsController
var body: VBoxContainer
var header_label: Label
var status_label: Label
var toggle: Button


func _ready() -> void:
	App.ready(self)
	controller = App.services.forms_flow
	_build()
	App.services.store.changed.connect(_on_changed)
	_refresh()
	await controller.load_album()


func _on_changed(slice: StringName) -> void:
	if slice == FormsState.FORMS and is_inside_tree():
		_refresh()


func _build() -> void:
	var column := UI.frame(self)
	column.add_child(UI.title(Strings.t("FORMS_TITLE")))
	header_label = UI.label("", UI.TEXT_POINTS, true)
	column.add_child(UI.plate(header_label))
	status_label = UI.status("info", "")
	column.add_child(UI.plate(status_label))
	body = UI.scroll(column)
	var actions := UI.row(-1.0, true)
	toggle = UI.button(Strings.t("FORMS_SHOW_MINE"), _toggle)
	UI.fit_to(toggle, [Strings.t("FORMS_SHOW_ALL")])
	actions.add_child(toggle)
	actions.add_child(UI.button(Strings.t("COMMON_HOME"), func() -> void: App.services.router.go(&"home"), true))
	column.add_child(UI.narrow(actions))


func _toggle() -> void:
	controller.show_mine(not bool(App.services.store.get_slice(FormsState.FORMS)["mine"]))


func _refresh() -> void:
	if not is_inside_tree():
		return
	var a := FormsPresenter.screen(App.services.store.get_slice(FormsState.FORMS))
	if a["error"] != "":
		UI.set_status(status_label, "alarm", a["error"])
	elif a["busy"] != "" or not a["ready"]:
		UI.set_status(status_label, "info", Strings.t("COMMON_LOADING"))
	else:
		UI.set_status(status_label, "info", "")
	header_label.text = a.get("header", "")
	UI.relabel(toggle, a["toggle"]["action"], true)
	toggle.set_meta("mine", a["mine"])
	for c in body.get_children():
		body.remove_child(c)
		c.queue_free()
	if not a["ready"]:
		return
	for n: Dictionary in a["notes"]:
		var box := VBoxContainer.new()
		for line: String in [n["title"], n["look"], n["quirk"], n["how"]]:
			box.add_child(UI.label(line, UI.TEXT_POINTS, true))
		body.add_child(UI.plate(box))
	for k: Dictionary in a["kinds"]:
		var box := VBoxContainer.new()
		box.add_child(UI.label(k["title"], UI.TEXT_POINTS, true))
		box.add_child(UI.label(k["outfit"], UI.TEXT_POINTS, true))
		for f: Dictionary in k["forms"]:
			var line := UI.label(f["text"], UI.TEXT_POINTS, true)
			line.set_meta("form", "%s/%s" % [k["kind"], f["note"]])
			box.add_child(line)
		body.add_child(UI.plate(box))
	var sails := VBoxContainer.new()
	sails.add_child(UI.label(Strings.t("FORMS_SAILS_TITLE"), UI.TEXT_POINTS, true))
	for s: String in a["sails"]:
		sails.add_child(UI.label(s, UI.TEXT_POINTS, true))
	body.add_child(UI.plate(sails))
