class_name OfflineTests
extends RefCounted
## The owner's answer to G41: online is the rule and is recommended, offline
## the exception. A stock of leases kept while online, the prompt a heist
## started offline shows, and what waited sent by itself on reconnecting.
## run.gd lends `check` and `mount`.

var tree: SceneTree
var check: Callable
var mount: Callable


func _init(t: SceneTree, c: Callable, m: Callable) -> void:
	tree = t
	check = c
	mount = m


func run() -> void:
	await _stock()
	await _prompt()
	await _reconnect()
	await _held_back()


func _services(name: String) -> Array:
	var transport := FakeTransport.new()
	var outbox := "user://outbox-%s.json" % name
	DirAccess.remove_absolute(outbox)
	DirAccess.remove_absolute(outbox.get_basename() + "-leases.json")
	var s := Fixtures.answered(Services.build(tree.root, "https://edge.example", transport, outbox))
	s.router.change = func(_path: String) -> void: pass
	return [s, transport]


func _stock() -> void:
	var f := _services("stock")
	var s: Services = f[0]
	var transport: FakeTransport = f[1]
	transport.on("GET /v1/targets", {"heart": "list1"})
	var list := {"candidates": [{"bundle": "b1", "owner": "me"}, {"bundle": "b2", "owner": "o2"},
		{"bundle": "b3", "owner": "o3"}, {"bundle": "b4", "owner": "o4"}, {"bundle": "b5", "owner": "o5"}]}
	transport.on("GET /v1/bundles/list1", JSON.stringify(list).to_utf8_buffer())
	for b: String in ["b2", "b3", "b4", "b5"]:
		transport.on("GET /v1/bundles/" + b, PackedByteArray([1, 2, 3]))
	transport.on("POST /v1/leases", {"token": "t", "seed": "9", "ticks": 4500, "expiresAt": 1})
	var added := await s.heists.fill_stock("me")
	var again := await s.heists.fill_stock("me")
	var held := s.heists.stock.bundles()
	# A restart reads the same file.
	var restarted := LeaseStock.new(s.heists.stock.path)
	check.call("while online the phone keeps three leases in stock, each on another player's island and no two "
			+ "alike, and a restart keeps them (G41)",
		added == 3 and again == 0 and held == ["b2", "b3", "b4"] and restarted.count() == 3,
		"added %d, again %d, held %s, restarted %d" % [added, again, held, restarted.count()])
	s.close()


func _prompt() -> void:
	var f := _services("prompt")
	var s: Services = f[0]
	var transport: FakeTransport = f[1]
	transport.offline = true
	var was: Services = App.services
	App.services = s
	s.store.dispatch(&"heist_started", {})
	var empty: HeistScreen = await mount.call("heist_screen")
	empty.set_process(false)
	for i in 10:
		await tree.process_frame
	var none := empty.hint_label.text == Strings.t("OFFLINE_NONE") and not empty.playing
	empty.queue_free()
	s.heists.stock.add("b9", {"token": "t9", "seed": "7", "ticks": 4500, "expiresAt": 1}, PackedByteArray())
	var screen: HeistScreen = await mount.call("heist_screen")
	screen.set_process(false)
	for i in 10:
		await tree.process_frame
	var words := screen.hint_label.text
	var buttons: Array = screen.find_children("*", "Button", true, false).map(func(b: Button) -> String:
		return b.text)
	var held := not screen.playing and screen.lease.is_empty()
	var played := screen.play_stocked(s)
	var ok: bool = none and words == Strings.t("OFFLINE_RECOMMEND") \
		and Strings.t("OFFLINE_TRY_AGAIN") in buttons and Strings.t("OFFLINE_PLAY_ANYWAY") in buttons and held \
		and played and screen.playing and str(screen.lease.get("token")) == "t9" and s.heists.stock.count() == 0
	check.call("with no network a heist recommends going online first, and plays a stocked lease only if the "
			+ "player chooses to; with none in stock it says to go online (G41, §24.12)", ok,
		"none %s, words %s, buttons %s, held %s, played %s" % [none, words, buttons, held, played])
	screen.queue_free()
	App.services = was
	s.close()
	await tree.process_frame


func _reconnect() -> void:
	var f := _services("reconnect")
	var s: Services = f[0]
	var transport: FakeTransport = f[1]
	s.outbox.put("t1", "/v1/heists/t1", PackedByteArray([1, 2, 3]))
	transport.on("POST /v1/session", {"account": "me", "token": "k"})
	transport.on("POST /v1/heists/t1", {"verdict": {"grade": "Clean"}, "haul": 100})
	var was: Services = App.services
	App.services = s
	var home: Control = await mount.call("home")
	for i in 20:
		await tree.process_frame
	var banners := home.find_children("Banner", "", true, false)
	var said := ""
	if not banners.is_empty():
		said = (banners[0].find_children("*", "Label", true, false)[0] as Label).text
	check.call("what was played offline is sent by itself when the network is back, and a banner says so "
			+ "(G41, §24.12)",
		s.outbox.pending() == 0 and said.contains(Strings.t("OFFLINE_SENT", 1)), "pending %d, said %s" % [
			s.outbox.pending(), said])
	home.queue_free()
	App.services = was
	s.close()
	await tree.process_frame


## The server's limit on how fast it is asked (G44): the session is kept, not
## asked for again each heist, and a sign-in held back is said as held back —
## not as a session refused, and not as offline.
func _held_back() -> void:
	var f := _services("held")
	var s: Services = f[0]
	var transport: FakeTransport = f[1]
	transport.on("POST /v1/session", {"account": "me", "token": "k"})
	var first := await s.session()
	var second := await s.session()
	var signed := transport.calls.filter(func(c: Dictionary) -> bool: return c["route"] == "POST /v1/session").size()
	check.call("the session is kept for its hour: a heist does not sign in again (G44)",
		first.ok and second.ok and str(second.value["account"]) == "me" and signed == 1, "signed in %d times" % signed)
	s.close()

	f = _services("held-sign-in")
	s = f[0]
	transport = f[1]
	transport.on("POST /v1/session", {"error": "too_many_requests", "retryAfter": 10}, 429)
	var balance := await s.api.get_json("/v1/balance")
	var asked := transport.calls.map(func(c: Dictionary) -> String: return c["route"])
	check.call("a sign-in the server holds back is the call's answer, with its wait, and the call is not sent "
			+ "without a session (G44)",
		balance.code == "too_many_requests" and int(balance.detail.get("retryAfter", 0)) == 10
			and asked == ["POST /v1/session"], "code %s, asked %s" % [balance.code, asked])
	var was: Services = App.services
	App.services = s
	s.heists.stock.add("b9", {"token": "t9", "seed": "7", "ticks": 4500, "expiresAt": 1}, PackedByteArray())
	s.store.dispatch(&"heist_started", {})
	var screen: HeistScreen = await mount.call("heist_screen")
	screen.set_process(false)
	for i in 10:
		await tree.process_frame
	var buttons: Array = screen.find_children("*", "Button", true, false).map(func(b: Button) -> String:
		return b.text)
	check.call("a heist the server holds back says so and offers to try again online, not to play offline (G44)",
		screen.hint_label.text == Errors.message("HEIST_NONE", "too_many_requests")
			and Strings.t("OFFLINE_TRY_AGAIN") in buttons and not Strings.t("OFFLINE_PLAY_ANYWAY") in buttons
			and not screen.playing,
		"words %s, buttons %s" % [screen.hint_label.text, buttons])
	screen.queue_free()
	App.services = was
	s.close()
	await tree.process_frame
