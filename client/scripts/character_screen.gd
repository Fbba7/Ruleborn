class_name CharacterScreen
extends Control
## One ruleborn in detail (§23.2: "School, role, ability, traits, level,
## best work"), laid out as the design's Character screen: the character
## idling full-bleed on its hero stage, with the roster's arrows, its place
## in the roster and its state on the stage; its name plate with its school
## and kind; its level on a gold hexagon beside a bar of the levels its home
## allows, and its health; then three tabs. Heist: its ability (§11.11), its
## role and what the role does (§11.1), what it resists, its traits on tiles
## with what each does (§11.3), what it is best at, and its forms (§21.6).
## Stats: §11.1's four numbers for its role, as the simulation plays them,
## each on a bar against the largest any role has. Compare: another of the
## roster's, chosen by its portrait, the two side by side on the kit's bars.
## Beneath, fixed: what Essence can do for it now — the next level, or
## waking from a rest (§11.6) — each asked for twice, a first tap showing the
## price, because Essence spent is not given back; and sending it to work.

## The forms the strip shows, in §21.6's order, then the guard form.
const LOOKS := ["hush", "spark", "echo", "guard"]
## §11.1's four numbers, in the order the design's Stats tab shows them,
## each with the designs' icon for it.
const STATS := [["health", "hud/shield"], ["speed", "realmactions/speed"], ["power", "heistcontrols/ability"],
	["carry", "resources/essence"]]
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
var forms: GridContainer
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
	# The stage runs to the screen's edges and under the status bar, as the
	# design's does; everything else keeps the safe area's margins.
	var safe := column.get_parent() as MarginContainer
	for side: String in ["margin_left", "margin_right", "margin_top"]:
		safe.add_theme_constant_override(side, 0)
	status_label = UI.status("info", "")
	column.add_child(_padded(UI.plate(status_label, "glass")))
	body = UI.scroll(column)
	body.add_theme_constant_override("separation", UI.px(10))
	stage = StageHero.new()
	stage.custom_minimum_size = Vector2(0, UI.px(Tokens.number("size", "safe_top_points") + 215.0))
	stage.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	# Clear of the place and state pills over the stage's top.
	stage.headroom = 0.08
	body.add_child(stage)
	# The name in the display face on the kit's dark plate at the stage's
	# foot, as the design's; the plate's material sets its ink.
	title_label = UI.label("", 24)
	title_label.theme_type_variation = "DisplayS"
	title_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	cards = VBoxContainer.new()
	cards.add_theme_constant_override("separation", UI.px(10))
	body.add_child(_padded(cards))
	forms = KitLayout.grid(LOOKS.size(), 6.0)
	forms.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var bottom := HBoxContainer.new()
	bottom.add_theme_constant_override("separation", UI.px(8))
	# Back to the roster: the kit's round back button, named for a screen
	# reader, in the lowest row as §21.1 keeps it.
	bottom.add_child(KitControls.icon_button("generalui/back", Strings.t("HOME_ROSTER"),
		func() -> void: App.services.router.go(&"roster"), "parchment", 56.0))
	actions = UI.row(-1.0, true)
	actions.alignment = FlowContainer.ALIGNMENT_CENTER
	actions.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bottom.add_child(actions)
	notes = VBoxContainer.new()
	notes.add_theme_constant_override("separation", UI.px(6))
	column.add_child(_padded(notes))
	# The lowest row on the kit's dark plate, standing above the corners'
	# band (§21.1: 8% of the frame's height, of which the safe area is 44
	# points), so it may run the column's width as the design's does.
	var tray := UI.panel("plate_dark")
	tray.add_child(bottom)
	var lift := MarginContainer.new()
	lift.add_theme_constant_override("margin_bottom", UI.px(20))
	lift.add_child(tray)
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
	cards.add_child(_level_row(int(me.get("level", 1)), int(me.get("top", 1)), int(numbers.get("health", -1))))
	var options: Array = []
	for i: int in TABS.size():
		options.append([Strings.t(TABS[i]), TAB_ICONS[i]])
	cards.add_child(KitNav.segmented(options, tab, _pick_tab, true))
	match tab:
		0:
			_heist_tab(c, me)
		1:
			_stats_tab(me)
		2:
			_compare_tab(slice, words, me)
	_actions(c)
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


## Under the stage, centred: its school on the kit's chip in the school's
## colours with its mark (§21.2), and its kind and role.
func _sub_line(c: Dictionary, me: Dictionary) -> Control:
	var line := KitLayout.flow(8)
	line.alignment = FlowContainer.ALIGNMENT_CENTER
	var chip := KitCards.school_chip(str(c["school"]))
	chip.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	line.add_child(chip)
	# One line; the flow puts it under the chip when the two do not fit.
	var sub := UI.label("%s · %s" % [RosterPresenter.kind_name(str(me.get("kind", ""))), c["role"]], 16)
	sub.theme_type_variation = "Secondary"
	sub.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	line.add_child(sub)
	_wrap_in(sub, line, 0.0)
	return line


## `l` on one line while it fits in `room`'s width, less `inset` points,
## and broken between words when it does not, so large text and longer
## words never push the column past the screen.
static func _wrap_in(l: Label, room: Control, inset: float) -> void:
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var wide := func() -> float:
		var font := l.get_theme_font("font")
		var words := l.text.to_upper() if l.uppercase else l.text
		return font.get_string_size(words, HORIZONTAL_ALIGNMENT_LEFT, -1, l.get_theme_font_size("font_size")).x \
			+ 2.0
	room.resized.connect(func() -> void:
		var want := minf(wide.call(), room.size.x - UI.px(inset))
		if absf(l.custom_minimum_size.x - want) > 0.5:
			l.custom_minimum_size.x = want)


## Its level on the kit's gold hexagon beside the bar of the levels its home
## allows, one segment a level, with the level in words beneath; and its
## health on a dark pill, when its role has one.
func _level_row(level: int, top: int, health: int) -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", UI.px(10))
	var hex := KitHex.make(Strings.t("CHARACTER_LEVEL_SHORT"), str(level))
	hex.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(hex)
	var v := VBoxContainer.new()
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	v.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	v.add_theme_constant_override("separation", UI.px(4))
	v.add_child(KitStatus.xp(level, maxi(top, 1), "", clampi(top, 1, 20)))
	var of := UI.label(Strings.t("CHARACTER_LEVEL_OF", [level, top]), 14, true)
	of.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	v.add_child(of)
	row.add_child(v)
	if health >= 0:
		var pill := KitStatus.pill("%s %d" % [Strings.t("CHARACTER_KICK_HEALTH"), health], "", "plate_dark", 160.0)
		pill.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		row.add_child(pill)
	return row


## As the design's Heist tab, on parchment: its ability on the kit's plum
## card in its school's window (§11.11), then four facts two by two: its
## role and what the role does (§11.1), what it resists, its traits (§11.3)
## and what it is best at; under them what each trait does. Then its forms
## (§21.6) and where it lives and works.
func _heist_tab(c: Dictionary, me: Dictionary) -> void:
	var kind := str(me.get("kind", ""))
	var frame := VBoxContainer.new()
	frame.add_theme_constant_override("separation", UI.px(8))
	var ability := KitCards.ability("heistcontrols/ability", str(c["school"]), Strings.t("CHARACTER_KICK_ABILITY"),
		Strings.term("ABILITY_USES", kind), Strings.term("ABILITY_DOES", kind), "")
	for l: Label in ability.find_children("*", "Label", true, false):
		if l.text == "":
			l.visible = false
		elif l.get_parent().name == "Tag":
			# Its kind of use, broken when larger words do not fit beside it.
			_wrap_in(l, l.get_parent().get_parent(), 16.0)
	frame.add_child(ability)
	var role := str(me.get("role", ""))
	var keys: Array = me.get("traits", [])
	var traits: Array = keys.map(func(t: String) -> String: return Strings.term("TRAIT", t))
	var first_trait := str(keys.front()).replace("_", "") if not keys.is_empty() else ""
	var grid := KitLayout.grid(2)
	for f: Array in [
		[_icon("crewroles/" + role.to_lower(), "heistcontrols/ability"), str(c["role"]), Strings.term("ROLE_JOB", role)],
		[_icon("hud/shield", "hud/star"), Strings.t("CHARACTER_KICK_RESISTS"), Strings.term("RESISTS", kind)],
		[_icon("traits/" + first_trait, "hud/star"), Strings.t("CHARACTER_KICK_TRAITS"), " · ".join(traits)],
		[_icon("realmactions/assignworker", "hud/star"), Strings.t("CHARACTER_KICK_BEST"),
			Strings.term("BEST_AT", kind)],
	]:
		var tile := KitCards.fact(f[0], f[1], f[2])
		for l: Label in tile.find_children("*", "Label", true, false):
			l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			l.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		grid.add_child(tile)
	frame.add_child(grid)
	# What each trait does, under the facts, as the traits fact names them.
	for t: String in keys:
		var line := HBoxContainer.new()
		line.add_theme_constant_override("separation", UI.px(6))
		var icon := "traits/" + t.replace("_", "")
		if Icons.has(icon):
			var mark := Icons.view(icon, 22.0)
			mark.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
			line.add_child(mark)
		var effect := UI.label("%s: %s" % [Strings.term("TRAIT", t), Strings.term("TRAIT_EFFECT", t)], 14, true)
		effect.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		effect.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		line.add_child(effect)
		frame.add_child(line)
	var paper := UI.panel("parchment")
	paper.add_child(frame)
	cards.add_child(paper)
	forms.columns = KitLayout.grid_columns(LOOKS.size())
	cards.add_child(_card(Strings.t("CHARACTER_KICK_FORMS"), forms))
	# Where it lives and works, and the one tap that sends it to work.
	var work := VBoxContainer.new()
	work.add_theme_constant_override("separation", UI.px(6))
	for said: String in [str(c["lives"]), str(c["where"])]:
		if said != "":
			var l := UI.label(said, 15, true)
			l.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
			work.add_child(l)
	var send := RosterScreen.offer(c["send"], c["busy"] != "", _send.bind(c))
	_dress(send, "leather")
	work.add_child(send)
	cards.add_child(_card(Strings.t("ROSTER_STATE_WORKING"), work))


## `icon` when the designs have it, else `instead`.
static func _icon(icon: String, instead: String) -> String:
	return icon if Icons.has(icon) else instead


## The kit's violet card with a kicker over `what`.
static func _card(heading: String, what: Control) -> PanelContainer:
	var p := UI.panel("card")
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", UI.px(6))
	if heading != "":
		var k := UI.label(heading, 13)
		k.theme_type_variation = "Kicker"
		k.uppercase = true
		k.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		k.set_meta("bold", true)
		v.add_child(k)
	v.add_child(what)
	p.add_child(v)
	return p


## §11.1's four numbers on the kit's stat tiles, two by two on parchment,
## each with ten pips filled to its share of the largest any role has; read
## aloud as name and number.
func _stats_tab(me: Dictionary) -> void:
	var role := str(me.get("role", ""))
	var numbers := _numbers(role)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", UI.px(8))
	var grid := KitLayout.grid(2)
	for s: Array in STATS:
		var stat := str(s[0])
		var value := float(numbers.get(stat, 0.0))
		var name := Strings.t("CHARACTER_STAT_" + stat.to_upper())
		var tile := KitCards.stat(str(s[1]), name, _shown(stat, value), "",
			roundi(clampf(value / _most(stat), 0.0, 1.0) * 10.0), 10)
		tile.accessibility_name = Strings.t("CHARACTER_STAT_SPOKEN", [name, _shown(stat, value)])
		grid.add_child(tile)
	v.add_child(grid)
	var note := UI.label(Strings.t("CHARACTER_STATS_NOTE", Strings.term("ROLE", role)), 14, true)
	note.theme_type_variation = "Secondary"
	v.add_child(note)
	var paper := UI.panel("parchment")
	paper.add_child(v)
	cards.add_child(paper)


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
## beside this one, stat by stat, on the kit's bars: the larger in green.
func _compare_tab(slice: Dictionary, words: Dictionary, me: Dictionary) -> void:
	var characters: Array = (slice.get("view", {}) as Dictionary).get("characters", [])
	var named := RosterPresenter.names(characters, words)
	var others: Array[Dictionary] = []
	for x: Dictionary in characters:
		if int(x["id"]) != id:
			others.append(x)
	if others.is_empty():
		cards.add_child(_card("", UI.label(Strings.t("CHARACTER_COMPARE_NONE"), 15, true)))
		return
	if _raw(slice, versus).is_empty() or versus == id:
		versus = int(others[0]["id"])
	var pick := KitLayout.flow(6)
	for x: Dictionary in others:
		var which := int(x["id"])
		var b := UI.action("", func() -> void:
			versus = which
			_refresh(), "leather", Strings.t("CHARACTER_COMPARE_WITH", str(named.get(which, ""))))
		b.custom_minimum_size = Vector2.ONE * UI.px(54)
		b.set_meta("item", "versus:%d" % which)
		KitControls.small_disc(b, 54.0)
		RbBox.of(b).set_chosen(which == versus)
		var face := StageHeroSkin.portrait_tile(str(x["kind"]), "", 46.0)
		face.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT, Control.PRESET_MODE_MINSIZE, UI.px(4))
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
		var h := UI.label(who, 16)
		h.theme_type_variation = "Heading"
		h.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		# Two halves; a long name wraps in its half rather than trimming.
		h.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		heads.add_child(h)
	v.add_child(heads)
	for s: Array in STATS:
		var stat := str(s[0])
		var a := float(mine.get(stat, 0.0))
		var b := float(theirs.get(stat, 0.0))
		var name := Strings.t("CHARACTER_STAT_" + stat.to_upper())
		var said := UI.label("%s  %s · %s" % [name, _shown(stat, a), _shown(stat, b)], 14, true)
		said.theme_type_variation = "Secondary"
		said.accessibility_name = Strings.t("CHARACTER_STAT_SPOKEN", [name, "%s · %s" % [_shown(stat, a),
			_shown(stat, b)]])
		v.add_child(said)
		var line := HBoxContainer.new()
		line.add_theme_constant_override("separation", UI.px(8))
		var green := Tokens.color("success")
		line.add_child(KitBar.make(a / _most(stat), green if a >= b else Color(), 12.0))
		line.add_child(KitBar.make(b / _most(stat), green if b >= a else Color(), 12.0))
		v.add_child(line)
	cards.add_child(_card("", v))
	# The others to choose from, under the comparison they change.
	cards.add_child(pick)


## The fixed spends, beside the way back to the roster: the next level on
## the kit's gold upgrade, and waking; at the top level a dark pill says so.
func _actions(c: Dictionary) -> void:
	var busy: bool = c["busy"] != ""
	if c["raise"] is Dictionary:
		actions.add_child(_upgrade(c["raise"], busy))
	else:
		actions.add_child(KitStatus.pill(Strings.t("CHARACTER_TOP_LEVEL"), "hud/star", "plate_dark"))
	# Why a level waits, on the kit's hint.
	if c["raise"] is Dictionary and str(c["raise"]["why"]) != "":
		notes.add_child(KitStatus.hint(str(c["raise"]["why"])))
	if c["wake"] is Dictionary:
		notes.add_child(_spend(c["wake"], busy, "gold"))
	notes.get_parent().visible = notes.get_child_count() > 0


## The design's UPGRADE on the kit: "Level up" in display capitals over the
## levels it moves between (or, asked once, the price to confirm), and the
## price on its chip beside Essence's icon. Spent on a second tap.
func _upgrade(o: Dictionary, busy: bool) -> Button:
	var confirming: bool = confirm == o["key"]
	var to := int(o["args"]["to"])
	var line := Strings.t("CHARACTER_CONFIRM", o["cost"]) if confirming \
		else Strings.t("CHARACTER_UPGRADE_LINE", [to - 1, to])
	var b := KitControls.upgrade(Strings.t("CHARACTER_UPGRADE"), line, "resources/essence", str(o["cost"]),
		_tap.bind(o), "gold")
	b.accessibility_name = Strings.t("CHARACTER_CONFIRM_SPOKEN", [o["spoken"], o["cost"]]) if confirming \
		else str(o["spoken"])
	b.disabled = busy or not o["can"]
	b.set_meta("key", o["key"])
	b.set_meta("item", o["item"])
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b.custom_minimum_size.x = UI.px(180)
	_fit_upgrade(b)
	return b


## The kit's upgrade stands 64 points tall with its words in the room left
## of a 96-point price; at large text the words and the chip outgrow both.
## Here the words keep clear of the chip as it is, the title wraps, and the
## button grows to hold them (requested of the kit as K1-R, see S3.md).
static func _fit_upgrade(b: Button) -> void:
	var v := b.get_child(0) as Control
	var cost: Control = null
	for n in b.get_children():
		if n is PanelContainer:
			cost = n
	if cost == null:
		return
	var title := v.get_child(0) as Label
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.offset_left = maxf(v.offset_left, UI.px(10))
	var fit := func() -> void:
		var right := -(cost.size.x + UI.px(20))
		if absf(v.offset_right - right) > 0.5:
			v.offset_right = right
		# Measured from the font at the room the title has, not from the
		# label, whose lines lag its width by a frame.
		var room := maxf(UI.px(40), b.size.x + right - v.offset_left)
		var font := title.get_theme_font("font")
		var size := title.get_theme_font_size("font_size")
		var words := font.get_multiline_string_size(title.text.to_upper(), HORIZONTAL_ALIGNMENT_CENTER,
			room, size, -1, TextServer.BREAK_MANDATORY | TextServer.BREAK_WORD_BOUND).y
		if v.get_child_count() > 1:
			words += (v.get_child(1) as Label).get_line_height()
		var tall := maxf(UI.px(64), words + UI.px(14))
		if absf(b.custom_minimum_size.y - tall) > 0.5:
			b.custom_minimum_size.y = tall
	b.resized.connect(fit)
	cost.resized.connect(fit)


## Every button in `node` on the kit's `kind`; the words beside one in the
## night's ink.
func _dress(node: Control, kind: String) -> void:
	for b: Button in node.find_children("*", "Button", true, false):
		UI.set_look(b, kind)
	for l: Label in node.find_children("*", "Label", true, false):
		l.add_theme_color_override("font_color", Tokens.color("text_on_night"))


## The character on its stage with, over it, its place in the roster and
## its state on dark pills, the kit's round gold arrows, and its name on a
## dark plate at the stage's foot.
func _stand(kind: String, c: Dictionary, slice: Dictionary, words: Dictionary) -> void:
	if kind != "" and str(stage.get_meta("showing", "")) != kind:
		stage.set_meta("showing", kind)
		# The design's violet disc, its lip lit lavender.
		stage.plinth_edge = Color("#6E60C8")
		stage.show_kinds([kind], [], "plinth")
		stage.backdrop.set_glow(Color("#8A78E8"))
		for n in forms.get_children():
			n.queue_free()
		# Each form's portrait over its name, on the kit's grid: fewer
		# columns at large text, so the names keep their room.
		for look: String in LOOKS:
			var cell := VBoxContainer.new()
			cell.add_theme_constant_override("separation", UI.px(4))
			cell.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			var tile := StageHeroSkin.portrait_tile(kind, look, 84.0)
			tile.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			cell.add_child(tile)
			var n := UI.label(Strings.t("ROSTER_STATE_GUARDING") if look == "guard" \
				else FormsPresenter.note_name(look), 14)
			n.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			cell.add_child(n)
			forms.add_child(cell)
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
	top.add_theme_constant_override("margin_left", UI.px(12))
	top.add_theme_constant_override("margin_right", UI.px(12))
	level_badge.add_child(top)
	var ids: Array = RosterScreen.kinds_of(slice).keys()
	var at := ids.find(id)
	var plate := UI.plate(title_label, "plate_dark")
	var foot := MarginContainer.new()
	foot.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	foot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	foot.add_theme_constant_override("margin_bottom", UI.px(6))
	level_badge.add_child(foot)
	StageHeroSkin.on_stage(foot, plate, Control.PRESET_CENTER_BOTTOM)
	# The state's icon carries its dot, so the words go without it.
	var state := KitStatus.pill(str(c["line"]).trim_prefix("● "), "characterstates/" + str(c["state"]),
		"plate_dark", 190.0)
	StageHeroSkin.on_stage(top, state, Control.PRESET_TOP_RIGHT)
	if at >= 0:
		StageHeroSkin.on_stage(top, KitStatus.pill(Strings.t("CHARACTER_COUNT", [at + 1, ids.size()]), "",
			"plate_dark"), Control.PRESET_TOP_LEFT)
	# The design's arrows through the roster, in its order, round at the ends.
	if ids.size() > 1 and at >= 0:
		var named := RosterPresenter.names((slice.get("view", {}) as Dictionary).get("characters", []), words)
		for step: int in [-1, 1]:
			var to: int = ids[posmod(at + step, ids.size())]
			var b := KitControls.icon_button("hud/prev" if step < 0 else "hud/next",
				Strings.t("CHARACTER_PREVIOUS" if step < 0 else "CHARACTER_NEXT", str(named.get(to, ""))),
				func() -> void: App.services.router.go(&"character", {"id": to}), "gold_round", 48.0)
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
