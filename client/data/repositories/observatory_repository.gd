class_name ObservatoryRepository
extends RefCounted
## The Observatory (§12.3, §12.4; server/src/observatory.mjs): the targets
## offered, each as its free target card, a Trace apart, and the paid
## refresh.

var api: Api


func _init(a: Api) -> void:
	api = a


func view() -> Result:
	return await api.get_json("/v1/observatory")


## §12.3: a new list, for 50 Aether doubling with each refresh in the hour.
func refresh() -> Result:
	return await api.post_json("/v1/observatory/refresh")
