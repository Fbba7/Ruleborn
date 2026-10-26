class_name SageHallScreen
extends Control
## The Sage hall (§23.2, "Heroes"): the Sages' level, which is the Keeper's;
## each Sage's heist powers and at-home effect, and what every fifth level
## adds, those reached marked in words; when a locked Sage unlocks; and which
## Sage guards the Heart (§11.7). It draws the store; Services' `sage_flow`
## asks. The Sages stand together in their hall on a 3D stage (§21.6), a
## locked one as a silhouette, the one on guard a step forward; each card
## carries its portrait rendered from its model (§21.3).

## Each launch Sage's three heist powers' icons, in its card's order (the
## design's `sagepowers` set).
const POWER_ICONS := {"THE_ARCHIVIST": ["suspend", "reveal", "recall"], "THE_TINKERER": ["invert", "jam", "plank"],
	"THE_GARDENER": ["vinebridge", "renew", "decoy"], "THE_WANDERER": ["copy", "rift", "tailwind"]}

var controller: SageController
var body: VBoxContainer
var header_label: Label
var guard_label: Label
var status_label: Label
var stage: StageHero
var cards: VBoxContainer
## The Sage whose powers and levels are shown, by id; the one on guard, or
## the first, when none is chosen.
var chosen := ""


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
	# The hall runs to the screen's edges and under the status bar.
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
	body.add_child(RosterScreen.padded(StageHeroKit.hub(1)))
	# The hall, every Sage in it, on the design's rimmed hero card.
	stage = StageHero.new()
	stage.custom_minimum_size = Vector2(0, UI.px(230))
	stage.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.add_child(RosterScreen.padded(StageHeroMaterial.panel("rim", stage, 18.0, 4.0)))
	var top := VBoxContainer.new()
	top.add_theme_constant_override("separation", UI.px(2))
	header_label = StageHeroKit.words("", 15.0, StageHeroSkin.LIGHT)
	header_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	top.add_child(header_label)
	guard_label = StageHeroKit.words("", 15.0, Color("#FFE6A0"))
	guard_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	top.add_child(guard_label)
	cards = VBoxContainer.new()
	cards.add_theme_constant_override("separation", UI.px(10))
	cards.add_child(StageHeroMaterial.panel("glass", top, 14.0, 8.0))
	body.add_child(RosterScreen.padded(cards))
	column.add_child(StageHeroKit.tab_bar())


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
	status_label.get_parent().get_parent().visible = status_label.text != ""
	header_label.text = h.get("header", "")
	guard_label.text = h.get("guard", "")
	for c in cards.get_children():
		if c.get_index() > 0:
			cards.remove_child(c)
			c.queue_free()
	stage.visible = h["ready"]
	if not h["ready"]:
		return
	_stand(h["sages"])
	var busy: bool = h["busy"] != ""
	var shown: Dictionary = {}
	for s: Dictionary in h["sages"]:
		if str(s["id"]) == chosen or (shown.is_empty() and s["guarding"]):
			shown = s
	if shown.is_empty() and not (h["sages"] as Array).is_empty():
		shown = h["sages"][0]
	if not shown.is_empty():
		cards.add_child(_sage(shown))
	var count := StageHeroKit.kicker(Strings.t("CREW_HUB_SAGES"))
	cards.add_child(count)
	var tiles: Array = []
	for s: Dictionary in h["sages"]:
		tiles.append(_tile(s, busy, str(s["id"]) == str(shown.get("id", ""))))
	cards.add_child(StageHeroKit.grid(tiles, self))
	StageHeroSkin.cap_buttons(cards, get_viewport_rect().size.x - UI.px(64))
	if focus_item != "":
		for b: Button in find_children("*", "Button", true, false):
			if b.get_meta("item", "") == focus_item and b.is_visible_in_tree():
				b.grab_focus.call_deferred()
				break


## The Sages in their hall, the one on guard a step forward, a locked one
## in silhouette, each named beneath on a row of plates that shrink their
## words, and wrap them, to fit; drawn again only when that changes.
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
	for n in stage.get_children():
		if n.has_meta("words"):
			n.queue_free()
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", UI.px(4))
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for s: Dictionary in sages:
		row.add_child(_name_plate(s, sages.size()))
	var m := StageHeroSkin.on_stage(stage, row, Control.PRESET_CENTER_BOTTOM)
	m.set_meta("words", true)
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL


## A Sage's name on the hall's floor, under where it stands: Marcellus on a
## glass plate, gold-edged for the one on guard; its words a size smaller
## for every Sage past three, and wrapping when still too long.
static func _name_plate(s: Dictionary, count: int) -> Control:
	var points := clampf(17.0 - float(maxi(0, count - 2)) * 2.0, 13.0, 17.0)
	var l := StageHeroKit.words(str(s["name"]), points, StageHeroSkin.LIGHT if s["unlocked"] else StageHeroSkin.LIGHT_SOFT)
	StageHeroSkin.named(l)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD
	l.custom_minimum_size.x = UI.px(40)
	var p := StageHeroMaterial.panel("rim" if s["guarding"] else "glass", l, 10.0, 5.0)
	p.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	p.size_flags_vertical = Control.SIZE_SHRINK_END
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return p


## The chosen Sage's card: its portrait with its school's shape and the
## guard's mark, its name, whether it is unlocked or on guard as chips, its
## powers, its at-home and on-guard effects, and every fifth level's gain on
## a track of pips.
func _sage(s: Dictionary) -> Control:
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", UI.px(6))
	# Portrait beside the name, or above it at §20.8's larger text.
	var head: BoxContainer = HBoxContainer.new()
	if Settings.text_scale > 100:
		head = VBoxContainer.new()
	head.add_theme_constant_override("separation", UI.px(10))
	var tile := StageHeroSkin.portrait_tile(str(s["id"]), "" if s["unlocked"] else "shadow", 96.0)
	tile.custom_minimum_size.x = UI.px(96)
	var school := StageHeroFigure.school(StageHeroFigure.key(str(s["id"])))
	var shade: Color = (Palette.SCHOOL.get(school, Palette.MOTION) as Color).darkened(0.55)
	StageHeroSkin.pin(tile, StageHeroSkin.badge(str(UI.SHAPE_GLYPH.get(Tokens.shape(school), "")), shade, 16.0),
		Control.PRESET_TOP_RIGHT)
	if s["guarding"]:
		# The Roster's mark for a guard, so the post reads without its colour.
		StageHeroSkin.pin(tile, StageHeroSkin.badge(str(RosterPresenter.MARK["guarding"]), Palette.MATTER.darkened(0.45),
			16.0), Control.PRESET_TOP_LEFT)
	head.add_child(tile)
	var side := VBoxContainer.new()
	side.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	side.add_theme_constant_override("separation", UI.px(4))
	var name := StageHeroKit.words(s["name"], 24.0, StageHeroSkin.LIGHT)
	StageHeroSkin.named(name)
	name.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	name.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	name.custom_minimum_size.x = UI.px(80)
	side.add_child(name)
	var chips := HFlowContainer.new()
	chips.add_theme_constant_override("h_separation", UI.px(6))
	chips.add_theme_constant_override("v_separation", UI.px(4))
	chips.add_child(StageHeroKit.chip(s["lock"], "#1F6A35" if s["unlocked"] else "card", "✓" if s["unlocked"] else ""))
	if s["guarding"]:
		chips.add_child(StageHeroKit.chip(Strings.t("SAGE_ON_GUARD"), "#5A3FB0", "sagepowers/onguard"))
	side.add_child(chips)
	head.add_child(side)
	box.add_child(head)
	if s["guarding"]:
		box.add_child(StageHeroKit.para(Strings.t("SAGE_STAYS"), 15.0, Color("#FFE6A0")))
	var key := str(s["id"]).to_upper()
	box.add_child(StageHeroKit.kicker(Strings.t("SAGE_KICK_POWERS")))
	for i: int in [1, 2, 3]:
		if Strings.rows().has("SAGE_POWER_%s_%d" % [key, i]):
			box.add_child(_power(key, i))
	var home := StageHeroKit.grid([
		StageHeroKit.card(Strings.t("SAGE_KICK_HOME"), StageHeroKit.para(Strings.t("SAGE_HOME_ONLY_" + key), 15.0),
			"well"),
		StageHeroKit.card(Strings.t("SAGE_KICK_GUARD"), StageHeroKit.para(_sentence(Strings.t("SAGE_GUARD_" + key)),
			15.0), "well")], self)
	box.add_child(home)
	box.add_child(StageHeroKit.kicker(Strings.t("SAGE_EVERY_FIFTH")))
	for lv: Dictionary in s["levels"]:
		box.add_child(_step(lv))
	return StageHeroMaterial.panel("card", box, 16.0, 12.0)


## One fifth level on the track: a round pip with its number, gold and
## ticked when reached, and what it adds.
static func _step(lv: Dictionary) -> Control:
	var line := HBoxContainer.new()
	line.add_theme_constant_override("separation", UI.px(8))
	var reached: bool = lv["reached"]
	var pip := StageHeroSkin.badge(str(lv["level"]), Color("#E9B65C") if reached else Color("#3A2A6A"), 15.0)
	pip.custom_minimum_size = Vector2.ONE * UI.px(30)
	line.add_child(pip)
	var words := StageHeroKit.para(lv["text"], 14.0, StageHeroSkin.LIGHT if reached else StageHeroSkin.LIGHT_SOFT)
	words.set_meta("reached", reached)
	words.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	line.add_child(words)
	return line


## One heist power: its name on a gold chip and its uses beside it, then
## what it does.
static func _power(key: String, i: int) -> Control:
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", UI.px(3))
	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", UI.px(6))
	var icons: Array = POWER_ICONS.get(key, [])
	head.add_child(StageHeroKit.chip(Strings.t("SAGE_POWER_%s_%d" % [key, i]), "gold",
		"sagepowers/" + str(icons[i - 1]) if i <= icons.size() else ""))
	head.add_child(StageHeroKit.chip(Strings.t("SAGE_POWER_USES_%s_%d" % [key, i]), "card"))
	v.add_child(head)
	v.add_child(StageHeroKit.para(_sentence(Strings.t("SAGE_POWER_DOES_%s_%d" % [key, i])), 15.0))
	return v


## A card's clause as a sentence: its first letter raised.
static func _sentence(words: String) -> String:
	return words.left(1).to_upper() + words.substr(1)


## A Sage's tile in the hall's grid: its portrait (a silhouette while
## locked) with the guard's mark, its name, and the guard choice, saying
## why it waits; a tap on the portrait shows its powers above.
func _tile(s: Dictionary, busy: bool, shown: bool) -> Control:
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", UI.px(4))
	var tile := StageHeroSkin.portrait_tile(str(s["id"]), "" if s["unlocked"] else "shadow", 96.0)
	tile.gui_input.connect(func(e: InputEvent) -> void:
		if e is InputEventMouseButton and (e as InputEventMouseButton).pressed:
			chosen = str(s["id"])
			_refresh())
	if s["guarding"]:
		StageHeroSkin.pin(tile, StageHeroSkin.badge(str(RosterPresenter.MARK["guarding"]), Palette.MATTER.darkened(0.45),
			16.0), Control.PRESET_TOP_LEFT)
	v.add_child(tile)
	var name := StageHeroKit.words(s["name"], 16.0, StageHeroSkin.LIGHT)
	StageHeroSkin.named(name)
	name.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	name.custom_minimum_size.x = UI.px(60)
	v.add_child(name)
	if not s["unlocked"]:
		v.add_child(StageHeroKit.chip(s["lock"], "card", "generalui/lock", true))
	var o: Dictionary = s["button"]
	var b := UI.button(o["action"], controller.station.bind(o["sage"]), false, Color(), o["spoken"])
	StageHeroMaterial.button(b, "gold" if s["unlocked"] and not s["guarding"] else "leather")
	b.disabled = busy or not o["can"]
	b.set_meta("key", o["key"])
	b.set_meta("item", o["item"])
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	v.add_child(b)
	StageHeroSkin.cap_buttons(v, UI.px(130))
	return StageHeroMaterial.panel("rim" if shown else "card", v, 14.0, 6.0)
