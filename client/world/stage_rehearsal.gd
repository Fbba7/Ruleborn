class_name StageRehearsal
extends VBoxContainer
## The Rehearse tab (§13's rehearsals, the design's "Rehearsal and defence
## log"): one of the simulation's three crews — cautious, greedy, fast —
## sent against the player's own island, played out live in the replay card
## over the island with the route it took and where it was seen, then its
## result: how long it took, how often it was seen and what it carried out.
## Free, unlimited, no rewards (§13). The crew's every step is the
## simulation's own policy (`RulebornReplay.rehearse`); this only shows it.

const STYLES: Array[String] = ["cautious", "greedy", "fast"]
const ICONS := {"cautious": "crewroles/scout", "greedy": "heiststatus/lootbag", "fast": "crewroles/breaker"}
## Simulation ticks a frame on the card: about six times the heist's pace,
## so a whole run is watched in well under a minute.
const TICKS_A_FRAME := 3
## A trail's point every this many ticks.
const TRAIL_EVERY := 6

var view: StageView
var route: OverlayRoute
var style := "cautious"
var replay: RulebornReplay
var playing := false
## How many rehearsals this screen has run: each takes the next seed, so a
## crew comes in where its seed draws (§13.3's raids differ by landing).
var runs := 0
var _island := PackedByteArray()
var _cards := {}
var _kicker: Label
var _result: VBoxContainer
var _run: Button
var _report_seen := -1
var _sight := {}


func _init(island: PackedByteArray) -> void:
	_island = island
	name = "Rehearse"
	size_flags_vertical = Control.SIZE_EXPAND_FILL
	add_theme_constant_override("separation", UI.px(10))
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var scroller := ScrollContainer.new()
	scroller.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroller.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var page := VBoxContainer.new()
	page.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	page.add_theme_constant_override("separation", UI.px(10))
	scroller.add_child(page)
	add_child(scroller)
	page.add_child(_map_card())
	var large := Settings.text_scale >= 150
	var styles: BoxContainer = (VBoxContainer.new() as BoxContainer) if large else (HBoxContainer.new() as BoxContainer)
	styles.add_theme_constant_override("separation", UI.px(6))
	for s: String in STYLES:
		styles.add_child(_style_card(s))
	page.add_child(styles)
	var card := UI.panel("parchment")
	_result = VBoxContainer.new()
	_result.add_theme_constant_override("separation", UI.px(8))
	card.add_child(_result)
	page.add_child(card)
	# At large text the key's second line stands over it, wrapping, so the
	# key never asks for more than the phone's width.
	if large:
		var free := UI.label(Strings.t("REHEARSE_RUN_LINE"), 13.0, true)
		free.theme_type_variation = "Secondary"
		add_child(free)
	_run = KitControls.action2(Strings.t("REHEARSE_RUN"), "" if large else Strings.t("REHEARSE_RUN_LINE"), run,
		"gold")
	_run.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	add_child(_run)
	_choose(style)


func _ready() -> void:
	run()


## The replay card: the island in 3D with the crew on it, the route over
## it, its crew's name at the top and the legend at the bottom.
func _map_card() -> Control:
	var card := UI.panel("card")
	card.name = "Replay"
	# A third of the phone's height, as the design's, whatever the text size.
	card.custom_minimum_size.y = UI.px(240)
	card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.ready.connect(func() -> void:
		card.custom_minimum_size.y = maxf(UI.px(200), card.get_viewport_rect().size.y * 0.25))
	UI.dress(card, "frame_gold")
	view = StageView.new()
	view.fill = 1.1
	view.taps_zoom = false
	view.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(view)
	# The card says where the crew was seen with its own marks: the heist's
	# floating words would crowd a picture this small.
	view.anchors.visible = false
	route = OverlayRoute.new(view)
	card.add_child(route)
	var words := VBoxContainer.new()
	words.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var tag := UI.panel("tag_dark")
	tag.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	tag.mouse_filter = Control.MOUSE_FILTER_IGNORE
	# One line at the card's top; at large text it wraps across the card.
	var large := Settings.text_scale >= 150
	_kicker = UI.label("", 13, large)
	if large:
		tag.size_flags_horizontal = Control.SIZE_FILL
	_kicker.uppercase = true
	_kicker.add_theme_font_override("font", UI.bold_font())
	_kicker.add_theme_color_override("font_color", Tokens.color("gold"))
	_kicker.set_meta("bold", true)
	tag.add_child(_kicker)
	words.add_child(tag)
	var gap := Control.new()
	gap.size_flags_vertical = Control.SIZE_EXPAND_FILL
	gap.mouse_filter = Control.MOUSE_FILTER_IGNORE
	words.add_child(gap)
	var legend := _legend()
	if not large:
		words.add_child(legend)
		card.add_child(words)
		return card
	# At large text the crew's name and the legend would cover the island:
	# they stand above and below the card instead.
	words.remove_child(tag)
	var stack := VBoxContainer.new()
	stack.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stack.add_child(tag)
	stack.add_child(card)
	stack.add_child(legend)
	return stack


## The legend in the card's corner: "! seen", guard sight, the Vault's star.
func _legend() -> Control:
	var plate := UI.panel("tag_dark")
	plate.size_flags_horizontal = Control.SIZE_SHRINK_END
	plate.mouse_filter = Control.MOUSE_FILTER_IGNORE
	# At large text the legend wraps across the card's width.
	var large := Settings.text_scale >= 150
	var row: Container = (HFlowContainer.new() as Container) if large else (HBoxContainer.new() as Container)
	if large:
		plate.size_flags_horizontal = Control.SIZE_FILL
	row.add_theme_constant_override("separation", UI.px(10))
	row.add_theme_constant_override("h_separation", UI.px(10))
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for item: String in ["! " + Strings.t("REHEARSE_LEGEND_SEEN"), "▢ " + Strings.t("REHEARSE_LEGEND_SIGHT"),
			"★ " + Strings.t("REHEARSE_LEGEND_VAULT")]:
		row.add_child(UI.label(item, 13))
	plate.add_child(row)
	return plate


## A crew's card: its mark, its name and what it does; the chosen one lit.
func _style_card(s: String) -> Control:
	var card := UI.panel("card")
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_tight(card, 6)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", UI.px(2))
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var icon := Icons.view(ICONS[s], 26.0)
	icon.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	v.add_child(icon)
	var title := UI.label(Strings.t("REHEARSE_STYLE_" + s.to_upper()), 17.0, true)
	title.add_theme_font_override("font", UI.bold_font())
	title.set_meta("bold", true)
	title.name = "Name"
	v.add_child(title)
	var line := UI.label(Strings.t("REHEARSE_STYLE_%s_LINE" % s.to_upper()), 13.0, true)
	line.name = "Line"
	v.add_child(line)
	card.add_child(v)
	# The whole card is the key: a clear button over it, named for a screen
	# reader.
	var b := Button.new()
	b.flat = true
	b.focus_mode = Control.FOCUS_ALL
	b.accessibility_name = "%s: %s" % [title.text, line.text]
	b.custom_minimum_size = Vector2.ONE * UI.px(48)
	b.set_meta("style", s)
	b.pressed.connect(func() -> void:
		_choose(s)
		run())
	card.add_child(b)
	_cards[s] = card
	return card


## A panel's padding brought in to `points` a side: the design's cards are
## tight round their words.
static func _tight(panel: PanelContainer, points: float) -> void:
	panel.add_theme_stylebox_override("panel", UI.clear_box(points, points))


func _choose(s: String) -> void:
	style = s
	for k: String in _cards:
		var card: PanelContainer = _cards[k]
		var on := k == s
		UI.dress(card, "parchment" if on else "card")
		card.set_meta("chosen", on)
		for l: Label in card.find_children("*", "Label", true, false):
			l.add_theme_color_override("font_color", Tokens.color("parchment_ink" if on else "text_on_night")
				if l.name == "Name" else Tokens.color("parchment_text_2" if on else "text_on_night_2"))
	_kicker.text = Strings.t("REHEARSE_REPLAY_" + s.to_upper())


## Run the chosen crew against the island: the simulation plays it whole
## (it is cheap), then the card plays it back at its pace. A tap while one
## plays shows its end at once.
func run() -> void:
	if playing and replay != null:
		_finish()
		return
	runs += 1
	var bytes := RulebornReplay.rehearse(_island, STYLES.find(style) + 1, str(runs), HeistController.TICKS,
		HeistController.CREW)
	replay = RulebornReplay.new()
	if bytes.is_empty() or not replay.load(bytes, _island):
		replay = null
		_show_result({})
		return
	view.show_replay(replay)
	var v: Dictionary = replay.vault()
	route.vault = v.get("at", Vector2(-1, -1))
	route.clear()
	for i in replay.crew_size():
		route.trails.append(PackedVector2Array())
	_report_seen = -1
	_sight.clear()
	playing = true
	_show_result({})
	if Settings.reduced_motion:
		_finish()


## Play the rest of the rehearsal at once.
func _finish() -> void:
	while replay.tick() < replay.ticks() and not _over():
		_step()
	_end()


func _process(_delta: float) -> void:
	if not playing or replay == null:
		return
	for i in TICKS_A_FRAME:
		if replay.tick() >= replay.ticks() or _over():
			_end()
			return
		_step()
	view.sync()
	_read_sight()


## Where the guards' sight reached in this run so far, every awake guard's
## `seen` gathered as it plays: the card's guard sight.
func _read_sight() -> void:
	var guards := replay.guards()
	for gi: int in guards.size():
		if not guards[gi]["down"]:
			for t: int in replay.seen(gi):
				_sight[t] = true
	route.sight = PackedInt32Array(_sight.keys())


func _step() -> void:
	replay.step()
	if replay.tick() % TRAIL_EVERY == 0:
		var crew := replay.crew()
		for i in mini(crew.size(), route.trails.size()):
			var m: Dictionary = crew[i]
			if replay.has_landed() and m["standing"] == "Active":
				route.trails[i].append(m["at"])
		if replay.tick() % (TRAIL_EVERY * 5) == 0:
			_mark_seen()
			_read_sight()


## Everyone out or caught: nothing left to watch.
func _over() -> bool:
	if not replay.has_landed():
		return false
	for m: Dictionary in replay.crew():
		if m["standing"] == "Active":
			return false
	return true


func _mark_seen() -> void:
	var rep: Dictionary = replay.report()
	var seen: Array = rep.get("seen", [])
	if seen.size() == _report_seen:
		return
	_report_seen = seen.size()
	# One mark for places side by side: the report names each tile once,
	# and a crew seen on the move is seen on a run of them.
	route.seen.clear()
	for s: Dictionary in seen:
		var t := Vector2i(int(s["x"]), int(s["y"]))
		if route.seen.all(func(o: Vector2i) -> bool: return maxi(absi(o.x - t.x), absi(o.y - t.y)) > 2):
			route.seen.append(t)


func _end() -> void:
	playing = false
	view.sync()
	_read_sight()
	_mark_seen()
	route.queue_redraw()
	_show_result(replay.report())


## The result card: its grade on a tag, the time, the times seen and what
## was carried out, and the report's words for where it was seen.
func _show_result(rep: Dictionary) -> void:
	for child: Node in _result.get_children():
		_result.remove_child(child)
		child.queue_free()
	var head := HFlowContainer.new()
	head.add_theme_constant_override("h_separation", UI.px(10))
	head.add_theme_constant_override("v_separation", UI.px(4))
	var kicker := UI.label(Strings.t("REHEARSE_RESULT"), 13.0)
	kicker.uppercase = true
	kicker.add_theme_font_override("font", UI.bold_font())
	kicker.add_theme_color_override("font_color", Tokens.color("parchment_text_2"))
	kicker.set_meta("bold", true)
	head.add_child(kicker)
	_result.add_child(head)
	if rep.is_empty() or replay == null:
		var wait := UI.label(Strings.t("REHEARSE_PLAYING" if playing else "REHEARSE_NONE"), 15.0, true)
		wait.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		wait.add_theme_color_override("font_color", Tokens.color("parchment_ink"))
		_result.add_child(wait)
		return
	var o: Dictionary = replay.outcome()
	var grade := str(o.get("grade", "Foiled")).to_upper()
	var look := {"CLEAN": "green", "LOUD": "gold_round", "PARTIAL": "gold_round", "FOILED": "red"}
	head.add_child(OverlayHud.badge(Strings.t("REHEARSE_GRADE_" + grade).to_upper(), look.get(grade, "badge"), 13.0))
	var large := Settings.text_scale >= 150
	var stats: BoxContainer = (VBoxContainer.new() as BoxContainer) if large else (HBoxContainer.new() as BoxContainer)
	stats.add_theme_constant_override("separation", UI.px(8))
	var held := int(rep.get("held", 0))
	# Times seen as the card marks them: once a place, places side by side
	# one.
	for s: Array in [[DefencesPresenter.clock(held), "REHEARSE_TIME"],
			[str(route.seen.size()), "REHEARSE_SEEN"],
			[ShopPresenter.grouped(int(o.get("banked", 0))), "REHEARSE_CARRIED"]]:
		var tile := KitStatus.stat(s[0], Strings.t(s[1]).to_upper(), "", "fact")
		stats.add_child(tile)
	_result.add_child(stats)
	# Where it was seen, a place a mark, by what stands nearest (§13.2's
	# words), or that no guard ever was alerted.
	var island := RulebornIsland.new()
	island.read(_island)
	var places: Array[String] = []
	var named := {}
	for t: Vector2i in route.seen:
		var near := DefencesPresenter.nearest(island, t.x, t.y)
		# One place a name: two marks by the same path read as one.
		if near != "" and named.has(near):
			continue
		named[near] = true
		places.append(Strings.t("DEFENCES_NEAR", [near, t.x + 1, t.y + 1]) if near != ""
			else Strings.t("DEFENCES_AT", [t.x + 1, t.y + 1]))
	var said := Strings.t("DEFENCES_SEEN", "; ".join(places)) if not places.is_empty() \
		else Strings.t("DEFENCES_UNSEEN")
	var line := UI.label(said, 15.0, true)
	line.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	line.add_theme_color_override("font_color", Tokens.color("parchment_ink"))
	_result.add_child(line)
