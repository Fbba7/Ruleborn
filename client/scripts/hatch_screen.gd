class_name HatchScreen
extends Control
## Hatch (§23.2, "Births at a Nursery"): each Nursery's ready births of the
## three it holds, the price, each kind's odds by §11.9's weights, the form's
## odds on a tie; the strays heists found, offered at the same price; and the
## newborn's traits, the first hatch's free outfit, and a name from the word
## lists (§19.20). Essence is spent on a second tap. It draws the roster's
## store; Services' `roster_flow` asks.

var controller: RosterController
var body: VBoxContainer
var header_label: Label
var status_label: Label
## The spend tapped once, by its key: the next tap on it spends.
var confirm := ""
## The name the word lists offer the newborn, as indices.
var pick := {"adjective": 0, "noun": 0}
var clock: Callable = func() -> int: return int(Time.get_unix_time_from_system() * 1000)


func _ready() -> void:
	App.ready(self)
	controller = App.services.roster_flow
	_build()
	App.services.store.changed.connect(_on_changed)
	_refresh()
	await controller.load_roster()
	await controller.load_words()


func _on_changed(slice: StringName) -> void:
	if slice in [RosterState.ROSTER, WorkshopState.WORKSHOP] and is_inside_tree():
		_refresh()


func _build() -> void:
	var column := UI.frame(self)
	column.add_child(UI.title(Strings.t("HATCH_TITLE")))
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
	var h := HatchPresenter.screen(App.services.store.get_slice(RosterState.ROSTER),
		App.services.store.get_slice(WorkshopState.WORKSHOP)["words"], clock.call(), pick)
	if h["error"] != "":
		UI.set_status(status_label, "alarm", h["error"])
	elif h["said"] != "":
		UI.set_status(status_label, "success", h["said"])
	elif h["busy"] != "" or not h["ready"]:
		UI.set_status(status_label, "info", Strings.t("COMMON_LOADING"))
	else:
		UI.set_status(status_label, "info", "")
	header_label.text = h.get("header", "")
	for c in body.get_children():
		body.remove_child(c)
		c.queue_free()
	if not h["ready"]:
		return
	var busy: bool = h["busy"] != ""
	if not (h["newborn"] as Dictionary).is_empty():
		body.add_child(_newborn(h["newborn"], busy))
	if h["none"] != "":
		body.add_child(UI.plate(UI.label(h["none"], UI.TEXT_POINTS, true)))
	for n: Dictionary in h["nurseries"]:
		var box := VBoxContainer.new()
		box.add_child(UI.label(n["title"], UI.TEXT_POINTS, true))
		box.add_child(UI.label(n["ready"], UI.TEXT_POINTS, true))
		if n["next"] != "":
			box.add_child(UI.label(n["next"], UI.TEXT_POINTS, true))
		box.add_child(UI.label(Strings.t("HATCH_KINDS"), UI.TEXT_POINTS, true))
		for k: String in n["kinds"]:
			box.add_child(UI.label(k, UI.TEXT_POINTS, true))
		box.add_child(UI.label(Strings.t("HATCH_FORMS"), UI.TEXT_POINTS, true))
		box.add_child(UI.label(n["forms"], UI.TEXT_POINTS, true))
		box.add_child(_spend(n["button"], busy))
		body.add_child(UI.plate(box))
	if not (h["strays"] as Array).is_empty():
		body.add_child(UI.plate(UI.label(Strings.t("HATCH_STRAYS"), UI.TEXT_POINTS, true)))
	for s: Dictionary in h["strays"]:
		var box := VBoxContainer.new()
		for line: String in [s["title"], s["born"], s["traits"], s["forms"]]:
			if line != "":
				box.add_child(UI.label(line, UI.TEXT_POINTS, true))
		box.add_child(_spend(s["take"], busy))
		box.add_child(RosterScreen.offer(s["decline"], busy, controller.decline_stray.bind(int(s["id"]))))
		body.add_child(UI.plate(box))
	if focus_item != "":
		for b: Button in find_children("*", "Button", true, false):
			if b.get_meta("item", "") == focus_item and b.is_visible_in_tree():
				b.grab_focus.call_deferred()
				break


## The newborn's card: who it is, its form and traits, the first hatch's
## outfit, and the name the word lists offer, with a word changed by a tap.
func _newborn(n: Dictionary, busy: bool) -> Control:
	var box := VBoxContainer.new()
	for line: String in [n["title"], n["form"], n["traits"], n["outfit"], n["name"]]:
		if line != "":
			box.add_child(UI.label(line, UI.TEXT_POINTS, true))
	if n["naming"]:
		var words: Dictionary = App.services.store.get_slice(WorkshopState.WORKSHOP)["words"]
		var r := UI.row()
		r.add_child(_word("adjective", Strings.t("SOCIAL_OTHER_ADJECTIVE"), (words.get("adjectives", []) as Array).size()))
		r.add_child(_word("noun", Strings.t("SOCIAL_OTHER_NOUN"), (words.get("nouns", []) as Array).size()))
		box.add_child(r)
		var a: Dictionary = n["give"]["args"]
		box.add_child(RosterScreen.offer(n["give"], busy, controller.name_character.bind(int(a["id"]),
			int(a["adjective"]), int(a["noun"]))))
	return UI.plate(box)


func _word(which: String, text: String, size: int) -> Button:
	var b := UI.button(text, func() -> void:
		pick[which] = (int(pick[which]) + 1) % maxi(1, size)
		_refresh())
	b.set_meta("item", "word:" + which)
	return b


## A spend's button: the first tap shows the price to confirm; the second
## spends.
func _spend(o: Dictionary, busy: bool) -> Control:
	var shown := o.duplicate()
	if confirm == o["key"]:
		shown["action"] = Strings.t("CHARACTER_CONFIRM", o["cost"])
		shown["spoken"] = Strings.t("CHARACTER_CONFIRM_SPOKEN", [o["spoken"], o["cost"]])
	return RosterScreen.offer(shown, busy, _tap.bind(o))


func _tap(o: Dictionary) -> void:
	if confirm != o["key"]:
		confirm = o["key"]
		_refresh()
		return
	confirm = ""
	var a: Dictionary = o["args"]
	if a.has("realm"):
		await controller.hatch(str(a["realm"]))
	else:
		await controller.take_stray(int(a["stray"]))
