class_name HarmonyScreen
extends Control
## The Harmony view (§23.2, "See how laws combine"): the universe's strain,
## then each realm's laws with their notes, and the harmonies, clashes,
## resonances and chords they make, each with what it does to its laws'
## cost. It changes nothing; Weaving does.

## Where the laws' cards stand on the stage, as shares of its room: in its
## corners, so the pylons between them stay in sight.
const CARD_AT: Array[Vector2] = [Vector2(0.02, 0.03), Vector2(0.98, 0.03), Vector2(0.98, 0.97)]

var controller: HarmonyController
## §21.7's harmony on screen, live: the realm with the most laws woven, its
## threads, clashes and chords drawn between its pylons (ScreenHarmonyStage).
var preview: LawFxPreview
var body: VBoxContainer
var header_label: Label
var status_label: Label
var _strain: PanelContainer
var _stage: MarginContainer
## The laws' cards over their pylons on the preview, as the design floats them.
var _over: Control
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
	preview = ScreenHarmonyStage.new()
	preview.custom_minimum_size.y = UI.px(270)
	preview.visible = false
	_stage = MarginContainer.new()
	_stage.add_child(preview)
	_over = Control.new()
	_over.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_over.draw.connect(_threads)
	_stage.add_child(_over)
	preview.resized.connect(_place_cards)
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
	# The design's realm strip over the preview: the realm sounding is chosen
	# there, and its card comes first.
	if (h["realms"] as Array).size() > 1:
		var options: Array = []
		for r: Dictionary in h["realms"]:
			options.append({"text": r["title"], "key": str(r["realm"]), "on": str(r["realm"]) == _shown,
				"icon": "realms/" + str(r["icon"])})
		var strip := ScreenParts.segmented(options, func(key: String) -> void:
			if key != _shown:
				_shown = key
				_refresh())
		body.add_child(strip)
		body.move_child(strip, 0)
	var ordered: Array = (h["realms"] as Array).filter(func(r: Dictionary) -> bool: return str(r["realm"]) == _shown)
	ordered += (h["realms"] as Array).filter(func(r: Dictionary) -> bool: return str(r["realm"]) != _shown)
	for r: Dictionary in ordered:
		body.add_child(_realm(r))
	body.add_child(ScreenKit.button(Strings.t("HOME_WEAVING"), func() -> void: App.services.router.go(&"weaving"),
		"gold"))


## A realm: its name, each law with its notes as symbols, then every
## combination its laws make, each with its mark and what it does to cost.
## The realm sounding sits on parchment, as the design's chord card does.
func _realm(r: Dictionary) -> Control:
	var on: bool = str(r["realm"]) == _shown
	var m := "parchment" if on else "card"
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", UI.px(6))
	var band := HBoxContainer.new()
	band.add_theme_constant_override("separation", UI.px(8))
	band.add_child(ScreenKit.icon("realms", str(r["icon"]), 30.0))
	var title := ScreenKit.text(r["title"], 20.0, "name", m)
	title.set_meta("realm", r["realm"])
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	band.add_child(title)
	box.add_child(band)
	if on:
		var sounding := ScreenParts.pill(Strings.t("SCREEN_HARMONY_SOUNDING"), "gold", "", "", 13.0)
		sounding.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		# Beside the name; under it at large text, where both do not fit.
		if Settings.text_scale <= 125:
			band.add_child(sounding)
		else:
			sounding.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
			box.add_child(sounding)
	var i := 0
	for line: String in r["laws"]:
		var shown: Array = r["shown"]
		if i < shown.size():
			box.add_child(_law(shown[i], line, m))
		else:
			box.add_child(ScreenKit.text(line, 15.0, "body", m, true, true))
		i += 1
	var k := 0
	for line: String in r["lines"]:
		var kinds: Array = r["kinds"]
		var l := ScreenKit.text(line, 15.0, "words", m, false, true)
		l.set_meta("combination", true)
		l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", UI.px(8))
		if k < kinds.size():
			var kind: Dictionary = kinds[k]
			var mark := ScreenKit.icon("harmony", kind["kind"], 44.0 if on else 34.0)
			mark.size_flags_vertical = Control.SIZE_SHRINK_CENTER
			row.add_child(mark)
			row.add_child(l)
			var pct := int(kind["pct"])
			var tag := ScreenKit.text(("−%d%%" if pct < 0 else "+%d%%") % absi(pct), 17.0, "number", m)
			if on:
				tag.add_theme_color_override("font_color", Tokens.color("success_text") if pct < 0
					else Tokens.color("alarm_text"))
			else:
				tag.add_theme_color_override("font_color", Tokens.color("success_text_on_night") if pct < 0
					else Tokens.color("alarm_text_on_night"))
			tag.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			row.add_child(tag)
		else:
			row.add_child(l)
		box.add_child(row)
		k += 1
	# A realm's card is the switch for the preview: tapped, it is the realm
	# shown.
	var card := ScreenKit.panel(m, box, 18.0, 12.0)
	if not on:
		ScreenParts.tap(card, func() -> void:
			_shown = str(r["realm"])
			_refresh(), Strings.t("SCREEN_SHOW_REALM", r["title"]))
	return card


## A law at work: its mark, its name (crowned or not) and its notes.
func _law(l: Dictionary, line: String, m: String) -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", UI.px(8))
	row.add_child(ScreenKit.icon("laws", str(l["law"]), 36.0))
	var name := ScreenKit.text(l["name"], 15.0, "words", m, false, true)
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
	var hidden := ScreenKit.text(line, 13.0, "body", m, true, true)
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
	for c in _over.get_children():
		c.queue_free()
	if not preview.visible:
		return
	preview.show_laws(laws, LawFxPreview.realm_type_of(best))
	var notes := {}
	for l: Dictionary in best.get("laws", []):
		notes[str(l["law"])] = l.get("notes", [])
	for k: int in mini(laws.size(), LawFxPreview.SPOTS.size()):
		_over.add_child(_card(str(laws[k]), notes.get(str(laws[k]), [])))
	_place_cards.call_deferred()


## A law's card as the design floats it over the realm: its mark over its
## name and its notes, on parchment. A picture: the realm's card below says it in
## words.
func _card(law: String, notes: Array) -> Control:
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", UI.px(2))
	col.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var mark := ScreenKit.icon("laws", law, 34.0)
	mark.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	col.add_child(mark)
	var name := ScreenKit.text(Strings.term("LAW", law), 13.0, "words", "parchment")
	name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(name)
	if not notes.is_empty():
		var row := HBoxContainer.new()
		row.alignment = BoxContainer.ALIGNMENT_CENTER
		row.add_theme_constant_override("separation", UI.px(2))
		for n: String in notes:
			row.add_child(ScreenKit.icon("lawnotes", n.to_lower(), 18.0))
		col.add_child(row)
	var card := ScreenKit.panel("parchment", col, 14.0, 8.0)
	card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.custom_minimum_size.x = UI.px(88)
	return card


## The cards at the design's places, each joined to its pylon by a thread.
func _place_cards() -> void:
	if preview.view == null or not is_instance_valid(_over):
		return
	var k := 0
	for c: Control in _over.get_children():
		if c.is_queued_for_deletion() or k >= CARD_AT.size():
			continue
		var sz := c.get_combined_minimum_size()
		c.size = sz
		c.position = Vector2(CARD_AT[k].x * (_over.size.x - sz.x), CARD_AT[k].y * (_over.size.y - sz.y))
		k += 1
	_over.queue_redraw()


## The gold threads from each card to its law's pylon, dashed as the
## design draws them.
func _threads() -> void:
	if preview.view == null:
		return
	var k := 0
	for c: Control in _over.get_children():
		if c.is_queued_for_deletion() or k >= LawFxPreview.SPOTS.size():
			continue
		var to := preview.view.screen_at(LawFxPreview.SPOTS[k])
		var from := c.position + c.size / 2.0
		_over.draw_dashed_line(from, to, Color("#F2C45C", 0.85), UI.px(2), UI.px(6))
		k += 1
