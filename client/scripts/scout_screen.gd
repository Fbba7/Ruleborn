class_name ScoutScreen
extends Control
## The scout report (§12.4, §23.2, "Read their laws"): the chosen target's
## realm as the scout saw it (`StageScout`: its island under mist, the guards
## it counted by role and the wards by kind lined up on the rim, its laws
## named over it, nothing placed), and below, its free facts in words — its
## laws, its guards by role, its wards by kind, its watch, one rough loot
## estimate, strain and faults — and the button that raids it.

var controller: ObservatoryController
var body: VBoxContainer
var status_label: Label
var view: StageView
var scout: StageScout
var _sheet: ScrollContainer
var _keys: Control
var _top: Control
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
	_top = OverlaySheet.ribbon(UI.title(Strings.t("SCOUT_TITLE")))
	column.add_child(_top)
	status_label = UI.status("info", "")
	column.add_child(UI.plate(status_label))
	StageScreen.window(column, 1.3)
	body = UI.scroll(column)
	_sheet = StageScreen.sheet(body, 0.6)
	var actions := UI.row(-1.0, true)
	actions.add_child(UI.button(Strings.t("OBS_TITLE"), func() -> void: App.services.router.go(&"observatory")))
	actions.add_child(UI.button(Strings.t("COMMON_HOME"), func() -> void: App.services.router.go(&"home"), true))
	_keys = StageScreen.handle(column, _sheet)
	column.add_child(UI.narrow(OverlaySheet.dock(actions)))
	OverlaySheet.dress(self)


func _refresh() -> void:
	if not is_inside_tree():
		return
	var s := ObservatoryPresenter.scout(App.services.store.get_slice(ObservatoryState.OBSERVATORY))
	for child in body.get_children():
		body.remove_child(child)
		child.queue_free()
	if not s["ready"]:
		UI.set_status(status_label, "info", Strings.t("SCOUT_NONE_CHOSEN"))
		(status_label.get_parent() as Control).visible = true
		return
	UI.set_status(status_label, "info", s["protected"])
	(status_label.get_parent() as Control).visible = status_label.text != ""
	var box := VBoxContainer.new()
	box.add_child(UI.label(s["title"], UI.TEXT_POINTS, true))
	for line: String in s["facts"]:
		box.add_child(UI.label(line, UI.TEXT_POINTS, true))
	body.add_child(UI.plate(box))
	var realm := VBoxContainer.new()
	for line: String in s["lines"]:
		var l := UI.label(line, UI.TEXT_POINTS, true)
		l.set_meta("fact", true)
		realm.add_child(l)
	body.add_child(UI.plate(realm))
	body.add_child(RosterScreen.offer(s["raid"], false, controller.raid.bind(s["card"])))
	OverlaySheet.dress(body)
	OverlaySheet.unsqueeze(body)
	_draw_world(s["card"])


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
