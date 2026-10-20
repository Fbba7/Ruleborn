class_name ShotData
extends RefCounted
## Sample states for the character screens' stills: RosterTests' home grown
## to a roster with every school in it.


static func roster() -> Dictionary:
	var v := RosterTests.sample()
	var more := [["skyskipper", "Motion", "Carrier", "working"], ["glass_golem", "Matter", "Warden", "idle"],
		["emberling", "Energy", "Breaker", "idle"], ["bloomling", "Life", "Mender", "idle"],
		["lantern_wisp", "Spirit", "Scout", "idle"], ["stormhound", "Energy", "Scout", "idle"],
		["hourkeeper", "Time", "Mender", "idle"], ["soulmender", "Spirit", "Mender", "idle"]]
	var id := 5
	for m: Array in more:
		var work: Variant = null
		if m[3] == "working":
			work = {"realm": "heart", "kind": "garden", "n": 1, "since": 0, "counts_from": 0}
		(v["characters"] as Array).append({"id": id, "kind": m[0], "school": m[1], "role": m[2],
			"traits": ["swift", "steady"], "level": 2 + id % 4, "top": 10, "home": "outer-1", "via": "birth",
			"state": m[3], "work": work, "next_level": {"to": 3 + id % 4, "cost": 200, "blocked": null}})
		id += 1
	return v
