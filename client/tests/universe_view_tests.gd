class_name UniverseViewTests
extends RefCounted
## The universe map in 3D (§21.1, §23.2): where the realms hang, that every
## realm and link the server names is drawn and nothing else, that it stays
## inside §21.3's budget, that the camera frames it and a tap finds the
## realm under it, that the pins follow what the store holds, and that home
## keeps every place and the heist within reach over it.

var tree: SceneTree
var check: Callable
var mount: Callable


func _init(t: SceneTree, c: Callable, m: Callable) -> void:
	tree = t
	check = c
	mount = m


func run() -> void:
	_layout()
	await _drawn()
	await _camera()
	await _pins()
	await _people()
	await _lazy()
	await _home()


func _layout() -> void:
	var view := UniverseSample.view(6)
	var places := UniverseLayout.places(view["realms"])
	var five := UniverseLayout.places(UniverseSample.view(5)["realms"], 1)
	var r_heart := UniverseLayout.radius(UniverseLayout.HEART_GRID)
	var r_outer := UniverseLayout.radius(UniverseLayout.OUTER_GRID)
	var apart := true
	for a: String in places:
		for b: String in places:
			if a < b:
				var ra := r_heart if a == "heart" else r_outer
				var rb := r_heart if b == "heart" else r_outer
				var pa: Vector3 = places[a]
				var pb: Vector3 = places[b]
				apart = apart and Vector2(pa.x - pb.x, pa.z - pb.z).length() > ra + rb + 2.0
	var box := UniverseLayout.bounds(places, r_outer)
	var ends := UniverseLayout.link_ends(Vector3.ZERO, 10.0, Vector3(30, 0, 0), 8.0)
	var young := UniverseLayout.places([{"realm": "heart"}, {"realm": "outer-1"}], 1)
	check.call("the universe hangs as a column for a portrait screen: the Heart in the middle, each outer realm in "
			+ "the next place in the order it opened, the next to open after them, no two islands touching, and a "
			+ "link leaving each rim toward the other (21.1, 5.3)",
		places["heart"] == Vector3.ZERO and places.size() == 7 and five.size() == 7 and five.has("next:0") and apart
			and box.size.z > box.size.x * 1.5 and young.size() == 3
			and is_equal_approx(ends[0].x, 10.0 * UniverseLayout.RIM) and is_equal_approx(ends[1].x, 30.0 - 8.0
			* UniverseLayout.RIM) and UniverseLayout.type_key("Lantern Vale") == "lanternvale"
			and UniverseLayout.type_key("Heart") == "heart" and UniverseLayout.type_key("Nowhere") == "heart",
		"%s %s %s" % [places, box, ends])


func _view() -> UniverseView:
	var view := UniverseView.new()
	view.size = Vector2(1080, 2340)
	tree.root.add_child(view)
	return view


func _drawn() -> void:
	var view := _view()
	var data := UniverseSample.view(6)
	view.show_universe(data, UniverseSample.extras())
	await tree.process_frame
	var realms := view.islands.keys().filter(func(id: String) -> bool: return not id.begins_with("next:"))
	var bridges := 0
	for n in view.statics.find_children("*", "MeshInstance3D", true, false):
		bridges += 1 if n.get_parent() != view.statics else 0
	var kinds := {}
	for l: Dictionary in data["links"]:
		kinds[l["kind"]] = true
	var built := view.statics.get_child_count()
	view.show_universe(data, UniverseSample.extras())
	var same := view.statics.get_child_count() == built and not view.statics.get_child(0).is_queued_for_deletion()
	# §21.3, held to what is in view: the whole universe, and each realm
	# seen close (T2's island and a character there).
	var reduced := Settings.reduced_motion
	Settings.reduced_motion = true
	view.set_zoom(0)
	view._process(0.01)
	var drawn: Array[int] = [view.drawn_triangles()]
	for id: String in ["heart", "outer-1", "outer-2", "outer-3", "outer-4", "outer-5", "outer-6"]:
		for level: int in [1, 2]:
			view.set_zoom(0)
			view.focus_realm(id, level)
			view._process(0.01)
			drawn.append(view.drawn_triangles())
	view.set_zoom(0)
	Settings.reduced_motion = reduced
	var budget: bool = drawn.max() < 40000 and view.draw_calls() < 150
	var small := UniverseSample.view(1)
	view.show_universe(small, {})
	await tree.process_frame
	var shrunk := view.islands.size() == 3 and view.islands.has("next:0")
	check.call("the map draws every realm the server names and only those, the next realm to open as mist, a rope "
			+ "bridge on a node of its own so it sways, all four kinds of link, and is not built again for the same "
			+ "universe; seven realms stay inside 21.3's 40,000 triangles in view and 150 draw calls, from afar and at "
			+ "each realm's two zooms (23.2, 5.3, 21.3)",
		realms.size() == 7 and kinds.size() == 4 and bridges >= 1 and same and budget and shrunk,
		"realms %s kinds %s ropes %d same %s drawn %s calls %d shrunk %s" % [realms, kinds, bridges, same,
			drawn, view.draw_calls(), view.islands.keys()])
	view.queue_free()
	await tree.process_frame


func _camera() -> void:
	var view := _view()
	view.focus_realm("heart", 1)
	var waited := view.zoom == 0
	view.show_universe(UniverseSample.view(6), UniverseSample.extras())
	var kept := view.zoom == 1 and view.focus_id == "heart"
	await tree.process_frame
	var reduced := Settings.reduced_motion
	Settings.reduced_motion = true
	view.set_zoom(0)
	view._process(0.016)
	var framed := true
	for id: String in view.islands:
		var at := view.screen_at((view.islands[id] as UniverseIsland).at)
		framed = framed and Rect2(Vector2.ZERO, view.size).has_point(at)
	var tapped := view.realm_at(view.screen_at((view.islands["outer-3"] as UniverseIsland).at))
	var sky := view.realm_at(Vector2(4, 4))
	var chosen: Array[String] = []
	view.realm_chosen.connect(func(id: String) -> void: chosen.append(id))
	view.choose("outer-3")
	view._process(0.016)
	var focused := view.zoom == 1 and view.focus_id == "outer-3"
	var centred := view.screen_at((view.islands["outer-3"] as UniverseIsland).at).distance_to(view.size / 2.0) \
		< view.size.x * 0.1
	view.choose("outer-3")
	var closer := view.zoom == 2
	view.turn(1)
	var turned := view.turns == 1
	view.turn(-1)
	view.set_zoom(0)
	view.turn(1)
	turned = turned and view.turns == 2
	view.turn(1)
	Settings.reduced_motion = reduced
	check.call("a realm asked for before the universe arrives is shown once it does; the whole universe is framed "
			+ "on the phone; a tap finds the realm under it and none in the sky; choosing a realm swoops to it at "
			+ "one zoom and a second time closer, turning in quarter turns (half turns over the whole universe, "
			+ "which stays upright), instantly under reduced motion (21.1, 20.8)",
		waited and kept and framed and tapped == "outer-3" and sky == "" and chosen == ["outer-3", "outer-3"]
			and focused and centred and closer and turned and view.zoom == 0,
		"waited %s kept %s framed %s tapped %s sky %s chosen %s focused %s centred %s closer %s" % [waited, kept,
			framed, tapped, sky, chosen, focused, centred, closer])
	view.queue_free()
	await tree.process_frame


func _pins() -> void:
	var view := _view()
	Settings.reduced_motion = true
	view.show_universe(UniverseSample.view(6), UniverseSample.extras())
	view.set_zoom(0)
	await tree.process_frame
	view._process(0.016)
	var plates := view.pins.get_children()
	var names := plates.filter(func(c: Node) -> bool: return c.has_meta("realm"))
	var texts := []
	for l in view.pins.find_children("*", "Label", true, false):
		texts.append((l as Label).text)
	var shown: Array[Rect2] = []
	var overlap := false
	for c: Control in plates:
		if c.visible:
			var r := Rect2(c.position, c.size).grow(-UI.px(2))
			for o: Rect2 in shown:
				overlap = overlap or o.intersects(r)
			shown.append(r)
	view.show_universe(UniverseSample.view(6), {})
	var raisable := 0
	for r: Dictionary in UniverseSample.view(6)["realms"]:
		for b: Dictionary in r["buildings"]:
			raisable += 1 if b["next"] is Dictionary and b["next"]["blocked"] == null else 0
	var quiet := view.pins.get_children().filter(func(c: Node) -> bool: return not c.is_queued_for_deletion())
	Settings.reduced_motion = false
	check.call("the map's pins name every realm, say what each producer has ready and the raids, mark the fault, "
			+ "and never cover one another; with nothing ready and no raids, only the realms, faults, links and the "
			+ "buildings that can be raised now are pinned (23.2, 10.2, 20.8)",
		names.size() == 7 and texts.has(WeavingPresenter.band_name(1) + " 74%") and texts.has("! 2")
			and texts.has("✦ 320") and texts.any(func(t: String) -> bool:
			return t.begins_with("ϟ")) and not overlap and quiet.size() == 8 + view.links.size() + raisable,
		"names %d texts %s overlap %s quiet %d raisable %d" % [names.size(), texts, overlap, quiet.size(),
			raisable])
	view.queue_free()
	await tree.process_frame


## The player's characters on the realm seen close, where the home view puts
## them; none from afar; a heading in a word list swoops the map.
func _people() -> void:
	var view := _view()
	Settings.reduced_motion = true
	view.show_universe(UniverseSample.view(6), UniverseSample.extras())
	await tree.process_frame
	var people := view.world.get_node("Characters")
	var far := people.get_child_count()
	view.focus_realm("heart", 2)
	await tree.process_frame
	var kinds: Array[String] = []
	for c in people.get_children():
		if not c.is_queued_for_deletion():
			kinds.append(str(c.name))
	var where := [UniverseCrowd.realm_of({"state": "working", "home": "spire",
			"work": {"realm": "outer-2", "kind": "garden", "n": 1}}),
		UniverseCrowd.realm_of({"state": "idle", "home": "spire", "work": null}),
		UniverseCrowd.realm_of({"state": "idle", "home": "outer-3", "work": null})]
	var title := UI.label("The Heart")
	var heading := UniverseHeading.make(title, "outer-4", view)
	view.add_child(heading)
	var press := InputEventMouseButton.new()
	press.button_index = MOUSE_BUTTON_LEFT
	press.pressed = true
	heading.gui_input.emit(press)
	var lift := press.duplicate() as InputEventMouseButton
	lift.pressed = false
	heading.gui_input.emit(lift)
	var swooped := view.focus_id == "outer-4" and view.zoom == 1
	Settings.reduced_motion = false
	check.call("the realm seen close shows the player's own characters the home view puts there, one at most, and "
			+ "none from afar; a character is where it works, else at home (the Spire is the Heart); a realm's "
			+ "heading in a word list swoops the map to it (23.2, 14.1)",
		far == 0 and kinds.size() == 1 and kinds.has("featherkin")
			and where == ["outer-2", "heart", "outer-3"] and swooped and heading.get_child(1) == title,
		"far %d kinds %s where %s swooped %s" % [far, kinds, where, swooped])
	view.queue_free()
	await tree.process_frame


## A realm's detailed buildings are made when the camera first comes to it,
## and its island as seen close while the camera rests on it.
func _lazy() -> void:
	var view := _view()
	Settings.reduced_motion = true
	view.show_universe(UniverseSample.view(6), UniverseSample.extras())
	view.set_zoom(0)
	view._process(0.01)
	var empty := true
	for id: String in view._lods:
		empty = empty and (view._lods[id][0] as Node3D).get_child_count() == 0
	var none_close := view._close.is_empty()
	view.focus_realm("outer-2", 1)
	view._process(0.01)
	var built := (view._lods["outer-2"][0] as Node3D).get_child_count() > 0 \
		and (view._lods["outer-1"][0] as Node3D).get_child_count() == 0
	var ready: bool = view._close.has("outer-2") and not (view._close["outer-2"] as Node3D).visible
	view.focus_realm("outer-2", 2)
	var shown: bool = (view._close["outer-2"] as Node3D).visible and not (view._rocks["outer-2"] as Node3D).visible
	view.focus_realm("heart", 2)
	view._process(0.01)
	var heart_rock: bool = (view._rocks["heart"] as Node3D).visible and not view._close.has("heart")
	Settings.reduced_motion = false
	check.call("from afar no realm's detailed buildings or close island are made; coming to a realm makes its "
			+ "buildings, resting there makes its island as seen close, and the close-up shows it in place of the "
			+ "map's rock; the Heart keeps its rock (21.3)",
		empty and none_close and built and ready and shown and heart_rock,
		"empty %s none %s built %s ready %s shown %s heart %s" % [empty, none_close, built, ready, shown, heart_rock])
	view.queue_free()
	await tree.process_frame


func _home() -> void:
	App.services.store.dispatch(&"universe_loaded", {"view": UniverseSample.view(3)})
	var home: Home = await mount.call("home")
	await tree.process_frame
	var places := []
	for b: Button in home.find_children("*", "Button", true, false):
		places.append(b.text)
	var every := Home.PLACES.all(func(r: StringName) -> bool: return places.has(Strings.t(Home.WORDS[r])) \
		or r == &"defences")
	var drawn := home.world != null and home.world.islands.has("heart") and home.world.islands.size() == 5
	var said := str(home.world.accessibility_description)
	home.queue_free()
	await tree.process_frame
	check.call("home draws the universe behind it, keeps every place in its menu and the Heist button, and reads "
			+ "the universe aloud (23.2, 21.8, 20.8)",
		every and places.has(Strings.t("HOME_PLAY")) and drawn and said.contains(Strings.t("UNIVERSE_HEART_TITLE", 6)),
		"%s drawn %s said %s" % [places, drawn, said])
