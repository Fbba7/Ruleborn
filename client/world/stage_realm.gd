class_name StageRealm
extends RefCounted
## The realm a screen that is not a heist draws: a heist started on the
## island's own bytes and left at tick 0, the way the builder and the heist
## do it (`RulebornReplay.start(seed, ticks, crew, island)`), so what any
## screen shows is the simulation's own reading of the island and never the
## client's. The helpers here turn what a screen's state holds — an island's
## bytes, a realm's level, the universe view's buildings — into that.

const SEED := "1"
const TICKS := 30
## The buildings' footprints when the island does not place them: §10.1's
## sides, read from the island by placing one on a blank grid.
const FALLBACK_SIDE := 2


## A heist at tick 0 on `bytes`, with `crew` raiders not yet landed; null if
## the bytes do not load.
static func replay_of(bytes: PackedByteArray, crew := 3) -> RulebornReplay:
	var r := RulebornReplay.new()
	if bytes.is_empty() or not r.start(SEED, TICKS, crew, bytes):
		return null
	return r


## A bare island of realm level `level` (§5.2: 10 by 10 at level 1 to 14 by
## 14 at 5): what a scout sees of a realm it knows only by its counts.
static func blank(level: int) -> PackedByteArray:
	var i := RulebornIsland.new()
	i.reset(clampi(level, 1, 5))
	return i.bytes()


## §21.4's realm type as the palette names it: "Heart" → "heart".
static func realm_type(type_name: String) -> String:
	var t := type_name.to_lower().replace(" ", "")
	return t if RealmPalette.TYPES.has(t) else "heart"


## The island's buildings, each {kind, at, side, level}: those the island
## places, at the level the universe view gives their kind, then those the
## universe view places that the island does not. `levels` maps a kind to
## its level.
static func buildings(island: RulebornIsland, listed: Array) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	var levels := {}
	for b: Dictionary in listed:
		levels[str(b["kind"])] = int(b.get("level", 1))
	var placed := {}
	for b: Array in island.buildings():
		var kind := str(b[0])
		placed[kind] = true
		out.append({"kind": kind, "at": Vector2i(int(b[1]), int(b[2])), "side": int(b[3]),
			"level": int(levels.get(kind, 1))})
	for b: Dictionary in listed:
		var at: Variant = b.get("at")
		if placed.has(str(b["kind"])) or not (at is Dictionary):
			continue
		out.append({"kind": str(b["kind"]), "at": Vector2i(int(at["x"]), int(at["y"])),
			"side": side_of(str(b["kind"])), "level": int(b.get("level", 1))})
	return out


## A building's footprint side, as the island's rules give it.
static func side_of(kind: String) -> int:
	var i := RulebornIsland.new()
	i.reset(5)
	if i.place_building(kind, 1, 1):
		for b: Array in i.buildings():
			return int(b[3])
	return FALLBACK_SIDE


## The island with its buildings lifted off, so the world's plain house does
## not stand inside the levelled one a screen draws in its place.
static func without_buildings(island: RulebornIsland) -> PackedByteArray:
	var copy := RulebornIsland.new()
	copy.read(island.bytes())
	for b: Array in island.buildings():
		for dy in int(b[3]):
			for dx in int(b[3]):
				copy.clear(int(b[1]) + dx, int(b[2]) + dy)
	return copy.bytes()
