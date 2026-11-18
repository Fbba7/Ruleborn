class_name CoreTests
extends RefCounted
## The architecture's own layers, headless: the store and its reducers, the
## API's failure codes, §24.12's outbox, the router, and the tokens. Each is
## a plain object, so no screen is mounted; `check(name, passed, detail)` is
## run.gd's.

## The words a screen's back control says, written or spoken: the kit's
## Back, Home, the roster (the character's) and the map (the realm's).
const WAY_BACK := ["KIT_BACK", "COMMON_HOME", "HOME_ROSTER", "RV_KEY_MAP"]

var tree: SceneTree
var check: Callable


func _init(t: SceneTree, c: Callable) -> void:
	tree = t
	check = c


func run() -> void:
	_store()
	await _api()
	await _outbox()
	_router()
	_tabs()
	await _back()
	_tokens()
	_overlay()


func _store() -> void:
	var store := Store.new()
	AppState.register(store)
	var seen: Array[StringName] = []
	store.changed.connect(func(slice: StringName) -> void: seen.append(slice))
	store.dispatch(&"signed_in", {"account": "a1"})
	store.dispatch(&"heist_started", {"island": PackedByteArray([1, 2]), "testing": true})
	store.dispatch(&"heist_finished", {"replay": PackedByteArray([9]), "verdict": {"ok": true, "grade": "Clean"}})
	store.dispatch(&"heist_verdict", {"server": true, "haul": 5})
	var heist: Dictionary = store.get_slice(AppState.HEIST)
	var logged := store.action_log.entries().map(func(e: Dictionary) -> String: return e["what"])
	check.call("the store changes a slice only through an action its reducer owns, tells who listens, "
			+ "and logs every action",
		store.get_slice(AppState.SESSION)["account"] == "a1" and heist["testing"]
			and heist["island"] == PackedByteArray([1, 2])
			and heist["verdict"] == {"ok": true, "grade": "Clean", "server": true, "haul": 5}
			and seen == [AppState.SESSION, AppState.HEIST, AppState.HEIST, AppState.HEIST]
			and logged == ["signed_in", "heist_started", "heist_finished", "heist_verdict"],
		"%s %s %s" % [heist, seen, logged])
	# A new heist clears the last one's replay and verdict: the result screen
	# never shows a verdict from a heist before.
	store.dispatch(&"heist_started", {})
	heist = store.get_slice(AppState.HEIST)
	check.call("a heist started clears the last heist's replay and verdict, "
			+ "and is not the builder's test unless it says so",
		heist["replay"].is_empty() and heist["verdict"].is_empty() and not heist["testing"], str(heist))
	# The log keeps kinds and short values, never bytes or long strings.
	var action_log := ActionLog.new()
	action_log.add("action", "x", {"token": "t".repeat(200), "n": 3, "bytes": PackedByteArray([1])})
	var kept: Dictionary = action_log.entries()[0]["fields"]
	for i in ActionLog.CAPACITY + 5:
		action_log.add("action", "y%d" % i)
	check.call("the action log keeps the last actions only, and no long string or bytes that could name a player",
		kept == {"n": 3} and action_log.entries().size() == ActionLog.CAPACITY, str(kept))


func _api() -> void:
	var fake := FakeTransport.new()
	tree.root.add_child(fake)
	var action_log := ActionLog.new()
	var api := Api.new(fake, "https://edge.example/", action_log)
	fake.on("POST /v1/session", {"account": "a1", "token": "tok"})
	fake.on("POST /v1/leases", {"error": "no_such_snapshot"}, 404)
	fake.on("GET /v1/balance", PackedByteArray([0x7b]))
	var account := AccountRepository.new(api)
	var signed := await account.sign_in("gc:x")
	var leased := await HeistRepository.new(api, Outbox.new("user://outbox-core.json")).lease("b1")
	var garbled := await account.balance()
	var missing := await api.get_json("/v1/nowhere")
	fake.offline = true
	var down := await account.balance()
	var bearer: bool = (fake.calls[1]["headers"] as PackedStringArray).has("Authorization: Bearer tok")
	check.call("every call answers a Result: the server's refusal reason as its code, "
			+ "the client's own for no answer or a garbled one",
		signed.ok and api.token == "tok" and bearer and not leased.ok and leased.code == "no_such_snapshot"
			and garbled.code == "malformed_response" and missing.code == "no_such_route" and down.code == "unreachable",
		"%s %s %s %s %s" % [signed, leased, garbled, missing, down])
	check.call("a failure is logged by its code and route, never the path's token",
		action_log.entries().any(func(e: Dictionary) -> bool:
			return e["what"] == "no_such_snapshot" and e["fields"]["route"] == "v1/leases"),
		action_log.dump())
	check.call("only HTTPS leaves the phone; plain HTTP only to this machine, for tests",
		Api.secure("https://edge.example/") and Api.secure("http://127.0.0.1:8787") and not Api.secure("http://edge.example")
			and not Api.secure("http://127.0.0.1.edge.example/") and Api.secure("http://localhost")
			and Api.secure("http://localhost:8787/v1"))
	# SR-06: a userinfo or backslash before the real host is not the loopback.
	check.call("SR-06: plain HTTP is refused to a host hidden behind the loopback's name",
		not Api.secure("http://localhost:1@edge.example/") and not Api.secure("http://127.0.0.1:80@edge.example")
			and not Api.secure("http://localhost\\@edge.example/") and not Api.secure("http://localhost.:80/")
			and not Api.secure("http://localhost:x@edge.example") and not Api.secure("http://localhost:1?@edge.example"))
	fake.queue_free()
	DirAccess.remove_absolute("user://outbox-core.json")


func _outbox() -> void:
	var file := "user://outbox-core.json"
	DirAccess.remove_absolute(file)
	var fake := FakeTransport.new()
	tree.root.add_child(fake)
	var api := Api.new(fake, "https://edge.example", ActionLog.new())
	var heists := HeistRepository.new(api, Outbox.new(file))
	# §24.12: offline, the replay waits, and the heist is shown as confirming.
	fake.offline = true
	var queued := await heists.submit("lease-1", PackedByteArray([1, 2, 3]))
	var waiting := heists.outbox.pending()
	# The phone restarts: the outbox is read back from its file.
	var reopened := Outbox.new(file)
	# Back online: the server answers, and the item is done.
	fake.offline = false
	fake.on("POST /v1/heists/lease-1", {"validated": true, "verdict": {"grade": "clean", "banked": 10},
			"haul": {"total": 5}, "fee": 1})
	var answered := {}
	reopened.settled.connect(func(key: String, r: Result) -> void: answered[key] = r)
	var sent := await reopened.flush(api)
	var body: PackedByteArray = fake.calls[-1]["body"]
	check.call("offline, a heist's replay waits in the outbox, survives a restart, "
			+ "and is sent once the server can be reached (24.12)",
		queued.ok and queued.value.get("pending", false) and waiting == 1 and reopened.pending() == 0 and sent == 1
			and answered.has("lease-1") and answered["lease-1"].ok and body == PackedByteArray([1, 2, 3]),
		"%s %d %d" % [queued, waiting, sent])
	# A refusal the server decided ends the item; a 5xx keeps it.
	var box := Outbox.new(file)
	box.put("a", "/v1/heists/a", PackedByteArray([1]))
	box.put("a", "/v1/heists/a", PackedByteArray([2]))
	box.put("b", "/v1/heists/b", PackedByteArray([1]))
	fake.on("POST /v1/heists/a", {"error": "lease_expired"}, 410)
	fake.on("POST /v1/heists/b", {"error": "internal"}, 500)
	await box.flush(api)
	check.call("an item is put once by its key; one the server refused is done, "
			+ "one the server failed on waits for the next try",
		box.pending() == 1 and box.has("b") and not box.has("a"), "pending %d" % box.pending())
	var shown := HeistController.settled(queued, {"ok": true, "grade": "Clean", "banked": 10})
	check.call("a heist still in the outbox shows the phone's own check, marked confirming, never a haul (24.12)",
		shown.get("confirming", false) and shown.get("grade") == "Clean" and not shown.has("haul"), str(shown))
	fake.queue_free()
	DirAccess.remove_absolute(file)


func _router() -> void:
	var store := Store.new()
	AppState.register(store)
	var router := Router.new(store)
	var shown: Array[String] = []
	router.change = func(path: String) -> void: shown.append(path)
	router.go(&"heist")
	router.go(&"result", {"from": "heist"})
	check.call("the router shows a route's scene, and the screen history is in the store and its log",
		shown == ["res://scenes/heist_screen.tscn", "res://scenes/result_screen.tscn"] and router.current() == &"result"
			and store.get_slice(AppState.ROUTE)["params"] == {"from": "heist"}
			and Router.ROUTES.values().all(func(p: String) -> bool: return ResourceLoader.exists(p)),
		"%s" % [shown])


## AD-R49: one route table for the bar. Every tab of the kit's bar has a route
## in the router's table, and home sends each tab where that table does, but for
## the tabs home keeps for itself (Home.TABS_HOME_KEEPS: Islands and the Heist).
func _tabs() -> void:
	var problems: Array[String] = []
	var ids: Array[String] = []
	for tab: Array in KitTabs.TABS:
		ids.append(str(tab[0]))
	for id: String in ids:
		if not Router.TABS.has(id) or not Router.ROUTES.has(Router.TABS[id]):
			problems.append("%s has no route" % id)
		var want: StringName = &"" if id in Home.TABS_HOME_KEEPS else Router.TABS.get(id, &"")
		if HomeParts.tab_route(id) != want:
			problems.append("home sends %s to '%s'" % [id, HomeParts.tab_route(id)])
	for id: String in Home.TABS_HOME_KEEPS:
		if id not in ids:
			problems.append("home keeps %s, not a tab" % id)
	check.call("every tab has a route in Router.TABS, and home's tabs go where it says, Islands and the Heist excepted",
		problems.is_empty() and Router.TABS.size() == ids.size() and Home.TABS_HOME_KEEPS == ["islands", "heist"],
		"; ".join(problems))


func _tokens() -> void:
	var problems: Array[String] = []
	var data: Variant = JSON.parse_string(FileAccess.get_file_as_string(Tokens.FILE))
	for group: String in ["color", "size", "motion"]:
		for name: String in data[group]:
			var t: Dictionary = data[group][name]
			if not t.has("value") or str(t.get("from", "")) == "":
				problems.append("%s.%s" % [group, name])
	check.call("every design token has a value and says where it comes from, "
			+ "and the screens' colours and sizes are the tokens'",
		problems.is_empty() and Palette.INK == Tokens.color("ink")
			and UI.CONTROL_POINTS == Tokens.number("size", "control_points")
			and Tokens.number("size", "smallest_points") == 13.0,
		"; ".join(problems))


func _overlay() -> void:
	var fake := FakeTransport.new()
	tree.root.add_child(fake)
	var services := Services.build(tree.root, "https://edge.example", fake, "user://outbox-core.json")
	var overlay := DebugOverlay.new(services)
	services.store.dispatch(&"signed_in", {"account": "a1"})
	services.store.dispatch(&"navigated", {"name": &"heist"})
	services.outbox.put("lease-9", "/v1/heists/lease-9", PackedByteArray([1]))
	var shown := overlay.text()
	check.call("the debug overlay shows the route, the account, what waits in the outbox, and the last actions",
		shown.contains("route heist") and shown.contains("account a1") and shown.contains("outbox 1")
			and shown.contains("signed_in") and shown.contains("navigated"),
		shown)
	overlay.free()
	fake.queue_free()
	DirAccess.remove_absolute("user://outbox-core.json")


## The phone's back and Escape (Router.BACK, App.GoBack): every route has a
## back route; each tab but home goes home; each screen below a tab goes
## where its own back control goes, pressed on the screen itself; home asks
## before quitting, Stay the default and focused, a second back closes the
## question, and nothing quits.
func _back() -> void:
	var router: Router = App.services.router
	var was := router.change
	var quitting := router.quit
	var quits := []
	router.quit = func() -> void: quits.append(true)
	var problems: Array[String] = []
	for name: StringName in Router.ROUTES:
		if not Router.BACK.has(name) or not Router.ROUTES.has(Router.BACK[name]):
			problems.append("%s: no back route" % name)
	for name: StringName in Router.BACK:
		if not Router.ROUTES.has(name):
			problems.append("%s: not a route" % name)
	var segments: Array = Router.HUBS.values().reduce(func(a: Array, h: Array) -> Array:
		return a + h.map(func(s: Dictionary) -> StringName: return s["route"]), [])
	var tabs: Array = Router.TABS.values() + segments
	for name: StringName in tabs:
		if name != &"home" and router.back_route(name) != &"home":
			problems.append("%s, a tab: back to %s" % [name, router.back_route(name)])
	# Each screen below a tab, opened as a player opens it, its back control
	# pressed: the route it opens is the table's.
	router.change = func(path: String) -> void: tree.change_scene_to_file(path)
	App.services.store.dispatch(&"roster_loaded", {"view": HatchTests.born()})
	var pressed := 0
	for name: StringName in Router.ROUTES:
		if name in tabs or router.back_route(name) == name:
			continue
		router.go(name, {"id": 2} if name == &"character" else {})
		await tree.create_timer(0.4).timeout
		await tree.process_frame
		var back := _back_control(tree.current_scene)
		if back == null:
			problems.append("%s: no back control" % name)
			continue
		back.pressed.emit()
		await tree.process_frame
		pressed += 1
		if router.current() != router.back_route(name):
			problems.append("%s: its back control opens %s, the table %s" % [name, router.current(),
				router.back_route(name)])
		# The phone's back from the same screen lands on the same route.
		router.go(name, {"id": 2} if name == &"character" else {})
		if router.go_back() or router.current() != router.back_route(name):
			problems.append("%s: the phone's back opens %s" % [name, router.current()])
	for name: StringName in Router.BACK:
		if Router.BACK[name] == name and name != &"home":
			App.services.store.dispatch(&"navigated", {"name": name, "params": {}})
			if router.go_back() or router.current() != name:
				problems.append("%s, with no way back: the back opened %s" % [name, router.current()])
	check.call("the phone's back and Escape follow the router's one back table: every route has one, each tab "
			+ "goes home, and each screen below a tab goes where its own back control does (%d)" % pressed,
		problems.is_empty() and pressed > 0, "; ".join(problems))

	# Home: the phone's back asks; a second back closes the question.
	router.go(&"home")
	await tree.create_timer(0.4).timeout
	await tree.process_frame
	var home := tree.current_scene as Home
	var go_back := App.GoBack.new()
	tree.root.add_child(go_back)
	await tree.process_frame
	go_back.notification(Node.NOTIFICATION_WM_GO_BACK_REQUEST)
	await tree.process_frame
	await tree.process_frame
	var asked := home != null and is_instance_valid(go_back.question) and go_back.question.get_parent() == home
	var stay: Button = go_back.question.find_child("Stay", true, false) if asked else null
	var leave: Button = go_back.question.find_child("Quit", true, false) if asked else null
	var question := "%s, stay %s, focus %s" % [asked, stay != null and stay.get_meta("primary", false),
		tree.root.gui_get_focus_owner()]
	var stays: bool = stay != null and leave != null and stay.get_meta("primary", false) \
		and tree.root.gui_get_focus_owner() == stay and go_back.question.name == "Confirm"
	var held := not tree.is_quit_on_go_back()
	go_back.notification(Node.NOTIFICATION_WM_GO_BACK_REQUEST)
	await tree.process_frame
	var closed := asked and go_back.question == null and router.current() == &"home"
	check.call("home's back asks whether to quit, with Stay the default and focused, a second back closes the "
			+ "question, and the game quits on neither",
		asked and stays and closed and held and quits.is_empty(), "%s closed %s held %s quits %d"
			% [question, closed, held, quits.size()])
	go_back.queue_free()
	tree.set_quit_on_go_back(true)
	tree.unload_current_scene()
	await tree.process_frame
	router.change = was
	router.quit = quitting


## The screen's way back: a back key (ScreenNav's, meta "back"), or a key
## that says where it goes, by its words or its spoken name (WAY_BACK).
func _back_control(screen: Node) -> Button:
	if screen == null:
		return null
	var words := WAY_BACK.map(func(key: String) -> String: return Strings.t(key))
	var found: Array = screen.find_children("*", "Button", true, false).filter(func(b: Button) -> bool:
		return b.is_visible_in_tree() and (b.get_meta("back", false) or b.accessibility_name in words
			or b.text in words))
	return found[0] if found else null
