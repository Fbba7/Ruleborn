class_name DefencesScreen
extends Control
## The defence log (§13.2, §23.2, "Rehearsal and defence log"): the season's
## raids on the player, newest first, each held or leaked with its grade, the
## haul denied, how long the defence held, who was caught and the share
## earned; Watch replay while it is kept; and Trace where the server offers
## it. Reading it clears the raid badge.
##
## Behind the log stands the defence it records: the player's own island with
## the defence overlay (`OverlayDefence`), its posts numbered and its wards
## marked, from the curation draft, the realm view's island or the builder's
## draft, whichever the phone holds. A tap on a post shows its guard's sight.

var controller: DefencesController
var body: VBoxContainer
var header_label: Label
var status_label: Label
var view: StageView
var defence: OverlayDefence
var _sheet: ScrollContainer
var _keys: Control
var _top: Control
var _drawn_key := ""
var _island: RulebornIsland
var _stats: HFlowContainer


func _ready() -> void:
	App.ready(self)
	controller = App.services.defences_flow
	_build()
	App.services.store.changed.connect(_on_changed)
	_refresh()
	await controller.load_log()


func _on_changed(slice: StringName) -> void:
	if slice == DefencesState.DEFENCES and is_inside_tree():
		_refresh()


func _build() -> void:
	var column := UI.frame(self)
	view = StageScreen.mount(self, column)
	view.fill = 0.86
	defence = OverlayDefence.new(view)
	view.tapped.connect(func(at: Vector2) -> void: _on_tap(view.tile_at(at)))
	var top := VBoxContainer.new()
	top.add_theme_constant_override("separation", UI.px(6))
	var heading := OverlayHud.heading("", Strings.t("DEFENCES_TITLE"))
	header_label = heading.find_child("Kicker", true, false) as Label
	top.add_child(heading)
	# A flow: at large text a tile that cannot share a line takes its own.
	_stats = HFlowContainer.new()
	_stats.add_theme_constant_override("h_separation", UI.px(6))
	_stats.add_theme_constant_override("v_separation", UI.px(6))
	# At large text the season's tiles scroll with the raids, above them,
	# where the phone has no room to keep them fixed.
	var large := Settings.text_scale >= 150
	if not large:
		top.add_child(_stats)
	_top = top
	column.add_child(top)
	status_label = UI.status("info", "")
	column.add_child(UI.plate(status_label, "glass"))
	StageScreen.window(column, 0.8)
	var scroller := ScrollContainer.new()
	scroller.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroller.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body = VBoxContainer.new()
	body.add_theme_constant_override("separation", UI.px(8))
	body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	if large:
		var both := VBoxContainer.new()
		both.add_theme_constant_override("separation", UI.px(8))
		both.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		both.mouse_filter = Control.MOUSE_FILTER_IGNORE
		both.add_child(_stats)
		both.add_child(body)
		scroller.add_child(both)
	else:
		scroller.add_child(body)
	column.add_child(scroller)
	_sheet = StageScreen.sheet(body, 1.0)
	_keys = StageScreen.handle(column, _sheet)
	var dock := HBoxContainer.new()
	dock.alignment = BoxContainer.ALIGNMENT_CENTER
	dock.add_child(OverlayHud.key("hud/home", Strings.t("COMMON_HOME"), func() -> void: App.services.router.go(&"home")))
	column.add_child(dock)
	StageScreen.corner_gap(column)
	_draw_world()


func _refresh() -> void:
	if not is_inside_tree():
		return
	var slice: Dictionary = App.services.store.get_slice(DefencesState.DEFENCES)
	var d := DefencesPresenter.screen(slice)
	if d["error"] != "":
		UI.set_status(status_label, "alarm", d["error"])
	elif d["busy"] != "" or not d["ready"]:
		UI.set_status(status_label, "info", Strings.t("COMMON_LOADING"))
	else:
		UI.set_status(status_label, "info", "")
	(status_label.get_parent() as Control).visible = status_label.text != ""
	header_label.text = str(d.get("header", "")).to_upper()
	for holder: Node in [body, _stats]:
		for child: Node in holder.get_children():
			holder.remove_child(child)
			child.queue_free()
	if not d["ready"]:
		return
	var season: Dictionary = (slice.get("view", {}) as Dictionary).get("season", {})
	for stat: Array in [["held", "DEFENCES_STAT_HELD", "heistoutcomes/foiled"],
			["leaked", "DEFENCES_STAT_LEAKED", "heistoutcomes/loud"],
			["partial", "DEFENCES_STAT_PARTIAL", "heistoutcomes/partial"]]:
		_stats.add_child(_stat(str(int(season.get(stat[0], 0))), Strings.t(stat[1]), stat[2], d.get("header", "")))
	var busy: bool = d["busy"] != ""
	if d.has("empty"):
		body.add_child(UI.plate(UI.label(d["empty"], UI.TEXT_POINTS, true), "glass"))
	for r: Dictionary in d["raids"]:
		body.add_child(_raid(r, busy))


## A season count on a card: the number large over its name.
func _stat(number: String, name: String, icon: String, spoken: String) -> Control:
	var card := UI.panel("card")
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.accessibility_name = spoken
	var words := VBoxContainer.new()
	words.add_theme_constant_override("separation", 0)
	var line := HBoxContainer.new()
	line.alignment = BoxContainer.ALIGNMENT_CENTER
	line.add_theme_constant_override("separation", UI.px(4))
	line.add_child(Icons.view(icon, 20.0))
	var n := UI.label(number, 22.0)
	n.add_theme_font_override("font", Tokens.font("display"))
	line.add_child(n)
	words.add_child(line)
	var k := UI.label(name, 13.0)
	k.theme_type_variation = "Secondary"
	words.add_child(k)
	card.add_child(words)
	return card


## A raid as the design's row: the raider's medallion with its level and its
## outcome's mark, the raider and the outcome on a tag, how long the defence
## held and who was caught, the haul denied, and Watch and Trace. Its lines
## are what a screen reader says for it.
func _raid(r: Dictionary, busy: bool) -> Control:
	var raw: Dictionary = r["raid"]
	var lines: Array = r["lines"]
	var row := UI.panel("parchment")
	row.accessibility_description = "\n".join(lines)
	var outer := VBoxContainer.new()
	outer.add_theme_constant_override("separation", UI.px(6))
	row.add_child(outer)
	# At large text the row stacks: the medallion, the words, then the keys
	# in a row, so nothing asks for more than the phone's width.
	var large := Settings.text_scale >= 150
	var line: BoxContainer = (VBoxContainer.new() as BoxContainer) if large else (HBoxContainer.new() as BoxContainer)
	line.add_theme_constant_override("separation", UI.px(8))
	outer.add_child(line)
	var raider: Dictionary = raw.get("raider", {})
	var medal := OverlayHud.medallion("heistoutcomes/" + str(raw.get("grade", "clean")),
		int(raider["keeper_level"]) if raider.get("keeper_level") != null else -1, 46.0)
	medal.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	line.add_child(medal)
	var middle := VBoxContainer.new()
	middle.add_theme_constant_override("separation", UI.px(2))
	middle.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	# The raider's name on its own line, wrapping at large text, its tags
	# under it.
	var title := UI.label(r["title"], 15.0, true)
	title.add_theme_font_override("font", UI.bold_font())
	title.set_meta("bold", true)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	title.set_meta("heist", r["heist"])
	middle.add_child(title)
	var name_row := HFlowContainer.new()
	name_row.add_theme_constant_override("h_separation", UI.px(6))
	name_row.add_theme_constant_override("v_separation", UI.px(4))
	var tag := "green_muted" if raw.get("held", false) else "red"
	# At large text the outcome's grade takes a line of its own on the tag.
	var outcome := str(lines[0]).to_upper()
	name_row.add_child(OverlayHud.badge(outcome.replace(" (", "\n(") if large else outcome, tag, 13.0))
	if r["new"]:
		var fresh := Strings.t("DEFENCES_NEW").trim_prefix(" · ").strip_edges().to_upper()
		name_row.add_child(OverlayHud.badge(fresh, "badge", 13.0))
	middle.add_child(name_row)
	var facts: Array[Control] = []
	if raw.get("held_seconds") != null:
		var t := int(raw["held_seconds"])
		facts.append(OverlayHud.pill("heiststatus/clock", "%d:%02d" % [t / 60, t % 60], lines[2], "card"))
	facts.append(OverlayHud.pill("heiststatus/knockedout", "%d/%d" % [int(raw.get("caught", 0)),
		int(raw.get("crew", 0))], lines[3], "card"))
	if raw.get("denied") != null:
		facts.append(OverlayHud.pill("heiststatus/lootbag", ShopPresenter.grouped(int(raw["denied"])), lines[1],
			"card"))
	middle.add_child(OverlayHud.row_of(facts))
	line.add_child(middle)
	var keys: Array[Control] = []
	if not (r["watch"] as Dictionary).is_empty():
		keys.append(_key(r["watch"], busy, controller.watch.bind(r["raid"]), "heistoutcomes/replay"))
	if not (r["trace"] as Dictionary).is_empty():
		keys.append(_key(r["trace"], busy, controller.trace.bind(r["raid"]), "planningactions/scout"))
	if not keys.is_empty():
		var side: BoxContainer = (HBoxContainer.new() as BoxContainer) if large else (VBoxContainer.new() as BoxContainer)
		side.alignment = BoxContainer.ALIGNMENT_END if large else BoxContainer.ALIGNMENT_CENTER
		side.add_theme_constant_override("separation", UI.px(4))
		for k: Control in keys:
			side.add_child(k)
		line.add_child(side)
	return row


func _key(o: Dictionary, busy: bool, pressed: Callable, icon: String) -> Button:
	# A round key with its mark: its words are what a screen reader says.
	var b := UI.action("", pressed, "leather", o["spoken"])
	b.custom_minimum_size = Vector2.ONE * UI.px(48)
	UI.dress(b, "leather", 24.0)
	b.tooltip_text = o["action"]
	b.disabled = busy or not o["can"]
	b.set_meta("key", o["key"])
	b.set_meta("item", o["item"])
	b.icon = Icons.texture(icon)
	b.add_theme_constant_override("icon_max_width", UI.px(26))
	b.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	return b


## The island the phone holds for the player's own defence: the curation
## draft, else the realm view's island, else the builder's draft.
static func own_island() -> PackedByteArray:
	var store := App.services.store
	for bytes: Variant in [store.get_slice(CurationState.CURATION).get("draft", PackedByteArray()),
			store.get_slice(RealmState.REALM).get("island", PackedByteArray()), Draft.island()]:
		if bytes is PackedByteArray and not (bytes as PackedByteArray).is_empty():
			return bytes
	return PackedByteArray()


## The player's defence in 3D, with its overlay.
func _draw_world() -> void:
	var bytes := own_island()
	var key := str(hash(bytes))
	if key == _drawn_key:
		return
	_drawn_key = key
	var island := RulebornIsland.new()
	if bytes.is_empty() or not island.read(bytes):
		island.reset(3)
	var replay := StageRealm.replay_of(island.bytes())
	if replay == null:
		return
	view.show_replay(replay)
	_island = island
	defence.draw(island, replay, CurationState.NO_POST, {})


## A tap on a post shows that guard's sight (§21.12), a tap elsewhere the
## first guard's: the defence the log records, read post by post.
func _on_tap(tile: Vector2i) -> void:
	if _island == null or view.replay == null:
		return
	var post := tile if str(_island.occupant(tile.x, tile.y)).begins_with("guard:") else CurationState.NO_POST
	defence.draw(_island, view.replay, post, {})


func _process(_delta: float) -> void:
	if _sheet != null and view != null:
		view.cover_bottom = StageScreen.covered_below(view, _keys)
		view.cover_top = StageScreen.covered_above(view, _top)
