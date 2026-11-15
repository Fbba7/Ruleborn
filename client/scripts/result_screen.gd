class_name ResultScreen
extends Control
## What a heist came to (§23.2's result screen: "Grade, loot kept, … replay"),
## read from the check the server would make, never from what the device
## claims: the grade is the re-simulation's (§24.12). A cleared rehearsal
## offers to publish the island (§18.6); a Workshop play, to rate it.
##
## Built from the kit alone (key frame 03-result.png): the night with its
## sunburst behind the outcome, the hero title, the moment's card, the reward
## tiles, the study card, the crew home with their faces, and the bar of
## actions. Nothing here draws or styles a box of its own.

## The reward sequence has ended, or there was none (`start_reward`).
signal rewarded

## §12.9's outcomes: each one's condition and what it multiplies (the haul
## and Renown), as the document's table gives them.
const OUTCOME := {"Clean": ["RESULT_CONDITION_CLEAN", "1.0", "1.0"], "Loud": ["RESULT_CONDITION_LOUD", "0.7", "0.8"],
	"Partial": ["RESULT_CONDITION_PARTIAL", "0.4", "0.5"], "Foiled": ["RESULT_CONDITION_FOILED", "0", "0"]}

## Each reward and its material, as key frame 03: the Starlight haul on
## parchment and wider, the other two on glass.
const REWARDS := [["starlight", "parchment"], ["essence", "glass"], ["renown", "glass"]]
## How many of the crew's faces the rest card shows, apart and larger than
## key frame 03's stack (gate, Character presence), and how large, in points.
const FACES := 3
const FACE_POINTS := 52.0
## The outcome's medal beside its title, in points.
const MEDAL_POINTS := 34.0
const TITLE_POINTS := 40.0
## The reward's tier (the kit Motion's) for each outcome that pays.
const TIERS := {"Clean": "epic", "Loud": "rare", "Partial": "common"}
## The pause before the reward begins, in seconds.
const REWARD_WAIT := 0.6

var kicker_label: Label
var grade_label: Label
## The outcome's medal beside the title, hidden for a refusal.
var grade_icon: Control
## §12.9's condition under the outcome, and its multipliers on a pill.
var condition_label: Label
var chip_label: Label
var chip: PanelContainer
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
## §11.6: the crew home and how long it rests, as the server set it, beside
## the faces of the crew that ran the heist.
var rest_card: PanelContainer
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
## The island after the heist, a quiet picture under the sunburst.
var world_view: WorldView
## Where the reward lands: the haul's tile, or the row of the split.
var counter: Control
## Set before `_ready`, the screen waits for `start_reward` (a shot steps it).
var hold_reward := false
## The reward sequence while it plays.
var reward_tween: Tween
## The reward has ended, or there was none to play.
var reward_done := false
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
## F6: the page that scrolls, and the actions with the corner's clearance
## that end it, or the bar at the phone's foot they move to (_fit_actions).
var _scroll: ScrollContainer
var _foot: VBoxContainer
var _ending: Array[Control] = []


func _ready() -> void:
	App.ready(self)
	var heist: Dictionary = App.services.store.get_slice(AppState.HEIST)
	var v0: Dictionary = heist["verdict"]
	# The kit's frame: the night, and the column inside the safe areas. A
	# heist that paid turns the night to the sunburst behind its title; a
	# foiled or refused one keeps the plain night (§23.2: "Celebrate or
	# learn"). High contrast keeps the plain night, as key frame 03-result_hc:
	# no rays, stars or glow behind the words (AD's S1-R24, as Collect's
	# shine).
	var column := UI.frame(self)
	if v0.get("ok", false) and str(v0.get("grade", "")) in ["Clean", "Loud", "Partial"] \
			and not Settings.high_contrast:
		KitNav.celebrate(self)
	_build_world(heist)
	if world_view != null:
		# The island over the night and under the page.
		move_child(world_view, get_node("Sky").get_index() + 1)
	var page := UI.scroll(column)
	page.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_scroll = page.get_parent() as ScrollContainer
	page.add_child(_hero())
	# §12.13: the moment that decided it, with its replay a tap away.
	var moment := _moment_card()
	var paid := VBoxContainer.new()
	paid.mouse_filter = Control.MOUSE_FILTER_IGNORE
	paid.add_theme_constant_override("separation", UI.px(4))
	haul_tile = KitCards.reward("resources/starlight", "", Strings.t("RESULT_LOOT"), "gold")
	UI.dress(haul_tile, "parchment")
	haul_tile.mouse_filter = Control.MOUSE_FILTER_IGNORE
	haul_tile.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	haul_tile.custom_minimum_size.x = UI.px(118)
	haul_label = haul_tile.get_child(0).get_child(1) as Label
	ResultFit.tile_row(haul_tile)
	counter = haul_tile
	paid.add_child(haul_tile)
	var tiles: Array = []
	for r: Array in REWARDS:
		var t := KitCards.reward("resources/" + str(r[0]), "", Strings.t("RESULT_" + str(r[0]).to_upper()), "gold")
		UI.dress(t, str(r[1]))
		t.mouse_filter = Control.MOUSE_FILTER_IGNORE
		t.size_flags_stretch_ratio = 1.3 if r[0] == "starlight" else 1.0
		reward_labels[str(r[0])] = t.get_child(0).get_child(1)
		ResultFit.tile_row(t)
		tiles.append(t)
	# Side by side, as the design's; one above another with large text.
	reward_row = KitLayout.columns(tiles, 8)
	if Settings.text_scale > KitLayout.SIDE_BY_SIDE_UP_TO:
		# Rows one above another sit closer, so the third clears the dock.
		reward_row.add_theme_constant_override("separation", UI.px(4))
	reward_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	reward_row.visible = false
	paid.add_child(reward_row)
	fee_label = UI.label("", 14, true)
	fee_label.visible = false
	paid.add_child(fee_label)
	detail_label = UI.label("", UI.TEXT_POINTS, true)
	paid.add_child(detail_label)
	check_label = UI.label("", 13, true)
	paid.add_child(check_label)
	# The lines under the tiles stand on the night with no plate.
	for l: Label in [fee_label, detail_label, check_label]:
		_ink(l, float(l.get_meta("points", UI.TEXT_POINTS)))
	# The totals as the home's display figures: the lead deep gold, the
	# others cream (key frame 03's "1,288", "+46" and "+12").
	_display(haul_label, "starlight")
	for k: String in reward_labels:
		_display(reward_labels[k], "starlight" if k == "starlight" else "cream")
	# With large text the haul comes first, under the time line, and the
	# moment after it (key frame 03-result_text200_pt_BR; AD's S1-R24): the
	# first screen shows what the heist paid.
	if Settings.text_scale > KitLayout.SIDE_BY_SIDE_UP_TO:
		page.add_child(paid)
		page.add_child(moment)
	else:
		page.add_child(moment)
		page.add_child(paid)
	# The design's order: what it paid, the law to study, the crew home.
	study_card = _study_card()
	page.add_child(study_card)
	rest_card = _rest_card()
	page.add_child(rest_card)
	var play: Dictionary = heist["workshop"]
	# The plain result's bottom bar is one row, Home and the wide next raid,
	# on the kit's bar; the others wrap their several choices.
	var actions: Container = UI.row()
	actions.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var ending: Control = UI.narrow(actions)
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
		ending = _raid_bar(str(v0.get("grade", "")) == "Foiled")
	# F6: the actions follow what the heist paid, at the page's end, rather
	# than a bar at the phone's foot with an empty band above it. With large
	# text the bar stays at the foot, where the thumb is, under the page.
	_foot = column
	var corner := Control.new()
	corner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	corner.custom_minimum_size.y = UI.px(Tokens.number("size", "corner_points") + 10.0)
	_ending = [ending, corner]
	for c: Control in _ending:
		(column if Settings.text_scale > 100 else page).add_child(c)
	show_verdict(heist["verdict"], (heist["replay"] as PackedByteArray).size())
	_fit_raid()
	_fit_actions()
	# The numbers start from nothing when the reward will bring them.
	if _reward_to() > 0:
		_write_reward(0, _reward_to())
	if not hold_reward:
		create_tween().tween_callback(start_reward).set_delay(0.0 if Settings.reduced_motion else REWARD_WAIT)


## The outcome as the kit's hero (key frame 03): the kicker, the medal and
## the title, the condition, the multipliers on the gold-edged pill, and the
## heist's length with the alarm's peak.
func _hero() -> VBoxContainer:
	var hero := KitNav.hero(" ", " ", " ", " ")
	hero.mouse_filter = Control.MOUSE_FILTER_IGNORE
	kicker_label = hero.get_child(0) as Label
	grade_label = hero.get_child(1) as Label
	# Key frame 03's outcome is Marcellus at 40 points, under the kit hero's
	# 52, so the page keeps its crew's card above the fold.
	grade_label.add_theme_font_size_override("font_size", UI.text_px(TITLE_POINTS))
	grade_label.set_meta("points", TITLE_POINTS)
	condition_label = hero.get_child(2) as Label
	chip = hero.get_child(3) as PanelContainer
	chip_label = chip.find_child("Words", true, false) as Label
	# The medal beside the title, as the design's.
	var title_row := HBoxContainer.new()
	title_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	title_row.alignment = BoxContainer.ALIGNMENT_CENTER
	title_row.add_theme_constant_override("separation", UI.px(8))
	grade_icon = Icons.view("heistoutcomes/clean", MEDAL_POINTS)
	grade_icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	title_row.add_child(grade_icon)
	hero.remove_child(grade_label)
	title_row.add_child(grade_label)
	hero.add_child(title_row)
	hero.move_child(title_row, 1)
	subline_label = UI.label("", 14, true)
	subline_label.theme_type_variation = "Secondary"
	hero.add_child(subline_label)
	_ink(kicker_label, 14)  # The hero's words stand on the sunburst, unplated.
	_ink(grade_label, TITLE_POINTS)
	grade_label.add_theme_color_override("font_shadow_color", Color.TRANSPARENT)  # Outline for drop.
	_ink(condition_label, 16)
	_ink(subline_label, 14)
	return hero


## An ink outline round words on the art with no plate: 1.5 points or 12% of
## their size (§21.8), as `UI.world_words`; 3 points in high contrast.
static func _ink(l: Label, points: float) -> void:
	if Settings.high_contrast:
		points = maxf(points, 25.0)
	l.add_theme_color_override("font_outline_color", Tokens.color("ink_line"))
	l.add_theme_constant_override("outline_size", UI.px(maxf(1.5, 0.12 * points) + 0.5))


## A reward's total as the home's figures ("Keeper 24", `Home.home_figure`):
## the display face, `tone` (a tokens.json colour) filled solid, a heavy ink
## outline and a hard drop under it, alike on parchment and glass and in
## high contrast (board 4's objection A).
static func _display(l: Label, tone: String) -> void:
	var font_px := float(l.get_theme_font_size("font_size"))
	var line := maxi(UI.px(2.0), int(round(0.21 * font_px)))
	l.add_theme_font_override("font", RbTheme.role_font("display"))
	l.add_theme_color_override("font_color", Tokens.color(tone))
	l.add_theme_color_override("font_outline_color", Tokens.color("ink_line"))
	l.add_theme_constant_override("outline_size", line)
	l.add_theme_color_override("font_shadow_color", Tokens.color("drop"))
	l.add_theme_constant_override("shadow_offset_x", 0)
	l.add_theme_constant_override("shadow_offset_y", maxi(UI.px(1.5), int(round(0.08 * font_px))))
	l.add_theme_constant_override("shadow_outline_size", line)


## §12.13's moment on the kit's card: the gold play button with the replay's
## length on it, beside when and what happened; over them with large text,
## so the words keep the card's width.
func _moment_card() -> PanelContainer:
	moment_card = UI.panel("card")
	moment_card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var moment: BoxContainer
	if Settings.text_scale <= 100:
		moment = HBoxContainer.new()
	else:
		moment = VBoxContainer.new()
	moment.mouse_filter = Control.MOUSE_FILTER_IGNORE
	moment.add_theme_constant_override("separation", UI.px(12))
	var watch := KitControls.big_action("hud/play", Strings.t("RESULT_THREE_SECONDS"), _watch_moment, "gold")
	watch.accessibility_name = Strings.t("RESULT_WATCH")
	watch.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	watch.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	# Watching the moment is occasional, not one of the hand's frequent
	# controls §21.1's thumb zone binds; it stays with its words.
	watch.set_meta("frequent", false)
	# The kit's size, grown to the icon and words (at 200% "3 s" clipped).
	var inner := watch.get_child(0) as Control
	var least := watch.custom_minimum_size
	var grow := func() -> void:
		var pad := Vector2(UI.px(12), UI.px(10))
		watch.custom_minimum_size = least.max(inner.get_combined_minimum_size() + pad)
	inner.minimum_size_changed.connect(grow)
	grow.call()
	moment.add_child(watch)
	var words := VBoxContainer.new()
	words.mouse_filter = Control.MOUSE_FILTER_IGNORE
	words.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	words.alignment = BoxContainer.ALIGNMENT_CENTER
	moment_when = UI.label("", 14, true)
	moment_when.theme_type_variation = "Kicker"
	moment_when.uppercase = true
	moment_when.add_theme_color_override("font_color", Tokens.color("gold"))
	moment_when.set_meta("bold", true)
	moment_when.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	moment_label = UI.label("", UI.TEXT_POINTS, true)
	moment_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	words.add_child(moment_when)
	words.add_child(moment_label)
	moment.add_child(words)
	moment_card.add_child(moment)
	moment_card.visible = false
	return moment_card


## §11.6's crew home on the kit's card (key frame 03): the faces of the crew
## that ran the heist, each apart in its ring, beside how long it rests.
func _rest_card() -> PanelContainer:
	var card := UI.panel("glass")
	card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.visible = false
	var row := HBoxContainer.new()
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_theme_constant_override("separation", UI.px(6))
	var faces := HBoxContainer.new()
	faces.name = "Faces"
	faces.mouse_filter = Control.MOUSE_FILTER_IGNORE
	faces.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	# Apart, not overlapping: the key frame's stack read as one small strip.
	# The rings' own ink edges are the gaps (about 8 px between the gold
	# bands at 960), so the rest line keeps two lines (AD's S1-R24).
	faces.add_theme_constant_override("separation", 0)
	for m: Variant in _crew_end:
		if faces.get_child_count() >= FACES:
			break
		var kind := str((m as Dictionary).get("kind", "")) if m is Dictionary else ""
		# Played by role alone: the role's default kind, as the heist's
		# portraits show it (FxPortrait, Cast.KIND).
		if kind == "" and m is Dictionary and Cast.KIND.has(str((m as Dictionary).get("role", ""))):
			kind = String(Cast.KIND[str((m as Dictionary)["role"])])
		if kind == "" or not CreatureModel.manifest().has(kind.replace("_", "")):
			continue
		faces.add_child(_face(CreatureBust.of(kind, "", Color(0, 0, 0, 0))))
	faces.visible = faces.get_child_count() > 0
	row.add_child(faces)
	rest_label = UI.label("", 13, true)
	rest_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	rest_label.add_theme_constant_override("line_spacing", 0)
	rest_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	rest_label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(rest_label)
	card.add_child(row)
	return card


## One crew member's face in the kit's ring, framed as the kit's avatars
## frame theirs (KitSocial's), on the leather band.
func _face(picture: Texture2D) -> KitRing:
	var ring := KitRing.new()
	ring.name = "Face"
	ring.picture = picture
	ring.band = Tokens.color("gold")
	ring.ground = Tokens.paint("#4A3A9A")
	ring.zoom = 1.2
	ring.focus = Vector2(0.5, 0.42)
	ring.custom_minimum_size = Vector2.ONE * UI.px(FACE_POINTS)
	ring.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return ring


## The plain result's bar at the phone's foot (key frame 03): Home on
## parchment, and the next raid as the main action, wide, in gold (in red
## when the heist was foiled), with how many of the roster are idle to go.
func _raid_bar(foiled: bool) -> PanelContainer:
	# On glass, as the design's: the tab bar's skin runs off the screen at its
	# foot, and here the bar stands in the page.
	var bar := UI.panel("glass")
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	# A box that can stand upright (`_fit_raid`), side by side at first.
	var row := BoxContainer.new()
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_theme_constant_override("separation", UI.px(8))
	var home := UI.action(Strings.t("COMMON_HOME"), func() -> void: App.services.router.go(&"home"), "parchment")
	home.icon = Icons.texture("hud/home")
	home.expand_icon = false
	home.add_theme_constant_override("icon_max_width", UI.px(26))
	UI.fit(home)
	row.add_child(home)
	var idle := idle_crew()
	var again := KitControls.action2(Strings.t("RESULT_RAID_AGAIN"),
		Strings.t("RESULT_IDLE_CREW", idle) if idle >= 0 else "", func() -> void:
			App.services.store.dispatch(&"heist_started", {})
			App.services.router.go(&"heist"), "red" if foiled else "gold")
	again.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(again)
	bar.add_child(row)
	return bar


## The island after the heist (§23.2's result: "Celebrate or learn"): the
## replay played to its end on the island it was played on, seen whole from
## the home camera's pitch, turning slowly, quiet under the page. A replay
## this phone cannot load leaves the night alone.
func _build_world(heist: Dictionary) -> void:
	var bytes: PackedByteArray = heist["replay"]
	var r := RulebornReplay.new()
	if bytes.is_empty() or not r.load(bytes, heist.get("island", PackedByteArray())):
		return
	_moments = ReplayScreen.moments(bytes, heist.get("island", PackedByteArray()))
	for p: Dictionary in r.pylons():
		if not _crossed.has(str(p["law"])):
			_crossed.append(str(p["law"]))
	while r.step():
		_peak = maxi(_peak, r.alarm())
	_ticks = r.tick()
	_crew_end = r.crew()
	# High contrast keeps the night plain: no island, nor its sky's moon and
	# stars, behind the words (AD's S1-R24).
	if Settings.high_contrast:
		return
	world_view = WorldView.new()
	world_view.heist = false
	world_view.pitch = WorldView.HOME_PITCH
	world_view.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	# The island a faint picture through the night, as the design's: the
	# outcome and the page read first.
	world_view.modulate = Color(0.55, 0.5, 0.7, 0.3)
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


func _process(delta: float) -> void:
	_clock += delta
	if world_view != null and not Settings.reduced_motion:
		# A slow sway of the island, the diorama on its stand.
		world_view.sway(sin(_clock * 0.25) * 0.5)


## The reward (report.md step 8) on the kit's `Motion.reward`: the medal
## bursts and coins fly into the Starlight tile (else the haul's), the other
## tiles counting with it, in the outcome's tier (TIERS); its reduced form
## with reduced motion. With nothing to reward it ends at once and returns
## null; else it returns the sequence's tween.
func start_reward() -> Tween:
	var to := _reward_to()
	if to <= 0 or not grade_icon.visible or not is_inside_tree():
		_end_reward.call_deferred()
		return null
	var tile := _reward_mark()
	_write_reward(0, to)
	reward_tween = Motion.reward(grade_icon, tile, 0, to, str(TIERS.get(str(_verdict.get("grade", "")), "common")),
		_write_reward.bind(to))
	_lift_reward()
	reward_tween.finished.connect(_end_reward)
	return reward_tween


## Motion's reward layer is `top_level`, so its z of 10 does not add to the
## page's 32 and it drew under the tiles. Until the kit answers (S1-R21), it
## takes the medal's whole z plus its own.
func _lift_reward() -> void:
	var z := 0
	var node: Node = grade_icon
	while node is CanvasItem:
		z += (node as CanvasItem).z_index
		if not (node as CanvasItem).z_as_relative:
			break
		node = node.get_parent()
	for layer in grade_icon.get_children(true):
		if layer is CanvasItem and (layer as CanvasItem).top_level:
			(layer as CanvasItem).z_index = clampi(z + (layer as CanvasItem).z_index, RenderingServer.CANVAS_ITEM_Z_MIN,
				RenderingServer.CANVAS_ITEM_Z_MAX)


## Where the coins land and what pulses: the icon (its box's first child) by
## the Starlight number, else the haul's, so no coin hides the roll (AD's D).
func _reward_mark() -> Control:
	var number := (reward_labels["starlight"] as Label) if reward_row.visible else haul_label
	return number.get_parent().get_child(0) as Control


## What the coins bring: the split's Starlight, else the haul, else 0.
func _reward_to() -> int:
	if reward_row.visible:
		return int((reward_labels["starlight"] as Label).get_meta("to", 0))
	return _haul if haul_tile.visible else 0


## Starlight (or the haul) at `v` of `to`, the other tiles at that share.
func _write_reward(v: int, to: int) -> void:
	if reward_row.visible:
		_count_rewards(float(v) / float(maxi(to, 1)))
		(reward_labels["starlight"] as Label).text = "+" + ShopPresenter.grouped(v)
	else:
		haul_label.text = "+%d" % v


## The reward has ended: every number at its final value.
func _end_reward() -> void:
	if reward_done:
		return
	reward_done = true
	reward_tween = null
	if reward_row.visible:
		_count_rewards(1.0)
	haul_label.text = "+%d" % _haul
	rewarded.emit()


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
	ResultFit.reward_rows(reward_row, reward_labels, get_viewport_rect().size.x)
	var fee := int(v["fee"])
	var back := int(v.get("fee_returned", 0))
	var said := Strings.t("RESULT_FEE_RETURNED", ShopPresenter.grouped(fee)) if back >= fee \
		else (Strings.t("RESULT_FEE_PAID", ShopPresenter.grouped(fee)) if back <= 0
		else Strings.t("RESULT_FEE_HALF", [ShopPresenter.grouped(fee), ShopPresenter.grouped(back)]))
	# A fee lost is the kit's alarm line; one returned, a quiet line.
	if back <= 0:
		UI.set_status(fee_label, "alarm", said)
	else:
		fee_label.theme_type_variation = "Secondary"
		fee_label.text = said
	# §11.6: the crew home, resting as long as the server set (the design's
	# "What you kept").
	var rest: Variant = v.get("rest")
	rest_label.visible = rest is Dictionary and int(rest.get("crew", 0)) > 0
	rest_card.visible = rest_label.visible
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
	var card := UI.panel("card")
	card.visible = false
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", UI.px(8))
	# The header as the hero's kicker: small capitals over the laws.
	var title := UI.label(Strings.t("RESULT_STUDY"), 14, true)
	title.theme_type_variation = "Kicker"
	title.uppercase = true
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	title.set_meta("bold", true)
	box.add_child(title)
	# The laws side by side on parchment, each an equal share, its icon then
	# its name, which wraps between words; stacked at large text. More than
	# three go two to a row.
	var laws: Array[Control] = []
	for law: String in _crossed:
		var b := UI.action(Strings.term("LAW", law), func() -> void: _study(law), "parchment", Strings.term("LAW", law))
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		# A law's name in the title family, as the key frame's law papers and
		# the kit's law names (type role "heading"), at body size.
		b.add_theme_font_override("font", RbTheme.role_font("heading"))
		b.set_meta("bold", false)
		# Six points of paper either side of the words, not a pill's nine, so
		# three laws share a row.
		for state: String in ["normal", "hover", "pressed", "focus", "disabled"]:
			b.add_theme_stylebox_override(state, UI.clear_box(6, 4))
		b.autowrap_mode = TextServer.AUTOWRAP_WORD
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		# No width of its own (UI.action fits one to the words), so each law
		# takes an equal share of the row.
		b.custom_minimum_size = Vector2(0, UI.px(52))
		var icon := "laws/" + law.replace("_", "")
		if Icons.has(icon):
			b.icon = Icons.texture(icon)
			b.expand_icon = false
			b.icon_alignment = HORIZONTAL_ALIGNMENT_LEFT
			b.add_theme_constant_override("icon_max_width", UI.px(24))
		b.set_meta("law", law)
		laws.append(b)
	var grid: Container
	if laws.size() <= 3:
		grid = KitLayout.columns(laws, 6.0)
	else:
		grid = KitLayout.grid(2)
		for b: Control in laws:
			grid.add_child(b)
	box.add_child(grid)
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


## A result button in the kit's material.
func _button(words: String, call: Callable, kind := "leather") -> Button:
	var b := UI.action(words, call, kind)
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
	if is_node_ready():
		_fit_actions()
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
			check_label.text = _verdict_line("RESULT_CONFIRMING" if v.get("confirming", false)
				else "RESULT_ACCEPTED_SERVER", replay_bytes)
		elif v.get("confirming", false):
			detail_label.text = Strings.t("RESULT_BANKED", int(v["banked"]))
			check_label.text = _verdict_line("RESULT_CONFIRMING", replay_bytes)
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
			check_label.text = _verdict_line("RESULT_ACCEPTED_SERVER", replay_bytes)
		else:
			detail_label.text = Strings.t("RESULT_BANKED", int(v["banked"]))
			check_label.text = _verdict_line("RESULT_ACCEPTED_LOCAL", replay_bytes)
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


## F6: the actions end the page while it fits on the phone; a page taller
## than the phone (a long language over the study card, say) leaves them in
## the bar at its foot, under the page that scrolls, as large text does. Once
## moved they stay: the page only grows (a verdict that arrives later).
func _fit_actions() -> void:
	if _ending.is_empty():
		return
	# The wrapped lines' heights are known once the page is laid out.
	await get_tree().process_frame
	await get_tree().process_frame
	if not is_inside_tree():
		return
	var laws := _fit_laws()
	if _fit_raid() or laws:
		await get_tree().process_frame
		await get_tree().process_frame
	var page := _ending[0].get_parent() as Control
	if Settings.text_scale > 100 and reward_row.visible and page == _foot:
		ResultFit.hero_shrink([[kicker_label, 14.0], [grade_label, TITLE_POINTS], [condition_label, 16.0],
			[subline_label, 14.0]], reward_labels.values(), _ending[0])
	if not is_inside_tree() or page == _foot or page.get_combined_minimum_size().y <= _scroll.size.y:
		return
	for c: Control in _ending:
		c.reparent(_foot)


## The laws to study two to a row, rather than side by side, when a law's
## longest word is wider than its share of the row (German's and
## Portuguese's long names). True when they moved.
func _fit_laws() -> bool:
	var row := study_card.find_child("Columns", true, false) as HBoxContainer
	if row == null:
		return false
	var fits := true
	for b: Button in row.get_children():
		fits = fits and ResultFit.word_fits(b)
	if fits:
		return false
	var grid := KitLayout.grid(2)
	row.add_sibling(grid)
	for b: Button in row.get_children():
		b.reparent(grid, false)
	row.queue_free()
	return true


## The next raid's words wrapped, the button as tall as they are, when they
## are wider than the room Home leaves it (large text, a long language); and
## the raid above Home, the bar's width, when one of its words alone is
## wider than that room. True when either changed.
func _fit_raid() -> bool:
	var again := _ending[0].find_child("Action", true, false) as Button
	if again == null or again.has_meta("wrapped"):
		return false
	var row := again.get_parent() as BoxContainer
	if row == null:
		return false
	# Less a margin of paper either side, so a long word does not meet the
	# button's edge.
	var pad := again.get_theme_stylebox("normal").get_minimum_size().x + UI.px(16)
	# The rooms as the column will lay them out, the phone's width less its
	# safe sides and the bar's padding, and that less Home's: measured rather
	# than read from the layout, so the bar is fitted before its first frame
	# and never shows unfitted.
	var full := get_viewport_rect().size.x - 2.0 * UI.px(Tokens.number("size", "safe_side_points")) \
		- (row.get_parent() as Control).get_theme_stylebox("panel").get_minimum_size().x
	var wide := full
	for c: Control in row.get_children():
		# Large text: Home as its icon on a square beside the raid, named
		# aloud, in every language, as key frames 03-result_text200 and
		# _pt_BR, so the raid leads the bar (board 4's objection E).
		if c != again and c is Button and Settings.text_scale > 100:
			ResultFit.home_square(c as Button)
		if c != again:
			wide -= c.get_combined_minimum_size().x + row.get_theme_constant("separation")
	var words := again.find_children("*", "Label", true, false)
	var upright := not ResultFit.words_fit(words, wide - pad)
	if upright:
		row.vertical = true
		row.move_child(again, 0)
		wide = full
	var lines := 0.0
	var wraps := false
	for l: Label in words:
		var n := ResultFit.lines(l, wide - pad)
		wraps = wraps or n > 1
		lines += n * l.get_theme_font("font").get_height(l.get_theme_font_size("font_size"))
	if not wraps and not upright:
		return false
	again.set_meta("wrapped", true)
	for l: Label in words:
		l.autowrap_mode = TextServer.AUTOWRAP_WORD
	# The words' box (KitControls.action2's, over the whole button) in from
	# either side, so they wrap within the room.
	for v: Control in again.get_children():
		v.offset_left = pad / 2.0
		v.offset_right = -pad / 2.0
	again.custom_minimum_size.y = maxf(again.custom_minimum_size.y, lines * 1.1 + UI.px(12))
	return true


## The verdict's line as the player reads it (F6): the check and what it
## found, without the replay's size in bytes, which is the developer's. The
## accepted lines carry the size on a line of their own, which is dropped;
## the confirming line carries it inline and keeps it until its string loses
## it (request S1-R13).
func _verdict_line(key: String, replay_bytes: int) -> String:
	return Strings.t(key, replay_bytes).split("\n")[0]


## §12.9's outcome in full (kicker, medal, condition, multipliers, length and
## peak) and §12.13's moment; a Workshop play or a refusal only its own lines.
func _show_outcome(v: Dictionary) -> void:
	var grade := str(v.get("grade", ""))
	var shown: bool = v.get("ok", false) and not v.get("workshop", false) and OUTCOME.has(grade)
	for l: Control in [kicker_label, condition_label, chip, subline_label]:
		l.visible = shown
	haul_tile.visible = _haul > 0
	haul_label.text = "+%d" % _haul
	# The medal for a graded heist; a refusal has none.
	var medal := "heistoutcomes/" + grade.to_lower()
	grade_icon.visible = v.get("ok", false) and Icons.has(medal)
	if grade_icon.visible:
		(grade_icon as TextureRect).texture = Icons.texture(medal)
	_fit_title.call_deferred()
	if not shown:
		moment_card.visible = false
		return
	var row: Array = OUTCOME[grade]
	# The multipliers on the kit's gold-edged pill; on its alarm tag when
	# foiled.
	if grade == "Foiled":
		UI.dress(chip, "tag_alarm", 999)
	KitStatus.set_pill(chip, Strings.t("RESULT_FOILED_CHIP") if grade == "Foiled" else Strings.t("RESULT_MULTIPLIERS",
		[row[1], row[2]]))
	if Settings.text_scale > 100 and not ResultFit.chip_on_one_line(chip, chip_label, get_viewport_rect().size.x):
		# Large text: the pill's words wrap onto more lines instead of
		# trailing off, when even its narrow form does not fit.
		chip_label.clip_text = false
		chip_label.text_overrun_behavior = TextServer.OVERRUN_NO_TRIMMING
		chip_label.custom_minimum_size.x = 0
		chip_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		chip_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		chip.size_flags_horizontal = Control.SIZE_FILL
		# Each part kept whole ("Renown ×1.0", "Renown −8"): the pill breaks
		# only at its dots.
		var parts := Array(chip_label.text.split(" · ")).map(func(part: String) -> String:
			return part.replace(" ", "\u00A0"))
		chip_label.text = " · ".join(parts)
	kicker_label.text = Strings.t("RESULT_KICKER_FOILED" if grade == "Foiled" else "RESULT_KICKER_DONE")
	condition_label.text = Strings.t(row[0])
	var seconds := _ticks / RulebornReplay.ticks_per_second()
	# F6: "alarm 5 / 6" under "No guard alerted" read as a contradiction.
	# The peak is the realm's ladder (§12.17), which climbs with time whatever
	# the crew does, so the line names it as that: the length, then the
	# realm alarm's true peak (§12.9).
	subline_label.text = "%d:%02d" % [seconds / 60, seconds % 60] + " · " + Strings.t("DEFENCES_ALARM", _peak)
	var keeper := keeper_name()
	if keeper != "":
		subline_label.text = Strings.t("RESULT_KEEPER_REALM", keeper) + " · " + subline_label.text
	subline_label.visible = _ticks > 0
	var m := _moment()
	moment_card.visible = _ticks > 0
	var at := int(m.get("tick", _ticks)) / RulebornReplay.ticks_per_second()
	moment_when.text = Strings.t("RESULT_MOMENT", [at / 60, at % 60])
	moment_label.text = _moment_words(m)


## The title on one line beside its medal while it fits the phone's width;
## a title too long for that (a long language) wraps under no medal.
func _fit_title() -> void:
	if not is_inside_tree() or grade_label == null:
		return
	var font := grade_label.get_theme_font("font")
	var size := grade_label.get_theme_font_size("font_size")
	var wide := font.get_string_size(grade_label.text, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
	var room := get_viewport_rect().size.x - 2.0 * UI.px(Tokens.number("size", "safe_side_points")) - UI.px(20)
	var medal := 0.0
	if grade_icon.visible:
		medal = float(UI.px(MEDAL_POINTS) + UI.px(8))
	if wide + medal <= room:
		grade_label.autowrap_mode = TextServer.AUTOWRAP_OFF
		grade_label.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		return
	grade_icon.visible = false
	grade_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	grade_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
