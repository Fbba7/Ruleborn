class_name PlannerScreen
extends Control
## The heist planner (§12.5, §23.2, "Plan the run"): the target's laws with
## the unfamiliar ones flagged, its clock and where the crew enters; the crew
## of 3 to the Keeper's most, resting characters unavailable; the Sage; the
## casts; the load target; and Start, which says what raiding a player ends
## while the player is protected. The scout report's Plan opens it.
##
## Above the words, the target's universe as the card tells it (`StagePlan`):
## its realm bare with every edge tile marked for landing, and across a
## universe its outer realms on their bridges, the faults in red and the
## route to the Heart.

var controller: PlannerController
var body: VBoxContainer
var header_label: Label
var status_label: Label
var view: StageView
var plan: StagePlan
var _sheet: ScrollContainer
var _keys: Control
var _top: Control
var _drawn_key := ""
var _tabs: HBoxContainer
var _dock: HBoxContainer
var _tab := "plan"


func _ready() -> void:
	App.ready(self)
	controller = App.services.planner_flow
	_build()
	App.services.store.changed.connect(_on_changed)
	_refresh()
	await controller.load_all()


func _on_changed(slice: StringName) -> void:
	if slice in [PlannerState.PLANNER, RosterState.ROSTER, SageState.SAGES, CodexState.CODEX, KeeperState.KEEPER] \
			and is_inside_tree():
		_refresh()


func _build() -> void:
	var column := UI.frame(self)
	view = StageScreen.mount(self, column)
	view.fill = 1.0
	plan = StagePlan.new(view)
	_top = OverlayTop.bar(func() -> void: App.services.router.go(&"scout"), Strings.t("PLAN_TITLE"), "")
	header_label = _top.find_child("Title", true, false) as Label
	column.add_child(_top)
	status_label = UI.status("info", "")
	column.add_child(UI.plate(status_label, "glass"))
	StageScreen.window(column, 1.1)
	_tabs = HBoxContainer.new()
	_tabs.add_theme_constant_override("separation", UI.px(4))
	column.add_child(_tabs)
	var scroller := ScrollContainer.new()
	scroller.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroller.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body = VBoxContainer.new()
	body.add_theme_constant_override("separation", UI.px(8))
	body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroller.add_child(body)
	column.add_child(scroller)
	_sheet = StageScreen.sheet(body, 0.9)
	_keys = StageScreen.handle(column, _sheet)
	column.remove_child(_tabs)
	column.add_child(_tabs)
	column.move_child(_tabs, scroller.get_index())
	_dock = HBoxContainer.new()
	_dock.alignment = BoxContainer.ALIGNMENT_CENTER
	_dock.add_theme_constant_override("separation", UI.px(10))
	column.add_child(_dock)
	StageScreen.corner_gap(column)


func _refresh() -> void:
	if not is_inside_tree():
		return
	var focused := get_viewport().gui_get_focus_owner()
	var focus_item := str(focused.get_meta("item", "")) if focused != null else ""
	var store := App.services.store
	var p := PlannerPresenter.screen(store.get_slice(PlannerState.PLANNER), store.get_slice(KeeperState.KEEPER),
		store.get_slice(RosterState.ROSTER), store.get_slice(SageState.SAGES), store.get_slice(CodexState.CODEX),
		store.get_slice(ObservatoryState.OBSERVATORY))
	UI.set_status(status_label, "info", "" if p["ready"] else Strings.t("COMMON_LOADING"))
	(status_label.get_parent() as Control).visible = status_label.text != ""
	header_label.text = p.get("title", "")
	for holder: Node in [body, _tabs, _dock]:
		for child: Node in holder.get_children():
			holder.remove_child(child)
			child.queue_free()
	if not p["ready"]:
		return
	var card: Dictionary = store.get_slice(PlannerState.PLANNER).get("target", {})
	var v := _values(store.get_slice(PlannerState.PLANNER), store.get_slice(KeeperState.KEEPER))
	var tabs := OverlayTop.tabs(["plan", "crew"], [Strings.t("PLAN_TAB_PLAN"),
		"%s %s" % [Strings.t("PLAN_TAB_CREW"), v["crew"]]], _tab, func(id: String) -> void:
			_tab = id
			_refresh.call_deferred())
	tabs.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_tabs.add_child(tabs)
	# Both tabs are built, the chosen one shown.
	_plan_tab(p, card, v)
	_crew_tab(p)
	for holder: Node in body.get_children():
		if holder.has_meta("tab"):
			(holder as Control).visible = str(holder.get_meta("tab")) == _tab
	var o: Dictionary = p["start"]
	var under: String = str(o["why"]) if str(o["why"]) != "" else _clock(card)
	var start := OverlayHud.main_key(o["action"], under, controller.start, o["spoken"])
	start.disabled = not o["can"]
	start.set_meta("key", o["key"])
	start.set_meta("item", o["item"])
	start.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_dock.add_child(start)
	if p["protected"] != "":
		var note := OverlayHud.pill("hud/shield", p["protected"], p["protected"], "track")
		var words := note.find_child("Words", true, false) as Label
		words.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		words.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		body.add_child(note)
	_draw_world(card)
	if focus_item != "":
		for b: Button in find_children("*", "Button", true, false):
			if b.get_meta("item", "") == focus_item and b.is_visible_in_tree():
				b.grab_focus.call_deferred()
				break


## The plan as the design's parchment table: each row a name and its value,
## then the target's laws as chips, the unfamiliar ones flagged in red, and
## the load target with its steps.
func _plan_tab(p: Dictionary, card: Dictionary, v: Dictionary) -> void:
	var page := _page("plan")
	var table := UI.panel("parchment")
	var rows := VBoxContainer.new()
	rows.add_theme_constant_override("separation", UI.px(2))
	table.add_child(rows)
	_row(rows, "heiststatus/clock", "PLAN_ROW_CLOCK", _clock(card), p["clock"])
	var across: bool = card.get("across", false)
	_row(rows, "planningactions/landing", "PLAN_ROW_ENTRY",
		Strings.t("PLAN_VALUE_ENTRY_ACROSS" if across else "PLAN_VALUE_ENTRY"), p["entry"])
	if p["route"] != "":
		_row(rows, "planningactions/route", "PLAN_ROW_ROUTE",
			Strings.t("PLAN_VALUE_ROUTE", maxi(1, int(card.get("depth", 1)))), p["route"])
	if p["faults"] != "":
		_row(rows, "stabilitybands/fault", "PLAN_ROW_FAULTS", p["faults"], p["faults"])
	_row(rows, "hud/crew", "PLAN_TAB_CREW", v["crew"], p["crew_count"])
	_row(rows, "heistcontrols/cast", "PLAN_CASTS_ROW", v["casts"], p["casts_count"])
	_row(rows, "heiststatus/bagcapacity", "PLAN_ROW_LOAD", v["load"], p["load"])
	page.add_child(table)
	var laws: Array = (card.get("realm", {}) as Dictionary).get("laws", [])
	var flagged: Array = (p["laws"] as Dictionary).get("ids", [])
	var chips: Array[Control] = []
	var k := UI.label(Strings.t("PLAN_LAWS_ROUTE"), 14.0)
	k.theme_type_variation = "BodyBold"
	k.add_theme_color_override("font_color", Tokens.color("gold"))
	chips.append(_on_glass(k))
	for l: String in laws:
		chips.append(OverlayHud.pill(OverlayHud.law_icon(l), Strings.term("LAW", l),
			(p["laws"] as Dictionary)["unfamiliar"] if l in flagged else Strings.term("LAW", l),
			"red" if l in flagged else "glass"))
	page.add_child(OverlayHud.row_of(chips))
	var steps: Array[Control] = []
	for step: int in [-1, 1]:
		var b := UI.action("−" if step < 0 else "+", controller.step_load.bind(step), "leather",
			Strings.t("PLAN_LOAD_DOWN") if step < 0 else Strings.t("PLAN_LOAD_UP"))
		b.disabled = not p["load_down" if step < 0 else "load_up"]
		b.set_meta("key", "load:%d" % step)
		b.set_meta("item", "load:%d" % step)
		steps.append(b)
	steps.insert(1, OverlayHud.pill("heiststatus/bagcapacity", v["load"], p["load"]))
	var load_row := OverlayHud.row_of(steps)
	load_row.alignment = FlowContainer.ALIGNMENT_CENTER
	page.add_child(load_row)


## The crew to choose, each a card in its colour once chosen; the Sage; and
## the casts.
func _crew_tab(p: Dictionary) -> void:
	var page := _page("crew")
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", UI.px(6))
	grid.add_theme_constant_override("v_separation", UI.px(6))
	for o: Dictionary in p["crew"]:
		var picked := str(o["action"]).begins_with("● ")
		var b := _choice(o, func() -> void: controller.toggle(int(o["id"])), "card_selected" if picked else "card",
			"characterstates/resting" if o.get("resting", false) else "characterstates/onaheist")
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		grid.add_child(b)
	page.add_child(grid)
	# Two cards a row, as the design's, unless their words ask for more than
	# half the sheet (a long language, large text): then one.
	var half := (get_viewport_rect().size.x - UI.px(64)) / 2.0
	for b: Node in grid.get_children():
		if (b as Control).get_combined_minimum_size().x > half:
			grid.columns = 1
	var sages: Array[Control] = []
	for o: Dictionary in p["sages"]:
		sages.append(_choice(o, func() -> void: controller.pick_sage(str(o["id"])),
			"card_selected" if str(o["action"]).begins_with("● ") else "card", "screens/sagehall"))
	var sec := OverlayHud.section("crew", Strings.t("PLAN_SAGE"))
	for c: Control in sages:
		OverlayHud.pills_of(sec).add_child(c)
	page.add_child(sec)
	sec = OverlayHud.section("laws", p["casts_count"])
	for o: Dictionary in p["casts"]:
		OverlayHud.pills_of(sec).add_child(_choice(o, func() -> void: controller.toggle_cast(str(o["law"])),
			"card_selected" if str(o["action"]).begins_with("● ") else "card", OverlayHud.law_icon(str(o["law"]))))
	page.add_child(sec)


## A tab's page on the sheet.
func _page(tab: String) -> VBoxContainer:
	var page := VBoxContainer.new()
	page.add_theme_constant_override("separation", UI.px(8))
	page.set_meta("tab", tab)
	body.add_child(page)
	return page


## An offer as a key: its own words (a chosen one leads with ●), its reason
## spoken with it when it waits.
func _choice(o: Dictionary, pressed: Callable, look: String, icon: String) -> Button:
	var b := UI.action(o["action"], pressed, look, o["spoken"] if str(o["why"]) == "" else "%s, %s" % [o["spoken"],
		o["why"]])
	b.disabled = not o["can"]
	# Its words wrap at large text rather than widen the sheet.
	b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	b.set_meta("key", o["key"])
	b.set_meta("item", o["item"])
	b.tooltip_text = o["why"]
	if Icons.has(icon):
		b.icon = Icons.texture(icon)
		b.add_theme_constant_override("icon_max_width", UI.px(22))
	return b


## A table row: an icon, the row's name in brown ink, its value in bold.
func _row(rows: VBoxContainer, icon: String, name_key: String, value: String, spoken: String) -> void:
	var line := HBoxContainer.new()
	line.add_theme_constant_override("separation", UI.px(8))
	line.accessibility_name = spoken
	line.add_child(Icons.view(icon, 20.0))
	var n := UI.label(Strings.t(name_key), 14.0)
	n.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	n.custom_minimum_size.x = UI.px(64)
	n.theme_type_variation = "Secondary"
	line.add_child(n)
	var v := UI.label(value, 14.0, true)
	v.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	v.add_theme_font_override("font", UI.bold_font())
	v.set_meta("bold", true)
	line.add_child(v)
	rows.add_child(line)


static func _on_glass(c: Control) -> Control:
	var p := UI.panel("glass")
	p.add_child(c)
	return p


## The heist clock as the card gives it: one time, or the range by realm.
static func _clock(card: Dictionary) -> String:
	var a := int(card.get("clock", 0))
	var b := int(card.get("clock_longest", a))
	var t := func(sec: int) -> String: return "%d:%02d" % [sec / 60, sec % 60]
	return t.call(a) if b <= a else "%s–%s" % [t.call(a), t.call(b)]


## The table's values without their names (the row names them): the crew
## and casts against their limits, and the load target, each from the
## catalogue's own value line so every language words it whole.
static func _values(planner: Dictionary, keeper: Dictionary) -> Dictionary:
	var lim := PlannerPresenter.limits(keeper)
	return {"crew": Strings.t("PLAN_VALUE_OF", [(planner.get("crew", []) as Array).size(), int(lim["crew"])]),
		"casts": Strings.t("PLAN_VALUE_CASTS", [(planner.get("casts", []) as Array).size(), int(lim["casts"])]),
		"load": Strings.t("PLAN_VALUE_LOAD", int(planner.get("load", 100)))}


## The target's universe, rebuilt when the target changes.
func _draw_world(card: Dictionary) -> void:
	var key := "%s|%d" % [card.get("bundle", ""), hash(card)]
	if key == _drawn_key or card.is_empty():
		return
	_drawn_key = key
	var realm: Dictionary = card.get("realm", {})
	var replay := StageRealm.replay_of(StageRealm.blank(int(realm.get("realm_level", 1))))
	if replay == null:
		return
	view.realm_type = StageRealm.realm_type(str(realm.get("type", "Heart")))
	view.show_replay(replay)
	view.show_vault(false)
	plan.build(card)
	view.show_bare_laws(realm.get("laws", []))
	var across: bool = card.get("across", false)
	var depth := maxi(1, int(card.get("depth", 1)))
	view.fill = (1.25 + 0.35 * depth) if across else 1.0
	view.look_up = (1.0 + 3.2 * depth) if across else 0.0


func _process(_delta: float) -> void:
	if _sheet != null and view != null:
		view.cover_bottom = StageScreen.covered_below(view, _keys)
		view.cover_top = StageScreen.covered_above(view, _top)
