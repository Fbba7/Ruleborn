class_name SageHallScreen
extends Control
## The Sage hall (§23.2, "Heroes"): the Sages' level, which is the Keeper's;
## each Sage's heist powers and at-home effect, and what every fifth level
## adds, those reached marked in words; when a locked Sage unlocks; and which
## Sage guards the Heart (§11.7). It draws the store; Services' `sage_flow`
## asks. The Sages stand together in their hall on a 3D stage (§21.6), a
## locked one as a silhouette, the one on guard a step forward; each card
## carries its portrait rendered from its model (§21.3).

var controller: SageController
var body: VBoxContainer
var header_label: Label
var guard_label: Label
var status_label: Label
var stage: StageHero
var cards: VBoxContainer


func _ready() -> void:
	App.ready(self)
	controller = App.services.sage_flow
	_build()
	App.services.store.changed.connect(_on_changed)
	_refresh()
	await controller.load_sages()


func _on_changed(slice: StringName) -> void:
	if slice == SageState.SAGES and is_inside_tree():
		_refresh()


func _build() -> void:
	var column := UI.frame(self)
	StageHeroSkin.night(self)
	column.add_child(StageHeroSkin.title(UI.title(Strings.t("SAGE_TITLE"))))
	var top := VBoxContainer.new()
	header_label = UI.label("", UI.TEXT_POINTS, true)
	top.add_child(header_label)
	guard_label = UI.label("", UI.TEXT_POINTS, true)
	top.add_child(guard_label)
	column.add_child(StageHeroSkin.plate(top, true))
	status_label = UI.status("info", "")
	column.add_child(StageHeroSkin.plate(status_label))
	body = UI.scroll(column)
	stage = StageHero.new()
	stage.custom_minimum_size = Vector2(0, UI.px(230))
	stage.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.add_child(stage)
	cards = VBoxContainer.new()
	cards.add_theme_constant_override("separation", UI.px(Tokens.number("size", "gap_points")))
	body.add_child(cards)
	var actions := UI.row(-1.0, true)
	actions.add_child(StageHeroSkin.button(UI.button(Strings.t("COMMON_HOME"),
		func() -> void: App.services.router.go(&"home"), true), true))
	column.add_child(UI.narrow(actions))


func _refresh() -> void:
	if not is_inside_tree():
		return
	var focused := get_viewport().gui_get_focus_owner()
	var focus_item := str(focused.get_meta("item", "")) if focused != null else ""
	var h := SagePresenter.screen(App.services.store.get_slice(SageState.SAGES))
	if h["error"] != "":
		UI.set_status(status_label, "alarm", h["error"])
	elif h["said"] != "":
		UI.set_status(status_label, "success", h["said"])
	elif h["busy"] != "" or not h["ready"]:
		UI.set_status(status_label, "info", Strings.t("COMMON_LOADING"))
	else:
		UI.set_status(status_label, "info", "")
	status_label.get_parent().visible = status_label.text != ""
	header_label.text = h.get("header", "")
	guard_label.text = h.get("guard", "")
	for c in cards.get_children():
		cards.remove_child(c)
		c.queue_free()
	stage.visible = h["ready"]
	if not h["ready"]:
		return
	_stand(h["sages"])
	var busy: bool = h["busy"] != ""
	for s: Dictionary in h["sages"]:
		cards.add_child(_sage(s, busy))
	StageHeroSkin.cap_buttons(cards, get_viewport_rect().size.x - UI.px(64))
	if focus_item != "":
		for b: Button in find_children("*", "Button", true, false):
			if b.get_meta("item", "") == focus_item and b.is_visible_in_tree():
				b.grab_focus.call_deferred()
				break


## The Sages in their hall, the one on guard a step forward, a locked one
## in silhouette; drawn again only when that changes.
func _stand(sages: Array) -> void:
	var list: Array[String] = []
	var looks: Array[String] = []
	var guard := -1
	for s: Dictionary in sages:
		list.append(str(s["id"]))
		looks.append("" if s["unlocked"] else "shadow")
		if s["guarding"]:
			guard = list.size() - 1
	var key := "%s%s%d" % [list, looks, guard]
	if str(stage.get_meta("showing", "")) == key:
		return
	stage.set_meta("showing", key)
	stage.show_kinds(list, looks, "hall")
	if guard >= 0:
		stage.tables[guard].position.z += 0.35


func _sage(s: Dictionary, busy: bool) -> Control:
	var box := VBoxContainer.new()
	var tile := StageHeroSkin.portrait_tile(str(s["id"]), "" if s["unlocked"] else "shadow", 120.0)
	var school := StageHeroFigure.school(StageHeroFigure.key(str(s["id"])))
	var shade: Color = (Palette.SCHOOL.get(school, Palette.MOTION) as Color).darkened(0.55)
	StageHeroSkin.pin(tile, StageHeroSkin.badge(str(UI.SHAPE_GLYPH.get(Tokens.shape(school), "")), shade, 18.0),
		Control.PRESET_TOP_RIGHT)
	if s["guarding"]:
		# The Roster's mark for a guard, so the post reads without its colour.
		StageHeroSkin.pin(tile, StageHeroSkin.badge(str(RosterPresenter.MARK["guarding"]), Palette.MATTER.darkened(0.45),
			18.0), Control.PRESET_TOP_LEFT)
	box.add_child(tile)
	box.add_child(StageHeroSkin.named(UI.label(s["name"], UI.TITLE_POINTS * 0.75, true)))
	box.add_child(UI.status("success" if s["unlocked"] else "info", s["lock"]))
	if s["guarding"]:
		box.add_child(UI.status("success", Strings.t("SAGE_ON_GUARD")))
		box.add_child(UI.label(Strings.t("SAGE_STAYS"), UI.TEXT_POINTS, true))
	box.add_child(UI.label(s["powers"], UI.TEXT_POINTS, true))
	box.add_child(UI.label(s["home"], UI.TEXT_POINTS, true))
	box.add_child(UI.label(Strings.t("SAGE_EVERY_FIFTH"), UI.TEXT_POINTS, true))
	for lv: Dictionary in s["levels"]:
		var line := UI.label(lv["text"], UI.TEXT_POINTS, true)
		line.set_meta("reached", lv["reached"])
		box.add_child(line)
	var o: Dictionary = s["button"]
	var b := StageHeroSkin.button(UI.button(o["action"], controller.station.bind(o["sage"]), false, Color(),
		o["spoken"]), s["unlocked"] and not s["guarding"])
	b.disabled = busy or not o["can"]
	b.set_meta("key", o["key"])
	b.set_meta("item", o["item"])
	var r := UI.row()
	r.add_child(b)
	if o["why"] != "":
		r.add_child(UI.label(o["why"], UI.TEXT_POINTS, true))
	box.add_child(r)
	return StageHeroSkin.plate(box)
