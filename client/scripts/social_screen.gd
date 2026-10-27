class_name SocialScreen
extends Control
## The league and the player's groups (§17.1, §17.7, §18.1): this season's
## league, division and Renown; the constellation, its members and their
## roles, or founding one from the word lists; the crew, its invite, or
## starting and joining one. It draws the store; `SocialController` asks.

var controller: SocialController
var body: VBoxContainer
var status_label: Label
var invite_field: LineEdit
## Joining a crew by its code: outside the list the screen draws again, so a
## code being typed survives a refresh.
var join_row: Control
## The name a constellation would be founded with: an adjective and a noun
## from the word lists, by index (D63).
var adjective := 0
var noun := 0


func _ready() -> void:
	App.ready(self)
	controller = App.services.social_flow
	_build()
	App.services.store.changed.connect(_on_changed)
	_refresh()
	await controller.load_league()
	await controller.load_groups()
	await controller.load_words()


func _on_changed(slice: StringName) -> void:
	if slice in [SocialState.LEAGUE, SocialState.GROUPS] and is_inside_tree():
		_refresh()


func _build() -> void:
	var column := ScreenKit.frame(self)
	column.add_child(ScreenNav.header(Strings.t("SOCIAL_TITLE")))
	status_label = UI.status("info", "")
	column.add_child(ScreenParts.status_plate(status_label))
	body = UI.scroll(column)
	# The code field beside its button, or above it where large text needs
	# the width.
	var join: BoxContainer = VBoxContainer.new()
	if Settings.text_scale <= 125:
		join = HBoxContainer.new()
	join.add_theme_constant_override("separation", UI.px(8))
	invite_field = UI.field(Strings.t("SOCIAL_CREW_CODE"))
	invite_field.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	join.add_child(invite_field)
	join.add_child(ScreenKit.button(Strings.t("SOCIAL_JOIN_CREW"), func() -> void: controller.join_crew(invite_field.text),
		"gold"))
	join_row = ScreenKit.panel("card", join, 18.0, 8.0)
	column.add_child(join_row)
	var friends := ScreenKit.button(Strings.t("SOCIAL_FRIENDS"), func() -> void: App.services.router.go(&"friends"),
		"leather")
	column.add_child(ScreenNav.dock(&"home", [friends]))


func _me() -> String:
	return str(App.services.store.get_slice(AppState.SESSION)["account"])


func _refresh() -> void:
	var l := SocialPresenter.league(App.services.store.get_slice(SocialState.LEAGUE))
	var gs: Dictionary = App.services.store.get_slice(SocialState.GROUPS)
	var g := SocialPresenter.groups(gs, _me())
	var error: String = l["error"] if l["error"] != "" else g["error"]
	UI.set_status(status_label, "alarm" if error != "" else "info",
		Errors.message("SOCIAL_FAILED", error) if error != "" else ("" if l["ready"] else Strings.t("COMMON_LOADING")))
	ScreenParts.show_status(status_label)
	for c in body.get_children():
		c.queue_free()
	if l["ready"]:
		body.add_child(_league(l))
	# Until the server has said, nothing claims the player is in no group.
	join_row.visible = g["known"] and not g["in_crew"]
	if not g["known"]:
		if error == "" and l["ready"]:
			body.add_child(ScreenKit.text(Strings.t("COMMON_LOADING"), 15.0, "words", "card", true))
		return
	body.add_child(_constellation(g, gs))
	body.add_child(_crew(g))


## This season's league: its crest, the place, Renown and the way on.
func _league(l: Dictionary) -> Control:
	var v: Dictionary = App.services.store.get_slice(SocialState.LEAGUE).get("view", {})
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", UI.px(12))
	row.add_child(ScreenKit.icon("leagues", str(v.get("league", "dust")), 64.0))
	var words := VBoxContainer.new()
	words.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	words.alignment = BoxContainer.ALIGNMENT_CENTER
	words.add_child(ScreenKit.text(l["place"], 20.0, "name", "card_lit", false, true))
	words.add_child(ScreenKit.text(l["renown"], 15.0, "words", "card_lit", false, true))
	words.add_child(ScreenKit.text(l["next"], 13.0, "words", "card_lit", true, true))
	row.add_child(words)
	return ScreenKit.panel("card_lit", row, 18.0, 12.0)


## The constellation: its name and members by role, or founding one from
## the word lists.
func _constellation(g: Dictionary, gs: Dictionary) -> Control:
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", UI.px(6))
	box.add_child(_heading("constellation", "constellation", g["constellation"]))
	for m: String in g["members"]:
		box.add_child(_member(m))
	var cons := UI.row(6.0)
	if g["in_constellation"]:
		cons.add_child(ScreenKit.button(Strings.t("SOCIAL_LEAVE_CONSTELLATION"), controller.leave, "leather", "", 14.0))
	elif not (gs["words"] as Dictionary).is_empty():
		var words: Dictionary = gs["words"]
		var adjectives: Array = words.get("adjectives", [])
		var nouns: Array = words.get("nouns", [])
		if not adjectives.is_empty() and not nouns.is_empty():
			var name := SocialPresenter.word_name(words, adjective, noun)
			var said := ScreenKit.text(Strings.t("SOCIAL_NAME", name), 17.0, "words", "parchment", false, true)
			box.add_child(ScreenKit.panel("parchment", said, 14.0, 10.0))
			cons.add_child(ScreenKit.button(Strings.t("SOCIAL_OTHER_ADJECTIVE"), func() -> void:
				adjective = (adjective + 1) % adjectives.size()
				_refresh(), "card", "", 14.0))
			cons.add_child(ScreenKit.button(Strings.t("SOCIAL_OTHER_NOUN"), func() -> void:
				noun = (noun + 1) % nouns.size()
				_refresh(), "card", "", 14.0))
			cons.add_child(ScreenKit.button(Strings.t("SOCIAL_FOUND"), func() -> void: controller.found(adjective, noun),
				"gold", Strings.t("SOCIAL_FOUND_NAMED", name), 14.0))
	box.add_child(cons)
	return ScreenKit.panel("card", box, 18.0, 12.0)


## The crew: its members, its invite, and starting or leaving one.
func _crew(g: Dictionary) -> Control:
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", UI.px(6))
	box.add_child(_heading("constellation", "crew", g["crew"]))
	for m: String in g["crew_members"]:
		box.add_child(_member(m))
	if g["crew_invite"] != "":
		var code := ScreenKit.text(Strings.t("SOCIAL_CREW_INVITE", g["crew_invite"]), 17.0, "words", "parchment", false,
			true)
		box.add_child(ScreenKit.panel("parchment", code, 14.0, 10.0))
	var crew := UI.row(6.0)
	if g["in_crew"]:
		crew.add_child(ScreenKit.button(Strings.t("SOCIAL_LEAVE_CREW"), controller.leave_crew, "leather", "", 14.0))
	else:
		crew.add_child(ScreenKit.button(Strings.t("SOCIAL_START_CREW"), controller.start_crew, "gold", "", 14.0))
	box.add_child(crew)
	return ScreenKit.panel("card", box, 18.0, 12.0)


## A member as Friends shows one: their round portrait, then their name
## and role.
func _member(words: String) -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", UI.px(8))
	row.add_child(ScreenParts.face(words.get_slice(",", 0), 36.0))
	var l := ScreenKit.text(words, 15.0, "words", "card", false, true)
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	row.add_child(l)
	return row


func _heading(group: String, icon: String, words: String) -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", UI.px(8))
	row.add_child(ScreenKit.icon(group, icon, 34.0))
	var t := ScreenKit.text(words, 17.0, "words", "card", false, true)
	t.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	t.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	row.add_child(t)
	return row
