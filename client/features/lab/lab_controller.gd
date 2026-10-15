class_name LabController
extends RefCounted
## The Lab with no screen: asks the repository and dispatches the answer.
## An experiment spends Aether, online only (G41); once one runs, the
## device's own "experiment finished" timer is set from the home (§14.6).

var services: Services


func _init(s: Services) -> void:
	services = s


func _store() -> Store:
	return services.store


func _slice() -> Dictionary:
	return _store().get_slice(LabState.LAB)


func load_lab() -> void:
	if str(_slice()["busy"]) != "":
		return
	_store().dispatch(&"lab_asked", {"what": "view"})
	var r := await services.lab.view()
	if r.ok:
		_store().dispatch(&"lab_loaded", {"view": r.value})
	else:
		_store().dispatch(&"lab_failed", {"code": r.code, "detail": r.detail})


## Sphere `slot` of chamber `chamber` holds the next restored law (`step`
## +1) or the one before (-1), never one another sphere holds.
func cycle(chamber: int, slot: int, step := 1) -> void:
	var laws := LabPresenter.picks(_slice(), chamber)
	var restored: Array = (_slice()["view"] as Dictionary).get("restored", [])
	_store().dispatch(&"lab_picked", {"chamber": chamber, "laws": LabPresenter.cycled(restored, laws, slot, step)})


## §8.5: from Lab level 3, the third sphere names a chord, free.
func name_chord() -> void:
	if str(_slice()["busy"]) != "":
		return
	_store().dispatch(&"lab_asked", {"what": "sphere"})
	var r := await services.lab.name_chord()
	if not r.ok:
		_store().dispatch(&"lab_failed", {"code": r.code, "detail": r.detail})
		return
	_store().dispatch(&"lab_loaded", {"view": r.value, "said": "named:" + str(r.value.get("named", ""))})


## §8.6: chamber `chamber`'s laws placed, paid, and the timer set.
func start(chamber: int) -> void:
	if str(_slice()["busy"]) != "":
		return
	var laws := LabPresenter.picks(_slice(), chamber)
	_store().dispatch(&"lab_asked", {"what": "start:%d" % chamber})
	var r := await services.lab.start(chamber, laws)
	if not r.ok:
		_store().dispatch(&"lab_failed", {"code": r.code, "detail": r.detail})
		return
	_store().dispatch(&"lab_loaded", {"view": r.value, "said": "started"})
	await services.set_timers()
