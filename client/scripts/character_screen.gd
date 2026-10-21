class_name CharacterScreen
extends Control
## One ruleborn in detail (§23.2: "School, role, ability, traits, level,
## best work"), laid out as the design's Character screen: the character
## idling full-bleed on its hero stage, with the roster's arrows, its place
## in the roster and its state on the stage; its name plate with its school
## and kind; its level on a gold hexagon beside a bar of the levels its home
## allows, and its health; then three tabs. Heist: its ability (§11.11), its
## role and what the role does (§11.1), what it resists, its traits as chips
## with what each does (§11.3), what it is best at, and its forms (§21.6).
## Stats: §11.1's four numbers for its role, as the simulation plays them,
## each on a bar against the largest any role has. Compare: another of the
## roster's, chosen by its portrait, the two side by side on mirrored bars.
## Beneath, fixed: what Essence can do for it now — the next level, or
## waking from a rest (§11.6) — each asked for twice, a first tap showing the
## price, because Essence spent is not given back; and sending it to work.

## The forms the strip shows, in §21.6's order, then the guard form.
const LOOKS := ["hush", "spark", "echo", "guard"]
## §11.1's four numbers, in the order the design's Stats tab shows them,
## each with its glyph and its bar's colour.
const STATS := [["health", "♥", "#5CC46A"], ["speed", "»", "#3CC6D8"], ["power", "✸", "#F07A3C"],
	["carry", "▣", "#F2B43C"]]
## The tabs, by their words' keys.
const TABS := ["CHARACTER_TAB_HEIST", "CHARACTER_TAB_STATS", "CHARACTER_TAB_COMPARE"]

var controller: RosterController
var id := 0
var title_label: Label
var body: VBoxContainer
var status_label: Label
## The hero stage, full-bleed, with its words and arrows over it.
var stage: StageHero
## The forms and guard form as portraits rendered from the model (§21.3).
var forms: HBoxContainer
var level_badge: Control
## Everything under the stage, redrawn on each change.
var cards: VBoxContainer
## The fixed spends beneath the scroll.
var actions: HFlowContainer
## The tab shown, and the character the Compare tab sets beside this one.
var tab := 0
var versus := 0
## The spend tapped once, by its key: the next tap on it spends.
var confirm := ""
var clock: Callable = func() -> int: return int(Time.get_unix_time_from_system() * 1000)
## The last success the stage celebrated, so a refresh does not repeat it.
var _cheered := ""


func _ready() -> void:
	App.ready(self)
	controller = App.services.roster_flow
	id = int(App.services.store.get_slice(AppState.ROUTE)["params"].get("id", 0))
	_build()
	App.services.store.changed.connect(_on_changed)
	_refresh()
	if (App.services.store.get_slice(RosterState.ROSTER)["view"] as Dictionary).is_empty():
		await controller.load_roster()
	await controller.load_words()


func _on_changed(slice: StringName) -> void:
	if slice in [RosterState.ROSTER, WorkshopState.WORKSHOP] and is_inside_tree():
		_refresh()


func _build() -> void:
	var column := UI.frame(self)
	StageHeroSkin.night(self)
	# The stage runs to the screen's edges and under the status bar, as the
	# design's does; everything else keeps the safe area's margins.
	var safe := column.get_parent() as MarginContainer
	for side: String in ["margin_left", "margin_right", "margin_top"]:
		safe.add_theme_constant_override(side, 0)
	status_label = UI.status("info", "")
	column.add_child(_padded(StageHeroSkin.plate(status_label)))
	body = UI.scroll(column)
	body.add_theme_constant_override("separation", UI.px(10))
	stage = StageHero.new()
	stage.custom_minimum_size = Vector2(0, UI.px(Tokens.number("size", "safe_top_points") + 290.0))
	stage.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.add_child(stage)
	title_label = UI.title("")
	cards = VBoxContainer.new()
	cards.add_theme_constant_override("separation", UI.px(10))
	body.add_child(_padded(cards))
	forms = HBoxContainer.new()
	forms.add_theme_constant_override("separation", UI.px(6))
	forms.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var bottom := UI.row(-1.0, true)
	bottom.alignment = FlowContainer.ALIGNMENT_CENTER
	var back := UI.button(Strings.t("HOME_ROSTER"), func() -> void: App.services.router.go(&"roster"))
	bottom.add_child(StageHeroMaterial.button(back, "leather"))
	actions = UI.row(-1.0, true)
	actions.alignment = FlowContainer.ALIGNMENT_CENTER
	bottom.add_child(actions)
	column.add_child(_padded(bottom))


## `what` held in from the screen's sides by the safe area's margin.
func _padded(what: Control) -> MarginContainer:
	var m := MarginContainer.new()
	var side := UI.px(Tokens.number("size", "safe_side_points"))
	m.add_theme_constant_override("margin_left", side)
	m.add_theme_constant_override("margin_right", side)
	m.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	m.add_child(what)
	return m


## This character as the server sends it, or {} when it is not in the view.
func _raw(slice: Dictionary, which: int) -> Dictionary:
	for x: Dictionary in (slice.get("view", {}) as Dictionary).get("characters", []):
		if int(x["id"]) == which:
			return x
	return {}


func _refresh() -> void:
	if not is_inside_tree():
		return
	var focused := get_viewport().gui_get_focus_owner()
	var focus_item := str(focused.get_meta("item", "")) if focused != null else ""
	var slice: Dictionary = App.services.store.get_slice(RosterState.ROSTER)
	var words: Dictionary = App.services.store.get_slice(WorkshopState.WORKSHOP)["words"]
	var c := RosterPresenter.character(slice, id, clock.call(), words)
	if c["error"] != "":
		UI.set_status(status_label, "alarm", c["error"])
	elif c["missing"]:
		UI.set_status(status_label, "alarm", Strings.t("CHARACTER_MISSING"))
	elif c["said"] != "":
		UI.set_status(status_label, "success", c["said"])
		# A level bought or a rest ended: the character celebrates, once.
		if c["said"] != _cheered:
			_cheered = c["said"]
			stage.cheer.call_deferred()
	elif c["busy"] != "" or not c["ready"]:
		UI.set_status(status_label, "info", Strings.t("COMMON_LOADING"))
	else:
		UI.set_status(status_label, "info", "")
	status_label.get_parent().get_parent().visible = status_label.text != ""
	for box: Container in [cards, actions]:
		for n in box.get_children():
			box.remove_child(n)
			if n != title_label and n != forms:
				n.queue_free()
	if title_label.get_parent() != null:
		title_label.get_parent().remove_child(title_label)
	if forms.get_parent() != null:
		forms.get_parent().remove_child(forms)
	title_label.text = c.get("title", Strings.t("ROSTER_TITLE"))
	var shown: bool = c["ready"] and not c["missing"]
	stage.visible = shown
	if not shown:
		return
	var me := _raw(slice, id)
	_stand(str(me.get("kind", "")), c, slice, words)
	var kind := RosterPresenter.kind_name(str(me.get("kind", "")))
	cards.add_child(StageHeroKit.name_plate(title_label, str(c["school"]), "%s · %s" % [kind, c["role"]]))
	var numbers := _numbers(str(me.get("role", "")))
	cards.add_child(StageHeroKit.level_row(int(me.get("level", 1)), int(me.get("top", 1)),
		int(numbers.get("health", -1))))
	cards.add_child(StageHeroKit.tabs(TABS.map(func(k: String) -> String: return Strings.t(k)), tab, _pick_tab))
	match tab:
		0:
			_heist_tab(c, me)
		1:
			_stats_tab(me)
		2:
			_compare_tab(slice, words, me)
	_actions(c)
	StageHeroSkin.cap_buttons(cards, get_viewport_rect().size.x - UI.px(48))
	if focus_item != "":
		for b: Button in find_children("*", "Button", true, false):
			if b.get_meta("item", "") == focus_item and b.is_visible_in_tree():
				b.grab_focus.call_deferred()
				break


func _pick_tab(i: int) -> void:
	tab = i
	_refresh()


## §11.1's numbers for `role`, the simulation's own.
static func _numbers(role: String) -> Dictionary:
	return RulebornReplay.role_numbers().get(role, {})


## The ability on its own card, then role, resists, traits and best work two
## to a row, then the forms.
func _heist_tab(c: Dictionary, me: Dictionary) -> void:
	var kind := str(me.get("kind", ""))
	cards.add_child(StageHeroKit.card(Strings.t("CHARACTER_KICK_ABILITY"),
		StageHeroKit.para(Strings.term("ABILITY", kind), 17.0)))
	var role := VBoxContainer.new()
	var role_name := StageHeroKit.para(str(c["role"]), 20.0, Color("#FFF3CC"))
	StageHeroSkin.named(role_name)
	role.add_child(role_name)
	role.add_child(StageHeroKit.para(Strings.term("ROLE_JOB", str(me.get("role", ""))), 14.0, StageHeroSkin.LIGHT_SOFT))
	var traits := VBoxContainer.new()
	traits.add_theme_constant_override("separation", UI.px(5))
	for t: String in me.get("traits", []):
		traits.add_child(StageHeroKit.chip(Strings.term("TRAIT", t), "#5A3FB0"))
		traits.add_child(StageHeroKit.para(Strings.term("TRAIT_EFFECT", t), 14.0, StageHeroSkin.LIGHT_SOFT))
	cards.add_child(StageHeroKit.grid([
		StageHeroKit.card(Strings.t("CHARACTER_KICK_ROLE"), role),
		StageHeroKit.card(Strings.t("CHARACTER_KICK_RESISTS"), StageHeroKit.para(Strings.term("RESISTS", kind), 15.0)),
		StageHeroKit.card(Strings.t("CHARACTER_KICK_TRAITS"), traits),
		StageHeroKit.card(Strings.t("CHARACTER_KICK_BEST"), StageHeroKit.para(Strings.term("BEST_AT", kind), 15.0)),
	], self))
	var strip := VBoxContainer.new()
	strip.add_theme_constant_override("separation", UI.px(4))
	strip.add_child(forms)
	var names := HBoxContainer.new()
	names.add_theme_constant_override("separation", UI.px(6))
	for look: String in LOOKS:
		var n := StageHeroKit.words(Strings.t("ROSTER_STATE_GUARDING") if look == "guard"
			else FormsPresenter.note_name(look), 14.0, StageHeroSkin.LIGHT)
		n.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		n.clip_text = true
		names.add_child(n)
	strip.add_child(names)
	cards.add_child(StageHeroKit.card(Strings.t("CHARACTER_KICK_FORMS"), strip))
	# Where it lives and works, and the one tap that sends it to work.
	var work := VBoxContainer.new()
	work.add_theme_constant_override("separation", UI.px(6))
	work.add_child(StageHeroKit.para(c["lives"], 15.0))
	if c["where"] != "":
		work.add_child(StageHeroKit.para(c["where"], 15.0))
	var send := RosterScreen.offer(c["send"], c["busy"] != "", _send.bind(c))
	_dress(send, "leather")
	work.add_child(send)
	cards.add_child(StageHeroKit.card(Strings.t("ROSTER_STATE_WORKING"), work))


## §11.1's four numbers on bars, each against the largest any role has.
func _stats_tab(me: Dictionary) -> void:
	var role := str(me.get("role", ""))
	var numbers := _numbers(role)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", UI.px(10))
	for s: Array in STATS:
		var value := float(numbers.get(s[0], 0.0))
		v.add_child(StageHeroKit.stat(Strings.t("CHARACTER_STAT_" + str(s[0]).to_upper()), _shown(str(s[0]), value),
			value / _most(str(s[0])), Color(str(s[2])), str(s[1])))
	v.add_child(StageHeroKit.para(Strings.t("CHARACTER_STATS_NOTE", Strings.term("ROLE", role)), 14.0,
		StageHeroSkin.LIGHT_SOFT))
	cards.add_child(StageHeroKit.card("", v))


## A number as the design writes it: speed with one decimal, the rest whole.
static func _shown(stat: String, value: float) -> String:
	return "%.1f" % value if stat == "speed" else "%d" % int(value)


## The largest any role has of `stat`, so every bar shares one scale.
static func _most(stat: String) -> float:
	var most := 0.0
	for n: Dictionary in RulebornReplay.role_numbers().values():
		most = maxf(most, float(n.get(stat, 0.0)))
	return maxf(most, 1.0)


## The roster's others as round portraits to choose from, and the chosen one
## beside this one, stat by stat, on mirrored bars: the larger in green.
func _compare_tab(slice: Dictionary, words: Dictionary, me: Dictionary) -> void:
	var characters: Array = (slice.get("view", {}) as Dictionary).get("characters", [])
	var named := RosterPresenter.names(characters, words)
	var others: Array[Dictionary] = []
	for x: Dictionary in characters:
		if int(x["id"]) != id:
			others.append(x)
	if others.is_empty():
		cards.add_child(StageHeroKit.card("", StageHeroKit.para(Strings.t("CHARACTER_COMPARE_NONE"))))
		return
	if _raw(slice, versus).is_empty() or versus == id:
		versus = int(others[0]["id"])
	var pick := HFlowContainer.new()
	pick.add_theme_constant_override("h_separation", UI.px(6))
	pick.add_theme_constant_override("v_separation", UI.px(6))
	for x: Dictionary in others:
		var which := int(x["id"])
		var b := Button.new()
		b.custom_minimum_size = Vector2.ONE * UI.px(54)
		b.accessibility_name = Strings.t("CHARACTER_COMPARE_WITH", str(named.get(which, "")))
		b.set_meta("item", "versus:%d" % which)
		b.toggle_mode = true
		b.button_pressed = which == versus
		b.pressed.connect(func() -> void:
			versus = which
			_refresh())
		var ring := StyleBoxFlat.new()
		ring.bg_color = Color(0, 0, 0, 0)
		ring.border_color = Color("#F2C45C") if which == versus else Color(0, 0, 0, 0)
		ring.set_border_width_all(UI.px(2.5))
		ring.set_corner_radius_all(UI.px(99))
		for state: String in ["normal", "hover", "pressed", "focus"]:
			b.add_theme_stylebox_override(state, ring)
		var face := StageHeroSkin.portrait_tile(str(x["kind"]), "", 50.0)
		face.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT, Control.PRESET_MODE_MINSIZE, UI.px(3))
		face.mouse_filter = Control.MOUSE_FILTER_IGNORE
		b.add_child(face)
		pick.add_child(b)
	cards.add_child(pick)
	var them := _raw(slice, versus)
	var mine := _numbers(str(me.get("role", "")))
	var theirs := _numbers(str(them.get("role", "")))
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", UI.px(8))
	var heads := HBoxContainer.new()
	for who: String in [str(title_label.text), str(named.get(versus, ""))]:
		var h := StageHeroKit.words(who, 16.0, Color("#FFF3CC"))
		StageHeroSkin.named(h)
		h.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		h.clip_text = true
		heads.add_child(h)
	v.add_child(heads)
	for s: Array in STATS:
		var stat := str(s[0])
		var a := float(mine.get(stat, 0.0))
		var b := float(theirs.get(stat, 0.0))
		var line := HBoxContainer.new()
		line.add_theme_constant_override("separation", UI.px(6))
		var green := Color("#3FBF7F")
		var dim := Color("#6A5A9A")
		line.add_child(StageHeroBar.make(a / _most(stat), green if a >= b else dim, "", 14.0, true))
		var mid := StageHeroKit.words("%s %s · %s" % [s[1], _shown(stat, a), _shown(stat, b)], 15.0,
			StageHeroSkin.LIGHT)
		mid.custom_minimum_size.x = UI.px(96)
		mid.accessibility_name = Strings.t("CHARACTER_STAT_SPOKEN", [Strings.t("CHARACTER_STAT_" + stat.to_upper()),
			"%s · %s" % [_shown(stat, a), _shown(stat, b)]])
		line.add_child(mid)
		line.add_child(StageHeroBar.make(b / _most(stat), green if b >= a else dim, "", 14.0))
		v.add_child(line)
	cards.add_child(StageHeroKit.card("", v))


## The fixed spends, beside the way back to the roster: the next level on
## the green button, and waking.
func _actions(c: Dictionary) -> void:
	var busy: bool = c["busy"] != ""
	if c["raise"] is Dictionary:
		actions.add_child(_spend(c["raise"], busy, "green"))
	else:
		actions.add_child(StageHeroKit.chip(Strings.t("CHARACTER_TOP_LEVEL"), "card", "★"))
	if c["wake"] is Dictionary:
		actions.add_child(_spend(c["wake"], busy, "gold"))


## Every button in `node` on `kind`, squashing when pressed; the words
## beside one (why it waits) in light ink on the night.
func _dress(node: Control, kind: String) -> void:
	for b: Button in node.find_children("*", "Button", true, false):
		StageHeroMaterial.button(b, kind)
	for l: Label in node.find_children("*", "Label", true, false):
		l.add_theme_color_override("font_color", StageHeroSkin.LIGHT)


## The character on its stage with its place in the roster, its state and
## the arrows over it.
func _stand(kind: String, c: Dictionary, slice: Dictionary, words: Dictionary) -> void:
	if kind != "" and str(stage.get_meta("showing", "")) != kind:
		stage.set_meta("showing", kind)
		stage.show_kinds([kind])
		for n in forms.get_children():
			n.queue_free()
		for look: String in LOOKS:
			var tile := StageHeroSkin.portrait_tile(kind, look, 84.0)
			tile.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			forms.add_child(tile)
	if level_badge != null:
		level_badge.queue_free()
	level_badge = Control.new()
	level_badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	level_badge.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	stage.add_child(level_badge)
	var top := MarginContainer.new()
	top.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	top.mouse_filter = Control.MOUSE_FILTER_IGNORE
	top.add_theme_constant_override("margin_top", UI.px(Tokens.number("size", "safe_top_points")))
	top.add_theme_constant_override("margin_left", UI.px(8))
	top.add_theme_constant_override("margin_right", UI.px(8))
	level_badge.add_child(top)
	var ids: Array = RosterScreen.kinds_of(slice).keys()
	var at := ids.find(id)
	var state := StageHeroKit.chip(str(c["line"]), "glass")
	StageHeroSkin.on_stage(top, state, Control.PRESET_TOP_RIGHT)
	if at >= 0:
		StageHeroSkin.on_stage(top, StageHeroKit.chip(Strings.t("CHARACTER_COUNT", [at + 1, ids.size()]), "glass"),
			Control.PRESET_TOP_LEFT)
	# The design's arrows through the roster, in its order, round at the ends.
	if ids.size() > 1 and at >= 0:
		var named := RosterPresenter.names((slice.get("view", {}) as Dictionary).get("characters", []), words)
		for step: int in [-1, 1]:
			var to: int = ids[posmod(at + step, ids.size())]
			var b := StageHeroKit.arrow(step < 0, Strings.t("CHARACTER_PREVIOUS" if step < 0 else "CHARACTER_NEXT",
				str(named.get(to, ""))), func() -> void: App.services.router.go(&"character", {"id": to}))
			b.set_meta("item", "step:%d" % step)
			StageHeroSkin.on_stage(top, b, Control.PRESET_CENTER_LEFT if step < 0 else Control.PRESET_CENTER_RIGHT)


## A spend's button on `kind`: the first tap shows the price to confirm; the
## second spends.
func _spend(o: Dictionary, busy: bool, kind: String) -> Control:
	var confirming: bool = confirm == o["key"]
	var shown := o.duplicate()
	if confirming:
		shown["action"] = Strings.t("CHARACTER_CONFIRM", o["cost"])
		shown["spoken"] = Strings.t("CHARACTER_CONFIRM_SPOKEN", [o["spoken"], o["cost"]])
	var r := RosterScreen.offer(shown, busy, _tap.bind(o))
	_dress(r, kind)
	return r


func _tap(o: Dictionary) -> void:
	if confirm != o["key"]:
		confirm = o["key"]
		_refresh()
		return
	confirm = ""
	var a: Dictionary = o["args"]
	if a.has("to"):
		await controller.level(int(a["id"]), int(a["to"]))
	else:
		await controller.wake(int(a["id"]))


func _send(c: Dictionary) -> void:
	var a: Dictionary = c["send"]["args"]
	if a.is_empty():
		return
	await controller.work(int(a["id"]), str(a["realm"]), str(a["kind"]), int(a["n"]), str(c["title"]))
