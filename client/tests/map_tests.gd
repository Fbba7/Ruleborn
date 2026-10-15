class_name MapTests
extends RefCounted
## The Universe map (§23.2; TD.19) in words: its content headless, the views
## it reads loaded together, the screen as drawn, and the map against the
## server when one is named. The diorama it becomes is the world's.

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


## The weaving view with a crowned law and two open faults, and a home whose
## Heart Star Well is full.
static func slices() -> Dictionary:
	var w := WeavingTests.sample()
	w["stability"]["faults"] = 2
	w["realms"][0]["slots"] = [{"slot": 1, "law": "half_gravity", "tier": 1, "ready_at": 0, "weaving": false}]
	var h := RosterTests.sample()
	for p: Dictionary in h["producers"]:
		p["stored"] = 40
		p["holds"] = 500
	h["producers"][3]["stored"] = 500
	return {"weaving": {"view": w}, "home": {"view": h},
		"wallet": {"known": true, "starlight": 5625, "essence": 1234}, "defences": {"unseen": 2}}


static func drawn(s: Dictionary) -> Dictionary:
	return MapPresenter.screen(s["weaving"], s["home"], s["wallet"], s["defences"])


func _words() -> void:
	var m := drawn(slices())
	var realms: Array = m["realms"]
	check.call("the Universe map shows each realm with the laws woven in it, the crown's laws, and the universe's "
			+ "strain, band and open faults (5.1, 5.5, 23.2)",
		realms.size() == 2 and realms[0]["laws"] == "Laws: Slow rivers" and realms[1]["laws"] == "No law woven"
			and m["crown"] == "Crown: Half gravity" and m["strain"] == "Strain 22%: Quiet · open faults 2",
		"%s | %s | %s" % [realms.map(func(r: Dictionary) -> String: return r["laws"]), m["crown"], m["strain"]])
	check.call("the map shows the resources held and what each producer has ready, and alerts the player can act on: "
			+ "new raids and a full producer (9.3, 14.6, 23.2)",
		m["resources"] == "Starlight 5,625 · Essence 1,234 · Aether 1,250"
			and m["ready_lines"][3] == "Star Well in The Heart: 500 ready of 500"
			and m["alerts"] == ["New raids on your universe: 2", "Star Well in The Heart is full"]
			and m["heist"]["action"] == "Find a target",
		"%s | %s | %s" % [m["resources"], m["ready_lines"], m["alerts"]])


func _flows() -> void:
	var transport := FakeTransport.new()
	var s := Fixtures.answered(Services.build(tree.root, "https://edge.example", transport,
		"user://outbox-map-test.json"))
	s.api.token = "t"
	var d := slices()
	transport.on("GET /v1/weaving", d["weaving"]["view"])
	transport.on("GET /v1/home", d["home"]["view"])
	transport.on("GET /v1/balance", {"starlight": 5625, "essence": 1234})
	transport.on("GET /v1/defences/badge", {"unseen": 2})
	await s.map_flow.load_all()
	var m := MapPresenter.screen(s.store.get_slice(WeavingState.WEAVING), s.store.get_slice(RosterState.ROSTER),
		s.store.get_slice(ShopState.WALLET), s.store.get_slice(DefencesState.DEFENCES))
	check.call("the map asks the server for the weaving view, the home, the wallet and the raid badge, and draws from "
			+ "them (23.2)",
		m["ready"] and m["strain"] == "Strain 22%: Quiet · open faults 2" and m["alerts"].size() == 2,
		"%s" % [transport.calls.map(func(c: Dictionary) -> String: return c["route"])])
	s.close()


func _on_screen() -> void:
	var services: Services = App.services
	var d := slices()
	services.store.dispatch(&"weaving_loaded", {"view": d["weaving"]["view"]})
	services.store.dispatch(&"roster_loaded", {"view": d["home"]["view"]})
	var screen: MapScreen = await mount.call("map")
	await tree.process_frame
	services.store.dispatch(&"weaving_loaded", {"view": d["weaving"]["view"]})
	var realms := screen.body.find_children("*", "Label", true, false).filter(
		func(l: Label) -> bool: return l.has_meta("realm")).map(func(l: Label) -> String: return l.get_meta("realm"))
	var heist := false
	for b: Button in screen.find_children("*", "Button", true, false):
		heist = heist or b.get_meta("key", "") == "heist"
	screen.queue_free()
	await tree.process_frame
	check.call("the Universe map screen draws each realm and the way to a heist (23.2)",
		realms == ["heart", "outer-1"] and heist, "%s %s" % [realms, heist])


func _online() -> void:
	var name := "against the server: a new Keeper's map shows the Heart with no law woven, a Quiet universe with no "
	name += "open faults, and the resources held (5.5, 23.2)"
	if server_url == "":
		check.call(name, false, "no server: run through client/status.py, which starts one")
		return
	var s := Fixtures.answered(Services.build(tree.root, server_url, null, "user://outbox-test-map.json"))
	s.router.change = func(_path: String) -> void: pass
	var me := await s.account.sign_in("test:map")
	if not me.ok:
		check.call(name, false, "sign-in refused: %s" % me.code)
		s.close()
		return
	await s.map_flow.load_all()
	var m := MapPresenter.screen(s.store.get_slice(WeavingState.WEAVING), s.store.get_slice(RosterState.ROSTER),
		s.store.get_slice(ShopState.WALLET), s.store.get_slice(DefencesState.DEFENCES))
	check.call(name,
		m["ready"] and (m["realms"] as Array).size() == 1 and m["realms"][0]["laws"] == "No law woven"
			and str(m["strain"]).ends_with("Quiet · open faults 0") and str(m["resources"]).begins_with("Starlight "),
		"%s %s %s" % [m.get("realms"), m.get("strain"), m.get("resources")])
	s.close()
