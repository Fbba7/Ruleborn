class_name LawScreen
extends Control
## The law card (§21.7, §23.2, "Explain one law in seconds"): the school's
## shape and name, the law's name, a live preview of the law on a small
## realm (its world signature and a figure in its gait), its one-line rule,
## its notes as symbols,
## its rank, its tier as pips, its pages and its one weakness (§7.7). It opens
## from the Codex on a law the player has met, and back to it.
##
## Drawn as the design's card (Screens v3, 03): a card in its rank's frame
## (oak, silver, gold, prismatic), the school and rank across its top, the
## name in Marcellus over three tier pips, the preview as its art, then the
## rule on parchment, the notes as their symbols, the pages as a bar, and
## the weakness; the Lab and the Codex beneath.

var law := ""
var box: VBoxContainer
var status_label: Label
## §21.7's preview: the law woven on a small realm, its world signature,
## crown and a figure walking in its gait (LawFxPreview).
var preview: LawFxPreview
var _frame: PanelContainer


func _ready() -> void:
	App.ready(self)
	law = str(App.services.store.get_slice(AppState.ROUTE)["params"].get("law", ""))
	_build()
	App.services.store.changed.connect(_on_changed)
	_refresh()
	if ((App.services.store.get_slice(CodexState.CODEX)["view"]) as Dictionary).is_empty():
		await App.services.codex_flow.load_codex()


func _on_changed(slice: StringName) -> void:
	if slice == CodexState.CODEX and is_inside_tree():
		_refresh()


func _build() -> void:
	var column := ScreenKit.frame(self)
	column.add_child(ScreenNav.header(Strings.t("LAW_CARD_TITLE")))
	status_label = UI.status("info", "")
	column.add_child(ScreenParts.status_plate(status_label))
	var list := UI.scroll(column)
	box = VBoxContainer.new()
	box.add_theme_constant_override("separation", UI.px(8))
	var inner := ScreenKit.panel("card_lit", box, 18.0, 12.0)
	_frame = ScreenKit.panel("oak", inner, 24.0, 7.0)
	list.add_child(_frame)
	# In the scroll, so large text never pushes the buttons off the phone.
	preview = LawFxPreview.new()
	preview.custom_minimum_size.y = UI.px(190)
	if law != "":
		preview.show_laws([law])
	var lab := ScreenKit.button(Strings.t("HUB_LAB"), func() -> void: App.services.router.go(&"lab"), "leather")
	var codex := ScreenKit.button(Strings.t("CODEX_TITLE"), func() -> void: App.services.router.go(&"codex"), "gold")
	column.add_child(ScreenNav.dock(&"codex", [lab, codex]))


func _refresh() -> void:
	if not is_inside_tree():
		return
	if preview.get_parent() != null:
		preview.get_parent().remove_child(preview)
	for child in box.get_children():
		box.remove_child(child)
		child.queue_free()
	var c := LawPresenter.from_codex(App.services.store.get_slice(CodexState.CODEX), law)
	if c.is_empty():
		UI.set_status(status_label, "info", Strings.t("COMMON_LOADING"))
		ScreenParts.show_status(status_label)
		return
	UI.set_status(status_label, "info", "")
	ScreenParts.show_status(status_label)
	var frame_kind: String = ScreenParts.RANK_FRAME.get(c["rank_key"], "oak")
	ScreenKit.restyle(_frame, frame_kind, 24.0)
	box.add_child(_top(c))
	var name := ScreenKit.inked(ScreenKit.text(c["name"], 30.0, "name", "card_lit"), 1.5)
	name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name.set_meta("law", c["law"])
	box.add_child(name)
	box.add_child(_pips(c))
	var art := ScreenKit.panel("well", preview, 16.0, 3.0)
	box.add_child(art)
	var rule := ScreenKit.text(c["rule"], 17.0, "body", "parchment", false, true)
	rule.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(ScreenKit.panel("parchment", rule, 14.0, 10.0))
	box.add_child(_notes(c))
	box.add_child(_pages(c))
	var weak := ScreenParts.item("hud", "warning", Strings.t("SCREEN_WEAKNESS"), c["weak"], null, "well")
	box.add_child(weak)


## The school's mark and name, and the rank on its chip.
func _top(c: Dictionary) -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", UI.px(6))
	row.add_child(ScreenCoin.make("school:" + str(c["school"]), 26.0))
	var school := ScreenKit.text(c["school_words"].to_upper(), 13.0, "words", "card_lit", true)
	school.set_meta("school", c["school"])
	school.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	school.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	row.add_child(school)
	var rank := ScreenParts.pill(c["rank_words"], "well", "lawranksandtiers", str(c["rank_key"]).to_lower())
	rank.tooltip_text = c["rank"]
	row.add_child(rank)
	return row


## Three tier pips, filled to the tier restored, with the tier in words.
func _pips(c: Dictionary) -> Control:
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", UI.px(4))
	var tier := int(c["tier_n"])
	for i: int in 3:
		var on := i < tier
		var gem := ScreenKit.icon("lawranksandtiers", "tier" + ["i", "ii", "iii"][i], 24.0)
		gem.modulate = Color.WHITE if on else Color(1, 1, 1, 0.28)
		row.add_child(gem)
	var words := ScreenKit.text(Strings.t("SCREEN_TIER", CodexPresenter.ROMAN[tier]) if tier > 0
		else Strings.t("SCREEN_NOT_RESTORED"), 13.0, "words", "card_lit", true)
	words.accessibility_name = c["tier_spoken"]
	words.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	row.add_child(words)
	return row


## The law's notes as their symbols, each named (§20.8: every note a symbol).
func _notes(c: Dictionary) -> Control:
	var row := ScreenParts.flow(6.0)
	row.alignment = FlowContainer.ALIGNMENT_CENTER
	for n: Dictionary in c["note_list"]:
		row.add_child(ScreenParts.pill(n["name"], "well", "lawnotes", n["note"], 15.0))
	if (c["note_list"] as Array).is_empty():
		row.add_child(ScreenKit.text(c["notes"], 13.0, "body", "card_lit", true, true))
	row.tooltip_text = c["notes"]
	return row


## The pages toward the next step as a bar, with the count written.
func _pages(c: Dictionary) -> Control:
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", UI.px(4))
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", UI.px(6))
	row.add_child(ScreenKit.icon("currencies", "pages", 22.0))
	var words := ScreenKit.text(c["pages"], 13.0, "words", "card_lit", false, true)
	words.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(words)
	col.add_child(row)
	if int(c["need"]) > 0:
		col.add_child(ScreenMeter.bar(int(c["pages_n"]), int(c["need"]), Color("#E9B65C"), 10.0))
	return col
