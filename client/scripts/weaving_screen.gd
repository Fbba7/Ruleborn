class_name WeavingScreen
extends Control
## Weaving (§23.2, "Put laws into slots"): the universe's stability as a bar
## of §5.5's seven bands, the one strain is in marked and its effect said;
## each realm's slots and the crown's; for each realm two or three
## recommended laws and then every other restored law, each with its points,
## the band strain would reach and the harmonies and clashes it would make;
## and each weave's Aether price and time on its button, spent by holding it
## for the hold time Settings keeps (§23.5's one second, adjustable, §20.8)
## or by a second tap. Every number is the server's, priced by the
## simulation (TD.14).

var controller: WeavingController
## The realm a weave would change, live (§21.7, LawFxPreview): its laws with
## the one tapped once to weave, so its harmonies and clashes show as
## threads and jagged lines before it is woven.
var preview: LawFxPreview
var body: VBoxContainer
var header_label: Label
var status_label: Label
## The weave tapped once, by its key: the next tap on it spends.
var confirm := ""
## The weave being held down, by its key, until the hold time has passed,
## and which press it is, so a hold let go and pressed again starts over.
var holding := ""
var presses := 0
## The weave a hold has spent, by its key: the release that ends the hold is
## no tap.
var held := ""
var clock: Callable = func() -> int: return int(Time.get_unix_time_from_system() * 1000)


func _ready() -> void:
	App.ready(self)
	controller = App.services.weaving_flow
	_build()
	App.services.store.changed.connect(_on_changed)
	_refresh()
	await controller.load_weaving()


func _on_changed(slice: StringName) -> void:
	if slice == WeavingState.WEAVING and is_inside_tree():
		_refresh()


func _build() -> void:
	var column := UI.frame(self)
	column.add_child(UI.title(Strings.t("WEAVING_TITLE")))
	header_label = UI.label("", UI.TEXT_POINTS, true)
	column.add_child(UI.plate(header_label))
	status_label = UI.status("info", "")
	column.add_child(UI.plate(status_label))
	body = UI.scroll(column)
	# In the scroll, so large text never pushes the buttons off the phone.
	preview = LawFxPreview.new()
	preview.visible = false
	body.add_child(preview)
	var actions := UI.row(-1.0, true)
	actions.add_child(UI.button(Strings.t("HARMONY_TITLE"), func() -> void: App.services.router.go(&"harmony")))
	actions.add_child(UI.button(Strings.t("COMMON_HOME"), func() -> void: App.services.router.go(&"home"), true))
	column.add_child(UI.narrow(actions))


func _refresh() -> void:
	if not is_inside_tree():
		return
	var focused := get_viewport().gui_get_focus_owner()
	var focus_item := str(focused.get_meta("item", "")) if focused != null else ""
	var w := WeavingPresenter.screen(App.services.store.get_slice(WeavingState.WEAVING), clock.call())
	if w["error"] != "":
		UI.set_status(status_label, "alarm", w["error"])
	elif w["refused"] != "":
		UI.set_status(status_label, "alarm", w["refused"])
	elif w["said"] != "":
		UI.set_status(status_label, "success", w["said"])
	elif w["confirming"] != "":
		UI.set_status(status_label, "confirming", w["confirming"])
	elif w["busy"] != "" or not w["ready"]:
		UI.set_status(status_label, "info", Strings.t("COMMON_LOADING"))
	else:
		UI.set_status(status_label, "info", "")
	header_label.text = w.get("header", "")
	# A held button is rebuilt below: its hold ends with it.
	holding = ""
	held = ""
	for c in body.get_children():
		if c == preview:
			continue
		body.remove_child(c)
		c.queue_free()
	if not w["ready"]:
		return
	var busy: bool = w["busy"] != ""
	_preview()
	body.add_child(_bar(w["bar"]))
	body.add_child(UI.plate(UI.label(Strings.t("WEAVING_HOW", SettingsScreen.seconds(Settings.hold_ms)),
		UI.TEXT_POINTS, true)))
	for r: Dictionary in w["realms"]:
		body.add_child(_realm(r, busy))
	if focus_item != "":
		for b: Button in find_children("*", "Button", true, false):
			if b.get_meta("item", "") == focus_item and b.is_visible_in_tree():
				b.grab_focus.call_deferred()
				break


## §5.5's seven bands, the current one marked by a word as well as a colour.
func _bar(b: Dictionary) -> Control:
	var box := VBoxContainer.new()
	box.add_child(UI.label(b["strain"], UI.TEXT_POINTS, true))
	var strip := UI.row()
	for band: Dictionary in b["bands"]:
		var cell := UI.label(("● " if band["current"] else "○ ") + band["name"], UI.TEXT_POINTS)
		cell.set_meta("band", band["name"])
		cell.set_meta("current", band["current"])
		strip.add_child(cell)
	box.add_child(strip)
	box.add_child(UI.label(b["effect"], UI.TEXT_POINTS, true))
	return UI.plate(box)


func _realm(r: Dictionary, busy: bool) -> Control:
	var box := VBoxContainer.new()
	box.add_child(UI.label(r["title"], UI.TEXT_POINTS, true))
	for s: Dictionary in r["slots"]:
		box.add_child(UI.label(s["text"], UI.TEXT_POINTS, true))
		if not (s["out"] as Dictionary).is_empty():
			var a: Dictionary = s["out"]["args"]
			box.add_child(RosterScreen.offer(s["out"], busy, controller.unweave.bind(str(a["realm"]), int(a["slot"]))))
	if not (r["recommended"] as Array).is_empty():
		box.add_child(UI.label(Strings.t("WEAVING_RECOMMENDED"), UI.TEXT_POINTS, true))
		for o: Dictionary in r["recommended"]:
			box.add_child(_offer(o, busy))
	if not (r["others"] as Array).is_empty():
		box.add_child(UI.label(Strings.t("WEAVING_OTHERS"), UI.TEXT_POINTS, true))
		for o: Dictionary in r["others"]:
			box.add_child(_offer(o, busy))
	return UI.plate(box)


## A law to weave: its comparison, then its button, whose first tap shows
## the price to confirm and whose second spends it.
func _offer(o: Dictionary, busy: bool) -> Control:
	var box := VBoxContainer.new()
	box.add_child(UI.label(o["title"], UI.TEXT_POINTS, true))
	for line: String in o["lines"]:
		box.add_child(UI.label(line, UI.TEXT_POINTS, true))
	var shown := o.duplicate()
	if confirm == o["key"]:
		shown["action"] = Strings.t("WEAVING_CONFIRM", o["cost"])
		shown["spoken"] = Strings.t("WEAVING_CONFIRM_SPOKEN", [o["spoken"], o["cost"]])
	var row := RosterScreen.offer(shown, busy, _tap.bind(o))
	var b := row.get_child(0) as Button
	b.button_down.connect(_hold.bind(o))
	b.button_up.connect(_release.bind(o))
	box.add_child(row)
	return box


## A Weave held down: once the hold time passes with it still held, it
## spends, as a second tap would.
func _hold(o: Dictionary) -> void:
	holding = o["key"]
	presses += 1
	var press := presses
	await get_tree().create_timer(Settings.hold_ms / 1000.0).timeout
	if holding != o["key"] or press != presses or not is_inside_tree():
		return
	holding = ""
	held = o["key"]
	confirm = ""
	await _spend(o)


func _release(o: Dictionary) -> void:
	if holding == o["key"]:
		holding = ""


func _tap(o: Dictionary) -> void:
	if held == o["key"]:
		held = ""
		return
	if confirm != o["key"]:
		confirm = o["key"]
		_refresh()
		return
	confirm = ""
	await _spend(o)


func _spend(o: Dictionary) -> void:
	var a: Dictionary = o["args"]
	await controller.weave(str(a["realm"]), int(a["slot"]), str(a["law"]))


## The realm of the weave tapped once, with that law added; else the first
## realm with a law woven; none if no realm has one.
func _preview() -> void:
	var v: Dictionary = App.services.store.get_slice(WeavingState.WEAVING).get("view", {})
	var shown: Dictionary = {}
	var extra := ""
	for r: Dictionary in v.get("realms", []):
		for o: Dictionary in r.get("offers", []):
			if confirm == "weave:%s:%s" % [r["realm"], o["law"]]:
				shown = r
				extra = str(o["law"])
	if shown.is_empty():
		for r: Dictionary in v.get("realms", []):
			if shown.is_empty() and not LawFxPreview.realm_laws(r).is_empty():
				shown = r
	var laws := LawFxPreview.realm_laws(shown)
	if extra != "" and not laws.has(extra):
		laws.push_front(extra)
	preview.visible = not laws.is_empty()
	if preview.visible:
		preview.show_laws(laws, LawFxPreview.realm_type_of(shown))
