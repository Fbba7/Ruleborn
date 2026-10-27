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
## Each list's icon in the strip.
const TAB_ICONS := {"top": "leagues/nova", "new": "generalui/new", "featured": "hud/star",
	"mine": "screens/islandworkshop"}

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
## The creator whose Block was tapped once, by island: a second tap blocks,
## since a block also ends a friendship (§17.8).
var confirm_block := ""


func _ready() -> void:
	App.ready(self)
	controller = App.services.workshop_flow
	var params: Dictionary = App.services.store.get_slice(AppState.ROUTE)["params"]
	publish_open = bool(params.get("publish", false))
	rate_open = bool(params.get("rate", false))
	_build()
	App.services.store.changed.connect(_on_changed)
	_refresh()
	# §20.11: the terms asked for beside the list, not before it; a refusal
	# for them asks again, so the gate shows either way.
	controller.load_terms()
	if publish_open:
		await controller.load_words()
	await controller.show_list("mine" if publish_open else "top")


func _on_changed(slice: StringName) -> void:
	if slice == WorkshopState.WORKSHOP and is_inside_tree():
		_refresh()


func _build() -> void:
	var column := ScreenKit.frame(self)
	column.add_child(ScreenNav.header(Strings.t("WORKSHOP_TITLE")))
	status_label = UI.status("info", "")
	column.add_child(ScreenParts.status_plate(status_label))
	body = UI.scroll(column)
	var build := ScreenKit.button(Strings.t("WORKSHOP_BUILD"), func() -> void: App.services.router.go(&"builder"),
		"gold")
	column.add_child(ScreenNav.dock(&"home", [build]))


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
		UI.set_status(status_label, "info", Strings.t("COMMON_LOADING") if w["busy"] else "")
	ScreenParts.show_status(status_label)
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
	body.add_child(ScreenParts.section(w["title"], str((w["items"] as Array).size())))
	if w["ladder"] != "":
		body.add_child(ScreenParts.item("leagues", "star", w["ladder"], "", null, "card_lit"))
	if w["empty"]:
		body.add_child(ScreenParts.item("screens", "islandworkshop",
			Strings.t("WORKSHOP_EMPTY_" + str(w["list"]).to_upper())))
	for item: Dictionary in w["items"]:
		body.add_child(_card(item, w["busy"]))
	if focus_key != "":
		for b: Button in find_children("*", "Button", true, false):
			if b.get_meta("key", "") == focus_key and b.is_visible_in_tree():
				b.grab_focus.call_deferred()
				break


## The lists the player may open, as the design's strip, each its icon over
## its word; at large text, chips that wrap. The list on show is marked in
## the strip, and said aloud as shown.
func _tabs(names: Array[String], on_show: String) -> Control:
	var options: Array = []
	for list: String in names:
		options.append({"text": Strings.t("WORKSHOP_TAB_" + list.to_upper()), "key": list, "on": list == on_show,
			"icon": TAB_ICONS.get(list, "screens/islandworkshop")})
	return ScreenParts.segmented(options, func(list: String) -> void:
		if list != on_show:
			controller.show_list(list))


## An island as the design's card: its mark, its name and realm level, who
## made it, its featured and remix tags, its plays and ratings, and what can
## be done with it.
func _card(item: Dictionary, busy: bool) -> Control:
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", UI.px(8))
	box.add_child(_cover(item))
	if item["rated"]:
		var figures: Array = []
		for aspect: String in ASPECTS:
			figures.append(ScreenParts.stat(item[aspect], Strings.t("SCREEN_RATE_" + aspect.to_upper()), "", "", "track"))
		var row := ScreenParts.columns(figures, 4.0)
		row.tooltip_text = item["ratings"]
		box.add_child(row)
	else:
		box.add_child(ScreenKit.text(item["ratings"], 13.0, "words", "card", true, true))
	# Plays and remixes as counts.
	var counts := ScreenParts.flow(4.0)
	counts.add_child(ScreenParts.pill("%s %s" % [item["completions"], Strings.t("SCREEN_PLAYS")], "well", "heistoutcomes",
		"clean"))
	counts.add_child(ScreenParts.pill("%s %s" % [item["remixes"], Strings.t("SCREEN_REMIXES")], "well", "realmactions",
		"rotate"))
	counts.tooltip_text = item["stats"]
	box.add_child(counts)
	for key: String in ["withdrawn", "removed"]:
		if item[key] != "":
			box.add_child(ScreenParts.pill(item[key], "well", "generalui", "info", 13.0, "words", true))
	# The card's own actions side by side (play, remix, or withdraw one's
	# own), then the safety ones (why, report, block) in a quieter row.
	var main: BoxContainer = HBoxContainer.new()
	if Settings.text_scale > 125:
		main = VBoxContainer.new()
	main.add_theme_constant_override("separation", UI.px(6))
	var safety := ScreenParts.flow(6.0)
	var name: String = item["name"]
	var id: String = item["id"]
	if item["mine"]:
		if item["listed"]:
			main.add_child(_act("withdraw:" + id, Strings.t("WORKSHOP_WITHDRAW"), controller.withdraw.bind(id), busy,
				Strings.t("WORKSHOP_WITHDRAW_NAMED", name)))
	elif item["listed"]:
		main.add_child(_act("play:" + id, Strings.t("WORKSHOP_PLAY"), _play.bind(id), busy,
			Strings.t("WORKSHOP_PLAY_NAMED", name), true))
		var reason: String = reasons.get(id, WorkshopState.REPORT_REASONS[0])
		var why := Strings.term("REPORT", reason)
		safety.add_child(_act("reason:" + id, Strings.t("WORKSHOP_REASON", why), _next_reason.bind(id), false,
			Strings.t("WORKSHOP_REASON_NAMED", [name, why]), false, "ghost"))
		safety.add_child(_act("report:" + id, Strings.t("WORKSHOP_REPORT"), controller.report.bind(id, reason), busy,
			Strings.t("WORKSHOP_REPORT_NAMED", [name, why]), false, "ghost"))
	if item["listed"] and item["creator"] != "":
		var blocking := confirm_block == id
		safety.add_child(_act("block:" + id, Strings.t("WORKSHOP_BLOCK_CONFIRM" if blocking else "WORKSHOP_BLOCK"),
			_block.bind(id, item["creator"]), busy,
			Strings.t("WORKSHOP_BLOCK_CONFIRM_NAMED" if blocking else "WORKSHOP_BLOCK_NAMED", [item["by"], name]),
			false, "ghost"))
	if item["listed"]:
		var confirming := confirm_remix == id
		main.add_child(_act("remix:" + id, Strings.t("WORKSHOP_REMIX_CONFIRM" if confirming else "WORKSHOP_REMIX"),
			_remix.bind(id), busy, Strings.t("WORKSHOP_REMIX_CONFIRM_NAMED" if confirming else "WORKSHOP_REMIX_NAMED",
				name)))
	for c: Node in main.get_children():
		(c as Control).size_flags_horizontal = Control.SIZE_EXPAND_FILL
	if main.get_child_count() > 0:
		box.add_child(main)
	if safety.get_child_count() > 0:
		box.add_child(safety)
	return ScreenKit.panel("card", box, 18.0, 10.0)


## The island's cover, as the design's card heads it: its name over a lit
## band with the realm's mark, who made it, and its featured and remix tags.
func _cover(item: Dictionary) -> Control:
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", UI.px(4))
	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", UI.px(10))
	var words := VBoxContainer.new()
	words.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	words.add_theme_constant_override("separation", 0)
	var title := ScreenKit.inked(ScreenKit.text(item["name"], 20.0, "name", "card_lit", false, true), 2.0)
	title.tooltip_text = item["title"]
	words.add_child(title)
	if item["by"] != "":
		words.add_child(ScreenKit.text(item["by"], 13.0, "words", "card_lit", true, true))
	head.add_child(words)
	var mark := ScreenKit.icon("screens", "realm", 52.0)
	mark.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	head.add_child(mark)
	col.add_child(head)
	var tags := ScreenParts.flow(4.0)
	tags.add_child(ScreenParts.pill(item["level"], "well", "screens", "realm"))
	if item["featured"] != "":
		tags.add_child(ScreenParts.pill(item["featured"], "cream", "hud", "star"))
	if item["remix"] != "":
		tags.add_child(ScreenParts.pill(item["remix"], "well", "realmactions", "rotate"))
	col.add_child(tags)
	return ScreenKit.panel("card_lit", col, 14.0, 12.0)


## §17.8: the first tap asks, the second blocks.
func _block(id: String, creator: String) -> void:
	if confirm_block != id:
		confirm_block = id
		_refresh()
		return
	confirm_block = ""
	await controller.block(creator)


## §20.11's gate: the terms to read, on the game's own server, and to accept
## before publishing, playing, rating or remixing.
func _terms_panel(terms: Dictionary, busy: bool) -> Control:
	var box := VBoxContainer.new()
	box.add_child(ScreenKit.text(terms["text"], 15.0, "words", "card", false, true))
	var r := UI.row(6.0)
	r.add_child(_act("terms:read", Strings.t("WORKSHOP_TERMS_READ"), _read_terms.bind(str(terms["url"])), false,
		Strings.t("WORKSHOP_TERMS_READ")))
	r.add_child(_act("terms:accept", Strings.t("WORKSHOP_TERMS_ACCEPT"), controller.accept_terms, busy,
		Strings.t("WORKSHOP_TERMS_ACCEPT"), true))
	box.add_child(r)
	return ScreenKit.panel("card", box, 18.0, 12.0)


func _read_terms(path: String) -> void:
	OS.shell_open(App.services.api.base + path)


## A control, named by `key` so focus comes back to it after a refresh.
func _act(key: String, text: String, pressed: Callable, busy: bool, spoken: String, main := false,
		material := "") -> Button:
	var b := ScreenKit.button(text, pressed, material if material != "" else ("gold" if main else "leather"), spoken,
		14.0)
	b.disabled = busy
	b.set_meta("key", key)
	# The safety actions (why, report, block) quieter and smaller than the
	# card's own, so they share a line.
	if material == "ghost":
		b.add_theme_font_size_override("font_size", UI.text_px(13))
		b.set_meta("points", 13.0)
		UI.fit(b)
	return b


## §18.6: the rehearsal just cleared, published under a name from the lists.
func _publish_panel(slice: Dictionary, busy: bool) -> void:
	var heist: Dictionary = App.services.store.get_slice(AppState.HEIST)
	var p := WorkshopPresenter.publishing(heist, slice, adjective, noun)
	if not p["can"]:
		return
	var box := VBoxContainer.new()
	box.add_child(ScreenKit.text(Strings.t("WORKSHOP_PUBLISH_TITLE"), 15.0, "words", "card", false, true))
	if p["remix"] != "":
		box.add_child(ScreenKit.text(p["remix"], 15.0, "words", "card", false, true))
	if not p["named"]:
		# The name lists, still coming, or refused: a way to ask again.
		if slice["busy"]:
			box.add_child(ScreenKit.text(Strings.t("COMMON_LOADING"), 15.0, "words", "card", false, true))
		else:
			var again := UI.row(6.0)
			again.add_child(_act("words", Strings.t("WORKSHOP_WORDS_AGAIN"), controller.load_words, false,
				Strings.t("WORKSHOP_WORDS_AGAIN")))
			box.add_child(again)
		body.add_child(ScreenKit.panel("card", box, 18.0, 12.0))
		return
	var words: Dictionary = slice["words"]
	box.add_child(ScreenKit.text(Strings.t("WORKSHOP_NAME", p["name"]), 15.0, "words", "card", false, true))
	var r := UI.row(6.0)
	r.add_child(_act("adjective", Strings.t("SOCIAL_OTHER_ADJECTIVE"), func() -> void:
		adjective = (adjective + 1) % maxi(1, (words.get("adjectives", []) as Array).size())
		_refresh(), false, Strings.t("WORKSHOP_OTHER_ADJECTIVE", p["name"])))
	r.add_child(_act("noun", Strings.t("SOCIAL_OTHER_NOUN"), func() -> void:
		noun = (noun + 1) % maxi(1, (words.get("nouns", []) as Array).size())
		_refresh(), false, Strings.t("WORKSHOP_OTHER_NOUN", p["name"])))
	r.add_child(_act("publish", Strings.t("WORKSHOP_PUBLISH"), _publish, busy,
		Strings.t("WORKSHOP_PUBLISH_NAMED", p["name"]), true))
	box.add_child(r)
	body.add_child(ScreenKit.panel("card", box, 18.0, 12.0))


func _publish() -> void:
	var heist: Dictionary = App.services.store.get_slice(AppState.HEIST)
	controller.publish(heist["island"], heist["replay"], adjective, noun)


## §18.6: fun, cleverness and fairness for the island just played.
func _rating_panel(slice: Dictionary, busy: bool) -> void:
	var p := WorkshopPresenter.rating(slice, scores)
	var box := VBoxContainer.new()
	box.add_child(ScreenKit.text(Strings.t("WORKSHOP_RATE_TITLE", p["name"]), 15.0, "words", "card", false, true))
	for aspect: String in ASPECTS:
		var r := UI.row(6.0)
		var said: String = p[aspect]
		r.add_child(_act("lower:" + aspect, "−", _score.bind(aspect, -1), false, Strings.t("WORKSHOP_LOWER", said)))
		r.add_child(ScreenKit.panel("track", ScreenKit.text(said, 15.0, "words", "well"), 14.0, 8.0))
		r.add_child(_act("raise:" + aspect, "+", _score.bind(aspect, 1), false, Strings.t("WORKSHOP_HIGHER", said)))
		box.add_child(r)
	var send := UI.row(6.0)
	send.add_child(_act("rate", Strings.t("WORKSHOP_SEND_RATING"), _send_rating.bind(p["id"]), busy,
		Strings.t("WORKSHOP_SEND_RATING_NAMED", p["name"]), true))
	box.add_child(send)
	body.add_child(ScreenKit.panel("card", box, 18.0, 12.0))


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
