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


## The design's filter strip: All with the restored count, then each
## school's round mark (T9's school button), the chosen one gold-edged.
func _filters(albums: Array) -> Control:
	var row := ScreenParts.flow(6.0)
	var restored := 0
	var total := 0
	for a: Dictionary in albums:
		restored += int(a["restored"])
		total += int(a["total"])
	var all := ScreenParts.chip("%s %d/%d" % [Strings.t("SCREEN_ALL"), restored, total], school_filter == "",
		_filter.bind(""))
	row.add_child(all)
	for a: Dictionary in albums:
		var school := str(a["school"])
		var b := KitControls.school_button(school.to_lower(), school_filter == school, _filter.bind(school))
		b.accessibility_name = Strings.t("SCREEN_FILTER_SCHOOL", Strings.t("SCHOOL_" + school.to_upper()))
		b.tooltip_text = "%d/%d" % [int(a["restored"]), int(a["total"])]
		row.add_child(b)
	return row


func _filter(school: String) -> void:
	school_filter = school
	_refresh()


## A school's album as the design draws it: the gold chapter band with the
## school's mark, its name, the milestones and the restored count; its
## mastery; then its laws as cards in their rank's frames on parchment, and
## their next steps beneath.
func _album(a: Dictionary, busy: bool) -> Control:
	var school := str(a["school"])
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", UI.px(8))
	var band := KitPanels.chapter(school.to_lower(), Strings.t("SCHOOL_" + school.to_upper()),
		Strings.t("SCREEN_MASTERY", [int(a["steps"]), int(a["steps_total"])]),
		"%d/%d" % [int(a["restored"]), int(a["total"])])
	band.accessibility_description = "%s. %s" % [a["count"], a["mastery"]]
	var name := band.find_children("*", "Label", true, false)[0] as Label
	name.set_meta("school", a["school"])
	# The ink of words on gold, so the school's name reads at its size; at
	# large text the band's words wrap rather than widen the screen.
	name.add_theme_color_override("font_color", ScreenKit.ink("gold"))
	for l: Label in band.find_children("*", "Label", true, false):
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		if l.get_parent() is VBoxContainer:
			l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	band.tooltip_text = "\n".join(a["milestones"])
	box.add_child(band)
	# The milestones as stamps: reached ones ticked, the rest locked.
	var stamps := ScreenParts.flow(4.0)
	var i := 0
	for ms: Dictionary in a["reached"]:
		var reached := bool(ms.get("reached", false))
		var p := ScreenParts.pill(str(int(ms.get("at", 0))), "cream" if reached else "well", "generalui",
			"confirm" if reached else "lock")
		p.tooltip_text = a["milestones"][i] if i < (a["milestones"] as Array).size() else ""
		stamps.add_child(p)
		i += 1
	var bar := ScreenMeter.bar(int(a["steps"]), maxi(int(a["steps_total"]), 1),
		Palette.SCHOOL.get(school.to_lower(), Color("#E9B65C")), 8.0)
	bar.tooltip_text = a["marks"]
	box.add_child(ScreenParts.columns([stamps, bar], 10.0))
	var grid := GridContainer.new()
	grid.columns = 2 if Settings.text_scale <= 125 else 1
	grid.add_theme_constant_override("h_separation", UI.px(6))
	grid.add_theme_constant_override("v_separation", UI.px(8))
	for l: Dictionary in a["laws"]:
		grid.add_child(_tile(l, school.to_lower()))
	box.add_child(ScreenKit.panel("parchment", grid, 16.0, 8.0))
	for l: Dictionary in a["laws"]:
		var step := _step(l, busy)
		if step != null:
			box.add_child(step)
	return box


## One law as the design's card (T9's law card): its mark in a window of its
## school's colour, framed by its rank, its tier on the corner plate and its
## pages on the disc; a law not met is a dark "?" that names nothing, with
## its chapter's lock while that is closed.
func _tile(l: Dictionary, school: String) -> Control:
	var known := bool(l["known"])
	var points := 130.0
	var tile: PanelContainer
	if known:
		var number := "%d/%d" % [int(l["pages"]), int(l["need"])] if int(l["tier"]) == 0 else ""
		tile = KitCards.law_card("laws/" + str(l["law"]).replace("_", ""), l["name"], school,
			str(l["rank"]).to_lower(), l["tier_words"] if int(l["tier"]) > 0 else "", points, number)
	else:
		var col := VBoxContainer.new()
		col.add_theme_constant_override("separation", UI.px(4))
		col.alignment = BoxContainer.ALIGNMENT_CENTER
		var mark := ScreenKit.icon("harmony", "unknownlaw", points * 0.42)
		mark.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		col.add_child(mark)
		var q := ScreenKit.text("?", 20.0, "number", "card")
		q.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		col.add_child(q)
		var tag: Control = ScreenParts.pill(Strings.t("SCREEN_NOT_MET"), "well") if l.get("open", false) \
			else ScreenParts.pill(Strings.t("SCREEN_CHAPTER", int(l.get("chapter", 2))), "well", "generalui", "lock")
		tag.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		col.add_child(tag)
		tile = ScreenKit.panel("card", col, 14.0, 6.0)
		tile.custom_minimum_size = Vector2(UI.px(points), UI.px(points * 1.25))
		tile.accessibility_name = l["text"]
	tile.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	if l.has("card"):
		var card: Dictionary = l["card"]
		var b := ScreenParts.tap(tile, App.services.router.go.bind(&"law", {"law": str(l["law"])}), card["spoken"],
			card["key"], card["item"])
		b.accessibility_description = l["text"]
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
