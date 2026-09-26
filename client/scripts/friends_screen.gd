class_name FriendsScreen
extends Control
## Friends and their week (§12.11, §17.6): the friends, the feed of their
## heists, an invite to share and a code to accept, and a challenge link to
## the player's own island. It draws the store; `SocialController` asks.

var controller: SocialController
var body: VBoxContainer
var status_label: Label
var code_field: LineEdit


func _ready() -> void:
	App.ready(self)
	controller = App.services.social_flow
	_build()
	App.services.store.changed.connect(_on_changed)
	_refresh()
	await controller.load_friends()


func _on_changed(slice: StringName) -> void:
	if slice == SocialState.FRIENDS and is_inside_tree():
		_refresh()


func _build() -> void:
	var column := UI.frame(self)
	column.add_child(UI.title(Strings.t("FRIENDS_TITLE")))
	status_label = UI.status("info", "")
	column.add_child(UI.plate(status_label))
	body = UI.scroll(column, true)
	var add := UI.row()
	code_field = UI.field(Strings.t("FRIENDS_CODE"))
	add.add_child(code_field)
	add.add_child(UI.button(Strings.t("FRIENDS_ACCEPT"), func() -> void: controller.accept(code_field.text)))
	column.add_child(add)
	var actions := UI.row(-1.0, true)
	actions.add_child(UI.button(Strings.t("FRIENDS_INVITE"), controller.make_invite, true))
	actions.add_child(UI.button(Strings.t("FRIENDS_CHALLENGE"), controller.make_challenge))
	actions.add_child(UI.button(Strings.t("COMMON_HOME"), func() -> void: App.services.router.go(&"home")))
	column.add_child(UI.narrow(actions))


func _refresh() -> void:
	var me := str(App.services.store.get_slice(AppState.SESSION)["account"])
	var f := SocialPresenter.friends(App.services.store.get_slice(SocialState.FRIENDS), me)
	# The latest outcome is the one shown: a new code is never hidden behind
	# an older message.
	if f["error"] != "":
		UI.set_status(status_label, "alarm", Errors.message("FRIENDS_FAILED", f["error"]))
	elif f["last"] == "accepted":
		UI.set_status(status_label, "success", f["accepted"])
	elif f["last"] in ["invite", "challenge"]:
		UI.set_status(status_label, "info", f[f["last"]])
	else:
		UI.set_status(status_label, "info", Strings.t("COMMON_LOADING") if f["busy"] else "")
	for c in body.get_children():
		c.queue_free()
	if f["none"]:
		body.add_child(UI.label(Strings.t("FRIENDS_NONE"), UI.TEXT_POINTS, true))
	for x: Dictionary in f["friends"]:
		var r := UI.row()
		r.add_child(UI.label(x["name"]))
		r.add_child(UI.button(Strings.t("FRIENDS_REMOVE"), controller.remove.bind(x["account"]), false, Color(),
			Strings.t("FRIENDS_REMOVE_NAMED", x["name"])))
		body.add_child(r)
	if not f["feed"].is_empty():
		body.add_child(UI.label(Strings.t("FRIENDS_FEED"), UI.TEXT_POINTS, true))
	for line: String in f["feed"]:
		body.add_child(UI.label(line, UI.TEXT_POINTS, true))
