class_name ProfileScreen
extends Control
## The Profile and stats (§23.2, "Your record"): Renown and league over time,
## heists by outcome, defences held and leaked, the ten records, §18.5's
## badges and the titles mastery gives, the battle log with its replays, and
## §20.2's visibility switch, locked private for 13 to 15.

var controller: ProfileController
## The tab on show: "overview" or "log".
var tab_shown := "overview"
var body: VBoxContainer
var header_label: Label
var status_label: Label


func _ready() -> void:
	App.ready(self)
	controller = App.services.profile_flow
	_build()
	App.services.store.changed.connect(_on_changed)
	_refresh()
	await controller.load_profile()


func _on_changed(slice: StringName) -> void:
	if slice == ProfileState.PROFILE and is_inside_tree():
		_refresh()


func _build() -> void:
	var column := ScreenKit.frame(self)
	column.add_child(ScreenNav.header(Strings.t("PROFILE_TITLE")))
	header_label = ScreenKit.text("", 13.0, "words", "card", true, true)
	header_label.visible = false
	column.add_child(header_label)
	status_label = UI.status("info", "")
	column.add_child(ScreenParts.status_plate(status_label))
	body = UI.scroll(column)
	var settings := ScreenKit.button(Strings.t("HOME_SETTINGS"), func() -> void: App.services.router.go(&"settings"),
		"leather")
	column.add_child(ScreenNav.dock(&"home", [settings]))


func _refresh() -> void:
	if not is_inside_tree():
		return
	var p := ProfilePresenter.screen(App.services.store.get_slice(ProfileState.PROFILE))
	if p["error"] != "":
		UI.set_status(status_label, "alarm", p["error"])
	elif p["busy"] != "" or not p["ready"]:
		UI.set_status(status_label, "info", Strings.t("COMMON_LOADING"))
	else:
		UI.set_status(status_label, "info", "")
	ScreenParts.show_status(status_label)
	header_label.text = p.get("header", "")
	for child in body.get_children():
		body.remove_child(child)
		child.queue_free()
	if not p["ready"]:
		return
	var busy: bool = p["busy"] != ""
	body.add_child(_hero(p))
	# The design's tabs: both built, the one chosen shown.
	body.add_child(ScreenParts.segmented([
		{"text": Strings.t("SCREEN_OVERVIEW"), "key": "overview", "on": tab_shown == "overview"},
		{"text": Strings.t("PROFILE_LOG_TITLE"), "key": "log", "on": tab_shown == "log"}], func(key: String) -> void:
			tab_shown = key
			_refresh()))
	var overview := VBoxContainer.new()
	var battles := VBoxContainer.new()
	for tab: VBoxContainer in [overview, battles]:
		tab.add_theme_constant_override("separation", UI.px(Tokens.number("size", "gap_points")))
		body.add_child(tab)
	overview.visible = tab_shown == "overview"
	battles.visible = tab_shown == "log"
	overview.add_child(_split(p))
	overview.add_child(ScreenParts.section(Strings.t("PROFILE_RECORDS")))
	overview.add_child(_records(p["record_tiles"]))
	overview.add_child(ScreenParts.section(Strings.t("PROFILE_BADGES")))
	overview.add_child(_badges(p))
	var titles := VBoxContainer.new()
	for line: String in p["titles"]:
		titles.add_child(ScreenKit.text(line, 15.0, "words", "card", false, true))
	overview.add_child(ScreenParts.section(Strings.t("PROFILE_TITLES_TITLE")))
	overview.add_child(ScreenKit.panel("card", titles, 16.0, 10.0))
	for e: Dictionary in p["log"]:
		battles.add_child(_battle(e, busy))
	var share: Dictionary = p["share"]
	var right: Control = null
	if share.has("button"):
		var b: Dictionary = share["button"]
		var go := ScreenKit.button(b["action"], controller.share.bind(bool(b["on"])), "leather", b["spoken"], 14.0)
		go.disabled = busy
		go.set_meta("key", b["key"])
		go.set_meta("item", b["item"])
		right = go
	battles.add_child(ScreenParts.item("social", "share", share.get("locked", share.get("state", "")), "", right))


## The league's crest, the Keeper and the place, Renown in large figures and
## the way to the next league, then each season before this one.
func _hero(p: Dictionary) -> Control:
	var top := HBoxContainer.new()
	top.add_theme_constant_override("separation", UI.px(12))
	top.add_child(ScreenKit.icon("leagues", p["league"], 72.0))
	var words := VBoxContainer.new()
	words.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	words.add_theme_constant_override("separation", UI.px(2))
	words.alignment = BoxContainer.ALIGNMENT_CENTER
	words.add_child(ScreenKit.text(p["header"], 13.0, "words", "card_lit", true, true))
	var big := ScreenKit.text(ShopPresenter.grouped(int(p["renown_n"])), 34.0, "number", "card_lit")
	ScreenKit.inked(big, 1.5)
	words.add_child(big)
	words.add_child(ScreenKit.text(p["renown"][0], 13.0, "words", "card_lit", true, true))
	top.add_child(words)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", UI.px(6))
	box.add_child(top)
	if int(p["next_n"]) > 0:
		box.add_child(ScreenMeter.bar(int(p["renown_n"]), int(p["next_n"]), Color("#E05CB4"), 10.0))
	box.add_child(ScreenKit.text(p["to_next"], 13.0, "words", "card_lit", true, true))
	var seasons := VBoxContainer.new()
	for line: String in (p["renown"] as Array).slice(1):
		seasons.add_child(ScreenParts.pill(line, "well", "season", "seasontrack", 13.0, "words", true))
	if seasons.get_child_count() > 0:
		box.add_child(seasons)
	return ScreenKit.panel("card_lit", box, 18.0, 12.0)


## Heists by outcome as one bar split by count, each outcome named with its
## mark and number; defences held and leaked beside.
func _split(p: Dictionary) -> Control:
	var counts: Dictionary = p["counts"]
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", UI.px(8))
	var heists := ScreenKit.text(p["heists"], 15.0, "words", "card")
	heists.set_meta("heist_split", true)
	heists.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(heists)
	var bar := HBoxContainer.new()
	bar.add_theme_constant_override("separation", UI.px(2))
	bar.custom_minimum_size.y = UI.px(14)
	var colours := {"clean": Color("#3FBF7F"), "loud": Color("#F2A03C"), "partial": Color("#3CC6D8"),
		"foiled": Color("#E2536B")}
	var legend := ScreenParts.flow(6.0)
	for g: String in ProfilePresenter.GRADES:
		var n := int(counts.get(g, 0))
		if n > 0:
			var seg := ScreenMeter.bar(1, 1, colours.get(g, Color.WHITE), 14.0)
			seg.size_flags_stretch_ratio = float(n)
			bar.add_child(seg)
		legend.add_child(ScreenParts.pill("%s %d" % [Strings.term("GRADE", g), n], "well", "heistoutcomes", g))
	box.add_child(bar)
	box.add_child(legend)
	var held: Dictionary = p["held"]
	var defences := ScreenParts.columns([
		ScreenParts.stat(str(int(held.get("held", 0))), Strings.t("SCREEN_HELD"), "alerts", "defencewon", "well"),
		ScreenParts.stat(str(int(held.get("leaked", 0))), Strings.t("SCREEN_LEAKED"), "alerts", "raided", "well"),
		ScreenParts.stat(str(int(held.get("partial", 0))), Strings.term("GRADE", "partial"), "heistoutcomes",
			"partial", "well")], 6.0)
	box.add_child(defences)
	var said := ScreenKit.text(p["defences"], 13.0, "words", "card", true, true)
	box.add_child(said)
	return ScreenKit.panel("card", box, 18.0, 12.0)


## The records as tiles, two to a row: a value, or a dash while none is kept.
func _records(tiles: Array) -> Control:
	var grid := GridContainer.new()
	grid.columns = ScreenParts.grid_columns(2) if Settings.text_scale <= 125 else 1
	grid.add_theme_constant_override("h_separation", UI.px(6))
	grid.add_theme_constant_override("v_separation", UI.px(6))
	for t: Dictionary in tiles:
		var col := VBoxContainer.new()
		col.add_theme_constant_override("separation", 0)
		var v := ScreenKit.text(t["value"], 20.0, "number", "card", not t["kept"])
		col.add_child(v)
		var n := ScreenKit.text(t["name"], 13.0, "words", "card", true, true)
		n.tooltip_text = t["text"]
		col.add_child(n)
		var p := ScreenKit.panel("card", col, 14.0, 8.0)
		p.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		grid.add_child(p)
	return grid


## Each badge with its count against its mark, and its grade on a plate.
func _badges(p: Dictionary) -> Control:
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", UI.px(6))
	var c: Array = p["badges"]
	# The collection's line leads the badges when the server sends one.
	if c.size() > (p["badge_tiles"] as Array).size():
		box.add_child(ScreenParts.item("screens", "formsalbum", c[0], "", null, "card"))
	for b: Dictionary in p["badge_tiles"]:
		var grade := str(b["grade"])
		var tag := ScreenParts.pill(Strings.t("PROFILE_GRADE_" + (grade.to_upper() if grade != "" else "NONE")),
			{"gold": "goldframe", "silver": "silver", "bronze": "oak"}.get(grade, "well"))
		var bar := ScreenMeter.bar(mini(int(b["count"]), int(b["mark"])), maxi(int(b["mark"]), 1),
			Color("#E9B65C"), 8.0)
		var words := VBoxContainer.new()
		words.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var n := ScreenKit.text(b["name"], 15.0, "words", "card", false, true)
		n.tooltip_text = b["text"]
		words.add_child(n)
		words.add_child(ScreenKit.text("%s / %s" % [ShopPresenter.grouped(int(b["count"])),
			ShopPresenter.grouped(int(b["mark"]))], 13.0, "words", "card", true))
		words.add_child(bar)
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", UI.px(8))
		row.add_child(ScreenKit.icon("hud", "star", 30.0))
		row.add_child(words)
		row.add_child(tag)
		box.add_child(ScreenKit.panel("card", row, 14.0, 8.0))
	return box


## A heist of the battle log: its outcome's mark, its haul, and Watch while
## its replay is kept.
func _battle(e: Dictionary, busy: bool) -> Control:
	var right: Control = null
	if not (e["watch"] as Dictionary).is_empty():
		var w: Dictionary = e["watch"]
		var b := ScreenKit.button(w["action"], App.services.defences_flow.watch.bind(e["raid"]), "gold", w["spoken"],
			14.0)
		b.disabled = busy
		b.set_meta("key", w["key"])
		b.set_meta("item", w["item"])
		right = b
	var row := ScreenParts.item("heistoutcomes", e["grade"], e["text"], "", right)
	for l: Label in row.find_children("*", "Label", true, false):
		l.set_meta("heist", e["heist"])
		break
	return row
