class_name FirstState
extends RefCounted
## The first launch as the store holds it: the beat on show, §20.2's
## protections and the word lists the server sent, the name being picked,
## and the last failure. The beat itself is kept on the phone (FirstLaunch).

const FIRST := &"first"


static func register(store: Store) -> void:
	store.register(FIRST, {"beat": "title", "protections": {}, "words": {}, "name": {"adjective": 0, "noun": 0},
			"asked": false, "error": ""}, {
		&"first_moved": moved,
		&"first_asked": asked,
		&"first_loaded": loaded,
		&"first_failed": failed,
		&"first_named": named,
	})


static func moved(s: Dictionary, p: Dictionary) -> Dictionary:
	var next := s.duplicate()
	next["beat"] = str(p["beat"])
	return next


static func asked(s: Dictionary, _p: Dictionary) -> Dictionary:
	var next := s.duplicate()
	next["asked"] = true
	next["error"] = ""
	return next


static func loaded(s: Dictionary, p: Dictionary) -> Dictionary:
	var next := s.duplicate()
	next["protections"] = p["protections"]
	next["words"] = p["words"]
	return next


static func failed(s: Dictionary, p: Dictionary) -> Dictionary:
	var next := s.duplicate()
	next["asked"] = false
	next["error"] = str(p["code"])
	return next


static func named(s: Dictionary, p: Dictionary) -> Dictionary:
	var next := s.duplicate()
	next["name"] = p["name"]
	return next
