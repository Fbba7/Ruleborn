class_name WorkshopScreen
extends Control
## The Island Workshop (§18.6, §18.7, §20.7): the top, new and featured
## lists, and the player's own islands with their creator level; each island
## to play, report or remix, and the player's own to withdraw. Opened from a
## cleared rehearsal it offers to publish that island, named from the word
## lists; opened from a play's result it offers to rate the island played. A
## player aged 13 to 15 is shown the featured list only (§20.7). It draws the
## store; Services' `workshop_flow` asks, so leaving mid-call loses nothing.

const ASPECTS := ["fun", "cleverness", "fairness"]

var controller: WorkshopController
var body: VBoxContainer
var status_label: Label
## What the screen was opened for: publishing the rehearsal, rating the play.
var publish_open := false
var rate_open := false
## The name being made for the island to publish: indices into the lists.
var adjective := 0
var noun := 0
## The scores for the island played, 1 to 5 each.
var scores := {"fun": 3, "cleverness": 3, "fairness": 3}
## The report reason chosen for each island, by id.
var reasons := {}
## The island whose Remix was tapped once: a second tap replaces the player's
## own island in the builder with it.
var confirm_remix := ""


func _ready() -> void:
	App.ready(self)
	controller = App.services.workshop_flow
	var params: Dictionary = App.services.store.get_slice(AppState.ROUTE)["params"]
	publish_open = bool(params.get("publish", false))
	rate_open = bool(params.get("rate", false))
	_build()
	App.services.store.changed.connect(_on_changed)
	_refresh()
	# §20.11: the terms first, so the gate shows before the first refusal.
	await controller.load_terms()
	if publish_open:
		await controller.load_words()
	await controller.show_list("mine" if publish_open else "top")


func _on_changed(slice: StringName) -> void:
	if slice == WorkshopState.WORKSHOP and is_inside_tree():
		_refresh()


func _build() -> void:
	var column := UI.frame(self)
	column.add_child(UI.title(Strings.t("WORKSHOP_TITLE")))
	status_label = UI.status("info", "")
	column.add_child(UI.plate(status_label))
	body = UI.scroll(column)
	var actions := UI.row(-1.0, true)
	actions.add_child(UI.button(Strings.t("WORKSHOP_BUILD"), func() -> void: App.services.router.go(&"builder")))
	actions.add_child(UI.button(Strings.t("COMMON_HOME"), func() -> void: App.services.router.go(&"home"), true))
	column.add_child(UI.narrow(actions))


## Built again after each change, keeping which control had focus, so a
## player on a screen reader or a keyboard is not sent back to the top by a
## tap or an answer (as the settings screen does).
func _refresh() -> void:
	var focused := get_viewport().gui_get_focus_owner() if is_inside_tree() else null
	var focus_key := str(focused.get_meta("key", "")) if focused != null else ""
	var slice: Dictionary = App.services.store.get_slice(WorkshopState.WORKSHOP)
	var w := WorkshopPresenter.screen(slice, str(App.services.store.get_slice(AppState.SESSION)["account"]))
	if w["error"] != "":
		UI.set_status(status_label, "alarm", Errors.message("WORKSHOP_FAILED", w["error"]))
	elif w["said"] != "":
		UI.set_status(status_label, "success", w["said"])
	else:
		UI.set_status(status_label, "info", Strings.t("COMMON_LOADING") if w["busy"] else w["title"])
	for c in body.get_children():
		body.remove_child(c)
		c.queue_free()
	# The lists head the scrolled body, so at large text they never crowd the
	# fixed rows into the corners (§20.8, §21.1).
	body.add_child(_tabs(w["tabs"], w["list"]))
	var terms := WorkshopPresenter.terms(slice)
	if terms["show"]:
		body.add_child(_terms_panel(terms, w["busy"]))
	if publish_open:
		_publish_panel(slice, w["busy"])
	if rate_open and str(slice["played"].get("id", "")) != "":
		_rating_panel(slice, w["busy"])
	if w["ladder"] != "":
		body.add_child(UI.plate(UI.label(w["ladder"], UI.TEXT_POINTS, true)))
	if w["empty"]:
		body.add_child(UI.plate(UI.label(Strings.t("WORKSHOP_EMPTY_" + str(w["list"]).to_upper()),
			UI.TEXT_POINTS, true)))
	for item: Dictionary in w["items"]:
		body.add_child(_card(item, w["busy"]))
	if focus_key != "":
		for b: Button in find_children("*", "Button", true, false):
			if b.get_meta("key", "") == focus_key and b.is_visible_in_tree():
				b.grab_focus.call_deferred()
				break


## The lists the player may open. The list on show is marked in the
## button's words and border, and said aloud as shown — never by disabling
## it, which would read as unavailable.
func _tabs(names: Array[String], on_show: String) -> HFlowContainer:
	var row := UI.row()
	for list: String in names:
		var chosen := list == on_show
		var b := UI.button(("▸" if chosen else "") + Strings.t("WORKSHOP_TAB_" + list.to_upper()),
			controller.show_list.bind(list), false, Color(),
			Strings.t("WORKSHOP_TAB_SHOWN" if chosen else "WORKSHOP_TAB_SHOW",
				Strings.t("WORKSHOP_LIST_" + list.to_upper())))
		UI.set_outline(b, 3 if chosen else 1)
		b.set_meta("key", "tab:" + list)
		row.add_child(b)
	return row


func _card(item: Dictionary, busy: bool) -> Control:
	var box := VBoxContainer.new()
	box.add_child(UI.label(item["title"], UI.TEXT_POINTS, true))
	for key: String in ["by", "featured", "remix", "stats", "ratings", "withdrawn", "removed"]:
		if item[key] != "":
			box.add_child(UI.label(item[key], UI.TEXT_POINTS, true))
	var r := UI.row()
	var name: String = item["name"]
	var id: String = item["id"]
	if item["mine"]:
		if item["listed"]:
			r.add_child(_act("withdraw:" + id, Strings.t("WORKSHOP_WITHDRAW"), controller.withdraw.bind(id), busy,
				Strings.t("WORKSHOP_WITHDRAW_NAMED", name)))
	elif item["listed"]:
		r.add_child(_act("play:" + id, Strings.t("WORKSHOP_PLAY"), _play.bind(id), busy,
			Strings.t("WORKSHOP_PLAY_NAMED", name), true))
		var reason: String = reasons.get(id, WorkshopState.REPORT_REASONS[0])
		var why := Strings.term("REPORT", reason)
		r.add_child(_act("reason:" + id, Strings.t("WORKSHOP_REASON", why), _next_reason.bind(id), false,
			Strings.t("WORKSHOP_REASON_NAMED", [name, why])))
		r.add_child(_act("report:" + id, Strings.t("WORKSHOP_REPORT"), controller.report.bind(id, reason), busy,
			Strings.t("WORKSHOP_REPORT_NAMED", [name, why])))
	if item["listed"] and item["creator"] != "":
		r.add_child(_act("block:" + id, Strings.t("WORKSHOP_BLOCK"), controller.block.bind(item["creator"]), busy,
			Strings.t("WORKSHOP_BLOCK_NAMED", [item["by"], name])))
	if item["listed"]:
		var confirming := confirm_remix == id
		r.add_child(_act("remix:" + id, Strings.t("WORKSHOP_REMIX_CONFIRM" if confirming else "WORKSHOP_REMIX"),
			_remix.bind(id), busy, Strings.t("WORKSHOP_REMIX_CONFIRM_NAMED" if confirming else "WORKSHOP_REMIX_NAMED",
				name)))
	if r.get_child_count() > 0:
		box.add_child(r)
	return UI.plate(box)


## §20.11's gate: the terms to read, on the game's own server, and to accept
## before publishing, playing, rating or remixing.
func _terms_panel(terms: Dictionary, busy: bool) -> Control:
	var box := VBoxContainer.new()
	box.add_child(UI.label(terms["text"], UI.TEXT_POINTS, true))
	var r := UI.row()
	r.add_child(_act("terms:read", Strings.t("WORKSHOP_TERMS_READ"), _read_terms.bind(str(terms["url"])), false,
		Strings.t("WORKSHOP_TERMS_READ")))
	r.add_child(_act("terms:accept", Strings.t("WORKSHOP_TERMS_ACCEPT"), controller.accept_terms, busy,
		Strings.t("WORKSHOP_TERMS_ACCEPT"), true))
	box.add_child(r)
	return UI.plate(box)


func _read_terms(path: String) -> void:
	OS.shell_open(App.services.api.base + path)


## A control, named by `key` so focus comes back to it after a refresh.
func _act(key: String, text: String, pressed: Callable, busy: bool, spoken: String, main := false) -> Button:
	var b := UI.button(text, pressed, main, Color(), spoken)
	b.disabled = busy
	b.set_meta("key", key)
	return b


## §18.6: the rehearsal just cleared, published under a name from the lists.
func _publish_panel(slice: Dictionary, busy: bool) -> void:
	var heist: Dictionary = App.services.store.get_slice(AppState.HEIST)
	var p := WorkshopPresenter.publishing(heist, slice, adjective, noun)
	if not p["can"]:
		return
	var box := VBoxContainer.new()
	box.add_child(UI.label(Strings.t("WORKSHOP_PUBLISH_TITLE"), UI.TEXT_POINTS, true))
	if p["remix"] != "":
		box.add_child(UI.label(p["remix"], UI.TEXT_POINTS, true))
	if not p["named"]:
		# The name lists, still coming, or refused: a way to ask again.
		if slice["busy"]:
			box.add_child(UI.label(Strings.t("COMMON_LOADING"), UI.TEXT_POINTS, true))
		else:
			var again := UI.row()
			again.add_child(_act("words", Strings.t("WORKSHOP_WORDS_AGAIN"), controller.load_words, false,
				Strings.t("WORKSHOP_WORDS_AGAIN")))
			box.add_child(again)
		body.add_child(UI.plate(box))
		return
	var words: Dictionary = slice["words"]
	box.add_child(UI.label(Strings.t("WORKSHOP_NAME", p["name"]), UI.TEXT_POINTS, true))
	var r := UI.row()
	r.add_child(_act("adjective", Strings.t("SOCIAL_OTHER_ADJECTIVE"), func() -> void:
		adjective = (adjective + 1) % maxi(1, (words.get("adjectives", []) as Array).size())
		_refresh(), false, Strings.t("WORKSHOP_OTHER_ADJECTIVE", p["name"])))
	r.add_child(_act("noun", Strings.t("SOCIAL_OTHER_NOUN"), func() -> void:
		noun = (noun + 1) % maxi(1, (words.get("nouns", []) as Array).size())
		_refresh(), false, Strings.t("WORKSHOP_OTHER_NOUN", p["name"])))
	r.add_child(_act("publish", Strings.t("WORKSHOP_PUBLISH"), _publish, busy,
		Strings.t("WORKSHOP_PUBLISH_NAMED", p["name"]), true))
	box.add_child(r)
	body.add_child(UI.plate(box))


func _publish() -> void:
	var heist: Dictionary = App.services.store.get_slice(AppState.HEIST)
	controller.publish(heist["island"], heist["replay"], adjective, noun)


## §18.6: fun, cleverness and fairness for the island just played.
func _rating_panel(slice: Dictionary, busy: bool) -> void:
	var p := WorkshopPresenter.rating(slice, scores)
	var box := VBoxContainer.new()
	box.add_child(UI.label(Strings.t("WORKSHOP_RATE_TITLE", p["name"]), UI.TEXT_POINTS, true))
	for aspect: String in ASPECTS:
		var r := UI.row()
		var said: String = p[aspect]
		r.add_child(_act("lower:" + aspect, "−", _score.bind(aspect, -1), false, Strings.t("WORKSHOP_LOWER", said)))
		r.add_child(UI.plate(UI.label(said)))
		r.add_child(_act("raise:" + aspect, "+", _score.bind(aspect, 1), false, Strings.t("WORKSHOP_HIGHER", said)))
		box.add_child(r)
	var send := UI.row()
	send.add_child(_act("rate", Strings.t("WORKSHOP_SEND_RATING"), _send_rating.bind(p["id"]), busy,
		Strings.t("WORKSHOP_SEND_RATING_NAMED", p["name"]), true))
	box.add_child(send)
	body.add_child(UI.plate(box))


## The rating sent; the panel closes once the server has it, and stays, with
## the scores chosen, to send again if it was refused.
func _send_rating(id: String) -> void:
	if await controller.rate(id, scores["fun"], scores["cleverness"], scores["fairness"]) and is_inside_tree():
		rate_open = false
		_refresh()


func _score(aspect: String, by: int) -> void:
	scores[aspect] = clampi(int(scores[aspect]) + by, 1, 5)
	_refresh()


func _next_reason(id: String) -> void:
	var list := WorkshopState.REPORT_REASONS
	reasons[id] = list[(list.find(reasons.get(id, list[0])) + 1) % list.size()]
	_refresh()


## A Workshop island, played on the heist screen — if the player is still
## here when it has been fetched.
func _play(id: String) -> void:
	var heist := await controller.play(id)
	if not heist.is_empty() and is_inside_tree():
		controller.start(heist)


## §18.6: the island into the builder, to build on; publishing it names the
## original. A player with an island of their own in the builder is asked
## first, by a second tap, since the remix takes its place.
func _remix(id: String) -> void:
	if not Draft.island().is_empty() and confirm_remix != id:
		confirm_remix = id
		_refresh()
		return
	confirm_remix = ""
	if await controller.remix(id) and is_inside_tree():
		App.services.router.go(&"builder")
