class_name NoticesTests
extends RefCounted
## The device's own notices and sessions (§14.6, §20.2, §24; TD.74): the push
## permission at the third session, the storage-full timer out of the night,
## and the session events, through a FakeLocalNotifier and a FakeTransport.

const HOUR := 60 * 60 * 1000
## 2026-10-12 00:00 UTC, a Monday: a fixed clock for the night's arithmetic.
const MIDNIGHT := 1791763200000

var tree: SceneTree
var check: Callable


func _init(t: SceneTree, c: Callable) -> void:
	tree = t
	check = c


func run() -> void:
	_permission()
	_storage_full()
	_rested()
	_sessions()
	await _foreground()


func _file(name: String) -> String:
	var path := "user://notices-%s-test.json" % name
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(path)
	return path


func _permission() -> void:
	var path := _file("permission")
	var notifier := FakeLocalNotifier.new()
	var asked_at: Array[int] = []
	for i in 5:
		var n := DeviceNotices.new(path)   # a launch reads what the last kept
		n.start(MIDNIGHT + i * HOUR)
		if n.should_ask():
			notifier.ask_permission()
			n.mark_asked()
			asked_at.append(n.sessions)
		n.stop(MIDNIGHT + i * HOUR + 60_000)
	check.call("the push permission is asked at the start of the third session, once, and kept across launches (TD.74)",
		asked_at == [3] and notifier.asked == 1 and DeviceNotices.new(path).asked,
		"%s, asked %d" % [asked_at, notifier.asked])


func _storage_full() -> void:
	var at := func(h: float) -> int: return MIDNIGHT + int(h * HOUR)
	var home := {"night": [22, 8], "producers": [
		{"kind": "garden", "full_at": at.call(15.0)},
		{"kind": "star_well", "full_at": at.call(14.5)},
		{"kind": "aether_spring", "full_at": null}]}
	var day := DeviceNotices.storage_full_at(home, 0)
	home["producers"][1]["full_at"] = at.call(23.0)
	home["producers"][0]["full_at"] = at.call(26.0)        # 02:00 the next day
	var night := DeviceNotices.storage_full_at(home, 0)
	# São Paulo, three hours behind: 23:00 UTC is 20:00 there, before its night.
	var west := DeviceNotices.storage_full_at(home, -180)
	var opened := DeviceNotices.storage_full_at({"night": null, "producers": home["producers"]}, 0)
	var notifier := FakeLocalNotifier.new()
	DeviceNotices.apply(notifier, home, 0)
	var without := notifier.timers.duplicate()
	notifier.ask_permission()
	DeviceNotices.apply(notifier, home, 0)
	var kept: Dictionary = notifier.timers.get(DeviceNotices.STORAGE_FULL, {})
	DeviceNotices.apply(notifier, {"night": [22, 8], "producers": [{"full_at": null}]}, 0)
	check.call("the storage-full notice is set for the first producer to fill, moved out of the night to its end, "
			+ "and taken away when nothing will fill (14.6, 20.2)",
		day == at.call(14.5) and night == at.call(32.0) and west == at.call(23.0) and opened == at.call(23.0)
			and without.is_empty() and kept.get("at") == at.call(32.0)
			and kept.get("title") == "ruleborn_storage_full_title" and notifier.timers.is_empty(),
		"%d %d %d %d %s %s" % [day, night, west, opened, without, kept])


## §14.6's "a character rested": the first rest the home names to end,
## moved out of the night, and taken away once nobody rests (§11.6).
func _rested() -> void:
	var at := func(h: float) -> int: return MIDNIGHT + int(h * HOUR)
	var home := {"night": [22, 8], "characters": [
		{"kind": "featherkin", "state": "resting", "resting_until": at.call(13.0)},
		{"kind": "emberling", "state": "resting", "resting_until": at.call(12.5)},
		{"kind": "tidewalker", "state": "idle"}]}
	var day := DeviceNotices.rested_at(home, 0)
	home["characters"][1]["resting_until"] = at.call(23.5)
	home["characters"][0]["resting_until"] = at.call(24.5)
	var night := DeviceNotices.rested_at(home, 0)
	var notifier := FakeLocalNotifier.new()
	notifier.ask_permission()
	DeviceNotices.apply(notifier, home, 0)
	var kept: Dictionary = notifier.timers.get(DeviceNotices.RESTED, {})
	DeviceNotices.apply(notifier, {"night": [22, 8], "characters": [{"state": "idle"}]}, 0)
	check.call("the rested notice is set for the first character whose rest ends, moved out of the night, "
			+ "and taken away once nobody rests (14.6, 11.6)",
		day == at.call(12.5) and night == at.call(32.0) and kept.get("at") == at.call(32.0)
			and kept.get("title") == "ruleborn_rested_title" and not notifier.timers.has(DeviceNotices.RESTED),
		"%d %d %s %s" % [day, night, kept, notifier.timers])


func _sessions() -> void:
	var path := _file("sessions")
	var n := DeviceNotices.new(path)
	n.start(MIDNIGHT)
	n.stop(MIDNIGHT + 90_000)
	n.start(MIDNIGHT + HOUR)
	n.seen(MIDNIGHT + HOUR + 30_000)
	# Killed without going to the background: the next launch ends it.
	var relaunch := DeviceNotices.new(path)
	relaunch.start(MIDNIGHT + 2 * HOUR)
	var got := relaunch.pending()
	relaunch.sent(2)
	var left := DeviceNotices.new(path).pending()
	var kinds := got.map(func(e: Dictionary) -> String: return e["kind"])
	check.call("a session's start and end are kept with its seconds, a session the app never closed is ended at the "
			+ "next launch as crashed, and what was sent is let go (24)",
		kinds == ["session_start", "session_end", "session_start", "session_end", "session_start"]
			and got[1]["data"] == {"seconds": 90, "crashed": false} and got[3]["data"] == {"seconds": 30, "crashed": true}
			and got[3]["at"] is int and left.size() == 3 and left[0]["kind"] == "session_start",
		"%s | %s" % [got, left])


func _foreground() -> void:
	var transport := FakeTransport.new()
	var s := Fixtures.answered(Services.build(tree.root, "https://edge.example", transport,
		"user://outbox-notices-test.json"))
	var notifier := FakeLocalNotifier.new()
	s.notifier = notifier
	s.notices = DeviceNotices.new(_file("foreground"))
	s.api.token = "t"
	s.store.dispatch(&"signed_in", {"account": "acc1"})
	var full := int(Time.get_unix_time_from_system() * 1000) + 3 * HOUR
	transport.on("PUT /v1/notifications", {"timeZone": "America/Sao_Paulo"})
	transport.on("POST /v1/events", {"recorded": 1}, 202)
	transport.on("GET /v1/home", {"night": null, "producers": [{"kind": "garden", "full_at": full}]})
	transport.offline = true
	await s.foreground()
	var waited := s.notices.pending().size()
	transport.offline = false
	await s.foreground()
	await s.foreground()
	var routes := transport.calls.map(func(c: Dictionary) -> String: return c["route"])
	var told: Variant = null
	var batches: Array[int] = []   # every batch tried, the offline one first
	for c: Dictionary in transport.calls:
		var body: Variant = JSON.parse_string((c["body"] as PackedByteArray).get_string_from_utf8())
		if c["route"] == "PUT /v1/notifications" and told == null:
			told = body
		if c["route"] == "POST /v1/events":
			batches.append((body as Array).size())
	var timer: Dictionary = notifier.timers.get(DeviceNotices.STORAGE_FULL, {})
	check.call("on coming to the foreground the device tells the server its time zone and, once it may notify, its "
			+ "push token, sends its session events — those kept offline too — and sets its storage-full timer from "
			+ "the home (G34, 14.6, 24)",
		waited == 1 and routes.has("GET /v1/home") and told is Dictionary
			and told.get("timeZone") == "America/Sao_Paulo" and not (told as Dictionary).has("pushToken")
			and batches == [1, 3, 2] and notifier.asked == 1
			and timer.get("at") == full and s.notices.pending().is_empty()
			and _last_body(transport, "PUT /v1/notifications").get("pushToken") == "device-token",
		"%s | %s | %s | %s" % [routes, told, batches, timer])
	s.close()


func _last_body(transport: FakeTransport, route: String) -> Dictionary:
	for i in range(transport.calls.size() - 1, -1, -1):
		var c: Dictionary = transport.calls[i]
		if c["route"] == route:
			var parsed: Variant = JSON.parse_string((c["body"] as PackedByteArray).get_string_from_utf8())
			return parsed if parsed is Dictionary else {}
	return {}
