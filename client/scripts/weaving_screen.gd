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
var _aether: PanelContainer
var _stage: PanelContainer


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
	_stage = ScreenKit.panel("well", preview, 18.0, 3.0)
	body.add_child(_stage)
	var harmony := ScreenKit.button(Strings.t("HARMONY_TITLE"), func() -> void: App.services.router.go(&"harmony"),
		"leather")
	column.add_child(ScreenNav.dock(&"home", [harmony]))


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
	for c in body.get_children():
		if c == _stage:
			continue
		body.remove_child(c)
		c.queue_free()
	if not w["ready"]:
		return
	var busy: bool = w["busy"] != ""
	ScreenParts.set_resource(_aether, ShopPresenter.grouped(int((App.services.store.get_slice(WeavingState.WEAVING)
		["view"] as Dictionary).get("aether", 0))))
	_preview()
	_stage.visible = preview.visible
	body.add_child(_bar(w["bar"]))
	body.move_child(_stage, body.get_child_count() - 1)
	body.add_child(ScreenParts.pill(Strings.t("WEAVING_HOW", SettingsScreen.seconds(Settings.hold_ms)), "glass",
		"generalui", "info", 13.0, "words", true))
	for r: Dictionary in w["realms"]:
		body.add_child(_realm(r, busy))
	if focus_item != "":
		for b: Button in find_children("*", "Button", true, false):
			if b.get_meta("item", "") == focus_item and b.is_visible_in_tree():
				b.grab_focus.call_deferred()
				break


## §5.5's seven bands: the strain and its band, the gauge, each band named
## (the current one marked by a word as well as a colour), and its effect.
func _bar(b: Dictionary) -> Control:
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", UI.px(6))
	var top := HBoxContainer.new()
	top.add_theme_constant_override("separation", UI.px(8))
	top.add_child(ScreenKit.icon("stabilitybands", ["quiet", "steady", "humming", "brimming", "strained", "cracking",
		"breaking"][clampi(int(b["band"]), 0, 6)], 40.0))
	var words := VBoxContainer.new()
	words.add_theme_constant_override("separation", 0)
	words.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var big := ScreenKit.text("%s · %s" % [b["percent"], b["name"]], 22.0, "number", "card_lit")
	words.add_child(big)
	words.add_child(ScreenKit.text(b["strain"], 13.0, "body", "card_lit", true, true))
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
		var p := ScreenKit.panel("cream" if on else "well", cell, -1.0, 2.0)
		(p.get_theme_stylebox("panel") as StyleBox).content_margin_left = UI.px(8)
		(p.get_theme_stylebox("panel") as StyleBox).content_margin_right = UI.px(8)
		strip.add_child(p)
	box.add_child(strip)
	box.add_child(ScreenKit.text(b["effect"], 15.0, "words", "card_lit", false, true))
	return ScreenKit.panel("card_lit", box, 18.0, 12.0)


## A realm (or the crown): its name, its slots as gems, then the laws to
## weave in it, the recommended first.
func _realm(r: Dictionary, busy: bool) -> Control:
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", UI.px(8))
	var band := HBoxContainer.new()
	band.add_theme_constant_override("separation", UI.px(8))
	var icon := "theheart" if str(r["type"]) == "Heart" else str(r["type"]).to_lower().replace(" ", "")
	band.add_child(ScreenKit.icon("realms", icon if r["realm"] != "crown" else "theheart", 34.0)
		if r["realm"] != "crown" else ScreenKit.icon("lawranksandtiers", "mastery", 34.0))
	var title := ScreenKit.text(r["title"], 20.0, "name", "card")
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	band.add_child(title)
	box.add_child(band)
	var slots := GridContainer.new()
	slots.columns = ScreenParts.grid_columns(2)
	slots.add_theme_constant_override("h_separation", UI.px(6))
	slots.add_theme_constant_override("v_separation", UI.px(6))
	for s: Dictionary in r["slots"]:
		slots.add_child(_slot(s, busy))
	box.add_child(slots)
	if not (r["recommended"] as Array).is_empty():
		box.add_child(ScreenParts.section(Strings.t("WEAVING_RECOMMENDED")))
		for o: Dictionary in r["recommended"]:
			box.add_child(_offer(o, busy))
	if not (r["others"] as Array).is_empty():
		box.add_child(ScreenParts.section(Strings.t("WEAVING_OTHERS")))
		for o: Dictionary in r["others"]:
			box.add_child(_offer(o, busy))
	return ScreenKit.panel("card", box, 18.0, 12.0)


## A slot as a gem: the law woven in it, or empty, resting or locked, with
## the button that unweaves it.
func _slot(s: Dictionary, busy: bool) -> Control:
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", UI.px(4))
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", UI.px(6))
	var state := str(s.get("state", "empty"))
	if s.get("law") is String:
		row.add_child(ScreenKit.icon("laws", str(s["law"]), 34.0))
	else:
		row.add_child(ScreenKit.icon("hud" if state == "empty" else "generalui",
			{"resting": "timer", "locked": "lock"}.get(state, "plus"), 30.0))
	var words := ScreenKit.text(s["text"], 13.0, "words", "well", state != "woven", true)
	words.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	words.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	row.add_child(words)
	col.add_child(row)
	if not (s["out"] as Dictionary).is_empty():
		var a: Dictionary = s["out"]["args"]
		var out: Dictionary = s["out"]
		var b := ScreenKit.button(out["action"], controller.unweave.bind(str(a["realm"]), int(a["slot"])), "leather",
			out["spoken"], 12.0)
		b.disabled = busy or not out["can"]
		b.set_meta("key", out["key"])
		b.set_meta("item", out["item"])
		col.add_child(b)
	var p := ScreenKit.panel("cream" if state == "weaving" else "well", col, 14.0, 8.0)
	if state == "weaving":
		ScreenParts.recolour(col, "cream")
	p.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return p


## A law to weave: its mark, name and points, the band it would bring, the
## harmonies and clashes it would make, then its button, whose first tap
## shows the price to confirm and whose second spends it.
func _offer(o: Dictionary, busy: bool) -> Control:
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", UI.px(6))
	var top := HBoxContainer.new()
	top.add_theme_constant_override("separation", UI.px(8))
	top.add_child(ScreenKit.icon("laws", str(o["law"]), 40.0))
	var words := VBoxContainer.new()
	words.add_theme_constant_override("separation", 0)
	words.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var name := ScreenKit.text(o["name"], 17.0, "words", "well")
	name.tooltip_text = o["title"]
	words.add_child(name)
	var tags := ScreenParts.flow(4.0)
	tags.add_child(ScreenParts.pill(Strings.t("SCREEN_POINTS", o["points"]), "card", "hud", "strain"))
	var band := ScreenParts.pill(o["band_name"], "card", "stabilitybands",
		["quiet", "steady", "humming", "brimming", "strained", "cracking", "breaking"][clampi(int(o["band"]), 0, 6)])
	tags.add_child(band)
	words.add_child(tags)
	top.add_child(words)
	box.add_child(top)
	var marks := ScreenParts.flow(4.0)
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
		var l := ScreenKit.text(line, 13.0, "body", "well", true, true)
		l.visible = false
		box.add_child(l)
	var shown := o.duplicate()
	if confirm == o["key"]:
		shown["action"] = Strings.t("WEAVING_CONFIRM", o["cost"])
		shown["spoken"] = Strings.t("WEAVING_CONFIRM_SPOKEN", [o["spoken"], o["cost"]])
	var b := ScreenKit.button(shown["action"], _tap.bind(o), "gold", shown["spoken"], 14.0)
	b.disabled = busy or not o["can"]
	b.set_meta("key", o["key"])
	b.set_meta("item", o["item"])
	b.button_down.connect(_hold.bind(o))
	b.button_up.connect(_release.bind(o))
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.add_child(b)
	if o["why"] != "":
		box.add_child(ScreenKit.text(o["why"], 13.0, "words", "well", true, true))
	return ScreenKit.panel("well", box, 16.0, 10.0)


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
