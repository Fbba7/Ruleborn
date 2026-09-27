class_name UniverseScreen
extends Control
## The player's universe (§5.2, §10.2): the Heart and each outer realm with
## their buildings, each building's next level and its price, what there is
## room to build, each realm's next level, and the next realm to open. A
## purchase is asked for twice — a first tap shows the price to confirm —
## because Starlight spent is not given back. It draws the store; Services'
## `universe_flow` asks, so leaving mid-purchase loses nothing.

var controller: UniverseController
var body: VBoxContainer
var header_label: Label
var status_label: Label
## The purchase tapped once, by its key: the next tap on it buys.
var confirm := ""


func _ready() -> void:
	App.ready(self)
	controller = App.services.universe_flow
	_build()
	App.services.store.changed.connect(_on_changed)
	_refresh()
	await controller.load_universe()


func _on_changed(slice: StringName) -> void:
	if slice == UniverseState.UNIVERSE and is_inside_tree():
		_refresh()


func _build() -> void:
	var column := UI.frame(self)
	column.add_child(UI.title(Strings.t("UNIVERSE_TITLE")))
	header_label = UI.label("", UI.TEXT_POINTS, true)
	column.add_child(UI.plate(header_label))
	status_label = UI.status("info", "")
	column.add_child(UI.plate(status_label))
	body = UI.scroll(column)
	var actions := UI.row(-1.0, true)
	actions.add_child(UI.button(Strings.t("COMMON_HOME"), func() -> void: App.services.router.go(&"home"), true))
	column.add_child(UI.narrow(actions))


## Built again after each change, keeping which control had focus (as the
## Workshop does), so a screen reader is not sent back to the top by a tap.
func _refresh() -> void:
	var focused := get_viewport().gui_get_focus_owner() if is_inside_tree() else null
	var focus_item := str(focused.get_meta("item", "")) if focused != null else ""
	var u := UniversePresenter.screen(App.services.store.get_slice(UniverseState.UNIVERSE))
	if u["error"] != "":
		UI.set_status(status_label, "alarm", u["error"])
	elif u["said"] != "":
		UI.set_status(status_label, "success", u["said"])
	elif u["busy"] != "":
		UI.set_status(status_label, "info", Strings.t("COMMON_LOADING"))
	else:
		UI.set_status(status_label, "info", "" if u["ready"] else Strings.t("COMMON_LOADING"))
	header_label.text = u.get("header", "")
	for c in body.get_children():
		body.remove_child(c)
		c.queue_free()
	if not u["ready"]:
		return
	var busy: bool = u["busy"] != ""
	for r: Dictionary in u["realms"]:
		body.add_child(_realm(r, busy))
	if u["open"] is Dictionary:
		var box := VBoxContainer.new()
		box.add_child(UI.label(u["open"]["title"], UI.TEXT_POINTS, true))
		for o: Dictionary in u["open"]["rows"]:
			box.add_child(_offer(o, busy))
		body.add_child(UI.plate(box))
	# Back to the same building, realm or opening, bought or not: its key
	# moves on with its level, its item does not.
	if focus_item != "":
		for b: Button in find_children("*", "Button", true, false):
			if b.get_meta("item", "") == focus_item and b.is_visible_in_tree():
				b.grab_focus.call_deferred()
				break


func _realm(r: Dictionary, busy: bool) -> Control:
	var box := VBoxContainer.new()
	box.add_child(UI.label(r["title"], UI.TEXT_POINTS, true))
	if r["raise"] is Dictionary:
		box.add_child(_offer(r["raise"], busy))
	for b: Dictionary in r["rows"]:
		box.add_child(UI.label(b["text"], UI.TEXT_POINTS, true))
		if b["key"] != "":
			box.add_child(_offer(b, busy))
	if not (r["room"] as Array).is_empty():
		box.add_child(UI.label(Strings.t("UNIVERSE_ROOM"), UI.TEXT_POINTS, true))
		for b: Dictionary in r["room"]:
			box.add_child(_offer(b, busy))
	return UI.plate(box)


## A purchase's button, and why it cannot be bought now, in words beside it.
func _offer(o: Dictionary, busy: bool) -> Control:
	var r := UI.row()
	var confirming: bool = confirm == o["key"]
	var text: String = Strings.t("UNIVERSE_CONFIRM", o["cost"]) if confirming else o["action"]
	var b := UI.button(text, _tap.bind(o), confirming, Color(),
		Strings.t("UNIVERSE_CONFIRM_SPOKEN", [o["spoken"], o["cost"]]) if confirming else o["spoken"])
	b.disabled = busy or not o["can"]
	b.set_meta("key", o["key"])
	b.set_meta("item", o["item"])
	r.add_child(b)
	if o["why"] != "":
		r.add_child(UI.label(o["why"]))
	return r


## The first tap asks; the second, on the same purchase, buys.
func _tap(o: Dictionary) -> void:
	if confirm != o["key"]:
		confirm = o["key"]
		_refresh()
		return
	confirm = ""
	var a: Dictionary = o["args"]
	if a.has("type"):
		await controller.open_realm(str(a["type"]))
	elif a.has("kind"):
		await controller.build(str(a["realm"]), str(a["kind"]), int(a["n"]), int(a["to"]))
	else:
		await controller.raise_realm(str(a["realm"]), int(a["to"]))
