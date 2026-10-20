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
var _laws_key := 0


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
	column.add_child(OverlaySheet.ribbon(UI.title(Strings.t("CUR_TITLE"))))
	header_label = UI.label("", UI.TEXT_POINTS, true)
	_top = UI.plate(header_label)
	column.add_child(_top)
	status_label = UI.status("info", "")
	column.add_child(UI.plate(status_label))
	StageScreen.window(column, 1.2)
	body = UI.scroll(column)
	_sheet = StageScreen.sheet(body, 0.62)
	var actions := UI.row(-1.0, true)
	actions.add_child(UI.button(Strings.t("HOME_MAP"), func() -> void: App.services.router.go(&"map"), true))
	actions.add_child(UI.button(Strings.t("COMMON_HOME"), func() -> void: App.services.router.go(&"home")))
	_keys = StageScreen.handle(column, _sheet)
	column.add_child(UI.narrow(OverlaySheet.dock(actions)))
	OverlaySheet.dress(self)


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
	header_label.text = c.get("header", "")
	(status_label.get_parent() as Control).visible = status_label.text != ""
	for child in body.get_children():
		body.remove_child(child)
		child.queue_free()
	if not c["ready"]:
		return
	var busy: bool = c["busy"] != ""
	var top := VBoxContainer.new()
	top.add_child(UI.label(c["origin"], UI.TEXT_POINTS, true))
	top.add_child(UI.label(c["name"], UI.TEXT_POINTS, true))
	if c["hold"] != "":
		top.add_child(UI.label(c["hold"], UI.TEXT_POINTS, true))
	body.add_child(UI.plate(top))
	_section("layouts", Strings.t("CUR_LAYOUTS"), c["layouts"], busy, _lay)
	if not (c["posts"] as Array).is_empty():
		var posts := _section("posts", Strings.t("CUR_POSTS"), c["posts"], busy, _pick)
		for o: Dictionary in c["dial"]:
			posts.add_child(RosterScreen.offer(o, busy, _dial.bind(o)))
	for row: Dictionary in c["laws"]:
		var box := _section("law:%d" % row["slot"], row["text"], row["offers"], busy, _preview.bind(int(row["slot"])))
		if row.has("preview"):
			box.add_child(UI.label(row["preview"], UI.TEXT_POINTS, true))
			var shown: Dictionary = (row["apply"] as Dictionary).duplicate()
			if confirm == "apply" and str(shown["cost"]) != "":
				shown["action"] = Strings.t("CODEX_CONFIRM", shown["cost"])
				shown["spoken"] = Strings.t("CODEX_CONFIRM_SPOKEN", [shown["spoken"], shown["cost"]])
			box.add_child(RosterScreen.offer(shown, busy, _apply.bind(row["apply"])))
	if not (c["changes"] as Dictionary).is_empty():
		var ch: Dictionary = c["changes"]
		var box := VBoxContainer.new()
		box.set_meta("section", "changes")
		box.add_child(UI.label(ch["line"], UI.TEXT_POINTS, true))
		box.add_child(RosterScreen.offer(ch["save"], busy, func() -> void: await controller.save()))
		box.add_child(RosterScreen.offer(ch["revert"], busy, controller.revert))
		body.add_child(UI.plate(box))
	if not (c["naming"] as Dictionary).is_empty():
		_naming(c["naming"], busy)
	OverlaySheet.dress(body)
	OverlaySheet.unsqueeze(body)
	_draw_world()
	if focus_item != "":
		for b: Button in find_children("*", "Button", true, false):
			if b.get_meta("item", "") == focus_item and b.is_visible_in_tree():
				b.grab_focus.call_deferred()
				break


## A plate titled `title` with a button for each of `offers`, each calling
## `pressed` with its offer.
func _section(key: String, title: String, offers: Array, busy: bool, pressed: Callable) -> VBoxContainer:
	var box := VBoxContainer.new()
	box.set_meta("section", key)
	box.add_child(UI.label(title, UI.TEXT_POINTS, true))
	for o: Dictionary in offers:
		box.add_child(RosterScreen.offer(o, busy, pressed.bind(o)))
	body.add_child(UI.plate(box))
	return box


func _naming(n: Dictionary, busy: bool) -> void:
	var box := VBoxContainer.new()
	box.set_meta("section", "naming")
	box.add_child(UI.label(Strings.t("CUR_NAMING"), UI.TEXT_POINTS, true))
	var words := UI.row()
	words.add_child(UI.button(Strings.t("CUR_NEXT_ADJECTIVE"), controller.cycle_name.bind("adjective")))
	words.add_child(UI.button(Strings.t("CUR_NEXT_NOUN"), controller.cycle_name.bind("noun")))
	box.add_child(words)
	box.add_child(RosterScreen.offer(n["give"], busy, func() -> void: await controller.name_island()))
	body.add_child(UI.plate(box))


func _lay(o: Dictionary) -> void:
	if str(o["seed"]) == "":
		await controller.more_layouts()
	else:
		await controller.lay(str(o["seed"]))


func _pick(o: Dictionary) -> void:
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
	# The laws' signatures change only with the draft, not with the pick.
	var woven := hash(island.bytes())
	if woven != _laws_key:
		_laws_key = woven
		view.show_laws(replay)
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
