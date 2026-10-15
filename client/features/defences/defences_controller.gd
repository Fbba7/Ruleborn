class_name DefencesController
extends RefCounted
## The defence log with no screen: asks the repository and dispatches the
## answer. Reading the log clears the raid badge; Watch replay fetches the
## replay and the island it was played on; Trace leases the raider's island
## with no fee (§12.3).

var services: Services


func _init(s: Services) -> void:
	services = s


func _store() -> Store:
	return services.store


func _slice() -> Dictionary:
	return _store().get_slice(DefencesState.DEFENCES)


func load_log() -> void:
	if str(_slice()["busy"]) != "":
		return
	_store().dispatch(&"defences_asked", {"what": "view"})
	var r := await services.defences.view()
	if r.ok:
		_store().dispatch(&"defences_loaded", {"view": r.value})
	else:
		_store().dispatch(&"defences_failed", {"code": r.code, "detail": r.detail})


## The raid badge's count, asked without reading the log.
func load_badge() -> void:
	var r := await services.defences.badge()
	if r.ok:
		_store().dispatch(&"defences_badge", {"unseen": int(r.value.get("unseen", 0))})


## §13: "The defender ... can watch the replay": the replay and the island
## it was played on, then the replay screen.
func watch(raid: Dictionary) -> void:
	if str(_slice()["busy"]) != "":
		return
	_store().dispatch(&"defences_asked", {"what": "watch"})
	var replay := await services.heists.replay(str(raid["heist"]))
	if not replay.ok:
		_store().dispatch(&"defences_failed", {"code": replay.code, "detail": replay.detail})
		return
	var island := await services.heists.fetch(str(raid["island"]))
	if not island.ok:
		_store().dispatch(&"defences_failed", {"code": island.code, "detail": island.detail})
		return
	_store().dispatch(&"defences_watching", {"replay": replay.value, "island": island.value})
	services.router.go(&"replay")


## §12.3's Trace on the raider's island, with no fee.
func trace(raid: Dictionary) -> void:
	_store().dispatch(&"heist_started", {"target": {"bundle": raid["trace"]["bundle"], "trace": true}})
	services.router.go(&"heist")
