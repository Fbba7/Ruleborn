class_name CodexScreen
extends Control
## The Codex (§7.6, §18.5, §23.2): the Keeper's Aether, Keeper level and
## Spire; when the next chapter opens; the law worked on; and each school's
## album — its shape and name, its restored count and milestones, its mastery
## track, and its laws, a "?" until met. Restoring a law or raising its tier
## spends on a second tap; marking it worked on takes one; a law met opens its
## law card. Every number is the server's.
##
## Drawn as the design's Law Codex (Screens v3, 13): the Laws hub, a summary
## with the restored ring, filter chips by school, and each album as a band
## over a grid of law tiles framed by rank, with its next steps beneath.

var controller: CodexController
var body: VBoxContainer
var header_label: Label
var status_label: Label
## The spend tapped once, by its key: the next tap on it spends.
var confirm := ""
## The school the albums are filtered to, or "" for all.
var school_filter := ""
var _aether: PanelContainer


func _ready() -> void:
	App.ready(self)
	controller = App.services.codex_flow
	_build()
	App.services.store.changed.connect(_on_changed)
	_refresh()
	await controller.load_codex()


func _on_changed(slice: StringName) -> void:
	if slice == CodexState.CODEX and is_inside_tree():
		_refresh()


func _build() -> void:
	var column := ScreenKit.frame(self)
	_aether = ScreenParts.resource("aether", "")
	column.add_child(ScreenNav.header(Strings.t("CODEX_TITLE"), _aether))
	header_label = ScreenKit.text("", 13.0, "body", "card", true, true)
	header_label.visible = false
	column.add_child(header_label)
	status_label = UI.status("info", "")
	column.add_child(ScreenParts.status_plate(status_label))
	body = UI.scroll(column)
	column.add_child(ScreenNav.hub("laws", &"codex"))
	column.add_child(ScreenNav.bar("laws"))


func _refresh() -> void:
	if not is_inside_tree():
		return
	var focused := get_viewport().gui_get_focus_owner()
	var focus_item := str(focused.get_meta("item", "")) if focused != null else ""
	var c := CodexPresenter.screen(App.services.store.get_slice(CodexState.CODEX))
	if c["error"] != "":
		UI.set_status(status_label, "alarm", c["error"])
	elif c["said"] != "":
		UI.set_status(status_label, "success", c["said"])
	elif c["busy"] != "" or not c["ready"]:
		UI.set_status(status_label, "info", Strings.t("COMMON_LOADING"))
	else:
		UI.set_status(status_label, "info", "")
	ScreenParts.show_status(status_label)
	header_label.text = c.get("header", "")
	for child in body.get_children():
		body.remove_child(child)
		child.queue_free()
	if not c["ready"]:
		return
	ScreenParts.set_resource(_aether, str(c["aether"]))
	var busy: bool = c["busy"] != ""
	body.add_child(_summary(c))
	body.add_child(_filters(c["albums"]))
	for a: Dictionary in c["albums"]:
		if school_filter == "" or school_filter == a["school"]:
			body.add_child(_album(a, busy))
	if focus_item != "":
		for b: Button in find_children("*", "Button", true, false):
			if b.get_meta("item", "") == focus_item and b.is_visible_in_tree():
				b.grab_focus.call_deferred()
				break


## The ring of laws restored, the laws met, the Keeper and Spire, the next
## chapter, and the law worked on.
func _summary(c: Dictionary) -> Control:
	var top := HBoxContainer.new()
	top.add_theme_constant_override("separation", UI.px(12))
	var ring := ScreenMeter.ring(int(c["restored"]), maxi(int(c["total"]), 1), Color("#E9B65C"), 64.0,
		"%d/%d" % [int(c["restored"]), int(c["total"])])
	ring.accessibility_name = Strings.t("SCREEN_CODEX_RESTORED", [int(c["restored"]), int(c["total"])])
	top.add_child(ring)
	var words := VBoxContainer.new()
	words.add_theme_constant_override("separation", UI.px(4))
	words.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	words.alignment = BoxContainer.ALIGNMENT_CENTER
	var title := ScreenKit.text(Strings.t("SCREEN_CODEX_OF_LAWS"), 20.0, "name", "card_lit")
	words.add_child(title)
	words.add_child(ScreenKit.text(Strings.t("SCREEN_CODEX_MET", [int(c["known"]), int(c["total"])]), 13.0,
		"words", "card_lit", true, true))
	var pills := ScreenParts.flow(6.0)
	pills.add_child(ScreenParts.pill(Strings.t("SCREEN_KEEPER_LEVEL", int(c["keeper"])), "well", "hud", "star"))
	pills.add_child(ScreenParts.pill(Strings.t("SCREEN_SPIRE_LEVEL", int(c["spire"])), "well", "generalui",
		"levelup"))
	words.add_child(pills)
	top.add_child(words)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", UI.px(8))
	box.add_child(top)
	var chapter := ScreenParts.pill(c["chapter"], "well", "generalui", "lock", 13.0, "words", true)
	box.add_child(chapter)
	var working := ScreenKit.text(c["working"], 13.0, "body", "card_lit", true, true)
	box.add_child(working)
	return ScreenKit.panel("card_lit", box, 18.0, 12.0)


## Chips that filter the albums by school: All, then each school's mark.
func _filters(albums: Array) -> Control:
	var row := ScreenParts.flow(6.0)
	row.add_child(ScreenParts.chip(Strings.t("SCREEN_ALL"), school_filter == "", _filter.bind("")))
	for a: Dictionary in albums:
		var school := str(a["school"])
		var on := school_filter == school
		row.add_child(ScreenParts.chip("%d/%d" % [int(a["restored"]), int(a["total"])], on, _filter.bind(school), "",
			"", Strings.t("SCREEN_FILTER_SCHOOL", Strings.t("SCHOOL_" + school.to_upper())),
			ScreenCoin.make("school:" + school.to_lower(), 22.0)))
	return row


func _filter(school: String) -> void:
	school_filter = school
	_refresh()


## A school's album: its band, its laws as tiles, and their next steps.
func _album(a: Dictionary, busy: bool) -> Control:
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", UI.px(8))
	var band := ScreenParts.flow(8.0)
	var school := str(a["school"])
	band.add_child(ScreenCoin.make("school:" + school.to_lower(), 30.0))
	var name := ScreenKit.text(Strings.t("SCHOOL_" + school.to_upper()), 18.0, "name", "card")
	name.set_meta("school", a["school"])
	name.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	band.add_child(name)
	band.add_child(ScreenParts.pill(a["count"], "well"))
	box.add_child(band)
	var stamps := ScreenParts.flow(4.0)
	var i := 0
	for ms: Dictionary in a["reached"]:
		var reached := bool(ms.get("reached", false))
		var p := ScreenParts.pill(str(int(ms.get("at", 0))), "cream" if reached else "well",
			"generalui", "confirm" if reached else "lock")
		p.tooltip_text = a["milestones"][i] if i < (a["milestones"] as Array).size() else ""
		stamps.add_child(p)
		i += 1
	var mastery := VBoxContainer.new()
	mastery.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	mastery.add_theme_constant_override("separation", UI.px(2))
	mastery.add_child(ScreenKit.text(a["mastery"], 13.0, "words", "card", true, true))
	mastery.add_child(ScreenMeter.bar(int(a["steps"]), maxi(int(a["steps_total"]), 1),
		Palette.SCHOOL.get(school.to_lower(), Color("#E9B65C")), 8.0))
	box.add_child(ScreenParts.columns([stamps, mastery], 10.0))
	var grid := GridContainer.new()
	grid.columns = ScreenParts.grid_columns(3)
	grid.add_theme_constant_override("h_separation", UI.px(5))
	grid.add_theme_constant_override("v_separation", UI.px(6))
	for l: Dictionary in a["laws"]:
		grid.add_child(_tile(l))
	box.add_child(grid)
	for l: Dictionary in a["laws"]:
		var step := _step(l, busy)
		if step != null:
			box.add_child(step)
	return ScreenKit.panel("card", box, 18.0, 10.0)


## One law as a tile: its school-framed mark in its rank's frame, its name,
## and its tier or its pages; a law not met is a "?" that names nothing.
func _tile(l: Dictionary) -> Control:
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", UI.px(3))
	col.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var known := bool(l["known"])
	var frame_kind: String = ScreenParts.RANK_FRAME.get(str(l.get("rank", "")), "well") if known else "well"
	var mark := ScreenKit.icon("laws", str(l["law"]) if known else "", 46.0)
	if not known:
		mark = ScreenKit.icon("harmony", "unknownlaw", 40.0)
	var frame := ScreenKit.panel(frame_kind, mark, 14.0, 4.0)
	frame.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	col.add_child(frame)
	var name := ScreenKit.text(l["name"] if known else "?", 13.0, "words", "card", false, true)
	name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(name)
	var tag: Control
	if known and int(l["tier"]) > 0:
		tag = ScreenParts.pill(Strings.t("SCREEN_TIER", l["tier_words"]), "cream")
	elif known:
		tag = ScreenParts.pill("%d/%d" % [int(l["pages"]), int(l["need"])], "well", "currencies", "pages")
	elif not l.get("open", false):
		tag = ScreenParts.pill(Strings.t("SCREEN_CHAPTER", int(l.get("chapter", 2))), "well", "generalui", "lock")
	else:
		tag = ScreenParts.pill(Strings.t("SCREEN_NOT_MET"), "well")
	tag.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	col.add_child(tag)
	var tile := ScreenKit.panel("well" if not known else "card_lit", col, 14.0, 4.0)
	tile.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	if l.has("card"):
		var card: Dictionary = l["card"]
		var b := ScreenParts.tap(tile, App.services.router.go.bind(&"law", {"law": str(l["law"])}), card["spoken"],
			card["key"], card["item"])
		b.accessibility_description = l["text"]
	else:
		tile.accessibility_name = l["text"]
	return tile


## A law's next step under its album: its mark and name, why it waits, and
## the button that takes it — or marks it worked on.
func _step(l: Dictionary, busy: bool) -> Control:
	if not l["known"]:
		return null
	var act: Dictionary = l["act"]
	var work: Dictionary = l["work"]
	if act.is_empty() and work.is_empty() and not l["worked"]:
		return null
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", UI.px(8))
	row.add_child(ScreenKit.icon("laws", str(l["law"]), 30.0))
	var words := VBoxContainer.new()
	words.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	words.add_theme_constant_override("separation", 0)
	words.alignment = BoxContainer.ALIGNMENT_CENTER
	words.add_child(ScreenKit.text(l["name"], 15.0, "words", "well"))
	if not act.is_empty() and act["why"] != "":
		words.add_child(ScreenKit.text(act["why"], 13.0, "body", "well", true, true))
	elif l["worked"]:
		words.add_child(ScreenKit.text(l["worked_text"], 13.0, "words", "well", true))
	row.add_child(words)
	var buttons := ScreenParts.flow(6.0)
	buttons.alignment = FlowContainer.ALIGNMENT_END
	if not act.is_empty():
		var shown: Dictionary = act.duplicate()
		if confirm == shown["key"]:
			shown["action"] = Strings.t("CODEX_CONFIRM", shown["cost"])
			shown["spoken"] = Strings.t("CODEX_CONFIRM_SPOKEN", [shown["spoken"], shown["cost"]])
		buttons.add_child(_offer(shown, busy, _tap.bind(act), "gold"))
	if not work.is_empty():
		buttons.add_child(_offer(work, busy, controller.work_on.bind(str(l["law"])), "leather"))
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", UI.px(6))
	box.add_child(row)
	box.add_child(buttons)
	return ScreenKit.panel("well", box, 14.0, 8.0)


static func _offer(o: Dictionary, busy: bool, pressed: Callable, material: String) -> Button:
	var b := ScreenKit.button(o["action"], pressed, material, o["spoken"], 14.0)
	b.disabled = busy or not o["can"]
	b.set_meta("key", o["key"])
	b.set_meta("item", o["item"])
	return b


## A spend's first tap shows its price to confirm; the second spends it.
func _tap(o: Dictionary) -> void:
	if confirm != o["key"]:
		confirm = o["key"]
		_refresh()
		return
	confirm = ""
	var a: Dictionary = o["args"]
	if int(a["to"]) == 1:
		await controller.restore(str(a["law"]))
	else:
		await controller.tier(str(a["law"]), int(a["to"]))
