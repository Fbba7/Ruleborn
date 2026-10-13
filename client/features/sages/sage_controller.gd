class_name SageController
extends RefCounted
## The Sage hall with no screen: asks the account repository and dispatches
## the answer. Who guards the Heart is the server's to keep, so a change is
## online only.

var services: Services


func _init(s: Services) -> void:
	services = s


func _store() -> Store:
	return services.store


## The hall fetched — but not over a change on its way.
func load_sages() -> void:
	if str(_store().get_slice(SageState.SAGES)["busy"]) not in ["", "view"]:
		return
	_store().dispatch(&"sages_asked")
	var r := await services.account.sages()
	if r.ok:
		_store().dispatch(&"sages_loaded", {"view": r.value})
	else:
		_store().dispatch(&"sages_failed", {"code": r.code})


## §11.7: `sage` put on guard at the Heart, or none when it is null. One
## change at a time.
func station(sage: Variant) -> void:
	if str(_store().get_slice(SageState.SAGES)["busy"]) != "":
		return
	_store().dispatch(&"guardian_asked", {"key": "guard:%s" % (sage if sage != null else "none")})
	var r := await services.account.set_guardian(sage)
	if r.ok:
		_store().dispatch(&"guardian_set", {"view": r.value})
	else:
		_store().dispatch(&"sages_failed", {"code": r.code})
