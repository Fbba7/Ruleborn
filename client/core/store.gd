class_name Store
extends RefCounted
## The app's state, in one place, changed in one way. A screen never writes
## state: it sends an action, a reducer for that action's kind returns the
## new value of its slice, and every listener is told which slice changed.
## Reducers are plain functions of (slice, action), so each is tested
## headless, and every action goes into the log, so a defect report says what
## the player did (unidirectional data flow, as Redux and The Composable
## Architecture do it).

signal changed(slice: StringName)

var log := ActionLog.new()
var _state: Dictionary = {}
## kind -> [slice, reducer]
var _reducers: Dictionary = {}


## A slice and its starting value, and the reducers that own it: {kind: fn}.
## A kind belongs to one slice only, so an action changes one thing.
func register(slice: StringName, initial: Variant, reducers: Dictionary) -> void:
	assert(not _state.has(slice), "slice %s registered twice" % slice)
	_state[slice] = initial
	for kind: StringName in reducers:
		assert(not _reducers.has(kind), "action %s has two reducers" % kind)
		_reducers[kind] = [slice, reducers[kind]]


func get_slice(slice: StringName) -> Variant:
	assert(_state.has(slice), "no slice %s" % slice)
	return _state[slice]


## Apply one action. An action no reducer owns is a defect, and fails loudly
## in a debug build rather than doing nothing.
func dispatch(kind: StringName, payload := {}) -> void:
	log.add("action", kind, payload)
	if not _reducers.has(kind):
		push_error("no reducer for action %s" % kind)
		assert(false, "no reducer for action %s" % kind)
		return
	var slice: StringName = _reducers[kind][0]
	var reducer: Callable = _reducers[kind][1]
	_state[slice] = reducer.call(_state[slice], payload)
	changed.emit(slice)
