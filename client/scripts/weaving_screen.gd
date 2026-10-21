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
##
## Drawn as the design's Weaving (Screens v3, 05): the realm's tapestry of
## slots, one big card for the law chosen from the deck with its live
## preview, its rule and the harmonies and clashes it would make, its cost,
## the strain it brings and its time, then the deck of the other laws, and
## the weave button in the thumb's reach.

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
var _aether: PanelContainer
var _stage: MarginContainer
## The realm on show and the law chosen in its deck.
var _realm_shown := ""
var _picked := ""
var _weave_row: HBoxContainer


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
	var column := ScreenKit.frame(self)
	_aether = ScreenParts.resource("aether", "")
	column.add_child(ScreenNav.header(Strings.t("WEAVING_TITLE"), _aether))
	header_label = ScreenKit.text("", 13.0, "body", "card", true, true)
	header_label.visible = false
	column.add_child(header_label)
	status_label = UI.status("info", "")
	column.add_child(ScreenParts.status_plate(status_label))
	body = UI.scroll(column)
	# In the scroll, so large text never pushes the buttons off the phone.
	preview = LawFxPreview.new()
	preview.custom_minimum_size.y = UI.px(170)
	preview.visible = false
	_stage = MarginContainer.new()
	_stage.add_child(preview)
	ScreenParts.cull(preview, body)
	_weave_row = HBoxContainer.new()
	column.add_child(ScreenNav.dock(&"home", [_weave_row]))


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
	ScreenParts.show_status(status_label)
	header_label.text = w.get("header", "")
	# A held button is rebuilt below: its hold ends with it.
	holding = ""
	held = ""
	if _stage.get_parent() != null:
		_stage.get_parent().remove_child(_stage)
	for c in body.get_children():
		body.remove_child(c)
		c.queue_free()
	for c in _weave_row.get_children():
		_weave_row.remove_child(c)
		c.queue_free()
	if not w["ready"]:
		return
	var busy: bool = w["busy"] != ""
	ScreenParts.set_resource(_aether, ShopPresenter.grouped(int((App.services.store.get_slice(WeavingState.WEAVING)
		["view"] as Dictionary).get("aether", 0))))
	var r := _shown(w["realms"])
	body.add_child(_realms(w["realms"]))
	body.add_child(_tapestry(r, busy))
	var offers: Array = (r["recommended"] as Array) + (r["others"] as Array)
	var o := _pick(offers)
	_preview(r)
	if not o.is_empty():
		body.add_child(_card(o))
		body.add_child(_cells(o))
		body.add_child(_deck(offers))
	elif bool(preview.get_meta("wanted", false)):
		body.add_child(_stage)
	for x: Dictionary in offers:
		_weave_row.add_child(_weave(x, busy, x["law"] == o.get("law", "")))
	body.add_child(_bar(w["bar"]))
	body.add_child(ScreenParts.pill(Strings.t("WEAVING_HOW", SettingsScreen.seconds(Settings.hold_ms)), "glass",
		"generalui", "info", 13.0, "words", true))
	body.add_child(ScreenParts.item("screens", "harmonyview", Strings.t("HARMONY_TITLE"), "",
		ScreenKit.button(Strings.t("SCREEN_OPEN"), func() -> void: App.services.router.go(&"harmony"), "leather", "",
			14.0)))
	if focus_item != "":
		for b: Button in find_children("*", "Button", true, false):
			if b.get_meta("item", "") == focus_item and b.is_visible_in_tree():
				b.grab_focus.call_deferred()
				break


## The realm on show: the one chosen, else the first with laws to weave.
func _shown(realms: Array) -> Dictionary:
	for r: Dictionary in realms:
		if str(r["realm"]) == _realm_shown:
			return r
	for r: Dictionary in realms:
		if not ((r["recommended"] as Array) + (r["others"] as Array)).is_empty():
			_realm_shown = str(r["realm"])
			return r
	_realm_shown = str((realms[0] as Dictionary)["realm"]) if not realms.is_empty() else ""
	return realms[0] if not realms.is_empty() else {"realm": "", "title": "", "slots": [], "recommended": [],
		"others": [], "type": ""}


## The law chosen in the deck: the one tapped, else the first recommended.
func _pick(offers: Array) -> Dictionary:
	for o: Dictionary in offers:
		if str(o["law"]) == _picked:
			return o
	_picked = str((offers[0] as Dictionary)["law"]) if not offers.is_empty() else ""
	return offers[0] if not offers.is_empty() else {}


## The realms (and the crown) as the design's gold strip, to choose the one
## woven into.
func _realms(realms: Array) -> Control:
	var options: Array = []
	for r: Dictionary in realms:
		options.append({"text": r["title"], "key": str(r["realm"]), "on": str(r["realm"]) == _realm_shown})
	return ScreenParts.segmented(options, func(key: String) -> void:
		if key != _realm_shown:
			_realm_shown = key
			_picked = ""
			confirm = ""
			_refresh())


## The realm's tapestry: each slot as a gem on a woven band, the law in it
## with its tier, or empty, resting or locked, and its Take out button.
func _tapestry(r: Dictionary, busy: bool) -> Control:
	var row := ScreenParts.flow(8.0)
	row.alignment = FlowContainer.ALIGNMENT_CENTER
	for s: Dictionary in r["slots"]:
		row.add_child(_slot(s, busy))
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", UI.px(6))
	var title := ScreenKit.text(r["title"], 18.0, "name", "card")
	title.set_meta("realm", r["realm"])
	box.add_child(title)
	box.add_child(row)
	return ScreenKit.panel("card", box, 18.0, 10.0)


func _slot(s: Dictionary, busy: bool) -> Control:
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", UI.px(4))
	col.alignment = BoxContainer.ALIGNMENT_CENTER
	var state := str(s.get("state", "empty"))
	var gem: Control
	if s.get("law") is String:
		var law := str(s["law"])
		gem = ScreenKit.panel("ring_" + LawFxLinks.school(law), ScreenKit.icon("laws", law, 40.0), -1.0, 6.0)
	else:
		var icon := ScreenKit.icon("hud" if state == "empty" else "generalui",
			{"resting": "timer", "locked": "lock"}.get(state, "plus"), 34.0)
		gem = ScreenKit.panel("track", icon, -1.0, 9.0)
	gem.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	col.add_child(gem)
	var words := ScreenKit.text(s["text"], 13.0, "words", "card", state != "woven", true)
	words.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	words.custom_minimum_size.x = UI.px(96)
	col.add_child(words)
	if not (s["out"] as Dictionary).is_empty():
		var a: Dictionary = s["out"]["args"]
		var out: Dictionary = s["out"]
		var b := ScreenKit.button(out["action"], controller.unweave.bind(str(a["realm"]), int(a["slot"])), "leather",
			out["spoken"], 12.0)
		b.disabled = busy or not out["can"]
		b.set_meta("key", out["key"])
		b.set_meta("item", out["item"])
		col.add_child(b)
	return col


## The big card: the law chosen, framed in its school's window, with the
## realm's live preview, its name and rule, and what it would sound with.
func _card(o: Dictionary) -> Control:
	var law := str(o["law"])
	var school := LawFxLinks.school(law)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", UI.px(8))
	var top := HBoxContainer.new()
	top.add_theme_constant_override("separation", UI.px(6))
	top.add_child(ScreenKit.icon("schools", school, 30.0))
	var school_name := ScreenKit.text(Strings.t("SCHOOL_" + school.to_upper()).to_upper(), 15.0, "words",
		"window_" + school)
	school_name.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	school_name.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	top.add_child(school_name)
	var info := KitControls.icon_button("generalui/info", Strings.t("CODEX_CARD_SPOKEN", o["name"]),
		App.services.router.go.bind(&"law", {"law": law}), "leather", 48.0)
	top.add_child(info)
	box.add_child(top)
	box.add_child(_stage)
	var name := ScreenKit.text(o["name"], 26.0, "name", "parchment")
	name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name.tooltip_text = o["title"]
	box.add_child(ScreenKit.panel("parchment", name, 12.0, 6.0))
	var rule := ScreenKit.text(Strings.t("LAW_RULE_" + law.to_upper()), 15.0, "body", "parchment", false, true)
	rule.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(ScreenKit.panel("parchment", rule, 12.0, 8.0))
	var marks := ScreenParts.flow(4.0)
	marks.alignment = FlowContainer.ALIGNMENT_CENTER
	for n: String in o["harmonies"]:
		marks.add_child(ScreenParts.pill(Strings.term("NOTE", n), "green", "harmony", "harmony"))
	for n: String in o["clashes"]:
		marks.add_child(ScreenParts.pill(Strings.term("NOTE", n), "red", "harmony", "dissonance"))
	if int(o["resonances"]) > 0:
		marks.add_child(ScreenParts.pill(str(int(o["resonances"])), "card_lit", "harmony", "resonance"))
	if int(o["chords"]) > 0:
		marks.add_child(ScreenParts.pill(str(int(o["chords"])), "card_lit", "harmony", "chord"))
	if marks.get_child_count() > 0:
		box.add_child(marks)
	for line: String in o["lines"]:
		var l := ScreenKit.text(line, 13.0, "body", "card", true, true)
		l.visible = false
		box.add_child(l)
	var face := ScreenKit.panel("card_lit", box, 18.0, 10.0)
	UI.dress(face, "window_" + school, 18.0)
	return ScreenKit.panel("frame_gold" if o["can"] else "frame_oak", face, 22.0, 6.0)


## The design's three cells on one plate: what it costs, the strain it
## brings with the band after it, and how long it takes.
func _cells(o: Dictionary) -> Control:
	var band: String = ["quiet", "steady", "humming", "brimming", "strained", "cracking", "breaking"][
		clampi(int(o["band"]), 0, 6)]
	var cells: Array = []
	for c: Array in [[o["price"], Strings.t("SCREEN_COST"), "resources", "aether"],
			[Strings.t("SCREEN_POINTS", o["points"]), o["band_name"], "stabilitybands", band],
			[o["time"], Strings.t("SCREEN_READY_IN"), "generalui", "timer"]]:
		var col := VBoxContainer.new()
		col.add_theme_constant_override("separation", 0)
		var top := HBoxContainer.new()
		top.alignment = BoxContainer.ALIGNMENT_CENTER
		top.add_theme_constant_override("separation", UI.px(4))
		top.add_child(ScreenKit.icon(str(c[2]), str(c[3]), 20.0))
		top.add_child(ScreenKit.text(str(c[0]), 18.0, "number", "card"))
		col.add_child(top)
		var w := ScreenKit.text(str(c[1]), 13.0, "words", "card", true, true)
		w.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		col.add_child(w)
		cells.append(col)
	return ScreenKit.panel("card", ScreenParts.columns(cells, 4.0), 16.0, 8.0)


## The deck: every other law to weave here as a small card in its school's
## window, the chosen one lit; a tap chooses it.
func _deck(offers: Array) -> Control:
	var row := GridContainer.new()
	row.columns = ScreenParts.grid_columns(3)
	row.add_theme_constant_override("h_separation", UI.px(6))
	row.add_theme_constant_override("v_separation", UI.px(6))
	for o: Dictionary in offers:
		var law := str(o["law"])
		var on := law == _picked
		var col := VBoxContainer.new()
		col.add_theme_constant_override("separation", UI.px(2))
		col.alignment = BoxContainer.ALIGNMENT_CENTER
		var art := ScreenKit.icon("laws", law, 52.0)
		art.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		col.add_child(art)
		var win := "window_" + LawFxLinks.school(law)
		var name := ScreenKit.text(o["name"], 13.0, "words", win, false, true)
		name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		col.add_child(name)
		var tag := "♪" if not (o["harmonies"] as Array).is_empty() else ("✕" if not (o["clashes"] as Array).is_empty()
			else "")
		var price := ScreenKit.text(("%s %s" % [tag, o["price"]]).strip_edges(), 15.0, "number", win)
		price.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		col.add_child(price)
		var card := ScreenKit.panel(win, col, 14.0, 6.0)
		if on:
			RbBox.of(card).set_chosen(true)
		card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		if not on:
			ScreenParts.tap(card, func() -> void:
				_picked = law
				confirm = ""
				_refresh(), Strings.t("SCREEN_CHOOSE", o["name"]))
		row.add_child(card)
	var strip := ScrollContainer.new()
	strip.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	strip.custom_minimum_size.y = row.get_combined_minimum_size().y + UI.px(8)
	strip.add_child(row)
	return strip


## A law's weave button: its price and time on it, the first tap showing the
## price to confirm and the second spending it, or a hold. Only the chosen
## law's is shown.
func _weave(o: Dictionary, busy: bool, shown: bool) -> Control:
	var s := o.duplicate()
	if confirm == o["key"]:
		s["action"] = Strings.t("WEAVING_CONFIRM", o["cost"])
		s["spoken"] = Strings.t("WEAVING_CONFIRM_SPOKEN", [o["spoken"], o["cost"]])
	var b := ScreenKit.button(s["action"], _tap.bind(o), "gold", s["spoken"], 16.0)
	b.disabled = busy or not o["can"]
	b.set_meta("key", o["key"])
	b.set_meta("item", o["item"])
	b.button_down.connect(_hold.bind(o))
	b.button_up.connect(_release.bind(o))
	b.visible = shown
	if o["why"] != "":
		b.tooltip_text = o["why"]
	return b


## §5.5's seven bands: the strain and its band, the gauge, each band named
## (the current one marked by a word as well as a colour), and its effect.
func _bar(b: Dictionary) -> Control:
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", UI.px(6))
	var top := HBoxContainer.new()
	top.add_theme_constant_override("separation", UI.px(8))
	top.add_child(ScreenKit.icon("stabilitybands", ["quiet", "steady", "humming", "brimming", "strained", "cracking",
		"breaking"][clampi(int(b["band"]), 0, 6)], 36.0))
	var words := VBoxContainer.new()
	words.add_theme_constant_override("separation", 0)
	words.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	words.add_child(ScreenKit.text("%s · %s" % [b["percent"], b["name"]], 20.0, "number", "card"))
	words.add_child(ScreenKit.text(b["strain"], 13.0, "body", "card", true, true))
	top.add_child(words)
	box.add_child(top)
	box.add_child(ScreenBands.make(int(b["band"]), (int(b["band"]) + 0.5) / 7.0))
	var strip := ScreenParts.flow(4.0)
	for band: Dictionary in b["bands"]:
		var on: bool = band["current"]
		var cell := ScreenKit.text(("● " if on else "○ ") + band["name"], 13.0, "words", "cream" if on else "well",
			not on)
		cell.set_meta("band", band["name"])
		cell.set_meta("current", on)
		strip.add_child(ScreenKit.panel("cream" if on else "well", cell, -1.0, 2.0))
	box.add_child(strip)
	box.add_child(ScreenKit.text(b["effect"], 15.0, "words", "card", false, true))
	return ScreenKit.panel("card", box, 18.0, 12.0)


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


## The realm on show with the chosen law added, so its harmonies and clashes
## show as threads and jagged lines before it is woven.
func _preview(r: Dictionary) -> void:
	var v: Dictionary = App.services.store.get_slice(WeavingState.WEAVING).get("view", {})
	var shown: Dictionary = {}
	for x: Dictionary in v.get("realms", []):
		if str(x["realm"]) == str(r.get("realm", "")):
			shown = x
	var laws := LawFxPreview.realm_laws(shown)
	if _picked != "" and not laws.has(_picked):
		laws.push_front(_picked)
	preview.set_meta("wanted", not laws.is_empty())
	preview.visible = not laws.is_empty()
	if preview.visible:
		preview.show_laws(laws, LawFxPreview.realm_type_of(shown))
