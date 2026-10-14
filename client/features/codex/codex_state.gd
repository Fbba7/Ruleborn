class_name CodexState
extends RefCounted
## The Codex as the store holds it (§7.6, §18.5): the server's view, the
## change on its way (by the key its button carries), the last one made, and
## the last failure.

const CODEX := &"codex"


static func register(store: Store) -> void:
	store.register(CODEX, {"view": {}, "busy": "", "error": "", "detail": {}, "last": {}, "changes": 0}, {
		&"codex_asked": asked,
		&"codex_loaded": loaded,
		&"codex_failed": failed,
		&"codex_change_asked": change_asked,
		&"codex_change_made": change_made,
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


static func change_asked(s: Dictionary, p: Dictionary) -> Dictionary:
	var next := s.duplicate()
	next["busy"] = str(p["key"])
	next["error"] = ""
	next["last"] = {}
	return next


## The server's answer: the Codex after the change, and what was changed.
static func change_made(s: Dictionary, p: Dictionary) -> Dictionary:
	var next := s.duplicate()
	next["view"] = p["view"]
	next["busy"] = ""
	next["error"] = ""
	next["last"] = p["what"]
	next["changes"] = int(s["changes"]) + 1
	return next
