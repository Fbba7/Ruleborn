class_name ProfileState
extends RefCounted
## The Profile as the store holds it: the server's view, what is on its way,
## and the last failure.

const PROFILE := &"profile"


static func register(store: Store) -> void:
	store.register(PROFILE, {"view": {}, "busy": "", "error": "", "detail": {}}, {
		&"profile_asked": asked,
		&"profile_loaded": loaded,
		&"profile_failed": failed,
	})


static func asked(s: Dictionary, p: Dictionary) -> Dictionary:
	var next := s.duplicate()
	next["busy"] = str(p.get("what", "view"))
	next["error"] = ""
	return next


static func loaded(s: Dictionary, p: Dictionary) -> Dictionary:
	var next := s.duplicate()
	next["view"] = p["view"]
	next["busy"] = ""
	next["error"] = ""
	return next


## A failure keeps the profile on show, and says why.
static func failed(s: Dictionary, p: Dictionary) -> Dictionary:
	var next := s.duplicate()
	next["busy"] = ""
	next["error"] = str(p["code"])
	next["detail"] = p.get("detail", {})
	return next
