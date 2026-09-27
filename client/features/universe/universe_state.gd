class_name UniverseState
extends RefCounted
## The player's universe as the store holds it (§5.2, §10.2): the server's
## view, the purchase on its way (named by the key its button carries), the
## last one made, and the last failure.

const UNIVERSE := &"universe"


static func register(store: Store) -> void:
	store.register(UNIVERSE, {"view": {}, "busy": "", "error": "", "detail": {}, "last": {},
		"purchases": 0}, {
		&"universe_asked": asked,
		&"universe_loaded": loaded,
		&"universe_failed": failed,
		&"purchase_asked": purchase_asked,
		&"purchase_made": made,
	})


## A fetch under way: the last view stays on show, and the last purchase's
## words go, so an old success never reads as a new one.
static func asked(s: Dictionary, _p: Dictionary) -> Dictionary:
	var next := s.duplicate()
	next["busy"] = "view"
	next["error"] = ""
	next["last"] = {}
	return next


## The fetched view, unless a purchase was answered after it was asked for:
## that answer's universe is the newer one.
static func loaded(s: Dictionary, p: Dictionary) -> Dictionary:
	var next := s.duplicate()
	if int(p.get("purchases", s["purchases"])) == int(s["purchases"]):
		next["view"] = p["view"]
	if next["busy"] == "view":
		next["busy"] = ""
	next["error"] = ""
	return next


## A failure keeps the universe that was on show, and says why.
static func failed(s: Dictionary, p: Dictionary) -> Dictionary:
	var next := s.duplicate()
	next["busy"] = ""
	next["error"] = str(p["code"])
	next["detail"] = p.get("detail", {})
	return next


static func purchase_asked(s: Dictionary, p: Dictionary) -> Dictionary:
	var next := s.duplicate()
	next["busy"] = str(p["key"])
	next["error"] = ""
	next["last"] = {}
	return next


## The server's answer to a purchase: the universe after it, and what was
## bought, with the Keeper experience it earned — none for one already made.
static func made(s: Dictionary, p: Dictionary) -> Dictionary:
	var next := s.duplicate()
	next["view"] = p["universe"]
	next["busy"] = ""
	next["error"] = ""
	next["last"] = {"what": p["what"], "keeper": p.get("keeper"), "repeated": bool(p.get("repeated", false))}
	next["purchases"] = int(s["purchases"]) + 1
	return next
