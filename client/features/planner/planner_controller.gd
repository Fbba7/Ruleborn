class_name PlannerController
extends RefCounted
## The heist planner with no screen (§12.5): what it reads is the roster, the
## Sages, the Codex and the Keeper's limits, each asked for once; Start turns
## the plan into the crew manifest the replay carries and opens the heist,
## which leases the target and lands where the player picks (§5.4).

var services: Services


func _init(s: Services) -> void:
	services = s


func _store() -> Store:
	return services.store


func _slice() -> Dictionary:
	return _store().get_slice(PlannerState.PLANNER)


## The scout report's Plan: the planner opened on `card`.
func open(card: Dictionary) -> void:
	_store().dispatch(&"planner_opened", {"card": card})
	services.router.go(&"planner")


## What the planner draws from, each fetched when it is not held yet.
func load_all() -> void:
	if (_store().get_slice(RosterState.ROSTER)["view"] as Dictionary).is_empty():
		await services.roster_flow.load_roster()
	if (_store().get_slice(SageState.SAGES)["view"] as Dictionary).is_empty():
		await services.sage_flow.load_sages()
	if (_store().get_slice(CodexState.CODEX)["view"] as Dictionary).is_empty():
		await services.codex_flow.load_codex()
	if not (_store().get_slice(KeeperState.KEEPER)["view"] as Dictionary).has("plan"):
		await services.keeper_flow.load_keeper()


func _screen() -> Dictionary:
	return PlannerPresenter.screen(_slice(), _store().get_slice(KeeperState.KEEPER),
		_store().get_slice(RosterState.ROSTER), _store().get_slice(SageState.SAGES),
		_store().get_slice(CodexState.CODEX), _store().get_slice(ObservatoryState.OBSERVATORY))


## The option `key` of the list `list` on show, if the player may take it.
func _may(list: String, key: String) -> bool:
	var p := _screen()
	if not p["ready"]:
		return false
	for o: Dictionary in p[list]:
		if o["key"] == key:
			return o["can"] or o.get("picked", false)
	return false


## Character `id` joins the crew or leaves it: never a resting one, nor one
## past the Keeper's most.
func toggle(id: int) -> void:
	if _may("crew", "crew:%d" % id):
		_store().dispatch(&"planner_crew", {"id": id})


func pick_sage(id: String) -> void:
	if _may("sages", "sage:" + id):
		_store().dispatch(&"planner_sage", {"sage": id})


func toggle_cast(law: String) -> void:
	if _may("casts", "cast:" + law):
		_store().dispatch(&"planner_cast", {"law": law})


## The load target one step up (+1) or down (-1), within §12.5's range.
func step_load(step: int) -> void:
	var steps: Array = PlannerPresenter.limits(_store().get_slice(KeeperState.KEEPER))["load"]
	var target := clampi(int(_slice()["load"]) + step * int(steps[2]), int(steps[0]), int(steps[1]))
	_store().dispatch(&"planner_load", {"load": target})


## §12.5's Start: the plan as the heist's crew manifest, then the heist.
func start() -> void:
	var p := _screen()
	if not p["ready"] or not p["start"]["can"]:
		return
	var card: Dictionary = _slice()["target"]
	# §5.4: a target whose raid crosses a universe is leased across it.
	_store().dispatch(&"heist_started", {"target": {"bundle": card["bundle"], "trace": card.get("kind") == "trace",
		"across": bool(card.get("across", false))}, "plan": p["plan"]})
	services.router.go(&"heist")
