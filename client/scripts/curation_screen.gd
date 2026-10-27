class_name CurationScreen
extends Control
## Curation (§13.3, §23.2), "the default creative act", over the draft island
## in 3D with the defence overlay (`OverlayDefence`): the posts a guard may
## stand on, the picked post's sight as the simulation draws it, its moves
## painted green or red and a ghost where it faces. A tap on a post picks it;
## a tap on a green tile next to it moves it there. Below, in words: the
## island's origin and name, the generator's layouts, each guard post — a tap
## picks it for the four-way dial and its moves — each woven law with its
## swaps, previewed free and applied as a weave that spends on a second tap,
## and the draft's save and revert.

## The tray's tabs, in the design's order.
const TABS := ["layout", "posts", "laws", "name"]

var controller: CurationController
var body: VBoxContainer
var header_label: Label
var status_label: Label
## The paid apply tapped once: the next tap spends.
var confirm := ""
var view: StageView
var defence: OverlayDefence
var _sheet: ScrollContainer
var _keys: Control
var _top: Control
var _drawn_key := ""
var _heading: HBoxContainer
var _facts: HFlowContainer
var _save_row: HFlowContainer
var _tabs: VBoxContainer
## The chosen tab of the tray, and the tabs the last refresh filled.
var _tab := ""
var _tab_names: Array[String] = []
var _dialled := false


func _ready() -> void:
	App.ready(self)
	controller = App.services.curation_flow
	_build()
	App.services.store.changed.connect(_on_changed)
	_refresh()
	await controller.load_curation()


func _on_changed(slice: StringName) -> void:
	if slice == CurationState.CURATION and is_inside_tree():
		_refresh()


func _build() -> void:
	var column := UI.frame(self)
	view = StageScreen.mount(self, column)
	view.fill = 0.74
	view.tapped.connect(func(at: Vector2) -> void: _on_tap(view.tile_at(at), at))
	defence = OverlayDefence.new(view)
	var top := VBoxContainer.new()
	top.add_theme_constant_override("separation", UI.px(6))
	_heading = OverlayTop.bar(func() -> void: App.services.router.go(&"map"), Strings.t("CUR_KICKER"),
		Strings.t("CUR_TITLE"))
	header_label = _heading.find_child("Kicker", true, false) as Label
	top.add_child(_heading)
	_facts = HFlowContainer.new()
	_facts.add_theme_constant_override("h_separation", UI.px(5))
	_facts.add_theme_constant_override("v_separation", UI.px(5))
	top.add_child(_facts)
	_top = top
	column.add_child(top)
	status_label = UI.status("info", "")
	column.add_child(UI.plate(status_label, "glass"))
	StageScreen.window(column, 1.2)
	# The design's segmented tray tabs; their words wrap at large text.
	_tabs = VBoxContainer.new()
	column.add_child(_tabs)
	var scroller := ScrollContainer.new()
	scroller.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroller.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var glass := UI.panel("glass")
	glass.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body = VBoxContainer.new()
	body.add_theme_constant_override("separation", UI.px(8))
	body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	glass.add_child(body)
	scroller.add_child(glass)
	column.add_child(scroller)
	_sheet = StageScreen.sheet(body, 0.62)
	_keys = StageScreen.handle(column, _sheet)
	column.remove_child(_tabs)
	column.add_child(_tabs)
	column.move_child(_tabs, scroller.get_index())
	# The dock: back to the map, and the draft's undo and save once it
	# changes, in the thumb's reach.
	_save_row = HFlowContainer.new()
	_save_row.alignment = FlowContainer.ALIGNMENT_CENTER
	_save_row.add_theme_constant_override("h_separation", UI.px(10))
	column.add_child(_save_row)


func _refresh() -> void:
	if not is_inside_tree():
		return
	var focused := get_viewport().gui_get_focus_owner()
	var focus_item := str(focused.get_meta("item", "")) if focused != null else ""
	var c := CurationPresenter.screen(App.services.store.get_slice(CurationState.CURATION))
	if c["error"] != "":
		UI.set_status(status_label, "alarm", c["error"])
	elif c["said"] != "":
		UI.set_status(status_label, "success", c["said"])
	elif c["busy"] != "" or not c["ready"]:
		UI.set_status(status_label, "info", Strings.t("COMMON_LOADING"))
	else:
		UI.set_status(status_label, "info", "")
	header_label.text = str(c.get("header", "")).replace("\n", " · ").to_upper()
	(status_label.get_parent() as Control).visible = status_label.text != ""
	for holder: Node in [body, _facts, _save_row, _tabs]:
		for child: Node in holder.get_children():
			holder.remove_child(child)
			child.queue_free()
	# §13's rehearsal: the draft as it stands, against a simulated crew.
	_save_row.add_child(KitControls.round_action("planningactions/rehearse", Strings.t("CUR_TEST_RUN"),
		func() -> void:
			DefencesScreen.tab = 0
			App.services.router.go(&"defences")))
	if not c["ready"]:
		return
	var busy: bool = c["busy"] != ""
	(_heading.find_child("Title", true, false) as Label).text = str(c["name"])
	_heading.accessibility_description = c["origin"]
	if c["hold"] != "":
		_facts.add_child(OverlayHud.pill("realmactions/defence", "", c["hold"]))
	# A post picked (on the island or by its key) brings up its dial.
	var dialled := not (c["dial"] as Array).is_empty()
	if dialled and not _dialled:
		_tab = "posts"
	_dialled = dialled
	_layouts(c["layouts"], busy)
	if not (c["posts"] as Array).is_empty():
		_posts(c["posts"], c["dial"], busy)
	for row: Dictionary in c["laws"]:
		_law(row, busy)
	if not (c["changes"] as Dictionary).is_empty():
		var ch: Dictionary = c["changes"]
		_save_row.add_child(OverlayHud.pill("generalui/timer", "", ch["line"]))
		_save_row.add_child(_offer(ch["revert"], busy, controller.revert, "leather", "generalui/cancel"))
		_save_row.add_child(_offer(ch["save"], busy, func() -> void: await controller.save(), "gold",
			"generalui/confirm"))
	if not (c["naming"] as Dictionary).is_empty():
		_naming(c["naming"], busy)
	_show_tab()
	_draw_world()
	if focus_item != "":
		for b: Button in find_children("*", "Button", true, false):
			if b.get_meta("item", "") == focus_item and b.is_visible_in_tree():
				b.grab_focus.call_deferred()
				break


## A presenter's offer as a key in `look`, with `icon`, its words `text`
## (the offer's own unless given), its sentence spoken, and its reason, if
## refused, on a small pill beside it.
func _offer(o: Dictionary, busy: bool, pressed: Callable, look := "leather", icon := "", text := "") -> Control:
	var b := UI.action(text if text != "" else str(o["action"]), pressed, look, str(o["spoken"]))
	b.disabled = busy or not o["can"]
	b.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	b.set_meta("key", o["key"])
	b.set_meta("item", o["item"])
	if icon != "" and Icons.has(icon):
		b.icon = Icons.texture(icon)
		b.add_theme_constant_override("icon_max_width", UI.px(22))
	if str(o.get("why", "")) == "":
		return b
	var box := VBoxContainer.new()
	box.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	box.add_child(b)
	var why := OverlayHud.pill("hud/warning", o["why"], o["why"], "track")
	var words := why.find_child("Words", true, false) as Label
	words.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	words.custom_minimum_size.x = UI.px(140)
	box.add_child(why)
	return box


## A tab's section on the tray: shown while its tab is chosen.
func _section(key: String, tab: String, title: String) -> VBoxContainer:
	var box := OverlayHud.section(key, title)
	box.set_meta("tab", tab)
	var holder := MarginContainer.new()
	holder.add_child(box)
	body.add_child(holder)
	if not _tab_names.has(tab):
		_tab_names.append(tab)
	return box


func _layouts(offers: Array, busy: bool) -> void:
	var row := OverlayHud.pills_of(_section("layouts", "layout", Strings.t("CUR_LAYOUTS")))
	for o: Dictionary in offers:
		var more := str(o["seed"]) == ""
		row.add_child(_offer(o, busy, _lay.bind(o), "card", "hud/plus" if more else "realmactions/terrain"))


## The posts as numbered keys, the picked one in gold, and its dial: the
## four turns and the four moves, each on its side of a compass.
func _posts(offers: Array, dial: Array, busy: bool) -> void:
	var row := OverlayHud.pills_of(_section("posts", "posts", Strings.t("CUR_POSTS")))
	for i: int in offers.size():
		var o: Dictionary = offers[i]
		row.add_child(_offer(o, busy, _pick.bind(o), "gold" if o.get("picked", false) else "leather",
			"crewroles/warden", str(i + 1)))
	if dial.is_empty():
		return
	var turns := dial.filter(func(d: Dictionary) -> bool: return d.has("facing"))
	var steps := dial.filter(func(d: Dictionary) -> bool: return not d.has("facing"))
	row.add_child(_compass(turns, busy, "heiststatus/visioncone"))
	row.add_child(_compass(steps, busy, "realmactions/move"))


## Four offers north, east, south and west round a mark.
func _compass(offers: Array, busy: bool, mark: String) -> GridContainer:
	var grid := GridContainer.new()
	grid.columns = 3
	grid.add_theme_constant_override("h_separation", UI.px(2))
	grid.add_theme_constant_override("v_separation", UI.px(2))
	var arrows := ["↑", "→", "↓", "←"]
	var cells: Array[Control] = []
	for k: int in 9:
		cells.append(null)
	var at := [1, 5, 7, 3]
	for i: int in mini(4, offers.size()):
		var o: Dictionary = offers[i]
		var b := _offer(o, busy, _dial.bind(o), "leather", "", arrows[i])
		cells[at[i]] = b
	var centre := CenterContainer.new()
	centre.add_child(Icons.view(mark, 30.0))
	cells[4] = centre
	for k: int in 9:
		grid.add_child(cells[k] if cells[k] != null else Control.new())
	return grid


func _law(row: Dictionary, busy: bool) -> void:
	var box := _section("law:%d" % row["slot"], "laws", row["text"])
	var pills := OverlayHud.pills_of(box)
	var law := ""
	for o: Dictionary in row["offers"]:
		pills.add_child(_offer(o, busy, _preview.bind(o, int(row["slot"])), "card",
			OverlayHud.law_icon(str(o["law"])), Strings.term("LAW", str(o["law"]))))
		law = str(o["law"])
	if row.has("preview"):
		box.add_child(OverlayHud.pill(OverlayHud.law_icon(law), "", row["preview"]))
		var shown: Dictionary = (row["apply"] as Dictionary).duplicate()
		if confirm == "apply" and str(shown["cost"]) != "":
			shown["action"] = Strings.t("CODEX_CONFIRM", shown["cost"])
			shown["spoken"] = Strings.t("CODEX_CONFIRM_SPOKEN", [shown["spoken"], shown["cost"]])
		box.add_child(_offer(shown, busy, _apply.bind(row["apply"]), "gold", "resources/aether"))


func _naming(n: Dictionary, busy: bool) -> void:
	var box := _section("naming", "name", Strings.t("CUR_NAMING"))
	var row := OverlayHud.pills_of(box)
	row.add_child(UI.action(Strings.t("CUR_NEXT_ADJECTIVE"), controller.cycle_name.bind("adjective"), "card"))
	row.add_child(UI.action(Strings.t("CUR_NEXT_NOUN"), controller.cycle_name.bind("noun"), "card"))
	row.add_child(_offer(n["give"], busy, func() -> void: await controller.name_island(), "gold",
		"generalui/confirm"))


## The tabs over the tray, as the design's Layout · Laws · Posts, and only
## the chosen tab's sections shown.
func _show_tab() -> void:
	if not _tab_names.has(_tab):
		_tab = _tab_names[0] if not _tab_names.is_empty() else ""
	var ids: Array = TABS.filter(func(t: String) -> bool: return _tab_names.has(t))
	if not ids.is_empty():
		var tabs := OverlayTop.tabs(ids, ids.map(func(t: String) -> String: return Strings.t("CUR_TAB_" + t.to_upper())),
			_tab, func(id: String) -> void:
				_tab = id
				_refresh.call_deferred())
		tabs.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		_tabs.add_child(tabs)
	for holder: Node in body.get_children():
		var box := holder.get_child(0) if holder.get_child_count() > 0 else null
		if box != null and box.has_meta("tab"):
			(holder as Control).visible = str(box.get_meta("tab")) == _tab
	_tab_names.clear()


func _lay(o: Dictionary) -> void:
	if str(o["seed"]) == "":
		await controller.more_layouts()
	else:
		await controller.lay(str(o["seed"]))


func _pick(o: Dictionary) -> void:
	_tab = "posts"
	controller.pick_post(o["at"])


func _dial(o: Dictionary) -> void:
	if o.has("facing"):
		controller.face_post(int(o["facing"]))
	else:
		controller.move_post(o["step"])


func _preview(o: Dictionary, slot: int) -> void:
	confirm = ""
	controller.preview_swap(slot, str(o["law"]))


## A swap's first tap shows its price to confirm; the second weaves it.
func _apply(o: Dictionary) -> void:
	if str(o["cost"]) != "" and confirm != "apply":
		confirm = "apply"
		_refresh()
		return
	confirm = ""
	await controller.apply_swap()


## The draft in 3D with the defence overlay, rebuilt when the draft or the
## picked post changes.
func _draw_world() -> void:
	var slice: Dictionary = App.services.store.get_slice(CurationState.CURATION)
	var island := CurationPresenter.draft_island(slice)
	if island == null:
		return
	var picked: Vector2i = slice.get("post", CurationState.NO_POST)
	var key := "%d|%s" % [hash(island.bytes()), picked]
	if key == _drawn_key:
		return
	_drawn_key = key
	var replay := StageRealm.replay_of(island.bytes())
	if replay == null:
		return
	view.realm_type = StageRealm.realm_type(str((slice.get("view", {}) as Dictionary).get("type", "Heart")))
	view.show_replay(replay)
	defence.draw(island, replay, picked, moves(island, picked))


## The tiles a move of the post on `picked` reaches, each with whether the
## island allows it there (`CurationPresenter.moved`, on a copy).
static func moves(island: RulebornIsland, picked: Vector2i) -> Dictionary:
	var out := {}
	if picked == CurationState.NO_POST:
		return out
	for step: Vector2i in CurationPresenter.STEPS:
		var probe := RulebornIsland.new()
		probe.read(island.bytes())
		out[picked + step] = CurationPresenter.moved(probe, picked, picked + step)
	return out


## A tap on a post picks it; on a tile a move reaches, moves the picked post.
func _on_tap(tile: Vector2i, _at: Vector2) -> void:
	var slice: Dictionary = App.services.store.get_slice(CurationState.CURATION)
	var island := CurationPresenter.draft_island(slice)
	if island == null or tile.x < 0 or str(slice.get("busy", "")) != "":
		return
	if str(island.occupant(tile.x, tile.y)).begins_with("guard:"):
		_tab = "posts"
		controller.pick_post(tile)
		return
	var picked: Vector2i = slice.get("post", CurationState.NO_POST)
	var step := tile - picked
	if picked != CurationState.NO_POST and step in CurationPresenter.STEPS:
		controller.move_post(step)


func _process(_delta: float) -> void:
	if _sheet != null and view != null:
		view.cover_bottom = StageScreen.covered_below(view, _keys)
		view.cover_top = StageScreen.covered_above(view, _top)
