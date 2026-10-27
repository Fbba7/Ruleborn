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
## Each tool's mark, in `TOOLS`' order.
const TOOL_ICONS := ["realmactions/terrain", "wards/staticcoil", "crewroles/warden", "buildings/lawpylon",
	"heiststatus/vaultprogress", "generalui/cancel"]
## A kind's card, in points.
const CARD_POINTS := 76.0

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
var level_button: Button
var raid_button: Button
var restore_button: Button
var undo_button: Button
var _stroke := false
var _dock: Control
var _stroke_tile := NO_MOUTH
var _stats: HFlowContainer
var _top: Control
var _said: Control
var _tool_tabs: HBoxContainer
var _cards: HFlowContainer
var _shelf: ScrollContainer
var _cards_key := ""


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
	var top := VBoxContainer.new()
	top.add_theme_constant_override("separation", UI.px(6))
	var heading := OverlayTop.bar(func() -> void: App.services.router.go(&"home"), Strings.t("BUILDER_KICKER"), "")
	title_label = heading.find_child("Title", true, false) as Label
	top.add_child(heading)
	_stats = HFlowContainer.new()
	_stats.add_theme_constant_override("h_separation", UI.px(5))
	top.add_child(_stats)
	_top = top
	column.add_child(top)
	StageScreen.window(column, 2.0)
	# What the island says, on a glass pill over the world: it scrolls in
	# its place when it runs long, so the controls below keep theirs at
	# §20.8's 200%.
	status_label = UI.label("", 14.0, true)
	status_label.add_theme_font_override("font", UI.bold_font())
	status_label.set_meta("bold", true)
	together_label = UI.label("", 13.0, true)
	var said := ScrollContainer.new()
	said.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	said.size_flags_vertical = Control.SIZE_EXPAND_FILL
	said.size_flags_stretch_ratio = 0.35
	said.custom_minimum_size.y = UI.px(UI.TEXT_POINTS * 2)
	var glass := UI.panel("glass")
	glass.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var words := VBoxContainer.new()
	words.add_theme_constant_override("separation", 0)
	words.add_child(status_label)
	words.add_child(together_label)
	glass.add_child(words)
	said.add_child(glass)
	column.add_child(said)
	_said = said
	# The sheet: the tools as tabs, the chosen tool's kinds as cards.
	var sheet := UI.panel("card")
	var inside := VBoxContainer.new()
	inside.add_theme_constant_override("separation", UI.px(6))
	_tool_tabs = HBoxContainer.new()
	_tool_tabs.add_theme_constant_override("separation", UI.px(3))
	inside.add_child(_tool_tabs)
	# The kinds wrap into rows that scroll, one row in sight: every card
	# stays on the screen (§21.1).
	var shelf := ScrollContainer.new()
	shelf.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	shelf.custom_minimum_size.y = UI.px(CARD_POINTS + 16)
	_cards = HFlowContainer.new()
	_cards.add_theme_constant_override("h_separation", UI.px(6))
	_cards.add_theme_constant_override("v_separation", UI.px(6))
	_cards.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	shelf.add_child(_cards)
	_shelf = shelf
	inside.add_child(shelf)
	sheet.add_child(inside)
	column.add_child(sheet)
	_dock = sheet
	var actions := HFlowContainer.new()
	actions.alignment = FlowContainer.ALIGNMENT_CENTER
	actions.add_theme_constant_override("h_separation", UI.px(5))
	actions.add_theme_constant_override("v_separation", UI.px(6))
	level_button = _small(Strings.t("BUILDER_LEVEL", 1), next_level, "realmactions/upgrade")
	actions.add_child(level_button)
	undo_button = _small(Strings.t("BUILDER_UNDO"), undo, "heistoutcomes/replay")
	actions.add_child(undo_button)
	# §18.6: the island a remix replaced, back — shown only while one is kept.
	restore_button = _small(Strings.t("BUILDER_RESTORE"), restore, "generalui/sort")
	restore_button.accessibility_name = Strings.t("BUILDER_RESTORE_NAMED")
	actions.add_child(restore_button)
	actions.add_child(_small(Strings.t("BUILDER_SAVE"), save, "generalui/confirm"))
	raid_button = UI.action(Strings.t("BUILDER_RAID"), raid, "gold")
	raid_button.custom_minimum_size.x = UI.px(104)
	raid_button.icon = Icons.texture("planningactions/launch")
	raid_button.add_theme_constant_override("icon_max_width", UI.px(22))
	actions.add_child(raid_button)
	column.add_child(UI.narrow(actions))


## A round leather key with a mark: its words are its spoken name and its
## tooltip.
func _small(words: String, pressed: Callable, icon: String) -> Button:
	var b := UI.action("", pressed, "leather", words)
	b.custom_minimum_size = Vector2.ONE * UI.px(48)
	UI.dress(b, "leather", 24.0)
	b.tooltip_text = words
	b.icon = Icons.texture(icon)
	b.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	b.add_theme_constant_override("icon_max_width", UI.px(26))
	return b


## The tools as tabs of marks, the chosen one lit; each says its name.
func _fill_tools() -> void:
	for c: Node in _tool_tabs.get_children():
		_tool_tabs.remove_child(c)
		c.queue_free()
	for t: int in TOOLS.size():
		var b := UI.action("", func() -> void:
			tool = t as Tool
			kind = 0
			mouth = NO_MOUTH
			_refresh(), "tab_active" if t == tool else "tab", Strings.t("BUILDER_TOOL_" + TOOLS[t]))
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.icon = Icons.texture(TOOL_ICONS[t])
		b.add_theme_constant_override("icon_max_width", UI.px(26))
		b.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
		b.tooltip_text = Strings.t("BUILDER_TOOL_" + TOOLS[t])
		b.set_meta("tool", TOOLS[t])
		_tool_tabs.add_child(b)


## The chosen tool's kinds as cards with their marks and names; the chosen
## one in gold. Rebuilt only when the tool changes.
func _fill_cards() -> void:
	var key := "%d|%d" % [tool, kind]
	if key == _cards_key:
		return
	var same_tool := _cards_key.begins_with("%d|" % tool)
	_cards_key = key
	if same_tool:
		for c: Node in _cards.get_children():
			UI.set_look(c as Button, "card_selected" if int(c.get_meta("kind")) == kind else "card")
		return
	for c: Node in _cards.get_children():
		_cards.remove_child(c)
		c.queue_free()
	var ks := kinds()
	for i: int in ks.size():
		var b := UI.action(kind_name(ks[i]), func() -> void:
			kind = i
			mouth = NO_MOUTH
			_refresh(), "card_selected" if i == kind else "card")
		b.custom_minimum_size = Vector2(UI.px(CARD_POINTS), UI.px(CARD_POINTS))
		b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		b.add_theme_font_size_override("font_size", UI.text_px(13))
		b.set_meta("points", 13.0)
		b.vertical_icon_alignment = VERTICAL_ALIGNMENT_TOP
		b.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
		var icon := _kind_icon(ks[i])
		b.icon = Icons.texture(icon if Icons.has(icon) else TOOL_ICONS[tool])
		b.add_theme_constant_override("icon_max_width", UI.px(38))
		b.set_meta("kind", i)
		_cards.add_child(b)
	if ks.is_empty():
		var p := OverlayHud.pill(TOOL_ICONS[tool], Strings.t("BUILDER_TOOL_" + TOOLS[tool]), "", "glass")
		_cards.add_child(p)


func _kind_icon(k: Variant) -> String:
	match tool:
		Tool.GROUND:
			return "terrain/" + str(k).replace("_", "") if str(k) != "" else "generalui/cancel"
		Tool.WARD:
			return OverlayHud.ward_icon(str(k))
		Tool.GUARD:
			return "crewroles/" + str(GUARD_ROLES[int(k)]).to_lower()
		Tool.LAW:
			return OverlayHud.law_icon(str(k))
	return TOOL_ICONS[tool]


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
	title_label.text = Strings.t("BUILDER_TITLE", island.realm_level()).replace("\n", " ")
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
	if tiles != null and view is StageView:
		OverlayDefence.pin_all(view as StageView, island, preview, NO_MOUTH)
	if tiles != null:
		tiles.show_grid()
		tiles.cursor(last_tile, last_ok)
		if mouth != NO_MOUTH:
			tiles.paint({mouth: OverlayTiles.OPEN})
		else:
			tiles.paint({})
		tiles.ghost(null, Vector2i.ZERO)
	_fill_tools()
	_fill_cards()
	level_button.accessibility_name = Strings.t("BUILDER_LEVEL", island.realm_level())
	level_button.tooltip_text = level_button.accessibility_name
	raid_button.disabled = not problems.is_empty()
	restore_button.visible = Draft.has_kept()
	_fill_stats(problems.size())


## The island's limits as pills: wards, guard posts and laws against what
## its level allows, and a warning while the island cannot be raided.
func _fill_stats(problems: int) -> void:
	for c: Node in _stats.get_children():
		_stats.remove_child(c)
		c.queue_free()
	var b: Dictionary = island.budget()
	var said := status_label.text
	_stats.add_child(OverlayHud.pill("hud/shield", "%d/%d" % [b["wards"][0], b["wards"][1]], said))
	_stats.add_child(OverlayHud.pill("crewroles/warden", "%d/%d" % [b["guards"][0], b["guards"][1]], said))
	_stats.add_child(OverlayHud.pill("buildings/lawpylon", "%d/%d" % [b["laws"][0], b["laws"][1]], said))
	_stats.add_child(OverlayHud.pill("hud/compass", "%d×%d" % [island.side(), island.side()], title_label.text))
	if problems > 0:
		_stats.add_child(OverlayHud.pill("hud/warning", str(problems), said, "red"))


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
		stage.cover_bottom = StageScreen.covered_below(stage, _said)
		stage.cover_top = StageScreen.covered_above(stage, _top)
