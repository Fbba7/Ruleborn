class_name Outbox
extends RefCounted
## §24.12's queue: "If offline, the result waits with its input log and a key
## made from the player, the token and the island". A heist's replay and a
## purchase's receipt are written here before they are sent and kept until
## the server has answered, so a phone that dies, or a train in a tunnel,
## loses nothing; the server answers a repeat from its first decision, so a
## retry can never pay twice.
##
## A failure the server decided (a 4xx: the lease expired, the replay did not
## reproduce) is an answer, and ends the item; one it never saw (no network,
## a timeout, a 5xx) keeps it for the next flush.

signal settled(key: String, result: Result)

const FILE := "user://outbox.json"

var path := FILE
var _items: Array[Dictionary] = []


func _init(p := FILE) -> void:
	path = p
	_read()


## Keep a request to send: `key` names it (a lease token, a store
## transaction); a second put with the same key is the same request.
func put(key: String, route: String, body: PackedByteArray, as_json := false) -> void:
	for item: Dictionary in _items:
		if item["key"] == key:
			return
	_items.append({"key": key, "route": route, "body": Marshalls.raw_to_base64(body), "json": as_json})
	_write()


## Keep a request and send it now with anything else waiting: the server's
## answer to it, or `{"pending": true}` when it waits for the network.
func send(api: Api, key: String, route: String, body: PackedByteArray) -> Result:
	put(key, route, body)
	var answered := {"result": null}
	var on_settled := func(k: String, r: Result) -> void:
		if k == key:
			answered["result"] = r
	settled.connect(on_settled)
	await flush(api)
	settled.disconnect(on_settled)
	if answered["result"] == null:
		return Result.success({"pending": true})
	return answered["result"]


## Let a kept request go unsent: one the player took back before the
## network returned.
func drop(key: String) -> void:
	_items = _items.filter(func(i: Dictionary) -> bool: return i["key"] != key)
	_write()


func pending() -> int:
	return _items.size()


func has(key: String) -> bool:
	return _items.any(func(i: Dictionary) -> bool: return i["key"] == key)


## Send everything waiting, oldest first. Returns how many were settled. One
## the server could not decide now stays, and the rest are still tried: a
## receipt is never held up behind a heist, nor a heist behind a receipt. With
## no network at all, the first failure ends the round.
func flush(api: Api) -> int:
	var done := 0
	for item: Dictionary in _items.duplicate():
		var body := Marshalls.base64_to_raw(item["body"])
		var r: Result
		if item["json"]:
			r = await api.post_json(item["route"], JSON.parse_string(body.get_string_from_utf8()))
		else:
			r = await _post_raw(api, item["route"], body)
		if not r.ok and transient(r):
			if r.code in ["offline", "unreachable", "timeout", "request_failed"]:
				break
			continue
		_items.erase(item)
		_write()
		done += 1
		settled.emit(item["key"], r)
	return done


func _post_raw(api: Api, route: String, body: PackedByteArray) -> Result:
	var r := await api.raw(HTTPClient.METHOD_POST, route, body)
	if not r.ok:
		return r
	var parsed: Variant = JSON.parse_string((r.value as PackedByteArray).get_string_from_utf8())
	return Result.success(parsed) if parsed is Dictionary else Result.failure("malformed_response")


## A failure the server never decided: try again later.
## A 5xx is one, whatever reason came with it: the server, or the store it
## asked, could not decide it now (D67's store_unavailable is a 503).
static func transient(r: Result) -> bool:
	# A session the server refused, or a limit on how fast it is asked,
	# decided nothing about the item itself.
	if r.code in ["offline", "unreachable", "timeout", "request_failed", "internal", "store_unavailable",
			"session_refused", "too_many_requests"]:
		return true
	return r.code.begins_with("status_5") or int(r.detail.get("status", 0)) >= 500


func _read() -> void:
	_items.clear()
	if not FileAccess.file_exists(path):
		return
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	if parsed is Array:
		for item: Variant in parsed:
			if item is Dictionary and item.has("key") and item.has("route") and item.has("body"):
				_items.append(item)


func _write() -> void:
	var f := FileAccess.open(path, FileAccess.WRITE)
	if f == null:
		push_error("could not write the outbox to %s" % path)
		return
	f.store_string(JSON.stringify(_items))
