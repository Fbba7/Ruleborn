class_name ObservatoryState
extends RefCounted
## The Observatory as the store holds it (§12.3, §12.4): the server's list,
## what is on its way ("view" or "refresh"), the target being read in the
## scout report, and the last failure.

const OBSERVATORY := &"observatory"


static func register(store: Store) -> void:
	store.register(OBSERVATORY, {"view": {}, "busy": "", "error": "", "detail": {}, "chosen": ""}, {
		&"observatory_asked": asked,
		&"observatory_loaded": loaded,
		&"observatory_failed": failed,
		&"observatory_chosen": chosen,
	})


static func asked(s: Dictionary, p: Dictionary) -> Dictionary:
	var next := s.duplicate()
	next["busy"] = str(p.get("what", "view"))
	next["error"] = ""
	return next


## The list as the server answered, from a fetch or a refresh.
static func loaded(s: Dictionary, p: Dictionary) -> Dictionary:
	var next := s.duplicate()
	next["view"] = p["view"]
	next["busy"] = ""
	next["error"] = ""
	return next


## A failure keeps the list that was on show, and says why.
static func failed(s: Dictionary, p: Dictionary) -> Dictionary:
	var next := s.duplicate()
	next["busy"] = ""
	next["error"] = str(p["code"])
	next["detail"] = p.get("detail", {})
	return next


## The target whose scout report is open, by its bundle.
static func chosen(s: Dictionary, p: Dictionary) -> Dictionary:
	var next := s.duplicate()
	next["chosen"] = str(p["bundle"])
	return next
