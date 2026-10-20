class_name LookTests
extends RefCounted
## How a realm looks around its grid (world/world_look.gd, island_builder.gd,
## realm_palette.gd): every realm has its palette, light and sky at every
## hour; the island holds the grid without a seam and keeps its scatter off
## it; and the island stays inside its share of §21.3's budgets.

## The island and its scatter's share of a realm's 25,000–40,000 triangles
## and of its 150 draw calls (§21.3), leaving the rest to the kit, the
## buildings and the figures.
const ISLAND_TRIANGLES := 18000
const ISLAND_CALLS := 24

var tree: SceneTree
var check: Callable


func _init(t: SceneTree, c: Callable) -> void:
	tree = t
	check = c


func run() -> void:
	_palettes()
	_hours()
	_seamless()
	await _budget()


## §21.4: all seven realms, each with every colour the world draws from.
func _palettes() -> void:
	var keys := ["ground", "grass", "stone", "rock", "soil", "dirt", "cliff", "cliff_deep", "trim", "plant", "accent",
		"bloom", "light", "sky_top", "sky_mid", "sky_low"]
	var missing := []
	for realm: String in ["heart", "skyfield", "crystalline", "tidehold", "emberreach", "verdant", "lanternvale"]:
		var p := RealmPalette.of(realm)
		for k: String in keys:
			if not p.has(k):
				missing.append("%s.%s" % [realm, k])
		if not RealmPalette.LIGHTS.has(realm):
			missing.append("%s light" % realm)
	check.call("every realm has its ground, plants, rock, sky and light (21.4)", missing.is_empty(), str(missing))


## §21.2: the sky and the light follow the hour; night is darker than day in
## every realm, and the shade is never black.
func _hours() -> void:
	var wrong := []
	for realm: String in RealmPalette.TYPES:
		var day := RealmPalette.realm_sky_at(12, realm)
		var night := RealmPalette.realm_sky_at(23, realm)
		if night[0].get_luminance() >= day[0].get_luminance():
			wrong.append("%s sky" % realm)
		var lit_day: Array = RealmPalette.light_at(12, realm)
		var lit_night: Array = RealmPalette.light_at(23, realm)
		if float(lit_night[1]) >= float(lit_day[1]):
			wrong.append("%s sun" % realm)
		var shade: Color = RealmPalette.hemisphere_at(23, realm)[1]
		if shade.get_luminance() <= 0.0:
			wrong.append("%s shade" % realm)
	var keys := [RealmPalette.hour_key(3), RealmPalette.hour_key(7), RealmPalette.hour_key(12),
		RealmPalette.hour_key(19), RealmPalette.hour_key(23)]
	check.call("the sky and the light follow the player's hour in every realm: night, dusk, day (21.2)",
		wrong.is_empty() and keys == ["night", "dusk", "day", "dusk", "night"], "%s %s" % [wrong, keys])


## §21.1: the round rock holds the square grid. The meadow is flat just under
## the grid's ground everywhere the grid reaches, the rock's edge clears
## the grid's corners, and no scatter stands on the grid.
func _seamless() -> void:
	var b := IslandBuilder.new(Vector2i(12, 12), 77, RealmPalette.of("verdant"), "verdant")
	var flat := true
	for x in range(-6, 7):
		for z in range(-6, 7):
			if absf(b.height(x, z) - (IslandBuilder.TOP - 0.02)) > 0.001:
				flat = false
	var clears := true
	for k in 72:
		var a := TAU * k / 72.0
		if b.edge(a) < Vector2(6, 6).length() + 0.5:
			clears = false
	var on_grid := 0
	for part: Array in b.scatter():
		if part.size() > 5 and part[5] is float and float(part[5]) > 0.0:
			continue
		for t: Transform3D in part[1]:
			# Standing on the ground, not flying over it as motes and fireflies do.
			if absf(t.origin.x) < 5.9 and absf(t.origin.z) < 5.9 and t.origin.y < 0.15:
				on_grid += 1
	check.call("the island holds the realm's grid without a seam: flat under every tile, its rim clear of the "
			+ "corners, and its grass, stones and flowers off the grid (21.1, 21.11)",
		flat and clears and on_grid == 0, "flat %s, clears %s, %d on the grid" % [flat, clears, on_grid])


## §21.3: the island, its scatter and its sky dressing inside their share,
## counted from the scene the look builds, instances included.
func _budget() -> void:
	var worst := Vector2i.ZERO
	var at := ""
	for realm: String in RealmPalette.TYPES:
		var world := Node3D.new()
		tree.root.add_child(world)
		var look := WorldLook.new(world)
		var statics := Node3D.new()
		world.add_child(statics)
		look.island(statics, Vector2i(14, 14), 5, RealmPalette.of(realm), realm)
		var drawn := LookTests.count(world)
		if drawn.x > worst.x or drawn.y > worst.y:
			worst = Vector2i(maxi(worst.x, drawn.x), maxi(worst.y, drawn.y))
			at = realm
		world.queue_free()
	await tree.process_frame
	check.call("a realm's island and scatter stay inside their share of §21.3's budgets: at most %d triangles and %d "
			% [ISLAND_TRIANGLES, ISLAND_CALLS] + "draw calls on a 14 by 14 grid (21.3)",
		worst.x <= ISLAND_TRIANGLES and worst.y <= ISLAND_CALLS, "%d triangles, %d draw calls (%s)" % [worst.x,
			worst.y, at])


## Triangles and draw calls under `root`: every mesh, every instance.
static func count(root: Node) -> Vector2i:
	var triangles := 0
	var calls := 0
	for n in root.find_children("*", "MeshInstance3D", true, false):
		var mesh := (n as MeshInstance3D).mesh
		if mesh != null:
			triangles += mesh.surface_get_array_len(0) / 3
			calls += 1
	for n in root.find_children("*", "MultiMeshInstance3D", true, false):
		var mm := (n as MultiMeshInstance3D).multimesh
		triangles += mm.mesh.surface_get_array_len(0) / 3 * mm.instance_count
		calls += 1
	return Vector2i(triangles, calls)
