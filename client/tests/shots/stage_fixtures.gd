class_name StageFixtures
extends RefCounted
## The realms the screens' shots draw (tools/render/shoot.sh): a lived-in
## Heart with its buildings, workers, laws and defence, and the slices the
## realm, curation and observatory screens read it from.


## A level 3 Heart, dressed: woods, a pond, raised ground, a lantern and a
## statue; its two guard posts, three wards and two laws, as §5.2 allows.
static func island() -> PackedByteArray:
	var i := RulebornIsland.new()
	i.reset(3)
	var put := {"tree": [[0, 0], [1, 0], [0, 1], [11, 0], [11, 1], [10, 11], [11, 11], [0, 11]],
		"bush": [[2, 0], [9, 11], [11, 6]], "hedge": [[4, 8], [5, 8]], "pond": [[10, 2], [10, 3]],
		"flower_meadow": [[1, 10], [2, 10], [2, 11], [9, 0]], "tall_grass": [[7, 10], [8, 10], [7, 11]],
		"raised_ground": [[9, 9], [10, 9], [9, 10], [10, 10]], "lantern_post": [[6, 6]], "statue": [[3, 3]],
		"boulder": [[11, 8]], "gravel_path": [[6, 2], [6, 3], [6, 4], [6, 5], [7, 6], [8, 6], [5, 6], [4, 6], [6, 7]],
		"fog_bank": [[0, 7]], "crystal_outcrop": [[11, 4]], "fence": [[8, 3], [8, 4]]}
	for id: String in put:
		for xy: Array in put[id]:
			i.set_ground(xy[0], xy[1], id)
	i.place_building("star_well", 1, 3)
	i.place_building("garden", 2, 8)
	i.place_building("storehouse", 9, 6)
	i.place_building("hearth", 4, 1)
	i.post_guard(0, 7, 8)
	i.post_guard(1, 3, 6)
	i.place_ward("static_coil", 8, 9)
	i.place_ward("lantern_glare", 5, 4)
	i.place_ward("thorn_hedge", 10, 7)
	i.weave("bloom", 7, 3)
	i.weave("slow_rivers", 4, 10)
	return i.bytes()


static func universe() -> Dictionary:
	return {"starlight": 100, "spire": 1, "keeper": 1, "open": null, "realms": [
		{"realm": "heart", "type": "Heart", "level": 3, "room": [], "raise": null, "island": "b-heart",
			"buildings": [{"kind": "star_well", "name": "Star Well", "n": 1, "level": 5, "top": 10, "next": null,
				"at": {"x": 1, "y": 3}},
				{"kind": "garden", "name": "Garden", "n": 1, "level": 3, "top": 10, "next": null, "at": {"x": 2, "y": 8}},
				{"kind": "storehouse", "name": "Storehouse", "n": 1, "level": 7, "top": 10, "next": null,
					"at": {"x": 9, "y": 6}},
				{"kind": "hearth", "name": "Hearth", "n": 1, "level": 2, "top": 10, "next": null, "at": {"x": 4, "y": 1}},
				{"kind": "library", "name": "Library", "n": 1, "level": 1, "top": 10, "next": null, "at": null}]}]}


## Services with the realm view's slices in the store, the island given.
static func realm(services: Services) -> void:
	var home := RosterTests.sample()
	for p: Dictionary in home["producers"]:
		if str(p["realm"]) == "heart" and str(p["kind"]) == "garden":
			p["workers"] = [4]
	# Two of the Heart's own, idle, to stroll between its doors.
	for c: Dictionary in [{"id": 5, "kind": "bloomling", "role": "Mender"},
			{"id": 6, "kind": "emberling", "role": "Breaker"}]:
		c.merge({"school": "Life", "traits": [], "level": 1, "top": 2, "home": "heart", "via": "woke", "state": "idle",
			"work": null, "next_level": null})
		(home["characters"] as Array).append(c)
	services.store.dispatch(&"universe_loaded", {"view": universe()})
	services.store.dispatch(&"weaving_loaded", {"view": WeavingTests.sample()})
	services.store.dispatch(&"roster_loaded", {"view": home})
	services.store.dispatch(&"realm_opened", {"realm": "heart"})
	services.store.dispatch(&"realm_island", {"island": island()})
