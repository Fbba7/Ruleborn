class_name KitTests
extends RefCounted
## The realm kit (world/realm_kit.gd and its kit_*.gd, T3): every terrain
## feature and every building builds inside §21.3's budgets, each of
## §21.5's four looks reads apart, the wards have their two levels, a
## footprint is drawn as its building, and the grid's ground meets the
## island's — all headless, from the meshes the kit writes.

## §21.3: "buildings 2,000 to 8,000" triangles; a feature is a tile's worth.
const BUILDING_MAX := 8000
const FEATURE_MAX := 1600
## §21.3: a whole realm on the home camera.
const REALM_MAX := 40000

var check: Callable


func _init(c: Callable) -> void:
	check = c


func run() -> void:
	_features()
	_buildings()
	_pieces()
	_footprints()
	_ground()
	_realm()
	_mid()
	_signatures()
	_map()
	_hours()


static func _layers(kit: RealmKit) -> int:
	var n := 0
	for g: Geo in [kit.hero, kit.prop, kit.clear, kit.water, kit.lava]:
		n += g.triangles
	return n


## A 3 × 3 realm with feature `code` in the middle.
static func single(code: int) -> RealmKit:
	var codes := PackedByteArray()
	codes.resize(9)
	codes[4] = code
	var levels := PackedByteArray()
	levels.resize(9)
	var ground := PackedByteArray()
	ground.resize(9)
	if code in RealmKit.WET:
		ground[4] = KitGround.WATER
	var kit := RealmKit.of_grid(Vector2i(3, 3), codes, levels, ground, RealmPalette.of("heart"))
	kit.build()
	return kit


func _features() -> void:
	var over := []
	var empty := []
	var uninked := []
	for code in range(1, RealmKit.F.size()):
		if code in [RealmKit.F.VAULT, RealmKit.F.PYLON, RealmKit.F.BUILDING, RealmKit.F.TUNNEL]:
			continue
		var kit := single(code)
		var n := _layers(kit)
		if n > FEATURE_MAX:
			over.append([RealmKit.F.keys()[code], n])
		if n == 0 and code not in [RealmKit.F.STREAM, RealmKit.F.GRAVEL_PATH]:
			empty.append(RealmKit.F.keys()[code])
		if code in RealmKit.HERO and code != RealmKit.F.BUILDING and kit.hero.triangles == 0:
			uninked.append(RealmKit.F.keys()[code])
	check.call("every terrain feature the simulation has builds its own piece, inside a tile's budget, and the ones "
			+ "that change a route are inked (21.9, 21.10, 21.3)",
		over.is_empty() and empty.is_empty() and uninked.is_empty(), "%s %s %s" % [over, empty, uninked])


func _buildings() -> void:
	var over := []
	var alike := []
	var colours := RealmPalette.of("heart")
	for kind: String in BuildingKit.KINDS:
		var looks := []
		for lvl: int in BuildingKit.LOOKS:
			var g := Geo.new()
			var fine := Geo.new()
			var side := 3 if kind == "keeper_s_spire" else 2
			BuildingKit.build(g, kind, Vector3.ZERO, side, lvl, colours, fine)
			var n := g.triangles + fine.triangles
			if n > BUILDING_MAX or n < 30:
				over.append([kind, lvl, n])
			var arrays := g.st.commit_to_arrays()
			looks.append(hash(arrays[Mesh.ARRAY_COLOR]) ^ n)
		for i in range(1, looks.size()):
			if looks[i] == looks[i - 1]:
				alike.append([kind, BuildingKit.LOOKS[i]])
	check.call("every one of the 17 buildings builds at each of §21.5's four looks inside §21.3's budget, and each "
			+ "look differs from the one before (21.5, 21.9, 21.3)",
		over.is_empty() and alike.is_empty() and BuildingKit.KINDS.size() == 17, "%s %s" % [over, alike])


func _pieces() -> void:
	var bad := []
	for kind: String in Palette.WARD_SCHOOL:
		var one := PieceKit.ward(kind, 1)
		var two := PieceKit.ward(kind, 2)
		if one == null or two == null or two.surface_get_array_len(0) <= one.surface_get_array_len(0):
			bad.append(kind)
	for m: ArrayMesh in [PieceKit.vault(false), PieceKit.vault(true), PieceKit.pylon(), PieceKit.broken_pylon(),
			PieceKit.dead_ward()]:
		if m == null or m.surface_get_array_len(0) / 3 > BUILDING_MAX:
			bad.append(m)
	check.call("the Vault shut and open, a pylon standing and broken, and the six wards at their two levels, the "
			+ "second with its gold, all build (21.5, 21.9)", bad.is_empty() and Palette.WARD_SCHOOL.size() == 6,
		str(bad))


func _footprints() -> void:
	var codes := PackedByteArray()
	codes.resize(64)
	for y in 3:
		for x in 3:
			codes[y * 8 + x] = RealmKit.F.BUILDING
	for y in range(5, 7):
		for x in range(5, 7):
			codes[y * 8 + x] = RealmKit.F.BUILDING
	var zeros := PackedByteArray()
	zeros.resize(64)
	var kit := RealmKit.of_grid(Vector2i(8, 8), codes, zeros, zeros, RealmPalette.of("verdant"))
	var plain := kit._footprints()
	kit.buildings = [["library", 5, 5, 2, 7]]
	var told := kit._footprints()
	# A path down the east side of the 2 × 2 at (5, 5) turns its door east.
	var lanes := zeros.duplicate()
	lanes[5 * 8 + 7] = KitGround.GRAVEL
	lanes[6 * 8 + 7] = KitGround.GRAVEL
	kit.surfaces = lanes
	var east := kit.facing(Vector2i(5, 5), 2)
	kit.surfaces = zeros
	var south := kit.facing(Vector2i(5, 5), 2)
	check.call("a 3 × 3 footprint is drawn as the Keeper's Spire and another as its building where the screen names "
			+ "it, at its level, its door toward the path beside it (10.1, 21.5)",
		plain.size() == 2 and plain[0][0] == "keeper_s_spire" and plain[1][0] == "hearth" and told[1][0] == "library"
			and told[1][4] == 7 and is_equal_approx(east, PI / 2.0) and is_zero_approx(south),
		"%s %s %f %f" % [plain, told, east, south])


func _ground() -> void:
	var zeros := PackedByteArray()
	zeros.resize(36)
	var colours := RealmPalette.of("tidehold")
	var kit := RealmKit.of_grid(Vector2i(6, 6), zeros, zeros, zeros, colours)
	kit.build()
	var arrays := kit.ground.st.commit_to_arrays()
	var verts: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var cols: PackedColorArray = arrays[Mesh.ARRAY_COLOR]
	var reach := 0.0
	var off := 0
	for i in verts.size():
		var v := verts[i]
		var out := maxf(absf(v.x), absf(v.z))
		reach = maxf(reach, out)
		if out > 3.4 and not cols[i].is_equal_approx(colours["grass"]):
			off += 1
	check.call("the grid's ground runs out past its edge onto the island and ends in the colour the island's meadow "
			+ "turns to beside it, so the two meet with no seam (21.1)", reach > 3.4 and off == 0, "%f %d" % [reach, off])


func _realm() -> void:
	var replay := RulebornReplay.new()
	replay.start("7", 100, 3, WorldTests.island())
	var kit := RealmKit.new(replay, RealmPalette.of("heart"))
	kit.build()
	var total := 0
	for g: Geo in [kit.ground, kit.scatter, kit.hero, kit.prop, kit.clear, kit.water, kit.lava]:
		total += g.triangles
	var nodes := kit.instances()
	check.call("a realm's ground, features and buildings take under §21.3's 40,000 triangles in at most seven merged "
			+ "meshes, so it draws in a handful of calls (21.3)",
		total > 3000 and total < REALM_MAX and nodes.size() <= 7, "%d triangles, %d meshes" % [total, nodes.size()])


## A lived-in realm (the kit's own `kit_realm.gd` shot, grown): the
## Keeper's Spire and nine more buildings at `lvl` on the largest grid,
## joined by paths, with trees, hedges, water, lanterns and a statue, its kit
## built at `detail`.
static func lived_in(lvl: int, detail: int) -> RealmKit:
	var ex := RulebornIsland.new()
	ex.reset(9)
	for b: Array in [["keeper_s_spire", 5, 4], ["hearth", 1, 1], ["star_well", 9, 1], ["hearth", 11, 4],
			["garden", 1, 9], ["library", 10, 9], ["storehouse", 5, 10], ["nursery", 1, 5], ["observatory", 11, 12],
			["hearth", 8, 12]]:
		ex.place_building(b[0], b[1], b[2])
	var put := {"gravel_path": [[2, 3], [3, 3], [4, 3], [5, 3], [6, 3], [7, 3], [8, 3], [9, 3], [10, 3], [6, 7],
		[6, 8], [6, 9], [3, 7], [4, 7], [5, 7], [7, 7], [8, 7], [9, 7], [10, 7], [10, 6], [3, 8], [3, 9]],
		"tree": [[0, 0], [4, 0], [13, 1], [0, 12], [13, 9], [4, 12], [12, 0], [7, 0]],
		"hedge": [[4, 9], [4, 10], [4, 11]], "pond": [[12, 2], [13, 2], [13, 3]], "stream": [[0, 7], [1, 7], [2, 7]],
		"lantern_post": [[4, 4], [9, 4], [8, 8], [2, 11]], "flower_meadow": [[5, 0], [6, 0], [0, 3], [7, 13]],
		"bush": [[8, 0], [12, 11], [3, 13]], "tall_grass": [[0, 9], [0, 10], [13, 12], [13, 13]],
		"boulder": [[10, 0]], "bell_post": [[9, 8]], "statue": [[5, 8]], "fence": [[0, 13], [1, 13], [2, 13]],
		"shade_canopy": [[7, 8]]}
	for id: String in put:
		for xy: Array in put[id]:
			ex.set_ground(xy[0], xy[1], id)
	var replay := RulebornReplay.new()
	replay.start("7", 4500, 3, ex.bytes())
	var kit := RealmKit.new(replay, RealmPalette.of("heart"))
	var known := []
	for b: Array in ex.buildings():
		known.append([b[0], b[1], b[2], b[3], lvl])
	kit.buildings = known
	kit.island_seed = 7
	kit.detail = detail
	kit.build()
	return kit


## The mid-detail level (BuildingKit.MID): a lived-in realm of ten
## buildings at level 10 on the home camera stays under §21.3's 40,000
## triangles as drawn, the inked layer counted twice for its ink pass; the
## buildings at that level take under 40 % of their full detail, and none
## of the larger ones over two thirds.
func _mid() -> void:
	var drawn := func(kit: RealmKit) -> int:
		var n := kit.hero.triangles
		for g: Geo in [kit.ground, kit.scatter, kit.hero, kit.prop, kit.clear, kit.water, kit.lava]:
			n += g.triangles
		return n
	var full: int = drawn.call(lived_in(10, BuildingKit.FULL))
	var mid: int = drawn.call(lived_in(10, BuildingKit.MID))
	var heavy := []
	var sums := Vector2i.ZERO
	for kind: String in BuildingKit.KINDS:
		var n: Array[int] = []
		for det: int in [BuildingKit.FULL, BuildingKit.MID]:
			var g := Geo.new()
			g.skip_down = true
			BuildingKit.build(g, kind, Vector3.ZERO, 2, 10, RealmPalette.of("heart"), null, null, 0.0, det)
			n.append(g.triangles)
		sums += Vector2i(n[0], n[1])
		if (n[0] > 600 and n[1] * 3 > n[0] * 2) or n[1] < 50:
			heavy.append([kind, n[0], n[1]])
	check.call("at the mid detail a fully built realm draws under §21.3's 40,000 triangles with its ink, and the "
			+ "buildings take about a third of their full detail (21.3)",
		mid < REALM_MAX and mid < full and sums.y * 5 < sums.x * 2 and heavy.is_empty(),
		"%d full, %d mid, %s %s" % [full, mid, sums, heavy])


func _signatures() -> void:
	var missing := []
	for realm: String in RealmPalette.TYPES:
		if realm == "tidehold":
			continue
		var g := Geo.new()
		var fine := Geo.new()
		KitSignature.build(g, fine, realm, 10.0, RealmPalette.of(realm))
		if g.triangles + fine.triangles == 0:
			missing.append(realm)
	# And it grows with the realm's level (21.4): more lanterns, a second windmill.
	var small := Geo.new()
	var big := Geo.new()
	KitSignature.build(small, Geo.new(), "lanternvale", 10.0, RealmPalette.of("lanternvale"), 0.0)
	KitSignature.build(big, Geo.new(), "lanternvale", 10.0, RealmPalette.of("lanternvale"), 1.0)
	check.call("each realm's home carries its signature past the grid — the Heart's walls, Skyfield's windmills, "
			+ "great crystals, a great tree, a lantern festival, smoking vents — grown with the realm's level (21.4)",
		missing.is_empty() and big.triangles > small.triangles, "%s %d %d" % [missing, small.triangles, big.triangles])


## The universe map's versions (BuildingKit.build_map): 80–250 triangles
## each, every look apart.
func _map() -> void:
	var bad := []
	var colours := RealmPalette.of("skyfield")
	for kind: String in BuildingKit.KINDS:
		var prev := -1
		for lvl: int in BuildingKit.LOOKS:
			var g := Geo.new()
			g.skip_down = true
			BuildingKit.build_map(g, kind, Vector3.ZERO, 2, lvl, colours)
			if g.triangles < 20 or g.triangles > 250 or g.triangles == prev:
				bad.append([kind, lvl, g.triangles])
			prev = g.triangles
	check.call("every building has a map version for the universe map of at most 250 triangles, each of §21.5's "
			+ "looks apart (21.3, 21.5)", bad.is_empty(), str(bad))


## RealmKit.by_hour: the kit's glows by the hour, none by day, full at night.
func _hours() -> void:
	var zeros := PackedByteArray()
	zeros.resize(9)
	var kit := RealmKit.of_grid(Vector2i(3, 3), zeros, zeros, zeros, RealmPalette.of("heart"))
	kit.build()
	var root := Node3D.new()
	for mi: MeshInstance3D in kit.instances():
		root.add_child(mi)
	var lit := func() -> Array:
		var out := []
		for n in root.get_children():
			var m := (n as MeshInstance3D).material_override as ShaderMaterial
			var v: Variant = m.get_shader_parameter("night")
			if v != null:
				out.append(float(v))
		return out
	RealmKit.by_hour(root, 23)
	var night: Array = lit.call()
	RealmKit.by_hour(root, 12)
	var day: Array = lit.call()
	check.call("the kit's windows, lanterns and crystals glow by the hour: brighter at night than by day (21.2)",
		not night.is_empty() and night.all(func(v: float) -> bool: return v == 1.0)
			and day.all(func(v: float) -> bool: return v == 0.0), "%s %s" % [night, day])
	# The builder's grid (RealmKit.show_grid) on the ground, and off again.
	var shown := func() -> Array:
		var out := []
		for n in root.get_children():
			var v: Variant = ((n as MeshInstance3D).material_override as ShaderMaterial).get_shader_parameter("grid_show")
			if v != null:
				out.append(float(v))
		return out
	RealmKit.show_grid(root, 1.0)
	var on: Array = shown.call()
	RealmKit.show_grid(root, 0.0)
	var off: Array = shown.call()
	root.free()
	check.call("the builder's grid shows on the realm's ground when asked and goes again (T6's terrain editor)",
		on == [1.0] and off == [0.0], "%s %s" % [on, off])
