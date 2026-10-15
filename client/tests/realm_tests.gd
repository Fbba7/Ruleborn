class_name RealmTests
extends RefCounted
## The realm view (§23.2; TD.19) in words: its content headless, the views
## and island it reads, the screen as drawn, and the view against the server
## when one is named. The diorama it becomes is the world's.

var tree: SceneTree
var check: Callable
var mount: Callable
var server_url := ""


func _init(t: SceneTree, c: Callable, m: Callable, url: String) -> void:
	tree = t
	check = c
	mount = m
	server_url = url


func run() -> void:
	_words()
	await _flows()
	await _on_screen()
	await _online()


## The Heart at realm level 3 with a placed Star Well and an unplaced Garden,
## its island published (fog and tall grass, two guards, two wards).
static func slices() -> Dictionary:
	var universe := {"starlight": 100, "spire": 1, "keeper": 1, "open": null, "realms": [
		{"realm": "heart", "type": "Heart", "level": 3, "room": [], "raise": null, "island": "b-heart",
			"buildings": [{"kind": "star_well", "name": "Star Well", "n": 1, "level": 2, "top": 10, "next": null,
				"at": {"x": 4, "y": 5}},
				{"kind": "garden", "name": "Garden", "n": 1, "level": 1, "top": 10, "next": null, "at": null}]}]}
	return {"view": {"realm": "heart", "island": LandingTests.island(true), "busy": false, "error": ""},
		"universe": {"view": universe}, "weaving": {"view": WeavingTests.sample()},
		"home": {"view": RosterTests.sample()}}


static func drawn(s: Dictionary) -> Dictionary:
	return RealmPresenter.screen(s["view"], s["universe"], s["weaving"], s["home"])


func _words() -> void:
	var r := drawn(slices())
	check.call("the realm view reads its grid and terrain from the realm's published island, and its wards and guard "
			+ "posts against §5.2's limits at its level (5.2, 6.2, 23.2)",
		r["title"] == "The Heart · realm level 3"
			and r["island"] == ["Grid 12 by 12 tiles", "Terrain: Fog bank 1, Tall grass 1",
				"Wards 2 of 6 · guard posts 2 of 2"],
		"%s | %s" % [r.get("title"), r.get("island")])
	check.call("the realm view lists each building with its level and tile, who works each producer, and each law "
			+ "pylon with what is woven in it (5.1, 10.1, 14.1, 23.2)",
		r["buildings"] == ["Star Well, level 2, at 4, 5", "Garden, level 1, not placed"]
			and "Star Well: Featherkin 1" in r["workers"] and "Garden: nobody working" in r["workers"]
			and r["pylons"] == ["Pylon 1: Slow rivers", "Pylon 2: empty"],
		"%s | %s | %s" % [r["buildings"], r["workers"], r["pylons"]])
	var bare := slices()
	bare["view"]["island"] = PackedByteArray()
	check.call("a realm with no island published says so (23.2)",
		drawn(bare)["island"] == ["No island published for this realm yet"], "%s" % [drawn(bare)["island"]])


func _flows() -> void:
	var transport := FakeTransport.new()
	var s := Fixtures.answered(Services.build(tree.root, "https://edge.example", transport,
		"user://outbox-realm-test.json"))
	s.api.token = "t"
	var routes: Array[StringName] = []
	s.router.change = func(path: String) -> void: routes.append(StringName(path.get_file().get_basename()))
	var d := slices()
	transport.on("GET /v1/universe", d["universe"]["view"])
	transport.on("GET /v1/weaving", d["weaving"]["view"])
	transport.on("GET /v1/home", d["home"]["view"])
	transport.on("GET /v1/bundles/b-heart", LandingTests.island(true))
	s.realm_flow.open("heart")
	await s.realm_flow.load_realm()
	var r := RealmPresenter.screen(s.store.get_slice(RealmState.REALM), s.store.get_slice(UniverseState.UNIVERSE),
		s.store.get_slice(WeavingState.WEAVING), s.store.get_slice(RosterState.ROSTER))
	check.call("a realm opened from the Universe map fetches its published island by its bundle and draws from it "
			+ "(23.2, 24.8)",
		&"realm" in routes and r["ready"] and r["island"][0] == "Grid 12 by 12 tiles"
			and transport.calls.any(func(c: Dictionary) -> bool: return c["route"] == "GET /v1/bundles/b-heart"),
		"%s %s" % [routes, r.get("island")])
	s.close()


func _on_screen() -> void:
	var services: Services = App.services
	var d := slices()
	services.store.dispatch(&"universe_loaded", {"view": d["universe"]["view"]})
	services.store.dispatch(&"realm_opened", {"realm": "heart"})
	services.store.dispatch(&"realm_island", {"island": d["view"]["island"]})
	var screen: RealmScreen = await mount.call("realm")
	await tree.process_frame
	services.store.dispatch(&"realm_island", {"island": d["view"]["island"]})
	var sections := screen.body.get_children().map(func(c: Node) -> String:
		var inner := c.find_children("*", "VBoxContainer", true, false)
		return str(inner[0].get_meta("section", "")) if not inner.is_empty() else "")
	screen.queue_free()
	await tree.process_frame
	check.call("the realm view screen draws the grid and terrain, the buildings, the workers and the law pylons (23.2)",
		sections == ["island", "buildings", "workers", "pylons"], "%s" % [sections])


func _online() -> void:
	var name := "against the server: a new Keeper's Heart shows its starting buildings and two empty law pylons, and "
	name += "says no island is published yet (10.2, 23.2)"
	if server_url == "":
		check.call(name, false, "no server: run through client/status.py, which starts one")
		return
	var s := Fixtures.answered(Services.build(tree.root, server_url, null, "user://outbox-test-realm.json"))
	s.router.change = func(_path: String) -> void: pass
	var me := await s.account.sign_in("test:realm")
	if not me.ok:
		check.call(name, false, "sign-in refused: %s" % me.code)
		s.close()
		return
	s.realm_flow.open("heart")
	await s.realm_flow.load_realm()
	var r := RealmPresenter.screen(s.store.get_slice(RealmState.REALM), s.store.get_slice(UniverseState.UNIVERSE),
		s.store.get_slice(WeavingState.WEAVING), s.store.get_slice(RosterState.ROSTER))
	check.call(name,
		r["ready"] and (r["buildings"] as Array).size() >= 5 and r["pylons"] == ["Pylon 1: empty", "Pylon 2: empty"]
			and r["island"] == ["No island published for this realm yet"],
		"%s %s %s" % [r.get("buildings"), r.get("pylons"), r.get("island")])
	s.close()
