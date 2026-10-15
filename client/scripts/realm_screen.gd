class_name RealmScreen
extends Control
## One realm (§23.2, "Build and shape one realm"), in words until the world
## draws it (TD.19): its grid and terrain, wards and guard posts against its
## limits, each building on its tile, who works where, and its law pylons.
## The builder shapes the island; the Universe screen buys buildings.

const SLICES := [RealmState.REALM, UniverseState.UNIVERSE, WeavingState.WEAVING, RosterState.ROSTER]

var controller: RealmController
var body: VBoxContainer
var header_label: Label
var status_label: Label


func _ready() -> void:
	App.ready(self)
	controller = App.services.realm_flow
	_build()
	App.services.store.changed.connect(_on_changed)
	_refresh()
	await controller.load_realm()


func _on_changed(slice: StringName) -> void:
	if slice in SLICES and is_inside_tree():
		_refresh()


func _build() -> void:
	var column := UI.frame(self)
	column.add_child(UI.title(Strings.t("RV_TITLE")))
	header_label = UI.label("", UI.TEXT_POINTS, true)
	column.add_child(UI.plate(header_label))
	status_label = UI.status("info", "")
	column.add_child(UI.plate(status_label))
	body = UI.scroll(column)
	var actions := UI.row(-1.0, true)
	actions.add_child(UI.button(Strings.t("HOME_MAP"), func() -> void: App.services.router.go(&"map"), true))
	actions.add_child(UI.button(Strings.t("RV_CURATE"), func() -> void:
		App.services.curation_flow.open(str(App.services.store.get_slice(RealmState.REALM)["realm"]))))
	actions.add_child(UI.button(Strings.t("HOME_BUILD"), func() -> void: App.services.router.go(&"builder")))
	column.add_child(UI.narrow(actions))


func _refresh() -> void:
	if not is_inside_tree():
		return
	var store := App.services.store
	var r := RealmPresenter.screen(store.get_slice(RealmState.REALM), store.get_slice(UniverseState.UNIVERSE),
		store.get_slice(WeavingState.WEAVING), store.get_slice(RosterState.ROSTER))
	if r["error"] != "":
		UI.set_status(status_label, "alarm", r["error"])
	else:
		UI.set_status(status_label, "info", "" if r["ready"] else Strings.t("COMMON_LOADING"))
	header_label.text = r.get("title", "")
	for child in body.get_children():
		body.remove_child(child)
		child.queue_free()
	if not r["ready"]:
		return
	for key: String in ["island", "buildings", "workers", "pylons"]:
		var box := VBoxContainer.new()
		box.set_meta("section", key)
		box.add_child(UI.label(Strings.t("RV_SECTION_" + key.to_upper()), UI.TEXT_POINTS, true))
		for line: String in r[key]:
			box.add_child(UI.label(line, UI.TEXT_POINTS, true))
		body.add_child(UI.plate(box))
