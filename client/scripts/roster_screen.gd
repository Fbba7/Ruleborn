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
## The state the grid shows only, or "" for every character.
var filter := ""
## What "now" is, in milliseconds; a test sets it, so a timer reads the same
## on every run.
var clock: Callable = func() -> int: return int(Time.get_unix_time_from_system() * 1000)
## The last success the stage celebrated, so a refresh does not repeat it.
var _cheered := ""


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
	# The hero stage runs to the screen's edges and under the status bar, as
	# the design's does; the rest keeps the safe area's margins.
	var safe := column.get_parent() as MarginContainer
	for side: String in ["margin_left", "margin_right", "margin_top"]:
		safe.add_theme_constant_override(side, 0)
	status_label = UI.status("info", "")
	column.add_child(padded(StageHeroSkin.plate(status_label)))
	body = UI.scroll(column)
	body.add_theme_constant_override("separation", UI.px(10))
	stage = StageHero.new()
	stage.custom_minimum_size = Vector2(0, UI.px(Tokens.number("size", "safe_top_points") + 236.0))
	stage.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.add_child(stage)
	header_label = StageHeroKit.words("", 15.0, StageHeroSkin.LIGHT)
	if Settings.text_scale > 100:
		header_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		header_label.custom_minimum_size.x = UI.px(120)
	cards = VBoxContainer.new()
	cards.add_theme_constant_override("separation", UI.px(10))
	body.add_child(padded(cards))
	var actions := UI.row(-1.0, true)
	actions.alignment = FlowContainer.ALIGNMENT_CENTER
	var home := UI.button(Strings.t("COMMON_HOME"), func() -> void: App.services.router.go(&"home"))
	actions.add_child(StageHeroMaterial.button(home, "leather"))
	column.add_child(padded(UI.narrow(actions)))


## `what` held in from the screen's sides by the safe area's margin.
static func padded(what: Control) -> MarginContainer:
	var m := MarginContainer.new()
	var side := UI.px(Tokens.number("size", "safe_side_points"))
	m.add_theme_constant_override("margin_left", side)
	m.add_theme_constant_override("margin_right", side)
	m.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	m.add_child(what)
	return m


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
		if r["said"] != _cheered:
			_cheered = r["said"]
			stage.cheer.call_deferred()
	elif r["confirming"] != "":
		UI.set_status(status_label, "confirming", r["confirming"])
	elif r["busy"] != "" or not r["ready"]:
		UI.set_status(status_label, "info", Strings.t("COMMON_LOADING"))
	else:
		UI.set_status(status_label, "info", "")
	status_label.get_parent().get_parent().visible = status_label.text != ""
	header_label.text = r.get("header", "")
	if header_label.get_parent() != null:
		header_label.get_parent().remove_child(header_label)
	for c in cards.get_children():
		cards.remove_child(c)
		c.queue_free()
	stage.visible = r["ready"] and not (r.get("rows", []) as Array).is_empty()
	if not r["ready"]:
		return
	var busy: bool = r["busy"] != ""
	var kinds := kinds_of(slice)
	var raw := {}
	for c: Dictionary in (slice.get("view", {}) as Dictionary).get("characters", []):
		raw[int(c["id"])] = c
	var rows: Array = r["rows"]
	var shown: Array = rows.filter(func(row: Dictionary) -> bool: return filter == "" or row["state"] == filter)
	if not rows.is_empty():
		var ids: Array = shown.map(func(row: Dictionary) -> int: return int(row["id"]))
		if ids.is_empty():
			ids = rows.map(func(row: Dictionary) -> int: return int(row["id"]))
		var pick: int = chosen if ids.has(chosen) else int(ids[0])
		_hero(rows, pick, raw.get(pick, {}), ids)
	cards.add_child(_filters(rows))
	var per := maxi(2, StageHeroSkin.columns(self, 150.0))
	if Settings.text_scale > 150:
		per = 1
	var grid := GridContainer.new()
	grid.columns = per
	grid.add_theme_constant_override("h_separation", UI.px(8))
	grid.add_theme_constant_override("v_separation", UI.px(8))
	cards.add_child(grid)
	var wide := (get_viewport_rect().size.x - UI.px(40) - UI.px(8) * (per - 1)) / per - UI.px(22)
	for row: Dictionary in shown:
		var c: Dictionary = raw.get(int(row["id"]), {})
		var card := character_row(row, busy, _send.bind(row), str(kinds.get(int(row["id"]), "")),
			_choose.bind(int(row["id"])), int(c.get("level", 0)))
		StageHeroSkin.cap_buttons(card, wide)
		grid.add_child(card)
	if focus_item != "":
		for b: Button in find_children("*", "Button", true, false):
			if b.get_meta("item", "") == focus_item and b.is_visible_in_tree():
				b.grab_focus.call_deferred()
				break


## The chosen character on the stage, with its place among those shown and
## its state over it and the arrows through them; under the stage its name
## plate, its level, and the places and Essence.
func _hero(rows: Array, pick: int, c: Dictionary, ids: Array) -> void:
	var kind := str(c.get("kind", ""))
	if str(stage.get_meta("showing", "")) != kind:
		stage.show_kinds([kind])
		stage.set_meta("showing", kind)
	for n in stage.get_children():
		if n.has_meta("words"):
			n.queue_free()
	var over := MarginContainer.new()
	over.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	over.mouse_filter = Control.MOUSE_FILTER_IGNORE
	over.add_theme_constant_override("margin_top", UI.px(Tokens.number("size", "safe_top_points")))
	over.set_meta("words", true)
	stage.add_child(over)
	var row: Dictionary = {}
	for x: Dictionary in rows:
		if int(x["id"]) == pick:
			row = x
	var at := ids.find(pick)
	StageHeroSkin.on_stage(over, StageHeroKit.chip(Strings.t("CHARACTER_COUNT", [at + 1, ids.size()]), "glass"),
		Control.PRESET_TOP_LEFT)
	StageHeroSkin.on_stage(over, StageHeroKit.chip(str(row.get("line", "")), "glass",
		"characterstates/" + str(row.get("state", ""))), Control.PRESET_TOP_RIGHT)
	if ids.size() > 1:
		for step: int in [-1, 1]:
			var to: int = ids[posmod(at + step, ids.size())]
			var name := ""
			for x: Dictionary in rows:
				if int(x["id"]) == to:
					name = str(x["name"])
			var b := StageHeroKit.arrow(step < 0, Strings.t("CHARACTER_PREVIOUS" if step < 0 else "CHARACTER_NEXT",
				name), _choose.bind(to))
			b.set_meta("item", "step:%d" % step)
			StageHeroSkin.on_stage(over, b, Control.PRESET_CENTER_LEFT if step < 0 else Control.PRESET_CENTER_RIGHT)
	var name_label := Label.new()
	name_label.text = str(row.get("name", ""))
	var school := str(c.get("school", "")).to_lower()
	var top := HFlowContainer.new()
	top.add_theme_constant_override("h_separation", UI.px(8))
	var plate := StageHeroKit.name_plate(name_label, school, "%s · %s" % [RosterPresenter.kind_name(kind),
		Strings.term("ROLE", str(c.get("role", "")))])
	plate.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(plate)
	var details := UI.button(Strings.t("ROSTER_DETAILS"), func() -> void:
		App.services.router.go(&"character", {"id": pick}), false, Color(), str(row.get("spoken", "")))
	details.set_meta("item", "details")
	details.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	top.add_child(StageHeroMaterial.button(details, "gold"))
	cards.add_child(top)
	cards.add_child(StageHeroKit.level_row(int(c.get("level", 1)), int(c.get("top", 1))))
	var places := StageHeroMaterial.panel("glass", header_label, 12.0, 8.0)
	places.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	cards.add_child(places)


## A chip a state, with how many are in it, that shows only those; "All"
## first. The chosen one on the tab material.
func _filters(rows: Array) -> Control:
	var counts := {}
	for row: Dictionary in rows:
		counts[row["state"]] = int(counts.get(row["state"], 0)) + 1
	var flow := HFlowContainer.new()
	flow.add_theme_constant_override("h_separation", UI.px(6))
	flow.add_theme_constant_override("v_separation", UI.px(6))
	var options: Array = [["", Strings.t("ROSTER_ALL"), "", rows.size()]]
	for state: String in ["idle", "working", "guarding", "resting"]:
		if counts.has(state):
			options.append([state, Strings.t("ROSTER_STATE_" + state.to_upper()),
				RosterPresenter.MARK.get(state, ""), int(counts[state])])
	for o: Array in options:
		var words := Strings.t("ROSTER_FILTER", [o[1], o[3]])
		var b := UI.button(("%s %s" % [o[2], words]).strip_edges(), _filter.bind(str(o[0])), false, Color(),
			Strings.t("ROSTER_FILTER_SPOKEN", [o[1], o[3]]))
		b.set_meta("item", "filter:%s" % o[0])
		b.toggle_mode = true
		b.button_pressed = filter == o[0]
		StageHeroMaterial.button(b, "tab" if filter == o[0] else "card", 12.0)
		flow.add_child(b)
	return flow


func _filter(state: String) -> void:
	filter = state
	_refresh()


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
		choose := Callable(), level := 0) -> Control:
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", UI.px(6))
	if kind != "":
		var tile := StageHeroSkin.portrait_tile(kind, "", 112.0)
		if choose.is_valid():
			tile.gui_input.connect(func(e: InputEvent) -> void:
				if e is InputEventMouseButton and (e as InputEventMouseButton).pressed:
					choose.call())
		# Its level on a gold plate (§21.8's Lilita One), its state's mark on
		# its state's colour, and its school's shape, as the design's tiles.
		var school := StageHeroFigure.school(StageHeroFigure.key(kind))
		var shade: Color = (Palette.SCHOOL.get(school, Palette.MOTION) as Color).darkened(0.55)
		if level > 0:
			StageHeroSkin.pin(tile, StageHeroSkin.badge(str(level), Color("#E9B65C"), 20.0), Control.PRESET_TOP_LEFT)
		var state: Color = Palette.ROSTER_STATE.get(row["state"], Palette.STONE)
		StageHeroSkin.pin(tile, StageHeroSkin.badge(str(row["mark"]), state.darkened(0.6), 18.0),
			Control.PRESET_TOP_RIGHT)
		StageHeroSkin.pin(tile, StageHeroSkin.badge(str(UI.SHAPE_GLYPH.get(Tokens.shape(school), "")), shade, 16.0),
			Control.PRESET_BOTTOM_LEFT)
		box.add_child(tile)
	var open := UI.button(row["name"], func() -> void:
		App.services.router.go(&"character", {"id": row["id"]}), false, Color(), row["spoken"])
	open.set_meta("item", "open:%d" % row["id"])
	StageHeroSkin.flat(open, 19.0)
	for state: String in ["normal", "hover", "pressed", "focus", "disabled"]:
		var flat := open.get_theme_stylebox(state) as StyleBoxFlat
		flat.bg_color = Color("#2A1E52") if state != "pressed" else Color("#3A2A6A")
		flat.border_color = Color("#E9B65C")
	for c: String in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		open.add_theme_color_override(c, StageHeroSkin.LIGHT)
	open.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.add_child(open)
	var line := state_line(row)
	for l: Label in line.find_children("*", "Label", true, false):
		l.add_theme_color_override("font_color", StageHeroSkin.LIGHT)
		l.set_meta("points", 15.0)
		l.add_theme_font_size_override("font_size", UI.text_px(15))
	box.add_child(line)
	if row["where"] != "":
		box.add_child(StageHeroKit.para(row["where"], 14.0, StageHeroSkin.LIGHT_SOFT))
	var send_row := offer(row["send"], busy, send)
	for b: Button in send_row.find_children("*", "Button", true, false):
		StageHeroMaterial.button(b, "leather")
		b.add_theme_font_size_override("font_size", UI.text_px(14))
		b.set_meta("points", 14.0)
	for l: Label in send_row.find_children("*", "Label", true, false):
		l.add_theme_color_override("font_color", StageHeroSkin.LIGHT)
	box.add_child(send_row)
	var card := StageHeroMaterial.panel("card", box, 16.0, 8.0)
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
