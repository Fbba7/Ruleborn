class_name OverlayDefence
extends RefCounted
## The defence overlay on a realm (the diorama's `buildDefend`/`dUpdate`,
## realm-diorama.js ~:280–376), for curation and the defence screens: the
## grid of tiles a guard post may stand on, the picked post edged in gold
## with its sight drawn as the simulation decides it (§21.12: "the selected
## guard's vision is drawn", hard-edged), the tiles a move would take it to
## painted green where the island allows the move and red where it refuses,
## a ghost of the guard on the way it faces, and a pin over every post
## with its number in the list of posts below and over every ward with its
## school's shape (§20.8: by number and shape, never colour alone).

const WAYS := [Vector2i(0, -1), Vector2i(1, 0), Vector2i(0, 1), Vector2i(-1, 0)]

var view: StageView
var tiles: OverlayTiles


func _init(on: StageView) -> void:
	view = on
	tiles = OverlayTiles.new(on)


## Draws the overlay for `island` as `replay` reads it, `picked` the post
## chosen (or (-1, -1)); `moves` maps a tile to whether a move there is
## allowed. Returns the guard index of the picked post, or -1.
func draw(island: RulebornIsland, replay: RulebornReplay, picked: Vector2i, moves: Dictionary) -> int:
	var blocked := {}
	var side := island.side()
	for y in side:
		for x in side:
			if str(island.ground(x, y)) not in ["", "plain"] or str(island.occupant(x, y)) not in ["", "guard:0",
					"guard:1", "guard:2", "guard:3", "guard:4"]:
				blocked[Vector2i(x, y)] = true
	tiles.show_grid(blocked)
	var paint := {}
	for t: Vector2i in moves:
		paint[t] = OverlayTiles.OPEN if moves[t] else OverlayTiles.BAD
	tiles.paint(paint)
	var open: Array = moves.keys().filter(func(t: Vector2i) -> bool: return moves[t])
	tiles.arrows(picked, open if picked.x >= 0 else [])
	var index := guard_at(replay, picked)
	view.selected_guard = index
	tiles.cursor(picked, true)
	if index >= 0 and picked.x >= 0:
		var f := island.facing(picked.x, picked.y)
		var ahead: Vector2i = picked + WAYS[posmod(f, 4)]
		tiles.ghost(ActorBuilder.mesh("guard") if moves.get(ahead, false) else null, ahead, true,
			_yaw(f))
	else:
		tiles.ghost(null, Vector2i.ZERO)
	pin_all(view, island, replay, picked)
	view.describe()
	return index


## The guard standing on tile `t` at the heist's start, or -1.
static func guard_at(replay: RulebornReplay, t: Vector2i) -> int:
	if t.x < 0:
		return -1
	var guards := replay.guards()
	for i in guards.size():
		var at: Vector2 = guards[i]["at"]
		if Vector2i(floori(at.x), floori(at.y)) == t:
			return i
	return -1


## Each post's number (its place in the list of posts) over it, gold for
## the picked one, and each ward's school shape over it: on `on`'s pins.
static func pin_all(on: StageView, island: RulebornIsland, replay: RulebornReplay, picked: Vector2i) -> void:
	var pins := StageScreen.pins_of(on)
	pins.clear()
	var posts := CurationPresenter.posts(island)
	for i in posts.size():
		# The picked post on gold, the others on leather: told apart by the
		# gold edge and the ring under it, not the fill alone (§20.8).
		pins.pin(OverlayHud.badge(str(i + 1), "gold_round" if posts[i]["at"] == picked else "leather", 15.0),
			on.tile_point(posts[i]["at"], 1.45))
	for w: Dictionary in replay.wards():
		pins.pin(OverlayHud.tag(OverlayHud.ward_icon(str(w["kind"]).to_snake_case()), ""),
			on.world_at(w["at"]) + Vector3(0, 1.2, 0))


## The yaw that turns a model facing −Z to face way `f` (0 north to 3 west)
## on the grid, whose north is −Z.
static func _yaw(f: int) -> float:
	return -PI / 2.0 * posmod(f, 4)
