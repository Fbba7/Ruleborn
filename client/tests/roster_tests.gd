class_name RosterTests
extends RefCounted
## The Roster and Character screens (§23.2): their reducers and words
## headless, their changes through a FakeTransport, the screens as drawn,
## and the roster against the server when one is named.

## A moment the sample's rest timers are read at.
const NOW := 1_000_000_000

var tree: SceneTree
var check: Callable
var mount: Callable
var server_url := ""


func _init(t: SceneTree, c: Callable, m: Callable, url: String) -> void:
	tree = t
	check = c
	mount = m
	server_url = url


func run() -> void:
	_reducers()
	_words()
	_reassign()
	_character()
	await _flows()
	await _offline()
	await _on_screen()
	await _online()


## A home as the server answers GET /v1/home: four characters, one in each
## state — the resting one still holding its slot at the Heart's Aether
## Spring — two realms, and the producers listed outer realm first, so the
## order §14.1 staffs in is the client's own.
static func sample() -> Dictionary:
	return {"characters": [
		{"id": 1, "kind": "featherkin", "school": "Motion", "role": "Scout", "traits": ["swift", "steady"],
			"level": 1, "top": 2, "home": "spire", "via": "woke", "state": "working",
			"work": {"realm": "heart", "kind": "star_well", "n": 1, "since": 0, "counts_from": 300000},
			"next_level": {"to": 2, "cost": 150, "blocked": null}},
		{"id": 2, "kind": "tidewalker", "school": "Time", "role": "Carrier", "traits": ["quiet", "lucky"],
			"level": 2, "top": 2, "home": "spire", "via": "woke", "state": "resting",
			"resting_until": NOW + 41 * 60000 + 1, "wake_cost": 168,
			"work": {"realm": "heart", "kind": "aether_spring", "n": 1, "since": 0, "counts_from": 300000},
			"next_level": {"to": 3, "cost": 233, "blocked": "home_too_low"}},
		{"id": 3, "kind": "featherkin", "school": "Motion", "role": "Scout", "traits": ["brave", "homebody"],
			"level": 3, "top": 4, "home": "outer-1", "via": "stray", "state": "guarding",
			"work": {"realm": "outer-1", "kind": "guardian_post", "n": 2, "since": 0, "counts_from": 300000},
			"next_level": {"to": 4, "cost": 360, "blocked": null}},
		{"id": 4, "kind": "mossbear", "school": "Life", "role": "Warden", "traits": ["sturdy", "green_thumb"],
			"level": 10, "top": 10, "home": "outer-1", "via": "birth", "state": "idle", "work": null,
			"next_level": null}],
		"realms": [{"realm": "heart", "type": "Heart"}, {"realm": "outer-1", "type": "Lantern Vale"}],
		"places": [{"home": "spire", "room": 3, "living": 2, "top": 2}, {"home": "outer-1", "room": 4, "living": 2,
			"top": 10}],
		"roster": {"used": 4, "most": 15}, "next_birth": 200, "nurseries": [],
		"producers": [
			{"realm": "outer-1", "kind": "star_well", "level": 1, "resource": "starlight", "slots": 2, "workers": []},
			{"realm": "heart", "kind": "aether_spring", "level": 1, "resource": "aether", "slots": 1, "workers": []},
			{"realm": "heart", "kind": "garden", "level": 1, "resource": "essence", "slots": 2, "workers": []},
			{"realm": "heart", "kind": "star_well", "level": 1, "resource": "starlight", "slots": 1, "workers": [1]}],
		"essence": 1234, "aether": 0, "night": null}


static func _with(view: Dictionary, id: int, changes: Dictionary) -> Dictionary:
	var v: Dictionary = view.duplicate(true)
	for c: Dictionary in v["characters"]:
		if int(c["id"]) == id:
			c.merge(changes, true)
	return v


func _reducers() -> void:
	var store := Store.new()
	RosterState.register(store)
	store.dispatch(&"roster_loaded", {"view": sample()})
	store.dispatch(&"roster_change_asked", {"key": "work:4:heart:garden"})
	var asked: Dictionary = store.get_slice(RosterState.ROSTER)
	store.dispatch(&"roster_failed", {"code": "slots_full", "detail": {"slots": 2}})
	var failed: Dictionary = store.get_slice(RosterState.ROSTER)
	var moved := _with(sample(), 4, {"state": "working", "work": {"realm": "heart", "kind": "garden", "n": 1}})
	store.dispatch(&"roster_changed", {"home": moved, "what": {"do": "work", "name": "Mossbear", "realm": "heart",
		"kind": "garden", "n": 1}})
	var made: Dictionary = store.get_slice(RosterState.ROSTER)
	store.dispatch(&"roster_asked")
	store.dispatch(&"roster_loaded", {"view": sample(), "changes": 0})
	var stale: Dictionary = store.get_slice(RosterState.ROSTER)
	check.call("the roster reducers mark the change on its way, keep the roster on show when one fails, take the "
			+ "server's home when one is made, and never put back a home fetched before it (11.4, 11.6)",
		asked["busy"] == "work:4:heart:garden" and failed["busy"] == "" and failed["error"] == "slots_full"
			and (failed["view"]["characters"] as Array).size() == 4 and made["view"]["characters"][3]["state"] == "working"
			and made["last"]["what"]["do"] == "work" and stale["view"]["characters"][3]["state"] == "working"
			and stale["busy"] == "",
		"%s | %s | %s | %s" % [asked["busy"], failed["error"], made["last"], stale["view"]["characters"][3]])


func _words() -> void:
	var r := RosterPresenter.screen({"view": sample(), "busy": "", "error": "", "last": {}}, NOW)
	var rows: Array = r["rows"]
	var marks := {}
	var colours := {}
	for s: String in RosterPresenter.MARK:
		marks[RosterPresenter.MARK[s]] = s
		colours[Palette.ROSTER_STATE[s]] = s
	check.call("the Roster shows every character's state as a symbol and a word as well as a colour, each "
			+ "state's symbol and colour its own (23.2, 20.8)",
		rows[0]["line"] == "● working" and rows[1]["line"].begins_with("◐ resting")
			and rows[2]["line"] == "◆ guarding" and rows[3]["line"] == "○ free"
			and marks.size() == 4 and colours.size() == 4 and r["header"] == "4 of 15 places · 1,234 Essence"
			and rows[0]["name"] == "Featherkin 1" and rows[2]["name"] == "Featherkin 2" and rows[3]["name"] == "Mossbear"
			and rows[0]["where"] == "Star Well, The Heart" and rows[2]["where"] == "Guardian Post 2, Lantern Vale"
			and rows[3]["where"] == "" and rows[1]["spoken"].begins_with("Tidewalker, ◐ resting"),
		"%s | %s" % [r["header"], rows])
	check.call("the Roster shows each rest's time left, by the minute begun (11.6, 23.2)",
		rows[1]["timer"] == "back in 42 min" and rows[1]["line"] == "◐ resting · back in 42 min"
			and RosterPresenter.back_in(125 * 60000) == "back in 2 h 5 min"
			and RosterPresenter.back_in(1) == "back in 1 min" and rows[0]["timer"] == "",
		"%s" % [rows[1]])


## §14.1: "Each new worker staffs the Heart's producers first, then each
## outer realm's in the order the realms opened. … The Roster's one-tap
## reassign follows the same order (23.2)."
func _reassign() -> void:
	var v := sample()
	var idle: Dictionary = RosterPresenter.reassign(v["characters"][3], v, "Mossbear")
	var worker: Dictionary = RosterPresenter.reassign(v["characters"][0], v, "Featherkin 1")
	var full: Dictionary = v.duplicate(true)
	full["producers"][2]["slots"] = 0
	var next: Dictionary = RosterPresenter.reassign(full["characters"][3], full, "Mossbear")
	var none: Dictionary = v.duplicate(true)
	for p: Dictionary in none["producers"]:
		p["slots"] = 0
	var waits: Dictionary = RosterPresenter.reassign(none["characters"][3], none, "Mossbear")
	check.call("the Roster's one tap sends a character to the first producer with a free slot in 14.1's order: "
			+ "the Heart's first, then each outer realm's as they opened, a resting worker's slot still held; "
			+ "with none free it waits and says why (14.1, 23.2)",
		idle["args"] == {"id": 4, "realm": "heart", "kind": "garden", "n": 1} and idle["can"]
			and idle["action"] == "Send to Garden, The Heart" and idle["spoken"] == "Send Mossbear to Garden, The Heart"
			and worker["args"]["kind"] == "garden" and next["args"]["realm"] == "outer-1"
			and next["args"]["kind"] == "star_well" and not waits["can"]
			and waits["why"] == "every producer is staffed" and waits["action"] == "Send to work",
		"%s | %s | %s | %s" % [idle, worker, next, waits])


func _character() -> void:
	var slice := {"view": sample(), "busy": "", "error": "", "last": {}}
	var c := RosterPresenter.character(slice, 2, NOW)
	var top := RosterPresenter.character(slice, 4, NOW)
	var missing := RosterPresenter.character(slice, 99, NOW)
	var ability := Strings.t("ABILITY_TIDEWALKER")
	check.call("the Character screen shows school, role, ability, traits, level and best work, from the "
			+ "character's card (11.11, 23.2)",
		c["title"] == "Tidewalker" and c["school"] == "time" and c["role"] == "Carrier"
			and c["ability"] == "Ability: " + ability and ability != "ABILITY_TIDEWALKER"
			and c["best"] == "Best at: Aether Springs, water routes"
			and c["traits"] == ["Quiet: " + Strings.t("TRAIT_EFFECT_QUIET"), "Lucky: " + Strings.t("TRAIT_EFFECT_LUCKY")]
			and c["level"] == "Level 2, of the 2 its home allows" and c["lives"] == "Lives in: Keeper's Spire"
			and c["line"] == "◐ resting · back in 42 min" and c["where"] == "Aether Spring, The Heart"
			and missing["missing"],
		"%s" % [c])
	check.call("the Character screen spends Essence at the server's price: the next level, held back in words "
			+ "when its home allows no higher, none past the top, and waking from a rest (11.4, 11.6)",
		not c["raise"]["can"] and c["raise"]["why"] == "its home allows no higher"
			and c["raise"]["action"] == "Raise to level 3, 233 Essence" and c["wake"]["action"] == "Wake now, 168 Essence"
			and c["wake"]["args"] == {"id": 2} and top["raise"] == null and top["wake"] == null
			and RosterPresenter.character(slice, 1, NOW)["raise"]["can"],
		"%s | %s" % [c["raise"], c["wake"]])


func _flows() -> void:
	var transport := FakeTransport.new()
	var s := Fixtures.answered(Services.build(tree.root, "https://edge.example", transport,
		"user://outbox-roster-test.json"))
	s.api.token = "t"
	transport.on("GET /v1/home", sample())
	await s.roster_flow.load_roster()
	var moved := _with(sample(), 4, {"state": "working", "work": {"realm": "heart", "kind": "garden", "n": 1}})
	transport.on("POST /v1/home/characters/4/work", {"home": moved})
	await s.roster_flow.work(4, "heart", "garden", 1, "Mossbear")
	var sent: Dictionary = JSON.parse_string((transport.calls[-1]["body"] as PackedByteArray).get_string_from_utf8())
	var made: Dictionary = s.store.get_slice(RosterState.ROSTER)
	var said: String = RosterPresenter.screen(made, NOW)["said"]
	transport.on("POST /v1/home/characters/1/level", {"error": "not_enough_essence", "cost": 150}, 409)
	await s.roster_flow.level(1, 2)
	var refused: Dictionary = s.store.get_slice(RosterState.ROSTER)
	var asked := transport.calls.size()
	s.store.dispatch(&"roster_change_asked", {"key": "wake:2"})
	await s.roster_flow.wake(2)
	await s.roster_flow.load_roster()
	check.call("a reassign sends the building the server is to staff and shows the home it answers, and says "
			+ "where the character went; a refusal keeps the roster on show and says why; a second change "
			+ "waits for the first (5.8, 23.2)",
		transport.calls[1]["route"] == "POST /v1/home/characters/4/work" and sent["realm"] == "heart"
			and sent["kind"] == "garden" and int(sent["n"]) == 1 and made["view"]["characters"][3]["state"] == "working"
			and said == "Mossbear goes to Garden, The Heart" and refused["error"] == "not_enough_essence"
			and RosterPresenter.screen(refused, NOW)["error"] == Errors.message("ROSTER_FAILED", "not_enough_essence")
			and (refused["view"]["characters"] as Array).size() == 4 and transport.calls.size() == asked,
		"%s | %s | %s" % [sent, said, refused["error"]])
	s.close()


## §24: "The device may … assign work offline, confirmed on reconnection".
func _offline() -> void:
	var path := "user://outbox-roster-offline-test.json"
	DirAccess.remove_absolute(path)
	var transport := FakeTransport.new()
	var s := Fixtures.answered(Services.build(tree.root, "https://edge.example", transport, path))
	s.api.token = "t"
	transport.on("GET /v1/home", sample())
	await s.roster_flow.load_roster()
	transport.offline = true
	await s.roster_flow.work(4, "heart", "garden", 1, "Mossbear")
	var waiting: Dictionary = s.store.get_slice(RosterState.ROSTER)
	var kept := s.outbox.pending()
	transport.offline = false
	var moved := _with(sample(), 4, {"state": "working", "work": {"realm": "heart", "kind": "garden", "n": 1}})
	transport.on("POST /v1/offline", {"results": [{"confirmed": true}], "universe": {}, "home": moved})
	await s.outbox.flush(s.api)
	var after: Dictionary = s.store.get_slice(RosterState.ROSTER)
	var sent: Array = transport.calls.filter(func(c: Dictionary) -> bool: return c["route"] == "POST /v1/offline")
	var body: Dictionary = JSON.parse_string((sent[0]["body"] as PackedByteArray).get_string_from_utf8()) \
		if not sent.is_empty() else {}
	var action: Dictionary = (body.get("actions", [{}]) as Array)[0]
	check.call("work assigned with no network waits in the outbox, shown as confirming, and is confirmed on "
			+ "reconnection with the home after it (24)",
		kept == 1 and (waiting["confirming"] as Dictionary).size() == 1
			and RosterPresenter.screen(waiting, NOW)["confirming"] == Strings.t("UNIVERSE_CONFIRMING", 1)
			and action.get("do") == "work" and int(action.get("character", 0)) == 4 and action.get("kind") == "garden"
			and s.outbox.pending() == 0 and (after["confirming"] as Dictionary).is_empty()
			and after["view"]["characters"][3]["state"] == "working",
		"%s | %s | %s" % [kept, waiting["confirming"], action])
	s.close()
	DirAccess.remove_absolute(path)


## The screens as drawn: each state's swatch in its colour beside its mark
## and word; the reassign button names where it sends; a character's name
## opens its page, whose spends are asked twice.
func _on_screen() -> void:
	var services: Services = App.services
	var screen: RosterScreen = await mount.call("roster")
	screen.clock = func() -> int: return NOW
	await tree.process_frame
	services.store.dispatch(&"roster_loaded", {"view": sample()})
	var swatches := {}
	for r: ColorRect in screen.find_children("*", "ColorRect", true, false):
		if r.has_meta("state"):
			swatches[r.get_meta("state")] = r.color
	var lines := screen.body.find_children("*", "Label", true, false).map(func(l: Label) -> String: return l.text)
	var send: Button = null
	var open: Button = null
	for b: Button in screen.find_children("*", "Button", true, false):
		if b.get_meta("key", "") == "work:4:heart:garden":
			send = b
		if b.get_meta("item", "") == "open:2":
			open = b
	var drawn: bool = swatches.size() == 4 and swatches["resting"] == Palette.ROSTER_STATE["resting"] \
		and swatches["working"] == Palette.ROSTER_STATE["working"] and "◐ resting · back in 42 min" in lines \
		and send != null and send.get_meta("words", "") == "Send to Garden, The Heart" and not send.disabled \
		and open != null and open.accessibility_name.begins_with("Tidewalker")
	send.pressed.emit()
	for i in 5:
		await tree.process_frame
	# Offline here: the work waits in the outbox to be confirmed (§24).
	var tried: Dictionary = services.store.get_slice(RosterState.ROSTER)
	var kept := services.outbox.has(RosterController.OFFLINE + "work:4:heart:garden")
	services.outbox.drop(RosterController.OFFLINE + "work:4:heart:garden")
	services.store.dispatch(&"roster_answered", {"key": "work:4:heart:garden"})
	# The rows were drawn again by those changes: the name's button is a new one.
	for b: Button in screen.find_children("*", "Button", true, false):
		if b.get_meta("item", "") == "open:2":
			open = b
	open.pressed.emit()
	var route: Dictionary = services.store.get_slice(AppState.ROUTE)
	screen.queue_free()
	await tree.process_frame
	var page: CharacterScreen = await mount.call("character")
	page.clock = func() -> int: return NOW
	page._refresh()
	var wake: Button = null
	var raise: Button = null
	for b: Button in page.find_children("*", "Button", true, false):
		if b.get_meta("key", "") == "wake:2":
			wake = b
		if b.get_meta("key", "") == "level:2:3":
			raise = b
	var words := page.find_children("*", "Label", true, false).map(func(l: Label) -> String: return l.text)
	var shown: bool = page.title_label.text == "Tidewalker" and words.has("Aether Springs, water routes") \
		and words.has("its home allows no higher") and raise != null and raise.disabled and wake != null
	wake.pressed.emit()
	await tree.process_frame
	var asked: Button = null
	for b: Button in page.find_children("*", "Button", true, false):
		if b.get_meta("key", "") == "wake:2":
			asked = b
	var confirming: bool = asked != null and asked.text == "Tap again to spend 168 Essence" \
		and services.store.get_slice(RosterState.ROSTER)["busy"] == ""
	page.queue_free()
	check.call("the Roster screen draws each state's colour beside its symbol and word, and its one tap sends the "
			+ "character to the producer it names; a name opens the character, whose Essence is spent on a "
			+ "second tap (20.8, 23.2)",
		drawn and kept and (tried["confirming"] as Dictionary).has("work:4:heart:garden")
			and route["name"] == &"character" and int(route["params"]["id"]) == 2 and shown and confirming,
		"%s %s %s | %s | %s" % [drawn, kept, swatches, route, words])


func _online() -> void:
	var name := "against the server: the roster is §15.6's three, idle, and one tap sends the first to the "
	name += "Heart's first producer with a free slot (14.1, 15.6, 23.2)"
	if server_url == "":
		check.call(name, false, "no server: run through client/status.py, which starts one")
		return
	var s := Fixtures.answered(Services.build(tree.root, server_url, null, "user://outbox-test-roster.json"))
	s.router.change = func(_path: String) -> void: pass
	var me := await s.account.sign_in("test:roster")
	if not me.ok:
		check.call(name, false, "sign-in refused: %s" % me.code)
		s.close()
		return
	await s.roster_flow.load_roster()
	var loaded: Dictionary = s.store.get_slice(RosterState.ROSTER)
	var v: Dictionary = loaded["view"]
	var first: Dictionary = v["characters"][0] if not (v.get("characters", []) as Array).is_empty() else {}
	var send: Dictionary = RosterPresenter.reassign(first, v, "") if not first.is_empty() else {"args": {}}
	var a: Dictionary = send["args"]
	if not a.is_empty():
		await s.roster_flow.work(int(a["id"]), str(a["realm"]), str(a["kind"]), int(a["n"]), "")
	var after: Dictionary = s.store.get_slice(RosterState.ROSTER)
	var states: Array = (v.get("characters", []) as Array).map(func(c: Dictionary) -> String: return c["state"])
	check.call(name,
		loaded["error"] == "" and states == ["idle", "idle", "idle"] and a.get("realm") == "heart"
			and after["error"] == "" and after["view"]["characters"][0]["state"] == "working"
			and after["view"]["characters"][0]["work"]["kind"] == a["kind"],
		"%s | %s | %s" % [states, a, after["error"]])
	s.close()
