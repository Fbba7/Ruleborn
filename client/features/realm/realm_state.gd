class_name RealmState
extends RefCounted
## The realm view as the store holds it (§23.2): which realm, its published
## island's bytes as the server keeps them, what is on its way, and the last
## failure. The rest it reads is the universe, weaving and home views.

const REALM := &"realm_view"


static func register(store: Store) -> void:
	store.register(REALM, {"realm": "heart", "island": PackedByteArray(), "busy": false, "error": ""}, {
		&"realm_opened": opened,
		&"realm_island": island,
		&"realm_failed": failed,
	})


static func opened(s: Dictionary, p: Dictionary) -> Dictionary:
	var next := s.duplicate()
	next["realm"] = str(p["realm"])
	next["island"] = PackedByteArray()
	next["busy"] = true
	next["error"] = ""
	return next


static func island(s: Dictionary, p: Dictionary) -> Dictionary:
	var next := s.duplicate()
	next["island"] = p["island"]
	next["busy"] = false
	return next


static func failed(s: Dictionary, p: Dictionary) -> Dictionary:
	var next := s.duplicate()
	next["busy"] = false
	next["error"] = str(p["code"])
	return next
