class_name SocialState
extends RefCounted
## The league, the player's constellation and crew, and their friends, as the
## store holds them (§12.9, §17, §18.1). Reducers are static functions of
## (slice, payload), tested directly.

## The player's Renown, league and division this season.
const LEAGUE := &"league"
## The player's constellation and crew, each {} for none, and the name word
## lists a constellation is founded with.
const GROUPS := &"groups"
## Friends, the feed, the last invite made and the last challenge link.
const FRIENDS := &"friends"


static func register(store: Store) -> void:
	store.register(LEAGUE, {"view": {}, "error": "", "busy": false}, {
		&"league_asked": asked,
		&"league_loaded": league_loaded,
		&"league_failed": failed,
	})
	store.register(GROUPS, {"constellation": {}, "crew": {}, "words": {}, "error": "", "busy": false,
			"known": false}, {
		&"groups_asked": asked,
		&"groups_loaded": groups_loaded,
		&"constellation_changed": constellation_changed,
		&"crew_changed": crew_changed,
		&"words_loaded": words_loaded,
		&"groups_failed": failed,
	})
	store.register(FRIENDS, {"friends": [], "feed": [], "blocked": [], "invite": {}, "challenge": {}, "error": "",
			"busy": false, "accepted": "", "last": ""}, {
		&"friends_asked": asked,
		&"friends_loaded": friends_loaded,
		&"invite_made": invite_made,
		&"friend_accepted": friend_accepted,
		&"challenge_made": challenge_made,
		&"friends_failed": failed,
	})


static func asked(s: Dictionary, _p: Dictionary) -> Dictionary:
	var next := s.duplicate()
	next["busy"] = true
	next["error"] = ""
	return next


static func failed(s: Dictionary, p: Dictionary) -> Dictionary:
	var next := s.duplicate()
	next["busy"] = false
	next["error"] = str(p["code"])
	return next


static func league_loaded(s: Dictionary, p: Dictionary) -> Dictionary:
	var next := s.duplicate()
	next["view"] = p["view"]
	next["busy"] = false
	next["error"] = ""
	return next


## The player's constellation and crew as the server holds them; a null is
## none, kept as {}.
static func groups_loaded(s: Dictionary, p: Dictionary) -> Dictionary:
	var next := s.duplicate()
	next["constellation"] = p["constellation"] if p["constellation"] is Dictionary else {}
	next["crew"] = p["crew"] if p["crew"] is Dictionary else {}
	next["busy"] = false
	next["error"] = ""
	next["known"] = true
	return next


static func constellation_changed(s: Dictionary, p: Dictionary) -> Dictionary:
	var next := s.duplicate()
	next["constellation"] = p["constellation"] if p["constellation"] is Dictionary else {}
	next["busy"] = false
	next["error"] = ""
	return next


static func crew_changed(s: Dictionary, p: Dictionary) -> Dictionary:
	var next := s.duplicate()
	next["crew"] = p["crew"] if p["crew"] is Dictionary else {}
	next["busy"] = false
	next["error"] = ""
	return next


static func words_loaded(s: Dictionary, p: Dictionary) -> Dictionary:
	var next := s.duplicate()
	next["words"] = p["words"]
	return next


static func friends_loaded(s: Dictionary, p: Dictionary) -> Dictionary:
	var next := s.duplicate()
	next["friends"] = p["friends"]
	next["feed"] = p["feed"]
	next["blocked"] = p.get("blocked", [])
	next["busy"] = false
	next["error"] = ""
	return next


## Each of the three outcomes is kept, and `last` says which came last: the
## one the screen shows.
static func invite_made(s: Dictionary, p: Dictionary) -> Dictionary:
	var next := s.duplicate()
	next["invite"] = p["invite"]
	next["last"] = "invite"
	next["busy"] = false
	next["error"] = ""
	return next


static func friend_accepted(s: Dictionary, p: Dictionary) -> Dictionary:
	var next := s.duplicate()
	next["accepted"] = str(p["friend"])
	next["last"] = "accepted"
	next["busy"] = false
	next["error"] = ""
	return next


static func challenge_made(s: Dictionary, p: Dictionary) -> Dictionary:
	var next := s.duplicate()
	next["challenge"] = p["challenge"]
	next["last"] = "challenge"
	next["busy"] = false
	next["error"] = ""
	return next
