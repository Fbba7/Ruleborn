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
	var column := UI.frame(self)
	column.add_child(UI.title(Strings.t("SOCIAL_TITLE")))
	status_label = UI.status("info", "")
	column.add_child(UI.plate(status_label))
	body = UI.scroll(column, true)
	var join := UI.row()
	invite_field = UI.field(Strings.t("SOCIAL_CREW_CODE"))
	join.add_child(invite_field)
	join.add_child(UI.button(Strings.t("SOCIAL_JOIN_CREW"), func() -> void: controller.join_crew(invite_field.text)))
	join_row = join
	column.add_child(join)
	var actions := UI.row(-1.0, true)
	actions.add_child(UI.button(Strings.t("SOCIAL_FRIENDS"), func() -> void: App.services.router.go(&"friends"), true))
	actions.add_child(UI.button(Strings.t("COMMON_HOME"), func() -> void: App.services.router.go(&"home")))
	column.add_child(UI.narrow(actions))


func _me() -> String:
	return str(App.services.store.get_slice(AppState.SESSION)["account"])


func _refresh() -> void:
	var l := SocialPresenter.league(App.services.store.get_slice(SocialState.LEAGUE))
	var gs: Dictionary = App.services.store.get_slice(SocialState.GROUPS)
	var g := SocialPresenter.groups(gs, _me())
	var error: String = l["error"] if l["error"] != "" else g["error"]
	UI.set_status(status_label, "alarm" if error != "" else "info",
		Errors.message("SOCIAL_FAILED", error) if error != "" else ("" if l["ready"] else Strings.t("COMMON_LOADING")))
	for c in body.get_children():
		c.queue_free()
	if l["ready"]:
		for key: String in ["place", "renown", "next"]:
			body.add_child(UI.label(l[key], UI.TEXT_POINTS, true))
	# Until the server has said, nothing claims the player is in no group.
	join_row.visible = g["known"] and not g["in_crew"]
	if not g["known"]:
		if error == "" and l["ready"]:
			body.add_child(UI.label(Strings.t("COMMON_LOADING"), UI.TEXT_POINTS, true))
		return
	body.add_child(UI.label(g["constellation"], UI.TEXT_POINTS, true))
	for m: String in g["members"]:
		body.add_child(UI.label(m, UI.TEXT_POINTS, true))
	var cons := UI.row()
	if g["in_constellation"]:
		cons.add_child(UI.button(Strings.t("SOCIAL_LEAVE_CONSTELLATION"), controller.leave))
	elif not (gs["words"] as Dictionary).is_empty():
		var words: Dictionary = gs["words"]
		var adjectives: Array = words.get("adjectives", [])
		var nouns: Array = words.get("nouns", [])
		if not adjectives.is_empty() and not nouns.is_empty():
			var name := SocialPresenter.word_name(words, adjective, noun)
			body.add_child(UI.label(Strings.t("SOCIAL_NAME", name), UI.TEXT_POINTS, true))
			cons.add_child(UI.button(Strings.t("SOCIAL_OTHER_ADJECTIVE"), func() -> void:
				adjective = (adjective + 1) % adjectives.size()
				_refresh()))
			cons.add_child(UI.button(Strings.t("SOCIAL_OTHER_NOUN"), func() -> void:
				noun = (noun + 1) % nouns.size()
				_refresh()))
			cons.add_child(UI.button(Strings.t("SOCIAL_FOUND"), func() -> void: controller.found(adjective, noun), true,
				Color(), Strings.t("SOCIAL_FOUND_NAMED", name)))
	body.add_child(cons)
	body.add_child(UI.label(g["crew"], UI.TEXT_POINTS, true))
	for m: String in g["crew_members"]:
		body.add_child(UI.label(m, UI.TEXT_POINTS, true))
	if g["crew_invite"] != "":
		body.add_child(UI.label(Strings.t("SOCIAL_CREW_INVITE", g["crew_invite"]), UI.TEXT_POINTS, true))
	var crew := UI.row()
	if g["in_crew"]:
		crew.add_child(UI.button(Strings.t("SOCIAL_LEAVE_CREW"), controller.leave_crew))
	else:
		crew.add_child(UI.button(Strings.t("SOCIAL_START_CREW"), controller.start_crew))
	body.add_child(crew)

