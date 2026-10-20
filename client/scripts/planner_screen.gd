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
	column.add_child(OverlaySheet.ribbon(UI.title(Strings.t("PLAN_TITLE"))))
	header_label = UI.label("", UI.TEXT_POINTS, true)
	_top = UI.plate(header_label)
	column.add_child(_top)
	status_label = UI.status("info", "")
	column.add_child(UI.plate(status_label))
	StageScreen.window(column, 1.1)
	body = UI.scroll(column)
	_sheet = StageScreen.sheet(body, 0.62)
	var actions := UI.row(-1.0, true)
	_keys = actions
	actions.add_child(UI.button(Strings.t("OBS_TITLE"), func() -> void: App.services.router.go(&"scout"), true))
	actions.add_child(StageScreen.fold_key(_sheet))
	column.add_child(UI.narrow(OverlaySheet.dock(actions)))
	OverlaySheet.dress(self)


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
	for child in body.get_children():
		body.remove_child(child)
		child.queue_free()
	if not p["ready"]:
		return
	var target := VBoxContainer.new()
	for line: String in [p["clock"], p["entry"], p["route"], p["faults"], p["laws"]["line"], p["laws"]["unfamiliar"]]:
		if line != "":
			target.add_child(UI.label(line, UI.TEXT_POINTS, true))
	body.add_child(UI.plate(target))
	body.add_child(_choices(p["crew_count"], p["crew"], func(o: Dictionary) -> void: controller.toggle(int(o["id"]))))
	body.add_child(_choices(Strings.t("PLAN_SAGE"), p["sages"],
		func(o: Dictionary) -> void: controller.pick_sage(str(o["id"]))))
	body.add_child(_choices(p["casts_count"], p["casts"],
		func(o: Dictionary) -> void: controller.toggle_cast(str(o["law"]))))
	var filling := VBoxContainer.new()
	filling.add_child(UI.label(p["load"], UI.TEXT_POINTS, true))
	var steps := UI.row()
	for step: int in [-1, 1]:
		var words := Strings.t("PLAN_LOAD_DOWN") if step < 0 else Strings.t("PLAN_LOAD_UP")
		var b := UI.button(words, controller.step_load.bind(step))
		b.disabled = not p["load_down" if step < 0 else "load_up"]
		b.set_meta("key", "load:%d" % step)
		b.set_meta("item", "load:%d" % step)
		steps.add_child(b)
	filling.add_child(steps)
	body.add_child(UI.plate(filling))
	var start := VBoxContainer.new()
	if p["protected"] != "":
		start.add_child(UI.label(p["protected"], UI.TEXT_POINTS, true))
	start.add_child(RosterScreen.offer(p["start"], false, controller.start))
	body.add_child(UI.plate(start))
	OverlaySheet.dress(body)
	OverlaySheet.unsqueeze(body)
	_draw_world(store.get_slice(PlannerState.PLANNER).get("target", {}))
	if focus_item != "":
		for b: Button in find_children("*", "Button", true, false):
			if b.get_meta("item", "") == focus_item and b.is_visible_in_tree():
				b.grab_focus.call_deferred()
				break


## A titled list of choices, each a button that says why it waits.
func _choices(title: String, options: Array, pressed: Callable) -> Control:
	var box := VBoxContainer.new()
	box.add_child(UI.label(title, UI.TEXT_POINTS, true))
	for o: Dictionary in options:
		box.add_child(RosterScreen.offer(o, false, pressed.bind(o)))
	return UI.plate(box)


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
	var across: bool = card.get("across", false)
	var depth := maxi(1, int(card.get("depth", 1)))
	view.fill = (1.25 + 0.35 * depth) if across else 1.0
	view.look_up = (1.0 + 3.2 * depth) if across else 0.0


func _process(_delta: float) -> void:
	if _sheet != null and view != null:
		view.cover_bottom = StageScreen.covered_below(view, _sheet, _keys)
		view.cover_top = StageScreen.covered_above(view, _top)
