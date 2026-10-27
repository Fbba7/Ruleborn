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
## The tabs, by their words' keys, and the design's icon for each.
const TABS := ["CHARACTER_TAB_HEIST", "CHARACTER_TAB_STATS", "CHARACTER_TAB_COMPARE"]
const TAB_ICONS := ["screens/heist", "realmactions/upgrade", "screens/roster"]

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
## Above them: waking from a rest, and why a level waits, on a row of
## their own so a long language's words wrap rather than widen the phone.
var notes: VBoxContainer
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
	stage.custom_minimum_size = Vector2(0, UI.px(Tokens.number("size", "safe_top_points") + 245.0))
	stage.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.add_child(stage)
	# The name on a gold-rimmed plate at the stage's foot, as the design's.
	title_label = UI.title("")
	StageHeroSkin.named(title_label)
	title_label.add_theme_font_size_override("font_size", UI.text_px(24))
	title_label.set_meta("points", 24.0)
	title_label.add_theme_color_override("font_color", Color("#FFF3CC"))
	title_label.set_meta("own_ink", true)
	title_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	cards = VBoxContainer.new()
	cards.add_theme_constant_override("separation", UI.px(10))
	body.add_child(_padded(cards))
	forms = HBoxContainer.new()
	forms.add_theme_constant_override("separation", UI.px(6))
	forms.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var bottom := HBoxContainer.new()
	bottom.add_theme_constant_override("separation", UI.px(8))
	# Back to the roster: the kit's round back button, named for a screen
	# reader, in the lowest row as §21.1 keeps it.
	bottom.add_child(KitControls.icon_button("generalui/back", Strings.t("HOME_ROSTER"),
		func() -> void: App.services.router.go(&"roster"), "leather", 56.0))
	actions = UI.row(-1.0, true)
	actions.alignment = FlowContainer.ALIGNMENT_CENTER
	actions.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bottom.add_child(actions)
	notes = VBoxContainer.new()
	notes.add_theme_constant_override("separation", UI.px(6))
	column.add_child(_padded(notes))
	# The lowest row stands above the corners' band (§21.1: 8% of the
	# frame's height, of which the safe area is 44 points), so it may run the
	# column's width as the design's does.
	var lift := MarginContainer.new()
	lift.add_theme_constant_override("margin_bottom", UI.px(20))
	lift.add_child(bottom)
	column.add_child(_padded(lift))


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
	for box: Container in [cards, actions, notes]:
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
	cards.add_child(_sub_line(c, me))
	var numbers := _numbers(str(me.get("role", "")))
	cards.add_child(StageHeroKit.level_row(int(me.get("level", 1)), int(me.get("top", 1)),
		int(numbers.get("health", -1))))
	cards.add_child(StageHeroKit.tabs(TABS.map(func(k: String) -> String: return Strings.t(k)), tab, _pick_tab,
		TAB_ICONS))
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


## Under the stage, centred: its school on a chip in the school's colour
## with its mark (§21.2), and its kind and role.
func _sub_line(c: Dictionary, me: Dictionary) -> Control:
	var line := HFlowContainer.new()
	line.alignment = FlowContainer.ALIGNMENT_CENTER
	line.add_theme_constant_override("h_separation", UI.px(8))
	var school := str(c["school"])
	var colour: Color = Palette.SCHOOL.get(school, Palette.MOTION)
	line.add_child(StageHeroKit.chip(Strings.t("SCHOOL_" + school.to_upper()).to_upper(),
		"#" + colour.darkened(0.55).to_html(false), "schools/" + school))
	var sub := StageHeroKit.words("%s · %s" % [RosterPresenter.kind_name(str(me.get("kind", ""))), c["role"]], 16.0,
		StageHeroSkin.LIGHT_SOFT)
	StageHeroKit.wrapped(sub, 300.0)
	sub.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	line.add_child(sub)
	return line


## As the design's Heist tab: on one parchment frame, the ability on a dark
## card beside its icon, with its uses as a tag; then role, resists, traits
## and best work two to a row, each on a light card beside its icon; then
## the forms, and where it lives and works.
func _heist_tab(c: Dictionary, me: Dictionary) -> void:
	var kind := str(me.get("kind", ""))
	var frame := VBoxContainer.new()
	frame.add_theme_constant_override("separation", UI.px(8))
	var ability := HBoxContainer.new()
	ability.add_theme_constant_override("separation", UI.px(10))
	var tile := StageHeroMaterial.panel("gold", Icons.view("heistcontrols/ability", 34.0), 14.0, 6.0)
	tile.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	ability.add_child(tile)
	var said := VBoxContainer.new()
	said.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var head := HFlowContainer.new()
	head.add_theme_constant_override("h_separation", UI.px(6))
	var kick := StageHeroKit.kicker(Strings.t("CHARACTER_KICK_ABILITY"))
	kick.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	head.add_child(kick)
	head.add_child(StageHeroKit.chip(Strings.term("ABILITY_USES", kind).to_upper(), "#5A3448"))
	said.add_child(head)
	said.add_child(StageHeroKit.para(Strings.term("ABILITY_DOES", kind), 16.0))
	ability.add_child(said)
	frame.add_child(StageHeroMaterial.panel("card", ability, 14.0, 10.0))
	var role := str(me.get("role", ""))
	var traits: Array = (me.get("traits", []) as Array).map(func(t: String) -> String: return Strings.term("TRAIT", t))
	var first_trait := str((me.get("traits", []) as Array).front()) if not (me.get("traits", []) as Array).is_empty() \
		else ""
	frame.add_child(StageHeroKit.grid([
		_info("crewroles/" + role.to_lower(), str(c["role"]), "#7A4A10", Strings.term("ROLE_JOB", role)),
		_info("hud/shield", Strings.t("CHARACTER_KICK_RESISTS"), "#1F6A35", Strings.term("RESISTS", kind)),
		_info("traits/" + first_trait.replace("_", ""), Strings.t("CHARACTER_KICK_TRAITS"), "#5A3AB0",
			" · ".join(traits)),
		_info("realmactions/assignworker", Strings.t("CHARACTER_KICK_BEST"), "#145560",
			Strings.term("BEST_AT", kind)),
	], self))
	# What each trait does, under the cards, as the traits card names them.
	for t: String in me.get("traits", []):
		var line := HBoxContainer.new()
		line.add_theme_constant_override("separation", UI.px(6))
		var icon := "traits/" + t.replace("_", "")
		if Icons.has(icon):
			line.add_child(Icons.view(icon, 22.0))
		var effect := StageHeroKit.para("%s: %s" % [Strings.term("TRAIT", t), Strings.term("TRAIT_EFFECT", t)], 14.0,
			Color("#2A1A10"))
		effect.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		line.add_child(effect)
		frame.add_child(line)
	cards.add_child(StageHeroMaterial.panel("parchment", frame, 18.0, 6.0))
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


## A light card on the Heist frame: the design's icon on a disc, a kicker in
## `tone` and the value in dark ink.
static func _info(icon: String, heading: String, tone: String, value: String) -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", UI.px(6))
	if Icons.has(icon):
		var disc := StageHeroMaterial.panel("#F1E3C4", Icons.view(icon, 24.0), 99.0, 2.0)
		disc.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		row.add_child(disc)
	var v := VBoxContainer.new()
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	v.add_theme_constant_override("separation", UI.px(1))
	v.add_child(StageHeroKit.kicker(heading, Color(tone)))
	var said := StageHeroKit.para(value, 14.0, Color("#2A1A10"))
	said.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	said.autowrap_mode = TextServer.AUTOWRAP_WORD
	said.add_theme_font_override("font", UI.bold_font())
	said.set_meta("bold", true)
	v.add_child(said)
	row.add_child(v)
	return StageHeroMaterial.panel("#FBF3E2", row, 14.0, 6.0)


## §11.1's four numbers on bars, each against the largest any role has.
func _stats_tab(me: Dictionary) -> void:
	var role := str(me.get("role", ""))
	var numbers := _numbers(role)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", UI.px(8))
	var tiles: Array = []
	for s: Array in STATS:
		var value := float(numbers.get(s[0], 0.0))
		tiles.append(_stat_tile(Strings.t("CHARACTER_STAT_" + str(s[0]).to_upper()), _shown(str(s[0]), value),
			value / _most(str(s[0])), Color(str(s[2])), str(s[1])))
	v.add_child(StageHeroKit.grid(tiles, self))
	v.add_child(StageHeroKit.para(Strings.t("CHARACTER_STATS_NOTE", Strings.term("ROLE", role)), 14.0,
		StageHeroSkin.BROWN))
	cards.add_child(StageHeroMaterial.panel("parchment", v, 16.0, 10.0))


## A stat as the design's tile: its glyph and name small and tracked, its
## number large in Lilita One, and a track of ten pips filled to its share
## of the largest any role has; read aloud as name and number.
static func _stat_tile(name: String, number: String, fraction: float, colour: Color, glyph: String) -> Control:
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", UI.px(2))
	var top := HBoxContainer.new()
	top.add_theme_constant_override("separation", UI.px(4))
	top.add_child(StageHeroKit.words(glyph, 15.0, colour.darkened(0.45)))
	var n := StageHeroKit.kicker(name, Color("#6A4A2A"))
	n.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	top.add_child(n)
	v.add_child(top)
	var value := StageHeroKit.words(number, 26.0, Color("#2A1A10"))
	value.add_theme_font_override("font", StageHeroSkin.numbers_font())
	value.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	v.add_child(value)
	var pips := HBoxContainer.new()
	pips.add_theme_constant_override("separation", UI.px(2))
	var lit := roundi(clampf(fraction, 0.0, 1.0) * 10.0)
	for i: int in 10:
		var pip := Panel.new()
		var dot := StyleBoxFlat.new()
		dot.bg_color = colour.darkened(0.15) if i < lit else Color("#D8C8A4")
		dot.set_corner_radius_all(UI.px(3))
		pip.add_theme_stylebox_override("panel", dot)
		pip.custom_minimum_size = Vector2(UI.px(8), UI.px(7))
		pip.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		pip.mouse_filter = Control.MOUSE_FILTER_IGNORE
		pips.add_child(pip)
	v.add_child(pips)
	v.accessibility_name = Strings.t("CHARACTER_STAT_SPOKEN", [name, number])
	for l: Label in v.find_children("*", "Label", true, false):
		l.set_meta("own_ink", true)
	var tile := StageHeroMaterial.panel("parchment", v, 12.0, 8.0)
	tile.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return tile


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
	# The others to choose from, under the comparison they change.
	cards.add_child(pick)


## The fixed spends, beside the way back to the roster: the next level on
## the design's big green button, and waking.
func _actions(c: Dictionary) -> void:
	var busy: bool = c["busy"] != ""
	if c["raise"] is Dictionary:
		actions.add_child(_upgrade(c["raise"], busy))
	else:
		actions.add_child(StageHeroKit.chip(Strings.t("CHARACTER_TOP_LEVEL"), "card", "hud/star"))
	# Why a level waits, in light words on the card's violet (§21.8).
	if c["raise"] is Dictionary and str(c["raise"]["why"]) != "":
		notes.add_child(StageHeroKit.chip(str(c["raise"]["why"]), "card", "generalui/lock", true))
	if c["wake"] is Dictionary:
		notes.add_child(_spend(c["wake"], busy, "gold"))
	notes.get_parent().visible = notes.get_child_count() > 0


## The design's UPGRADE: "Level up" in Lilita One over the levels it moves
## between (or why it waits, or, asked once, the price to confirm), and the
## price beside Essence's icon. Spent on a second tap.
func _upgrade(o: Dictionary, busy: bool) -> Button:
	var confirming: bool = confirm == o["key"]
	var b := UI.action("", _tap.bind(o), "green", Strings.t("CHARACTER_CONFIRM_SPOKEN", [o["spoken"], o["cost"]])
		if confirming else str(o["spoken"]))
	b.disabled = busy or not o["can"]
	b.set_meta("key", o["key"])
	b.set_meta("item", o["item"])
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b.custom_minimum_size.x = UI.px(180)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", UI.px(8))
	row.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT, Control.PRESET_MODE_MINSIZE, UI.px(10))
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var words := VBoxContainer.new()
	words.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	words.alignment = BoxContainer.ALIGNMENT_CENTER
	words.add_theme_constant_override("separation", 0)
	var big := StageHeroKit.words(Strings.t("CHARACTER_UPGRADE").to_upper(), 22.0, Color("#FFFDF0"), true)
	big.add_theme_font_override("font", StageHeroSkin.numbers_font())
	big.add_theme_constant_override("outline_size", UI.px(3))
	big.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	words.add_child(big)
	var to := int(o["args"]["to"])
	var line := Strings.t("CHARACTER_CONFIRM", o["cost"]) if confirming \
		else Strings.t("CHARACTER_UPGRADE_LINE", [to - 1, to])
	var sub := StageHeroKit.words(line, 14.0, Color("#FFFDF0"), true)
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	sub.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	sub.custom_minimum_size.x = UI.px(90)
	words.add_child(sub)
	row.add_child(words)
	# The price at the bar's end on a dark chip, beside Essence's icon, as
	# the design's UPGRADE.
	var price := HBoxContainer.new()
	price.add_theme_constant_override("separation", UI.px(4))
	price.add_child(Icons.view("resources/essence", 20.0))
	var cost := StageHeroKit.words(str(o["cost"]), 18.0, Color("#FFFDF0"), true)
	cost.add_theme_font_override("font", StageHeroSkin.numbers_font())
	price.add_child(cost)
	var chip := PanelContainer.new()
	var dark := StyleBoxFlat.new()
	dark.bg_color = Color("#1E1440")
	dark.set_corner_radius_all(UI.px(12))
	dark.content_margin_left = UI.px(10)
	dark.content_margin_right = UI.px(10)
	dark.content_margin_top = UI.px(4)
	dark.content_margin_bottom = UI.px(4)
	chip.add_theme_stylebox_override("panel", dark)
	chip.set_meta("behind", [dark.bg_color] as Array[Color])
	chip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	chip.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	chip.add_child(price)
	row.add_child(chip)
	b.add_child(row)
	b.custom_minimum_size.y = maxf(b.custom_minimum_size.y, row.get_combined_minimum_size().y + UI.px(20))
	row.minimum_size_changed.connect(func() -> void:
		b.custom_minimum_size.y = maxf(UI.px(64), row.get_combined_minimum_size().y + UI.px(20)))
	return b


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
		# The design's violet disc, its lip lit lavender.
		stage.plinth_edge = Color("#6E60C8")
		stage.show_kinds([kind], [], "plinth")
		stage.backdrop.set_glow(Color("#8A78E8"))
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
	var plate := StageHeroMaterial.panel("rim", title_label, 12.0, 8.0)
	var foot := MarginContainer.new()
	foot.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	foot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	level_badge.add_child(foot)
	StageHeroSkin.on_stage(foot, plate, Control.PRESET_CENTER_BOTTOM)
	var state := StageHeroKit.chip(str(c["line"]), "glass", "characterstates/" + str(c["state"]))
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
