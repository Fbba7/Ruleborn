class_name SocialController
extends RefCounted
## The league, constellations, crews and friends, with no screen: each asks
## the social repository and dispatches what came back, so the screens only
## draw the store and the tests drive the flows headless.

var services: Services


func _init(s: Services) -> void:
	services = s


func _store() -> Store:
	return services.store


func _repo() -> SocialRepository:
	return services.social


func load_league() -> void:
	_store().dispatch(&"league_asked")
	var r := await _repo().league()
	_store().dispatch(&"league_loaded" if r.ok else &"league_failed",
		{"view": r.value} if r.ok else {"code": r.code})


func load_groups() -> void:
	_store().dispatch(&"groups_asked")
	var c := await _repo().my_constellation()
	if not c.ok:
		_store().dispatch(&"groups_failed", {"code": c.code})
		return
	var crew := await _repo().my_crew()
	if not crew.ok:
		_store().dispatch(&"groups_failed", {"code": crew.code})
		return
	_store().dispatch(&"groups_loaded", {"constellation": c.value.get("constellation"),
		"crew": crew.value.get("crew")})


func load_words() -> void:
	var r := await _repo().words()
	if r.ok:
		_store().dispatch(&"words_loaded", {"words": r.value})


## §17.1: found a constellation named from the word lists.
func found(adjective: int, noun: int) -> void:
	_store().dispatch(&"groups_asked")
	var r := await _repo().found(adjective, noun)
	_store().dispatch(&"constellation_changed" if r.ok else &"groups_failed",
		{"constellation": r.value} if r.ok else {"code": r.code})


func join(id: String) -> void:
	_store().dispatch(&"groups_asked")
	var r := await _repo().join(id)
	_store().dispatch(&"constellation_changed" if r.ok else &"groups_failed",
		{"constellation": r.value} if r.ok else {"code": r.code})


func leave() -> void:
	_store().dispatch(&"groups_asked")
	var r := await _repo().leave()
	_store().dispatch(&"constellation_changed" if r.ok else &"groups_failed",
		{"constellation": null} if r.ok else {"code": r.code})


## §17.7: start a crew, join one by its invite, or leave it.
func start_crew() -> void:
	_store().dispatch(&"groups_asked")
	var r := await _repo().start_crew()
	_store().dispatch(&"crew_changed" if r.ok else &"groups_failed", {"crew": r.value} if r.ok else {"code": r.code})


func join_crew(invite: String) -> void:
	_store().dispatch(&"groups_asked")
	var r := await _repo().join_crew(invite.strip_edges())
	_store().dispatch(&"crew_changed" if r.ok else &"groups_failed", {"crew": r.value} if r.ok else {"code": r.code})


func leave_crew() -> void:
	_store().dispatch(&"groups_asked")
	var r := await _repo().leave_crew()
	_store().dispatch(&"crew_changed" if r.ok else &"groups_failed", {"crew": null} if r.ok else {"code": r.code})


func load_friends() -> void:
	_store().dispatch(&"friends_asked")
	var f := await services.friends.friends()
	if not f.ok:
		_store().dispatch(&"friends_failed", {"code": f.code})
		return
	var feed := await services.friends.feed()
	if not feed.ok:
		_store().dispatch(&"friends_failed", {"code": feed.code})
		return
	# §17.8: the players blocked, each to unblock from here.
	# A blocks call that fails keeps the list shown (CLI-24).
	var blocked := await services.account.blocks()
	_store().dispatch(&"friends_loaded", {"friends": f.value, "feed": feed.value,
		"blocked": blocked.value if blocked.ok else _store().get_slice(SocialState.FRIENDS).get("blocked", [])})


func make_invite() -> void:
	_store().dispatch(&"friends_asked")
	var r := await services.friends.invite()
	_store().dispatch(&"invite_made" if r.ok else &"friends_failed", {"invite": r.value} if r.ok else {"code": r.code})


func accept(code: String) -> void:
	_store().dispatch(&"friends_asked")
	var r := await services.friends.accept(code.strip_edges())
	if not r.ok:
		_store().dispatch(&"friends_failed", {"code": r.code})
		return
	_store().dispatch(&"friend_accepted", {"friend": r.value["friend"]})
	await load_friends()


## §17.8: a block undone. Nothing it ended comes back of itself: a
## friendship is made again by an invite.
func unblock(account: String) -> void:
	_store().dispatch(&"friends_asked")
	var r := await services.account.unblock(account)
	if not r.ok:
		_store().dispatch(&"friends_failed", {"code": r.code})
		return
	await load_friends()


func remove(account: String) -> void:
	_store().dispatch(&"friends_asked")
	var r := await services.friends.remove(account)
	if not r.ok:
		_store().dispatch(&"friends_failed", {"code": r.code})
		return
	await load_friends()


## §17.6: a challenge link to the player's own island.
func make_challenge() -> void:
	_store().dispatch(&"friends_asked")
	var r := await services.friends.challenge()
	_store().dispatch(&"challenge_made" if r.ok else &"friends_failed",
		{"challenge": r.value} if r.ok else {"code": r.code})
