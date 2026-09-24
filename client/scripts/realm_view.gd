class_name RealmView
extends Control
## One realm, drawn from the simulation's own state after each tick.
##
## Top-down and flat for now: §21.1's diorama camera is the art pass, and this
## is the proof that what the phone draws is what the server validates. Shapes
## follow §21.12 — sharp edges, a tile inside or outside, one guard's vision at
## a time — and every colour comes from Palette.

## Tile codes from RulebornReplay.features(): 0 is open ground, then 1 + the
## index in sim/src/grid.rs's Feature.
enum Tile { OPEN, ROCK_PILLAR, RUIN_WALL, FENCE, FOG_BANK, TALL_GRASS, VAULT, PYLON, CRYSTAL_WALL }

var replay: RulebornReplay
## §21.12: "The selected guard's vision is drawn; the others show only their
## facing." -1 is the first guard still on its feet.
var selected_guard := -1

var _size := Vector2i.ZERO
var _features := PackedByteArray()
var _heights := PackedByteArray()
var _surfaces := PackedByteArray()


func show_replay(r: RulebornReplay) -> void:
	replay = r
	_size = r.size()
	_features = r.features()
	_heights = r.heights()
	_surfaces = r.surfaces()
	queue_redraw()


## Pixels a tile, and where the realm's top-left corner sits, fitted to this
## control's rect with a tile of rim on every side.
func layout() -> Array:
	if _size.x == 0:
		return [0.0, Vector2.ZERO]
	var tile: float = min(size.x / (_size.x + 1), size.y / (_size.y + 1))
	var origin := (size - Vector2(_size) * tile) / 2.0
	return [tile, origin]


func to_screen(at_tiles: Vector2) -> Vector2:
	var l := layout()
	return l[1] + at_tiles * l[0]


func _draw() -> void:
	if replay == null or _size.x == 0:
		return
	var l := layout()
	var t: float = l[0]
	var o: Vector2 = l[1]
	# The island, with soil beneath its edge.
	var island := Rect2(o, Vector2(_size) * t)
	draw_rect(island.grow(t * 0.35), Palette.SOIL)
	draw_rect(island, Palette.STONE)
	for y in _size.y:
		for x in _size.x:
			var i := y * _size.x + x
			var r := Rect2(o + Vector2(x, y) * t, Vector2(t, t))
			var h := _heights[i] if i < _heights.size() else 0
			if h > 0:
				draw_rect(r, Palette.STONE.darkened(0.08 * h))
			match _surfaces[i] if i < _surfaces.size() else 0:
				1:
					draw_rect(r.grow(-t * 0.04), Palette.GRAVEL)
				2:
					draw_rect(r, Palette.WATER)
			_draw_feature(_features[i], r, t)
	_draw_vault(t)
	for ward in replay.wards():
		_draw_ward(ward, t)
	var guards := replay.guards()
	var shown := selected_guard
	if shown < 0 or shown >= guards.size() or guards[shown]["down"]:
		shown = -1
		for gi in guards.size():
			if not guards[gi]["down"]:
				shown = gi
				break
	for gi in guards.size():
		_draw_guard(guards[gi], gi == shown, gi, t)
	for member in replay.crew():
		_draw_member(member, t)


func _draw_feature(code: int, r: Rect2, t: float) -> void:
	match code:
		Tile.ROCK_PILLAR:
			draw_rect(r.grow(-t * 0.08), Palette.SOIL.darkened(0.25))
		Tile.RUIN_WALL:
			draw_rect(r.grow(-t * 0.12), Palette.SOIL)
		Tile.FENCE:
			draw_line(r.position + Vector2(0, t * 0.5), r.end - Vector2(0, t * 0.5), Palette.WOOD, t * 0.12)
		Tile.FOG_BANK:
			draw_rect(r, Color(Palette.PAPER, 0.7))
		Tile.TALL_GRASS:
			draw_rect(r, Palette.LIFE.lightened(0.25))
			for k in 3:
				var base := r.position + Vector2(t * (0.25 + 0.25 * k), t * 0.85)
				draw_line(base, base + Vector2(0, -t * 0.45), Palette.LIFE.darkened(0.3), t * 0.06)
		Tile.PYLON:
			var c := r.get_center()
			var d := t * 0.35
			draw_colored_polygon(PackedVector2Array([c + Vector2(0, -d), c + Vector2(d, 0), c + Vector2(0, d), c + Vector2(-d, 0)]), Palette.MATTER)
		Tile.CRYSTAL_WALL:
			draw_rect(r.grow(-t * 0.1), Palette.TIME)


## A ward as a ring in its school's colour; hollow once disarmed or broken.
func _draw_ward(w: Dictionary, t: float) -> void:
	var c := to_screen(w["at"])
	var colour: Color = Palette.WARD.get(w["kind"], Palette.INK)
	var d := t * 0.28
	var diamond := PackedVector2Array([c + Vector2(0, -d), c + Vector2(d, 0), c + Vector2(0, d), c + Vector2(-d, 0), c + Vector2(0, -d)])
	if w["live"]:
		draw_colored_polygon(diamond.slice(0, 4), Color(colour, 0.85))
	draw_polyline(diamond, Palette.INK, max(1.5, t * 0.05))


func _draw_vault(t: float) -> void:
	var v := replay.vault()
	var c := to_screen(v["at"])
	var half := Vector2(t, t) * 0.45
	var fill := Palette.MOTION if not v["open"] else Palette.MOTION.lightened(0.4)
	draw_rect(Rect2(c - half, half * 2), fill)
	draw_rect(Rect2(c - half, half * 2), Palette.INK, false, max(1.5, t * 0.05))


func _draw_guard(g: Dictionary, selected: bool, index: int, t: float) -> void:
	var c := to_screen(g["at"])
	var facing: float = g["facing"]
	if selected:
		# The cone, sharp-edged (§21.12). Occlusion is the simulation's to
		# decide; RulebornReplay.seen() names the tiles it reaches.
		var origin: Vector2 = layout()[1]
		for tile in replay.seen(index):
			var p := Vector2(tile % _size.x, tile / _size.x)
			draw_rect(Rect2(origin + p * t, Vector2(t, t)), Color(Palette.ALARM, 0.22))
	var ring: Color = Palette.GUARD_STATE.get(g["state"], Palette.INK)
	var radius := t * 0.34
	draw_circle(c, radius, Palette.INK if not g["down"] else Palette.INK.lightened(0.5))
	draw_arc(c, radius, 0, TAU, 24, ring, max(2.0, t * 0.08))
	draw_line(c, c + Vector2(cos(facing), sin(facing)) * t * 0.6, Palette.PAPER, max(2.0, t * 0.07))


func _draw_member(m: Dictionary, t: float) -> void:
	if m["standing"] == "Out":
		return
	var c := to_screen(m["at"])
	var colour: Color = Palette.ROLE.get(m["role"], Palette.PAPER)
	if m["standing"] != "Active":
		colour = colour.darkened(0.5)
	var radius := t * 0.3
	draw_circle(c, radius, colour)
	draw_arc(c, radius, 0, TAU, 20, Palette.INK, max(1.5, t * 0.05))
	# What it carries, as a filled arc against its bag (§12.19).
	var share: float = float(m["carried"]) / max(1, m["carry"])
	if share > 0.0:
		draw_arc(c, radius * 1.35, -PI / 2, -PI / 2 + TAU * share, 20, Palette.MOTION, max(2.0, t * 0.08))


## The guard nearest a point on screen becomes the one whose cone is drawn.
func select_guard_near(at: Vector2) -> void:
	var guards := replay.guards()
	var best := -1
	var best_d := INF
	for gi in guards.size():
		var d := to_screen(guards[gi]["at"]).distance_to(at)
		if d < best_d:
			best_d = d
			best = gi
	selected_guard = best
	queue_redraw()


## The tile under a point on screen, or (-1, -1) off the realm.
func tile_at(at: Vector2) -> Vector2i:
	var l := layout()
	if l[0] <= 0.0:
		return Vector2i(-1, -1)
	var p: Vector2 = (at - l[1]) / l[0]
	var t := Vector2i(floori(p.x), floori(p.y))
	if t.x < 0 or t.y < 0 or t.x >= _size.x or t.y >= _size.y:
		return Vector2i(-1, -1)
	return t
