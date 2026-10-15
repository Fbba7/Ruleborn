class_name ShareState
extends RefCounted
## The share sheet as the store holds it (§23.2): the challenge link made,
## the personal invite made, what is on its way, whether a code was copied,
## and the last failure.

const SHARE := &"share"


static func register(store: Store) -> void:
	store.register(SHARE, {"link": {}, "invite": {}, "busy": false, "copied": false, "error": ""}, {
		&"share_asked": asked,
		&"share_link": link,
		&"share_invite": invite,
		&"share_copied": copied,
		&"share_failed": failed,
	})


static func asked(s: Dictionary, _p: Dictionary) -> Dictionary:
	var next := s.duplicate()
	next["busy"] = true
	next["error"] = ""
	return next


static func link(s: Dictionary, p: Dictionary) -> Dictionary:
	var next := s.duplicate()
	next["link"] = p["link"]
	next["busy"] = false
	next["copied"] = false
	return next


## §17.6's personal invite, which brings both players the invite gift.
static func invite(s: Dictionary, p: Dictionary) -> Dictionary:
	var next := s.duplicate()
	next["invite"] = p["invite"]
	next["busy"] = false
	next["copied"] = false
	return next


static func copied(s: Dictionary, _p: Dictionary) -> Dictionary:
	var next := s.duplicate()
	next["copied"] = true
	return next


static func failed(s: Dictionary, p: Dictionary) -> Dictionary:
	var next := s.duplicate()
	next["busy"] = false
	next["error"] = str(p["code"])
	return next
