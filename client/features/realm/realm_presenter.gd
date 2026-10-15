class_name RealmPresenter
extends RefCounted
## The realm view in words (§23.2: "Build and shape one realm. Grid, terrain
## and budget, buildings, workers, pylons, wards, guard posts"): the grid and
## the terrain features laid on it, read from the realm's published island;
## each building with its level and tile; who works each producer; the law
## pylons and what is woven in each; and the wards and guard posts against
## §5.2's limits at the realm's level. §6.1's terrain budget is the terrain
## editor's (TD.22); the diorama is the world's (TD.19).


## The realm `id` of the universe view, or {}.
static func realm_of(universe: Dictionary, id: String) -> Dictionary:
	for r: Dictionary in (universe.get("view", {}) as Dictionary).get("realms", []):
		if str(r["realm"]) == id:
			return r
	return {}


static func screen(view: Dictionary, universe: Dictionary, weaving: Dictionary, home: Dictionary) -> Dictionary:
	var id := str(view.get("realm", "heart"))
	var r := realm_of(universe, id)
	var h: Dictionary = home.get("view", {})
	var out := {"ready": not r.is_empty() and not h.is_empty() and not bool(view.get("busy", false)),
		"error": Errors.message("RV_FAILED", str(view["error"])) if str(view.get("error", "")) != "" else ""}
	if not out["ready"]:
		return out
	out["title"] = Strings.t("RV_VIEW_TITLE", [UniversePresenter.realm_name(str(r.get("type", "Heart"))),
		int(r.get("level", 3))])
	var lines: Array[String] = []
	var bytes: PackedByteArray = view.get("island", PackedByteArray())
	var island := RulebornIsland.new()
	if not bytes.is_empty() and island.read(bytes):
		lines.append(Strings.t("RV_GRID", [island.side(), island.side()]))
		lines.append(terrain(island))
		var b: Dictionary = island.budget()
		lines.append(Strings.t("RV_HOLDS", [b["wards"][0], b["wards"][1], b["guards"][0], b["guards"][1]]))
	else:
		lines.append(Strings.t("RV_NO_ISLAND"))
	out["island"] = lines
	var buildings: Array[String] = []
	for bd: Dictionary in r.get("buildings", []):
		var name := UniversePresenter.building_name(str(bd["kind"]), str(bd.get("name", "")))
		var at: Variant = bd.get("at")
		buildings.append(Strings.t("RV_BUILDING", [name, int(bd["level"]), int(at["x"]), int(at["y"])])
			if at is Dictionary else Strings.t("RV_BUILDING_UNPLACED", [name, int(bd["level"])]))
	out["buildings"] = buildings
	var named := RosterPresenter.names(h.get("characters", []))
	var workers: Array[String] = []
	for p: Dictionary in h.get("producers", []):
		if str(p["realm"]) != id:
			continue
		var who := (p.get("workers", []) as Array).map(func(w: Variant) -> String: return str(named.get(int(w), "")))
		workers.append(Strings.t("RV_WORKERS", [UniversePresenter.building_name(str(p["kind"])), ", ".join(who)])
			if not who.is_empty() else Strings.t("RV_NO_WORKERS", UniversePresenter.building_name(str(p["kind"]))))
	out["workers"] = workers
	var pylons: Array[String] = []
	for wr: Dictionary in (weaving.get("view", {}) as Dictionary).get("realms", []):
		if str(wr["realm"]) != id:
			continue
		for s: Dictionary in wr.get("slots", []):
			pylons.append(Strings.t("RV_PYLON", [int(s["slot"]), Strings.term("LAW", str(s["law"]))])
				if s.get("law") is String else Strings.t("RV_PYLON_EMPTY", int(s["slot"])))
	out["pylons"] = pylons
	return out


## The terrain features laid on the grid, counted by kind.
static func terrain(island: RulebornIsland) -> String:
	var counts := {}
	for y in island.side():
		for x in island.side():
			var g := str(island.ground(x, y))
			if g != "" and g != "plain":
				counts[g] = int(counts.get(g, 0)) + 1
	if counts.is_empty():
		return Strings.t("RV_NO_TERRAIN")
	var kinds := counts.keys()
	kinds.sort()
	return Strings.t("RV_TERRAIN", ", ".join(kinds.map(func(k: String) -> String:
		return Strings.t("SCOUT_COUNT", [Strings.term("GROUND", k), int(counts[k])]))))
