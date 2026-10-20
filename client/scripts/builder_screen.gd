class_name BuilderScreen
extends Control
## The island builder (§13): lay §6.2's ground on the realm's grid, post
## guards, place wards, weave laws with their pylons, move the Vault, and raid
## what was built. Every edit goes through `RulebornIsland`, which is the
## simulation's own island, so the builder never writes the bundle format and
## never judges an island itself: `problems()` is `Island::check`, the rules
## the server publishes by, and the Raid button waits until it is empty.
##
## The realm is drawn by the heist's own world (`StageView`, a `WorldView`),
## full-bleed under the controls, from a heist started on the island at tick
## 0, so what the builder shows is what a raider meets before it lands: no
## crew, which lands wherever the raider chooses (§5.4). Over it, the terrain
## overlay (`OverlayTiles`): the grid as plates, a ghost of what the tool
## would place under the finger — gold where the island takes it, red where
## it refuses — and the last tile tapped edged the same way, so what
## `RulebornIsland` allows and rejects shows on the tile. Ground and the
## eraser paint with a drag; every stroke can be undone.

enum Tool { GROUND, WARD, GUARD, LAW, VAULT, ERASE }

const TOOLS := ["GROUND", "WARD", "GUARD", "LAW", "VAULT", "ERASE"]
## §12.17's role rows, in order: a guard post is its row.
const GUARD_ROLES := ["Scout", "Warden", "Breaker", "Carrier", "Mender"]
## §6.2's tunnel: ground laid with two taps, one for each mouth.
const TUNNEL := "tunnel"
const NO_MOUTH := Vector2i(-1, -1)
## How many edits Undo remembers.
const UNDO_DEPTH := 40

var island := RulebornIsland.new()
var preview := RulebornReplay.new()
var palette: Dictionary = RulebornIsland.palette()
var tool := Tool.GROUND
## Which of the tool's kinds is chosen: an index into `kinds()`.
var kind := 0
## A tunnel's first mouth, tapped and waiting for the second.
var mouth := NO_MOUTH
## A word for the player about the last tap, shown once in the status line.
var hint := ""
## The island before each edit, newest last.
var undo_stack: Array[PackedByteArray] = []
## The tile last acted on and whether the island took the action.
var last_tile := NO_MOUTH
var last_ok := true
var tiles: OverlayTiles

var view: RealmView
var title_label: Label
var status_label: Label
var together_label: Label
var tool_button: Button
var kind_button: Button
var level_button: Button
var raid_button: Button
var restore_button: Button
var undo_button: Button
var _stroke := false
var _dock: Control
var _stroke_tile := NO_MOUTH


func _ready() -> void:
	App.ready(self)
	var kept := Draft.island()
	if not kept.is_empty():
		island.read(kept)
	_build()
	_refresh()


func _build() -> void:
	var column := UI.frame(self)
	var stage := StageScreen.mount(self, column)
	stage.taps_zoom = false
	stage.fill = 0.86
	view = stage
	tiles = OverlayTiles.new(stage)
	view.gui_input.connect(_on_input)
	title_label = UI.label("", UI.TEXT_POINTS, true)
	column.add_child(OverlaySheet.ribbon(title_label))
	StageScreen.window(column, 2.0)
	status_label = UI.label("", UI.TEXT_POINTS, true)
	together_label = UI.label("", UI.TEXT_POINTS, true)
	# What the island says scrolls in its place when it runs long, so the
	# controls below keep theirs: at §20.8's 200% a German or French line
	# wraps where an English one does not, and would push the bottom row
	# into the phone's safe area. It takes a share of the room the realm
	# leaves, never less than a line.
	var words := UI.scroll(column, true)
	var said := words.get_parent().get_parent() as ScrollContainer
	said.size_flags_stretch_ratio = 0.4
	said.custom_minimum_size.y = UI.px(UI.TEXT_POINTS * 2)
	words.add_child(status_label)
	words.add_child(together_label)

	var tools := UI.row()
	tool_button = UI.button("", next_tool)
	kind_button = UI.button("", next_kind)
	tools.add_child(tool_button)
	tools.add_child(kind_button)
	# §18.6: the island a remix replaced, back — shown only while one is kept.
	restore_button = UI.button(Strings.t("BUILDER_RESTORE"), restore)
	restore_button.accessibility_name = Strings.t("BUILDER_RESTORE_NAMED")
	tools.add_child(restore_button)
	undo_button = UI.button(Strings.t("BUILDER_UNDO"), undo)
	tools.add_child(undo_button)
	var keys := VBoxContainer.new()
	keys.mouse_filter = Control.MOUSE_FILTER_IGNORE
	keys.add_child(tools)
	var actions := UI.row()
	level_button = UI.button("", next_level)
	actions.add_child(level_button)
	actions.add_child(UI.button(Strings.t("BUILDER_SAVE"), save))
	raid_button = UI.button(Strings.t("BUILDER_RAID"), raid, true)
	actions.add_child(raid_button)
	# Home rides with the actions: one row fewer, so the realm keeps its room
	# at §20.8's large text.
	actions.add_child(UI.button(Strings.t("COMMON_HOME"), func() -> void: App.services.router.go(&"home")))
	keys.add_child(actions)
	_dock = OverlaySheet.dock(keys)
	column.add_child(UI.narrow(_dock))
	OverlaySheet.dress(self)


## The kinds the chosen tool offers, as ids: ground and wards by content id,
## guards by role row, laws by id. The Vault and the eraser have none.
func kinds() -> Array:
	match tool:
		Tool.GROUND:
			return [""] + Array(palette["ground"])
		Tool.WARD:
			return Array(palette["wards"])
		Tool.GUARD:
			return range(GUARD_ROLES.size())
		Tool.LAW:
			return Array(palette["laws"])
	return []


func kind_name(k: Variant) -> String:
	match tool:
		Tool.GROUND:
			return Strings.t("BUILDER_BARE") if k == "" else Strings.t("GROUND_" + str(k).to_upper())
		Tool.WARD:
			return Strings.t("WARD_" + str(k).to_upper())
		Tool.GUARD:
			return Strings.term("ROLE", GUARD_ROLES[k])
		Tool.LAW:
			return Strings.t("LAW_" + str(k).to_upper())
	return "—"


func next_tool() -> void:
	tool = ((tool + 1) % TOOLS.size()) as Tool
	kind = 0
	mouth = NO_MOUTH
	_refresh()


func next_kind() -> void:
	var ks := kinds()
	if not ks.is_empty():
		kind = (kind + 1) % ks.size()
	mouth = NO_MOUTH
	_refresh()


## A new, blank realm of the next level, 1 to 5 (§5.2's 10 by 10 to 14 by 14).
func next_level() -> void:
	undo_stack.append(island.bytes())
	island.reset(island.realm_level() % 5 + 1)
	# A blank realm is the player's own island, not a remix of one (§18.6).
	Draft.forget_origin()
	_refresh()


## What the chosen tool does to the tapped tile.
func tap_tile(tile: Vector2i) -> void:
	if tile.x < 0 or tile.y < 0 or tile.x >= island.side() or tile.y >= island.side():
		return
	var before := island.bytes()
	var asked_mouth := mouth
	_apply(tile)
	var after := island.bytes()
	last_tile = tile
	# A tunnel's first mouth changes nothing yet, and is not refused.
	last_ok = after != before or (tool == Tool.GROUND and mouth != NO_MOUTH and asked_mouth == NO_MOUTH)
	if after != before:
		undo_stack.append(before)
		if undo_stack.size() > UNDO_DEPTH:
			undo_stack.pop_front()
	_refresh()


## The chosen tool on `tile`, through the island.
func _apply(tile: Vector2i) -> void:
	var ks := kinds()
	var k: Variant = ks[kind] if kind < ks.size() else null
	match tool:
		Tool.GROUND:
			lay(tile, str(k))
		Tool.WARD:
			island.place_ward(k, tile.x, tile.y)
		Tool.GUARD:
			# A second tap on a post of the same role turns it a quarter: a
			# held post faces where its owner sets (G56). A new post faces
			# the way a crew comes in.
			if island.occupant(tile.x, tile.y) == "guard:%d" % k:
				island.turn(tile.x, tile.y)
			else:
				island.post_guard(k, tile.x, tile.y)
		Tool.LAW:
			island.weave(k, tile.x, tile.y)
		Tool.VAULT:
			island.set_vault(tile.x, tile.y)
		Tool.ERASE:
			island.clear(tile.x, tile.y)


## Ground on a tapped tile. Ground that faces one of the four ways (G56),
## laid where the same ground already is, turns a quarter instead; a tunnel
## takes two taps, its mouths 2 to 6 tiles apart (§6.2).
func lay(tile: Vector2i, k: String) -> void:
	if k == TUNNEL:
		if mouth == NO_MOUTH:
			mouth = tile
			return
		var reach: Array = palette["tunnel"]
		if not island.dig_tunnel(mouth.x, mouth.y, tile.x, tile.y):
			hint = Strings.t("BUILDER_TUNNEL_FAR", reach)
		mouth = NO_MOUTH
		return
	if k in Array(palette["facing"]) and island.ground(tile.x, tile.y) == k:
		island.turn(tile.x, tile.y)
	else:
		island.set_ground(tile.x, tile.y, k)


## The island as it was before the last edit.
func undo() -> void:
	if undo_stack.is_empty():
		return
	island.read(undo_stack.pop_back())
	mouth = NO_MOUTH
	last_tile = NO_MOUTH
	_refresh()


## A press acts on its tile; a drag with ground or the eraser paints every
## tile it crosses; a finger or pointer resting over a tile shows the ghost.
func _on_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and (event as InputEventMouseButton).button_index == MOUSE_BUTTON_LEFT:
		var e := event as InputEventMouseButton
		_stroke = e.pressed
		if e.pressed:
			_stroke_tile = view.tile_at(e.position)
			tap_tile(_stroke_tile)
	elif event is InputEventMouseMotion:
		var t := view.tile_at((event as InputEventMouseMotion).position)
		if _stroke and t != _stroke_tile and paints():
			_stroke_tile = t
			var ks := kinds()
			if tool == Tool.ERASE or str(island.ground(t.x, t.y)) != str(ks[kind] if kind < ks.size() else ""):
				tap_tile(t)
		elif not _stroke:
			show_ghost(t)


## Whether a drag paints with the chosen tool: ground that has no direction
## and is not a tunnel, and the eraser.
func paints() -> bool:
	if tool == Tool.ERASE:
		return true
	if tool != Tool.GROUND:
		return false
	var ks := kinds()
	var k := str(ks[kind]) if kind < ks.size() else ""
	return k != TUNNEL and k not in Array(palette["facing"])


## Whether the island would take the chosen tool on `t`, tried on a copy.
func would_take(t: Vector2i) -> bool:
	if t.x < 0 or t.y < 0 or t.x >= island.side() or t.y >= island.side():
		return false
	var probe := RulebornIsland.new()
	probe.read(island.bytes())
	var keep := island
	island = probe
	var was_mouth := mouth
	_apply(t)
	var took := probe.bytes() != keep.bytes() or (mouth != was_mouth)
	island = keep
	mouth = was_mouth
	hint = ""
	return took


## The ghost of what the tool places on `t`, gold or red.
func show_ghost(t: Vector2i) -> void:
	if tiles == null:
		return
	var ok := would_take(t)
	tiles.cursor(t, ok)
	tiles.ghost(ghost_mesh(), t, ok)


## What the chosen tool puts on a tile, as a mesh for its ghost; null for
## ground and the eraser, which the cursor alone shows.
func ghost_mesh() -> Mesh:
	var ks := kinds()
	var k: Variant = ks[kind] if kind < ks.size() else null
	match tool:
		Tool.WARD:
			return PieceKit.ward(str(k).to_pascal_case())
		Tool.GUARD:
			return ActorBuilder.mesh("guard")
		Tool.LAW:
			return PieceKit.pylon()
		Tool.VAULT:
			return PieceKit.vault(false)
	return null


func save() -> void:
	if Draft.keep(island.bytes()):
		status_label.text = Strings.t("BUILDER_SAVED")


## The island a remix replaced, back in the builder; the remix is kept in
## its place, so the player can go back and forth.
func restore() -> void:
	if not Draft.restore():
		return
	island.read(Draft.island())
	_refresh()


## Raid your own island (§13's "test your own defence"): the heist screen
## plays it, offline, and the result screen offers the way back here.
func raid() -> void:
	if not island.problems().is_empty():
		return
	save()
	App.services.store.dispatch(&"heist_started", {"island": island.bytes(), "testing": true})
	# Only as the app's own screen: a test that mounts the builder drives the
	# heist screen itself.
	if get_tree().current_scene == self:
		App.services.router.go(&"heist")


func _refresh() -> void:
	title_label.text = Strings.t("BUILDER_TITLE", island.realm_level())
	preview.start("1", 30, 3, island.bytes())
	view.show_replay(preview)
	var problems := island.problems()
	if problems.is_empty():
		var b: Dictionary = island.budget()
		status_label.text = Strings.t("BUILDER_READY", [b["wards"][0], b["wards"][1],
			b["guards"][0], b["guards"][1], b["laws"][0], b["laws"][1]])
	else:
		var why := Array(problems).map(func(p: Variant) -> String: return Strings.t("PROBLEM_" + str(p).to_upper()))
		status_label.text = Strings.t("BUILDER_BLOCKED", ", ".join(why))
	if mouth != NO_MOUTH:
		status_label.text = Strings.t("BUILDER_TUNNEL_END", palette["tunnel"])
	elif hint != "":
		status_label.text = hint
		hint = ""
	together_label.text = together(island.combos())
	undo_button.disabled = undo_stack.is_empty()
	if tiles != null:
		tiles.show_grid()
		tiles.cursor(last_tile, last_ok)
		if mouth != NO_MOUTH:
			tiles.paint({mouth: OverlayTiles.OPEN})
		else:
			tiles.paint({})
		tiles.ghost(null, Vector2i.ZERO)
	UI.relabel(tool_button, Strings.t("BUILDER_TOOL_" + TOOLS[tool]))
	var ks := kinds()
	UI.relabel(kind_button, kind_name(ks[kind]) if kind < ks.size() else "—")
	kind_button.disabled = ks.is_empty()
	UI.relabel(level_button, Strings.t("BUILDER_LEVEL", island.realm_level()))
	raid_button.disabled = not problems.is_empty()
	restore_button.visible = Draft.has_kept()


## §8.6: harmonies and dissonances are "shown automatically when weaving", so
## the builder names what the laws make together — and, since this is the
## owner's own island, the resonances and chords too.
static func together(c: Dictionary) -> String:
	var parts := []
	for n: Variant in c["harmonies"]:
		parts.append(Strings.t("BUILDER_HARMONY", Strings.t("NOTE_" + str(n).to_upper())))
	for n: Variant in c["dissonances"]:
		parts.append(Strings.t("BUILDER_CLASH", Strings.t("NOTE_" + str(n).to_upper())))
	for r: Variant in c["resonances"]:
		parts.append(Strings.t("RES_" + str(r).to_upper()))
	for ch: Variant in c["chords"]:
		parts.append(Strings.t("CHORD_" + str(ch).to_upper()))
	if parts.is_empty():
		return Strings.t("BUILDER_ALONE")
	return Strings.t("BUILDER_TOGETHER", ", ".join(parts))


func _process(_delta: float) -> void:
	var stage := view as StageView
	if stage != null and _dock != null:
		stage.cover_bottom = StageScreen.covered_below(stage, status_label.get_parent().get_parent().get_parent())
		stage.cover_top = StageScreen.covered_above(stage, title_label)
