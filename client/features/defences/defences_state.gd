class_name DefencesState
extends RefCounted
## The defence log as the store holds it (§13.2): the server's log, what is
## on its way, the raid badge's count, the raid being watched (its replay and
## the island it was played on, for the replay screen), and the last failure.

const DEFENCES := &"defences"


static func register(store: Store) -> void:
	store.register(DEFENCES, {"view": {}, "busy": "", "error": "", "detail": {}, "unseen": 0, "watching": {}}, {
		&"defences_asked": asked,
		&"defences_loaded": loaded,
		&"defences_failed": failed,
		&"defences_badge": badge,
		&"defences_watching": watching,
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
