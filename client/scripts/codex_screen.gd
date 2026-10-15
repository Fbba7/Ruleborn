class_name CodexScreen
extends Control
## The Codex (§7.6, §18.5, §23.2): the Keeper's Aether, Keeper level and
## Spire; when the next chapter opens; the law worked on; and each school's
## album — its shape and name, its restored count and milestones, its mastery
## track, and its laws, a "?" until met. Restoring a law or raising its tier
## spends on a second tap; marking it worked on takes one; a law met opens its
## law card. Every number is the server's.

var controller: CodexController
var body: VBoxContainer
var header_label: Label
var status_label: Label
## The spend tapped once, by its key: the next tap on it spends.
var confirm := ""


func _ready() -> void:
	App.ready(self)
	controller = App.services.codex_flow
	_build()
	App.services.store.changed.connect(_on_changed)
	_refresh()
	await controller.load_codex()


func _on_changed(slice: StringName) -> void:
	if slice == CodexState.CODEX and is_inside_tree():
		_refresh()


func _build() -> void:
	var column := UI.frame(self)
	column.add_child(UI.title(Strings.t("CODEX_TITLE")))
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
	var focused := get_viewport().gui_get_focus_owner()
	var focus_item := str(focused.get_meta("item", "")) if focused != null else ""
	var c := CodexPresenter.screen(App.services.store.get_slice(CodexState.CODEX))
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
	top.add_child(UI.label(c["chapter"], UI.TEXT_POINTS, true))
	top.add_child(UI.label(c["working"], UI.TEXT_POINTS, true))
	body.add_child(UI.plate(top))
	for a: Dictionary in c["albums"]:
		body.add_child(_album(a, busy))
	if focus_item != "":
		for b: Button in find_children("*", "Button", true, false):
			if b.get_meta("item", "") == focus_item and b.is_visible_in_tree():
				b.grab_focus.call_deferred()
				break


## A school's album: its mark and count, milestones, mastery, and laws.
func _album(a: Dictionary, busy: bool) -> Control:
	var box := VBoxContainer.new()
	var title := UI.label(a["title"], UI.TEXT_POINTS, true)
	title.set_meta("school", a["school"])
	box.add_child(title)
	box.add_child(UI.label(a["count"], UI.TEXT_POINTS, true))
	for line: String in a["milestones"]:
		box.add_child(UI.label(line, UI.TEXT_POINTS, true))
	box.add_child(UI.label(a["mastery"], UI.TEXT_POINTS, true))
	box.add_child(UI.label(a["marks"], UI.TEXT_POINTS, true))
	for l: Dictionary in a["laws"]:
		box.add_child(UI.label(l["text"], UI.TEXT_POINTS, true))
		if l.has("card"):
			box.add_child(RosterScreen.offer(l["card"], false,
				App.services.router.go.bind(&"law", {"law": str(l["law"])})))
		if not (l["act"] as Dictionary).is_empty():
			var shown: Dictionary = (l["act"] as Dictionary).duplicate()
			if confirm == shown["key"]:
				shown["action"] = Strings.t("CODEX_CONFIRM", shown["cost"])
				shown["spoken"] = Strings.t("CODEX_CONFIRM_SPOKEN", [shown["spoken"], shown["cost"]])
			box.add_child(RosterScreen.offer(shown, busy, _tap.bind(l["act"])))
		if not (l["work"] as Dictionary).is_empty():
			box.add_child(RosterScreen.offer(l["work"], busy, controller.work_on.bind(str(l["law"]))))
		elif l["worked"]:
			box.add_child(UI.label(l["worked_text"], UI.TEXT_POINTS, true))
	return UI.plate(box)


## A spend's first tap shows its price to confirm; the second spends it.
func _tap(o: Dictionary) -> void:
	if confirm != o["key"]:
		confirm = o["key"]
		_refresh()
		return
	confirm = ""
	var a: Dictionary = o["args"]
	if int(a["to"]) == 1:
		await controller.restore(str(a["law"]))
	else:
		await controller.tier(str(a["law"]), int(a["to"]))
