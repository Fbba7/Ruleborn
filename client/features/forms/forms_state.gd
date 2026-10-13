class_name FormsState
extends RefCounted
## The Forms album as the store holds it (§11.10): the server's answer, the
## last failure, and whether the album shows only the player's own forms
## (§23.2's "Show mine").

const FORMS := &"forms"


static func register(store: Store) -> void:
	store.register(FORMS, {"view": {}, "busy": "", "error": "", "mine": false}, {
		&"forms_asked": asked,
		&"forms_loaded": loaded,
		&"forms_failed": failed,
		&"forms_mine": mine,
	})


static func asked(s: Dictionary, _p: Dictionary) -> Dictionary:
	var next := s.duplicate()
	next["busy"] = "view"
	next["error"] = ""
	return next


static func loaded(s: Dictionary, p: Dictionary) -> Dictionary:
	var next := s.duplicate()
	next["view"] = p["view"]
	next["busy"] = ""
	next["error"] = ""
	return next


## A failure keeps the album that was on show, and says why.
static func failed(s: Dictionary, p: Dictionary) -> Dictionary:
	var next := s.duplicate()
	next["busy"] = ""
	next["error"] = str(p["code"])
	return next


## "Show mine", or all of them again.
static func mine(s: Dictionary, p: Dictionary) -> Dictionary:
	var next := s.duplicate()
	next["mine"] = bool(p["mine"])
	return next
