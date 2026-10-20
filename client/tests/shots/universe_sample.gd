class_name UniverseSample
extends RefCounted
## A full universe as the server answers GET /v1/universe, for the map's
## stills and tests: the Heart and six outer realms, each with buildings at
## their levels, links of all four kinds, a fault, and the producers the home
## view adds. `outer` keeps that many outer realms.


static func view(outer := 6) -> Dictionary:
	var types := ["Skyfield", "Tidehold", "Crystalline", "Verdant", "Emberreach", "Lantern Vale"]
	var realms: Array = [{"realm": "heart", "type": "Heart", "level": 6, "buildings": [
		_b("vault", 1, 5), _b("star_well", 1, 4), _b("hearth", 1, 5), _b("library", 1, 3), _b("garden", 1, 4),
		_b("nursery", 1, 2), _b("observatory", 1, 6), _b("ward", 1, 3), _b("ward", 2, 2), _b("storehouse", 1, 4),
		_b("guardian_post", 1, 3), _b("aether_spring", 1, 2), _b("beacon", 1, 5)], "room": [], "raise": null}]
	var kinds := [["star_well", "garden", "guardian_post", "ward"], ["aether_spring", "storehouse", "ward"],
		["resonance_lab", "star_well", "ward", "ward"], ["garden", "nursery", "hearth"],
		["beacon", "guardian_post", "ward"], ["observatory", "library", "ward"]]
	for i in mini(outer, types.size()):
		var bs: Array = []
		var n := {}
		for k: String in kinds[i]:
			n[k] = int(n.get(k, 0)) + 1
			bs.append(_b(k, n[k], 1 + (i + bs.size()) % 6))
		realms.append({"realm": "outer-%d" % (i + 1), "type": types[i], "level": 1 + i % 4, "buildings": bs,
			"room": [], "raise": null})
	var links: Array = []
	var plan := [["heart", "outer-1", "stone_bridge"], ["heart", "outer-2", "rope_bridge"],
		["heart", "outer-3", "stone_bridge"], ["heart", "outer-4", "rift"], ["outer-2", "outer-3", "chute"],
		["outer-1", "outer-5", "rope_bridge"], ["outer-4", "outer-6", "stone_bridge"]]
	var k := 1
	for l: Array in plan:
		var far := int(str(l[1]).get_slice("-", 1))
		var near := int(str(l[0]).get_slice("-", 1)) if str(l[0]) != "heart" else 0
		if far <= outer and near <= outer:
			links.append({"n": k, "kind": l[2], "a": l[0], "b": l[1], "open": true})
			k += 1
	var open: Variant = null
	if outer < types.size():
		open = {"realm": "outer-%d" % (outer + 1), "types": [types[outer]], "cost": 2000,
			"needs": {"keeper": 6, "spire": 1}, "blocked": null}
	return {"keeper": 14, "spire": 4, "starlight": 12650, "realms": realms, "links": links, "open": open,
		"faults": ["outer-5"] if outer >= 5 else [], "depth": {}, "deepest": 2}


static func _b(kind: String, n: int, level: int) -> Dictionary:
	return {"kind": kind, "name": kind, "n": n, "level": level, "top": 10, "next": null}


## What the home and the raid badge add.
static func extras() -> Dictionary:
	return {"band": 1, "strain": 0.74, "raids": 2, "characters": [
		{"kind": "featherkin", "state": "working", "home": "spire",
			"work": {"realm": "heart", "kind": "star_well", "n": 1}},
		{"kind": "mossbear", "state": "idle", "home": "spire", "work": null},
		{"kind": "tidewalker", "state": "working", "home": "outer-2",
			"work": {"realm": "outer-2", "kind": "aether_spring", "n": 1}}], "producers": [
		{"kind": "star_well", "realm": "heart", "stored": 320, "holds": 320},
		{"kind": "garden", "realm": "outer-4", "stored": 85, "holds": 200},
		{"kind": "aether_spring", "realm": "outer-2", "stored": 40, "holds": 140}]}
