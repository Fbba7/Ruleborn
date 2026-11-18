class_name HeistFxTests
extends RefCounted
## The heist drawn as a game (world/fx_*.gd, scripts/heist_hud.gd): the HUD's
## clock, alarm and laws, what changes between two readings and is shown, the
## follow camera's span, taps and gestures, the law effects and reduced
## motion — all checked headless, from the nodes the screens build.

const HEIST := "res://scenes/heist_screen.tscn"
## The orders that spread the crew to sneak (the heist shot's "sneak" moment).
const SNEAK := [[4, 9], [3, 10], [4, 11]]

var tree: SceneTree
var check: Callable


func _init(t: SceneTree, c: Callable) -> void:
	tree = t
	check = c


func run() -> void:
	var replay := RulebornReplay.new()
	replay.start("7", 4500, 3, WorldTests.island())
	var spots := replay.reaching()
	var s: Vector2i = spots[0]
	replay.give(0, HeistController.Kind.LAND, s.x * 256 + 128, s.y * 256 + 128)
	for i in 60:
		replay.step()
	_hud(replay)
	var view := WorldView.new()
	view.size = Vector2(540, 1170)
	tree.root.add_child(view)
	view.show_replay(replay)
	view.describe()
	await tree.process_frame
	_events(view, replay)
	_camera(view, replay)
	_taps(view)
	_laws(view)
	_calm(view)
	_skiff(view, replay)
	_moments()
	_sight_marks(view, replay)
	_pen()
	_speech(view)
	view.queue_free()
	await tree.process_frame
	await _models(replay)
	await _entry_card()
	await _layers()
	await _vault_band()
	_planned()


func _hud(replay: RulebornReplay) -> void:
	var hud := HeistHud.new()
	tree.root.add_child(hud)
	hud.show_state(replay)
	var left := (replay.ticks() - replay.tick()) / RulebornReplay.ticks_per_second()
	var clock := hud.clock_label.text == "%d:%02d" % [left / 60, left % 60]
	var alarm := hud.alarm_label.text.contains("%d / 6" % replay.alarm())
	var standing := replay.pylons().filter(func(p: Dictionary) -> bool: return p["standing"]).size()
	var chips := hud.laws_box.get_child_count() == standing and standing > 0
	var named := false
	for chip in hud.laws_box.get_children():
		for l in chip.find_children("*", "Label", true, false):
			named = named or (l as Label).text == Strings.term("LAW", "bloom")
	hud.queue_free()
	check.call("the heist HUD counts the clock down, says the alarm as N / 6 beside its bells, and names each law "
			+ "running in a chip with its school's shape (21.8, 12.6, 20.8)",
		clock and alarm and chips and named, "%s %s %s %s" % [hud.clock_label.text, hud.alarm_label.text, chips, named])


## Each change between two readings is shown once, and only a change is: the
## same reading twice shows nothing, a reading back in time starts afresh.
func _events(view: WorldView, replay: RulebornReplay) -> void:
	var fx := view.events
	view.anchors.pops.clear()
	fx.read(replay)
	var quiet := view.anchors.pops.is_empty()
	# The last reading had crew member 0 carrying 25 less, guard 0 standing,
	# and the alarm one lower: a grab, a knock-out and an alarm to show.
	var was: Dictionary = fx._reading(replay)
	(was["crew"][0] as Array)[0] = int(was["crew"][0][0]) - 25
	(was["guards"][0] as Array)[0] = false
	was["alarm"] = int(was["alarm"]) - 1
	var down := replay.guards()[0]["down"] as bool
	fx._last = was
	view.anchors.flash = 0.0
	fx.read(replay)
	var texts: Array = view.anchors.pops.map(func(p: Dictionary) -> String: return p["text"])
	var shown := texts.has("+25") and view.anchors.flash > 0.9 and (texts.has("KO") == down)
	view.anchors.pops.clear()
	fx._first = false
	var back: Dictionary = fx._reading(replay)
	back["tick"] = int(back["tick"]) + 100
	fx._last = back
	fx.read(replay)
	var fresh := view.anchors.pops.is_empty()
	# A reading in another realm than the last: the crew crossed, and the
	# camera swoops (21.1).
	var crossed: Dictionary = fx._reading(replay)
	crossed["realm"] = 5
	fx._last = crossed
	view._swoop = 0.0
	fx.read(replay)
	var swooped := view._swoop > 0.99 and view.anchors.wipe > 0.99
	view._swoop = 0.0
	view.anchors.wipe = 0.0
	check.call("what happens is drawn from the simulation's own readings: a grab rises as its number, the alarm "
			+ "flashes the screen's edge, a knock-out shows; nothing is shown twice, and a replay restarted starts "
			+ "afresh; a crossing to another realm swoops (21.8, 24.1, 21.1)", quiet and shown and fresh and swooped,
		"%s %s %s %s %s" % [quiet, texts, view.anchors.flash, fresh, swooped])


## §21.1: the heist's follow camera shows about 12 tiles across, eight close
## up and the whole realm zoomed out, round the crew it follows.
func _camera(view: WorldView, replay: RulebornReplay) -> void:
	view.heist = true
	view.follow = [0]
	view.set_zoom(1)
	var aspect := view.size.x / view.size.y
	var across := view.camera.size * aspect
	view.set_zoom(2)
	var close := view.camera.size * aspect
	view.set_zoom(0)
	var whole := view.camera.size * aspect
	view.set_zoom(1)
	view._aimed = false
	view._frame_camera()
	var me := view.camera.unproject_position(view._crew[0].position)
	var framed := Rect2(Vector2.ZERO, view.size).has_point(me)
	var picks := view.tile_at(view.screen_at(Vector2i(replay.crew()[0]["at"]))) == Vector2i(replay.crew()[0]["at"])
	view.follow = []
	view.set_zoom(1)
	check.call("the heist's camera follows the crew at 50 degrees showing about 12 tiles across (15 metres on its width), "
			+ "seven close up and the whole realm zoomed out, and a tap still picks the tile drawn under it (21.1)",
		is_equal_approx(across, WorldView.FOLLOW_TILES) and is_equal_approx(close, WorldView.CLOSE_TILES)
			and whole > across and framed and picks, "%.2f %.2f %.2f %s %s" % [across, close, whole, framed, picks])


func _press(view: WorldView, at: Vector2, down: bool) -> void:
	var e := InputEventMouseButton.new()
	e.button_index = MOUSE_BUTTON_LEFT
	e.pressed = down
	e.position = at
	view._gui_input(e)


## A tap is a tap; a drag or a pinch never is; a double tap steps the zoom; a
## twist turns a quarter. Nothing needs two fingers (20.8).
func _taps(view: WorldView) -> void:
	var taps: Array[Vector2] = []
	var on_tap := func(at: Vector2) -> void: taps.append(at)
	view.tapped.connect(on_tap)
	view._last_tap_ms = -10000
	_press(view, Vector2(100, 100), true)
	_press(view, Vector2(102, 101), false)
	var one := taps.size() == 1
	_press(view, Vector2(300, 300), true)
	var move := InputEventMouseMotion.new()
	move.position = Vector2(400, 380)
	view._gui_input(move)
	_press(view, Vector2(400, 380), false)
	var dragged := taps.size() == 1
	view.set_zoom(1)
	view._last_tap_ms = -10000
	_press(view, Vector2(200, 200), true)
	_press(view, Vector2(200, 200), false)
	_press(view, Vector2(201, 201), true)
	_press(view, Vector2(201, 201), false)
	var stepped := view.zoom == 2
	var turns := view.turns
	view._twist_by(WorldView.TWIST_RADIANS + 0.1)
	var turned := view.turns == posmod(turns + 1, 4)
	view.turn(-1)
	view.set_zoom(1)
	view.tapped.disconnect(on_tap)
	check.call("a tap on the world is a tap and a drag is not; a double tap steps the zoom and a twist turns the "
			+ "camera a quarter, so no action needs two fingers (21.1, 20.8)", one and dragged and stepped and turned,
		"%s %s %s %s" % [one, dragged, stepped, turned])


## The heist's figures step as the laws woven make them (T8's gait, §21.7):
## a hoppy law hops higher, a slow one steps slower, none is plain.
func _laws(view: WorldView) -> void:
	var plain := FxMotion.movement(LawFxGait.blend([]), true, 0.0)
	var hoppy := FxMotion.movement(LawFxGait.blend(["half_gravity"]), true, 0.0)
	var woven := view.woven.duplicate()
	var expect := LawFxGait.blend(woven)
	check.call("the heist's figures step as the laws woven make them, by the one law-effect system's gait: plain with "
			+ "none, higher under half gravity, and the realm's own laws read from its pylons (21.7)",
		is_equal_approx(float(plain["hop"]), 1.0) and is_equal_approx(float(plain["rate"]), 1.0)
			and (float(hoppy["hop"]) > 1.0 or float(hoppy["float"]) > 0.0) and view.gait == expect
			and woven.has("bloom"), "%s %s %s" % [plain, hoppy, woven])


## Reduced motion: no shake, no swoop (20.8).
func _calm(view: WorldView) -> void:
	Settings.reduced_motion = true
	view._shake = 0.0
	view._swoop = 0.0
	view.shake(1.0)
	view.swoop()
	var still := view._shake == 0.0 and view._swoop == 0.0
	Settings.reduced_motion = false
	view.shake(0.5)
	var moves := view._shake > 0.0
	view._shake = 0.0
	check.call("reduced motion takes away the shake and the swoop between realms; without it the shake is gentle "
			+ "(20.8, 21.8)", still and moves, "%s %s" % [still, moves])


## Get out's skiff stands where the order called it, and nowhere before.
func _skiff(view: WorldView, replay: RulebornReplay) -> void:
	view._sync_skiff(0.0)
	var hidden := not view._skiff.visible
	replay.give(0, HeistController.Kind.SKIFF, 128, 11 * 256 + 128)
	replay.step()
	view.describe()
	view._sync_skiff(0.0)
	var edge := view.world_at(Vector2(0.5, 11.5))
	var shown := view._skiff.visible and Vector2(view._skiff.position.x, view._skiff.position.z).length() \
		> Vector2(edge.x, edge.z).length()
	check.call("the skiff Get out calls is drawn off the island's edge where it was called, and not before (5.4)",
		hidden and shown, "%s %s %s" % [hidden, view._skiff.visible, view._skiff.position])


## The replay's timeline marks a golden heist's moments where they happen.
func _moments() -> void:
	var golden := FileAccess.get_file_as_bytes("res://goldens/planned-clean.rbh")
	var marks := ReplayScreen.moments(golden, PackedByteArray())
	var count := func(kind: String) -> int:
		return marks.filter(func(m: Dictionary) -> bool: return m["kind"] == kind).size()
	var ordered := true
	for k in range(1, marks.size()):
		ordered = ordered and int(marks[k]["tick"]) >= int(marks[k - 1]["tick"])
	check.call("the replay's timeline marks each knock-out, each rise of the alarm, the Vault opening and each pylon "
			+ "broken, in the order they happen",
		count.call("ko") == 4 and count.call("vault") == 1 and count.call("alarm") >= 1 and count.call("pylon") == 1
			and ordered, "%s" % [marks])


## The eye over a crew member is the simulation's sight: one standing on a
## tile any guard on its feet sees, and no other.
func _sight_marks(view: WorldView, replay: RulebornReplay) -> void:
	view.describe()
	var want := {}
	var crew := replay.crew()
	for gi in replay.guards().size():
		if replay.guards()[gi]["down"]:
			continue
		var seen := Array(replay.seen(gi))
		for i in crew.size():
			var at: Vector2 = crew[i]["at"]
			if crew[i]["standing"] == "Active" and seen.has(floori(at.y) * replay.size().x + floori(at.x)):
				want[i] = true
	check.call("a crew member is marked as in sight exactly when it stands on a tile a guard on its feet sees, by the "
			+ "simulation's own sight (21.12)", view.in_sight == want, "%s %s" % [view.in_sight, want])


## A character model given by `figure_maker` takes each actor's figure and is
## played the clip for what its actor is doing (the integrator's hook for T1).
func _models(replay: RulebornReplay) -> void:
	var model := GDScript.new()
	model.source_code = "extends Node3D\nvar played: Array[String] = []\n\n\n" \
		+ "func play(clip: StringName, _speed := 1.0) -> void:\n\tplayed.append(String(clip))\n"
	model.reload()
	var made: Array[String] = []
	WorldView.figure_maker = func(role: String, _height: float) -> Node3D:
		made.append(role)
		var n := Node3D.new()
		n.set_script(model)
		return n
	var view := WorldView.new()
	view.size = Vector2(540, 960)
	tree.root.add_child(view)
	view.show_replay(replay)
	view.describe()
	FxMotion.animate(view, float(replay.tick()))
	var figure := view._crew[0].get_node("Rig/Figure")
	var played: Array = figure.get("played")
	var guard_figure := view._guards[0].get_node("Rig/Figure")
	WorldView.figure_maker = Callable()
	var clips := [FxMotion.model_clip(true, true, "Run", true, true),
		FxMotion.model_clip(false, false, "Walk", true, true),
		FxMotion.model_clip(false, true, "Run", true, false), FxMotion.model_clip(false, true, "Run", false, false),
		FxMotion.model_clip(false, true, "Crouch", false, false), FxMotion.model_clip(false, false, "Walk", false, false)]
	played = played if clips == ["ko", "hit", "carry", "run", "walk", "idle"] else []
	check.call("a character model, when the integrator gives one, takes each actor's figure and is played the clip "
			+ "for what the simulation says it is doing (TD.9)",
		made.size() == replay.crew().size() + replay.guards().size() and made.has("guard") and played.size() == 1
			and str(played[0]) in ["idle", "walk", "run", "carry", "hit", "ko"] and guard_figure.get_script() == model,
		"%s %s" % [made, played])
	view.queue_free()
	await tree.process_frame


## Landing in a realm or crossing into the next shows its name on a card for
## about two seconds (15.3); nothing for a heist of one island.
func _entry_card() -> void:
	var maker := WorldView.figure_maker
	App.services.store.dispatch(&"heist_started", {})
	var screen: HeistScreen = load(HEIST).instantiate()
	tree.root.add_child(screen)
	await tree.process_frame
	screen.set_process(false)
	screen.entry_card("")
	var none := screen.card == null
	screen.entry_card(HeistHud.realm(0, 0))
	var words := ""
	for l in screen.card.find_children("*", "Label", true, false):
		words = (l as Label).text
	var shown := screen.card.is_inside_tree() and words == Strings.t("HEIST_IN_HEART")
	# A held press opens the gait menu at the finger; a gait from it is the
	# chosen member's, sent to the held tile.
	screen.controller.land_here()
	screen.view.show_replay(screen.controller.world)
	var at := screen.view.screen_at(Vector2i(6, 6))
	screen.open_gait_menu(at)
	var opened := screen.gait_menu != null and screen.gait_menu.find_children("*", "Button", true, false).size() == 3
	screen._go_at(2, Vector2i(6, 6))
	var orders: Array = screen.controller.world.commands()
	var gave: Dictionary = orders[orders.size() - 1] if orders.size() > 0 else {}
	var gait: Dictionary = orders[orders.size() - 2] if orders.size() > 1 else {}
	var sent := screen.gait_menu == null and int(gait.get("kind", -1)) == HeistController.Kind.GAIT \
		and int(gait.get("x", -1)) == 2 and int(gave.get("kind", -1)) == HeistController.Kind.MOVE_TO
	screen.queue_free()
	await tree.process_frame
	WorldView.figure_maker = maker
	check.call("holding the ground opens Crouch / Walk / Run at the finger, and the gait chosen is sent with the walk "
			+ "to the held tile (12.18)", opened and sent, "%s %s %s %s" % [opened, sent, gait, gave])
	check.call("landing in a realm, or crossing into the next, shows its name on a card for about two seconds, and a "
			+ "heist of one island shows none (15.3, 5.4)", none and shown and HeistScreen.ENTRY_SECONDS <= 3.0,
		"%s %s %s" % [none, shown, words])


## AD-R55 (flow board 2's F9): at 200% text the loot panel grows down over
## the map, so the heist mounted as the app mounts it (the kit's layers on, as
## UI.root_theme() puts them) has every part of its HUD, panel faces and
## words, drawn above every layer of the world, the markers' and marks' layer
## (FxAnchors) included; and the loot's flying coins over the HUD.
func _layers() -> void:
	var maker := WorldView.figure_maker
	var scale := Settings.text_scale
	UI.root_theme()
	Settings.text_scale = 200
	App.services.store.dispatch(&"heist_started", {})
	var screen: HeistScreen = load(HEIST).instantiate()
	tree.root.add_child(screen)
	await tree.process_frame
	screen.set_process(false)
	screen.controller.land_here()
	screen.controller.advance(60)
	screen._refresh()
	await tree.process_frame
	var world := _z_span(screen.view)
	var hud := Vector2i(RenderingServer.CANVAS_ITEM_Z_MAX, RenderingServer.CANVAS_ITEM_Z_MIN)
	for c: Node in screen.get_children():
		if c is MarginContainer:
			var span := _z_span(c as CanvasItem)
			hud = Vector2i(mini(hud.x, span.x), maxi(hud.y, span.y))
	var coins := true
	if not Settings.reduced_motion:
		screen.hud.fly_coins(Vector2(100, 900), 1)
		var coin := screen.hud.get_child(screen.hud.get_child_count() - 1) as CanvasItem
		coins = coin != null and coin.top_level and _z_of(coin) > hud.y
	screen.queue_free()
	await tree.process_frame
	Settings.text_scale = scale
	WorldView.figure_maker = maker
	check.call("at 200% text no marker or mark of the world draws above the heist's HUD: the world's layers, its "
			+ "markers' included, all stand under the HUD's lowest, and the loot's coins fly over it (AD-R55)",
		world.y < hud.x and coins, "world z %d..%d, HUD z %d..%d, coins %s" % [world.x, world.y, hud.x, hud.y, coins])


## AD-R65: at 200% text the heist's opening frame keeps the vault and its
## tag inside the map band, between the loot panel's foot and the crew
## tray's top edge, in en, pt_BR and de (the HUD over the markers, AD-R55,
## would otherwise cover 'COFRE' and 'TRESOR').
func _vault_band() -> void:
	var scale := Settings.text_scale
	var locale := TranslationServer.get_locale()
	UI.root_theme()
	var ok := true
	var seen: Array[String] = []
	# Each locale at 200%, and en at 100%, where the frame keeps §21.1's
	# framing (no lift).
	for case: Array in [[200, "en"], [200, "pt_BR"], [200, "de"], [100, "en"]]:
		var lang: String = case[1]
		Settings.text_scale = case[0]
		Settings.apply()
		Strings.set_locale(lang)
		# AD-R65's moment: WorldTests' island, the crew spread to sneak and
		# played in steps to tick 150, as the shot of preview-2 has it.
		App.services.store.dispatch(&"heist_started", {"island": WorldTests.island(), "testing": true})
		var screen: HeistScreen = load(HEIST).instantiate()
		tree.root.add_child(screen)
		await tree.process_frame
		screen.set_process(false)
		screen.controller.land_here()
		for i in SNEAK.size():
			var t: Array = SNEAK[i]
			screen.controller.world.give(i, HeistController.Kind.MOVE_TO, int(t[0]) * 256 + 128, int(t[1]) * 256 + 128)
		var v := screen.view
		for k in 15:
			screen.controller.advance(10)
			screen._refresh()
			v._process(1.0 / 3.0)
		# The landing's drop played out, as it has by the time the player looks.
		if v._intro != null:
			v._intro.kill()
		v._zoom_f = float(v.zoom)
		for i in 4:
			await tree.process_frame
		var at := v.anchors.get_global_rect().position.y
		var plate: Rect2 = v.anchors._vault_plate
		var top := screen.hud.loot_panel.get_global_rect().end.y - at
		var foot := screen.actions_band.get_global_rect().position.y - at
		var base := v.camera.unproject_position(v.world_at(v.replay.vault()["at"])).y
		ok = ok and plate.has_area() and plate.position.y >= top and maxf(plate.end.y, base) <= foot \
				and (case[0] > 100 or v.lift == 0.0)
		seen.append("%d%% %s tag %d..%d, vault %d, band %d..%d, lift %d" % [case[0], lang, plate.position.y,
			plate.end.y, base, top, foot, v.lift])
		screen.queue_free()
		await tree.process_frame
	Strings.set_locale(locale)
	Settings.text_scale = scale
	Settings.apply()
	check.call("at 200% text the heist's opening frame keeps the vault and its tag inside the map band, between the "
			+ "loot panel's foot and the crew tray's top edge, in en, pt_BR and de; at 100% the frame is not lifted "
			+ "(AD-R65)", ok, "; ".join(seen))


## The lowest and highest z a drawn canvas item under `n` (itself included)
## draws at on `n`'s canvas (a sub-viewport's own canvas is drawn into its
## picture, at the z of the container that shows it).
func _z_span(n: CanvasItem) -> Vector2i:
	var out := Vector2i(RenderingServer.CANVAS_ITEM_Z_MAX, RenderingServer.CANVAS_ITEM_Z_MIN)
	var items: Array[Node] = [n]
	items.append_array(n.find_children("*", "CanvasItem", true, false))
	for c: Node in items:
		var item := c as CanvasItem
		if item == null or not item.is_visible_in_tree() or item.get_canvas() != n.get_canvas():
			continue
		var z := _z_of(item)
		out = Vector2i(mini(out.x, z), maxi(out.y, z))
	return out


## The z `item` draws at: its own, plus its parents' while it is relative to
## them (a top-level item stands on the canvas itself).
static func _z_of(item: CanvasItem) -> int:
	var z := 0
	var at: Node = item
	while at is CanvasItem:
		var c := at as CanvasItem
		z += c.z_index
		if not c.z_as_relative or c.top_level:
			break
		at = c.get_parent()
	return z


## The HUD's shapes gather into one triangle array (FxPen): circles, arcs,
## lines and boxes add triangles whose corners all exist, words send what is
## gathered first, and nothing is kept once the drawing ends.
func _pen() -> void:
	var ci := Control.new()
	tree.root.add_child(ci)
	var closed_before := FxPen.gathered(ci)
	FxPen.begin(ci)
	FxPen.circle(ci, Vector2(20, 20), 10.0, Color.RED)
	FxPen.arc(ci, Vector2(20, 20), 12.0, 0.0, PI, 16, Color.WHITE, 3.0)
	FxPen.line(ci, Vector2.ZERO, Vector2(30, 0), Color.BLACK, 2.0)
	var box := StyleBoxFlat.new()
	box.set_corner_radius_all(8)
	box.set_border_width_all(2)
	box.shadow_size = 4
	FxPen.style_box(ci, box, Rect2(0, 0, 80, 30))
	var shapes := FxPen.gathered(ci)
	FxPen.string(ci, ThemeDB.fallback_font, Vector2(0, 20), "Hi")
	var after_words := FxPen.gathered(ci)
	FxPen.end(ci)
	var whole := FxPen.rounded(Rect2(0, 0, 80, 30), 8.0)
	check.call("the HUD's shapes are gathered as triangles and sent as one draw (21.3: under 150 draw calls)",
		closed_before == -1 and shapes > 60 and after_words == 0 and FxPen.gathered(ci) == -1 and whole.size() > 12,
		"%d %d %d %d" % [closed_before, shapes, after_words, whole.size()])
	ci.queue_free()


## A guard says what it has come to (§12.16's examples), for a while, and
## says nothing for a state without words.
func _speech(view: WorldView) -> void:
	view.anchors.speech.clear()
	view.anchors.say(0, "Unaware")
	var quiet := view.anchors.speech.is_empty()
	view.anchors.say(0, "Alerted")
	var said := str(view.anchors.speech.get(0, {}).get("text", "")) == Strings.t("GUARD_SAY_ALERTED")
	view.anchors.tick(FxAnchors.SAY_SECONDS + 0.1)
	check.call("a guard says what it has come to over its head, then falls quiet (12.16)",
		quiet and said and view.anchors.speech.is_empty(), "%s %s %s" % [quiet, said, view.anchors.speech])


## §12.5's planned crew as the heist's HUD reads it from the simulation: each
## member's kind and ability uses (the portraits), the Sage's powers and the
## casts carried (the Sage's disc and Cast); a power and a cast given at a
## tile spend what the simulation says they spend.
func _planned() -> void:
	var law := Array(RulebornStability.law_ids()).find("glowing_dark")
	var plan := PackedByteArray()
	for k: int in [1, 6, 4, 3, 9]:
		plan.append_array(PackedByteArray([k, 0, 3, 0]))
	plan.append_array(PackedByteArray([1, 1, law]))
	var r := RulebornReplay.new()
	var started := r.start_planned("7", 4500, 5, plan, WorldTests.island())
	var s: Vector2i = r.reaching()[0]
	r.give(0, HeistController.Kind.LAND, s.x * 256 + 128, s.y * 256 + 128)
	for i in 30:
		r.step()
	var kinds := r.crew().map(func(m: Dictionary) -> String: return str(m["kind"]))
	var uses := r.crew().map(func(m: Dictionary) -> int: return int(m["uses"]))
	var sage := r.sage()
	var powers: Array = sage.get("powers", [])
	var left := powers.map(func(p: Dictionary) -> int: return int(p["uses"]))
	var casts := r.casts()
	var at: Vector2 = r.crew()[0]["at"]
	r.give(1, HeistController.Kind.SAGE, int(at.x) * 256 + 128, int(at.y) * 256 + 128)
	r.give(0, HeistController.Kind.CAST, int(at.x) * 256 + 128, int(at.y) * 256 + 128)
	for i in 3:
		r.step()
	var after: Array = (r.sage().get("powers", []) as Array).map(func(p: Dictionary) -> int: return int(p["uses"]))
	var cooling := int(r.sage().get("cooling_until", 0)) > r.tick()
	var cast_used := not r.casts().is_empty() and bool(r.casts()[0]["used"])
	check.call("a planned crew's portraits, Sage and Cast read the simulation: each member's kind and two ability "
			+ "uses, the Archivist's three powers, the cast carried; a power and a cast given spend a use (21.8, 12.7)",
		started and kinds == ["skyskipper", "tidewalker", "quarryback", "glass_golem", "emberling"]
			and uses == [2, 2, 2, 2, 2] and str(sage.get("id", "")) == "the_archivist" and left == [1, 2, 1]
			and casts.size() == 1 and str(casts[0]["law"]) == "glowing_dark" and not bool(casts[0]["used"])
			and after == [1, 1, 1] and cooling and cast_used,
		"%s %s %s %s %s %s %s %s" % [started, kinds, uses, sage.get("id"), left, casts, after, [cooling, cast_used]])
