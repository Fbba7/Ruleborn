class_name LandingTests
extends RefCounted
## §5.4's landing picker on one island (TD.41): its words headless, the
## controller on a real island, and the heist screen as drawn.

var tree: SceneTree
var check: Callable
var mount: Callable


func _init(t: SceneTree, c: Callable, m: Callable) -> void:
	tree = t
	check = c
	mount = m


func run() -> void:
	_words()
	_picking()
	await _on_screen()
	_across()
	await _across_on_screen()


## A universe of three realms (sim/src/universe.rs's RBU1): the Heart, outer
## realm 1 joined to it and outer realm 2 joined to outer realm 1, with a
## fault from outer realm 2; and the lease's view of it.
static func universe() -> Dictionary:
	var islands: Array[PackedByteArray] = [island(false)]
	for level: int in [1, 2]:
		var i := RulebornIsland.new()
		i.reset(level)
		islands.append(i.bytes())
	var bytes := PackedByteArray("RBU1".to_ascii_buffer())
	bytes.append(3)
	for code in 3:
		bytes.append(code)
		var h := HashingContext.new()
		h.start(HashingContext.HASH_SHA256)
		h.update(islands[code])
		bytes.append_array(h.finish())
	bytes.append_array(PackedByteArray([2, 0, 1, 0, 0, 2, 1, 0, 1, 2]))
	var leased := {"digest": "", "realms": [
		{"realm": "heart", "links": 0, "ticks": null, "fault": false},
		{"realm": "outer-1", "links": 1, "ticks": 165 * 30, "fault": false},
		{"realm": "outer-2", "links": 2, "ticks": 180 * 30, "fault": true}], "flicker": 0}
	return {"bytes": bytes, "islands": islands, "leased": leased}


func _across() -> void:
	var u := universe()
	var c := HeistController.new()
	var began := c.begin_universe("42", 3, u["leased"], u["bytes"], u["islands"])
	var places := {}
	for m: Dictionary in c.marks:
		places["%s%s" % [m["code"], "f" if m.get("fault", false) else ""]] = true
	var fault: Dictionary = c.marks[c.marks.size() - 1]
	var first: Dictionary = c.marks[0]
	var p1 := LandingPresenter.picker(c.marks, 0, 0, 6, 0)
	var pf := LandingPresenter.picker(c.marks, c.marks.size() - 1, 0, 6, 0)
	var size1 := c.world.size()
	c.next_realm()
	var second: Dictionary = c.marks[c.pick]
	var size2 := c.world.size()
	var p2 := LandingPresenter.picker(c.marks, c.pick, 0, 6, 0)
	check.call("the landing picker offers every outer realm's edge spots and each fault, each choice with its realm, "
			+ "its links to the Heart and its own clock, across a universe of several realms (5.4, 23.2, T3.3)",
		began and c.choosing and places.keys() == ["1", "2", "2f"] and fault.get("fault", false)
			and int(first["code"]) == 1 and p1["realm"] == "In outer realm 1, one link from the Heart"
			and p1["clock"] == "Heist clock 2:45" and p1["across"] == "Outer realms: 2 · faults to the Heart: 1"
			and int(second["code"]) == 2 and p2["realm"] == "In outer realm 2, 2 links from the Heart"
			and p2["clock"] == "Heist clock 3:00" and size1 != size2
			and pf["spot"] == "The fault from outer realm 2: straight through to the Heart's entrance"
			and c.shown_marks().all(func(m: Dictionary) -> bool: return int(m["code"]) == 2),
		"%s | %s | %s | %s %s" % [places.keys(), p1, p2, size1, size2])
	# Landed on outer realm 1's spot on show: the replay's first command names
	# the realm, and the replay is one across the universe.
	var edge := HeistController.new()
	edge.begin_universe("42", 3, u["leased"], u["bytes"], u["islands"])
	var landed := edge.land_here()
	edge.advance(30 * 5)
	var command: Dictionary = edge.world.commands()[0]
	var replay := edge.record()
	var local := RulebornReplay.validate_universe(replay, u["bytes"], u["islands"])
	# At the fault: straight to the Heart, outer realm 2's clock.
	var cracked := HeistController.new()
	cracked.begin_universe("42", 3, u["leased"], u["bytes"], u["islands"])
	cracked.pick = cracked.marks.size() - 1
	cracked.next_spot(0)
	var through := cracked.land_here()
	cracked.advance(1)
	check.call("a landing across a universe is the replay's first command naming its realm, or its fault, and the "
			+ "heist plays realm by realm on the landing realm's clock, as the server checks it (5.4, T3.3)",
		landed and int(command["kind"]) == HeistController.Kind.LAND and int(command["actor"]) == 1
			and edge.world.realm_code() == 1 and edge.world.ticks() == 165 * 30 and local.get("ok", false)
			and through and int(cracked.world.commands()[0]["actor"]) == 8 + 2 and cracked.world.realm_code() == 0
			and cracked.world.ticks() == 180 * 30,
		"%s %s %s | %s %s" % [command, edge.world.realm_code(), local, cracked.world.commands(),
			cracked.world.realm_code()])
	check.call("the heist's top row says the realm the crew is in and how many it has yet to cross to the Heart "
			+ "(5.4, 21.8)",
		HeistHud.realm(2, 2) == "In outer realm 2, on the way to the Heart (2 to cross)"
			and HeistHud.realm(0, 0) == "In the Heart" and HeistHud.realm(-1, 0) == ""
			and edge.world.realms_to_go() == 1 and Array(edge.world.realms_crossed()) == [1],
		HeistHud.realm(2, 2))


func _across_on_screen() -> void:
	var services: Services = App.services
	services.store.dispatch(&"heist_started", {"island": island(false), "testing": true})
	var screen: HeistScreen = await mount.call("heist_screen")
	await tree.process_frame
	var u := universe()
	var began := screen.begin_universe("42", 3, u["leased"], u["bytes"], u["islands"])
	await tree.process_frame
	var shown := screen.picker_realm.visible and screen.next_realm_button.visible \
		and screen.picker_realm.text == "In outer realm 1, one link from the Heart"
	var size1 := screen.view._size
	screen.next_realm_button.pressed.emit()
	await tree.process_frame
	var moved := screen.picker_realm.text == "In outer realm 2, 2 links from the Heart" and screen.view._size != size1
	screen.controller.land_here()
	await tree.process_frame
	var in_realm := screen.hud.realm_label.visible \
		and screen.hud.realm_label.text == "In outer realm 2, on the way to the Heart (2 to cross)"
	screen.queue_free()
	services.store.dispatch(&"heist_started", {})
	await tree.process_frame
	check.call("the heist screen's picker says each choice's realm and steps realm by realm, drawing each, and the "
			+ "top row says the realm the crew is in (5.4, 21.8, T3.3)",
		began and shown and moved and in_realm, "%s %s %s %s" % [began, shown, moved, in_realm])

## A blank realm with fog and tall grass on its north edge; `defended` adds
## guards and wards, which must change no landing mark.
static func island(defended: bool) -> PackedByteArray:
	var i := RulebornIsland.new()
	i.reset(3)
	i.set_ground(2, 0, "fog_bank")
	i.set_ground(5, 0, "tall_grass")
	if defended:
		i.post_guard(0, 4, 4)
		i.post_guard(1, 7, 5)
		i.place_ward("static_coil", 6, 6)
		i.place_ward("gravity_well", 3, 7)
	return i.bytes()


func _words() -> void:
	var side := 13
	check.call("the landing picker names each edge spot by its side and place along it, covered or open, with how "
			+ "far a landing is heard and the heist clock (5.4, 23.2)",
		LandingPresenter.place(Vector2i(4, 0), side) == ["NORTH", 5]
			and LandingPresenter.place(Vector2i(0, 6), side) == ["WEST", 7]
			and LandingPresenter.place(Vector2i(12, 3), side) == ["EAST", 4]
			and LandingPresenter.place(Vector2i(2, 12), side) == ["SOUTH", 3]
			and LandingPresenter.spot({"at": Vector2i(2, 0), "covered": true}, side, 6)
				== "North edge, 3 of 13: covered, so no guard hears the skiff"
			and LandingPresenter.spot({"at": Vector2i(0, 6), "covered": false}, side, 6)
				== "West edge, 7 of 13: open, heard by guards within 6 tiles"
			and LandingPresenter.clock(150) == "Heist clock 2:30",
		LandingPresenter.spot({"at": Vector2i(2, 0), "covered": true}, side, 6))


func _picking() -> void:
	var open := HeistController.new()
	var defended := HeistController.new()
	var began: bool = open.begin("42", 600, 3, island(false)) and defended.begin("42", 600, 3, island(true))
	var marks := func(c: HeistController) -> Array:
		return c.marks.map(func(m: Dictionary) -> String: return "%s:%s" % [m["at"], m["covered"]])
	var covered: Array = open.marks.filter(func(m: Dictionary) -> bool: return m["covered"]).map(
		func(m: Dictionary) -> Vector2i: return m["at"])
	check.call("each edge spot is marked covered or open from the terrain alone, the same whatever guards and wards "
			+ "the island places (5.4, 12.4, TD.41)",
		began and open.choosing and not open.marks.is_empty() and marks.call(open) == marks.call(defended)
			and Vector2i(2, 0) in covered and Vector2i(5, 0) in covered and covered.size() == 2,
		"%s" % [covered])
	defended.next_spot(1)
	defended.next_spot(-2)
	var at: Vector2i = defended.marks[defended.pick]["at"]
	var landed := defended.land_here()
	var first: Dictionary = defended.world.commands()[0] if not defended.world.commands().is_empty() else {}
	var tapped := HeistController.new()
	tapped.begin("42", 600, 3, island(true))
	tapped.tap_tile(Vector2i(6, 6))
	var still := tapped.choosing and tapped.world.commands().is_empty()
	tapped.tap_tile(Vector2i(5, 0))
	var tap_first: Dictionary = tapped.world.commands()[0] if not tapped.world.commands().is_empty() else {}
	check.call("the chosen spot is the replay's first command, at tick 0, whether stepped to or tapped; a tap off "
			+ "the edge lands nowhere (5.4, TD.41)",
		landed and not defended.choosing and int(first.get("tick", -1)) == 0
			and int(first.get("kind", -1)) == HeistController.Kind.LAND
			and int(first["x"]) == at.x * 256 + 128 and int(first["y"]) == at.y * 256 + 128
			and still and not tapped.choosing and int(tap_first.get("x", 0)) == 5 * 256 + 128
			and int(tap_first.get("y", -1)) == 128,
		"%s %s | %s" % [at, first, tap_first])


func _on_screen() -> void:
	var services: Services = App.services
	services.store.dispatch(&"heist_started", {"island": island(true), "testing": true})
	var screen: HeistScreen = await mount.call("heist_screen")
	await tree.process_frame
	var picking: bool = screen.picker.visible and not screen.actions_node.visible and not screen.crew_node.visible \
		and screen.controller.choosing and screen.view.landing_marks.size() == screen.controller.marks.size()
	var tick := screen.controller.world.tick()
	screen._process(1.0)
	var waited := screen.controller.world.tick() == tick
	var here: Button = null
	for b: Button in screen.find_children("*", "Button", true, false):
		if b.text == Strings.t("LANDING_HERE"):
			here = b
	here.pressed.emit()
	await tree.process_frame
	var after: bool = not screen.picker.visible and screen.actions_node.visible and not screen.controller.choosing \
		and screen.controller.landed()
	screen.queue_free()
	services.store.dispatch(&"heist_started", {})
	await tree.process_frame
	check.call("the heist screen shows the picker in place of the action and crew rows, its clock waits until the "
			+ "crew lands, and Land here lands it (5.4, 21.8)",
		picking and waited and after, "%s %s %s" % [picking, waited, after])
