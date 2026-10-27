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
		{"text": Strings.t("SCREEN_OVERVIEW"), "key": "overview", "on": tab_shown == "overview",
			"icon": "screens/character"},
		{"text": Strings.t("PROFILE_LOG_TITLE"), "key": "log", "on": tab_shown == "log",
			"icon": "screens/heist"}], func(key: String) -> void:
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
	# The design's identity card: the Keeper and the figure on the left, the
	# league's crest on the right.
	var top := HBoxContainer.new()
	top.add_theme_constant_override("separation", UI.px(12))
	var words := VBoxContainer.new()
	words.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	words.add_theme_constant_override("separation", UI.px(2))
	words.alignment = BoxContainer.ALIGNMENT_CENTER
	words.add_child(ScreenKit.text(p["header"], 13.0, "words", "card_lit", true, true))
	var big := ScreenKit.text(ShopPresenter.grouped(int(p["renown_n"])), 34.0, "number", "card_lit")
	ScreenKit.inked(big, 1.5)
	big.add_theme_color_override("font_color", Tokens.color("gold_top"))
	words.add_child(big)
	words.add_child(ScreenKit.text(p["renown"][0], 13.0, "words", "card_lit", true, true))
	top.add_child(words)
	var crest := ScreenKit.icon("leagues", p["league"], 72.0)
	crest.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	top.add_child(crest)
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


## Heists and defences under their heading: the design's two cards, each a
## ring of its share with its counts named beneath.
func _split(p: Dictionary) -> Control:
	var counts: Dictionary = p["counts"]
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", UI.px(8))
	box.add_child(ScreenParts.section(Strings.t("SCREEN_PROFILE_RECORD")))
	var colours := {"clean": Color("#3FBF7F"), "loud": Color("#F2A03C"), "partial": Color("#3CC6D8"),
		"foiled": Color("#E2536B")}
	# The design's two cards side by side: heists as a ring of the share that
	# got away with something, defences as a ring of the share held, each
	# with its counts named beside it.
	var raids := 0
	var got := 0
	var legend := VBoxContainer.new()
	legend.add_theme_constant_override("separation", UI.px(4))
	for g: String in ProfilePresenter.GRADES:
		var n := int(counts.get(g, 0))
		raids += n
		if g != "foiled":
			got += n
		var pill := ScreenParts.pill("%s %d" % [Strings.term("GRADE", g), n], "well", "heistoutcomes", g, 13.0,
			"words", true)
		pill.set_meta("grade", g)
		legend.add_child(pill)
	var held: Dictionary = p["held"]
	var kept := int(held.get("held", 0))
	var lost := int(held.get("leaked", 0)) + int(held.get("partial", 0))
	var cards: Array = [
		_ring_card("screens", "heist", Strings.t("SCREEN_HEISTS"), got, raids, colours["clean"], legend),
		_ring_card("alerts", "defencewon", Strings.t("SCREEN_DEFENCE"), kept, kept + lost, Color("#3CC6D8"),
			_counts([[Strings.t("SCREEN_HELD"), kept, "alerts", "defencewon"],
				[Strings.t("SCREEN_LEAKED"), int(held.get("leaked", 0)), "alerts", "raided"],
				[Strings.term("GRADE", "partial"), int(held.get("partial", 0)), "heistoutcomes", "partial"]]))]
	# Each card's whole count in words, for a screen reader and a long press.
	(cards[0] as Control).tooltip_text = p["heists"]
	(cards[1] as Control).tooltip_text = p["defences"]
	box.add_child(ScreenParts.columns(cards, 8.0))
	return box


## A card the design's way: its mark and name, a ring of `part` of `whole`
## with the share in its middle, and what it counts beneath.
func _ring_card(group: String, icon: String, title: String, part: int, whole: int, colour: Color,
		below: Control) -> Control:
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", UI.px(8))
	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", UI.px(6))
	head.add_child(ScreenKit.icon(group, icon, 24.0))
	var name := ScreenKit.text(title, 15.0, "words", "card")
	name.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name.autowrap_mode = TextServer.AUTOWRAP_WORD
	head.add_child(name)
	col.add_child(head)
	var share := roundi(100.0 * part / whole) if whole > 0 else 0
	col.add_child(ScreenMeter.ring(part, maxi(whole, 1), colour, 72.0, "%d%%" % share))
	col.add_child(below)
	var card := ScreenKit.panel("card", col, 16.0, 10.0)
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return card


## Counts as a column of pills, each its mark, its name and its number.
func _counts(rows: Array) -> Control:
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", UI.px(4))
	for r: Array in rows:
		col.add_child(ScreenParts.pill("%s %d" % [r[0], r[1]], "well", str(r[2]), str(r[3]), 13.0, "words", true))
	return col


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
