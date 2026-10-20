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
	column.add_child(StageHeroSkin.title(UI.title(Strings.t("FORMS_TITLE"))))
	header_label = UI.label("", UI.TEXT_POINTS, true)
	column.add_child(StageHeroSkin.plate(header_label, true))
	status_label = UI.status("info", "")
	column.add_child(StageHeroSkin.plate(status_label))
	body = UI.scroll(column)
	stage = StageHero.new()
	stage.custom_minimum_size = Vector2(0, UI.px(210))
	stage.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.add_child(stage)
	cards = VBoxContainer.new()
	cards.add_theme_constant_override("separation", UI.px(Tokens.number("size", "gap_points")))
	body.add_child(cards)
	var actions := UI.row(-1.0, true)
	toggle = StageHeroSkin.button(UI.button(Strings.t("FORMS_SHOW_MINE"), _toggle))
	UI.fit_to(toggle, [Strings.t("FORMS_SHOW_ALL")])
	actions.add_child(toggle)
	actions.add_child(StageHeroSkin.button(UI.button(Strings.t("COMMON_HOME"),
		func() -> void: App.services.router.go(&"home"), true), true))
	column.add_child(UI.narrow(actions))


func _toggle() -> void:
	controller.show_mine(not bool(App.services.store.get_slice(FormsState.FORMS)["mine"]))


func _refresh() -> void:
	if not is_inside_tree():
		return
	var a := FormsPresenter.screen(App.services.store.get_slice(FormsState.FORMS))
	if a["error"] != "":
		UI.set_status(status_label, "alarm", a["error"])
	elif a["busy"] != "" or not a["ready"]:
		UI.set_status(status_label, "info", Strings.t("COMMON_LOADING"))
	else:
		UI.set_status(status_label, "info", "")
	status_label.get_parent().visible = status_label.text != ""
	header_label.text = a.get("header", "")
	UI.relabel(toggle, a["toggle"]["action"], true)
	toggle.set_meta("mine", a["mine"])
	for c in cards.get_children():
		cards.remove_child(c)
		c.queue_free()
	var kinds: Array = a.get("kinds", [])
	stage.visible = a["ready"] and not kinds.is_empty()
	if not a["ready"]:
		return
	_stand(kinds)
	for k: Dictionary in kinds:
		var box := VBoxContainer.new()
		box.add_child(StageHeroSkin.named(UI.label(k["title"], UI.TITLE_POINTS * 0.75, true)))
		var tiles := HBoxContainer.new()
		tiles.add_theme_constant_override("separation", UI.px(6))
		for f: Dictionary in k["forms"]:
			var tile := StageHeroSkin.portrait_tile(str(k["kind"]), str(f["note"]) if int(f["owned"]) > 0 else "shadow",
				84.0)
			tile.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			tile.gui_input.connect(_choose.bind(str(k["kind"])))
			tiles.add_child(tile)
		box.add_child(tiles)
		box.add_child(UI.label(k["outfit"], UI.TEXT_POINTS, true))
		for f: Dictionary in k["forms"]:
			var line := UI.label(f["text"], UI.TEXT_POINTS, true)
			line.set_meta("form", "%s/%s" % [k["kind"], f["note"]])
			box.add_child(line)
		cards.add_child(StageHeroSkin.plate(box))
	for n: Dictionary in a["notes"]:
		var box := VBoxContainer.new()
		for line: String in [n["title"], n["look"], n["quirk"], n["how"]]:
			box.add_child(UI.label(line, UI.TEXT_POINTS, true))
		cards.add_child(StageHeroSkin.plate(box, true))
	var sails := VBoxContainer.new()
	sails.add_child(StageHeroSkin.named(UI.label(Strings.t("FORMS_SAILS_TITLE"), UI.TEXT_POINTS, true)))
	for s: String in a["sails"]:
		sails.add_child(UI.label(s, UI.TEXT_POINTS, true))
	cards.add_child(StageHeroSkin.plate(sails, true))


## The chosen kind's three forms side by side, one not hatched in silhouette.
func _stand(kinds: Array) -> void:
	if kinds.is_empty():
		return
	var k: Dictionary = kinds[0]
	for each: Dictionary in kinds:
		if str(each["kind"]) == chosen:
			k = each
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
	for f: Dictionary in k["forms"]:
		var p := StageHeroSkin.pill(FormsPresenter.note_name(str(f["note"])))
		p.size_flags_horizontal = Control.SIZE_EXPAND | Control.SIZE_SHRINK_CENTER
		names.add_child(p)
	StageHeroSkin.on_stage(stage, names, Control.PRESET_CENTER_BOTTOM).set_meta("words", true)
	names.size_flags_horizontal = Control.SIZE_EXPAND_FILL


func _choose(event: InputEvent, kind: String) -> void:
	if event is InputEventMouseButton and (event as InputEventMouseButton).pressed:
		chosen = kind
		_refresh()
