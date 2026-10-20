class_name KitGround
extends RefCounted
## The realm's ground as one painted surface (§21.1's picture-book diorama,
## the design's "painted grass with worn dirt paths"), built from the
## simulation's own grid: every tile flat at its height (`heights()`), its
## surface (`surfaces()`: plain, gravel, water, moss) painted into the
## vertices and read by kit_ground.gdshader, which adds the brush strokes,
## the cobbles of a path and the faint seams that keep the grid readable.
## A step between levels is a soft earthy cliff with a rounded grass lip;
## water lies in a bed below its banks, its surface a mesh of its own for
## water.gdshader, carrying how far each point is from the shore.
##
## Paint channels (UV, UV2): path, lushness; cliff, stone.

## Quads along a tile's side: the ground's resolution.
const SUB := 3
## How far a water bed lies below its tile, and the water under its banks.
const BED := 0.24
const WATER_DROP := 0.012
## The most trail segments the ground shader draws (kit_ground.gdshader).
const LANES := 48
## The island's own grass top, which the grid's edge meets.
const ISLAND_Y := -0.02
## A tile's surfaces, as `surfaces()` gives them.
const GRAVEL := 1
const WATER := 2
const MOSS := 3

var size := Vector2i.ZERO
var levels := PackedInt32Array()
var wet := PackedByteArray()
var palette: Dictionary = {}
## §21.4's realm, for its plants among the grass.
var realm := "heart"

var terrain := Geo.new()
var water := Geo.new()
var scatter := Geo.new()
## A water tile's tint (marsh, spring, rapids), by tile.
var tints := {}
## The island's own builder (T2's), for the meadow's colour: the grid's
## ground starts from the very colour the island's meadow has under it.
var island: IslandBuilder
## Worn earth trails, tile-space segments [a, b] (Vector2), joining the
## buildings' doors and the Vault: ground paint, not the simulation's gravel.
var trails: Array = []

## Fields at tile centres, sampled between them so the paint never shows a
## tile's square: path, lush, apron, scorch, stone, shade, wet.
var _fields: Dictionary = {}


## `codes` are `RulebornReplay.features()`; `blocked` the tiles under a
## building; `wet_codes` the features drawn as water.
func _init(grid: Vector2i, heights: PackedByteArray, surfaces: PackedByteArray, codes: PackedByteArray,
		blocked: Dictionary, wet_codes: Array, colours: Dictionary) -> void:
	size = grid
	palette = colours
	realm = KitStyle.realm_of(colours)
	terrain.painted = true
	water.painted = true
	var n := size.x * size.y
	levels.resize(n)
	wet.resize(n)
	for key: String in ["path", "lush", "apron", "scorch", "stone", "shade", "wet", "bloom", "occ"]:
		var f := PackedFloat32Array()
		f.resize(n)
		_fields[key] = f
	for i in n:
		levels[i] = heights[i] if i < heights.size() else 0
		var s: int = surfaces[i] if i < surfaces.size() else 0
		var c: int = codes[i] if i < codes.size() else 0
		var t := Vector2i(i % size.x, i / size.x)
		wet[i] = 1 if s == WATER or c in wet_codes else 0
		_put("path", i, 1.0 if s == GRAVEL or c == RealmKit.F.GRAVEL_PATH else 0.0)
		_put("lush", i, 1.0 if s == MOSS else (0.7 if c in [RealmKit.F.TALL_GRASS, RealmKit.F.THICKET,
			RealmKit.F.MARSH, RealmKit.F.HEDGE, RealmKit.F.CLIMBING_VINES] else 0.0))
		_put("apron", i, 1.0 if blocked.has(t) else 0.0)
		_put("scorch", i, 1.0 if c in [RealmKit.F.LAVA_CRACK, RealmKit.F.EMBER_VENT] else 0.0)
		_put("stone", i, 1.0 if c in [RealmKit.F.SCREE, RealmKit.F.ROCK_PILLAR, RealmKit.F.PIT,
			RealmKit.F.STATIC_STONE, RealmKit.F.TUNNEL] else 0.0)
		_put("shade", i, 1.0 if c in [RealmKit.F.TREE, RealmKit.F.SHADE_CANOPY, RealmKit.F.THICKET] else 0.0)
		_put("bloom", i, 1.0 if c == RealmKit.F.FLOWER_MEADOW else 0.0)
		_put("occ", i, 1.0 if c in RealmKit.HERO or blocked.has(t) else 0.0)
		_put("wet", i, float(wet[i]))


func _put(key: String, i: int, v: float) -> void:
	var f: PackedFloat32Array = _fields[key]
	f[i] = v
	_fields[key] = f


## Build the terrain, the water and the grass between features.
func build(open: Callable) -> void:
	for y in size.y:
		for x in size.x:
			var t := Vector2i(x, y)
			_top(t)
			for d: Vector2i in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
				_side(t, d)
			if is_wet(t):
				_water(t, tints.get(t, Color.WHITE))
				if realm in ["tidehold", "verdant"] and RealmKit.jitter(t, 7) < 0.6:
					_lilies(t)
			elif open.call(t):
				_tufts(t)


func index(t: Vector2i) -> int:
	return t.y * size.x + t.x


func inside(t: Vector2i) -> bool:
	return t.x >= 0 and t.y >= 0 and t.x < size.x and t.y < size.y


func is_wet(t: Vector2i) -> bool:
	return inside(t) and wet[index(t)] == 1


## The ground's height on tile `t`: its level, or its bed if it is water;
## the island's top outside the grid.
func top_y(t: Vector2i) -> float:
	if not inside(t):
		return ISLAND_Y
	var y := levels[index(t)] * IslandBuilder.LEVEL
	return y - BED if wet[index(t)] == 1 else y


## World position of the tile-space point (u, v) (0..size) at height y.
func world(u: float, v: float, y: float) -> Vector3:
	return Vector3(u - size.x / 2.0, y, v - size.y / 2.0)


## Field `key` at the tile-space point (u, v), bilinear between tile centres.
func field(key: String, u: float, v: float) -> float:
	var f: PackedFloat32Array = _fields[key]
	var fu := clampf(u - 0.5, 0.0, size.x - 1.0)
	var fv := clampf(v - 0.5, 0.0, size.y - 1.0)
	var x0 := mini(int(fu), size.x - 1)
	var y0 := mini(int(fv), size.y - 1)
	var x1 := mini(x0 + 1, size.x - 1)
	var y1 := mini(y0 + 1, size.y - 1)
	var a := fu - x0
	var b := fv - y0
	var top := lerpf(f[y0 * size.x + x0], f[y0 * size.x + x1], a)
	var low := lerpf(f[y1 * size.x + x0], f[y1 * size.x + x1], a)
	return lerpf(top, low, b)


## How near the tile-space point (u, v) is to the path network: 1 on a
## path's middle line, falling to 0 a little over a third of a tile out.
## The network joins each path tile's centre to its path neighbours', so
## paths are ribbons that turn and branch, never blots.
func path_at(u: float, v: float) -> float:
	var f: PackedFloat32Array = _fields["path"]
	var best := 9.0
	var cx := int(floor(u))
	var cy := int(floor(v))
	var p := Vector2(u, v)
	for dy in range(-1, 2):
		for dx in range(-1, 2):
			var t := Vector2i(cx + dx, cy + dy)
			if not inside(t) or f[index(t)] < 0.5:
				continue
			var a := Vector2(t) + Vector2(0.5, 0.5)
			best = minf(best, p.distance_to(a) - 0.06)
			for d: Vector2i in [Vector2i(1, 0), Vector2i(0, 1)]:
				var n := t + d
				if inside(n) and f[index(n)] >= 0.5:
					best = minf(best, _segment(p, a, a + Vector2(d)))
	return clampf(1.0 - best / 0.62, 0.0, 1.0)


static func _segment(p: Vector2, a: Vector2, b: Vector2) -> float:
	var ab := b - a
	var t := clampf((p - a).dot(ab) / ab.length_squared(), 0.0, 1.0)
	return p.distance_to(a + ab * t)


## Trodden earth and path stone in a realm: its stone, warmed by its soil
## (its "ground" is grass-green in some realms, so never that).
static func earth(colours: Dictionary) -> Color:
	return (colours["stone"] as Color).lerp(colours["soil"], 0.3)


## A smooth seeded noise in [0, 1) over the ground, for the paint.
static func noise(u: float, v: float, scale: float) -> float:
	var p := Vector2(u, v) * scale
	var i := Vector2i(floori(p.x), floori(p.y))
	var f := p - Vector2(i)
	f = f * f * (Vector2(3, 3) - 2.0 * f)
	var h := func(q: Vector2i) -> float: return RealmKit.jitter(q, 77)
	return lerpf(lerpf(h.call(i), h.call(i + Vector2i(1, 0)), f.x),
		lerpf(h.call(i + Vector2i(0, 1)), h.call(i + Vector2i(1, 1)), f.x), f.y)


## The paint at (u, v) on a tile of level `lvl`: the colour, and the
## shader's channels (path, lush, cliff, stone).
func paint(u: float, v: float, lvl: int, on_wet: bool) -> Array:
	var grass: Color = palette["grass"]
	var soil: Color = palette["soil"]
	var dirt := earth(palette)
	var n1 := noise(u, v, 0.55)
	var n2 := noise(u + 17.0, v - 9.0, 1.7)
	var w := world(u, v, 0.0)
	var c := meadow(w.x, w.z)
	# Lush ground (moss, tall grass, thickets) is deeper and cooler.
	var lush := field("lush", u, v)
	c = c.lerp(grass.darkened(0.2).lerp(Color("#3E8A5A"), 0.15), clampf(lush * 1.2, 0.0, 1.0) * 0.8)
	var bloom := field("bloom", u, v)
	c = c.lerp(grass.lightened(0.12).lerp(palette["accent"], 0.12), bloom * 0.6)
	# Worn earth where a building stands, fading into the grass.
	var apron := smoothstep(0.25, 0.7, field("apron", u, v) + (n2 - 0.5) * 0.35)
	c = c.lerp(dirt.lerp(soil, 0.25), apron * 0.85)
	var stone := smoothstep(0.3, 0.7, field("stone", u, v) + (n1 - 0.5) * 0.3)
	c = c.lerp(palette["rock"].lightened(0.25), stone * 0.6)
	var scorch := smoothstep(0.2, 0.7, field("scorch", u, v) + (n2 - 0.5) * 0.3)
	c = c.lerp(palette["rock"].darkened(0.35), scorch * 0.75)
	var shade := field("shade", u, v)
	c = c.darkened(0.1 * shade)
	# A soft contact shade round whatever stands up from the ground.
	var occ := field("occ", u, v)
	c = c.darkened(0.09 * smoothstep(0.1, 0.6, occ) * (1.0 - apron))
	# A sandy bank where the grass meets water.
	var bank := smoothstep(0.25, 0.5, field("wet", u, v) + (n1 - 0.5) * 0.2)
	c = c.lerp(c.lerp(dirt, 0.5).darkened(0.05), bank * 0.5)
	if on_wet:
		c = dirt.lerp(soil, 0.45).darkened(0.1)
	# Higher ground catches a little more light.
	c = c.lightened(0.07 * lvl)
	# A worn trail between doors: trodden earth through the grass.
	var trail := trail_at(u, v)
	# (The shader draws the trail itself, crisp; the vertices only wear the
	# grass round it a little.)
	c = c.lerp(c.darkened(0.08).lerp(soil, 0.1), smoothstep(0.0, 0.6, trail))
	var path := path_at(u, v)
	# Worn earth round a path, before its cobbles start.
	c = c.lerp(dirt.lerp(soil, 0.3), smoothstep(0.25, 0.5, path) * 0.5)
	return [c, Vector4(path, lush, 0.0, stone)]


## The island meadow's colour beside the grid: T2's `IslandBuilder.meadow`
## turns to the palette's `grass` over its GRID_BLEND metres next to the grid
## (and lays the same brush), so the grid paints that `grass`. The meadow's
## own noise fields are kept for a pass that wants them (`far`).
func meadow(x: float, z: float, far := false) -> Color:
	var grass: Color = palette["grass"]
	if not far:
		return grass
	var gc := IslandBuilder.hsl(grass, 0.0, -0.08, -0.03)
	if island == null:
		return gc
	var lt := IslandBuilder.hsl(gc, 0.015, 0.02, 0.06)
	var dk := IslandBuilder.hsl(gc, -0.01, 0.02, -0.1)
	var nn := island.n2(x * 0.42 + 3.0, z * 0.42 - 2.0)
	var c := gc.lerp(lt if nn > 0.55 else dk, minf(1.0, absf(nn - 0.55) * 1.8))
	var wn := island.n2(x * 0.22 + 9.0, z * 0.22 - 4.0)
	if wn > 0.62:
		c = c.lerp(palette["accent"], minf(0.22, (wn - 0.62) * 0.9))
	if wn < 0.36:
		c = IslandBuilder.hsl(c, 0.02, 0.06, 0.02)
	return c


## How near (u, v) is to a worn trail: 1 on its line, 0 a third of a tile out.
func trail_at(u: float, v: float) -> float:
	var best := 9.0
	var p := Vector2(u, v)
	for seg: Array in trails:
		best = minf(best, _segment(p, seg[0], seg[1]))
	return clampf(1.0 - best / 0.6, 0.0, 1.0)


## Tile `t`'s flat top, SUB × SUB quads, its edge rounded where it falls away.
func _top(t: Vector2i) -> void:
	var y := top_y(t)
	var lvl := levels[index(t)]
	var on_wet := is_wet(t)
	var pts: Array[Vector3] = []
	var nrm: Array[Vector3] = []
	var cols: Array[Color] = []
	var chans: Array[Vector4] = []
	for j in SUB + 1:
		for i in SUB + 1:
			var u := t.x + float(i) / SUB
			var v := t.y + float(j) / SUB
			# Where this point sits on a side that falls away, round it over.
			var out := Vector3.ZERO
			if i == 0 and top_y(t + Vector2i(-1, 0)) < y - 0.01:
				out.x -= 1.0
			if i == SUB and top_y(t + Vector2i(1, 0)) < y - 0.01:
				out.x += 1.0
			if j == 0 and top_y(t + Vector2i(0, -1)) < y - 0.01:
				out.z -= 1.0
			if j == SUB and top_y(t + Vector2i(0, 1)) < y - 0.01:
				out.z += 1.0
			var drop := 0.06 if out != Vector3.ZERO else 0.0
			pts.append(world(u, v, y - drop))
			nrm.append((Vector3.UP + out * 0.5).normalized())
			var p := paint(u, v, lvl, on_wet)
			var col: Color = p[0]
			cols.append(col.darkened(0.06) if drop > 0.0 else col)
			chans.append(p[1])
	for j in SUB:
		for i in SUB:
			var a := j * (SUB + 1) + i
			var b := a + 1
			var c := a + SUB + 2
			var d := a + SUB + 1
			terrain.tri_painted([pts[a], pts[c], pts[b]], [nrm[a], nrm[c], nrm[b]], [cols[a], cols[c], cols[b]],
				[chans[a], chans[c], chans[b]])
			terrain.tri_painted([pts[a], pts[d], pts[c]], [nrm[a], nrm[d], nrm[c]], [cols[a], cols[d], cols[c]],
				[chans[a], chans[d], chans[c]])


## The side of tile `t` toward `d`: a soft earthy cliff down to the lower
## neighbour, a bank down into water, or the grass running out onto the
## island past the grid's edge.
func _side(t: Vector2i, d: Vector2i) -> void:
	var n := t + d
	var y0 := top_y(t) - 0.06
	var y1 := top_y(n)
	var edge_out := not inside(n)
	if y1 >= y0 + 0.05 and not edge_out:
		return
	var out := Vector3(d.x, 0, d.y)
	# The side's two ends along the tile edge, in tile space.
	var along := Vector2(-d.y, d.x)
	var mid := Vector2(t) + Vector2(0.5, 0.5) + Vector2(d) * 0.5
	var bank := is_wet(n) and not is_wet(t)
	var soil: Color = palette["soil"]
	var rock: Color = palette["rock"]
	var grass: Color = palette["grass"]
	var dirt := earth(palette)
	if y1 < y0 - 0.02:
		var rows := [0.0, 0.18, 0.55, 1.0]
		var bulge := [0.0, 0.05, 0.035, 0.0]
		var tint := [grass.darkened(0.2), soil.lightened(0.05), soil.darkened(0.12), rock.lerp(soil, 0.4).darkened(0.25)]
		if bank:
			tint = [dirt.lightened(0.05), dirt.darkened(0.08), soil.lightened(0.05), soil.darkened(0.15)]
		var grid: Array = []
		for r in rows.size():
			var line: Array[Vector3] = []
			for k in SUB + 1:
				var s := float(k) / SUB - 0.5
				var p2 := mid + along * s
				var taper := 1.0 - pow(absf(s) * 2.0, 4.0)
				var jit := (RealmKit.jitter(Vector2i(int(p2.x * 8.0), int(p2.y * 8.0)), r) - 0.5) * 0.05
				var push: float = (bulge[r] + (jit if r in [1, 2] else 0.0)) * taper
				var y := lerpf(y0, y1, rows[r])
				line.append(world(p2.x, p2.y, y) + out * push)
			grid.append(line)
		for r in rows.size() - 1:
			for k in SUB:
				var a: Vector3 = grid[r][k]
				var b: Vector3 = grid[r][k + 1]
				var c: Vector3 = grid[r + 1][k + 1]
				var e: Vector3 = grid[r + 1][k]
				var na := (out + Vector3.UP * (0.5 if r == 0 else 0.05)).normalized()
				var ca: Color = tint[r]
				var cb: Color = tint[r + 1]
				var shade := 0.04 * RealmKit.jitter(Vector2i(t.x * 7 + k, t.y * 5 + r), 3)
				ca = ca.darkened(shade)
				cb = cb.darkened(shade)
				var ch := Vector4(0, 0, 0.0 if r == 0 else 1.0, 0)
				var ch2 := Vector4(0, 0, 1.0, 0)
				_wall_quad(a, b, c, e, na, ca, cb, ch, ch2, out)
		if not bank and inside(n):
			# Stones fallen to the cliff's foot, and grass hanging over its lip.
			for k in 2:
				var s2 := (RealmKit.jitter(t + d * 7, k) - 0.5) * 0.8
				var foot := mid + along * s2 + Vector2(d) * 0.1
				scatter.rock(Geo.place(world(foot.x, foot.y, y1 + 0.03), s2 * 5.0, Vector3(1, 0.65, 1)),
					0.06 + 0.04 * RealmKit.jitter(t, k + 9), rock.lerp(soil, 0.3), t.x * 5 + k)
			var lip := mid + along * (RealmKit.jitter(t, 33) - 0.5) * 0.6
			scatter.moving(Geo.Anim.SHIVER, world(lip.x, lip.y, y0 + 0.06))
			for b in 3:
				scatter.blade(world(lip.x, lip.y, y0 + 0.05) + out * 0.02 + Vector3(along.x, 0, along.y) * (b - 1) * 0.05,
					0.14, 0.025, grass.darkened(0.15), 2.2, atan2(out.z, out.x))
			scatter.moving(Geo.Anim.NONE, Vector3.ZERO)
	if edge_out:
		_skirt(t, d, minf(y1, y0 + 0.06))


func _wall_quad(a: Vector3, b: Vector3, c: Vector3, e: Vector3, n: Vector3, top: Color, low: Color,
		ch_top: Vector4, ch_low: Vector4, out: Vector3) -> void:
	var face := (b - a).cross(e - a)
	if face.dot(out) > 0:
		terrain.tri_painted([a, b, c], [n, n, n], [top, top, low], [ch_top, ch_top, ch_low])
		terrain.tri_painted([a, c, e], [n, n, n], [top, low, low], [ch_top, ch_low, ch_low])
	else:
		terrain.tri_painted([a, c, b], [n, n, n], [top, low, top], [ch_top, ch_low, ch_top])
		terrain.tri_painted([a, e, c], [n, n, n], [top, low, low], [ch_top, ch_low, ch_low])


## Grass running from the grid's edge out over the island's top, so the
## realm's ground and the island's meet with no seam.
func _skirt(t: Vector2i, d: Vector2i, y: float) -> void:
	var along := Vector2(-d.y, d.x)
	var mid := Vector2(t) + Vector2(0.5, 0.5) + Vector2(d) * 0.5
	var grass: Color = palette["grass"]
	var reach := 0.45
	for k in SUB:
		var s0 := float(k) / SUB - 0.5
		var s1 := float(k + 1) / SUB - 0.5
		var p0 := mid + along * s0
		var p1 := mid + along * s1
		var q0 := p0 + Vector2(d) * reach + along * (s0 * 0.0)
		var q1 := p1 + Vector2(d) * reach
		var a := world(p0.x, p0.y, y)
		var b := world(p1.x, p1.y, y)
		var c := world(q1.x, q1.y, ISLAND_Y - 0.01)
		var e := world(q0.x, q0.y, ISLAND_Y - 0.01)
		var ca: Color = paint(p0.x, p0.y, 0, false)[0]
		var cb: Color = paint(p1.x, p1.y, 0, false)[0]
		var far := world(q0.x, q0.y, 0.0)
		grass = meadow(far.x, far.z)
		var up := Vector3.UP
		var z := Vector4.ZERO
		var face := (b - a).cross(e - a)
		if face.y > 0:
			terrain.tri_painted([a, b, c], [up, up, up], [ca, cb, grass], [z, z, z])
			terrain.tri_painted([a, c, e], [up, up, up], [ca, grass, grass], [z, z, z])
		else:
			terrain.tri_painted([a, c, b], [up, up, up], [ca, grass, cb], [z, z, z])
			terrain.tri_painted([a, e, c], [up, up, up], [ca, grass, grass], [z, z, z])


## The water on a wet tile: its surface below the banks, each point carrying
## its distance from the shore (UV.x) for the shader's foam and ripples, and
## its colour (stream, marsh, spring) in COLOR.
func _water(t: Vector2i, tint := Color.WHITE) -> void:
	var y := levels[index(t)] * IslandBuilder.LEVEL - WATER_DROP
	# Which sides meet the shore: west 1, east 2, north 4, south 8.
	var mask := 0
	var bit := 1
	for d: Vector2i in [Vector2i(-1, 0), Vector2i(1, 0), Vector2i(0, -1), Vector2i(0, 1)]:
		var nb := t + d
		if not is_wet(nb) or levels[index(nb)] != levels[index(t)]:
			mask |= bit
		bit *= 2
	var pts: Array[Vector3] = []
	var chans: Array[Vector4] = []
	for j in SUB + 1:
		for i in SUB + 1:
			var fu := float(i) / SUB
			var fv := float(j) / SUB
			pts.append(world(t.x + fu, t.y + fv, y))
			chans.append(Vector4(1.0, float(mask), fu, fv))
	var up := Vector3.UP
	for j in SUB:
		for i in SUB:
			var a := j * (SUB + 1) + i
			var b := a + 1
			var c := a + SUB + 2
			var d := a + SUB + 1
			water.tri_painted([pts[a], pts[c], pts[b]], [up, up, up], [tint, tint, tint], [chans[a], chans[c], chans[b]])
			water.tri_painted([pts[a], pts[d], pts[c]], [up, up, up], [tint, tint, tint], [chans[a], chans[d], chans[c]])


## Lily pads on a water tile, one in flower (§21.4: Tidehold's "reeds,
## lilies"), floating with the swell.
func _lilies(t: Vector2i) -> void:
	var y := levels[index(t)] * IslandBuilder.LEVEL - WATER_DROP + 0.006
	for k in 3:
		var p := world(t.x + 0.25 + 0.5 * RealmKit.jitter(t, 11 + k), t.y + 0.25 + 0.5 * RealmKit.jitter(t, 21 + k), y)
		scatter.moving(Geo.Anim.BOB, p)
		var a := RealmKit.jitter(t, 31 + k) * TAU
		for s in 7:
			var a0 := a + 0.5 + TAU * s / 8.0
			var a1 := a + 0.5 + TAU * (s + 1) / 8.0
			var r := 0.09 - 0.015 * k
			scatter.tri(p, p + Vector3(cos(a1), 0, sin(a1)) * r, p + Vector3(cos(a0), 0, sin(a0)) * r, Color("#3F9A4A"))
		if k == 0:
			scatter.ball(Geo.place(p + Vector3(0, 0.02, 0)), 0.03, Color("#F7A6DA"), 2, 5)
		scatter.moving(Geo.Anim.NONE, Vector3.ZERO)


## A couple of grass tufts on an open tile, which shiver in the wind: the
## ground's texture made solid (§21.10: ambient, never told apart).
func _tufts(t: Vector2i) -> void:
	var y := top_y(t)
	scatter.standing(y)
	var grass: Color = palette["grass"]
	var plant: Color = palette["plant"]
	var near_water := field("wet", t.x + 0.5, t.y + 0.5) > 0.12
	for k in 2:
		if RealmKit.jitter(t, 40 + k) < 0.25:
			continue
		var u := t.x + 0.15 + 0.7 * RealmKit.jitter(t, 50 + k)
		var v := t.y + 0.15 + 0.7 * RealmKit.jitter(t, 60 + k)
		var base := world(u, v, y)
		var odd := RealmKit.jitter(t, 90 + k) < 0.3
		scatter.moving(Geo.Anim.SHIVER, base)
		if odd and realm == "lanternvale":
			# A glowing mushroom (§21.4: "glowing mushrooms").
			scatter.cyl(Geo.place(base), 0.018, 0.014, 0.07, Color("#E8E0F0"), 5)
			scatter.ball(Geo.place(base + Vector3(0, 0.075, 0), 0.0, Vector3(1, 0.55, 1)), 0.045,
				Color(Color("#7AD8C8"), 0.25), 2, 6, true)
		elif odd and realm == "skyfield":
			# A dandelion puff.
			scatter.blade(base, 0.2, 0.01, plant.darkened(0.3))
			scatter.ball(Geo.place(base + Vector3(0, 0.21, 0)), 0.04, Color("#FFFDF4"), 2, 6)
		elif near_water and realm in ["tidehold", "verdant", "heart"]:
			# Reeds by the water, a bulrush or two.
			for b in 4:
				var a := TAU * b / 4.0 + RealmKit.jitter(t, 70 + k)
				var p := base + Vector3(cos(a), 0, sin(a)) * 0.04
				scatter.blade(p, 0.3 + 0.1 * RealmKit.jitter(t, 80 + b), 0.018, Color("#6A8A3A").lerp(plant, 0.3), 0.15, a)
			scatter.cyl(Geo.place(base + Vector3(0, 0.22, 0)), 0.018, 0.018, 0.07, Color("#7A4A2A"), 5)
		else:
			for b in 3:
				var a := TAU * (b / 3.0 + RealmKit.jitter(t, 70 + k))
				var col := grass.darkened(0.12).lerp(plant, 0.35).lightened(0.06 * b)
				scatter.blade(base + Vector3(cos(a), 0, sin(a)) * 0.03, 0.16 + 0.08 * RealmKit.jitter(t, 80 + k * 3 + b),
					0.03, col, 0.35, a)
		scatter.moving(Geo.Anim.NONE, Vector3.ZERO)
