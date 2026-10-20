class_name LawFxSite
extends RefCounted
## What a law's signature is drawn over: the realm's grid as the simulation
## gives it (`RulebornReplay.size()`, `features()`, `heights()`), its pylons
## and its Vault, in the world's frame (tile (x, y) centred at
## (x − w/2 + 0.5, h, y − h/2 + 0.5), as `WorldView.world_at`). Every choice a
## signature makes at random is drawn from the heist's seed, so a replay and
## every phone show the same motes in the same places.

## Codes are `RulebornReplay.features()`'s: 0 open, 1 + sim::grid::Feature's
## index (`RealmKit.F`).
## What stands up out of the ground and stops a crew: what Bounce wobbles,
## Glass clears, Thorns and Brittle stone dress.
const WALLS := [RealmKit.F.RUIN_WALL, RealmKit.F.FENCE, RealmKit.F.CRYSTAL_WALL, RealmKit.F.HEDGE,
	RealmKit.F.BOULDER, RealmKit.F.ROCK_PILLAR, RealmKit.F.STATUE, RealmKit.F.BUILDING]
const HEDGES := [RealmKit.F.HEDGE, RealmKit.F.THICKET, RealmKit.F.BUSH]
const PLANTS := [RealmKit.F.TREE, RealmKit.F.HEDGE, RealmKit.F.THICKET, RealmKit.F.BUSH, RealmKit.F.TALL_GRASS,
	RealmKit.F.FLOWER_MEADOW, RealmKit.F.SHADE_CANOPY, RealmKit.F.CLIMBING_VINES]
const WATER := [RealmKit.F.STREAM, RealmKit.F.POND, RealmKit.F.MARSH, RealmKit.F.RAPIDS, RealmKit.F.HOT_SPRING,
	RealmKit.F.WATERFALL]
## Metal and charged props, where Chain lightning's arcs jump.
const METAL := [RealmKit.F.STATIC_STONE, RealmKit.F.BELL_POST, RealmKit.F.LANTERN_POST]
const LIGHTS := [RealmKit.F.LANTERN_POST, RealmKit.F.EMBER_VENT, RealmKit.F.LAVA_CRACK, RealmKit.F.HOT_SPRING]
## Ground a crew walks on, where a ground mark may be laid.
const GROUND := [RealmKit.F.OPEN, RealmKit.F.TALL_GRASS, RealmKit.F.GRAVEL_PATH, RealmKit.F.FLOWER_MEADOW,
	RealmKit.F.SCREE, RealmKit.F.ICE_SHEET, RealmKit.F.FOG_BANK, RealmKit.F.SHADE_CANOPY]

var size := Vector2i.ZERO
var features := PackedByteArray()
var heights := PackedByteArray()
## Each woven law's pylon: {"at": world position, "tile", "law", "school",
## "standing"}.
var pylons: Array[Dictionary] = []
## The Vault, in the world; the realm's middle if it has none.
var heart := Vector3.ZERO
## The wards and where each guard stood at the start, in the world.
var wards: Array = []
var posts: Array = []
var seed_value := 0


static func from_replay(r: RulebornReplay) -> LawFxSite:
	var s := LawFxSite.new()
	s.size = r.size()
	s.features = r.features()
	s.heights = r.heights()
	s.seed_value = hash(str(r.seed())) ^ hash(s.features)
	var v := r.vault()
	if v.has("at"):
		s.heart = s.world_at(v["at"])
	for w: Dictionary in r.wards():
		s.wards.append(s.world_at(w["at"]))
	for g: Dictionary in r.guards():
		s.posts.append(s.world_at(g["at"]))
	for p: Dictionary in r.pylons():
		var at: Vector2 = p["at"]
		s.pylons.append({"at": s.world_at(at), "tile": Vector2i(floori(at.x), floori(at.y)), "law": str(p["law"]),
			"school": str(p["school"]), "standing": bool(p["standing"])})
	return s


## A bare realm of `grid` tiles, for a preview with no heist behind it: the
## law card's and Weaving's live preview.
static func bare(grid: Vector2i, laws: Array, seed_from := 7) -> LawFxSite:
	var s := LawFxSite.new()
	s.size = grid
	s.features.resize(grid.x * grid.y)
	s.heights.resize(grid.x * grid.y)
	s.seed_value = seed_from
	var n := laws.size()
	for k in n:
		var a := TAU * k / maxf(1.0, n) + 0.6
		var tile := Vector2i(grid.x / 2 + roundi(cos(a) * grid.x * 0.28), grid.y / 2 + roundi(sin(a) * grid.y * 0.28))
		s.pylons.append({"at": s.centre(tile), "tile": tile, "law": str(laws[k]),
			"school": LawFxLinks.school(str(laws[k])), "standing": true})
	return s


## Where a point in tiles (as RulebornReplay gives it) stands in the world.
func world_at(at: Vector2) -> Vector3:
	var t := Vector2i(clampi(floori(at.x), 0, maxi(0, size.x - 1)), clampi(floori(at.y), 0, maxi(0, size.y - 1)))
	return Vector3(at.x - size.x / 2.0, height(t), at.y - size.y / 2.0)


## The middle of tile `t`, on the ground at its height.
func centre(t: Vector2i) -> Vector3:
	return Vector3(t.x - size.x / 2.0 + 0.5, height(t), t.y - size.y / 2.0 + 0.5)


func height(t: Vector2i) -> float:
	var i := t.y * size.x + t.x
	return (heights[i] if i >= 0 and i < heights.size() else 0) * IslandBuilder.LEVEL


func code(t: Vector2i) -> int:
	var i := t.y * size.x + t.x
	return features[i] if i >= 0 and i < features.size() else 0


## Every tile whose feature is one of `codes`, in row order.
func tiles(codes: Array) -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	for y in size.y:
		for x in size.x:
			if codes.has(code(Vector2i(x, y))):
				out.append(Vector2i(x, y))
	return out


## A generator for one law's choices, the same on every phone for this heist.
func rng(slot: String) -> RandomNumberGenerator:
	var r := RandomNumberGenerator.new()
	r.seed = seed_value ^ hash(slot)
	return r


## A point over the realm's tiles at `lift` above its ground.
func anywhere(r: RandomNumberGenerator, lift := 0.0) -> Vector3:
	var t := Vector2i(r.randi_range(0, maxi(0, size.x - 1)), r.randi_range(0, maxi(0, size.y - 1)))
	return centre(t) + Vector3(r.randf_range(-0.5, 0.5), lift, r.randf_range(-0.5, 0.5))


## The realm's half-width and half-depth in metres.
func half() -> Vector2:
	return Vector2(size) / 2.0


## This law's pylon, or the first pylon, or the Heart.
func pylon_of(law: String) -> Vector3:
	for p: Dictionary in pylons:
		if p["law"] == law:
			return p["at"]
	return heart
