class_name FirstScreen
extends Control
## The first launch (§20.1, §23.2, TD.26): one beat at a time — the title, the
## age check (its own screen), the protections the band sets, and the
## Keeper's name from the word lists — with no skip, resuming where a killed
## app left it.

var controller: FirstController
var body: VBoxContainer
var status_label: Label


func _ready() -> void:
	App.ready(self)
	controller = App.services.first_flow
	_build()
	App.services.store.changed.connect(_on_changed)
	_refresh()
	await controller.resume()


func _on_changed(slice: StringName) -> void:
	if slice == FirstState.FIRST and is_inside_tree():
		_refresh()


func _build() -> void:
	var column := UI.frame(self)
	column.add_child(UI.title(Strings.t("FIRST_TITLE")))
	status_label = UI.status("info", "")
	column.add_child(UI.plate(status_label))
	body = UI.scroll(column)


func _refresh() -> void:
	if not is_inside_tree():
		return
	var f := FirstPresenter.screen(App.services.store.get_slice(FirstState.FIRST), App.services.age.band())
	UI.set_status(status_label, "alarm" if f["error"] != "" else "info", f["error"])
	for child in body.get_children():
		body.remove_child(child)
		child.queue_free()
	var box := VBoxContainer.new()
	box.set_meta("beat", f["beat"])
	for line: String in f["lines"]:
		box.add_child(UI.label(line, UI.TEXT_POINTS, true))
	if f["beat"] == "name":
		var name := UI.label(str(f.get("name", "")), UI.TEXT_POINTS + 6, true)
		name.set_meta("name", true)
		box.add_child(name)
		for part: String in ["adjective", "noun"]:
			var words := Strings.t("FIRST_NEXT_" + part.to_upper())
			var b := UI.button(words, controller.cycle.bind(part, 1))
			b.set_meta("key", "cycle:" + part)
			box.add_child(b)
	if str(f["next"]) != "":
		var go := UI.button(f["next"], controller.keep_name if f["beat"] == "name" else controller.next, true)
		go.set_meta("key", "next")
		box.add_child(go)
	body.add_child(UI.plate(box))
