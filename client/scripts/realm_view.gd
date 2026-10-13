class_name RealmView
extends Control
## One realm, drawn from the simulation's own state after each tick.
##
## Top-down and flat for now: §21.1's diorama camera is the art pass, and this
## is the proof that what the phone draws is what the server validates. Shapes
## follow §21.12 — sharp edges, a tile inside or outside, one guard's vision at
## a time — and every colour comes from Palette.
##
## §20.8: no information is carried by colour alone. A ward is drawn as its
## school's shape (§21.2), a guard's state has a mark over it, a crew member
## has its role's letters on it, and every feature that changes a route is
## edged in ink, so the realm still reads in grayscale (§21.10). A screen
## reader is told the realm in words (`describe`).

## Tile codes from RulebornReplay.features(): 0 is open ground, then 1 + the
## index in sim/src/grid.rs's Feature.
enum Tile { OPEN, ROCK_PILLAR, RUIN_WALL, FENCE, FOG_BANK, TALL_GRASS, VAULT, PYLON, CRYSTAL_WALL }

## §21.10's hero features: the ones that change a route, and so must be told
## apart from the ground by value, not hue.
const HERO := [Tile.ROCK_PILLAR, Tile.RUIN_WALL, Tile.FENCE, Tile.FOG_BANK, Tile.TALL_GRASS, Tile.PYLON,
		Tile.CRYSTAL_WALL]

## A guard's state as a mark over it, so the ring's colour is never the only
## sign (§12.17's states; §20.8).
const GUARD_MARK := {"Unaware": "", "Returning": "", "Suspicious": "?", "Investigating": "??",
		"Searching": "???", "Alerted": "!"}

var replay: RulebornReplay
## §21.12: "The selected guard's vision is drawn; the others show only their
## facing." -1 is the first guard still on its feet.
var selected_guard := -1

var _size := Vector2i.ZERO
var _features := PackedByteArray()
var _heights := PackedByteArray()
var _surfaces := PackedByteArray()
## Each tile's facing (0 north to 3 west, 255 for none) and the tunnels'
## mouths in pairs: the ground that has a direction (G56).
var _facings := PackedByteArray()
var _tunnels: Array[Vector2i] = []


func show_replay(r: RulebornReplay) -> void:
	replay = r
	_size = r.size()
	_features = r.features()
	_heights = r.heights()
	_surfaces = r.surfaces()
	_facings = r.facings()
	_tunnels = r.tunnels()
	describe()
	queue_redraw()


## The realm in words, for a screen reader (§20.8: "the universe map can be
## read realm by realm"): its size, the Vault, the guards on their feet and
## the wards still standing.
func describe() -> void:
	if replay == null or _size.x == 0:
		return
	var up := 0
	for g in replay.guards():
		if not g["down"]:
			up += 1
	var live := 0
	for w in replay.wards():
		if w["live"]:
			live += 1
	accessibility_name = Strings.t("REALM_DESCRIBED", [_size.x, _size.y,
		Strings.t("REALM_VAULT_OPEN" if replay.vault()["open"] else "REALM_VAULT_SHUT"), up, live])


## The colour of the mark that sets a hero feature apart from the ground.
static func edge_colour(_tile: int) -> Color:
	return Palette.INK


## Every ground a figure can stand on, as `_draw` paints it: stone at each
## height, gravel and water.
static func grounds() -> Dictionary:
	var out := {"stone": Palette.STONE, "gravel": Palette.GRAVEL, "water": Palette.WATER}
	for h in range(1, 4):
		out["stone %d up" % h] = Palette.STONE.darkened(0.08 * h)
	return out


## What sets each figure apart from the ground, as `_draw` paints it: a
## guard's body, the outlines of wards, the Vault and the crew, water's
## ripples. §21.10 asks each to hold by value.
static func figures() -> Dictionary:
	return {"guard": Palette.INK, "ward outline": Palette.INK, "vault outline": Palette.INK,
		"crew outline": Palette.INK, "water ripple": ColourCheck.over(Color(Palette.INK, 0.55), Palette.WATER)}


## A mark's words on the realm: a guard's state, a crew member's letters. Ink,
## or the alarm's deeper red for Alerted, on a paper halo.
static func mark_colour(state := "") -> Color:
	return Palette.ALARM_TEXT if state == "Alerted" else Palette.INK


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
					# Ripples in ink: water reads as water in grayscale.
					for k in 2:
						var y0 := r.position.y + t * (0.35 + 0.3 * k)
						draw_line(Vector2(r.position.x + t * 0.2, y0), Vector2(r.end.x - t * 0.2, y0),
							figures()["water ripple"], max(1.0, t * 0.04))
			_draw_feature(_features[i], r, t)
			if _features[i] in HERO:
				draw_rect(r.grow(-t * 0.06), edge_colour(_features[i]), false, max(1.0, t * 0.04))
			if i < _facings.size() and _facings[i] < 4:
				_draw_facing(_facings[i], r, t)
	_draw_tunnels(t, o)
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
	# Before it lands the crew is nowhere a raider would meet it (§5.4).
	if replay.has_landed():
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
			draw_colored_polygon(PackedVector2Array([c + Vector2(0, -d), c + Vector2(d, 0), c + Vector2(0, d),
					c + Vector2(-d, 0)]), Palette.MATTER)
		Tile.CRYSTAL_WALL:
			draw_rect(r.grow(-t * 0.1), Palette.TIME)


## The way a ramp, stairs, vines, a waterfall or rapids face (G56), as an
## ink chevron pointing that way: a shape, never a colour alone (§20.8).
func _draw_facing(facing: int, r: Rect2, t: float) -> void:
	var c := r.get_center()
	var ahead := [Vector2.UP, Vector2.RIGHT, Vector2.DOWN, Vector2.LEFT][facing] as Vector2
	var side := Vector2(-ahead.y, ahead.x)
	var tip := c + ahead * t * 0.3
	var back := c - ahead * t * 0.05
	draw_polyline(PackedVector2Array([back + side * t * 0.25, tip, back - side * t * 0.25]),
		Palette.INK, max(1.5, t * 0.06))


## A tunnel's two mouths as ink rings, joined by a dashed line: "a hidden
## path", so the owner sees it and a raider's map shows where it runs.
func _draw_tunnels(t: float, o: Vector2) -> void:
	for k in range(0, _tunnels.size() - 1, 2):
		var a := o + (Vector2(_tunnels[k]) + Vector2(0.5, 0.5)) * t
		var b := o + (Vector2(_tunnels[k + 1]) + Vector2(0.5, 0.5)) * t
		draw_dashed_line(a, b, Palette.INK, max(1.0, t * 0.04), t * 0.2)
		for m: Vector2 in [a, b]:
			draw_circle(m, t * 0.3, Palette.SOIL.darkened(0.4))
			draw_arc(m, t * 0.3, 0, TAU, 24, Palette.INK, max(1.0, t * 0.05))


## A ward as its school's shape in its school's colour; hollow once disarmed
## or broken.
func _draw_ward(w: Dictionary, t: float) -> void:
	var c := to_screen(w["at"])
	var colour: Color = Palette.WARD.get(w["kind"], Palette.INK)
	var outline := shape_points(Tokens.shape(str(Palette.WARD_SCHOOL.get(w["kind"], "motion"))), c, t * 0.3)
	if w["live"]:
		draw_colored_polygon(outline, Color(colour, 0.85))
	var closed := outline.duplicate()
	closed.append(outline[0])
	draw_polyline(closed, figures()["ward outline"], max(1.5, t * 0.05))


## §21.2's school shapes, as a polygon of radius `d` around `c`.
static func shape_points(shape: String, c: Vector2, d: float) -> PackedVector2Array:
	var p := PackedVector2Array()
	match shape:
		"chevron":
			for v: Vector2 in [Vector2(-1, 0.6), Vector2(0, -0.7), Vector2(1, 0.6), Vector2(0.6, 0.9), Vector2(0, -0.1),
					Vector2(-0.6, 0.9)]:
				p.append(c + v * d)
		"cube":
			for v: Vector2 in [Vector2(-0.8, -0.8), Vector2(0.8, -0.8), Vector2(0.8, 0.8), Vector2(-0.8, 0.8)]:
				p.append(c + v * d)
		"hourglass":
			for v: Vector2 in [Vector2(-0.8, -1), Vector2(0.8, -1), Vector2(0.1, 0), Vector2(0.8, 1), Vector2(-0.8, 1),
					Vector2(-0.1, 0)]:
				p.append(c + v * d)
		"bolt":
			for v: Vector2 in [Vector2(0.2, -1), Vector2(0.7, -1), Vector2(0.2, -0.1), Vector2(0.7, -0.1),
					Vector2(-0.3, 1), Vector2(-0.1, 0.15), Vector2(-0.6, 0.15)]:
				p.append(c + v * d)
		"leaf":
			for k in 12:
				var a := TAU * k / 12.0
				p.append(c + Vector2(cos(a) * 0.55, sin(a)).rotated(PI / 4) * d)
		"eye":
			for k in 12:
				var a := TAU * k / 12.0
				p.append(c + Vector2(cos(a), sin(a) * 0.5) * d)
		_:
			for v: Vector2 in [Vector2(0, -1), Vector2(1, 0), Vector2(0, 1), Vector2(-1, 0)]:
				p.append(c + v * d)
	return p


func _draw_vault(t: float) -> void:
	var v := replay.vault()
	var c := to_screen(v["at"])
	var half := Vector2(t, t) * 0.45
	var fill := Palette.MOTION if not v["open"] else Palette.MOTION.lightened(0.4)
	draw_rect(Rect2(c - half, half * 2), fill)
	draw_rect(Rect2(c - half, half * 2), figures()["vault outline"], false, max(1.5, t * 0.05))


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
	draw_circle(c, radius, figures()["guard"] if not g["down"] else Palette.INK.lightened(0.5))
	draw_arc(c, radius, 0, TAU, 24, ring, max(2.0, t * 0.08))
	draw_line(c, c + Vector2(cos(facing), sin(facing)) * t * 0.6, Palette.PAPER, max(2.0, t * 0.07))
	var mark: String = GUARD_MARK.get(g["state"], "")
	if mark != "" and not g["down"]:
		_draw_text(mark, c + Vector2(0, -t * 0.55), t * 0.45, mark_colour(g["state"]))


func _draw_member(m: Dictionary, t: float) -> void:
	if m["standing"] == "Out":
		return
	var c := to_screen(m["at"])
	var colour: Color = Palette.ROLE.get(m["role"], Palette.PAPER)
	if m["standing"] != "Active":
		colour = colour.darkened(0.5)
	var radius := t * 0.3
	draw_circle(c, radius, colour)
	draw_arc(c, radius, 0, TAU, 20, figures()["crew outline"], max(1.5, t * 0.05))
	_draw_text(Strings.term("ROLE", m["role"]).substr(0, 2), c + Vector2(0, radius * 0.35), t * 0.3, mark_colour())
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


## Words centred on `at`, with a paper halo, so they read on any ground: the
## words are checked against the halo (tests/a11y_tests.gd).
func _draw_text(text: String, at: Vector2, height: float, colour: Color) -> void:
	var font := ThemeDB.fallback_font
	var fs := maxi(8, int(height))
	var w := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
	var pos := at - Vector2(w / 2.0, 0)
	draw_string_outline(font, pos, text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, maxi(2, fs / 5), Palette.PAPER)
	draw_string(font, pos, text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, colour)
