class_name FriendsScreen
extends Control
## Friends and their week (§12.11, §17.6): the friends, the feed of their
## heists, an invite to share and a code to accept, and a challenge link to
## the player's own island. It draws the store; `SocialController` asks.

var controller: SocialController
var body: VBoxContainer
var status_label: Label
var code_field: LineEdit
## The tab on show: "feed" or "friends".
var tab_shown := "feed"
var _count: PanelContainer
var _invite: PanelContainer


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
	var column := ScreenKit.frame(self)
	_count = ScreenParts.pill("", "glass", "social", "friends", 15.0)
	_count.visible = false
	column.add_child(ScreenNav.header(Strings.t("FRIENDS_TITLE"), _count))
	status_label = UI.status("info", "")
	column.add_child(ScreenParts.status_plate(status_label))
	body = UI.scroll(column)
	var card := VBoxContainer.new()
	card.add_theme_constant_override("separation", UI.px(8))
	card.add_child(ScreenParts.section(Strings.t("SCREEN_FRIENDS_ADD")))
	# The code field beside its button, or above it where large text needs
	# the width (German, French and Portuguese run longest).
	var add: BoxContainer = VBoxContainer.new()
	if Settings.text_scale <= 125:
		add = HBoxContainer.new()
	add.add_theme_constant_override("separation", UI.px(8))
	code_field = UI.field(Strings.t("FRIENDS_CODE"))
	code_field.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	add.add_child(code_field)
	add.add_child(ScreenKit.button(Strings.t("FRIENDS_ACCEPT"), func() -> void: controller.accept(code_field.text),
		"gold"))
	card.add_child(add)
	var actions := UI.row(8.0, true)
	actions.add_child(ScreenKit.button(Strings.t("FRIENDS_INVITE"), controller.make_invite, "gold"))
	actions.add_child(ScreenKit.button(Strings.t("FRIENDS_CHALLENGE"), controller.make_challenge, "leather"))
	card.add_child(actions)
	_invite = ScreenKit.panel("card", card, 18.0, 12.0)
	body.add_child(_invite)
	column.add_child(ScreenNav.bar("friends"))


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
	ScreenParts.show_status(status_label)
	var coded: bool = f["last"] in ["invite", "challenge"] and str(f[f["last"] + "_code"]) != ""
	# A code just made is shown large below, not twice.
	if coded:
		(status_label.get_parent() as Control).visible = false
	ScreenParts.set_pill(_count, str((f["friends"] as Array).size()) if not f["none"] else "")
	for c in body.get_children():
		if c != _invite:
			c.queue_free()
	if coded:
		body.add_child(_code(f))
	if f["none"]:
		body.add_child(ScreenParts.item("social", "invite", Strings.t("FRIENDS_NONE"), "", null, "card_lit"))
	else:
		body.add_child(_strip(f["friends"]))
	# The design's tabs under the faces: what friends did, or the friends
	# themselves with what can be done about each.
	body.add_child(ScreenParts.segmented([
		{"text": Strings.t("SCREEN_FEED"), "key": "feed", "on": tab_shown == "feed"},
		{"text": Strings.t("KIT_TAB_FRIENDS"), "key": "friends", "on": tab_shown == "friends"}],
		func(key: String) -> void:
			tab_shown = key
			_refresh()))
	if tab_shown == "friends":
		_friends_tab(f)
	else:
		_feed_tab(f)
	body.move_child(_invite, body.get_child_count() - 1)


## What friends did this week, each as the design's cream card with its
## outcome's mark on a disc.
func _feed_tab(f: Dictionary) -> void:
	# Nothing done yet this week: the friends themselves.
	if f["feed"].is_empty():
		_friends_tab(f)
		return
	if not f["feed"].is_empty():
		body.add_child(ScreenParts.section(Strings.t("FRIENDS_FEED")))
	var i := 0
	for line: String in f["feed"]:
		var item: Dictionary = f["feed_items"][i] if i < (f["feed_items"] as Array).size() else {}
		var grade := str(item.get("grade", ""))
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", UI.px(10))
		var mark := ScreenKit.icon("heistoutcomes" if grade != "" else "social", grade if grade != "" else "presetchat",
			30.0)
		var disc := ScreenKit.panel("well", mark, -1.0, 6.0)
		disc.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		row.add_child(disc)
		var words := ScreenKit.text(line, 15.0, "words", "parchment", false, true)
		words.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		words.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		row.add_child(words)
		body.add_child(ScreenKit.panel("parchment", row, 16.0, 10.0))
		i += 1


## Each friend with Remove, then the players blocked, each to unblock.
func _friends_tab(f: Dictionary) -> void:
	for x: Dictionary in f["friends"]:
		var remove := ScreenKit.button(Strings.t("FRIENDS_REMOVE"), controller.remove.bind(x["account"]), "leather",
			Strings.t("FRIENDS_REMOVE_NAMED", x["name"]), 14.0)
		body.add_child(_person(x["name"], remove))
	if not f["blocked"].is_empty():
		body.add_child(ScreenParts.section(Strings.t("FRIENDS_BLOCKED")))
	for x: Dictionary in f["blocked"]:
		var unblock := ScreenKit.button(Strings.t("FRIENDS_UNBLOCK"), controller.unblock.bind(x["account"]), "leather",
			Strings.t("FRIENDS_UNBLOCK_NAMED", x["name"]), 14.0)
		body.add_child(ScreenParts.item("social", "block", x["name"], "", unblock))


## The friends at the top as the design's strip: a round portrait each, the
## Keeper's initials on it, and the name beneath.
func _strip(friends: Array) -> Control:
	var row := ScreenParts.flow(10.0)
	for x: Dictionary in friends:
		var col := VBoxContainer.new()
		col.add_theme_constant_override("separation", UI.px(2))
		var face := _face(str(x["name"]), 56.0)
		face.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		col.add_child(face)
		var n := ScreenKit.text(x["name"], 13.0, "words", "card")
		n.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		col.add_child(n)
		row.add_child(col)
	return row


## A Keeper's portrait: a round plate with the last word of their name.
static func _face(name: String, points: float) -> Control:
	var initials := ScreenKit.text(name.get_slice(" ", name.get_slice_count(" ") - 1).left(2), points * 0.36,
		"number", "card_lit")
	initials.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	initials.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	var p := ScreenKit.panel("card_lit", initials, -1.0, 2.0)
	p.custom_minimum_size = Vector2.ONE * UI.px(points)
	return p


## A friend's row: their portrait and name, and what can be done.
func _person(name: String, right: Control) -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", UI.px(10))
	row.add_child(_face(name, 40.0))
	var n := ScreenKit.text(name, 16.0, "words", "card", false, true)
	n.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	n.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	row.add_child(n)
	row.add_child(right)
	return ScreenKit.panel("card", row, 16.0, 8.0)


## A code just made, large on parchment, to read out or copy.
func _code(f: Dictionary) -> Control:
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", UI.px(2))
	var kind: String = f["last"]
	box.add_child(ScreenKit.text(f[kind], 13.0, "words", "parchment", true, true))
	var code := ScreenKit.text(str(f[kind + "_code"]).to_upper(), 30.0, "number", "parchment")
	code.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(code)
	return ScreenKit.panel("parchment", box, 16.0, 12.0)
