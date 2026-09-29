class_name WorkshopController
extends RefCounted
## The Island Workshop with no screen: browsing, publishing, playing, rating,
## reporting, remixing and withdrawing, each asked of the repository and its
## answer dispatched. It lives on Services, so a publication or a rating in
## flight goes on when the player leaves the screen; a play is started by the
## screen that asked, only if the player is still there. The heist screen
## submits the play through here when the clock runs out.

var services: Services
var _asked := 0


func _init(s: Services) -> void:
	services = s


## "top", "new", "featured", or "mine" for the player's own. A player aged 13
## to 15 is refused all but the featured list (§20.7), and is shown it.
func show_list(list: String) -> void:
	_store().dispatch(&"workshop_asked")
	await _list(list)


## §20.11: the terms of use, as the server holds them for the player.
func load_terms() -> void:
	var r := await services.account.terms()
	if r.ok:
		_store().dispatch(&"workshop_terms", {"terms": r.value})


## The current terms accepted, which opens publishing, playing, rating and
## remixing (reporting never waits for them). True once the server has it.
func accept_terms() -> bool:
	var terms: Dictionary = _store().get_slice(WorkshopState.WORKSHOP)["terms"]
	if terms.is_empty():
		await load_terms()
		terms = _store().get_slice(WorkshopState.WORKSHOP)["terms"]
		if terms.is_empty():
			return false
	_store().dispatch(&"workshop_asked")
	var r := await services.account.accept_terms(str(terms["version"]))
	if not r.ok:
		_fail(r.code)
		# Refused as old: the server has newer terms, to be read first.
		await load_terms()
		return false
	_store().dispatch(&"workshop_terms", {"terms": r.value})
	_store().dispatch(&"workshop_done", {"what": "terms", "answer": r.value})
	return true


## §17.8: a creator blocked, and the list on show asked again without them.
func block(account: String) -> void:
	_store().dispatch(&"workshop_asked")
	var r := await services.account.block(account)
	if not r.ok:
		_fail(r.code)
		return
	_store().dispatch(&"workshop_done", {"what": "blocked", "answer": r.value})
	await _list(str(_store().get_slice(WorkshopState.WORKSHOP)["list"]), true)


func load_words() -> void:
	var r := await services.social.words()
	if r.ok:
		_store().dispatch(&"workshop_words", {"words": r.value})
	else:
		_fail(r.code)


## §18.6: publish the island the player has just cleared, with that clear,
## named from the word lists; a remix names its original (Draft). An original
## removed since cannot be named, so the island is published as the player's
## own. An answer that comes after the player has moved on to another
## rehearsal, or another remix, marks neither.
func publish(bundle: PackedByteArray, replay: PackedByteArray, adjective: int, noun: int) -> bool:
	_store().dispatch(&"workshop_asked")
	var origin := Draft.remix_of()
	var r := await _repo().publish(bundle, replay, adjective, noun, origin)
	if not r.ok and r.code == "no_such_island" and origin != "":
		Draft.forget_origin()
		origin = ""
		r = await _repo().publish(bundle, replay, adjective, noun)
	if not r.ok:
		_fail(r.code)
		return false
	if Draft.remix_of() == origin:
		Draft.forget_origin()
	if _store().get_slice(AppState.HEIST)["replay"] == replay:
		_store().dispatch(&"heist_published")
	_store().dispatch(&"workshop_done", {"what": "published", "answer": r.value})
	await _list("mine", true)
	return true


## Fetch an island on the list to play: the heist it starts, for `start`, or
## {} when it could not be had. The caller starts it only if the player is
## still where they asked, so a slow answer never replaces a heist begun since.
func play(id: String) -> Dictionary:
	var item := _item(id)
	_store().dispatch(&"workshop_asked")
	var r := await _repo().play(id)
	if not r.ok:
		_fail(r.code)
		return {}
	var b := await services.heists.fetch(str(r.value["bundle"]))
	if not b.ok:
		_fail(b.code)
		return {}
	_store().dispatch(&"workshop_playing", {"item": item if not item.is_empty() else {"id": id}})
	return {"island": b.value, "workshop": {"id": id, "token": str(r.value["token"]), "seed": str(r.value["seed"]),
		"ticks": int(r.value["ticks"])}}


## A play `play` fetched, on the heist screen: its token, seed and clock ride
## in the heist slice.
func start(heist: Dictionary) -> void:
	_store().dispatch(&"heist_started", heist)
	services.router.go(&"heist")


## The heist screen's play, sent (kept in the outbox until the server has
## it): whether it cleared, and whether it counted.
func submit(token: String, replay: PackedByteArray) -> Result:
	var r := await _repo().submit(token, replay)
	if r.ok and not r.value.get("pending", false):
		_store().dispatch(&"workshop_done", {"what": "played", "answer": r.value})
	return r


func rate(id: String, fun: int, cleverness: int, fairness: int) -> bool:
	_store().dispatch(&"workshop_asked")
	var r := await _repo().rate(id, fun, cleverness, fairness)
	if r.ok:
		_store().dispatch(&"workshop_done", {"what": "rated", "answer": r.value})
	else:
		_fail(r.code)
	return r.ok


func report(id: String, reason: String) -> void:
	_store().dispatch(&"workshop_asked")
	var r := await _repo().report(id, reason)
	if r.ok:
		_store().dispatch(&"workshop_done", {"what": "reported", "answer": r.value})
	else:
		_fail(r.code)


## §18.6: an island to build on becomes the player's draft; its publication
## names the original. True once the draft is kept.
func remix(id: String) -> bool:
	_store().dispatch(&"workshop_asked")
	var r := await _repo().remix(id)
	if not r.ok:
		_fail(r.code)
		return false
	if not Draft.start_remix(r.value, id):
		_fail("draft_not_kept")
		return false
	_store().dispatch(&"workshop_done", {"what": "remixed", "answer": {"id": id}})
	return true


func withdraw(id: String) -> void:
	_store().dispatch(&"workshop_asked")
	var r := await _repo().withdraw(id)
	if not r.ok:
		_fail(r.code)
		return
	_store().dispatch(&"workshop_done", {"what": "withdrawn", "answer": r.value})
	await _list("mine", true)


## A Workshop play's answer in the result screen's terms: its grade, whether
## it cleared the island, and whether it counted as a completion (§18.7). An
## answer still in the outbox is the device's own check, marked confirming.
static func settled(r: Result, local: Dictionary) -> Dictionary:
	if r.ok and r.value.get("pending", false):
		var confirming := local.duplicate()
		confirming["confirming"] = true
		confirming["workshop"] = true
		return confirming
	if not r.ok:
		return {"ok": false, "refused": r.code, "server": true, "workshop": true}
	var out: Dictionary = r.value
	if not out.get("validated", false):
		return {"ok": false, "refused": str(out.get("reason", "refused")), "server": true, "workshop": true}
	var verdict: Dictionary = out["verdict"]
	return {"ok": true, "grade": str(verdict["grade"]).capitalize(), "banked": verdict["banked"], "server": true,
		"workshop": true, "cleared": bool(out.get("cleared", false)), "counted": bool(out.get("counted", false))}


## A verdict clears an island as the server judges it (workshop.mjs's
## `clears`): loot banked and out.
static func clears(v: Dictionary) -> bool:
	if v.has("cleared"):
		return bool(v["cleared"])
	return v.get("ok", false) and str(v.get("grade", "")).to_lower() != "foiled" and int(v.get("banked", 0)) > 0


## The list, as the server answers it. Only the latest request's answer is
## shown, so tapping one list and then another ends on the second. After an
## action, a list that cannot be had leaves the action's own outcome on show.
func _list(list: String, after_action := false) -> void:
	_asked += 1
	var ticket := _asked
	var r: Result
	if list == "mine":
		r = await _repo().mine()
	else:
		r = await _repo().browse(list)
	if not r.ok and r.code == "curated_lists_only" and list != "featured":
		_store().dispatch(&"workshop_curated")
		list = "featured"
		r = await _repo().browse(list)
	if ticket != _asked:
		return
	if not r.ok:
		if not after_action:
			_fail(r.code)
		return
	_store().dispatch(&"workshop_listed", {"list": list, "items": r.value})
	if list == "mine":
		var me := str(_store().get_slice(AppState.SESSION)["account"])
		if me == "":
			return
		var ladder := await _repo().ladder(me)
		if ladder.ok:
			_store().dispatch(&"workshop_ladder", {"ladder": ladder.value})


func _item(id: String) -> Dictionary:
	for i: Dictionary in _store().get_slice(WorkshopState.WORKSHOP)["items"]:
		if str(i.get("id", "")) == id:
			return i
	return {}


func _store() -> Store:
	return services.store


func _repo() -> WorkshopRepository:
	return services.workshop


## A failure, shown. Refused for the terms: they are asked for again, so the
## screen offers them.
func _fail(code: String) -> void:
	_store().dispatch(&"workshop_failed", {"code": code})
	if code == "terms_first" or code == "not_the_current_terms":
		await load_terms()
