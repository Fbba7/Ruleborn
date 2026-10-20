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
	_signatures()


static func _layers(kit: RealmKit) -> int:
	var n := 0
	for g: Geo in [kit.hero, kit.prop, kit.clear, kit.water, kit.lava]:
		n += g.triangles
	return n


## A 3 × 3 realm with feature `code` in the middle.
static func _one(code: int) -> RealmKit:
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
		var kit := _one(code)
		var n := _layers(kit)
		if n > FEATURE_MAX:
			over.append([RealmKit.F.keys()[code], n])
		if n == 0 and code not in [RealmKit.F.STREAM]:
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
	check.call("the grid's ground runs out past its edge onto the island and ends in the island's own grass, so the "
			+ "two meet with no seam (21.1)", reach > 3.4 and off == 0, "%f %d" % [reach, off])


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
	check.call("each realm's home carries its signature past the grid — the Heart's walls, Skyfield's windmills, "
			+ "great crystals, a great tree, a lantern festival, smoking vents (21.4)", missing.is_empty(), str(missing))
