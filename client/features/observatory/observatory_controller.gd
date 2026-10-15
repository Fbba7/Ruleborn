class_name ObservatoryController
extends RefCounted
## The Observatory with no screen: asks the repository and dispatches the
## answer. A refresh spends Aether, online only (G41).

var services: Services


func _init(s: Services) -> void:
	services = s


func _store() -> Store:
	return services.store


func load_observatory() -> void:
	if str(_store().get_slice(ObservatoryState.OBSERVATORY)["busy"]) != "":
		return
	await _ask("view", services.observatory.view)
	if (_store().get_slice(ObservatoryState.OBSERVATORY)["words"] as Dictionary).is_empty():
		var w := await services.first_repo.words()
		if w.ok:
			_store().dispatch(&"observatory_words", {"words": w.value})


## §12.3's refresh, paid.
func refresh() -> void:
	if str(_store().get_slice(ObservatoryState.OBSERVATORY)["busy"]) != "":
		return
	await _ask("refresh", services.observatory.refresh)


func _ask(what: String, call: Callable) -> void:
	_store().dispatch(&"observatory_asked", {"what": what})
	var r: Result = await call.call()
	if r.ok:
		_store().dispatch(&"observatory_loaded", {"view": r.value})
	else:
		_store().dispatch(&"observatory_failed", {"code": r.code, "detail": r.detail})


## The scout report for the target `bundle`.
func choose(bundle: String) -> void:
	_store().dispatch(&"observatory_chosen", {"bundle": bundle})
	services.router.go(&"scout")


## The scout report's Plan: the planner on the chosen target (§12.5), whose
## Start leases it (§24.12), a Trace as one.
func raid(card: Dictionary) -> void:
	services.planner_flow.open(card)
