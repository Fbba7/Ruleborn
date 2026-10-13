class_name SageHallScreen
extends Control
## The Sage hall (§23.2, "Heroes"): the Sages' level, which is the Keeper's;
## each Sage's heist powers and at-home effect, and what every fifth level
## adds, those reached marked in words; when a locked Sage unlocks; and which
## Sage guards the Heart (§11.7). It draws the store; Services' `sage_flow`
## asks.

var controller: SageController
var body: VBoxContainer
var header_label: Label
var guard_label: Label
var status_label: Label


func _ready() -> void:
	App.ready(self)
	controller = App.services.sage_flow
	_build()
	App.services.store.changed.connect(_on_changed)
	_refresh()
	await controller.load_sages()


func _on_changed(slice: StringName) -> void:
	if slice == SageState.SAGES and is_inside_tree():
		_refresh()


func _build() -> void:
	var column := UI.frame(self)
	column.add_child(UI.title(Strings.t("SAGE_TITLE")))
	var top := VBoxContainer.new()
	header_label = UI.label("", UI.TEXT_POINTS, true)
	top.add_child(header_label)
	guard_label = UI.label("", UI.TEXT_POINTS, true)
	top.add_child(guard_label)
	column.add_child(UI.plate(top))
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
	var h := SagePresenter.screen(App.services.store.get_slice(SageState.SAGES))
	if h["error"] != "":
		UI.set_status(status_label, "alarm", h["error"])
	elif h["said"] != "":
		UI.set_status(status_label, "success", h["said"])
	elif h["busy"] != "" or not h["ready"]:
		UI.set_status(status_label, "info", Strings.t("COMMON_LOADING"))
	else:
		UI.set_status(status_label, "info", "")
	header_label.text = h.get("header", "")
	guard_label.text = h.get("guard", "")
	for c in body.get_children():
		body.remove_child(c)
		c.queue_free()
	if not h["ready"]:
		return
	var busy: bool = h["busy"] != ""
	for s: Dictionary in h["sages"]:
		body.add_child(_sage(s, busy))
	if focus_item != "":
		for b: Button in find_children("*", "Button", true, false):
			if b.get_meta("item", "") == focus_item and b.is_visible_in_tree():
				b.grab_focus.call_deferred()
				break


func _sage(s: Dictionary, busy: bool) -> Control:
	var box := VBoxContainer.new()
	box.add_child(UI.label(s["name"], UI.TEXT_POINTS, true))
	box.add_child(UI.status("success" if s["unlocked"] else "info", s["lock"]))
	if s["guarding"]:
		box.add_child(UI.status("success", Strings.t("SAGE_ON_GUARD")))
		box.add_child(UI.label(Strings.t("SAGE_STAYS"), UI.TEXT_POINTS, true))
	box.add_child(UI.label(s["powers"], UI.TEXT_POINTS, true))
	box.add_child(UI.label(s["home"], UI.TEXT_POINTS, true))
	box.add_child(UI.label(Strings.t("SAGE_EVERY_FIFTH"), UI.TEXT_POINTS, true))
	for lv: Dictionary in s["levels"]:
		var line := UI.label(lv["text"], UI.TEXT_POINTS, true)
		line.set_meta("reached", lv["reached"])
		box.add_child(line)
	var o: Dictionary = s["button"]
	var b := UI.button(o["action"], controller.station.bind(o["sage"]), false, Color(), o["spoken"])
	b.disabled = busy or not o["can"]
	b.set_meta("key", o["key"])
	b.set_meta("item", o["item"])
	var r := UI.row()
	r.add_child(b)
	if o["why"] != "":
		r.add_child(UI.label(o["why"], UI.TEXT_POINTS, true))
	box.add_child(r)
	return UI.plate(box)
