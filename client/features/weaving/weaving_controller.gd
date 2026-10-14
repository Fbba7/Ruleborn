class_name WeavingController
extends RefCounted
## Weaving with no screen: asks the repository and dispatches the answer. A
## screen draws the store; leaving it mid-weave loses nothing, since this
## lives on Services. A weave or an unweave sent while the network is away
## waits in the outbox (§24: "The device may build, weave and assign work
## offline, confirmed on reconnection"), and the server prices it then.

## The outbox's keys for what the phone wove offline.
const OFFLINE := "offline-weave:"

var services: Services


func _init(s: Services) -> void:
	services = s


func _store() -> Store:
	return services.store


## What is woven, fetched — but not over a change on its way, whose answer
## brings the view after it.
func load_weaving() -> void:
	var slice: Dictionary = _store().get_slice(WeavingState.WEAVING)
	if str(slice["busy"]) not in ["", "view"]:
		return
	var changes := int(slice["changes"])
	_store().dispatch(&"weaving_asked")
	var r := await services.weaving.view()
	if r.ok:
		_store().dispatch(&"weaving_loaded", {"view": r.value, "changes": changes})
	else:
		_store().dispatch(&"weaving_failed", {"code": r.code, "detail": r.detail})


## §5.6: `law` woven into slot `slot` of `realm`.
func weave(realm: String, slot: int, law: String) -> void:
	await _change("weave:%s:%s" % [realm, law], {"do": "weave", "realm": realm, "law": law},
		services.weaving.weave.bind(realm, slot, law),
		{"do": "weave", "realm": realm, "slot": slot, "law": law})


## §5.6: slot `slot` of `realm` emptied; it rests an hour.
func unweave(realm: String, slot: int) -> void:
	await _change("unweave:%s:%d" % [realm, slot], {"do": "unweave", "realm": realm},
		services.weaving.unweave.bind(realm, slot), {"do": "unweave", "realm": realm, "slot": slot})


## One change at a time: a second tap while one is on its way is ignored.
func _change(key: String, what: Dictionary, call: Callable, offline: Dictionary) -> void:
	if str(_store().get_slice(WeavingState.WEAVING)["busy"]) != "":
		return
	_store().dispatch(&"weave_asked", {"key": key})
	var r: Result = await call.call()
	if not r.ok and r.code in UniverseController.NO_NETWORK:
		services.outbox.put(OFFLINE + key, "/v1/offline", JSON.stringify({"actions": [offline]}).to_utf8_buffer(), true)
		_store().dispatch(&"weave_queued", {"key": key, "what": what})
		return
	if not r.ok:
		_store().dispatch(&"weaving_failed", {"code": r.code, "detail": r.detail})
		return
	_store().dispatch(&"weave_made", {"view": r.value["weaving"], "what": what})


## The server's answer to a weave the phone kept, when the outbox sends it:
## confirmed, with what is woven after it, or refused, and why.
func offline_settled(key: String, r: Result) -> void:
	if not key.begins_with(OFFLINE):
		return
	var k := key.trim_prefix(OFFLINE)
	if not r.ok:
		_store().dispatch(&"weave_answered", {"key": k, "refused": r.code, "detail": r.detail})
		return
	var answer: Dictionary = r.value
	var results: Array = answer.get("results", [])
	var one: Dictionary = results[0] if not results.is_empty() and results[0] is Dictionary else {}
	_store().dispatch(&"weave_answered", {"key": k, "view": answer.get("weaving"),
		"refused": str(one.get("refused", "")), "detail": one.get("detail", {})})
