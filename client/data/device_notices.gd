class_name DeviceNotices
extends RefCounted
## What the device keeps for itself between launches (§14.6, §20.2, §24):
## how many sessions there have been, whether the push permission has been
## asked, the session open now, and the session events not yet sent.
##
## §14.6: "Notifications: only for things the player can act on (storage
## full, a character rested, an experiment finished, a heist against you)."
## The heist is the server's push; storage full is this device's own timer,
## set from the home the server keeps (each producer's `full_at`) and moved
## out of §20.2's night to its end. The permission is asked at the start of
## the third session, not the first (TD.74), and once.
##
## A session runs from the app coming to the foreground to its going
## (`session_start`, `session_end` with its seconds). A session the app never
## closed — it was killed, or crashed — is ended at the next launch, as long
## as it was last seen, and marked crashed.

const FILE := "user://notices.json"
const ASK_AT_SESSION := 3
const STORAGE_FULL := "storage_full"
const RESTED := "rested"
const EXPERIMENT := "experiment"
const MINUTE_MS := 60 * 1000
const DAY_MS := 24 * 60 * MINUTE_MS

var path := FILE
var sessions := 0
var asked := false
var _open_since := 0
var _seen := 0
var _pending: Array = []


func _init(p := FILE) -> void:
	path = p
	_read()


## The app came to the foreground at `now` (unix ms).
func start(now: int) -> void:
	if _open_since > 0:
		_end(maxi(_seen, _open_since), true)
	sessions += 1
	_open_since = now
	_seen = now
	_pending.append({"kind": "session_start", "data": {}, "at": now})
	_write()


## The app is still open at `now`: the time a crashed session is ended at.
func seen(now: int) -> void:
	if _open_since > 0:
		_seen = now
		_write()


## The app went to the background at `now`.
func stop(now: int) -> void:
	if _open_since > 0:
		_end(now, false)
		_write()


func _end(at: int, crashed: bool) -> void:
	_pending.append({"kind": "session_end",
		"data": {"seconds": maxi(0, (at - _open_since) / 1000), "crashed": crashed}, "at": at})
	_open_since = 0
	_seen = 0


## The events not yet sent, oldest first.
func pending() -> Array:
	return _pending.duplicate(true)


## The first `n` pending events reached the server.
func sent(n: int) -> void:
	_pending = _pending.slice(n)
	_write()


## Whether to ask for the push permission now: from the third session, once.
func should_ask() -> bool:
	return sessions >= ASK_AT_SESSION and not asked


func mark_asked() -> void:
	asked = true
	_write()


## When the storage-full notice is due: the first producer to fill, moved to
## the end of the player's `night` ([from, to] o'clock, or null for none) in
## their local time, `bias` minutes from UTC; 0 when none will fill.
static func storage_full_at(home: Dictionary, bias: int) -> int:
	var at := 0
	for p: Variant in home.get("producers", []):
		var full: Variant = (p as Dictionary).get("full_at")
		if full != null and (at == 0 or int(full) < at):
			at = int(full)
	if at == 0:
		return 0
	return out_of_night(at, home.get("night"), bias)


## When the first character resting ends its rest (§11.6), from the home
## the server answers, moved out of the night; 0 when nobody rests.
static func rested_at(home: Dictionary, bias: int) -> int:
	var at := 0
	for c: Variant in home.get("characters", []):
		var until: Variant = (c as Dictionary).get("resting_until")
		if until != null and (at == 0 or int(until) < at):
			at = int(until)
	if at == 0:
		return 0
	return out_of_night(at, home.get("night"), bias)


## When the first experiment running in the Lab finishes (§8.6), from the
## home the server answers, moved out of the night; 0 when none runs.
static func experiment_at(home: Dictionary, bias: int) -> int:
	var at := 0
	for e: Variant in home.get("experiments", []):
		var ready: Variant = (e as Dictionary).get("ready_at")
		if ready != null and (at == 0 or int(ready) < at):
			at = int(ready)
	if at == 0:
		return 0
	return out_of_night(at, home.get("night"), bias)


## `at` (unix ms), or the end of the night it falls in.
static func out_of_night(at: int, night: Variant, bias: int) -> int:
	if not (night is Array) or (night as Array).size() != 2:
		return at
	var from := int(night[0]) * 60 * MINUTE_MS
	var to := int(night[1]) * 60 * MINUTE_MS
	var local := posmod(at + bias * MINUTE_MS, DAY_MS)
	var inside := (local >= from or local < to) if from > to else (local >= from and local < to)
	if not inside:
		return at
	return at + posmod(to - local, DAY_MS)


## §14.6's timers set on `notifier` from `home` — storage full, a
## character rested and an experiment finished — each taken away when
## nothing will happen, and nothing set without the permission.
static func apply(notifier: LocalNotifier, home: Dictionary, bias: int) -> void:
	_timer(notifier, STORAGE_FULL, storage_full_at(home, bias))
	_timer(notifier, RESTED, rested_at(home, bias))
	_timer(notifier, EXPERIMENT, experiment_at(home, bias))


static func _timer(notifier: LocalNotifier, id: String, at: int) -> void:
	if at == 0 or not notifier.permitted():
		notifier.cancel(id)
		return
	notifier.schedule(id, at, "ruleborn_%s_title" % id, "ruleborn_%s_body" % id)


func _read() -> void:
	if not FileAccess.file_exists(path):
		return
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	if not (parsed is Dictionary):
		return
	var d: Dictionary = parsed
	sessions = int(d.get("sessions", 0))
	asked = bool(d.get("asked", false))
	_open_since = int(d.get("open_since", 0))
	_seen = int(d.get("seen", 0))
	# JSON reads every number back as a float; the server takes whole ones.
	_pending = []
	var p: Variant = d.get("pending", [])
	for e: Variant in (p as Array) if p is Array else []:
		if not (e is Dictionary):
			continue
		var data: Dictionary = (e as Dictionary).get("data", {})
		if data.has("seconds"):
			data["seconds"] = int(data["seconds"])
		_pending.append({"kind": str(e["kind"]), "data": data, "at": int(e["at"])})


func _write() -> void:
	var f := FileAccess.open(path, FileAccess.WRITE)
	if f == null:
		push_error("could not keep the device's notices in %s" % path)
		return
	f.store_string(JSON.stringify({"sessions": sessions, "asked": asked, "open_since": _open_since,
		"seen": _seen, "pending": _pending}))
