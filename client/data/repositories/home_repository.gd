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
