class_name HomeRepository
extends RefCounted
## The home (§9.3, §11.5; server/src/home.mjs): the roster, the producers and
## what each holds and when it fills, and the night the device keeps its own
## notices out of (§20.2).

var api: Api


func _init(a: Api) -> void:
	api = a


func view() -> Result:
	return await api.get_json("/v1/home")


## §5.8, §11.6: character `id` set to work at building `n` of `kind` in
## `realm`, a producer's slot or a Guardian Post. A retry of one already made
## is answered as made.
func work(id: int, realm: String, kind: String, n := 1) -> Result:
	return await api.post_json("/v1/home/characters/%d/work" % id, {"realm": realm, "kind": kind, "n": n})


## §11.6: a resting character back now, for the Essence the home says.
func wake(id: int) -> Result:
	return await api.post_json("/v1/home/characters/%d/wake" % id)


## §11.4: character `id` raised to level `to`, the next.
func level(id: int, to: int) -> Result:
	return await api.post_json("/v1/home/characters/%d/level" % id, {"to": to})
