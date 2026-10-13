class_name UniverseController
extends RefCounted
## The universe with no screen: asks the repository, dispatches the answer,
## and moves the Keeper bar with the experience a purchase earned (§14.2). A
## screen draws the store; leaving it mid-purchase loses nothing, since this
## lives on Services.

## The outbox's keys for what the phone built offline.
const OFFLINE := "offline:"
## Failures that mean the server never heard: the purchase can wait for it.
const NO_NETWORK := ["offline", "unreachable", "timeout", "request_failed"]

var services: Services


func _init(s: Services) -> void:
	services = s


func _store() -> Store:
	return services.store


## The universe fetched — but not over a purchase on its way, whose answer
## brings the universe after it.
func load_universe() -> void:
	var slice: Dictionary = _store().get_slice(UniverseState.UNIVERSE)
	if str(slice["busy"]) not in ["", "view"]:
		return
	var purchases := int(slice["purchases"])
	_store().dispatch(&"universe_asked")
	var r := await services.universe.view()
	if r.ok:
		_store().dispatch(&"universe_loaded", {"view": r.value, "purchases": purchases})
	else:
		_store().dispatch(&"universe_failed", {"code": r.code, "detail": r.detail})


## §5.2: the next outer realm, of `type`.
func open_realm(type: String) -> void:
	await _buy("open:" + type, {"realm": type}, services.universe.open_realm.bind(type))


## §5.2: `realm` raised to level `to`.
func raise_realm(realm: String, to: int) -> void:
	await _buy("raise:%s:%d" % [realm, to], {"raise": realm, "to": to}, services.universe.raise_realm.bind(realm, to))


## §10.2: building `n` of `kind` in `realm` to level `to`. One the network
## does not reach waits to be confirmed (§24).
func build(realm: String, kind: String, n: int, to: int) -> void:
	await _buy("build:%s:%s:%d:%d" % [realm, kind, n, to], {"kind": kind, "n": n, "to": to},
		services.universe.build.bind(realm, kind, n, to),
		{"do": "build", "realm": realm, "kind": kind, "n": n, "to": to})


## One purchase at a time: a second tap while one is on its way is ignored.
## §24 lets the device build offline, confirmed on reconnection: a purchase
## that names an `offline` action and finds no network is kept in the outbox
## for POST /v1/offline, which the server makes in order and answers one by
## one; anything else waits for the server.
func _buy(key: String, what: Dictionary, call: Callable, offline := {}) -> void:
	if str(_store().get_slice(UniverseState.UNIVERSE)["busy"]) != "":
		return
	_store().dispatch(&"purchase_asked", {"key": key})
	var r: Result = await call.call()
	if not r.ok and not offline.is_empty() and r.code in NO_NETWORK:
		services.outbox.put(OFFLINE + key, "/v1/offline", JSON.stringify({"actions": [offline]}).to_utf8_buffer(), true)
		_store().dispatch(&"purchase_queued", {"key": key, "what": what})
		return
	if not r.ok:
		_store().dispatch(&"universe_failed", {"code": r.code, "detail": r.detail})
		return
	var answer: Dictionary = r.value
	_store().dispatch(&"purchase_made", {"universe": answer["universe"], "what": what,
		"keeper": answer.get("keeper"), "repeated": answer.get("repeated", false)})
	if answer.get("keeper") is Dictionary:
		_store().dispatch(&"keeper_earned", {"keeper": answer["keeper"]})


## The server's answer to something the phone built offline, when the outbox
## sends it: confirmed or refused, with the universe after it, and the
## Keeper experience it earned (§14.2).
func offline_settled(key: String, r: Result) -> void:
	if not key.begins_with(OFFLINE):
		return
	var k := key.trim_prefix(OFFLINE)
	if not r.ok:
		_store().dispatch(&"offline_answered", {"key": k, "refused": r.code, "detail": r.detail})
		return
	var answer: Dictionary = r.value
	var results: Array = answer.get("results", [])
	var one: Dictionary = results[0] if not results.is_empty() and results[0] is Dictionary else {}
	_store().dispatch(&"offline_answered", {"key": k, "universe": answer.get("universe"),
		"refused": str(one.get("refused", "")), "detail": one.get("detail", {})})
	if one.get("keeper") is Dictionary:
		_store().dispatch(&"keeper_earned", {"keeper": one["keeper"]})
