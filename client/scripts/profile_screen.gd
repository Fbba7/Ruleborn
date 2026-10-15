class_name ProfileScreen
extends Control
## The Profile and stats (§23.2, "Your record"): Renown and league over time,
## heists by outcome, defences held and leaked, the ten records, §18.5's
## badges and the titles mastery gives, the battle log with its replays, and
## §20.2's visibility switch, locked private for 13 to 15.

var controller: ProfileController
var body: VBoxContainer
var header_label: Label
var status_label: Label


func _ready() -> void:
	App.ready(self)
	controller = App.services.profile_flow
	_build()
	App.services.store.changed.connect(_on_changed)
	_refresh()
	await controller.load_profile()


func _on_changed(slice: StringName) -> void:
	if slice == ProfileState.PROFILE and is_inside_tree():
		_refresh()


func _build() -> void:
	var column := UI.frame(self)
	column.add_child(UI.title(Strings.t("PROFILE_TITLE")))
	header_label = UI.label("", UI.TEXT_POINTS, true)
	column.add_child(UI.plate(header_label))
	status_label = UI.status("info", "")
	column.add_child(UI.plate(status_label))
	body = UI.scroll(column)
	var actions := UI.row(-1.0, true)
	actions.add_child(UI.button(Strings.t("COMMON_HOME"), func() -> void: App.services.router.go(&"home"), true))
	column.add_child(UI.narrow(actions))


func _refresh() -> void:
	if not is_inside_tree():
		return
	var p := ProfilePresenter.screen(App.services.store.get_slice(ProfileState.PROFILE))
	if p["error"] != "":
		UI.set_status(status_label, "alarm", p["error"])
	elif p["busy"] != "" or not p["ready"]:
		UI.set_status(status_label, "info", Strings.t("COMMON_LOADING"))
	else:
		UI.set_status(status_label, "info", "")
	header_label.text = p.get("header", "")
	for child in body.get_children():
		body.remove_child(child)
		child.queue_free()
	if not p["ready"]:
		return
	var busy: bool = p["busy"] != ""
	body.add_child(_section("PROFILE_RENOWN", p["renown"]))
	var outcomes: Array[String] = [str(p["heists"]), str(p["defences"])]
	body.add_child(_section("PROFILE_RECORD_TITLE", outcomes))
	body.add_child(_section("PROFILE_RECORDS", p["records"]))
	body.add_child(_section("PROFILE_BADGES", p["badges"]))
	body.add_child(_section("PROFILE_TITLES_TITLE", p["titles"]))
	var battles := VBoxContainer.new()
	battles.add_child(UI.label(Strings.t("PROFILE_LOG_TITLE"), UI.TEXT_POINTS, true))
	for e: Dictionary in p["log"]:
		var line := UI.label(e["text"], UI.TEXT_POINTS, true)
		line.set_meta("heist", e["heist"])
		battles.add_child(line)
		if not (e["watch"] as Dictionary).is_empty():
			battles.add_child(RosterScreen.offer(e["watch"], busy, App.services.defences_flow.watch.bind(e["raid"])))
	body.add_child(UI.plate(battles))
	var share: Dictionary = p["share"]
	var box := VBoxContainer.new()
	box.add_child(UI.label(share.get("locked", share.get("state", "")), UI.TEXT_POINTS, true))
	if share.has("button"):
		box.add_child(RosterScreen.offer(share["button"], busy, controller.share.bind(bool(share["button"]["on"]))))
	body.add_child(UI.plate(box))


func _section(title: String, lines: Array[String]) -> Control:
	var box := VBoxContainer.new()
	box.add_child(UI.label(Strings.t(title), UI.TEXT_POINTS, true))
	for line in lines:
		box.add_child(UI.label(line, UI.TEXT_POINTS, true))
	return UI.plate(box)
