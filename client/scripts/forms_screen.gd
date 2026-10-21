class_name FormsScreen
extends Control
## The Forms album (§23.2, "The creature collection"): how many of the 54
## forms the player has hatched; each note's look, quirk, symbol and the
## launch laws that hatch it; each kind's three forms and its outfit; each
## note's skiff sail; and "Show mine". Trades come with version 1.1 (§11.10).
## It draws the store; Services' `forms_flow` asks. A kind's three forms
## stand side by side on the hero stage — one not yet hatched as a
## silhouette — and each card shows them as portraits rendered from the
## models (§21.3, §21.6); a tap on a card's portraits stands that kind.

## Each note's glyph, after its symbol (§8: a crescent, a star, a ring), so a
## pip reads without its colour (§20.8).
const GLYPH := {"hush": "☾", "spark": "★", "echo": "◎"}

var controller: FormsController
var body: VBoxContainer
var header_label: Label
var status_label: Label
var toggle: Button
var stage: StageHero
var cards: VBoxContainer
## The kind the hero stage shows; the first in the album when none is chosen.
var chosen := ""


func _ready() -> void:
	App.ready(self)
	controller = App.services.forms_flow
	_build()
	App.services.store.changed.connect(_on_changed)
	_refresh()
	await controller.load_album()


func _on_changed(slice: StringName) -> void:
	if slice == FormsState.FORMS and is_inside_tree():
		_refresh()


func _build() -> void:
	var column := UI.frame(self)
	StageHeroSkin.night(self)
	var safe := column.get_parent() as MarginContainer
	for side: String in ["margin_left", "margin_right", "margin_top"]:
		safe.add_theme_constant_override(side, 0)
	status_label = UI.status("info", "")
	column.add_child(RosterScreen.padded(StageHeroSkin.plate(status_label)))
	body = UI.scroll(column)
	body.add_theme_constant_override("separation", UI.px(10))
	stage = StageHero.new()
	stage.custom_minimum_size = Vector2(0, UI.px(Tokens.number("size", "safe_top_points") + 230.0))
	stage.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.add_child(stage)
	header_label = StageHeroKit.words("", 15.0, StageHeroSkin.LIGHT)
	cards = VBoxContainer.new()
	cards.add_theme_constant_override("separation", UI.px(10))
	body.add_child(RosterScreen.padded(cards))
	var actions := UI.row(-1.0, true)
	actions.alignment = FlowContainer.ALIGNMENT_CENTER
	toggle = StageHeroMaterial.button(UI.button(Strings.t("FORMS_SHOW_MINE"), _toggle), "gold")
	UI.fit_to(toggle, [Strings.t("FORMS_SHOW_ALL")])
	actions.add_child(toggle)
	var home := UI.button(Strings.t("COMMON_HOME"), func() -> void: App.services.router.go(&"home"))
	actions.add_child(StageHeroMaterial.button(home, "leather"))
	column.add_child(RosterScreen.padded(actions))


func _toggle() -> void:
	controller.show_mine(not bool(App.services.store.get_slice(FormsState.FORMS)["mine"]))


func _refresh() -> void:
	if not is_inside_tree():
		return
	var slice: Dictionary = App.services.store.get_slice(FormsState.FORMS)
	var a := FormsPresenter.screen(slice)
	if a["error"] != "":
		UI.set_status(status_label, "alarm", a["error"])
	elif a["busy"] != "" or not a["ready"]:
		UI.set_status(status_label, "info", Strings.t("COMMON_LOADING"))
	else:
		UI.set_status(status_label, "info", "")
	status_label.get_parent().get_parent().visible = status_label.text != ""
	header_label.text = a.get("header", "")
	UI.relabel(toggle, a["toggle"]["action"], true)
	toggle.set_meta("mine", a["mine"])
	if header_label.get_parent() != null:
		header_label.get_parent().remove_child(header_label)
	for c in cards.get_children():
		cards.remove_child(c)
		c.queue_free()
	var kinds: Array = a.get("kinds", [])
	stage.visible = a["ready"] and not kinds.is_empty()
	if not a["ready"]:
		return
	var outfits := {}
	for o: Dictionary in (slice.get("view", {}) as Dictionary).get("outfits", []):
		outfits[o["kind"]] = o
	var k := _chosen(kinds)
	_stand(k)
	if not k.is_empty():
		cards.add_child(_detail(k, outfits.get(k["kind"], {})))
	var count := StageHeroMaterial.panel("glass", header_label, 12.0, 8.0)
	count.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	cards.add_child(count)
	var grid := GridContainer.new()
	grid.columns = 1 if Settings.text_scale > 150 else (2 if Settings.text_scale > 100 else 3)
	grid.add_theme_constant_override("h_separation", UI.px(8))
	grid.add_theme_constant_override("v_separation", UI.px(8))
	for each: Dictionary in kinds:
		grid.add_child(_tile(each, outfits.get(each["kind"], {})))
	cards.add_child(grid)
	for n: Dictionary in a["notes"]:
		cards.add_child(_note(n))
	cards.add_child(_sails(a["sails"], (slice.get("view", {}) as Dictionary).get("sails", [])))


## The kind chosen, or the album's first.
func _chosen(kinds: Array) -> Dictionary:
	for each: Dictionary in kinds:
		if str(each["kind"]) == chosen:
			return each
	return kinds[0] if not kinds.is_empty() else {}


## The chosen kind: its name, its outfit's progress on a bar, and each of
## its forms beside its note's badge, with its quirk and how many are had.
func _detail(k: Dictionary, o: Dictionary) -> Control:
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", UI.px(6))
	var name := StageHeroKit.words(k["title"], 28.0, StageHeroSkin.LIGHT)
	StageHeroSkin.named(name)
	name.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	v.add_child(name)
	if not o.is_empty():
		var have := int(o["have"])
		var of := maxi(1, int(o["of"]))
		v.add_child(StageHeroBar.make(float(have) / float(of), Color("#3FBF7F") if have >= of else Color("#E9B65C"),
			"", 12.0))
		v.add_child(StageHeroKit.para(k["outfit"], 15.0, Color("#FFE6A0") if have >= of else StageHeroSkin.LIGHT))
	for f: Dictionary in k["forms"]:
		var line := HBoxContainer.new()
		line.add_theme_constant_override("separation", UI.px(8))
		line.add_child(_pip(str(f["note"]), int(f["owned"]) > 0, 30.0))
		var words := StageHeroKit.para(f["text"], 15.0, StageHeroSkin.LIGHT if int(f["owned"]) > 0
			else StageHeroSkin.LIGHT_SOFT)
		words.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		line.add_child(words)
		v.add_child(line)
	return StageHeroKit.card("", v)


## A note's badge: its glyph on its colour, bright when had, dim when not.
static func _pip(note: String, had: bool, points := 22.0) -> PanelContainer:
	var colour: Color = StageHeroSculpt.NOTE.get(note, StageHeroSkin.OUTLINE)
	var p := StageHeroSkin.badge(str(GLYPH.get(note, "?")), colour.darkened(0.35) if had else Color("#2A1E52"),
		points * 0.6)
	p.custom_minimum_size = Vector2.ONE * UI.px(points)
	if not had:
		p.modulate = Color(1, 1, 1, 0.75)
	return p


## A kind's tile: its portrait in its first form had (a silhouette with
## none), its three notes' pips, each the form it is, and its name; a tick
## when all three are had and its outfit is unlocked. A tap stands it on the stage.
func _tile(k: Dictionary, o: Dictionary) -> Control:
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", UI.px(4))
	var look := "shadow"
	for f: Dictionary in k["forms"]:
		if int(f["owned"]) > 0:
			look = str(f["note"])
			break
	var tile := StageHeroSkin.portrait_tile(str(k["kind"]), look, 92.0)
	tile.custom_minimum_size.x = UI.px(60)
	tile.gui_input.connect(_choose.bind(str(k["kind"])))
	if not o.is_empty() and int(o["have"]) >= int(o["of"]):
		var done := StageHeroSkin.badge("✓", Color("#2F8A45"), 16.0)
		done.accessibility_name = Strings.t("FORMS_OUTFIT_DONE", int(o["of"]))
		StageHeroSkin.pin(tile, done, Control.PRESET_TOP_RIGHT)
	v.add_child(tile)
	var pips := HBoxContainer.new()
	pips.alignment = BoxContainer.ALIGNMENT_CENTER
	pips.add_theme_constant_override("separation", UI.px(4))
	for f: Dictionary in k["forms"]:
		var pip := _pip(str(f["note"]), int(f["owned"]) > 0, 26.0)
		var mark := pip.get_child(0) as Label
		mark.set_meta("form", "%s/%s" % [k["kind"], f["note"]])
		pip.accessibility_name = str(f["text"])
		pips.add_child(pip)
	v.add_child(pips)
	var name := StageHeroKit.words(k["title"], 15.0, StageHeroSkin.LIGHT)
	StageHeroSkin.named(name)
	name.clip_text = true
	v.add_child(name)
	var card := StageHeroMaterial.panel("tab" if str(k["kind"]) == chosen else "card", v, 14.0, 6.0)
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return card


## A note's page: its name and symbol, how its forms look, their quirk on
## a chip, and the laws that hatch them.
func _note(n: Dictionary) -> Control:
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", UI.px(5))
	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", UI.px(8))
	head.add_child(_pip(str(n["note"]), true, 32.0))
	var title := StageHeroKit.words(n["title"], 18.0, StageHeroSkin.LIGHT)
	StageHeroSkin.named(title)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(title)
	v.add_child(head)
	v.add_child(StageHeroKit.para(n["look"], 15.0, StageHeroSkin.LIGHT_SOFT))
	v.add_child(StageHeroKit.chip(n["quirk"], "gold", "", true))
	v.add_child(StageHeroKit.para(n["how"], 15.0))
	return StageHeroKit.card("", v)


## The skiff sails: each note's progress across every kind on a bar.
static func _sails(lines: Array, raw: Array) -> Control:
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", UI.px(6))
	var title := StageHeroKit.words(Strings.t("FORMS_SAILS_TITLE"), 18.0, Color("#FFE6A0"))
	StageHeroSkin.named(title)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	v.add_child(title)
	for i: int in lines.size():
		var s: Dictionary = raw[i] if i < raw.size() else {}
		var note := str(s.get("note", ""))
		var line := HBoxContainer.new()
		line.add_theme_constant_override("separation", UI.px(8))
		line.add_child(_pip(note, true, 28.0))
		var col := VBoxContainer.new()
		col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		col.add_child(StageHeroKit.para(str(lines[i]), 14.0))
		col.add_child(StageHeroBar.make(float(s.get("have", 0)) / maxf(1.0, float(s.get("of", 1))),
			StageHeroSculpt.NOTE.get(note, Color("#E9B65C")), "", 10.0))
		line.add_child(col)
		v.add_child(line)
	return StageHeroKit.card("", v)


## The chosen kind's three forms side by side, one not hatched in
## silhouette, each named beneath on a plate in its note's colour.
func _stand(k: Dictionary) -> void:
	if k.is_empty():
		return
	var list: Array[String] = []
	var looks: Array[String] = []
	for f: Dictionary in k["forms"]:
		list.append(str(k["kind"]))
		looks.append(str(f["note"]) if int(f["owned"]) > 0 else "shadow")
	var key := "%s%s" % [k["kind"], looks]
	if str(stage.get_meta("showing", "")) == key:
		return
	stage.set_meta("showing", key)
	stage.show_kinds(list, looks)
	for n in stage.get_children():
		if n.has_meta("words"):
			n.queue_free()
	var names := HBoxContainer.new()
	names.add_theme_constant_override("separation", UI.px(6))
	for f: Dictionary in k["forms"]:
		var note := str(f["note"])
		var colour: Color = StageHeroSculpt.NOTE.get(note, StageHeroSkin.OUTLINE)
		var p := StageHeroKit.chip(FormsPresenter.note_name(note), "#" + colour.darkened(0.45).to_html(false),
			str(GLYPH.get(note, "")))
		p.size_flags_horizontal = Control.SIZE_EXPAND | Control.SIZE_SHRINK_CENTER
		names.add_child(p)
	StageHeroSkin.on_stage(stage, names, Control.PRESET_CENTER_BOTTOM).set_meta("words", true)
	names.size_flags_horizontal = Control.SIZE_EXPAND_FILL


func _choose(event: InputEvent, kind: String) -> void:
	if event is InputEventMouseButton and (event as InputEventMouseButton).pressed:
		chosen = kind
		_refresh()
