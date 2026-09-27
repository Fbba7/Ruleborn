class_name UniverseRepository
extends RefCounted
## The home economy (§5.2, §10.2; server/src/universe.mjs): the universe as
## the server holds it — realms, buildings, and what each can buy now — and
## each purchase. Every purchase names the level it leads to, so a retry of
## one the server already made is answered as made and never charged twice;
## they are online only, like every spend (G41).

var api: Api


func _init(a: Api) -> void:
	api = a


func view() -> Result:
	return await api.get_json("/v1/universe")


## §5.2: the next outer realm, of a `type` the player does not yet own.
func open_realm(type: String) -> Result:
	return await api.post_json("/v1/universe/realms", {"type": type})


## §5.2: an outer realm raised to level `to`, the one after its own.
func raise_realm(realm: String, to: int) -> Result:
	return await api.post_json("/v1/universe/realms/%s/level" % realm.uri_encode(), {"to": to})


## §10.2: building `n` of `kind` in `realm` taken to level `to` — built at 1.
func build(realm: String, kind: String, n: int, to: int) -> Result:
	return await api.post_json("/v1/universe/buildings", {"realm": realm, "kind": kind, "n": n, "to": to})
