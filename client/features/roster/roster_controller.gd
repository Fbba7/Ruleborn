class_name RosterController
extends RefCounted
## The roster with no screen: asks the home repository, dispatches the
## answer. A screen draws the store; leaving it mid-change loses nothing,
## since this lives on Services. Work sent while the network is away waits in
## the outbox (§24: "The device may … assign work offline, confirmed on
## reconnection"); spending Essence is online only, like every spend (G41).

## The outbox's keys for work the phone assigned offline.
const OFFLINE := "offline-work:"

var services: Services


func _init(s: Services) -> void:
	services = s


func _store() -> Store:
	return services.store


## The home fetched — but not over a change on its way, whose answer brings
## the home after it.
func load_roster() -> void:
	var slice: Dictionary = _store().get_slice(RosterState.ROSTER)
	if str(slice["busy"]) not in ["", "view"]:
		return
	var changes := int(slice["changes"])
	_store().dispatch(&"roster_asked")
	var r := await services.home.view()
	if r.ok:
		_store().dispatch(&"roster_loaded", {"view": r.value, "changes": changes})
	else:
		_store().dispatch(&"roster_failed", {"code": r.code, "detail": r.detail})


## §23.2's one-tap reassign: character `id`, named `name` in the words that
## follow, sent to building `n` of `kind` in `realm`.
func work(id: int, realm: String, kind: String, n: int, name: String) -> void:
	await _change("work:%d:%s:%s" % [id, realm, kind],
		{"do": "work", "name": name, "realm": realm, "kind": kind, "n": n},
		services.home.work.bind(id, realm, kind, n),
		{"do": "work", "character": id, "realm": realm, "kind": kind, "n": n})


## §11.4: the next level, for the Essence the home says.
func level(id: int, to: int) -> void:
	await _change("level:%d:%d" % [id, to], {"do": "level", "to": to}, services.home.level.bind(id, to))


## §11.6: back from a rest now, for the Essence the home says.
func wake(id: int) -> void:
	await _change("wake:%d" % id, {"do": "wake"}, services.home.wake.bind(id))


## §19.20's word lists, which a given name is read from, fetched once and
## kept where the Workshop keeps them; without them a name is its kind's.
func load_words() -> void:
	if not (_store().get_slice(WorkshopState.WORKSHOP)["words"] as Dictionary).is_empty():
		return
	var r := await services.social.words()
	if r.ok:
		_store().dispatch(&"workshop_words", {"words": r.value})


## §11.5: a birth at the Nursery in `realm`, the roster's next.
func hatch(realm: String) -> void:
	var n := (_store().get_slice(RosterState.ROSTER)["view"].get("characters", []) as Array).size() + 1
	await _change("birth:%s:%d" % [realm, n], {"do": "birth"}, services.home.birth.bind(realm, n))


## §11.5: a heist's stray taken in, or let go.
func take_stray(id: int) -> void:
	await _change("stray:%d" % id, {"do": "stray"}, services.home.take_stray.bind(id))


func decline_stray(id: int) -> void:
	await _change("decline:%d" % id, {"do": "decline"}, services.home.decline_stray.bind(id))


## §19.20: character `id` named from the word lists.
func name_character(id: int, adjective: int, noun: int) -> void:
	await _change("name:%d" % id, {"do": "name", "id": id, "adjective": adjective, "noun": noun},
		services.home.name_character.bind(id, adjective, noun))


## §9.3: every producer that holds something collected, one after another,
## each answer's home dispatched; the wallet asked afresh after. Returns what
## was paid in, by resource.
func collect_all() -> Dictionary:
	var paid := {}
	var home: Dictionary = _store().get_slice(RosterState.ROSTER).get("view", {})
	for p: Dictionary in home.get("producers", []):
		if int(p.get("stored", 0)) <= 0:
			continue
		var r: Result = await services.home.collect(str(p.get("realm", "")), str(p.get("kind", "")))
		if not r.ok:
			_store().dispatch(&"roster_failed", {"code": r.code, "detail": r.detail})
			break
		var got: Dictionary = r.value.get("collected", {})
		paid[str(got.get("resource", ""))] = int(paid.get(str(got.get("resource", "")), 0)) + int(got.get("paid", 0))
		_store().dispatch(&"roster_changed", {"home": r.value["home"], "what": {"collected": got}})
	if not paid.is_empty():
		await services.shop_flow.load_wallet()
	return paid


## One change at a time: a second tap while one is on its way is ignored.
func _change(key: String, what: Dictionary, call: Callable, offline := {}) -> void:
	if str(_store().get_slice(RosterState.ROSTER)["busy"]) != "":
		return
	_store().dispatch(&"roster_change_asked", {"key": key})
	var r: Result = await call.call()
	if not r.ok and not offline.is_empty() and r.code in UniverseController.NO_NETWORK:
		services.outbox.put(OFFLINE + key, "/v1/offline", JSON.stringify({"actions": [offline]}).to_utf8_buffer(), true)
		_store().dispatch(&"roster_queued", {"key": key, "what": what})
		return
	if not r.ok:
		_store().dispatch(&"roster_failed", {"code": r.code, "detail": r.detail})
		return
	var answer: Dictionary = r.value
	# What a birth or a stray brought: the newborn, and the first hatch's outfit.
	var made := what.duplicate()
	for k: String in ["born", "first", "outfit"]:
		if answer.has(k):
			made[k] = answer[k]
	_store().dispatch(&"roster_changed", {"home": answer["home"], "what": made,
		"repeated": answer.get("repeated", false)})


## The server's answer to work the phone assigned offline, when the outbox
## sends it: confirmed, with the home after it, or refused, and why.
func offline_settled(key: String, r: Result) -> void:
	if not key.begins_with(OFFLINE):
		return
	var k := key.trim_prefix(OFFLINE)
	if not r.ok:
		_store().dispatch(&"roster_answered", {"key": k, "refused": r.code, "detail": r.detail})
		return
	var answer: Dictionary = r.value
	var results: Array = answer.get("results", [])
	var one: Dictionary = results[0] if not results.is_empty() and results[0] is Dictionary else {}
	_store().dispatch(&"roster_answered", {"key": k, "home": answer.get("home"),
		"refused": str(one.get("refused", "")), "detail": one.get("detail", {})})
