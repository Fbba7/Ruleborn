class_name ShareScreen
extends Control
## The share sheet (§23.2, "Share a moment or a challenge"): a challenge link
## to the player's island, its code to copy, a personal invite with its gift
## (§17.6), and §20.7's limits for the player's age band. Nothing here posts to the Beacon or grades a moment.

var controller: ShareController
var body: VBoxContainer
var status_label: Label


func _ready() -> void:
	App.ready(self)
	controller = App.services.share_flow
	_build()
	App.services.store.changed.connect(_on_changed)
	_refresh()


func _on_changed(slice: StringName) -> void:
	if slice == ShareState.SHARE and is_inside_tree():
		_refresh()


func _build() -> void:
	var column := UI.frame(self)
	column.add_child(UI.title(Strings.t("SHARE_TITLE")))
	status_label = UI.status("info", "")
	column.add_child(UI.plate(status_label))
	body = UI.scroll(column)
	var actions := UI.row(-1.0, true)
	actions.add_child(UI.button(Strings.t("COMMON_HOME"), func() -> void: App.services.router.go(&"home"), true))
	column.add_child(UI.narrow(actions))


func _refresh() -> void:
	if not is_inside_tree():
		return
	var s := SharePresenter.screen(App.services.store.get_slice(ShareState.SHARE), App.services.age.band())
	if s["error"] != "":
		UI.set_status(status_label, "alarm", s["error"])
	else:
		UI.set_status(status_label, "success" if str(s.get("copied", "")) != "" else "info", str(s.get("copied", "")))
	for child in body.get_children():
		body.remove_child(child)
		child.queue_free()
	var link := VBoxContainer.new()
	var text := UI.label(s["link"], UI.TEXT_POINTS, true)
	text.set_meta("link", true)
	link.add_child(text)
	link.add_child(RosterScreen.offer(s["make"], s["busy"], controller.make_link))
	if not (s["copy"] as Dictionary).is_empty():
		link.add_child(RosterScreen.offer(s["copy"], s["busy"], controller.copy))
	body.add_child(UI.plate(link))
	var invite := VBoxContainer.new()
	invite.set_meta("section", "invite")
	invite.add_child(UI.label(s["gift"], UI.TEXT_POINTS, true))
	if s["invitation"] != "":
		invite.add_child(UI.label(s["invitation"], UI.TEXT_POINTS, true))
	invite.add_child(RosterScreen.offer(s["invite"], s["busy"], controller.make_invite))
	if not (s["copy_invite"] as Dictionary).is_empty():
		invite.add_child(RosterScreen.offer(s["copy_invite"], s["busy"], controller.copy.bind("invite")))
	body.add_child(UI.plate(invite))
	var limits := VBoxContainer.new()
	limits.add_child(UI.label(Strings.t("SHARE_LIMITS"), UI.TEXT_POINTS, true))
	for line: String in s["limits"]:
		limits.add_child(UI.label(line, UI.TEXT_POINTS, true))
	body.add_child(UI.plate(limits))
