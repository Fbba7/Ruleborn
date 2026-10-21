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
	var column := ScreenKit.frame(self)
	column.add_child(ScreenNav.header(Strings.t("SHARE_TITLE")))
	status_label = UI.status("info", "")
	column.add_child(ScreenParts.status_plate(status_label))
	body = UI.scroll(column)
	column.add_child(ScreenNav.dock(&"home"))


func _refresh() -> void:
	if not is_inside_tree():
		return
	var s := SharePresenter.screen(App.services.store.get_slice(ShareState.SHARE), App.services.age.band())
	if s["error"] != "":
		UI.set_status(status_label, "alarm", s["error"])
	else:
		UI.set_status(status_label, "success" if str(s.get("copied", "")) != "" else "info", str(s.get("copied", "")))
	ScreenParts.show_status(status_label)
	for child in body.get_children():
		body.remove_child(child)
		child.queue_free()
	var link := VBoxContainer.new()
	link.add_theme_constant_override("separation", UI.px(8))
	link.add_child(_title("screens", "realm", Strings.t("SCREEN_SHARE_CHALLENGE")))
	var text := ScreenKit.text(s["link"], 15.0, "words", "card_lit", false, true)
	text.set_meta("link", true)
	link.add_child(ScreenKit.panel("parchment", text, 14.0, 10.0))
	text.add_theme_color_override("font_color", ScreenKit.ink("parchment"))
	var row := UI.row(8.0)
	row.add_child(_offer(s["make"], s["busy"], controller.make_link, "gold"))
	if not (s["copy"] as Dictionary).is_empty():
		row.add_child(_offer(s["copy"], s["busy"], controller.copy, "leather"))
	link.add_child(row)
	body.add_child(ScreenKit.panel("card_lit", link, 18.0, 12.0))
	var invite := VBoxContainer.new()
	invite.add_theme_constant_override("separation", UI.px(8))
	invite.set_meta("section", "invite")
	invite.add_child(_title("social", "invite", Strings.t("SCREEN_SHARE_INVITE")))
	var gift := HBoxContainer.new()
	gift.add_theme_constant_override("separation", UI.px(10))
	gift.add_child(ScreenKit.icon("shopcosmetics", "gift", 44.0))
	var words := ScreenKit.text(s["gift"], 15.0, "words", "card", false, true)
	words.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	gift.add_child(words)
	invite.add_child(gift)
	if s["invitation"] != "":
		var said := ScreenKit.text(s["invitation"], 15.0, "words", "parchment", false, true)
		invite.add_child(ScreenKit.panel("parchment", said, 14.0, 10.0))
	var row2 := UI.row(8.0)
	row2.add_child(_offer(s["invite"], s["busy"], controller.make_invite, "gold"))
	if not (s["copy_invite"] as Dictionary).is_empty():
		row2.add_child(_offer(s["copy_invite"], s["busy"], controller.copy.bind("invite"), "leather"))
	invite.add_child(row2)
	body.add_child(ScreenKit.panel("card", invite, 18.0, 12.0))
	var limits := VBoxContainer.new()
	limits.add_theme_constant_override("separation", UI.px(6))
	limits.add_child(_title("settingsandwellbeing", "parentcontrols", Strings.t("SHARE_LIMITS")))
	for line: String in s["limits"]:
		var r := HBoxContainer.new()
		r.add_theme_constant_override("separation", UI.px(8))
		r.add_child(ScreenKit.icon("generalui", "info", 22.0))
		var l := ScreenKit.text(line, 15.0, "words", "card", true, true)
		l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		r.add_child(l)
		limits.add_child(r)
	body.add_child(ScreenKit.panel("card", limits, 18.0, 12.0))


## A card's heading: its icon and its name in Marcellus.
func _title(group: String, icon: String, words: String) -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", UI.px(8))
	row.add_child(ScreenKit.icon(group, icon, 34.0))
	var t := ScreenKit.text(words, 20.0, "name", "card", false, true)
	t.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	t.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	row.add_child(t)
	return row


static func _offer(o: Dictionary, busy: bool, pressed: Callable, material: String) -> Button:
	var b := ScreenKit.button(o["action"], pressed, material, o["spoken"], 14.0)
	b.disabled = busy or not o["can"]
	b.set_meta("key", o["key"])
	b.set_meta("item", o["item"])
	return b
