class_name HarmonyScreen
extends Control
## The Harmony view (§23.2, "See how laws combine"): the universe's strain,
## then each realm's laws with their notes, and the harmonies, clashes,
## resonances and chords they make, each with what it does to its laws'
## cost. It changes nothing; Weaving does.

var controller: HarmonyController
## §21.7's harmony on screen, live: the realm with the most laws woven, its
## threads, clashes and chords drawn between its pylons (LawFxPreview).
var preview: LawFxPreview
var body: VBoxContainer
var header_label: Label
var status_label: Label
var _strain: PanelContainer
var _stage: MarginContainer
## The realm the preview shows, chosen by its chip.
var _shown := ""


func _ready() -> void:
	App.ready(self)
	controller = App.services.harmony_flow
	_build()
	App.services.store.changed.connect(_on_changed)
	_refresh()
	await controller.load_harmony()


func _on_changed(slice: StringName) -> void:
	if slice == HarmonyState.HARMONY and is_inside_tree():
		_refresh()


func _build() -> void:
	var column := ScreenKit.frame(self)
	_strain = ScreenParts.pill("", "glass", "", "", 15.0)
	_strain.visible = false
	column.add_child(ScreenNav.header(Strings.t("HARMONY_TITLE"), _strain))
	header_label = ScreenKit.text("", 13.0, "body", "card", true, true)
	header_label.visible = false
	column.add_child(header_label)
	status_label = UI.status("info", "")
	column.add_child(ScreenParts.status_plate(status_label))
	body = UI.scroll(column)
	# In the scroll, so large text never pushes the buttons off the phone.
	preview = LawFxPreview.new()
	preview.custom_minimum_size.y = UI.px(300)
	preview.visible = false
	_stage = MarginContainer.new()
	_stage.add_child(preview)
	ScreenParts.cull(preview, body)
	body.add_child(_stage)
	column.add_child(ScreenNav.hub("laws", &"harmony"))
	column.add_child(ScreenNav.bar("laws"))


func _refresh() -> void:
	if not is_inside_tree():
		return
	var h := HarmonyPresenter.screen(App.services.store.get_slice(HarmonyState.HARMONY))
	if h["error"] != "":
		UI.set_status(status_label, "alarm", h["error"])
	elif h["busy"] or not h["ready"]:
		UI.set_status(status_label, "info", Strings.t("COMMON_LOADING"))
	else:
		UI.set_status(status_label, "info", "")
	ScreenParts.show_status(status_label)
	header_label.text = h.get("header", "")
	for child in body.get_children():
		if child == _stage:
			continue
		body.remove_child(child)
		child.queue_free()
	if not h["ready"]:
		return
	ScreenParts.set_pill(_strain, "%s · %s" % [h["percent"], WeavingPresenter.band_name(int(h["band"]))])
	_strain.tooltip_text = h["header"]
	_preview()
	_stage.visible = bool(preview.get_meta("wanted", false))
	for r: Dictionary in h["realms"]:
		body.add_child(_realm(r))
	body.add_child(ScreenKit.button(Strings.t("HOME_WEAVING"), func() -> void: App.services.router.go(&"weaving"),
		"gold"))


## A realm: its name, each law with its notes as symbols, then every
## combination its laws make, each with its mark and what it does to cost.
func _realm(r: Dictionary) -> Control:
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", UI.px(6))
	var band := HBoxContainer.new()
	band.add_theme_constant_override("separation", UI.px(8))
	var title := ScreenKit.text(r["title"], 20.0, "name", "card")
	title.set_meta("realm", r["realm"])
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	band.add_child(title)
	box.add_child(band)
	var i := 0
	for line: String in r["laws"]:
		var shown: Array = r["shown"]
		if i < shown.size():
			box.add_child(_law(shown[i], line))
		else:
			box.add_child(ScreenKit.text(line, 15.0, "body", "card", true, true))
		i += 1
	var k := 0
	for line: String in r["lines"]:
		var kinds: Array = r["kinds"]
		var l := ScreenKit.text(line, 15.0, "words", "well", false, true)
		l.set_meta("combination", true)
		l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", UI.px(8))
		if k < kinds.size():
			var kind: Dictionary = kinds[k]
			row.add_child(ScreenKit.icon("harmony", kind["kind"], 34.0))
			row.add_child(l)
			var pct := int(kind["pct"])
			var tag := ScreenKit.text(("−%d%%" if pct < 0 else "+%d%%") % absi(pct), 17.0, "number", "card")
			tag.add_theme_color_override("font_color", Tokens.color("success_text_on_night") if pct < 0
				else Tokens.color("alarm_text_on_night"))
			tag.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			row.add_child(tag)
		else:
			row.add_child(l)
		box.add_child(row)
		k += 1
	# A realm's card is the switch for the preview: tapped, it is the realm
	# shown, and lit.
	var on: bool = str(r["realm"]) == _shown
	var card := ScreenKit.panel("card_lit" if on else "card", box, 18.0, 12.0)
	if not on:
		ScreenParts.tap(card, func() -> void:
			_shown = str(r["realm"])
			_refresh(), Strings.t("SCREEN_SHOW_REALM", r["title"]))
	return card


## A law at work: its mark, its name (crowned or not) and its notes.
func _law(l: Dictionary, line: String) -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", UI.px(8))
	row.add_child(ScreenKit.icon("laws", str(l["law"]), 36.0))
	var name := ScreenKit.text(l["name"], 15.0, "words", "card", false, true)
	name.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	name.tooltip_text = line
	row.add_child(name)
	if l["crowned"]:
		var crown := ScreenKit.icon("lawranksandtiers", "mastery", 26.0)
		crown.tooltip_text = Strings.t("SCREEN_CROWNED")
		row.add_child(crown)
		name.text = "%s · %s" % [l["name"], Strings.t("SCREEN_CROWNED")]
	for n: String in l["notes"]:
		var note := ScreenKit.icon("lawnotes", n.to_lower(), 26.0)
		note.tooltip_text = Strings.term("NOTE", n)
		row.add_child(note)
	var hidden := ScreenKit.text(line, 13.0, "body", "card", true, true)
	hidden.visible = false
	var col := VBoxContainer.new()
	col.add_child(row)
	col.add_child(hidden)
	return col


## The realm with the most laws, drawn with its links; none if no realm holds
## two laws to link.
func _preview() -> void:
	var v: Dictionary = App.services.store.get_slice(HarmonyState.HARMONY).get("view", {})
	var best: Dictionary = {}
	for r: Dictionary in v.get("realms", []):
		if LawFxPreview.realm_laws(r).size() > LawFxPreview.realm_laws(best).size():
			best = r
	for r: Dictionary in v.get("realms", []):
		if str(r["realm"]) == _shown and LawFxPreview.realm_laws(r).size() >= 2:
			best = r
	if _shown == "" and not best.is_empty():
		_shown = str(best["realm"])
	var laws := LawFxPreview.realm_laws(best)
	preview.set_meta("wanted", laws.size() >= 2)
	preview.visible = laws.size() >= 2
	if preview.visible:
		preview.show_laws(laws, LawFxPreview.realm_type_of(best))
