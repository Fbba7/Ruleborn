class_name FixTraceEventsTests
extends RefCounted
## The November bug report's Trace and device-event defects (FX4-2): a Trace
## whose island is also offered as a target (RB-31), a refused event batch
## that blocks the queue (RB-32), a sign-in that renews a fresh token every
## time (RB-41), and overlapping event sends (RB-42).

const MINUTE := 60 * 1000
const DAY := 24 * 60 * MINUTE

var tree: SceneTree
var check: Callable


## POST /v1/events as server/src/telemetry.mjs `batch` answers it: more than
## 100 events refused 413, an event dated in the future or more than seven
## days back refused 400 — the whole batch either way — else every event
## recorded. `refuse` answers every batch with that status instead; `slow`
## answers that many frames late, as a slow network does.
class EventsServer:
	extends FakeTransport
	var recorded: Array = []
	var refuse := 0
	var slow := 0

	func send(method: HTTPClient.Method, url: String, headers: PackedStringArray,
			body: PackedByteArray) -> Dictionary:
		var path := ("/" + url.split("/", false, 2)[2] if url.contains("://") else url).get_slice("?", 0)
		if method != HTTPClient.METHOD_POST or path != "/v1/events":
			return await super.send(method, url, headers, body)
		calls.append({"route": "POST /v1/events", "url": path, "headers": headers, "body": body})
		for i in slow + 1:
			await (Engine.get_main_loop() as SceneTree).process_frame
		if offline:
			return {"error": "unreachable"}
		var events: Array = JSON.parse_string(body.get_string_from_utf8())
		if refuse > 0:
			return _answer(refuse, {"error": "too_many_events"})
		if events.size() > 100:
			return _answer(413, {"error": "batch_too_large", "most": 100})
		var now := int(Time.get_unix_time_from_system() * 1000)
		for i in events.size():
			var at := int(events[i]["at"])
			if at > now or at < now - 7 * DAY:
				return _answer(400, {"error": "bad_time", "index": i})
		recorded.append_array(events)
		return _answer(202, {"recorded": events.size()})

	static func _answer(status: int, said: Dictionary) -> Dictionary:
		return {"status": status, "body": JSON.stringify(said).to_utf8_buffer()}


func _init(t: SceneTree, c: Callable) -> void:
	tree = t
	check = c


func run() -> void:
	await _trace_preferred_when_its_island_is_offered()
	await _refused_batches_do_not_block_the_queue()
	await _sign_in_keeps_a_fresh_token()
	await _overlapping_sends_send_each_event_once()


func _services(name: String, transport: FakeTransport) -> Services:
	var outbox := "user://outbox-fix2-%s-test.json" % name
	for suffix: String in ["", "-auth", "-leases", "-notices"]:
		DirAccess.remove_absolute(outbox.get_basename() + suffix + ".json")
	var s := Fixtures.answered(Services.build(tree.root, "https://edge.example", transport, outbox))
	s.router.change = func(_path: String) -> void: pass
	return s


func _notices(name: String) -> DeviceNotices:
	var path := "user://notices-fix2-%s-test.json" % name
	DirAccess.remove_absolute(path)
	return DeviceNotices.new(path)


static func _now() -> int:
	return int(Time.get_unix_time_from_system() * 1000)


## The `at` of every event posted, in the order posted: an event's `at` is
## its name here, each one different.
static func _posted(t: FakeTransport) -> Array[int]:
	var out: Array[int] = []
	for c: Dictionary in t.calls:
		if c["route"] == "POST /v1/events":
			for e: Variant in JSON.parse_string((c["body"] as PackedByteArray).get_string_from_utf8()):
				out.append(int(e["at"]))
	return out


static func _sizes(t: FakeTransport) -> Array[int]:
	var out: Array[int] = []
	for c: Dictionary in t.calls:
		if c["route"] == "POST /v1/events":
			out.append((JSON.parse_string((c["body"] as PackedByteArray).get_string_from_utf8()) as Array).size())
	return out


## RB-31: the raider's island is also among the defender's offered targets.
## Tapping the Trace opens the scout report on the Trace, free, and its Plan
## opens the planner on the Trace, which leases it as one (trace_of set, no
## fee), not on the paid target with the same bundle.
func _trace_preferred_when_its_island_is_offered() -> void:
	var transport := FakeTransport.new()
	var s := _services("rb31", transport)
	s.api.token = "t"
	var view := ObservatoryTests.sample()
	(view["targets"] as Array).append(ObservatoryTests._card("t1", "player", {"fee": 100}))
	transport.on("GET /v1/observatory", view)
	await s.observatory_flow.load_observatory()
	s.observatory_flow.choose("t1")
	var report := ObservatoryPresenter.scout(s.store.get_slice(ObservatoryState.OBSERVATORY))
	var card: Dictionary = report.get("card", {})
	s.observatory_flow.raid(card)
	var planned: Dictionary = s.store.get_slice(PlannerState.PLANNER)["target"]
	check.call("RB-31: a Trace whose island is also offered as a target opens as the Trace, free, and its Plan "
			+ "leases it as a Trace, not as the paid target with the same bundle",
		report.get("ready", false) and card.get("kind") == "trace" and int(card.get("fee", -1)) == 0
			and planned.get("kind") == "trace" and planned.get("bundle") == "t1",
		"scout card kind %s fee %s, planner target kind %s" % [card.get("kind"), card.get("fee"),
			planned.get("kind")])
	s.close()


## RB-32: a batch the server refuses for good — 413 over 100 events, 400 for
## an event more than seven days old — no longer blocks the queue: events go
## in chunks of at most 100, those older than the server takes are let go,
## and a chunk refused for good is dropped. A refusal that may pass later
## (429, offline) keeps the events for the next time.
func _refused_batches_do_not_block_the_queue() -> void:
	var now := _now()
	# About 60 offline sessions: 120 events.
	var many := EventsServer.new()
	var s := _services("rb32-many", many)
	s.api.token = "t"
	s.notices = _notices("rb32-many")
	for i in 60:
		s.notices.start(now - 3 * DAY + i * 2 * MINUTE)
		s.notices.stop(now - 3 * DAY + i * 2 * MINUTE + MINUTE)
	for i in 3:
		await s.send_events()
	var many_left := s.notices.pending().size()
	var many_sizes := _sizes(many)
	var many_recorded := many.recorded.size()
	s.close()
	# Killed, and back eight days later: the crashed session is ended with
	# its old date.
	var late := EventsServer.new()
	var t := _services("rb32-late", late)
	t.api.token = "t"
	t.notices = _notices("rb32-late")
	t.notices.start(now - 8 * DAY)
	t.notices = DeviceNotices.new(t.notices.path)
	t.notices.start(now)
	for i in 3:
		await t.send_events()
	var late_left := t.notices.pending().size()
	var fresh_recorded := late.recorded.any(func(e: Dictionary) -> bool: return int(e["at"]) == now)
	t.close()
	# A refusal that may pass later keeps the events.
	var busy := EventsServer.new()
	var u := _services("rb32-busy", busy)
	u.api.token = "t"
	u.notices = _notices("rb32-busy")
	u.notices.start(now - MINUTE)
	u.notices.stop(now)
	busy.refuse = 429
	await u.send_events()
	var kept_429 := u.notices.pending().size()
	busy.refuse = 0
	busy.offline = true
	await u.send_events()
	var kept_offline := u.notices.pending().size()
	u.close()
	check.call("RB-32: a queue the server refuses for good drains — 120 events go in chunks of at most 100, an "
			+ "event eight days old is let go and the fresh one still reaches the server — while a 429 or no "
			+ "network keeps the events for the next time",
		many_left == 0 and many_recorded == 120 and many_sizes.all(func(n: int) -> bool: return n <= 100)
			and late_left == 0 and fresh_recorded and kept_429 == 2 and kept_offline == 2,
		"120 events: batches %s, recorded %d, left %d; eight days late: left %d, fresh one recorded %s; "
			% [many_sizes, many_recorded, many_left, late_left, fresh_recorded]
			+ "kept after 429 %d, after offline %d" % [kept_429, kept_offline])


## RB-41: home calls sign_in on each visit while the outbox holds an item.
## A fresh token is kept: no renewal per visit, which the server limits.
func _sign_in_keeps_a_fresh_token() -> void:
	var transport := FakeTransport.new()
	var s := FixTransportTests.new(tree, check)._fake("rb41", transport)
	var first := await s.session()
	var token := s.api.token
	var visits: Array[bool] = []
	for i in 3:
		visits.append(await s.sign_in())
	var renewals := transport.calls.filter(func(c: Dictionary) -> bool:
		return c["route"] == "POST /v1/session/refresh").size()
	check.call("RB-41: signing in while the token is still fresh keeps it, with no renewal on each visit",
		first.ok and visits == [true, true, true] and renewals == 0 and s.api.token == token,
		"visits %s, renewals %d, token kept %s" % [visits, renewals, s.api.token == token])
	s.close()


## RB-42: the app is paused while a send is in flight, quickly resumed, and
## paused again. Each event is sent once, and none is let go unsent.
func _overlapping_sends_send_each_event_once() -> void:
	var now := _now()
	var server := EventsServer.new()
	server.slow = 3
	var s := _services("rb42", server)
	s.api.token = "t"
	s.notices = _notices("rb42")
	s.notices.start(now - 4 * MINUTE)
	s.notices.stop(now - 3 * MINUTE)
	var done: Array[int] = [0]
	var send := func() -> void:
		await s.send_events()
		done[0] += 1
	send.call()
	s.notices.start(now - 2 * MINUTE)
	send.call()
	s.notices.stop(now - MINUTE)
	await FixTransportTests._until(func() -> bool: return done[0] == 2)
	await s.send_events()
	var posted := _posted(server)
	var each := [now - 4 * MINUTE, now - 3 * MINUTE, now - 2 * MINUTE, now - MINUTE]
	var counts := each.map(func(at: int) -> int: return posted.count(at))
	check.call("RB-42: overlapping event sends post each event once, and none is let go unsent",
		counts == [1, 1, 1, 1] and s.notices.pending().is_empty(),
		"times each event was posted %s, left %d" % [counts, s.notices.pending().size()])
	s.close()
