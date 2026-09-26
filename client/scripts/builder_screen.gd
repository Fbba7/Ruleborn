class_name BuilderScreen
extends Control
## The island builder (§13): lay §6.2's ground on the realm's grid, post
## guards, place wards, weave laws with their pylons, move the Vault, and raid
## what was built. Every edit goes through `RulebornIsland`, which is the
## simulation's own island, so the builder never writes the bundle format and
## never judges an island itself: `problems()` is `Island::check`, the rules
## the server publishes by, and the Raid button waits until it is empty.
##
## The realm is drawn by the heist's own `RealmView`, from a heist started on
## the island at tick 0, so what the builder shows is what a raider meets
## before it lands: no crew, which lands wherever the raider chooses (§5.4).

enum Tool { GROUND, WARD, GUARD, LAW, VAULT, ERASE }

const TOOLS := ["GROUND", "WARD", "GUARD", "LAW", "VAULT", "ERASE"]
## §12.17's role rows, in order: a guard post is its row.
const GUARD_ROLES := ["Scout", "Warden", "Breaker", "Carrier", "Mender"]

## Where the island is kept between runs; a test points this elsewhere.
static var path := "user://island.rbi"

var island := RulebornIsland.new()
var preview := RulebornReplay.new()
var palette: Dictionary = RulebornIsland.palette()
var tool := Tool.GROUND
## Which of the tool's kinds is chosen: an index into `kinds()`.
var kind := 0

var view: RealmView
var title_label: Label
var status_label: Label
var together_label: Label
var tool_button: Button
var kind_button: Button
var level_button: Button
var raid_button: Button


func _ready() -> void:
	App.ready(self)
	if FileAccess.file_exists(path):
		island.read(FileAccess.get_file_as_bytes(path))
	_build()
	_refresh()


func _build() -> void:
	var column := UI.frame(self)
	title_label = UI.label("", UI.TEXT_POINTS)
	column.add_child(title_label)
	view = RealmView.new()
	view.size_flags_vertical = Control.SIZE_EXPAND_FILL
	view.gui_input.connect(func(event: InputEvent) -> void:
		if event is InputEventMouseButton and event.pressed:
			tap_tile(view.tile_at(event.position)))
	column.add_child(view)
	status_label = UI.label("", UI.TEXT_POINTS, true)
	together_label = UI.label("", UI.TEXT_POINTS, true)
	column.add_child(status_label)
	column.add_child(together_label)

	var tools := UI.row()
	tool_button = UI.button("", next_tool)
	kind_button = UI.button("", next_kind)
	tools.add_child(tool_button)
	tools.add_child(kind_button)
	column.add_child(tools)
	var actions := UI.row()
	level_button = UI.button("", next_level)
	actions.add_child(level_button)
	actions.add_child(UI.button(Strings.t("BUILDER_SAVE"), save))
	raid_button = UI.button(Strings.t("BUILDER_RAID"), raid, true)
	actions.add_child(raid_button)
	column.add_child(actions)
	var back := UI.row()
	back.add_child(UI.button(Strings.t("COMMON_HOME"), func() -> void: App.services.router.go(&"home")))
	column.add_child(back)


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
	_refresh()


func next_kind() -> void:
	var ks := kinds()
	if not ks.is_empty():
		kind = (kind + 1) % ks.size()
	_refresh()


## A new, blank realm of the next level, 1 to 5 (§5.2's 10 by 10 to 14 by 14).
func next_level() -> void:
	island.reset(island.realm_level() % 5 + 1)
	_refresh()


## What the chosen tool does to the tapped tile.
func tap_tile(tile: Vector2i) -> void:
	if tile.x < 0 or tile.y < 0 or tile.x >= island.side() or tile.y >= island.side():
		return
	var ks := kinds()
	var k: Variant = ks[kind] if kind < ks.size() else null
	match tool:
		Tool.GROUND:
			island.set_ground(tile.x, tile.y, k)
		Tool.WARD:
			island.place_ward(k, tile.x, tile.y)
		Tool.GUARD:
			island.post_guard(k, tile.x, tile.y)
		Tool.LAW:
			island.weave(k, tile.x, tile.y)
		Tool.VAULT:
			island.set_vault(tile.x, tile.y)
		Tool.ERASE:
			island.clear(tile.x, tile.y)
	_refresh()


func save() -> void:
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file != null:
		file.store_buffer(island.bytes())
		file.close()
		status_label.text = Strings.t("BUILDER_SAVED")


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
	together_label.text = together(island.combos())
	tool_button.text = Strings.t("BUILDER_TOOL_" + TOOLS[tool])
	var ks := kinds()
	kind_button.text = kind_name(ks[kind]) if kind < ks.size() else "—"
	kind_button.disabled = ks.is_empty()
	level_button.text = Strings.t("BUILDER_LEVEL", island.realm_level())
	raid_button.disabled = not problems.is_empty()


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
