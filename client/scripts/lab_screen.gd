class_name LabScreen
extends Control
## The Resonance Lab (§8.6, §10.2, §23.2, "Run experiments"): the Lab's
## level and Aether and the next experiment's price and time; each chamber,
## running with its time left and any paradox warning, or idle with its
## spheres — a tap moves a sphere to the next restored law — and the button
## that runs it, which spends on a second tap; each chamber's last result
## and hint; from Lab level 3 the third sphere, which names a chord free; and
## what has been found, hinted and remains by school.

var controller: LabController
var body: VBoxContainer
var header_label: Label
var status_label: Label
## The run tapped once, by its key: the next tap on it spends.
var confirm := ""
var clock: Callable = func() -> int: return int(Time.get_unix_time_from_system() * 1000)


func _ready() -> void:
	App.ready(self)
	controller = App.services.lab_flow
	_build()
	App.services.store.changed.connect(_on_changed)
	_refresh()
	await controller.load_lab()


func _on_changed(slice: StringName) -> void:
	if slice == LabState.LAB and is_inside_tree():
		_refresh()


func _build() -> void:
	var column := UI.frame(self)
	column.add_child(UI.title(Strings.t("LAB_TITLE")))
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
	var l := LabPresenter.screen(App.services.store.get_slice(LabState.LAB), clock.call())
	if l["error"] != "":
		UI.set_status(status_label, "alarm", l["error"])
	elif l["said"] != "":
		UI.set_status(status_label, "success", l["said"])
	elif l["busy"] != "" or not l["ready"]:
		UI.set_status(status_label, "info", Strings.t("COMMON_LOADING"))
	else:
		UI.set_status(status_label, "info", "")
	header_label.text = l.get("header", "")
	for child in body.get_children():
		body.remove_child(child)
		child.queue_free()
	if not l["ready"]:
		return
	var busy: bool = l["busy"] != ""
	var top := VBoxContainer.new()
	for key: String in ["none", "terms", "chords"]:
		if str(l.get(key, "")) != "":
			top.add_child(UI.label(l[key], UI.TEXT_POINTS, true))
	body.add_child(UI.plate(top))
	for c: Dictionary in l["chambers"]:
		body.add_child(_chamber(c, busy))
	if not (l.get("sphere", {}) as Dictionary).is_empty():
		var sphere := VBoxContainer.new()
		sphere.add_child(UI.label(Strings.t("LAB_SPHERE_TITLE"), UI.TEXT_POINTS, true))
		sphere.add_child(RosterScreen.offer(l["sphere"], busy, controller.name_chord))
		body.add_child(UI.plate(sphere))
	var found := VBoxContainer.new()
	found.add_child(UI.label(Strings.t("LAB_FOUND_TITLE"), UI.TEXT_POINTS, true))
	for line: String in l["found"]:
		found.add_child(UI.label(line, UI.TEXT_POINTS, true))
	body.add_child(UI.plate(found))
	if focus_item != "":
		for b: Button in find_children("*", "Button", true, false):
			if b.get_meta("item", "") == focus_item and b.is_visible_in_tree():
				b.grab_focus.call_deferred()
				break


func _chamber(c: Dictionary, busy: bool) -> Control:
	var box := VBoxContainer.new()
	var title := UI.label(c["title"], UI.TEXT_POINTS, true)
	title.set_meta("chamber", c["chamber"])
	box.add_child(title)
	for line: String in c["lines"]:
		box.add_child(UI.label(line, UI.TEXT_POINTS, true))
	var n := int(c["chamber"])
	for s: Dictionary in c["slots"]:
		var b := UI.button(s["text"], controller.cycle.bind(n, int(s["slot"])), false, Color(), s["spoken"])
		b.disabled = busy
		b.set_meta("key", s["key"])
		b.set_meta("item", s["key"])
		box.add_child(b)
	if not (c["run"] as Dictionary).is_empty():
		var shown: Dictionary = (c["run"] as Dictionary).duplicate()
		if confirm == shown["key"]:
			shown["action"] = Strings.t("CODEX_CONFIRM", shown["cost"])
			shown["spoken"] = Strings.t("CODEX_CONFIRM_SPOKEN", [shown["spoken"], shown["cost"]])
		box.add_child(RosterScreen.offer(shown, busy, _run.bind(c["run"], n)))
	return UI.plate(box)


## A paid run's first tap shows its price to confirm; the second spends it.
## The first experiment is free and runs on one tap.
func _run(o: Dictionary, n: int) -> void:
	if str(o["cost"]) != "" and confirm != o["key"]:
		confirm = o["key"]
		_refresh()
		return
	confirm = ""
	await controller.start(n)
