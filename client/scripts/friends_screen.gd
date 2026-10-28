class_name FriendsScreen
extends Control
## Friends and their week (§12.11, §17.6): the friends, the feed of their
## heists, an invite to share and a code to accept, and a challenge link to
## the player's own island. It draws the store; `SocialController` asks.

## Each outcome's pill on a feed card.
const GRADE_LOOK := {"clean": "green", "loud": "gold", "partial": "well", "foiled": "red"}

var controller: SocialController
var clock: Callable = func() -> int: return int(Time.get_unix_time_from_system() * 1000)
var body: VBoxContainer
var status_label: Label
var code_field: LineEdit
## The tab on show: "feed", "friends" or "invite".
var tab_shown := "feed"
## The kind of code last shown, so a code just made opens the Invite tab once.
var _shown_code := ""
## Whether the screen has chosen its first tab.
var _opened := false
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
	# A code just made opens the Invite tab, where it is shown; so does a
	# first visit with no friends yet, where the way to make one is.
	if coded and f["last"] != _shown_code or f["none"] and f["loaded"] and not _opened:
		tab_shown = "invite"
	_opened = _opened or f["loaded"]
	_shown_code = str(f["last"]) if coded else ""
	if f["none"]:
		body.add_child(ScreenParts.item("social", "invite", Strings.t("FRIENDS_NONE"), "", null, "card_lit"))
	else:
		body.add_child(_strip(f["friends"]))
	# The design's tabs under the faces: what friends did, or the friends
	# themselves with what can be done about each.
	body.add_child(ScreenParts.segmented([
		{"text": Strings.t("SCREEN_FEED"), "key": "feed", "on": tab_shown == "feed",
			"icon": "social/share"},
		{"text": Strings.t("KIT_TAB_FRIENDS"), "key": "friends", "on": tab_shown == "friends",
			"icon": "social/friends"},
		{"text": Strings.t("SCREEN_TAB_INVITE"), "key": "invite", "on": tab_shown == "invite",
			"icon": "social/invite"}],
		func(key: String) -> void:
			tab_shown = key
			_refresh()))
	_invite.visible = tab_shown == "invite"
	if tab_shown == "friends":
		_friends_tab(f)
	elif tab_shown == "invite":
		if coded:
			body.add_child(_code(f))
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
		# The design's feed card: the raider's portrait, the outcome's mark on
		# its corner; their name and the outcome's pill; what happened.
		var face := ScreenParts.face(str(item.get("raider", "")), 48.0)
		var holder := Control.new()
		holder.custom_minimum_size = face.custom_minimum_size
		holder.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
		holder.add_child(face)
		face.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		if grade != "":
			var mark := ScreenKit.icon("heistoutcomes", grade, 24.0)
			mark.position = face.custom_minimum_size - Vector2.ONE * UI.px(18)
			holder.add_child(mark)
		row.add_child(holder)
		var col := VBoxContainer.new()
		col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		col.add_theme_constant_override("separation", UI.px(2))
		var head := ScreenParts.flow(6.0)
		var who := ScreenKit.text(str(item.get("raider", "")), 16.0, "number", "parchment")
		head.add_child(who)
		if grade != "":
			var pill := ScreenParts.pill(Strings.term("GRADE", grade), GRADE_LOOK.get(grade, "well"), "", "", 13.0)
			pill.size_flags_vertical = Control.SIZE_SHRINK_CENTER
			head.add_child(pill)
		var when := SocialPresenter.ago(int(item.get("at", 0)), clock.call())
		if when != "":
			head.add_child(ScreenKit.text(when, 13.0, "words", "parchment", true))
		col.add_child(head)
		var words := ScreenKit.text(line, 14.0, "body", "parchment", false, true)
		words.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		col.add_child(words)
		row.add_child(col)
		body.add_child(ScreenKit.panel("parchment", row, 16.0, 10.0))
		i += 1


## Each friend with Remove, then the players blocked, each to unblock.
func _friends_tab(f: Dictionary) -> void:
	# The friends as rows of one card; Remove quiet at each row's end.
	var list := VBoxContainer.new()
	list.add_theme_constant_override("separation", 0)
	for x: Dictionary in f["friends"]:
		var remove := ScreenKit.button(Strings.t("FRIENDS_REMOVE"), controller.remove.bind(x["account"]), "ghost",
			Strings.t("FRIENDS_REMOVE_NAMED", x["name"]), 14.0)
		remove.add_theme_font_size_override("font_size", UI.text_px(13))
		remove.set_meta("points", 13.0)
		UI.fit(remove)
		if list.get_child_count() > 0:
			var line := ColorRect.new()
			line.color = Color(1, 1, 1, 0.08)
			line.custom_minimum_size.y = maxf(1.0, UI.px(1))
			line.mouse_filter = Control.MOUSE_FILTER_IGNORE
			list.add_child(line)
		list.add_child(_person(x["name"], remove))
	if list.get_child_count() > 0:
		body.add_child(ScreenKit.panel("card", list, 18.0, 4.0))
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
		var face := ScreenParts.face(str(x["name"]), 56.0)
		face.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		col.add_child(face)
		var n := ScreenKit.text(x["name"], 13.0, "words", "card")
		n.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		col.add_child(n)
		row.add_child(col)
	return row


## A friend's row of the card: their portrait and name, and what can be done.
func _person(name: String, right: Control) -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", UI.px(10))
	row.add_child(ScreenParts.face(name, 40.0))
	var n := ScreenKit.text(name, 16.0, "words", "card", false, true)
	n.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	n.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	row.add_child(n)
	right.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(right)
	var pad := MarginContainer.new()
	for side: String in ["left", "right", "top", "bottom"]:
		pad.add_theme_constant_override("margin_" + side, UI.px(8))
	pad.add_child(row)
	return pad


## A code just made, large on parchment, to read out or copy.
func _code(f: Dictionary) -> Control:
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", UI.px(2))
	var kind: String = f["last"]
	box.add_child(ScreenKit.text(f[kind], 13.0, "words", "parchment", true, true))
	var code := ScreenKit.text(Strings.t("SCREEN_CODE", str(f[kind + "_code"]).to_upper()), 30.0, "number", "parchment")
	code.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(code)
	return ScreenKit.panel("parchment", box, 16.0, 12.0)
