class_name LawFxPaint
extends RefCounted
## The few strokes every law's signature is painted with: a spray of motes,
## a mark on a set of tiles, a pool of light, a cluster of solid pieces. Each
## is one layer, so one draw call (and two for an inked piece).


## A spray of motes, one layer. `o` says how:
## - "n": how many; "shape": law_fx_mote's shape; "colour" (its alpha the
##   strongest opacity); "radius": [least, most];
## - where they start: "tiles" (an Array[Vector2i]: on those tiles), or "at"
##   (a Vector3) with "reach" (metres round it), else anywhere on the realm;
##   "lift": [least, most] metres over the ground;
## - how they move: "vel" (a Vector3, metres a second), "spread" (a Vector3
##   added at random to it), "period": [least, most] seconds of a loop (0:
##   they stay and twinkle), "wobble";
## - "glow" and "pace" for the material.
static func spray(fx: LawFx, sig: Node3D, slot: String, o: Dictionary) -> MeshInstance3D:
	var r := fx.site.rng(slot)
	var b := LawFxBatch.new(LawFxBatch.Kind.MOTES)
	var tiles: Array = o.get("tiles", [])
	var lift: Array = o.get("lift", [0.2, 2.0])
	var radius: Array = o.get("radius", [0.06, 0.12])
	var period: Array = o.get("period", [0.0, 0.0])
	var vel: Vector3 = o.get("vel", Vector3.ZERO)
	var spread: Vector3 = o.get("spread", Vector3.ZERO)
	var colour: Color = o.get("colour", Color.WHITE)
	for k in int(o.get("n", 40)):
		var at: Vector3
		if not tiles.is_empty():
			var t: Vector2i = tiles[k % tiles.size()]
			at = fx.site.centre(t) + Vector3(r.randf_range(-0.45, 0.45), 0, r.randf_range(-0.45, 0.45))
		elif o.has("at"):
			var a := r.randf() * TAU
			var d := sqrt(r.randf()) * float(o.get("reach", 2.0))
			at = (o["at"] as Vector3) + Vector3(cos(a) * d, 0, sin(a) * d)
		else:
			at = fx.site.anywhere(r)
		at.y += r.randf_range(float(lift[0]), float(lift[1]))
		var v := vel + Vector3(r.randf_range(-1, 1) * spread.x, r.randf_range(-1, 1) * spread.y,
			r.randf_range(-1, 1) * spread.z)
		var c := colour
		if o.has("colour_b"):
			c = colour.lerp(o["colour_b"], r.randf())
		b.mote(at, v, r.randf_range(float(period[0]), float(period[1])), r.randf(),
			r.randf_range(float(radius[0]), float(radius[1])), float(o.get("wobble", 0.0)), int(o.get("shape", 0)), c)
	return fx.layer(sig, b, fx.mote_material(float(o.get("glow", 0.35)), float(o.get("pace", 1.0))))


## `pattern` (law_fx_decal's) laid over each of `tiles`, each at its own
## weight a little under 1 so the mark breathes across the realm.
static func mark(fx: LawFx, sig: Node3D, tiles: Array[Vector2i], pattern: int, a: Color, b := Color("#1A0C14"),
		pace := 1.0) -> MeshInstance3D:
	var batch := LawFxBatch.new(LawFxBatch.Kind.DECALS)
	for t: Vector2i in tiles:
		batch.tile(fx.site, t, 0.75 + 0.25 * RealmKit.jitter(t, 5))
	var mi := fx.layer(sig, batch, fx.decal_material(pattern, a, b, pace))
	mi.set_meta("ground", true)
	return mi


## Round marks of `pattern` at each of `centres` (a Vector3 each), `radius`
## metres across: pools of light, ripples, rune rings, a clock face.
static func rounds(fx: LawFx, sig: Node3D, centres: Array, radius: float, pattern: int, a: Color,
		b := Color("#1A0C14"), pace := 1.0) -> MeshInstance3D:
	var batch := LawFxBatch.new(LawFxBatch.Kind.DECALS)
	var k := 0
	for c: Vector3 in centres:
		batch.decal(c + Vector3(0, 0.025, 0), Vector2(radius, radius), 1.0, Vector4(c.x, c.z, k * 0.37, radius))
		k += 1
	return fx.layer(sig, batch, fx.decal_material(pattern, a, b, pace))


## Ground a crew walks on: every tile a ground mark may lie on.
static func ground(site: LawFxSite) -> Array[Vector2i]:
	return site.tiles(LawFxSite.GROUND)


## A few of `tiles`, at most `n`, spread through them evenly.
static func some(tiles: Array[Vector2i], n: int) -> Array[Vector2i]:
	if tiles.size() <= n:
		return tiles
	var out: Array[Vector2i] = []
	var step := float(tiles.size()) / n
	for k in n:
		out.append(tiles[int(k * step)])
	return out


## A few of `points`, at most `n`, spread through them evenly.
static func some_points(points: Array, n: int) -> Array:
	if points.size() <= n:
		return points
	var out: Array = []
	var step := float(points.size()) / n
	for k in n:
		out.append(points[int(k * step)])
	return out


## The pylon's ground, wherever the signature centres: its law's pylon.
static func home(fx: LawFx, law: String) -> Vector3:
	return fx.site.pylon_of(law)


## A soft shadow under something floating, as a dark pool.
static func shadows(fx: LawFx, sig: Node3D, centres: Array, radius: float) -> MeshInstance3D:
	return rounds(fx, sig, centres, radius, 8, Color(0.16, 0.1, 0.25, 1.0))


## §20.8's reduced motion: no strobes, no flashes, no blinking; flashes come
## and go softly and every signature runs slower.
static func calm() -> bool:
	return Settings.reduced_motion


## A flash of light `u` seconds into it, over its first second: sharp, or
## with reduced motion a soft swell that never jumps.
static func flash(u: float, peak: float) -> float:
	if u >= 1.0 or u < 0.0:
		return 0.0
	if calm():
		return sin(u * PI) * minf(peak, 0.2)
	return peak * (1.0 - u)
