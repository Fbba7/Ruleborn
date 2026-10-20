class_name HeistFxTests
extends RefCounted
## The heist drawn as a game (world/fx_*.gd, scripts/heist_hud.gd): the HUD's
## clock, alarm and laws, what changes between two readings and is shown, the
## follow camera's span, taps and gestures, the law effects and reduced
## motion — all checked headless, from the nodes the screens build.

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
	view.queue_free()
	await tree.process_frame
	await _models(replay)


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
	check.call("the heist's camera follows the crew at 50 degrees showing about 12 tiles across (10.5 on its width), seven close up "
			+ "and the whole realm zoomed out, and a tap still picks the tile drawn under it (21.1)",
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
