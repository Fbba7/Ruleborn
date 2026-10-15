class_name CurationScreen
extends Control
## Curation (§13.3, §23.2), "the default creative act", in words until the
## world draws it: the island's origin and name, the generator's layouts,
## each guard post — a tap picks it for the four-way dial and its moves —
## each woven law with its swaps, previewed free and applied as a weave
## that spends on a second tap, and the draft's save and revert.

var controller: CurationController
var body: VBoxContainer
var header_label: Label
var status_label: Label
## The paid apply tapped once: the next tap spends.
var confirm := ""


func _ready() -> void:
	App.ready(self)
	controller = App.services.curation_flow
	_build()
	App.services.store.changed.connect(_on_changed)
	_refresh()
	await controller.load_curation()


func _on_changed(slice: StringName) -> void:
	if slice == CurationState.CURATION and is_inside_tree():
		_refresh()


func _build() -> void:
	var column := UI.frame(self)
	column.add_child(UI.title(Strings.t("CUR_TITLE")))
	header_label = UI.label("", UI.TEXT_POINTS, true)
	column.add_child(UI.plate(header_label))
	status_label = UI.status("info", "")
	column.add_child(UI.plate(status_label))
	body = UI.scroll(column)
	var actions := UI.row(-1.0, true)
	actions.add_child(UI.button(Strings.t("HOME_MAP"), func() -> void: App.services.router.go(&"map"), true))
	actions.add_child(UI.button(Strings.t("COMMON_HOME"), func() -> void: App.services.router.go(&"home")))
	column.add_child(UI.narrow(actions))


func _refresh() -> void:
	if not is_inside_tree():
		return
	var focused := get_viewport().gui_get_focus_owner()
	var focus_item := str(focused.get_meta("item", "")) if focused != null else ""
	var c := CurationPresenter.screen(App.services.store.get_slice(CurationState.CURATION))
	if c["error"] != "":
		UI.set_status(status_label, "alarm", c["error"])
	elif c["said"] != "":
		UI.set_status(status_label, "success", c["said"])
	elif c["busy"] != "" or not c["ready"]:
		UI.set_status(status_label, "info", Strings.t("COMMON_LOADING"))
	else:
		UI.set_status(status_label, "info", "")
	header_label.text = c.get("header", "")
	for child in body.get_children():
		body.remove_child(child)
		child.queue_free()
	if not c["ready"]:
		return
	var busy: bool = c["busy"] != ""
	var top := VBoxContainer.new()
	top.add_child(UI.label(c["origin"], UI.TEXT_POINTS, true))
	top.add_child(UI.label(c["name"], UI.TEXT_POINTS, true))
	body.add_child(UI.plate(top))
	_section("layouts", Strings.t("CUR_LAYOUTS"), c["layouts"], busy, _lay)
	if not (c["posts"] as Array).is_empty():
		var posts := _section("posts", Strings.t("CUR_POSTS"), c["posts"], busy, _pick)
		for o: Dictionary in c["dial"]:
			posts.add_child(RosterScreen.offer(o, busy, _dial.bind(o)))
	for row: Dictionary in c["laws"]:
		var box := _section("law:%d" % row["slot"], row["text"], row["offers"], busy, _preview.bind(int(row["slot"])))
		if row.has("preview"):
			box.add_child(UI.label(row["preview"], UI.TEXT_POINTS, true))
			var shown: Dictionary = (row["apply"] as Dictionary).duplicate()
			if confirm == "apply" and str(shown["cost"]) != "":
				shown["action"] = Strings.t("CODEX_CONFIRM", shown["cost"])
				shown["spoken"] = Strings.t("CODEX_CONFIRM_SPOKEN", [shown["spoken"], shown["cost"]])
			box.add_child(RosterScreen.offer(shown, busy, _apply.bind(row["apply"])))
	if not (c["changes"] as Dictionary).is_empty():
		var ch: Dictionary = c["changes"]
		var box := VBoxContainer.new()
		box.set_meta("section", "changes")
		box.add_child(UI.label(ch["line"], UI.TEXT_POINTS, true))
		box.add_child(RosterScreen.offer(ch["save"], busy, func() -> void: await controller.save()))
		box.add_child(RosterScreen.offer(ch["revert"], busy, controller.revert))
		body.add_child(UI.plate(box))
	if not (c["naming"] as Dictionary).is_empty():
		_naming(c["naming"], busy)
	if focus_item != "":
		for b: Button in find_children("*", "Button", true, false):
			if b.get_meta("item", "") == focus_item and b.is_visible_in_tree():
				b.grab_focus.call_deferred()
				break


## A plate titled `title` with a button for each of `offers`, each calling
## `pressed` with its offer.
func _section(key: String, title: String, offers: Array, busy: bool, pressed: Callable) -> VBoxContainer:
	var box := VBoxContainer.new()
	box.set_meta("section", key)
	box.add_child(UI.label(title, UI.TEXT_POINTS, true))
	for o: Dictionary in offers:
		box.add_child(RosterScreen.offer(o, busy, pressed.bind(o)))
	body.add_child(UI.plate(box))
	return box


func _naming(n: Dictionary, busy: bool) -> void:
	var box := VBoxContainer.new()
	box.set_meta("section", "naming")
	box.add_child(UI.label(Strings.t("CUR_NAMING"), UI.TEXT_POINTS, true))
	var words := UI.row()
	words.add_child(UI.button(Strings.t("CUR_NEXT_ADJECTIVE"), controller.cycle_name.bind("adjective")))
	words.add_child(UI.button(Strings.t("CUR_NEXT_NOUN"), controller.cycle_name.bind("noun")))
	box.add_child(words)
	box.add_child(RosterScreen.offer(n["give"], busy, func() -> void: await controller.name_island()))
	body.add_child(UI.plate(box))


func _lay(o: Dictionary) -> void:
	if str(o["seed"]) == "":
		await controller.more_layouts()
	else:
		await controller.lay(str(o["seed"]))


func _pick(o: Dictionary) -> void:
	controller.pick_post(o["at"])


func _dial(o: Dictionary) -> void:
	if o.has("facing"):
		controller.face_post(int(o["facing"]))
	else:
		controller.move_post(o["step"])


func _preview(o: Dictionary, slot: int) -> void:
	confirm = ""
	controller.preview_swap(slot, str(o["law"]))


## A swap's first tap shows its price to confirm; the second weaves it.
func _apply(o: Dictionary) -> void:
	if str(o["cost"]) != "" and confirm != "apply":
		confirm = "apply"
		_refresh()
		return
	confirm = ""
	await controller.apply_swap()
