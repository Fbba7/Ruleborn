class_name RosterScreen
extends Control
## The Roster (§23.2: "Who does what"): every character's state as a symbol
## and a word as well as a colour, how long each rest has left, where each
## works, and one tap that sends a character to the first producer with a
## free slot in §14.1's staffing order. A character's name opens its page.
## It draws the store; Services' `roster_flow` asks, so leaving mid-change
## loses nothing. Drawn as §21.8's game interface: the chosen character on
## its hero stage, then a grid of cards with portraits rendered from the
## models (§21.3), on the night backdrop.

## How often the rest timers are said again, in seconds.
const TICK_SECONDS := 30.0

var controller: RosterController
var body: VBoxContainer
var header_label: Label
var status_label: Label
## The hero stage at the top of the list, and the cards below it.
var stage: StageHero
var cards: VBoxContainer
## The character the hero stage shows, by id; the first when none is chosen.
var chosen := -1
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
	await controller.load_words()


func _on_changed(slice: StringName) -> void:
	if slice in [RosterState.ROSTER, WorkshopState.WORKSHOP] and is_inside_tree():
		_refresh()


func _build() -> void:
	var column := UI.frame(self)
	StageHeroSkin.night(self)
	column.add_child(StageHeroSkin.title(UI.title(Strings.t("ROSTER_TITLE"))))
	header_label = UI.label("", UI.TEXT_POINTS, true)
	column.add_child(StageHeroSkin.plate(header_label, true))
	status_label = UI.status("info", "")
	column.add_child(StageHeroSkin.plate(status_label))
	body = UI.scroll(column)
	stage = StageHero.new()
	stage.custom_minimum_size = Vector2(0, UI.px(200))
	stage.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.add_child(stage)
	cards = VBoxContainer.new()
	cards.add_theme_constant_override("separation", UI.px(Tokens.number("size", "gap_points")))
	body.add_child(cards)
	var actions := UI.row(-1.0, true)
	actions.add_child(StageHeroSkin.button(UI.button(Strings.t("COMMON_HOME"),
		func() -> void: App.services.router.go(&"home"), true), true))
	column.add_child(UI.narrow(actions))


## Built again after each change, keeping which control had focus, so a
## screen reader is not sent back to the top by a tap.
func _refresh() -> void:
	if not is_inside_tree():
		return
	var focused := get_viewport().gui_get_focus_owner()
	var focus_item := str(focused.get_meta("item", "")) if focused != null else ""
	var slice: Dictionary = App.services.store.get_slice(RosterState.ROSTER)
	var r := RosterPresenter.screen(slice, clock.call(), App.services.store.get_slice(WorkshopState.WORKSHOP)["words"])
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
	status_label.get_parent().visible = status_label.text != ""
	header_label.text = r.get("header", "")
	for c in cards.get_children():
		cards.remove_child(c)
		c.queue_free()
	stage.visible = r["ready"] and not (r.get("rows", []) as Array).is_empty()
	if not r["ready"]:
		return
	var busy: bool = r["busy"] != ""
	var kinds := kinds_of(slice)
	var rows: Array = r["rows"]
	if not rows.is_empty():
		var pick := chosen if kinds.has(chosen) else int(rows[0]["id"])
		if str(stage.get_meta("showing", "")) != str(kinds.get(pick, "")):
			stage.show_kinds([kinds.get(pick, "")])
			stage.set_meta("showing", str(kinds.get(pick, "")))
	var per := StageHeroSkin.columns(self)
	var grid := GridContainer.new()
	grid.columns = per
	grid.add_theme_constant_override("h_separation", UI.px(8))
	grid.add_theme_constant_override("v_separation", UI.px(8))
	cards.add_child(grid)
	var wide := (get_viewport_rect().size.x - UI.px(40) - UI.px(8) * (per - 1)) / per - UI.px(22)
	for row: Dictionary in rows:
		var card := character_row(row, busy, _send.bind(row), str(kinds.get(int(row["id"]), "")),
			_choose.bind(int(row["id"])))
		StageHeroSkin.cap_buttons(card, wide)
		grid.add_child(card)
	if focus_item != "":
		for b: Button in find_children("*", "Button", true, false):
			if b.get_meta("item", "") == focus_item and b.is_visible_in_tree():
				b.grab_focus.call_deferred()
				break


## Each character's kind by its id, from the roster the server sent.
static func kinds_of(slice: Dictionary) -> Dictionary:
	var out := {}
	for c: Dictionary in (slice.get("view", {}) as Dictionary).get("characters", []):
		out[int(c["id"])] = str(c["kind"])
	return out


## A character's card: its portrait on its school's ground with its level,
## its name, which opens its page; its state's swatch, mark and word, with
## the time a rest has left; where it works; and the reassign button, with
## why it waits when it cannot be used. A tap on the portrait stands it on
## the hero stage.
static func character_row(row: Dictionary, busy: bool, send: Callable, kind := "",
		choose := Callable()) -> Control:
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", UI.px(6))
	if kind != "":
		var tile := StageHeroSkin.portrait_tile(kind, "", 112.0)
		if choose.is_valid():
			tile.gui_input.connect(func(e: InputEvent) -> void:
				if e is InputEventMouseButton and (e as InputEventMouseButton).pressed:
					choose.call())
		box.add_child(tile)
	var open := UI.button(row["name"], func() -> void:
		App.services.router.go(&"character", {"id": row["id"]}), false, Color(), row["spoken"])
	open.set_meta("item", "open:%d" % row["id"])
	StageHeroSkin.flat(open)
	open.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.add_child(open)
	box.add_child(state_line(row))
	if row["where"] != "":
		box.add_child(UI.label(row["where"], UI.TEXT_POINTS, true))
	var send_row := offer(row["send"], busy, send)
	for b: Button in send_row.find_children("*", "Button", true, false):
		StageHeroSkin.button(b)
	box.add_child(send_row)
	var card := StageHeroSkin.plate(box)
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return card


## A state as §23.2 asks: its colour as a swatch beside its symbol and word.
static func state_line(row: Dictionary) -> Control:
	var line := HBoxContainer.new()
	line.add_theme_constant_override("separation", UI.px(6))
	var swatch := ColorRect.new()
	swatch.color = Palette.ROSTER_STATE.get(row["state"], Palette.STONE)
	swatch.custom_minimum_size = Vector2.ONE * UI.px(UI.TEXT_POINTS)
	swatch.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	swatch.set_meta("state", row["state"])
	line.add_child(swatch)
	var words := UI.label(row["line"], UI.TEXT_POINTS, true)
	words.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	words.size_flags_horizontal = Control.SIZE_EXPAND_FILL
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


func _choose(id: int) -> void:
	chosen = id
	_refresh()
	stage.act(0)


func _send(row: Dictionary) -> void:
	var a: Dictionary = row["send"]["args"]
	if a.is_empty():
		return
	await controller.work(int(a["id"]), str(a["realm"]), str(a["kind"]), int(a["n"]), str(row["name"]))
