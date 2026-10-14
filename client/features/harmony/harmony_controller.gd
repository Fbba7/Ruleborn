class_name HarmonyController
extends RefCounted
## The Harmony view with no screen: asks the weaving repository and
## dispatches the answer.

var services: Services


func _init(s: Services) -> void:
	services = s


func load_harmony() -> void:
	if bool(services.store.get_slice(HarmonyState.HARMONY)["busy"]):
		return
	services.store.dispatch(&"harmony_asked")
	var r := await services.weaving.harmony()
	if r.ok:
		services.store.dispatch(&"harmony_loaded", {"view": r.value})
	else:
		services.store.dispatch(&"harmony_failed", {"code": r.code})
