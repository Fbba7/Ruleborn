class_name DefencesState
extends RefCounted
## The defence log as the store holds it (§13.2): the server's log, what is
## on its way, the raid badge's count, the raid being watched (its replay and
## the island it was played on, for the replay screen), the raids' islands by
## bundle, which name the report's places, and the last failure.

const DEFENCES := &"defences"


static func register(store: Store) -> void:
	store.register(DEFENCES, {"view": {}, "busy": "", "error": "", "detail": {}, "unseen": 0, "watching": {},
		"islands": {}}, {
		&"defences_asked": asked,
		&"defences_loaded": loaded,
		&"defences_failed": failed,
		&"defences_badge": badge,
		&"defences_watching": watching,
		&"defences_island": island,
	})


static func asked(s: Dictionary, p: Dictionary) -> Dictionary:
	var next := s.duplicate()
	next["busy"] = str(p.get("what", "view"))
	next["error"] = ""
	return next


## The log as the server answered; reading it cleared the badge.
static func loaded(s: Dictionary, p: Dictionary) -> Dictionary:
	var next := s.duplicate()
	next["view"] = p["view"]
	next["busy"] = ""
	next["error"] = ""
	next["unseen"] = 0
	return next


## A failure keeps the log that was on show, and says why.
static func failed(s: Dictionary, p: Dictionary) -> Dictionary:
	var next := s.duplicate()
	next["busy"] = ""
	next["error"] = str(p["code"])
	next["detail"] = p.get("detail", {})
	return next


static func badge(s: Dictionary, p: Dictionary) -> Dictionary:
	var next := s.duplicate()
	next["unseen"] = int(p["unseen"])
	return next


## A raid's replay and its island, for the replay screen; empty when done.
static func watching(s: Dictionary, p: Dictionary) -> Dictionary:
	var next := s.duplicate()
	next["busy"] = ""
	next["watching"] = p.duplicate()
	return next


## A raid's island, by its bundle, so its report names places (§13.2).
static func island(s: Dictionary, p: Dictionary) -> Dictionary:
	var next := s.duplicate()
	var islands: Dictionary = (s["islands"] as Dictionary).duplicate()
	islands[str(p["bundle"])] = p["island"]
	next["islands"] = islands
	return next
