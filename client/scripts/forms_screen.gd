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
## Beside the stage: the chosen form's state, kind, note, the three notes'
## pips to choose between and the outfit's progress.
var hero_info: VBoxContainer
var cards: VBoxContainer
## The chosen kind's form on the stage, by its note; its first when none.
var form_note := ""
## The kind the hero stage shows; the first in the album when none is chosen.
var chosen := ""
## Which kinds the album shows, as the design's pills: "" all, "outfits"
## those whose outfit is unlocked, "missing" those with a form not hatched.
var shelf := ""


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
	var head := Control.new()
	head.custom_minimum_size.y = UI.px(Tokens.number("size", "safe_top_points") - 34.0)
	body.add_child(head)
	body.add_child(RosterScreen.padded(StageHeroKit.hub(2)))
	# The design's hero card: the chosen form on the stage at the left, its
	# state, name, note, the three pips and the outfit at the right.
	var hero: BoxContainer = HBoxContainer.new()
	if Settings.text_scale > 100:
		hero = VBoxContainer.new()
	hero.add_theme_constant_override("separation", UI.px(8))
	stage = StageHero.new()
	stage.custom_minimum_size = Vector2(UI.px(130), UI.px(190))
	stage.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	stage.size_flags_stretch_ratio = 0.9
	hero.add_child(stage)
	hero_info = VBoxContainer.new()
	hero_info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hero_info.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	hero_info.add_theme_constant_override("separation", UI.px(6))
	hero.add_child(hero_info)
	body.add_child(RosterScreen.padded(StageHeroMaterial.panel("rim", hero, 18.0, 4.0)))
	header_label = StageHeroKit.words("", 15.0, StageHeroSkin.LIGHT)
	if Settings.text_scale > 100:
		header_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		header_label.custom_minimum_size.x = UI.px(120)
	cards = VBoxContainer.new()
	cards.add_theme_constant_override("separation", UI.px(10))
	body.add_child(RosterScreen.padded(cards))
	# A pill like the shelves it stands beside, gold so it reads as the
	# album's own switch.
	toggle = StageHeroMaterial.button(UI.button(Strings.t("FORMS_SHOW_MINE"), _toggle), "gold", 12.0)
	toggle.add_theme_font_size_override("font_size", UI.text_px(14))
	toggle.set_meta("points", 14.0)
	for state: String in ["normal", "hover", "pressed", "focus", "disabled"]:
		toggle.add_theme_stylebox_override(state, UI.clear_box(6, 4))
	UI.fit_to(toggle, [Strings.t("FORMS_SHOW_ALL")])
	column.add_child(StageHeroKit.tab_bar())


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
	for kept: Control in [header_label, toggle]:
		if kept.get_parent() != null:
			kept.get_parent().remove_child(kept)
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
	_over_stage(k, kinds)
	_hero(k, outfits.get(k.get("kind", ""), {}))
	cards.add_child(_errands(k, outfits.get(k.get("kind", ""), {})))
	cards.add_child(_shelves(kinds, outfits))
	cards.add_child(_count(slice))
	var grid := GridContainer.new()
	grid.columns = 1 if Settings.text_scale > 150 else (2 if Settings.text_scale > 100 else 3)
	grid.add_theme_constant_override("h_separation", UI.px(8))
	grid.add_theme_constant_override("v_separation", UI.px(8))
	for each: Dictionary in kinds:
		if _on_shelf(each, outfits.get(each["kind"], {}), shelf):
			grid.add_child(_tile(each, outfits.get(each["kind"], {})))
	cards.add_child(grid)
	# The chosen kind's forms and outfit under the album, as the design's
	# hero card leads to them.
	if not k.is_empty():
		cards.add_child(_detail(k, outfits.get(k["kind"], {})))
	for n: Dictionary in a["notes"]:
		cards.add_child(_note(n))
	cards.add_child(_sails(a["sails"], (slice.get("view", {}) as Dictionary).get("sails", [])))


## Under the hero card, as the design's: the way to a Nursery, and the
## chosen kind's outfit with how many of its forms are hatched.
func _errands(k: Dictionary, o: Dictionary) -> Control:
	var row: BoxContainer = HBoxContainer.new()
	if Settings.text_scale > 125:
		row = VBoxContainer.new()
	row.add_theme_constant_override("separation", UI.px(8))
	var find := UI.button(Strings.t("FORMS_FIND_NURSERY", UniversePresenter.building_name("nursery")),
		func() -> void: App.services.router.go(&"hatch"))
	StageHeroMaterial.button(find, "tab")
	find.icon = Icons.texture("buildings/nursery") if Icons.has("buildings/nursery") else null
	find.add_theme_constant_override("icon_max_width", UI.px(28))
	find.set_meta("item", "find_nursery")
	find.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(find)
	if not k.is_empty() and not o.is_empty():
		var v := VBoxContainer.new()
		v.add_theme_constant_override("separation", 0)
		v.add_child(StageHeroKit.kicker(Strings.t("FORMS_OUTFIT_LABEL")))
		v.add_child(StageHeroKit.para(Strings.t("FORMS_OUTFIT_COUNT", [int(o["have"]), int(o["of"])]), 14.0))
		var card := StageHeroMaterial.panel("rim" if int(o["have"]) >= int(o["of"]) else "card", v, 14.0, 8.0)
		card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		card.accessibility_name = str(k["outfit"])
		row.add_child(card)
	return row


## The design's pills over the album: All, Outfits and Missing, each with
## how many kinds it shows; the chosen one on the tab material.
func _shelves(kinds: Array, outfits: Dictionary) -> Control:
	var flow := HFlowContainer.new()
	flow.add_theme_constant_override("h_separation", UI.px(6))
	flow.add_theme_constant_override("v_separation", UI.px(6))
	for which: String in ["", "outfits", "missing"]:
		var n := kinds.filter(func(each: Dictionary) -> bool:
			return _on_shelf(each, outfits.get(each["kind"], {}), which)).size()
		var word := Strings.t("FORMS_FILTER_" + ("ALL" if which == "" else which.to_upper()))
		var b := UI.button("%s · %d" % [word, n], func() -> void:
			shelf = which
			_refresh(), false, Color(), Strings.t("FORMS_FILTER_SPOKEN", [word, n]))
		b.toggle_mode = true
		b.button_pressed = shelf == which
		b.set_meta("item", "shelf:" + which)
		StageHeroMaterial.button(b, "tab" if shelf == which else "card", 12.0)
		b.add_theme_font_size_override("font_size", UI.text_px(14))
		b.set_meta("points", 14.0)
		for state: String in ["normal", "hover", "pressed", "focus", "disabled"]:
			b.add_theme_stylebox_override(state, UI.clear_box(6, 4))
		UI.fit(b)
		flow.add_child(b)
	# Show mine beside them: the server's own list of what the player has.
	flow.add_child(toggle)
	return flow


## Whether a kind is on the album's `which` shelf (_shelves).
static func _on_shelf(k: Dictionary, o: Dictionary, which: String) -> bool:
	match which:
		"outfits":
			return not o.is_empty() and int(o["have"]) >= int(o["of"])
		"missing":
			return (k["forms"] as Array).any(func(f: Dictionary) -> bool: return int(f["owned"]) == 0)
	return true


## The design's count line: the album's kicker, the forms hatched, and
## each note's count beside its icon.
func _count(slice: Dictionary) -> Control:
	var line := HFlowContainer.new()
	line.add_theme_constant_override("h_separation", UI.px(10))
	line.add_theme_constant_override("v_separation", UI.px(6))
	var kick := StageHeroKit.kicker(Strings.t("CREW_HUB_FORMS"))
	kick.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	line.add_child(kick)
	header_label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	line.add_child(header_label)
	var had := {}
	for f: Dictionary in (slice.get("view", {}) as Dictionary).get("forms", []):
		if int(f["owned"]) > 0:
			had[f["note"]] = int(had.get(f["note"], 0)) + 1
	for note: String in GLYPH:
		var each := HBoxContainer.new()
		each.add_theme_constant_override("separation", UI.px(2))
		each.add_child(Icons.view("lawnotes/" + note, 20.0))
		var n := StageHeroKit.words(str(int(had.get(note, 0))), 15.0, StageHeroSkin.LIGHT)
		n.add_theme_font_override("font", StageHeroSkin.numbers_font())
		each.add_child(n)
		each.accessibility_name = "%s: %d" % [FormsPresenter.note_name(note), int(had.get(note, 0))]
		each.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		line.add_child(each)
	return line


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


## A note's badge: the design's icon for the note on its colour, bright
## when had, dim when not; its glyph is kept as its words (`mark`) for a
## screen reader and the album's own checks.
static func _pip(note: String, had: bool, points := 22.0) -> PanelContainer:
	var colour: Color = StageHeroSculpt.NOTE.get(note, StageHeroSkin.OUTLINE)
	var holder := CenterContainer.new()
	holder.custom_minimum_size = Vector2.ONE * UI.px(points * 0.8)
	var icon := Icons.view("lawnotes/" + note, points * 0.72)
	if not had:
		icon.modulate = Color(1, 1, 1, 0.45)
	holder.add_child(icon)
	var mark := Label.new()
	mark.text = str(GLYPH.get(note, "?"))
	mark.name = "Mark"
	mark.visible = false
	holder.add_child(mark)
	var p := StageHeroMaterial.panel("#" + (colour.darkened(0.45) if had else Color("#2A1E52")).to_html(false), holder,
		99.0, 1.0)
	p.custom_minimum_size = Vector2.ONE * UI.px(points)
	p.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	p.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	return p


## A note's dot on a tile, as the design's: filled in the note's colour
## when its form is had, hollow when not, always in the notes' order. A flat
## box, so a grid of 18 kinds stays inside §21.3's draw calls; its glyph is
## kept as its words (`mark`) as `_pip` keeps it.
static func _dot(note: String, had: bool) -> PanelContainer:
	var colour: Color = StageHeroSculpt.NOTE.get(note, StageHeroSkin.OUTLINE)
	var p := PanelContainer.new()
	var b := StyleBoxFlat.new()
	b.bg_color = colour if had else Color("#1A1236")
	b.border_color = StageHeroSkin.OUTLINE if had else colour.darkened(0.2)
	b.set_border_width_all(UI.px(2))
	b.set_corner_radius_all(UI.px(99))
	p.add_theme_stylebox_override("panel", b)
	p.custom_minimum_size = Vector2.ONE * UI.px(14)
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var mark := Label.new()
	mark.text = str(GLYPH.get(note, "?"))
	mark.name = "Mark"
	mark.visible = false
	p.add_child(mark)
	return p


## A kind's tile: its portrait in its first form had (a silhouette with
## none), its three notes' pips, each the form it is, and its name; a tick
## when all three are had and its outfit is unlocked. A tap stands it on the stage.
func _tile(k: Dictionary, o: Dictionary) -> Control:
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", UI.px(4))
	# The kind in its own look once any form is hatched, as the design's
	# album shows it; a silhouette until then.
	var look := "shadow"
	for f: Dictionary in k["forms"]:
		if int(f["owned"]) > 0:
			look = ""
			break
	var tile := StageHeroSkin.portrait_tile(str(k["kind"]), look, 118.0)
	tile.custom_minimum_size.x = UI.px(60)
	tile.gui_input.connect(_choose.bind(str(k["kind"])))
	if not o.is_empty() and int(o["have"]) >= int(o["of"]):
		var done := StageHeroSkin.badge("✓", Color("#1F6A35"), 16.0)
		done.accessibility_name = Strings.t("FORMS_OUTFIT_DONE", int(o["of"]))
		StageHeroSkin.pin(tile, done, Control.PRESET_BOTTOM_RIGHT)
	v.add_child(tile)
	var pips := HBoxContainer.new()
	pips.alignment = BoxContainer.ALIGNMENT_CENTER
	pips.add_theme_constant_override("separation", UI.px(4))
	for f: Dictionary in k["forms"]:
		var pip := _dot(str(f["note"]), int(f["owned"]) > 0)
		var mark := pip.find_child("Mark", true, false) as Label
		mark.set_meta("form", "%s/%s" % [k["kind"], f["note"]])
		pip.accessibility_name = str(f["text"])
		pips.add_child(pip)
	# The notes' pips over the picture's top corner, as the design's cards.
	pips.alignment = BoxContainer.ALIGNMENT_BEGIN
	pips.add_theme_constant_override("separation", UI.px(2))
	StageHeroSkin.pin(tile, pips, Control.PRESET_TOP_LEFT)
	var name := StageHeroKit.words(k["title"], 14.0,
		StageHeroSkin.LIGHT if look != "shadow" else StageHeroSkin.LIGHT_SOFT)
	name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
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


## The chosen form on the stage, in silhouette until it is hatched; drawn
## again only when that changes.
func _stand(k: Dictionary) -> void:
	if k.is_empty():
		return
	var f := _form(k)
	var look := str(f["note"]) if int(f["owned"]) > 0 else "shadow"
	var key := "%s%s" % [k["kind"], look]
	if str(stage.get_meta("showing", "")) == key:
		return
	stage.set_meta("showing", key)
	stage.plinth_edge = StageHeroSculpt.NOTE.get(str(f["note"]), Color("#E9B65C"))
	stage.show_kinds([str(k["kind"])], [look], "plinth")


## Over the stage, as the design's: the form's note on a plate at the
## plinth, and small arrows through the album's kinds at the sides.
func _over_stage(k: Dictionary, kinds: Array) -> void:
	for n in stage.get_children():
		if n.has_meta("words"):
			n.queue_free()
	if k.is_empty():
		return
	var over := MarginContainer.new()
	over.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	over.mouse_filter = Control.MOUSE_FILTER_IGNORE
	over.set_meta("words", true)
	stage.add_child(over)
	var note := str(_form(k)["note"])
	var colour: Color = StageHeroSculpt.NOTE.get(note, StageHeroSkin.OUTLINE)
	StageHeroSkin.on_stage(over, StageHeroKit.chip(FormsPresenter.note_name(note).to_upper(),
		"#" + colour.darkened(0.5).to_html(false), "lawnotes/" + note), Control.PRESET_CENTER_BOTTOM)
	var at := kinds.find(k)
	if kinds.size() < 2 or at < 0:
		return
	for step: int in [-1, 1]:
		var to: Dictionary = kinds[posmod(at + step, kinds.size())]
		var b := StageHeroKit.small_arrow(step < 0, Strings.t("FORMS_PREVIOUS" if step < 0 else "FORMS_NEXT",
			str(to["title"])), func() -> void:
				chosen = str(to["kind"])
				form_note = ""
				_refresh())
		b.set_meta("item", "step:%d" % step)
		StageHeroSkin.on_stage(over, b, Control.PRESET_CENTER_LEFT if step < 0 else Control.PRESET_CENTER_RIGHT)


## The chosen kind's chosen form.
func _form(k: Dictionary) -> Dictionary:
	var list: Array = k["forms"]
	for f: Dictionary in list:
		if str(f["note"]) == form_note:
			return f
	return list[0]


## Beside the stage: the form's state on a chip, the kind's name in
## Marcellus, its note, a pip for each of its three forms to stand it on
## the stage, and the outfit's progress on a bar.
func _hero(k: Dictionary, _o: Dictionary) -> void:
	for n in hero_info.get_children():
		hero_info.remove_child(n)
		n.queue_free()
	if k.is_empty():
		return
	var f := _form(k)
	var had := int(f["owned"]) > 0
	var note_name := FormsPresenter.note_name(str(f["note"]))
	# As the design's: "Not yet hatched" on a lock chip, or the note with a
	# tick; the form's name ("Echo Skyskipper"); its school and note.
	var state := StageHeroKit.chip(("✓ " + note_name) if had else Strings.t("FORMS_NOT_HATCHED").to_upper(),
		"#1F6A35" if had else "card", "" if had else "generalui/lock")
	hero_info.add_child(state)
	var name := StageHeroKit.words(Strings.t("FORMS_FORM_NAME", [note_name, k["title"]]), 22.0, StageHeroSkin.LIGHT)
	StageHeroSkin.named(name)
	name.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	name.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	name.custom_minimum_size.x = UI.px(80)
	hero_info.add_child(name)
	var school := StageHeroFigure.school(StageHeroFigure.key(str(k["kind"])))
	var line := StageHeroKit.para(Strings.t("FORMS_KIND_LINE", [Strings.t("SCHOOL_" + school.to_upper()), note_name]),
		14.0, StageHeroSkin.LIGHT_SOFT)
	line.accessibility_name = str(f["text"])
	hero_info.add_child(line)
	var pips := HBoxContainer.new()
	pips.add_theme_constant_override("separation", UI.px(4))
	for each: Dictionary in k["forms"]:
		var note := str(each["note"])
		var b := Button.new()
		b.custom_minimum_size = Vector2.ONE * UI.px(48)
		b.accessibility_name = str(each["text"])
		b.set_meta("item", "form:%s" % note)
		for st: String in ["normal", "hover", "pressed", "focus", "disabled"]:
			var ring := StyleBoxFlat.new()
			ring.bg_color = Color(0, 0, 0, 0)
			ring.draw_center = false
			ring.set_corner_radius_all(UI.px(99))
			var on := note == str(f["note"])
			ring.border_color = Color("#FFF3CC") if on or st == "focus" else Color(0, 0, 0, 0)
			ring.set_border_width_all(UI.px(2))
			b.add_theme_stylebox_override(st, ring)
		var pip := _pip(note, int(each["owned"]) > 0, 38.0)
		pip.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
		pip.mouse_filter = Control.MOUSE_FILTER_IGNORE
		b.add_child(pip)
		b.pressed.connect(func() -> void:
			form_note = note
			_refresh())
		pips.add_child(b)
	hero_info.add_child(pips)
	# How many of the kind's forms are hatched, on a bar, as the design's.
	var forms_of: Array = k["forms"]
	var have := forms_of.filter(func(x: Dictionary) -> bool: return int(x["owned"]) > 0).size()
	var of := maxi(1, forms_of.size())
	hero_info.add_child(StageHeroBar.make(float(have) / float(of), Color("#3FBF7F") if have >= of
		else Color("#E9B65C"), "", 10.0))
	hero_info.add_child(StageHeroKit.para(Strings.t("FORMS_COUNT_OF", [have, of, k["title"]]), 13.0,
		StageHeroSkin.LIGHT_SOFT))


func _choose(event: InputEvent, kind: String) -> void:
	if event is InputEventMouseButton and (event as InputEventMouseButton).pressed:
		chosen = kind
		form_note = ""
		_refresh()
