class_name ResultScreen
extends Control
## What a heist came to (§23.2's result screen: "Grade, loot kept, … replay"),
## read from the check the server would make, never from what the device
## claims: the grade is the re-simulation's (§24.12). A cleared rehearsal
## offers to publish the island (§18.6); a Workshop play, to rate it.

## §12.9's outcomes: each one's condition and what it multiplies (the haul
## and Renown), as the document's table gives them.
const OUTCOME := {"Clean": ["RESULT_CONDITION_CLEAN", "1.0", "1.0"], "Loud": ["RESULT_CONDITION_LOUD", "0.7", "0.8"],
	"Partial": ["RESULT_CONDITION_PARTIAL", "0.4", "0.5"], "Foiled": ["RESULT_CONDITION_FOILED", "0", "0"]}

## How long the coins fly home, in seconds, before the page rests.
const FLIGHT_SECONDS := 2.2
## The design's reward tiles, in its order, each rimmed in its colour.
const REWARDS := [["starlight", "#F2B43C"], ["essence", "#3FBF7F"], ["renown", "#E06AC4"]]

var kicker_label: Label
var grade_label: Label
## §12.9's condition under the outcome, and its multipliers on a chip.
var condition_label: Label
var chip_label: Label
## The heist's length and the alarm's true peak (§12.9).
var subline_label: Label
## §12.13's moment: when, and what happened.
var moment_when: Label
var moment_label: Label
var moment_card: PanelContainer
## The design's three reward tiles (Starlight, Essence, Renown), shown when
## the server's answer carries the split, and the entry fee's line.
var reward_row: BoxContainer
var reward_labels := {}
var fee_label: Label
## §11.6: the crew home and how long it rests, as the server set it.
var rest_label: Label
## §7.6's study card: one law the crew crossed, studied once for the pages
## the server gives.
var study_card: PanelContainer
## The haul's tile and its number, counting up.
var haul_tile: PanelContainer
var haul_label: Label
var detail_label: Label
var check_label: Label
## A Workshop play's Again, which waits for the island's answer.
var again_button: Button
## The island after the heist, and the coins flying home over it.
var world_view: WorldView
var flight: FxDraw
## The haul's number on the card, where the coins land.
var counter: Control
## The laws the crew crossed, from the replay's pylons, for the study card.
var _crossed: Array[String] = []
var _haul := 0
## The replay's moments (ReplayScreen.moments), its length in ticks, its
## alarm's peak and the crew as it ended.
var _moments: Array[Dictionary] = []
var _ticks := 0
var _peak := 0
var _crew_end: Array = []
var _clock := 0.0
var _verdict := {}


func _ready() -> void:
	App.ready(self)
	var heist: Dictionary = App.services.store.get_slice(AppState.HEIST)
	_build_world(heist)
	# The designs' result: the outcome over gold rays (a red dusk when
	# foiled) on the night under the island, the haul on a parchment tile.
	# The page is the night's: its words take the dark family's shades, and
	# the contrast checks read them against the night they stand on.
	theme = RbTheme.of("dark")
	set_meta("text_bg", Tokens.material("night")["text_bg"])
	set_meta("rb_family", "dark")
	var backdrop := FxDraw.new(_draw_rays)
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(backdrop)
	var columns := FxSkin.frame(self)
	var column := columns[1]
	# The page hangs from the top, as the design's, over the bottom bar.
	# With large text the page is taller than the phone: it scrolls under the
	# safe top, over the bottom bar that stays where the thumb is.
	var page: VBoxContainer = columns[0]
	if Settings.text_scale > 100:
		var safe := column.get_parent() as MarginContainer
		safe.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		safe.add_theme_constant_override("margin_top", UI.px(Tokens.number("size", "safe_top_points")))
		var scroll := ScrollContainer.new()
		scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
		scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
		page = VBoxContainer.new()
		page.mouse_filter = Control.MOUSE_FILTER_IGNORE
		page.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		page.add_theme_constant_override("separation", column.get_theme_constant("separation"))
		scroll.add_child(page)
		column.add_child(scroll)
	var card := VBoxContainer.new()
	card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var box := VBoxContainer.new()
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_theme_constant_override("separation", UI.px(4))
	card.add_child(box)
	kicker_label = FxSkin.label("", 14.0)
	kicker_label.add_theme_color_override("font_color", FxSkin.GOLD)
	kicker_label.add_theme_constant_override("outline_size", UI.px(3))
	grade_label = FxSkin.label("", UI.TITLE_POINTS + 26.0)
	grade_label.add_theme_font_override("font", Tokens.font("title"))
	# Warm cream, as the designs' title over its rays.
	grade_label.add_theme_color_override("font_color", Color("#FFF1CF"))
	grade_label.add_theme_constant_override("outline_size", UI.px(5))
	grade_label.add_theme_color_override("font_shadow_color", Color(FxSkin.INK_LINE, 0.9))
	grade_label.add_theme_constant_override("shadow_offset_y", UI.px(3))
	grade_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	condition_label = FxSkin.label("", UI.TEXT_POINTS)
	condition_label.add_theme_color_override("font_color", FxSkin.ON_DARK_SOFT)
	condition_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var chip := PanelContainer.new()
	chip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	chip.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	chip_label = FxSkin.label("", 15.0)
	# A pill as wide as its words; with large text it spans the page and its
	# words wrap there (a wrapping label in a shrunk pill has no width at all).
	if Settings.text_scale > 100:
		chip.size_flags_horizontal = Control.SIZE_FILL
		chip_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	chip.add_child(chip_label)
	subline_label = FxSkin.label("", 14.0)
	subline_label.add_theme_font_override("font", FxSkin.figures())
	subline_label.add_theme_color_override("font_color", FxSkin.ON_DARK_SOFT)
	detail_label = FxSkin.label("", UI.TEXT_POINTS)
	detail_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	check_label = FxSkin.label("", 13.0)
	check_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(kicker_label)
	box.add_child(grade_label)
	box.add_child(condition_label)
	box.add_child(chip)
	box.add_child(subline_label)
	# The haul on a parchment tile, counting up beside the loot's icon.
	haul_tile = UI.panel("parchment")
	haul_tile.mouse_filter = Control.MOUSE_FILTER_IGNORE
	haul_tile.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	# As the designs' reward tiles: the icon over the number over its name,
	# on cream rimmed in gold.
	haul_tile.custom_minimum_size.x = UI.px(118)
	HeistHud._gold_rim(haul_tile)
	var tile := VBoxContainer.new()
	tile.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tile.add_theme_constant_override("separation", 0)
	tile.alignment = BoxContainer.ALIGNMENT_CENTER
	var icon := Icons.view("resources/starlight", 30.0)
	icon.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	tile.add_child(icon)
	haul_label = FxSkin.label("", 24.0, "parchment")
	haul_label.add_theme_font_override("font", FxSkin.figures())
	tile.add_child(haul_label)
	var loot_word := FxSkin.label(Strings.t("RESULT_LOOT"), 14.0, "parchment")
	tile.add_child(loot_word)
	haul_tile.add_child(tile)
	box.add_child(haul_tile)
	counter = haul_tile
	reward_row = HBoxContainer.new()
	# With §20.8's large text the tiles stand one above another.
	if Settings.text_scale > 100:
		reward_row = VBoxContainer.new()
	reward_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	reward_row.alignment = BoxContainer.ALIGNMENT_CENTER
	reward_row.add_theme_constant_override("separation", UI.px(8))
	for r: Array in REWARDS:
		reward_row.add_child(_reward_tile(str(r[0]), Color(str(r[1]))))
	reward_row.visible = false
	box.add_child(reward_row)
	fee_label = FxSkin.label("", 14.0)
	fee_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	fee_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	fee_label.visible = false
	box.add_child(fee_label)
	rest_label = FxSkin.label("", 14.0)
	rest_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	rest_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	rest_label.add_theme_color_override("font_color", FxSkin.ON_DARK_SOFT)
	rest_label.visible = false
	box.add_child(rest_label)
	box.add_child(detail_label)
	box.add_child(check_label)
	page.add_child(card)
	# §12.13: the moment that decided it, with its replay a tap away.
	moment_card = UI.panel("card")
	# The play button beside the words; over them with large text, so the
	# words keep the card's width.
	var moment: BoxContainer = HBoxContainer.new()
	if Settings.text_scale > 100:
		moment = VBoxContainer.new()
	moment.mouse_filter = Control.MOUSE_FILTER_IGNORE
	moment.add_theme_constant_override("separation", UI.px(10))
	var words := VBoxContainer.new()
	words.mouse_filter = Control.MOUSE_FILTER_IGNORE
	words.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	moment_when = FxSkin.label("", 14.0)
	moment_when.add_theme_color_override("font_color", FxSkin.GOLD)
	moment_when.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	moment_when.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	moment_label = FxSkin.label("", UI.TEXT_POINTS)
	moment_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	moment_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	words.add_child(moment_when)
	words.add_child(moment_label)
	# The designs' square play button with the replay's length under it.
	var watch := UI.action("", _watch_moment, "leather", Strings.t("RESULT_WATCH"))
	watch.custom_minimum_size = Vector2(UI.px(60), UI.px(60))
	watch.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	watch.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	# Watching the moment is occasional, not one of the hand's frequent
	# controls §21.1's thumb zone binds; it stays with its words.
	watch.set_meta("frequent", false)
	UI.dress(watch, "leather", 14.0)
	var watch_box := VBoxContainer.new()
	watch_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	watch_box.alignment = BoxContainer.ALIGNMENT_CENTER
	watch_box.add_theme_constant_override("separation", 0)
	watch_box.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	watch_box.add_child(Icons.view("hud/play", 22.0))
	watch_box.add_child(FxSkin.label(Strings.t("RESULT_THREE_SECONDS"), 14.0))
	watch.add_child(watch_box)
	moment.add_child(watch)
	moment.add_child(words)
	moment_card.add_child(moment)
	moment_card.visible = false
	page.add_child(moment_card)
	# The designs' order: the outcome, the moment, then what it paid.
	var paid := VBoxContainer.new()
	paid.mouse_filter = Control.MOUSE_FILTER_IGNORE
	paid.add_theme_constant_override("separation", UI.px(4))
	for c: Control in [haul_tile, reward_row, fee_label, rest_label, detail_label, check_label]:
		c.reparent(paid)
	page.add_child(paid)
	# The design's order: what it paid, then the law to study.
	study_card = _study_card()
	page.add_child(study_card)
	var play: Dictionary = heist["workshop"]
	var plain: bool = not heist["testing"] and play.is_empty()
	# The plain result's bottom bar is one row, Home and the wide next raid;
	# the others wrap their several choices.
	var actions: Container = UI.row()
	if plain:
		actions = HBoxContainer.new()
	actions.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if plain:
		actions.add_theme_constant_override("separation", UI.px(8))
	if heist["testing"]:
		actions.add_child(_button(Strings.t("RESULT_WATCH"), func() -> void: App.services.router.go(&"replay"), "card"))
		actions.add_child(_button(Strings.t("RESULT_BUILDER"), func() -> void: App.services.router.go(&"builder")))
		# §18.6: a cleared rehearsal is the clear the Workshop publishes with.
		if WorkshopController.clears(heist["verdict"]) and not heist["published"]:
			actions.add_child(_button(Strings.t("RESULT_PUBLISH"), func() -> void:
				App.services.router.go(&"workshop", {"publish": true}), "gold"))
	elif not play.is_empty():
		actions.add_child(_button(Strings.t("COMMON_HOME"), func() -> void: App.services.router.go(&"home"), "card"))
		# §18.6: a play the server has checked may rate the island.
		var v: Dictionary = heist["verdict"]
		if v.get("ok", false) and v.get("server", false):
			actions.add_child(_button(Strings.t("RESULT_RATE"), func() -> void:
				App.services.router.go(&"workshop", {"rate": true})))
		again_button = _button(Strings.t("RESULT_AGAIN"), play_again.bind(str(play["id"])), "gold")
		actions.add_child(again_button)
	else:
		# The designs' bottom bar: Home, and the next raid as the main action,
		# wide, in gold (in red when the heist was foiled).
		actions.add_child(UI.action(Strings.t("COMMON_HOME"), func() -> void: App.services.router.go(&"home"),
			"leather"))
		var foiled := str((heist["verdict"] as Dictionary).get("grade", "")) == "Foiled"
		# The design's "Raid again", with how many of the roster are idle to
		# go (the roster's states) when it is known.
		var idle := idle_crew()
		var again_words := Strings.t("RESULT_RAID_AGAIN").to_upper()
		if idle >= 0:
			again_words += "\n" + Strings.t("RESULT_IDLE_CREW", idle)
		var again := UI.action(again_words, func() -> void:
			App.services.store.dispatch(&"heist_started", {})
			App.services.router.go(&"heist"), "red" if foiled else "gold")
		again.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		# Its words wrap rather than outgrow the phone with large text.
		again.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		again.custom_minimum_size.x = UI.px(UI.CONTROL_POINTS)
		actions.add_child(again)
	column.add_child(actions if plain else UI.narrow(actions))
	column.add_child(FxSkin.corner_clear())
	show_verdict(heist["verdict"], (heist["replay"] as PackedByteArray).size())
	# The coins fly over everything, into the card.
	if flight != null:
		add_child(flight)


## The island after the heist (§23.2's result: "Celebrate or learn"): the
## replay played to its end on the island it was played on, seen whole from
## the home camera's pitch, turning slowly, with the loot flying home. A
## replay this phone cannot load leaves the night sky behind the card.
func _build_world(heist: Dictionary) -> void:
	var bytes: PackedByteArray = heist["replay"]
	var r := RulebornReplay.new()
	if bytes.is_empty() or not r.load(bytes, heist.get("island", PackedByteArray())):
		# No island to stand on: the night behind the card.
		var sky := FxDraw.new(func(ci: Control) -> void:
			FxPen.rect(ci, Rect2(Vector2.ZERO, ci.size), FxSkin.CARD_BOTTOM))
		sky.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		add_child(sky)
		return
	_moments = ReplayScreen.moments(bytes, heist.get("island", PackedByteArray()))
	for p: Dictionary in r.pylons():
		if not _crossed.has(str(p["law"])):
			_crossed.append(str(p["law"]))
	while r.step():
		_peak = maxi(_peak, r.alarm())
	_ticks = r.tick()
	_crew_end = r.crew()
	world_view = WorldView.new()
	world_view.heist = false
	world_view.pitch = WorldView.HOME_PITCH
	world_view.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	world_view.anchor_bottom = 0.56
	# Under the title's rays, as the design's page: the island a quiet
	# backdrop, so the outcome reads first.
	world_view.modulate = Color(0.5, 0.45, 0.65)
	world_view.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(world_view)
	world_view.show_replay(r)
	world_view.set_zoom(1)
	world_view.describe()
	# The island as a diorama: no bars or marks over it.
	world_view.anchors.visible = false
	# A quiet backdrop: the guards stay out of it, the crew's island and
	# skiff are the picture (and §21.3's draw calls go to the page).
	for g: Node3D in world_view._guards:
		g.visible = false
	# A heist that paid: the crew that got away celebrates on the island,
	# where character models stand in for them.
	var v0: Dictionary = heist["verdict"]
	if v0.get("ok", false) and str(v0.get("grade", "")) in ["Clean", "Loud", "Partial"]:
		var crew := r.crew()
		world_view._sync_skiff(0.0)
		var aboard: Array[int] = []
		var deck: Vector3 = world_view._skiff.position if world_view._skiff.visible else Vector3.ZERO
		for i in world_view._crew.size():
			var actor := world_view._crew[i]
			actor.set_meta("pose", "celebrate")
			if i < crew.size() and str(crew[i]["standing"]) in ["Out", "Gone"] and world_view._skiff.visible:
				# Those who got away stand in the skiff that took them.
				var along := world_view._skiff.basis.x.normalized()
				var at := deck + along * ((i - (crew.size() - 1) * 0.5) * 0.55) + Vector3(0, 0.35, 0)
				world_view._to["c%d" % i] = at
				world_view._from["c%d" % i] = at
				actor.position = at
				actor.visible = true
				aboard.append(i)
		if not aboard.is_empty():
			# The camera comes close on the skiff and the crew in it, at the
			# heist's own pitch: the moment to celebrate.
			world_view.heist = true
			world_view.pitch = WorldView.HEIST_PITCH
			world_view.follow = aboard
			world_view.set_zoom(1)
	var v: Dictionary = heist["verdict"]
	_haul = int(v.get("banked", 0)) if v.get("ok", false) else 0
	flight = FxDraw.new(_draw_flight)
	flight.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)


## The page behind the outcome (the designs'): the night rising over the
## island's foot, and from behind the title a burst of gold rays turning
## slowly when the heist paid, a red dusk when it was foiled (§23.2's
## result: "Celebrate or learn").
func _draw_rays(ci: Control) -> void:
	var h := ci.size.y
	var top := h * 0.3
	var night := FxSkin.CARD_BOTTOM
	# The fade from the island into the night, in bands.
	for k in 12:
		var y := top + (h * 0.22) * k / 12.0
		FxPen.rect(ci, Rect2(0, y, ci.size.x, h * 0.22 / 12.0 + 1.0), Color(night, (k + 1) / 12.0))
	FxPen.rect(ci, Rect2(0, top + h * 0.22, ci.size.x, h), night)
	if grade_label == null or not grade_label.is_visible_in_tree():
		return
	var c := grade_label.get_global_rect().get_center() - ci.get_global_rect().position
	if str(_verdict.get("grade", "")) == "Foiled":
		for k in 10:
			FxPen.circle(ci, c, ci.size.x * (0.9 - k * 0.07), Color(FxSkin.ALARM_DEEP, 0.05))
		return
	if _haul <= 0:
		return
	var turn := 0.0 if Settings.reduced_motion else _clock * 0.05
	var reach := ci.size.x * 0.9
	for k in 18:
		var a := turn + TAU * k / 18.0
		var w := 0.07
		var pts := PackedVector2Array([c, c + Vector2(cos(a - w), sin(a - w)) * reach,
			c + Vector2(cos(a + w), sin(a + w)) * reach])
		FxPen.polygon(ci, pts, Color(1.0, 0.86, 0.45, 0.1 if k % 2 == 0 else 0.05))


## §21.8: "rewards fly into their counter": coins rise from the island and
## arc into the card, a few at a time, for as long as there is loot to bring
## home; reduced motion shows them resting in the card instead.
func _draw_flight(ci: Control) -> void:
	# The coins fly while the count rises, then rest: the page settles as
	# the design's does.
	if _haul <= 0 or counter == null or _clock > FLIGHT_SECONDS:
		return
	var to := counter.get_global_rect().get_center() - ci.get_global_rect().position
	to.x -= UI.px(24)
	var from := Vector2(ci.size.x * 0.5, ci.size.y * 0.3)
	var count := clampi(_haul / 40, 4, 14)
	var r := UI.px(5)
	if Settings.reduced_motion:
		for k in 3:
			FxIcons.coin(ci, to + Vector2((k - 1) * r * 2.4, -r * 2.0), r)
		return
	for k in count:
		var u := fmod(_clock * 0.55 + float(k) / count, 1.0)
		var side := (float(k % 5) - 2.0) * ci.size.x * 0.06
		var p := from.lerp(to, u) + Vector2(side * sin(u * PI), -sin(u * PI) * ci.size.y * 0.12)
		FxIcons.coin(ci, p, r * (0.7 + 0.5 * sin(u * PI)) * (1.0 - 0.4 * u))


func _process(delta: float) -> void:
	_clock += delta
	if world_view != null and not Settings.reduced_motion:
		# A slow sway of the island, the diorama on its stand.
		world_view.sway(sin(_clock * 0.25) * 0.5)
	if flight != null:
		flight.queue_redraw()
	if haul_label != null:
		# The haul counting up from nothing in a second (reduced motion: at
		# once).
		var shown := _haul if Settings.reduced_motion else int(_haul * clampf((_clock - 0.6) / 1.0, 0.0, 1.0))
		haul_label.text = "+%d" % shown
	if reward_row != null and reward_row.visible:
		_count_rewards(1.0 if Settings.reduced_motion else clampf((_clock - 0.6) / 1.0, 0.0, 1.0))
	for c in find_children("*", "FxDraw", true, false):
		(c as FxDraw).queue_redraw()


## The replay from three seconds before the moment (§12.13).
func _watch_moment() -> void:
	App.services.router.go(&"replay", {"from": int(_moment().get("tick", 0))})


## §12.13's moment that decided the heist, from its replay's moments: the
## first crew member caught when any was (Partial, Foiled), else the first
## guard alerted (Loud), else the Vault opening (Clean); {} when none.
func _moment() -> Dictionary:
	for kind: String in ["caught", "seen", "vault"]:
		for m in _moments:
			if str(m["kind"]) == kind:
				return m
	return {}


## The moment in words: what happened, to whom.
func _moment_words(m: Dictionary) -> String:
	match str(m.get("kind", "")):
		"caught":
			var who := int(m.get("who", 0))
			var role := str(_crew_end[who]["role"]) if who < _crew_end.size() else ""
			return Strings.t("RESULT_MOMENT_CAUGHT", Strings.term("ROLE", role))
		"seen":
			return Strings.t("RESULT_MOMENT_SEEN")
		"vault":
			return Strings.t("RESULT_MOMENT_VAULT")
	return Strings.t("RESULT_MOMENT_CLOCK")


## One of the design's reward tiles: the resource's icon over its number
## over its name, on cream rimmed in its colour; its number's label is kept
## by name.
func _reward_tile(kind: String, rim: Color) -> PanelContainer:
	var t := UI.panel("parchment")
	t.mouse_filter = Control.MOUSE_FILTER_IGNORE
	t.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var box := RbBox.of(t)
	if box != null and box.material is ShaderMaterial:
		(box.material as ShaderMaterial).set_shader_parameter("rim_color", rim)
		(box.material as ShaderMaterial).set_shader_parameter("rim_w", UI.px(3.5))
	var v := VBoxContainer.new()
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_theme_constant_override("separation", 0)
	var icon := Icons.view("resources/" + kind, 30.0)
	icon.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	v.add_child(icon)
	var n := FxSkin.label("", 22.0, "parchment")
	n.add_theme_font_override("font", FxSkin.figures())
	v.add_child(n)
	v.add_child(FxSkin.label(Strings.t("RESULT_" + kind.to_upper()), 14.0, "parchment"))
	t.add_child(v)
	reward_labels[kind] = n
	return t


## The server's split on the three tiles and the entry fee's line; the one
## haul tile when the answer has none (the phone's own check, a Workshop
## play).
func _show_rewards(v: Dictionary) -> void:
	var split: bool = v.get("ok", false) and v.has("starlight") and not v.get("workshop", false)
	# Foiled pays nothing: the chip says the Renown lost, and no tiles stand
	# (the design's foiled page).
	var paid := split and str(v.get("grade", "")) != "Foiled"
	reward_row.visible = paid
	fee_label.visible = split and int(v.get("fee", 0)) > 0
	if not split:
		return
	haul_tile.visible = false
	counter = reward_row
	for kind: String in reward_labels:
		(reward_labels[kind] as Label).set_meta("to", int(v.get(kind, 0)))
	_count_rewards(1.0)
	var fee := int(v["fee"])
	var back := int(v.get("fee_returned", 0))
	fee_label.text = Strings.t("RESULT_FEE_RETURNED", ShopPresenter.grouped(fee)) if back >= fee \
		else (Strings.t("RESULT_FEE_PAID", ShopPresenter.grouped(fee)) if back <= 0
		else Strings.t("RESULT_FEE_HALF", [ShopPresenter.grouped(fee), ShopPresenter.grouped(back)]))
	fee_label.add_theme_color_override("font_color", FxSkin.ON_DARK_SOFT if back > 0 else FxSkin.ALARM_ON_DARK)
	# §11.6: the crew home, resting as long as the server set (the design's
	# "What you kept").
	var rest: Variant = v.get("rest")
	rest_label.visible = rest is Dictionary and int(rest.get("crew", 0)) > 0
	if rest_label.visible:
		rest_label.text = Strings.t("RESULT_CREW_RESTING", [int(rest["crew"]), int(rest.get("minutes", 0))])


## How many of the roster's characters are idle, ready for the next raid;
## -1 when the roster has not been read.
static func idle_crew() -> int:
	var view: Dictionary = App.services.store.get_slice(RosterState.ROSTER).get("view", {})
	if not view.has("characters"):
		return -1
	return (view["characters"] as Array).filter(func(c: Dictionary) -> bool: return str(c["state"]) == "idle").size()


## The reward tiles' numbers at `share` of the way up from nothing, signed
## and grouped.
func _count_rewards(share: float) -> void:
	for kind: String in reward_labels:
		var l: Label = reward_labels[kind]
		var n := int(int(l.get_meta("to", 0)) * share)
		l.text = ("+" if n >= 0 else "-") + ShopPresenter.grouped(absi(n))


## §7.6's study, as the design's card: "Study one law you crossed" over a
## tile a law the crew crossed; a tap studies it, once, and the tile says the
## pages the server gave. Shown for a heist the server settled.
func _study_card() -> PanelContainer:
	var card := UI.panel("parchment")
	card.visible = false
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", UI.px(6))
	var title := FxSkin.label(Strings.t("RESULT_STUDY"), 15.0, "parchment")
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(title)
	var row := UI.row(6.0, true)
	for law: String in _crossed:
		var b := UI.action(Strings.term("LAW", law), func() -> void: _study(law), "parchment", Strings.term("LAW", law))
		b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		b.custom_minimum_size = Vector2(UI.px(96), UI.px(64))
		var icon := "laws/" + law.replace("_", "")
		if Icons.has(icon):
			b.icon = Icons.texture(icon)
			b.expand_icon = false
			b.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
			b.vertical_icon_alignment = VERTICAL_ALIGNMENT_TOP
			b.add_theme_constant_override("icon_max_width", UI.px(28))
		b.set_meta("law", law)
		row.add_child(b)
	box.add_child(row)
	card.add_child(box)
	return card


## Studies `law` on this heist, and says what the server answered: the pages
## given, on its tile; the others closed, as one heist allows one study.
func _study(law: String) -> void:
	var token := str(_verdict.get("token", ""))
	if token == "":
		return
	var answer: Result = await App.services.codex.study(token, law)
	if not is_inside_tree():
		return
	for b: Button in study_card.find_children("*", "Button", true, false):
		b.disabled = true
		if str(b.get_meta("law", "")) == law:
			b.text = "%s\n%s" % [Strings.term("LAW", law), Strings.t("RESULT_STUDIED", int(answer.value.get("pages", 0)))
				if answer.ok else Errors.message("RESULT_STUDY_FAILED", answer.code)]


## The raided Keeper's name (G58, §12.4's free fact), from the target card
## the planner opened on when it is this heist's, in the word lists' words;
## "" for a heist with none (a rehearsal, a generated target).
static func keeper_name() -> String:
	var store := App.services.store
	var card: Dictionary = store.get_slice(PlannerState.PLANNER).get("target", {})
	var raided: Dictionary = store.get_slice(AppState.HEIST).get("target", {})
	var named: Variant = card.get("keeper_name")
	if not named is Dictionary or str(card.get("bundle", "")) != str(raided.get("bundle", "-")):
		return ""
	var words: Dictionary = store.get_slice(ObservatoryState.OBSERVATORY).get("words", {})
	return SocialPresenter.word_name(words, int(named["adjective"]), int(named["noun"]))


## A result button in the heist's skin.
func _button(words: String, call: Callable, kind := "leather") -> Button:
	var b := UI.button(words, call)
	FxSkin.style_button(b, kind)
	UI.fit(b)
	return b


## The Workshop island again, on a new play: the button waits for the answer,
## and a refusal (withdrawn since, no network) is said here, not lost.
func play_again(id: String) -> void:
	again_button.disabled = true
	var heist := await App.services.workshop_flow.play(id)
	if not is_inside_tree():
		return
	if heist.is_empty():
		again_button.disabled = false
		UI.set_status(check_label, "alarm", Errors.message("WORKSHOP_FAILED",
			str(App.services.store.get_slice(WorkshopState.WORKSHOP)["error"])))
		return
	App.services.workshop_flow.start(heist)


func show_verdict(v: Dictionary, replay_bytes: int) -> void:
	_verdict = v
	var by_server: bool = v.get("server", false)
	_show_outcome(v)
	_show_rewards(v)
	# §7.6: a heist the server settled may study one law it crossed.
	if study_card != null:
		study_card.visible = v.get("ok", false) and v.get("server", false) and str(v.get("token", "")) != "" \
			and not _crossed.is_empty() and not v.get("confirming", false)
	if v.get("ok", false):
		grade_label.text = Strings.term("GRADE", str(v["grade"]))
		if v.get("workshop", false):
			# A Workshop play banks nothing: it clears the island or not, and a
			# clear counts once a player (§18.7).
			detail_label.text = Strings.t("WORKSHOP_CLEARED" if WorkshopController.clears(v)
				else "WORKSHOP_NOT_CLEARED")
			if by_server and WorkshopController.clears(v):
				detail_label.text += "\n" + Strings.t("RESULT_COUNTED" if v.get("counted", false) else "RESULT_NOT_COUNTED")
			check_label.text = Strings.t("RESULT_CONFIRMING" if v.get("confirming", false)
				else "RESULT_ACCEPTED_SERVER", replay_bytes)
		elif v.get("confirming", false):
			detail_label.text = Strings.t("RESULT_BANKED", int(v["banked"]))
			check_label.text = Strings.t("RESULT_CONFIRMING", replay_bytes)
		elif by_server:
			# The split's tiles say what was minted; without one, the line does.
			var lines := PackedStringArray()
			if not v.has("starlight"):
				lines.append(Strings.t("RESULT_BANKED_SERVER", [int(v["banked"]), int(v["haul"]), int(v["fee"])]))
			var keeper := KeeperPresenter.earned(v.get("keeper"))
			if keeper != "":
				lines.append(keeper)
			if v.get("gift", false):
				lines.append(Strings.t("RESULT_INVITE_GIFT"))
			detail_label.text = "\n".join(lines)
			check_label.text = Strings.t("RESULT_ACCEPTED_SERVER", replay_bytes)
		else:
			detail_label.text = Strings.t("RESULT_BANKED", int(v["banked"]))
			check_label.text = Strings.t("RESULT_ACCEPTED_LOCAL", replay_bytes)
		# The haul's count on the rule already says what was banked.
		detail_label.visible = detail_label.text != Strings.t("RESULT_BANKED", int(v["banked"])) \
			and detail_label.text != ""
		UI.set_status(check_label, "confirming" if v.get("confirming", false) else "success", check_label.text)
	else:
		grade_label.text = Strings.t("RESULT_NOT_ACCEPTED")
		detail_label.text = Errors.message("RESULT_REFUSED", str(v.get("refused", "")))
		# A Workshop play stakes and pays nothing: refused, it does not count.
		var nothing := "RESULT_PAID_NOTHING" if by_server else "RESULT_WOULD_PAY_NOTHING"
		UI.set_status(check_label, "alarm", Strings.t("RESULT_PLAY_NOT_COUNTED" if v.get("workshop", false) else nothing))


## §12.9's outcome in full: the kicker, the condition, what it multiplies,
## and the heist's length with the alarm's true peak; §12.13's moment under
## it. A Workshop play and a refusal show only their own lines.
func _show_outcome(v: Dictionary) -> void:
	var grade := str(v.get("grade", ""))
	var shown: bool = v.get("ok", false) and not v.get("workshop", false) and OUTCOME.has(grade)
	for l: Control in [kicker_label, condition_label, chip_label.get_parent(), subline_label]:
		l.visible = shown
	haul_tile.visible = _haul > 0
	if not shown:
		moment_card.visible = false
		return
	var row: Array = OUTCOME[grade]
	# The multipliers on a pill rimmed in gold, in red when foiled.
	var pill := StyleBoxFlat.new()
	pill.bg_color = Color(FxSkin.CARD_BOTTOM, 0.85)
	pill.border_color = FxSkin.ALARM if grade == "Foiled" else FxSkin.GOLD
	pill.set_border_width_all(UI.px(2))
	pill.set_corner_radius_all(UI.px(20))
	pill.content_margin_left = UI.px(14)
	pill.content_margin_right = UI.px(14)
	pill.content_margin_top = UI.px(4)
	pill.content_margin_bottom = UI.px(4)
	(chip_label.get_parent() as PanelContainer).add_theme_stylebox_override("panel", pill)
	chip_label.add_theme_color_override("font_color", FxSkin.ALARM_ON_DARK if grade == "Foiled" else FxSkin.GOLD)
	kicker_label.text = Strings.t("RESULT_KICKER_FOILED" if grade == "Foiled" else "RESULT_KICKER_DONE").to_upper()
	condition_label.text = Strings.t(row[0])
	chip_label.text = Strings.t("RESULT_FOILED_CHIP") if grade == "Foiled" else Strings.t("RESULT_MULTIPLIERS",
		[row[1], row[2]])
	var seconds := _ticks / RulebornReplay.ticks_per_second()
	subline_label.text = Strings.t("RESULT_SUBLINE", [seconds / 60, seconds % 60, _peak])
	var keeper := keeper_name()
	if keeper != "":
		subline_label.text = Strings.t("RESULT_KEEPER_REALM", keeper) + " · " + subline_label.text
	subline_label.visible = _ticks > 0
	var m := _moment()
	moment_card.visible = _ticks > 0
	var at := int(m.get("tick", _ticks)) / RulebornReplay.ticks_per_second()
	moment_when.text = Strings.t("RESULT_MOMENT", [at / 60, at % 60])
	moment_label.text = _moment_words(m)
