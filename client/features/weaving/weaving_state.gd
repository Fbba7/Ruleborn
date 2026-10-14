class_name WeavingState
extends RefCounted
## Weaving as the store holds it (§5.5, §5.6): the server's view, the change
## on its way (by the key its button carries), the last one made, and the
## last failure; and what the phone wove offline, waiting for the server to
## confirm it (§24), with the last the server refused.

const WEAVING := &"weaving"


static func register(store: Store) -> void:
	store.register(WEAVING, {"view": {}, "busy": "", "error": "", "detail": {}, "last": {},
		"changes": 0, "confirming": {}, "refused": {}}, {
		&"weaving_asked": asked,
		&"weaving_loaded": loaded,
		&"weaving_failed": failed,
		&"weave_asked": weave_asked,
		&"weave_made": weave_made,
		&"weave_queued": queued,
		&"weave_answered": answered,
	})


## A fetch under way: the last view stays on show, and the last change's
## words go, so an old success never reads as a new one.
static func asked(s: Dictionary, _p: Dictionary) -> Dictionary:
	var next := s.duplicate()
	next["busy"] = "view"
	next["error"] = ""
	next["last"] = {}
	return next


## The fetched view, unless a change was answered after it was asked for:
## that answer's view is the newer one.
static func loaded(s: Dictionary, p: Dictionary) -> Dictionary:
	var next := s.duplicate()
	if int(p.get("changes", s["changes"])) == int(s["changes"]):
		next["view"] = p["view"]
	if next["busy"] == "view":
		next["busy"] = ""
	next["error"] = ""
	return next


## A failure keeps the view that was on show, and says why.
static func failed(s: Dictionary, p: Dictionary) -> Dictionary:
	var next := s.duplicate()
	next["busy"] = ""
	next["error"] = str(p["code"])
	next["detail"] = p.get("detail", {})
	return next


static func weave_asked(s: Dictionary, p: Dictionary) -> Dictionary:
	var next := s.duplicate()
	next["busy"] = str(p["key"])
	next["error"] = ""
	next["last"] = {}
	return next


## The server's answer: the view after the change, and what was changed.
static func weave_made(s: Dictionary, p: Dictionary) -> Dictionary:
	var next := s.duplicate()
	next["view"] = p["view"]
	next["busy"] = ""
	next["error"] = ""
	next["last"] = p["what"]
	next["changes"] = int(s["changes"]) + 1
	return next


## A weave the network did not reach, kept to send (§24: "The device may
## build, weave and assign work offline, confirmed on reconnection").
static func queued(s: Dictionary, p: Dictionary) -> Dictionary:
	var next := s.duplicate()
	next["busy"] = ""
	next["error"] = ""
	var waiting: Dictionary = (s["confirming"] as Dictionary).duplicate()
	waiting[str(p["key"])] = p["what"]
	next["confirming"] = waiting
	return next


## The server's answer to a weave the phone kept: confirmed, with what is
## woven after it, or refused, and said why.
static func answered(s: Dictionary, p: Dictionary) -> Dictionary:
	var next := s.duplicate()
	var waiting: Dictionary = (s["confirming"] as Dictionary).duplicate()
	var what: Variant = waiting.get(str(p["key"]), {})
	waiting.erase(str(p["key"]))
	next["confirming"] = waiting
	if p.get("view") is Dictionary and not (p["view"] as Dictionary).is_empty():
		next["view"] = p["view"]
		next["changes"] = int(s["changes"]) + 1
	if str(p.get("refused", "")) != "":
		next["refused"] = {"what": what, "code": str(p["refused"]), "detail": p.get("detail", {})}
		next["last"] = {}
	return next
