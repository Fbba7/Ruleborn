class_name CoreTests
extends RefCounted
## The architecture's own layers, headless: the store and its reducers, the
## API's failure codes, §24.12's outbox, the router, and the tokens. Each is
## a plain object, so no screen is mounted; `check(name, passed, detail)` is
## run.gd's.

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
	_tokens()


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
			and not Api.secure("http://127.0.0.1.edge.example/"))
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
