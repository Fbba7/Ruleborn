class_name LawFxTests
extends RefCounted
## §21.7's laws on screen (world/law_fx*.gd): every launch law has a world
## signature within §21.3's budget, built from the heist's grid and the same
## on every run; every law has a movement signature; every school a crown;
## harmonies, dissonances and chords are found from content's notes.

## A signature's budget: "a few thousand triangles and a handful of draw
## calls" (the track's brief), inside §21.3's 60,000 and 150 for a heist.
const MAX_TRIANGLES := 6000
const MAX_DRAWS := 8

var tree: SceneTree
var check: Callable


func _init(t: SceneTree, c: Callable) -> void:
	tree = t
	check = c


func run() -> void:
	_tables()
	_links()
	_gaits()
	_crowns()
	await _signatures()
	await _same_every_time()


## The copies of content's notes and chords are content's.
func _tables() -> void:
	var root := ProjectSettings.globalize_path("res://").path_join("..")
	var laws: Array = JSON.parse_string(FileAccess.get_file_as_string(root.path_join("content/laws.json")))
	var chords: Array = JSON.parse_string(FileAccess.get_file_as_string(root.path_join("content/chords.json")))
	var off: Array = []
	for l: Dictionary in laws:
		var notes: Array = []
		for n: String in l["notes"]:
			notes.append(n.to_lower())
		if LawFxLinks.school(l["id"]) != str(l["school"]).to_lower() or LawFxLinks.notes(l["id"]) != notes:
			off.append(l["id"])
	for c: Dictionary in chords:
		var notes: Array = []
		for n: String in c["notes"]:
			notes.append(n.to_lower())
		if LawFxLinks.CHORDS.get(c["id"], []) != notes:
			off.append(c["id"])
	var launch: Array = []
	for l: Dictionary in laws:
		if l["launch"]:
			launch.append(l["id"])
	check.call("LawFx's notes, schools and chords are content's, and its launch list is §7.10's 24 (8.1, 8.5, 21.7)",
		off.is_empty() and laws.size() == LawFxLinks.LAWS.size() and chords.size() == LawFxLinks.CHORDS.size()
			and launch == Array(LawFx.LAUNCH), "%s" % [off])


func _links() -> void:
	var h := LawFxLinks.harmonies(["haste", "static", "aurora"])
	var d := LawFxLinks.dissonances(["bloom", "static", "aurora"])
	var c := LawFxLinks.chords(["haste", "static", "aurora"])
	var two := LawFxLinks.chords(["bounce", "haste"])
	check.call("harmonies, dissonances and chords are read from the laws' notes: Haste and Static share Spark, "
			+ "Bloom clashes with Static and Aurora, and Haste, Static and Aurora make Tempest — three laws, not "
			+ "two (8.2, 8.3, 8.5, 8.8)",
		h.size() == 1 and h[0]["note"] == "spark" and d.size() == 2 and c.size() == 1 and c[0]["chord"] == "tempest"
			and two.is_empty(), "%s %s %s %s" % [h, d, c, two])


func _gaits() -> void:
	var off: Array = []
	for law: String in Array(LawFx.LAUNCH) + Array(LawFx.PARADOXES):
		var g := LawFx.gait(law)
		for k: String in ["bounce", "lean", "stride", "float", "skate"]:
			if not g.has(k):
				off.append([law, k])
	var mixed := LawFxGait.blend(["half_gravity", "frictionless"])
	check.call("every launch law and paradox has a movement signature with bounce, lean, stride, float and skate, "
			+ "and two laws blend into one gait (21.7)",
		off.is_empty() and LawFx.gait("frictionless")["skate"] == 1.0 and LawFx.gait("half_gravity")["float"] > 0.5
			and mixed["skate"] == 1.0 and mixed["float"] > 0.5, "%s %s" % [off, mixed])


func _crowns() -> void:
	var off: Array = []
	for school: String in ["motion", "matter", "time", "energy", "life", "spirit"]:
		var m := LawFx.crown(school)
		var tris := 0 if m == null else m.surface_get_array_len(0) / 3
		if m == null or tris > 400 or tris < 12:
			off.append([school, tris])
	check.call("every school's crown is its own shape, built from code within a few hundred triangles (21.2)",
		off.is_empty() and LawFx.crown("time") != LawFx.crown("life"), "%s" % [off])


static func realm(law: String) -> PackedByteArray:
	var i := RulebornIsland.new()
	i.reset(2)
	var n := i.side()
	var put := {"hedge": [[2, 2], [3, 2]], "ruin_wall": [[n - 3, 3]], "tree": [[1, n - 3]], "pond": [[n - 2, n - 3]],
		"lantern_post": [[2, n - 2]], "static_stone": [[n - 2, 1]]}
	for id: String in put:
		for xy: Array in put[id]:
			i.set_ground(xy[0], xy[1], id)
	i.post_guard(0, 3, 5)
	i.post_guard(1, n - 4, 6)
	i.place_ward("static_coil", 5, 3)
	i.weave(law, n / 2 - 1, n / 2 + 1)
	return i.bytes()


func _signatures() -> void:
	var off: Array = []
	var counts := {}
	for law: String in LawFx.LAUNCH:
		var replay := RulebornReplay.new()
		replay.start("11", 4500, 3, realm(law))
		var view := WorldView.new()
		view.size = Vector2(360, 640)
		tree.root.add_child(view)
		view.show_replay(replay)
		var fx := LawFx.attach(view, replay)
		fx.sync(90)
		fx.sync_world(replay)
		var b := fx.budget(law)
		counts[law] = b
		if not fx.signatures.has(law) or b["triangles"] <= 0 or b["triangles"] > MAX_TRIANGLES \
				or b["draws"] > MAX_DRAWS or fx.crowns.get_child_count() != 2:
			off.append([law, b])
		view.queue_free()
		await tree.process_frame
	var detail: Variant = counts
	if not off.is_empty():
		detail = off
	check.call("every launch law has a world signature over its realm and a crowned pylon, each within %d "
			% MAX_TRIANGLES + "triangles and %d draw calls (21.3, 21.7, 21.9)" % MAX_DRAWS, off.is_empty(),
		"%s" % [detail])


## A replay looks the same every time: the signature's pieces come from the
## heist's seed and its motion from the tick, never the clock.
func _same_every_time() -> void:
	var meshes: Array = []
	for k in 2:
		var replay := RulebornReplay.new()
		replay.start("11", 4500, 3, realm("static"))
		var fx := LawFx.new()
		tree.root.add_child(fx)
		fx.build(LawFxSite.from_replay(replay))
		fx.sync(123)
		var arrays: Array = []
		for mi: MeshInstance3D in fx.find_children("*", "MeshInstance3D", true, false):
			if mi.mesh != null:
				arrays.append(mi.mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX])
		meshes.append(arrays)
		fx.queue_free()
	await tree.process_frame
	check.call("a law's signature is built from the heist's seed alone, so a replay shows the same motes in the same "
			+ "places every time (21.7, 24.10)", not meshes[0].is_empty() and meshes[0] == meshes[1])
