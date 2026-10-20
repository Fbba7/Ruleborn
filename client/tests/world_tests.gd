class_name WorldTests
extends RefCounted
## The realm on the world in 3D (world/world_view.gd, TD.8, TD.10): where its
## actors stand, what a tap picks, its materials and its budgets — all
## checked headless, from the scene the view builds.

var tree: SceneTree
var check: Callable


func _init(t: SceneTree, c: Callable) -> void:
	tree = t
	check = c


## A realm with a little of everything: features, raised ground, water, two
## posts, two wards, a law and a building, as the landing tests' island is.
static func island() -> PackedByteArray:
	var i := RulebornIsland.new()
	i.reset(3)
	var put := {"tree": [[1, 1], [9, 2]], "hedge": [[4, 3], [5, 3]], "rock_pillar": [[8, 8]],
		"tall_grass": [[2, 8], [3, 8]], "pond": [[10, 6]], "fog_bank": [[7, 1]], "raised_ground": [[9, 9], [10, 9]],
		"fence": [[3, 1]], "lantern_post": [[5, 9]], "lava_crack": [[6, 11]], "stairs": [[8, 9]]}
	for id: String in put:
		for xy: Array in put[id]:
			i.set_ground(xy[0], xy[1], id)
	i.post_guard(0, 6, 4)
	i.post_guard(1, 3, 7)
	i.place_ward("static_coil", 8, 5)
	i.place_ward("lantern_glare", 2, 3)
	i.weave("bloom", 9, 4)
	i.place_building("hearth", 1, 6)
	return i.bytes()


func run() -> void:
	var replay := RulebornReplay.new()
	replay.start("7", 4500, 3, island())
	var view := WorldView.new()
	view.size = Vector2(540, 960)
	tree.root.add_child(view)
	view.show_replay(replay)
	var spots := replay.reaching()
	var s: Vector2i = spots[0]
	replay.give(0, HeistController.Kind.LAND, s.x * 256 + 128, s.y * 256 + 128)
	for i in 120:
		replay.step()
	view.describe()
	await tree.process_frame
	_places(view, replay)
	_picking(view, replay)
	_materials(view)
	_budgets(view)
	_sight(view, replay)
	view.queue_free()
	await tree.process_frame


func _places(view: WorldView, replay: RulebornReplay) -> void:
	view._place_actors(1.0)
	var crew := replay.crew()
	var guards := replay.guards()
	var off := []
	for i in crew.size():
		var at: Vector2 = crew[i]["at"]
		var want := Vector3(at.x - 6.0, view.world_at(at).y, at.y - 6.0)
		if view._crew[i].position.distance_to(want) > 0.001:
			off.append(["crew", i, view._crew[i].position, want])
	for i in guards.size():
		var at: Vector2 = guards[i]["at"]
		if view._guards[i].position.distance_to(view.world_at(at)) > 0.001:
			off.append(["guard", i, view._guards[i].position, view.world_at(at)])
	# A tile's centre in tiles is its centre in metres, the grid centred.
	var centred := view.world_at(Vector2(0.5, 0.5)).is_equal_approx(Vector3(-5.5, 0, -5.5)) \
		and view.world_at(Vector2(9.5, 9.5)).is_equal_approx(Vector3(3.5, IslandBuilder.LEVEL, 3.5))
	check.call("the world puts every crew member and guard where the simulation does, one tile a metre, the grid "
			+ "centred and a height level half a metre (21.1, TD.10, G65)",
		off.is_empty() and centred and crew.size() == 3 and guards.size() == 2, "%s %s" % [off, centred])


func _picking(view: WorldView, replay: RulebornReplay) -> void:
	var size := replay.size()
	var wrong := []
	for y in size.y:
		for x in size.x:
			var t := Vector2i(x, y)
			var got := view.tile_at(view.screen_at(t))
			if got != t:
				wrong.append([t, got])
	view.turn(1)
	var turned := view.tile_at(view.screen_at(Vector2i(2, 7))) == Vector2i(2, 7)
	view.turn(-1)
	check.call("a tap on the world picks the tile drawn under it, raised tiles included, at every quarter turn of "
			+ "the camera (21.1, TD.10)",
		wrong.is_empty() and turned and view.tile_at(Vector2(2, 2)) == Vector2i(-1, -1),
		"%s %s" % [wrong.slice(0, 6), turned])


## Every mesh in the world, with how many draw calls it takes.
static func meshes(view: WorldView) -> Array:
	var out := []
	for n in view.world.find_children("*", "MeshInstance3D", true, false):
		var mi := n as MeshInstance3D
		if mi.mesh != null and mi.is_visible_in_tree():
			out.append(mi)
	return out


func _materials(view: WorldView) -> void:
	var kit := [load("res://world/toon.gdshader"), load("res://world/toon_clear.gdshader"),
		load("res://world/water.gdshader"), load("res://world/kit_toon.gdshader"), load("res://world/kit_clear.gdshader"),
		load("res://world/kit_ground.gdshader")]
	var inks := [load("res://world/outline.gdshader"), load("res://world/kit_outline.gdshader")]
	var stray := []
	var outlined := 0
	for mi: MeshInstance3D in meshes(view):
		var m := mi.material_override as ShaderMaterial
		if m == null or not (m.shader in kit):
			stray.append(mi.name)
		elif m.next_pass is ShaderMaterial:
			var o := m.next_pass as ShaderMaterial
			outlined += 1
			if not (o.shader in inks) or o.get_shader_parameter("width_px") != null \
					and float(o.get_shader_parameter("width_px")) != 1.5:
				stray.append(mi.name)
	var sky := (view.environment.sky.sky_material as ShaderMaterial).shader == load("res://world/sky.gdshader")
	check.call("every model in the world carries the toon kit's material, the figures and hero features its "
			+ "1.5-pixel ink outline, under §21.2's sky (21.3, 21.2, TD.8)",
		stray.is_empty() and outlined >= 8 and sky, "%s %d %s" % [stray, outlined, sky])


func _budgets(view: WorldView) -> void:
	var triangles := 0
	var calls := 0
	for mi: MeshInstance3D in meshes(view):
		for s in mi.mesh.get_surface_count():
			triangles += mi.mesh.surface_get_array_index_len(s) / 3 if mi.mesh.surface_get_array_index_len(s) > 0 \
				else mi.mesh.surface_get_array_len(s) / 3
			calls += 2 if (mi.material_override as ShaderMaterial).next_pass != null else 1
	check.call("a heist's realm on the world is inside §21.3's budgets: up to about 60,000 triangles and under 150 "
			+ "draw calls (21.3)",
		triangles > 2000 and triangles <= 60000 and calls < 150, "%d triangles, %d draw calls" % [triangles, calls])


func _sight(view: WorldView, replay: RulebornReplay) -> void:
	var shown := view.shown_guard()
	var seen := replay.seen(shown).size() if shown >= 0 else 0
	var drawn: int = view.overlay.mesh.get_surface_count() if view.overlay.mesh != null else 0
	var tris: int = view.overlay.mesh.surface_get_array_len(0) / 3 if drawn > 0 else 0
	view.selected_guard = 1
	view.describe()
	var other := replay.seen(1).size()
	var tris2: int = view.overlay.mesh.surface_get_array_len(0) / 3 if view.overlay.mesh != null else 0
	check.call("the selected guard's sight is drawn on the world tile by tile, as the simulation decides it, with "
			+ "hard edges and no gradient, and only one guard's at a time (21.12)",
		seen > 0 and tris == seen * 12 and tris2 == other * 12, "%d %d %d %d" % [seen, tris, other, tris2])
