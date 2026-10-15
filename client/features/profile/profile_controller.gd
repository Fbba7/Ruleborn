class_name ProfileController
extends RefCounted
## The Profile with no screen: asks the repository and dispatches the answer.

var services: Services


func _init(s: Services) -> void:
	services = s


func _store() -> Store:
	return services.store


func load_profile() -> void:
	await _ask("view", services.profile.view)


## §20.2's switch: the profile shown to others, or hidden.
func share(on: bool) -> void:
	await _ask("share", services.profile.share.bind(on))


func _ask(what: String, call: Callable) -> void:
	if str(_store().get_slice(ProfileState.PROFILE)["busy"]) != "":
		return
	_store().dispatch(&"profile_asked", {"what": what})
	var r: Result = await call.call()
	if r.ok:
		_store().dispatch(&"profile_loaded", {"view": r.value})
	else:
		_store().dispatch(&"profile_failed", {"code": r.code, "detail": r.detail})
