class_name PlannerState
extends RefCounted
## The heist planner as the store holds it (§12.5): the target the scout
## report opened it on, and the plan so far — the crew by roster id in
## portrait order, the Sage by id ("" for none), the casts by law, and the
## load target.

const PLANNER := &"planner"


static func register(store: Store) -> void:
	store.register(PLANNER, {"target": {}, "crew": [], "sage": "", "casts": [], "load": 100}, {
		&"planner_opened": opened,
		&"planner_crew": crew,
		&"planner_sage": sage,
		&"planner_cast": cast,
		&"planner_load": load_target,
	})


## A new plan on the target card `card`: no crew suggested, no Sage, no
## casts, and the load target the player used last.
static func opened(s: Dictionary, p: Dictionary) -> Dictionary:
	return {"target": p["card"], "crew": [], "sage": "", "casts": [], "load": int(s.get("load", 100))}


## Character `id` joins the crew, or leaves it.
static func crew(s: Dictionary, p: Dictionary) -> Dictionary:
	var next := s.duplicate()
	var ids: Array = (s["crew"] as Array).duplicate()
	var id := int(p["id"])
	if id in ids:
		ids.erase(id)
	else:
		ids.append(id)
	next["crew"] = ids
	return next


static func sage(s: Dictionary, p: Dictionary) -> Dictionary:
	var next := s.duplicate()
	next["sage"] = str(p["sage"])
	return next


## Law `law` carried as a cast, or put back.
static func cast(s: Dictionary, p: Dictionary) -> Dictionary:
	var next := s.duplicate()
	var laws: Array = (s["casts"] as Array).duplicate()
	var law := str(p["law"])
	if law in laws:
		laws.erase(law)
	else:
		laws.append(law)
	next["casts"] = laws
	return next


static func load_target(s: Dictionary, p: Dictionary) -> Dictionary:
	var next := s.duplicate()
	next["load"] = int(p["load"])
	return next
