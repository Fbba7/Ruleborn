class_name ScoutScreen
extends Control
## The scout report (§12.4, §23.2, "Read their laws"): the chosen target's
## realm as the scout saw it (`StageScout`: its island under mist, the guards
## it counted by role and the wards by kind lined up on the rim, its laws
## named over it, nothing placed), under the design's report: a back key and
## the target's name, its free facts as pills of icons and counts — its
## laws, its guards by role and wards by kind with its watch, its universe's
## size, loot, strain and faults — the line that says what a scout cannot
## see, and the gold key that plans the raid.

var controller: ObservatoryController
var body: VBoxContainer
var status_label: Label
var view: StageView
var scout: StageScout
var _sheet: ScrollContainer
var _keys: Control
var _top: Control
var _heading: PanelContainer
var _dock: HFlowContainer
var _drawn_key := ""


func _ready() -> void:
	App.ready(self)
	controller = App.services.observatory_flow
	_build()
	App.services.store.changed.connect(_on_changed)
	_refresh()


func _on_changed(slice: StringName) -> void:
	if slice == ObservatoryState.OBSERVATORY and is_inside_tree():
		_refresh()


func _build() -> void:
	var column := UI.frame(self)
	view = StageScreen.mount(self, column)
	view.fill = 1.12
	scout = StageScout.new(view)
	var top := HBoxContainer.new()
	top.add_theme_constant_override("separation", UI.px(8))
	_heading = OverlayHud.heading(Strings.t("SCOUT_TITLE"), "")
	top.add_child(_heading)
	_top = top
	column.add_child(top)
	status_label = UI.status("info", "")
	status_label.add_theme_font_size_override("font_size", UI.text_px(13))
	status_label.set_meta("points", 13.0)
	column.add_child(UI.plate(status_label, "glass"))
	StageScreen.window(column, 1.3)
	var s := ScrollContainer.new()
	s.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	s.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var glass := UI.panel("glass")
	glass.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body = VBoxContainer.new()
	body.add_theme_constant_override("separation", UI.px(8))
	body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	glass.add_child(body)
	s.add_child(glass)
	column.add_child(s)
	_sheet = StageScreen.sheet(body, 1.0)
	_keys = StageScreen.handle(column, _sheet)
	_dock = HFlowContainer.new()
	_dock.alignment = FlowContainer.ALIGNMENT_CENTER
	_dock.add_theme_constant_override("h_separation", UI.px(12))
	column.add_child(_dock)
	StageScreen.corner_gap(column)


func _refresh() -> void:
	if not is_inside_tree():
		return
	var s := ObservatoryPresenter.scout(App.services.store.get_slice(ObservatoryState.OBSERVATORY))
	for child: Node in body.get_children():
		body.remove_child(child)
		child.queue_free()
	for child: Node in _dock.get_children():
		child.queue_free()
	_dock.add_child(OverlayHud.back_key(func() -> void: App.services.router.go(&"observatory")))
	if not s["ready"]:
		UI.set_status(status_label, "info", Strings.t("SCOUT_NONE_CHOSEN"))
		(status_label.get_parent() as Control).visible = true
		return
	UI.set_status(status_label, "info", s["protected"])
	(status_label.get_parent() as Control).visible = status_label.text != ""
	(_heading.find_child("Title", true, false) as Label).text = s["title"]
	var card: Dictionary = s["card"]
	var realm: Dictionary = card.get("realm", {})
	var lines: Array = s["lines"]
	# The loot in a gold ring, and the realm's threats counted beside it.
	var hero := HBoxContainer.new()
	hero.add_theme_constant_override("separation", UI.px(10))
	var loot := "~" + ShopPresenter.grouped(int(card.get("loot", 0)))
	hero.add_child(OverlayHud.ring(loot, Strings.t("SCOUT_LOOT_KICKER"), (s["facts"] as Array)[0]))
	var counts := VBoxContainer.new()
	counts.add_theme_constant_override("separation", UI.px(5))
	counts.alignment = BoxContainer.ALIGNMENT_CENTER
	var type := "Heart" if realm.get("realm") == "heart" else str(realm.get("type", "Heart"))
	counts.add_child(OverlayHud.pill(OverlayHud.realm_icon(type), "%d · %d" % [int(realm.get("realm_level", 1)),
		int(realm.get("vault_level", 1))], lines[0], "card"))
	counts.add_child(OverlayHud.pill("crewroles/warden", str(ObservatoryPresenter.total(realm.get("guards", {}))),
		lines[2], "card"))
	counts.add_child(OverlayHud.pill("hud/shield", str(ObservatoryPresenter.total(realm.get("wards", {}))),
		lines[3], "card"))
	hero.add_child(counts)
	body.add_child(hero)
	var sec := OverlayHud.section("island", lines[0])
	var row := OverlayHud.pills_of(sec)
	for p: Control in OverlayFacts.universe(card, s["facts"], false):
		row.add_child(p)
	body.add_child(sec)
	sec = OverlayHud.section("laws", lines[1])
	row = OverlayHud.pills_of(sec)
	var laws := OverlayFacts.laws(realm)
	if laws.is_empty():
		laws.append(OverlayHud.pill("generalui/cancel", "0", lines[1]))
	for p: Control in laws:
		row.add_child(p)
	body.add_child(sec)
	sec = OverlayHud.section("defence", "%s · %s" % [lines[2], lines[3]])
	row = OverlayHud.pills_of(sec)
	for p: Control in OverlayFacts.defence(realm):
		row.add_child(p)
	body.add_child(sec)
	# What a scout cannot know (§12.4), behind its padlock.
	var hidden := OverlayHud.pill("generalui/lock", lines[5], lines[5], "track")
	(hidden.find_child("Words", true, false) as Label).autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	(hidden.find_child("Words", true, false) as Label).size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.add_child(hidden)
	var o: Dictionary = s["raid"]
	var raid := OverlayHud.main_key(Strings.t("SCOUT_PLAN_KEY"), ObservatoryPresenter.fee(card),
		controller.raid.bind(card), o["spoken"])
	raid.disabled = not o["can"]
	raid.set_meta("key", o["key"])
	raid.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_dock.add_child(raid)
	_draw_world(card)


## The target's realm as the scout knows it: a bare island of its level.
func _draw_world(card: Dictionary) -> void:
	var realm: Dictionary = card.get("realm", {})
	var key := "%s|%d" % [card.get("bundle", ""), hash(realm)]
	if key == _drawn_key:
		return
	_drawn_key = key
	var replay := StageRealm.replay_of(StageRealm.blank(int(realm.get("realm_level", 1))))
	if replay == null:
		return
	view.realm_type = StageRealm.realm_type(str(realm.get("type", "Heart")))
	view.show_replay(replay)
	view.show_bare_laws(realm.get("laws", []))
	view.show_vault(false)
	scout.build(realm)


func _process(_delta: float) -> void:
	if _sheet != null and view != null:
		view.cover_bottom = StageScreen.covered_below(view, _keys)
		view.cover_top = StageScreen.covered_above(view, _top)
