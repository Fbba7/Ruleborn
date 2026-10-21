class_name UniverseLayout
extends RefCounted
## Where each realm of a universe hangs on the map (§21.1: "Islands hang in a
## vertical column for a portrait screen"; §23.2: "Home. See every realm and
## link at once"). The Heart in the middle, the outer realms in the order
## they opened, filling the rows above and below it as the design's map does
## (realm_diorama.js `UMAP`, :73), so a young universe is a short column and
## a full one fills the phone. Where a link's two ends meet each island, and
## what each realm's type looks like, are worked out here too: no rule of
## the game is, so this is the map's art alone.

## §21.4's realm types, as the server names them, and the palette each
## takes (`RealmPalette`).
const TYPES := {"Heart": "heart", "Skyfield": "skyfield", "Crystalline": "crystalline", "Tidehold": "tidehold",
	"Emberreach": "emberreach", "Verdant": "verdant", "Lantern Vale": "lanternvale"}
## Each realm type's school (§21.4), whose colour its glows take.
const SCHOOLS := {"heart": "spirit", "skyfield": "motion", "crystalline": "matter", "tidehold": "time",
	"emberreach": "energy", "verdant": "life", "lanternvale": "spirit"}
## The outer realms' places, in the order realms open: [x, z, y] in metres
## from the Heart, the column running along z (down the screen).
const SLOTS := [[-14.5, 28.0, -1.2], [15.0, -28.0, 1.0], [15.5, 27.5, -0.6], [-15.0, -27.5, 0.8],
	[0.5, 54.0, -2.0], [-0.5, -54.0, 2.0]]
## A realm's grid across, in tiles: the server's view does not carry it, so
## the map draws the Heart a size up on the outer realms (the design's map
## scales the Heart 0.29 to the others' 0.19).
const OUTER_GRID := 11
const HEART_GRID := 15
## A link's span of the island's radius where it leaves the rim.
const RIM := 0.93


## A realm type's key in `RealmPalette` and `SCHOOLS`: "Lantern Vale" is
## "lanternvale".
static func type_key(type: String) -> String:
	if TYPES.has(type):
		return TYPES[type]
	var k := type.to_lower().replace(" ", "")
	return k if SCHOOLS.has(k) else "heart"


## The island's radius for a grid `tiles` across: its corners and a rim.
static func radius(tiles: int) -> float:
	return Vector2(tiles, tiles).length() / 2.0 + 1.4


static func grid(realm: Dictionary) -> int:
	return HEART_GRID if str(realm.get("realm", "")) == "heart" else OUTER_GRID


## Each realm's place, by its id: the Heart at the origin and each outer
## realm in the next slot, in the order the server lists them (the order
## they opened). `extra` more places follow, for realms still to open.
static func places(realms: Array, extra := 0) -> Dictionary:
	var out := {}
	var slot := 0
	for r: Dictionary in realms:
		var id := str(r.get("realm", ""))
		if id == "heart":
			out[id] = Vector3.ZERO
		elif slot < SLOTS.size():
			out[id] = slot_at(slot)
			slot += 1
	for k in extra:
		if slot + k < SLOTS.size():
			out["next:%d" % k] = slot_at(slot + k)
	return out


static func slot_at(i: int) -> Vector3:
	var s: Array = SLOTS[clampi(i, 0, SLOTS.size() - 1)]
	return Vector3(s[0], s[2], s[1])


## Where a link leaves island `a` (radius `ra`) toward island `b` (radius
## `rb`), and where it lands: on each rim, facing the other.
static func link_ends(a: Vector3, ra: float, b: Vector3, rb: float) -> Array[Vector3]:
	var flat := Vector3(b.x - a.x, 0, b.z - a.z)
	var dir := flat.normalized() if flat.length() > 0.001 else Vector3.FORWARD
	return [a + dir * ra * RIM + Vector3(0, 0.05, 0), b - dir * rb * RIM + Vector3(0, 0.05, 0)]


## The box that holds every place, each with its island's reach: what the
## whole-universe camera frames.
static func bounds(places_by_id: Dictionary, reach: float) -> AABB:
	var box := AABB()
	var first := true
	for id: String in places_by_id:
		var p: Vector3 = places_by_id[id]
		var r := reach * (1.3 if id == "heart" else 1.0)
		var b := AABB(p - Vector3(r, r * 0.6, r), Vector3(r, r * 0.6, r) * 2.0)
		box = b if first else box.merge(b)
		first = false
	return box


## The realm nearest a point on the map's plane, within its island: what a
## tap there means. "" when the point is in the sky.
static func realm_near(places_by_id: Dictionary, at: Vector3, reach: float) -> String:
	var best := ""
	var best_d := INF
	for id: String in places_by_id:
		var p: Vector3 = places_by_id[id]
		var d := Vector2(at.x - p.x, at.z - p.z).length()
		var r := reach * (1.3 if id == "heart" else 1.0)
		if d < r and d < best_d:
			best = id
			best_d = d
	return best
