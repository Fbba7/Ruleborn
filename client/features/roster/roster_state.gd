class_name RosterState
extends RefCounted
## The roster as the store holds it (§11.4 to §11.6, §23.2): the server's
## home view, the change on its way (named by the key its button carries),
## the last one made, and the last failure; and the work the phone assigned
## offline, waiting for the server to confirm it (§24), with the last the
## server refused.

const ROSTER := &"roster"


static func register(store: Store) -> void:
	store.register(ROSTER, {"view": {}, "busy": "", "error": "", "detail": {}, "last": {},
		"changes": 0, "confirming": {}, "refused": {}}, {
		&"roster_asked": asked,
		&"roster_loaded": loaded,
		&"roster_failed": failed,
		&"roster_change_asked": change_asked,
		&"roster_changed": change_made,
		&"roster_queued": queued,
		&"roster_answered": answered,
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
## that answer's home is the newer one.
static func loaded(s: Dictionary, p: Dictionary) -> Dictionary:
	var next := s.duplicate()
	if int(p.get("changes", s["changes"])) == int(s["changes"]):
		next["view"] = p["view"]
	if next["busy"] == "view":
		next["busy"] = ""
	next["error"] = ""
	return next


## A failure keeps the roster that was on show, and says why.
static func failed(s: Dictionary, p: Dictionary) -> Dictionary:
	var next := s.duplicate()
	next["busy"] = ""
	next["error"] = str(p["code"])
	next["detail"] = p.get("detail", {})
	return next


static func change_asked(s: Dictionary, p: Dictionary) -> Dictionary:
	var next := s.duplicate()
	next["busy"] = str(p["key"])
	next["error"] = ""
	next["last"] = {}
	return next


## The server's answer to a change: the home after it, and what was changed.
static func change_made(s: Dictionary, p: Dictionary) -> Dictionary:
	var next := s.duplicate()
	next["view"] = p["home"]
	next["busy"] = ""
	next["error"] = ""
	next["last"] = {"what": p["what"], "repeated": bool(p.get("repeated", false))}
	next["changes"] = int(s["changes"]) + 1
	return next


## Work the network did not reach, kept to send (§24: "The device may …
## assign work offline, confirmed on reconnection").
static func queued(s: Dictionary, p: Dictionary) -> Dictionary:
	var next := s.duplicate()
	next["busy"] = ""
	next["error"] = ""
	var waiting: Dictionary = (s["confirming"] as Dictionary).duplicate()
	waiting[str(p["key"])] = p["what"]
	next["confirming"] = waiting
	return next


## The server's answer to work the phone kept: confirmed, with the home after
## it, or refused, and said why.
static func answered(s: Dictionary, p: Dictionary) -> Dictionary:
	var next := s.duplicate()
	var waiting: Dictionary = (s["confirming"] as Dictionary).duplicate()
	var what: Variant = waiting.get(str(p["key"]), {})
	waiting.erase(str(p["key"]))
	next["confirming"] = waiting
	if p.get("home") is Dictionary and not (p["home"] as Dictionary).is_empty():
		next["view"] = p["home"]
		next["changes"] = int(s["changes"]) + 1
	if str(p.get("refused", "")) != "":
		next["refused"] = {"what": what, "code": str(p["refused"]), "detail": p.get("detail", {})}
		next["last"] = {}
	return next
