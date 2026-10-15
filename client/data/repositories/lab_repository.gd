class_name LabRepository
extends RefCounted
## The Resonance Lab (§8.6, §10.2; server/src/lab.mjs): its chambers, the
## next experiment's price and time, what has been found and hinted, and an
## experiment started.

var api: Api


func _init(a: Api) -> void:
	api = a


## The Lab, every experiment finished by now settled first.
func view() -> Result:
	return await api.get_json("/v1/lab")


## §8.6: two restored `laws` placed in chamber `chamber`, paid now.
## Answers the Lab after it.
func start(chamber: int, laws: Array) -> Result:
	return await api.post_json("/v1/lab", {"chamber": chamber, "laws": laws})


## §8.5: the third sphere names, free and once a day, the first chord the
## player has woven or crossed. Answers the Lab after it, with `named`.
func name_chord() -> Result:
	return await api.post_json("/v1/lab/sphere")
