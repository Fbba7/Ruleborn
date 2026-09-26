class_name KeeperController
extends RefCounted
## The Keeper bar with no screen: asks the server for the level and
## dispatches the answer.

var services: Services


func _init(s: Services) -> void:
	services = s


func load_keeper() -> void:
	var r := await services.account.keeper()
	if r.ok:
		services.store.dispatch(&"keeper_loaded", {"view": r.value})
	else:
		services.store.dispatch(&"keeper_failed", {"code": r.code})
