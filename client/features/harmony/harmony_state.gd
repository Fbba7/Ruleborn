class_name HarmonyState
extends RefCounted
## The Harmony view as the store holds it (§8, §23.2): the server's answer,
## whether a fetch is on its way, and the last failure. It changes nothing,
## so it holds no change.

const HARMONY := &"harmony"


static func register(store: Store) -> void:
	store.register(HARMONY, {"view": {}, "busy": false, "error": ""}, {
		&"harmony_asked": asked,
		&"harmony_loaded": loaded,
		&"harmony_failed": failed,
	})


static func asked(s: Dictionary, _p: Dictionary) -> Dictionary:
	var next := s.duplicate()
	next["busy"] = true
	next["error"] = ""
	return next


static func loaded(s: Dictionary, p: Dictionary) -> Dictionary:
	var next := s.duplicate()
	next["view"] = p["view"]
	next["busy"] = false
	next["error"] = ""
	return next


## A failure keeps the view that was on show, and says why.
static func failed(s: Dictionary, p: Dictionary) -> Dictionary:
	var next := s.duplicate()
	next["busy"] = false
	next["error"] = str(p["code"])
	return next
