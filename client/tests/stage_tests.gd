class_name StageTests
extends RefCounted
## The realm screens' 3D (world/stage_*.gd, world/overlay_*.gd): the realm a
## screen draws is the simulation's reading of the island it holds, its
## buildings stand where the island puts them at the levels the universe
## gives, the defence overlay reads the simulation's guards, the scout draws
## nothing placed, the builder's edits undo and its ghost says what the
## island takes, and the Observatory's pictures come from one viewport.

var tree: SceneTree
var check: Callable
var mount: Callable


func _init(t: SceneTree, c: Callable, m: Callable) -> void:
	tree = t
	check = c
	mount = m


func run() -> void:
	_realm()
	_defence()
	await _scout()
	await _builder()
	await _drag()
	await _fold()
	await _thumbs()


func _realm() -> void:
	var island := RulebornIsland.new()
	island.read(StageFixtures.island())
	var listed: Array = (StageFixtures.universe()["realms"][0] as Dictionary)["buildings"]
	var b := StageRealm.buildings(island, listed)
	var kinds := b.map(func(x: Dictionary) -> String: return "%s@%s L%d" % [x["kind"], x["at"], x["level"]])
	var bare := RulebornIsland.new()
	bare.read(StageRealm.without_buildings(island))
	var replay := StageRealm.replay_of(StageRealm.blank(3))
	check.call("a realm screen draws the island's own buildings at the levels the universe gives them, lifts them off "
			+ "the island it hands the world so none stands twice, and starts the world from the island's bytes "
			+ "(23.2, 21.5)",
		kinds == ["star_well@(1, 3) L5", "garden@(2, 8) L3", "hearth@(4, 1) L2", "storehouse@(9, 6) L7"]
			and bare.buildings().is_empty() and replay != null and replay.size() == Vector2i(12, 12)
			and StageRealm.realm_type("Lantern Vale") == "lanternvale" and StageRealm.realm_type("?") == "heart",
		"%s %s %s" % [kinds, bare.buildings(), replay])


func _defence() -> void:
	var island := RulebornIsland.new()
	island.read(StageFixtures.island())
	var replay := StageRealm.replay_of(island.bytes())
	var moves := CurationScreen.moves(island, Vector2i(7, 8))
	var picked := OverlayDefence.guard_at(replay, Vector2i(7, 8))
	var none := OverlayDefence.guard_at(replay, Vector2i(0, 0))
	check.call("the defence overlay finds the picked post among the simulation's guards and paints each of its four "
			+ "moves as the island allows it (13.3, 21.12)",
		picked >= 0 and none == -1 and moves.size() == 4 and moves[Vector2i(7, 7)] == true
			and moves[Vector2i(7, 9)] == true,
		"%d %d %s" % [picked, none, moves])


func _scout() -> void:
	var view := StageView.new()
	view.size = Vector2(540, 960)
	tree.root.add_child(view)
	var pins := OverlayPins.new(view)
	view.set_meta("pins", pins)
	tree.root.add_child(pins)
	var scout := StageScout.new(view)
	view.show_replay(StageRealm.replay_of(StageRealm.blank(3)))
	view.show_vault(false)
	var card: Dictionary = (ObservatoryTests.sample()["targets"] as Array)[0]
	scout.build(card["realm"])
	await tree.process_frame
	# Two guards and three wards in the card: five figures, on the rim, none
	# on a tile; two kinds of each, so four counts; two laws, two banners.
	var on_grid := scout.figures.get_children().filter(func(n: Node3D) -> bool:
		return absf(n.position.x) < 6.0 and absf(n.position.z) < 6.0)
	check.call("the scout report draws what the scout counted and nothing placed: the guards by role and wards by kind "
			+ "on the rim with their counts pinned, the laws as banners, and the Vault hidden (12.4)",
		scout.figures.get_child_count() == 5 and on_grid.is_empty() and pins.count() == 4 and scout.banners.mesh != null
			and not view._vault.visible and not view.anchors.vault_shown,
		"%d figures, %d on the grid, %d pins" % [scout.figures.get_child_count(), on_grid.size(), pins.count()])
	pins.queue_free()
	view.queue_free()
	await tree.process_frame


func _builder() -> void:
	var builder: BuilderScreen = await mount.call("builder")
	builder.island.reset(3)
	builder.undo_stack.clear()
	builder.tool = BuilderScreen.Tool.GROUND
	builder.kind = builder.kinds().find("boulder")
	builder.tap_tile(Vector2i(3, 3))
	var laid := builder.island.ground(3, 3) == "boulder" and builder.last_ok
	builder.tool = BuilderScreen.Tool.WARD
	builder.kind = 0
	var takes := builder.would_take(Vector2i(5, 5))
	var vault := Vector2i(-1, -1)
	for y in builder.island.side():
		for x in builder.island.side():
			if builder.island.occupant(x, y) == "vault":
				vault = Vector2i(x, y)
	var refuses := not builder.would_take(vault)
	var untouched := builder.island.occupant(5, 5) == ""
	builder.undo()
	var undone := builder.island.ground(3, 3) == "" and builder.undo_button.disabled
	builder.queue_free()
	await tree.process_frame
	check.call("the builder's ghost asks the island on a copy whether it takes the tool there, changing nothing, and "
			+ "Undo puts the island back as it was (13, 6.2)",
		laid and takes and refuses and untouched and undone,
		"%s %s %s %s %s" % [laid, takes, refuses, untouched, undone])


## A press, a drag across a row and a release on the builder's world, then
## two quick taps, as `WorldView`'s gestures receive them.
func _drag() -> void:
	var b: BuilderScreen = await mount.call("builder")
	b.island.reset(3)
	b.undo_stack.clear()
	b.tool = BuilderScreen.Tool.GROUND
	b.kind = b.kinds().find("moss")
	b._refresh()
	for i in 3:
		await tree.process_frame
	var v := b.view as StageView
	var a := v.screen_at(Vector2i(2, 5))
	var c := v.screen_at(Vector2i(8, 5))
	var feed := func(e: InputEvent) -> void:
		v.gui_input.emit(e)
		v._gui_input(e)
	feed.call(_button(a, true))
	for i in 21:
		var m := InputEventMouseMotion.new()
		m.position = a.lerp(c, i / 20.0)
		m.button_mask = MOUSE_BUTTON_MASK_LEFT
		feed.call(m)
	feed.call(_button(c, false))
	var painted := range(12).filter(func(x: int) -> bool: return b.island.ground(x, 5) == "moss").size()
	for t: Vector2i in [Vector2i(3, 3), Vector2i(4, 3)]:
		feed.call(_button(v.screen_at(t), true))
		feed.call(_button(v.screen_at(t), false))
	var still := v.turns == 0 and is_equal_approx(v._zoom_f, 1.0)
	var edits := b.undo_stack.size()
	b.queue_free()
	await tree.process_frame
	check.call("in the builder a drag paints every tile it crosses and neither turns nor zooms the camera, and two "
			+ "quick taps are two edits, never a zoom (13, 21.1)",
		painted == 7 and still and edits == 9, "%d painted, still %s" % [painted, still])


## The realm view over a realm with two laws: their signatures drawn
## (T8's LawFx), and the fold key hiding the words and bringing them back.
func _fold() -> void:
	StageFixtures.realm(App.services)
	var screen: RealmScreen = await mount.call("realm")
	StageFixtures.realm(App.services)
	await tree.process_frame
	# WorldView draws the laws (T8's LawFx) where a 3D renderer runs; a
	# headless run checks the fold alone.
	var laws := not WorldView.rendering_3d() or (screen.view.law_fx != null
		and screen.view.law_fx.signatures.size() == 2)
	var key: Button = null
	for b: Button in screen.find_children("*", "Button", true, false):
		if b.has_meta("fold"):
			key = b
	var shown := screen.body.is_visible_in_tree()
	key.pressed.emit()
	var hidden := not screen.body.is_visible_in_tree() and key.text == Strings.t("STAGE_SHOW_WORDS")
	key.pressed.emit()
	var back := screen.body.is_visible_in_tree() and not StageScreen.folded
	var sections := screen.body.get_child_count()
	# The fixture's two idle residents of the Heart stroll its doors (where
	# their models are exported).
	var strolling: int = screen.town._strollers.size()
	var exported := CreatureModel.manifest().has("bloomling") and CreatureModel.manifest().has("emberling")
	screen.queue_free()
	await tree.process_frame
	check.call("the realm view wears its woven laws' signatures (21.7), its idle residents stroll its doors, and one key "
			+ "folds its words away so the world takes the phone, and brings them back (21.1)",
		laws and shown and hidden and back and sections == 4 and (strolling == 2 or not exported),
		"%s %s %s %s %d %d" % [laws, shown, hidden, back, sections, strolling])


static func _button(at: Vector2, pressed: bool) -> InputEventMouseButton:
	var e := InputEventMouseButton.new()
	e.button_index = MOUSE_BUTTON_LEFT
	e.pressed = pressed
	e.position = at
	return e


func _thumbs() -> void:
	var thumbs := StageThumbs.new()
	tree.root.add_child(thumbs)
	var cards: Array = ObservatoryTests.sample()["targets"]
	for c: Dictionary in cards:
		thumbs.picture(c)
	for i in 12 * cards.size():
		await tree.process_frame
	var views := thumbs.find_children("*", "SubViewport", true, false)
	var keys := cards.map(func(c: Dictionary) -> String: return StageThumbs.key_of(c))
	var drawn := keys.all(func(k: String) -> bool: return thumbs._done.has(k))
	check.call("the Observatory draws every card's universe through one shared offscreen viewport, never one a card "
			+ "(12.3, 21.3)",
		views.size() == 1 and drawn and keys.size() == 3 and keys[0] != keys[1],
		"%d viewports, drawn %s" % [views.size(), drawn])
	thumbs.queue_free()
	await tree.process_frame
