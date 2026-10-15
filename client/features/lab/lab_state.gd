class_name LabState
extends RefCounted
## The Lab as the store holds it (§8.6): the server's view, what is on its
## way ("view", a chamber's "start:N" or the third sphere's "sphere"), the
## laws placed in each idle chamber's spheres by its number, what was last
## done ("started", or "named:" and the chord), and the last failure.

const LAB := &"lab"


static func register(store: Store) -> void:
	store.register(LAB, {"view": {}, "busy": "", "error": "", "detail": {}, "picks": {}, "said": ""}, {
		&"lab_asked": asked,
		&"lab_loaded": loaded,
		&"lab_failed": failed,
		&"lab_picked": picked,
	})


static func asked(s: Dictionary, p: Dictionary) -> Dictionary:
	var next := s.duplicate()
	next["busy"] = str(p.get("what", "view"))
	next["error"] = ""
	next["said"] = ""
	return next


## The Lab as the server answered; an experiment started says so.
static func loaded(s: Dictionary, p: Dictionary) -> Dictionary:
	var next := s.duplicate()
	next["view"] = p["view"]
	next["busy"] = ""
	next["error"] = ""
	next["said"] = str(p.get("said", ""))
	return next


## A failure keeps the Lab that was on show, and says why.
static func failed(s: Dictionary, p: Dictionary) -> Dictionary:
	var next := s.duplicate()
	next["busy"] = ""
	next["error"] = str(p["code"])
	next["detail"] = p.get("detail", {})
	return next


## The laws in chamber `chamber`'s spheres, in order.
static func picked(s: Dictionary, p: Dictionary) -> Dictionary:
	var next := s.duplicate()
	var picks: Dictionary = (s["picks"] as Dictionary).duplicate()
	picks[str(p["chamber"])] = (p["laws"] as Array).duplicate()
	next["picks"] = picks
	return next
