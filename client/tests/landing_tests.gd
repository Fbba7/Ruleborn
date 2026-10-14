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
