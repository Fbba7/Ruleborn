class_name KeeperState
extends RefCounted
## The player's Keeper level (§14.2) as the store holds it: the server's
## view — level, experience toward the next, what the next needs — kept up to
## date by each heist's answer, and the last failure to fetch it.

const KEEPER := &"keeper"


static func register(store: Store) -> void:
	store.register(KEEPER, {"view": {}, "error": ""}, {
		&"keeper_loaded": loaded,
		&"keeper_failed": failed,
		&"keeper_earned": earned,
	})


static func loaded(s: Dictionary, p: Dictionary) -> Dictionary:
	var next := s.duplicate()
	next["view"] = p["view"]
	next["error"] = ""
	return next


## A failure keeps the bar that was on show.
static func failed(s: Dictionary, p: Dictionary) -> Dictionary:
	var next := s.duplicate()
	next["error"] = str(p["code"])
	return next


## A heist's answer: the level and progress it left, so the bar moves without
## asking again.
static func earned(s: Dictionary, p: Dictionary) -> Dictionary:
	var next := s.duplicate()
	var view: Dictionary = (s["view"] as Dictionary).duplicate()
	var k: Dictionary = p["keeper"]
	view["level"] = k.get("level", view.get("level", 1))
	view["xp"] = k.get("xp", view.get("xp", 0))
	view["toNext"] = k.get("toNext")
	next["view"] = view
	return next
