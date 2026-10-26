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
## Beside the stage: the chosen Sage's chips, name, school and the level.
var hero_info: VBoxContainer
var cards: VBoxContainer
## The Sage whose powers and levels are shown, by id; the one on guard, or
## the first, when none is chosen.
var chosen := ""
## The power shown on the chosen Sage's card, by its place (the design's
## power tabs).
var power := 0


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
	# The design's hero card: the chosen Sage in the hall at the left, its
	# chips, name, school and the Sages' level at the right.
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
	hero_info.add_theme_constant_override("separation", UI.px(5))
	hero.add_child(hero_info)
	body.add_child(RosterScreen.padded(StageHeroMaterial.panel("rim", hero, 18.0, 4.0)))
	header_label = StageHeroKit.words("", 14.0, Color("#8FF0A8"))
	header_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	header_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	header_label.custom_minimum_size.x = UI.px(80)
	guard_label = StageHeroKit.words("", 15.0, Color("#FFE6A0"))
	guard_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	cards = VBoxContainer.new()
	cards.add_theme_constant_override("separation", UI.px(10))
	cards.add_child(StageHeroMaterial.panel("glass", guard_label, 14.0, 8.0))
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
	if header_label.get_parent() != null:
		header_label.get_parent().remove_child(header_label)
	for n in hero_info.get_children():
		hero_info.remove_child(n)
		n.queue_free()
	stage.visible = h["ready"]
	if not h["ready"]:
		return
	var busy: bool = h["busy"] != ""
	var shown: Dictionary = {}
	for s: Dictionary in h["sages"]:
		if str(s["id"]) == chosen or (shown.is_empty() and s["guarding"]):
			shown = s
	if shown.is_empty() and not (h["sages"] as Array).is_empty():
		shown = h["sages"][0]
	if not shown.is_empty():
		_stand(shown, h["sages"])
		_hero(shown)
		cards.add_child(_powers(shown))
	var count := StageHeroKit.kicker(Strings.t("CREW_HUB_SAGES"))
	cards.add_child(count)
	var tiles: Array = []
	for s: Dictionary in h["sages"]:
		tiles.append(_tile(s, busy, str(s["id"]) == str(shown.get("id", ""))))
	# Three to a row, as the design's; fewer at §20.8's larger text.
	var grid := GridContainer.new()
	grid.columns = 3 if Settings.text_scale <= 100 else (2 if Settings.text_scale <= 150 else 1)
	grid.add_theme_constant_override("h_separation", UI.px(5))
	grid.add_theme_constant_override("v_separation", UI.px(8))
	for t: Control in tiles:
		t.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		grid.add_child(t)
	cards.add_child(grid)
	if not shown.is_empty():
		cards.add_child(_sage(shown))
	StageHeroSkin.cap_buttons(cards, get_viewport_rect().size.x - UI.px(64))
	if focus_item != "":
		for b: Button in find_children("*", "Button", true, false):
			if b.get_meta("item", "") == focus_item and b.is_visible_in_tree():
				b.grab_focus.call_deferred()
				break


## The chosen Sage in its hall, a silhouette while locked; the arrows
## through the Sages over it. Drawn again only when that changes.
func _stand(s: Dictionary, sages: Array) -> void:
	var key := "%s%s" % [s["id"], s["unlocked"]]
	if str(stage.get_meta("showing", "")) != key:
		stage.set_meta("showing", key)
		stage.show_kinds([str(s["id"])], ["" if s["unlocked"] else "shadow"])
	for n in stage.get_children():
		if n.has_meta("words"):
			n.queue_free()
	var ids: Array = sages.map(func(x: Dictionary) -> String: return str(x["id"]))
	var at := ids.find(str(s["id"]))
	var over := MarginContainer.new()
	over.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	over.mouse_filter = Control.MOUSE_FILTER_IGNORE
	over.set_meta("words", true)
	stage.add_child(over)
	if ids.size() > 1:
		for step: int in [-1, 1]:
			var to: Dictionary = sages[posmod(at + step, ids.size())]
			var b := StageHeroKit.arrow(step < 0, Strings.t("CHARACTER_PREVIOUS" if step < 0 else "CHARACTER_NEXT",
				str(to["name"])), _choose.bind(str(to["id"])))
			b.set_meta("item", "step:%d" % step)
			StageHeroSkin.on_stage(over, b, Control.PRESET_CENTER_LEFT if step < 0 else Control.PRESET_CENTER_RIGHT)


## Beside the stage: whether the chosen Sage is unlocked or on guard as
## chips, its name in Marcellus, its school, and the Sages' level.
func _hero(s: Dictionary) -> void:
	var chips := HFlowContainer.new()
	chips.add_theme_constant_override("h_separation", UI.px(6))
	chips.add_theme_constant_override("v_separation", UI.px(4))
	chips.add_child(StageHeroKit.chip(s["lock"], "#1F6A35" if s["unlocked"] else "card", "✓" if s["unlocked"] else ""))
	hero_info.add_child(chips)
	var name := StageHeroKit.words(s["name"], 26.0, StageHeroSkin.LIGHT)
	StageHeroSkin.named(name)
	name.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	name.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	name.custom_minimum_size.x = UI.px(80)
	hero_info.add_child(name)
	var school := StageHeroFigure.school(StageHeroFigure.key(str(s["id"])))
	hero_info.add_child(StageHeroKit.para(Strings.t("SCHOOL_" + school.to_upper()), 14.0, StageHeroSkin.LIGHT_SOFT))
	hero_info.add_child(header_label)


func _choose(which: String) -> void:
	chosen = which
	power = 0
	_refresh()


## The chosen Sage's card: its portrait with its school's shape and the
## guard's mark, its name, whether it is unlocked or on guard as chips, its
## powers, its at-home and on-guard effects, and every fifth level's gain on
## a track of pips.
func _sage(s: Dictionary) -> Control:
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", UI.px(6))
	if s["guarding"]:
		box.add_child(StageHeroKit.para(Strings.t("SAGE_STAYS"), 15.0, Color("#FFE6A0")))
	var key := str(s["id"]).to_upper()
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


## The chosen Sage's heist powers as the design's: a tab for each, and the
## chosen power's card.
func _powers(s: Dictionary) -> Control:
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", UI.px(6))
	var key := str(s["id"]).to_upper()
	box.add_child(StageHeroKit.kicker(Strings.t("SAGE_KICK_POWERS")))
	# The design's power tabs: each power's name and icon, the chosen one's
	# uses and what it does beneath.
	var names: Array = []
	var icons: Array = []
	var own: Array = POWER_ICONS.get(key, [])
	for i: int in [1, 2, 3]:
		if Strings.rows().has("SAGE_POWER_%s_%d" % [key, i]):
			names.append(Strings.t("SAGE_POWER_%s_%d" % [key, i]))
			icons.append("sagepowers/" + str(own[i - 1]) if i <= own.size() else "")
	if not names.is_empty():
		power = clampi(power, 0, names.size() - 1)
		box.add_child(StageHeroKit.tabs(names, power, func(i: int) -> void:
			power = i
			_refresh(), icons))
		box.add_child(_power(key, power + 1))
	return box


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


## One heist power as the design's parchment card: its icon in a round
## well, its name and its uses, then what it does.
static func _power(key: String, i: int) -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", UI.px(10))
	var icons: Array = POWER_ICONS.get(key, [])
	var icon := "sagepowers/" + str(icons[i - 1]) if i <= icons.size() else ""
	if Icons.has(icon):
		var well := StageHeroSkin.badge("", Color("#3A2A6A"), 15.0)
		well.custom_minimum_size = Vector2.ONE * UI.px(48)
		var view := Icons.view(icon, 34.0)
		view.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
		well.add_child(view)
		well.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		row.add_child(well)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", UI.px(2))
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var head := HFlowContainer.new()
	head.add_theme_constant_override("h_separation", UI.px(8))
	var name := StageHeroKit.words(Strings.t("SAGE_POWER_%s_%d" % [key, i]), 18.0, Color("#2A1A10"))
	name.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	head.add_child(name)
	head.add_child(StageHeroKit.chip(Strings.t("SAGE_POWER_USES_%s_%d" % [key, i]), "#7A1E52"))
	v.add_child(head)
	v.add_child(StageHeroKit.para(_sentence(Strings.t("SAGE_POWER_DOES_%s_%d" % [key, i])), 15.0, Color("#4A3020")))
	row.add_child(v)
	for l: Label in row.find_children("*", "Label", true, false):
		l.set_meta("own_ink", true)
	return StageHeroMaterial.panel("parchment", row, 14.0, 10.0)


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
			_choose(str(s["id"])))
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
	StageHeroSkin.cap_buttons(v, UI.px(80))
	return StageHeroMaterial.panel("rim" if shown else "card", v, 14.0, 4.0)
