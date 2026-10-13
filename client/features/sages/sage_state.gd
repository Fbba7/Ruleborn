class_name SageState
extends RefCounted
## The Sage hall as the store holds it (§11.7): the server's answer — each
## Sage, the level, the one on guard — the change on its way, the last one
## made, and the last failure.

const SAGES := &"sages"


static func register(store: Store) -> void:
	store.register(SAGES, {"view": {}, "busy": "", "error": "", "last": {}}, {
		&"sages_asked": asked,
		&"sages_loaded": loaded,
		&"sages_failed": failed,
		&"guardian_asked": guardian_asked,
		&"guardian_set": guardian_set,
	})


static func asked(s: Dictionary, _p: Dictionary) -> Dictionary:
	var next := s.duplicate()
	next["busy"] = "view"
	next["error"] = ""
	next["last"] = {}
	return next


## The fetched view, unless a change is on its way, whose answer is newer.
static func loaded(s: Dictionary, p: Dictionary) -> Dictionary:
	var next := s.duplicate()
	if str(s["busy"]) in ["", "view"]:
		next["view"] = p["view"]
		next["busy"] = ""
	next["error"] = ""
	return next


## A failure keeps the hall that was on show, and says why.
static func failed(s: Dictionary, p: Dictionary) -> Dictionary:
	var next := s.duplicate()
	next["busy"] = ""
	next["error"] = str(p["code"])
	return next


static func guardian_asked(s: Dictionary, p: Dictionary) -> Dictionary:
	var next := s.duplicate()
	next["busy"] = str(p["key"])
	next["error"] = ""
	next["last"] = {}
	return next


## The server's answer: the hall after the change, and who is on guard now.
static func guardian_set(s: Dictionary, p: Dictionary) -> Dictionary:
	var next := s.duplicate()
	next["view"] = p["view"]
	next["busy"] = ""
	next["error"] = ""
	next["last"] = {"guardian": p["view"].get("guardian")}
	return next
