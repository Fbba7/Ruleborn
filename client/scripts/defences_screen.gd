class_name DefencesScreen
extends Control
## Rehearsal and defence log (§13, §13.2, §23.2), as the design draws it: a
## back key, then two tabs.
##
## Rehearse (`StageRehearsal`): one of the simulation's three crews against
## the player's own island, played live in a replay card with its route,
## where it was seen and its result.
##
## Defence log: the season's raids on the player, newest first, each held or
## leaked with its grade, how long the defence held, who was caught and the
## haul denied; its report and replay (Report ›) while the replay is kept,
## and Trace where the server offers it. Reading it clears the raid badge.

## The tab the player last chose, kept while the app runs.
static var tab := -1

var controller: DefencesController
var body: VBoxContainer
var header_label: Label
var status_label: Label
var rehearsal: StageRehearsal
var _log: VBoxContainer
var _stats: HBoxContainer
var _segments: Control
var _gap: Control


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
	column.add_theme_constant_override("separation", UI.px(12))
	# The design's back key and tabs at the top: neither is a control the
	# player reaches for often (§21.1's thumb zone binds those).
	# On one row: the phone keeps its height for the replay card and the
	# result.
	var top := HBoxContainer.new()
	top.add_theme_constant_override("separation", UI.px(10))
	var back := KitNav.back(func() -> void: App.services.router.go(&"home"))
	back.set_meta("frequent", false)
	back.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	top.add_child(back)
	column.add_child(top)
	if tab < 0:
		var unseen := int(App.services.store.get_slice(DefencesState.DEFENCES).get("unseen", 0))
		tab = 1 if unseen > 0 else 0
	_segments = KitNav.segmented([Strings.t("REHEARSE_TAB").to_upper(), Strings.t("DEFENCES_TAB_LOG").to_upper()],
		tab, _show)
	for b: Button in _segments.find_children("*", "Button", true, false):
		b.set_meta("frequent", false)
	_segments.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	# At large text the tabs take a row of their own under the back key.
	if Settings.text_scale >= 150:
		column.add_child(_segments)
	else:
		top.add_child(_segments)
	rehearsal = StageRehearsal.new(own_island())
	column.add_child(rehearsal)
	_log = VBoxContainer.new()
	_log.name = "Log"
	_log.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_log.add_theme_constant_override("separation", UI.px(12))
	column.add_child(_log)
	# The season's line, for a screen reader and the header of the log.
	header_label = UI.label("", 13.0, true)
	header_label.theme_type_variation = "Secondary"
	header_label.visible = false
	_log.add_child(header_label)
	status_label = UI.status("info", "")
	_log.add_child(UI.plate(status_label, "glass"))
	var scroller := ScrollContainer.new()
	scroller.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroller.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var both := VBoxContainer.new()
	both.add_theme_constant_override("separation", UI.px(12))
	both.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_stats = HBoxContainer.new()
	_stats.add_theme_constant_override("separation", UI.px(8))
	both.add_child(_stats)
	body = VBoxContainer.new()
	body.add_theme_constant_override("separation", UI.px(10))
	body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	both.add_child(body)
	scroller.add_child(both)
	_log.add_child(scroller)
	_gap = StageScreen.corner_gap(column)
	_show(tab)


func _show(which: int) -> void:
	tab = which
	rehearsal.visible = which == 0
	rehearsal.set_process(which == 0)
	_log.visible = which == 1
	# The log has no key at the bottom to lift over the corners: its list
	# runs to the phone's edge.
	_gap.visible = which == 0


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
	header_label.text = str(d.get("header", ""))
	for holder: Node in [body, _stats]:
		for child: Node in holder.get_children():
			holder.remove_child(child)
			child.queue_free()
	if not d["ready"]:
		return
	var season: Dictionary = (slice.get("view", {}) as Dictionary).get("season", {})
	# The design's three: the season's raids, how many it held, and how
	# many raiders can be traced back.
	var raids: Array = (slice.get("view", {}) as Dictionary).get("raids", [])
	var traced := raids.filter(func(r: Dictionary) -> bool: return r.get("trace") is Dictionary).size()
	for stat: Array in [[int(season.get("held", 0)) + int(season.get("leaked", 0)), "DEFENCES_STAT_RAIDS"],
			[int(season.get("held", 0)), "DEFENCES_STAT_HELD"], [traced, "DEFENCES_STAT_TRACE"]]:
		var tile := KitStatus.stat(str(stat[0]), Strings.t(stat[1]))
		tile.accessibility_name = d.get("header", "")
		_stats.add_child(tile)
	var busy: bool = d["busy"] != ""
	if d.has("empty"):
		body.add_child(UI.plate(UI.label(d["empty"], UI.TEXT_POINTS, true), "glass"))
	for r: Dictionary in d["raids"]:
		body.add_child(_raid(r, busy))


## A raid as the design's row on parchment: the raider's medallion with its
## level and its outcome's mark; the raider and the outcome on a tag; how
## long the defence held and who was caught; the haul denied, Report › (its
## report and replay) and Trace. Its lines are what a screen reader says.
func _raid(r: Dictionary, busy: bool) -> Control:
	var raw: Dictionary = r["raid"]
	var lines: Array = r["lines"]
	var row := UI.panel("parchment")
	row.accessibility_description = "\n".join(lines)
	# At large text the row stacks, so nothing asks for more than the phone.
	var large := Settings.text_scale >= 150
	var line: BoxContainer = (VBoxContainer.new() as BoxContainer) if large else (HBoxContainer.new() as BoxContainer)
	line.add_theme_constant_override("separation", UI.px(10))
	row.add_child(line)
	var raider: Dictionary = raw.get("raider", {})
	var medal := OverlayHud.medallion("heistoutcomes/" + str(raw.get("grade", "clean")),
		int(raider["keeper_level"]) if raider.get("keeper_level") != null else -1, 46.0)
	medal.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	medal.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	line.add_child(medal)
	var middle := VBoxContainer.new()
	middle.add_theme_constant_override("separation", UI.px(2))
	middle.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	middle.alignment = BoxContainer.ALIGNMENT_CENTER
	var title := UI.label(r["title"], 17.0, true)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.add_theme_font_override("font", UI.bold_font())
	title.add_theme_color_override("font_color", Tokens.color("parchment_ink"))
	title.set_meta("bold", true)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	title.set_meta("heist", r["heist"])
	middle.add_child(title)
	var grade := str(raw.get("grade", "foiled"))
	var tag := "DEFENCES_TAG_HELD" if raw.get("held", false) else (
		"DEFENCES_STAT_PARTIAL" if grade == "partial" else "DEFENCES_TAG_OUT")
	var looks := {"DEFENCES_TAG_HELD": "green", "DEFENCES_STAT_PARTIAL": "gold_round", "DEFENCES_TAG_OUT": "gold_round"}
	var tags := HBoxContainer.new()
	tags.add_theme_constant_override("separation", UI.px(6))
	var badge := OverlayHud.badge(Strings.t(tag).to_upper(), looks[tag], 13.0)
	badge.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	tags.add_child(badge)
	if r["new"]:
		var fresh := Strings.t("DEFENCES_NEW").trim_prefix(" · ").strip_edges().to_upper()
		var b := OverlayHud.badge(fresh, "badge", 13.0)
		b.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		tags.add_child(b)
	var facts: Array[String] = []
	if raw.get("held_seconds") != null:
		facts.append(Strings.t("DEFENCES_HELD_THEM", DefencesPresenter.clock(int(raw["held_seconds"]))))
	facts.append(Strings.t("DEFENCES_CAUGHT_OF", [int(raw.get("caught", 0)), int(raw.get("crew", 0))]))
	var said := UI.label(" · ".join(facts), 15.0, true)
	said.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	said.add_theme_color_override("font_color", Tokens.color("parchment_text_2"))
	# Its tags, then how long it held and who was caught; at large text the
	# words take a line under the tags.
	var under: BoxContainer = (VBoxContainer.new() as BoxContainer) if large else (HBoxContainer.new() as BoxContainer)
	under.add_theme_constant_override("separation", UI.px(8))
	tags.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	under.add_child(tags)
	said.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	under.add_child(said)
	middle.add_child(under)
	line.add_child(middle)
	# Under the words: the haul denied, then Report › and Trace at the end.
	var side := HFlowContainer.new()
	side.add_theme_constant_override("h_separation", UI.px(8))
	side.alignment = FlowContainer.ALIGNMENT_END
	side.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	if raw.get("denied") != null:
		var denied := UI.label(Strings.t("DEFENCES_DENIED_SHORT", ShopPresenter.grouped(int(raw["denied"]))), 16.0)
		denied.add_theme_font_override("font", UI.bold_font())
		denied.add_theme_color_override("font_color", Tokens.color("success_text"))
		denied.set_meta("bold", true)
		denied.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		side.add_child(denied)
	if not (r["watch"] as Dictionary).is_empty():
		side.add_child(_key(r["watch"], busy, controller.watch.bind(r["raid"]), Strings.t("DEFENCES_REPORT_KEY")))
	if not (r["trace"] as Dictionary).is_empty():
		side.add_child(_key(r["trace"], busy, controller.trace.bind(r["raid"]), r["trace"]["action"]))
	middle.add_child(side)
	return row


## A key on a row, in the design's plain gold words: its words are what a
## screen reader says.
func _key(o: Dictionary, busy: bool, pressed: Callable, words: String) -> Button:
	var b := Button.new()
	b.text = words
	b.flat = true
	b.accessibility_name = o["spoken"]
	b.pressed.connect(pressed)
	b.custom_minimum_size = Vector2(UI.px(48), UI.px(48))
	b.add_theme_font_override("font", UI.bold_font())
	b.add_theme_color_override("font_hover_color", Tokens.color("leather_dark"))
	b.add_theme_color_override("font_pressed_color", Tokens.color("leather_dark"))
	b.alignment = HORIZONTAL_ALIGNMENT_RIGHT
	b.add_theme_color_override("font_color", Tokens.color("leather_mid"))
	b.add_theme_font_size_override("font_size", UI.text_px(15))
	b.tooltip_text = o["action"]
	b.disabled = busy or not o["can"]
	b.set_meta("key", o["key"])
	b.set_meta("item", o["item"])
	return b


## The island the phone holds for the player's own defence: the curation
## draft, else the realm view's island, else the builder's draft, else a
## starting island.
static func own_island() -> PackedByteArray:
	var store := App.services.store
	for bytes: Variant in [store.get_slice(CurationState.CURATION).get("draft", PackedByteArray()),
			store.get_slice(RealmState.REALM).get("island", PackedByteArray()), Draft.island()]:
		if bytes is PackedByteArray and not (bytes as PackedByteArray).is_empty():
			return bytes
	var island := RulebornIsland.new()
	island.reset(3)
	return island.bytes()
