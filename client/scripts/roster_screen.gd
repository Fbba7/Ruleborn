class_name RosterScreen
extends Control
## The Roster (§23.2: "Who does what"): every character's state as a symbol
## and a word as well as a colour, how long each rest has left, where each
## works, and one tap that sends a character to the first producer with a
## free slot in §14.1's staffing order. A character's name opens its page.
## It draws the store; Services' `roster_flow` asks, so leaving mid-change
## loses nothing.

## How often the rest timers are said again, in seconds.
const TICK_SECONDS := 30.0

var controller: RosterController
var body: VBoxContainer
var header_label: Label
var status_label: Label
## What "now" is, in milliseconds; a test sets it, so a timer reads the same
## on every run.
var clock: Callable = func() -> int: return int(Time.get_unix_time_from_system() * 1000)


func _ready() -> void:
	App.ready(self)
	controller = App.services.roster_flow
	_build()
	App.services.store.changed.connect(_on_changed)
	var tick := Timer.new()
	tick.wait_time = TICK_SECONDS
	tick.timeout.connect(_refresh)
	add_child(tick)
	tick.start()
	_refresh()
	await controller.load_roster()


func _on_changed(slice: StringName) -> void:
	if slice == RosterState.ROSTER and is_inside_tree():
		_refresh()


func _build() -> void:
	var column := UI.frame(self)
	column.add_child(UI.title(Strings.t("ROSTER_TITLE")))
	header_label = UI.label("", UI.TEXT_POINTS, true)
	column.add_child(UI.plate(header_label))
	status_label = UI.status("info", "")
	column.add_child(UI.plate(status_label))
	body = UI.scroll(column)
	var actions := UI.row(-1.0, true)
	actions.add_child(UI.button(Strings.t("COMMON_HOME"), func() -> void: App.services.router.go(&"home"), true))
	column.add_child(UI.narrow(actions))


## Built again after each change, keeping which control had focus, so a
## screen reader is not sent back to the top by a tap.
func _refresh() -> void:
	if not is_inside_tree():
		return
	var focused := get_viewport().gui_get_focus_owner()
	var focus_item := str(focused.get_meta("item", "")) if focused != null else ""
	var r := RosterPresenter.screen(App.services.store.get_slice(RosterState.ROSTER), clock.call())
	if r["error"] != "":
		UI.set_status(status_label, "alarm", r["error"])
	elif r["refused"] != "":
		UI.set_status(status_label, "alarm", r["refused"])
	elif r["said"] != "":
		UI.set_status(status_label, "success", r["said"])
	elif r["confirming"] != "":
		UI.set_status(status_label, "confirming", r["confirming"])
	elif r["busy"] != "" or not r["ready"]:
		UI.set_status(status_label, "info", Strings.t("COMMON_LOADING"))
	else:
		UI.set_status(status_label, "info", "")
	header_label.text = r.get("header", "")
	for c in body.get_children():
		body.remove_child(c)
		c.queue_free()
	if not r["ready"]:
		return
	var busy: bool = r["busy"] != ""
	for row: Dictionary in r["rows"]:
		body.add_child(character_row(row, busy, _send.bind(row)))
	if focus_item != "":
		for b: Button in find_children("*", "Button", true, false):
			if b.get_meta("item", "") == focus_item and b.is_visible_in_tree():
				b.grab_focus.call_deferred()
				break


## A character's row: its name, which opens its page; its state's swatch,
## mark and word, with the time a rest has left; where it works; and the
## reassign button, with why it waits when it cannot be used.
static func character_row(row: Dictionary, busy: bool, send: Callable) -> Control:
	var box := VBoxContainer.new()
	var open := UI.button(row["name"], func() -> void:
		App.services.router.go(&"character", {"id": row["id"]}), false, Color(), row["spoken"])
	open.set_meta("item", "open:%d" % row["id"])
	box.add_child(open)
	box.add_child(state_line(row))
	if row["where"] != "":
		box.add_child(UI.label(row["where"], UI.TEXT_POINTS, true))
	box.add_child(offer(row["send"], busy, send))
	return UI.plate(box)


## A state as §23.2 asks: its colour as a swatch beside its symbol and word.
static func state_line(row: Dictionary) -> Control:
	var line := UI.row()
	var swatch := ColorRect.new()
	swatch.color = Palette.ROSTER_STATE.get(row["state"], Palette.STONE)
	swatch.custom_minimum_size = Vector2.ONE * UI.px(UI.TEXT_POINTS)
	swatch.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	swatch.set_meta("state", row["state"])
	line.add_child(swatch)
	var words := UI.label(row["line"], UI.TEXT_POINTS, true)
	words.set_meta("state", row["state"])
	line.add_child(words)
	return line


## A change's button, and why it cannot be made now, in words beside it.
static func offer(o: Dictionary, busy: bool, pressed: Callable) -> Control:
	var r := UI.row()
	var b := UI.button(o["action"], pressed, false, Color(), o["spoken"])
	b.disabled = busy or not o["can"]
	b.set_meta("key", o["key"])
	b.set_meta("item", o["item"])
	r.add_child(b)
	if o["why"] != "":
		r.add_child(UI.label(o["why"], UI.TEXT_POINTS, true))
	return r


func _send(row: Dictionary) -> void:
	var a: Dictionary = row["send"]["args"]
	if a.is_empty():
		return
	await controller.work(int(a["id"]), str(a["realm"]), str(a["kind"]), int(a["n"]), str(row["name"]))
