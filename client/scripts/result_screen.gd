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
var detail_label: Label
var check_label: Label
## A Workshop play's Again, which waits for the island's answer.
var again_button: Button
## The island after the heist, and the coins flying home over it.
var world_view: WorldView
var flight: FxDraw
## The haul's number on the card, where the coins land.
var counter: FxDraw
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
	var column := FxSkin.frame(self)[1]
	# The outcome on parchment, as the designs' result card: the grade in
	# Lilita One, outlined, then what was banked and how it was checked.
	# Rays behind the card when the heist paid: the moment to celebrate.
	column.add_child(FxDraw.new(_draw_rays, Vector2(0, UI.px(8))))
	var card := FxSkin.panel("parchment", 22.0, 14.0)
	var box := VBoxContainer.new()
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_theme_constant_override("separation", UI.px(4))
	card.add_child(box)
	kicker_label = FxSkin.label("", 13.0, "parchment")
	kicker_label.add_theme_color_override("font_color", FxSkin.GOLD_INK)
	grade_label = FxSkin.label("", UI.TITLE_POINTS + 18.0, "parchment", true)
	condition_label = FxSkin.label("", UI.TEXT_POINTS, "parchment")
	condition_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var chip := FxSkin.panel("card", 12.0, 8.0)
	chip.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	chip_label = FxSkin.label("", 13.0)
	chip.add_child(chip_label)
	subline_label = FxSkin.label("", 13.0, "parchment")
	subline_label.add_theme_font_override("font", FxSkin.figures())
	detail_label = FxSkin.label("", UI.TEXT_POINTS, "parchment")
	detail_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	check_label = FxSkin.label("", 13.0, "parchment")
	check_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(kicker_label)
	# The grade's stars over it: three for Clean, down to none for Foiled.
	box.add_child(FxDraw.new(_draw_stars, Vector2(0, UI.px(30))))
	box.add_child(grade_label)
	box.add_child(condition_label)
	box.add_child(chip)
	box.add_child(subline_label)
	# The haul, counting up beside a coin, on the rule under the grade.
	counter = FxDraw.new(_draw_rule, Vector2(0, UI.px(34)))
	box.add_child(counter)
	box.add_child(detail_label)
	box.add_child(check_label)
	column.add_child(card)
	# §12.13: the moment that decided it, with its replay a tap away.
	moment_card = FxSkin.panel("card", 18.0, 12.0)
	var moment := HBoxContainer.new()
	moment.mouse_filter = Control.MOUSE_FILTER_IGNORE
	moment.add_theme_constant_override("separation", UI.px(10))
	var words := VBoxContainer.new()
	words.mouse_filter = Control.MOUSE_FILTER_IGNORE
	words.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	moment_when = FxSkin.label("", 13.0)
	moment_when.add_theme_color_override("font_color", FxSkin.ON_DARK_SOFT)
	moment_when.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	moment_label = FxSkin.label("", UI.TEXT_POINTS)
	moment_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	moment_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	words.add_child(moment_when)
	words.add_child(moment_label)
	var watch := FxSkin.icon_button(Strings.t("RESULT_WATCH"), _watch_moment, "play", "gold")
	watch.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	moment.add_child(watch)
	moment.add_child(words)
	moment.add_child(FxDraw.new(_draw_crew, Vector2(UI.px(30) * 3.2, UI.px(48))))
	moment_card.add_child(moment)
	moment_card.visible = false
	column.add_child(moment_card)
	var actions := UI.row()
	actions.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var play: Dictionary = heist["workshop"]
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
		# The designs' bottom bar: Home, and the next raid as the main action.
		actions.add_child(_button(Strings.t("COMMON_HOME"), func() -> void: App.services.router.go(&"home"), "card"))
		var again := _button(Strings.t("RESULT_AGAIN"), func() -> void:
			App.services.store.dispatch(&"heist_started", {})
			App.services.router.go(&"heist"), "gold")
		again.custom_minimum_size.x = UI.px(170)
		actions.add_child(again)
	column.add_child(UI.narrow(actions))
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
	var sky := FxDraw.new(func(ci: Control) -> void:
		FxPen.rect(ci, Rect2(Vector2.ZERO, ci.size), FxSkin.CARD_BOTTOM))
	sky.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(sky)
	var bytes: PackedByteArray = heist["replay"]
	var r := RulebornReplay.new()
	if bytes.is_empty() or not r.load(bytes, heist.get("island", PackedByteArray())):
		return
	_moments = ReplayScreen.moments(bytes, heist.get("island", PackedByteArray()))
	while r.step():
		_peak = maxi(_peak, r.alarm())
	_ticks = r.tick()
	_crew_end = r.crew()
	world_view = WorldView.new()
	world_view.heist = false
	world_view.pitch = WorldView.HOME_PITCH
	world_view.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	world_view.anchor_bottom = 0.62
	world_view.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(world_view)
	world_view.show_replay(r)
	world_view.set_zoom(1)
	world_view.describe()
	# The island as a diorama: no bars or marks over it.
	world_view.anchors.visible = false
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


## A burst of gold rays rising behind the card, turning slowly, when the
## heist banked loot (§23.2's result: "Celebrate or learn").
func _draw_rays(ci: Control) -> void:
	if _haul <= 0:
		return
	var c := Vector2(ci.size.x * 0.5, ci.size.y + UI.px(60))
	var turn := 0.0 if Settings.reduced_motion else _clock * 0.15
	var reach := ci.size.x * 0.62
	for k in 9:
		var a := PI + fmod(turn + PI * (k + 0.5) / 9.0, PI)
		var w := 0.09
		var pts := PackedVector2Array([c, c + Vector2(cos(a - w), sin(a - w)) * reach,
			c + Vector2(cos(a + w), sin(a + w)) * reach])
		FxPen.polygon(ci, pts, Color(1.0, 0.86, 0.45, 0.26 if k % 2 == 0 else 0.14))


## The stars a grade earns, gold for each earned and hollow for the rest,
## the middle one larger; they pop in one by one (none with reduced motion).
func _draw_stars(ci: Control) -> void:
	var grade := str(_verdict.get("grade", "")) if _verdict.get("ok", false) else ""
	if grade == "":
		return
	var earned: int = {"Clean": 3, "Loud": 2, "Partial": 1}.get(grade, 0)
	var c := Vector2(ci.size.x * 0.5, ci.size.y * 0.55)
	for k in 3:
		var big := 1.25 if k == 1 else 1.0
		var r := ci.size.y * 0.42 * big
		var at := c + Vector2((k - 1) * ci.size.y * 1.15, -ci.size.y * 0.12 if k == 1 else 0.0)
		var pop := 1.0 if Settings.reduced_motion else clampf((_clock - 0.3 - k * 0.25) * 5.0, 0.0, 1.0)
		if k < earned:
			FxIcons.star(ci, at, r * pop * (1.0 + 0.15 * sin(clampf(pop, 0, 1) * PI)), FxSkin.GOLD)
		else:
			FxIcons.star(ci, at, r, Color("#D9CBB0"))


## A thin ink rule under the grade, and on it the haul in Lilita One beside a
## coin, counting up from nothing in a second (reduced motion: at once).
func _draw_rule(ci: Control) -> void:
	var y := ci.size.y * 0.5
	if _haul <= 0:
		FxPen.line(ci, Vector2(ci.size.x * 0.12, y), Vector2(ci.size.x * 0.88, y), FxSkin.PARCH_INK, 2.0, true)
		return
	var shown := _haul if Settings.reduced_motion else int(_haul * clampf((_clock - 0.6) / 1.0, 0.0, 1.0))
	var font := FxSkin.numbers()
	var px := int(ci.size.y * 0.95)
	var words := "+%d" % shown
	var w := font.get_string_size(words, HORIZONTAL_ALIGNMENT_LEFT, -1, px).x
	var r := ci.size.y * 0.36
	var x := ci.size.x * 0.5 - (w + r * 2.6) * 0.5
	FxPen.line(ci, Vector2(ci.size.x * 0.06, y), Vector2(x - r, y), FxSkin.PARCH_INK, 2.0, true)
	FxPen.line(ci, Vector2(x + w + r * 3.6, y), Vector2(ci.size.x * 0.94, y), FxSkin.PARCH_INK, 2.0, true)
	FxIcons.coin(ci, Vector2(x + r, y), r)
	var base := Vector2(x + r * 2.6, y + px * 0.36)
	FxPen.string_outline(ci, font, base, words, HORIZONTAL_ALIGNMENT_LEFT, -1, px, maxi(4, px / 6), FxSkin.INK_LINE)
	FxPen.string(ci, font, base, words, HORIZONTAL_ALIGNMENT_LEFT, -1, px, FxSkin.GOLD)


## §21.8: "rewards fly into their counter": coins rise from the island and
## arc into the card, a few at a time, for as long as there is loot to bring
## home; reduced motion shows them resting in the card instead.
func _draw_flight(ci: Control) -> void:
	if _haul <= 0 or counter == null:
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


## The crew as the heist ended, a face each: ringed green when it got out,
## greyed with a red ring when it was caught.
func _draw_crew(ci: Control) -> void:
	var n := _crew_end.size()
	if n == 0:
		return
	var r := minf(ci.size.y * 0.42, ci.size.x / (n * 2.1))
	# Discs, then faces, then rings: each pass one draw.
	for step in 3:
		for i in n:
			var m: Dictionary = _crew_end[i]
			var c := Vector2(ci.size.x - r * 1.05 - (n - 1 - i) * r * 1.7, ci.size.y * 0.5)
			var caught := str(m["standing"]) == "Caught"
			var role := str(m["role"])
			var picture: Texture2D = Portrait.of(String(Cast.KIND[role])) if Cast.KIND.has(role) else null
			match step:
				0:
					FxPen.circle(ci, c, r + UI.px(1.5), FxSkin.INK_LINE)
					FxPen.circle(ci, c, r, Color(Palette.ROLE.get(role, Palette.STONE)).darkened(0.6 if caught else 0.25))
					if picture == null:
						FxIcons.face(ci, c + Vector2(0, r * 0.1), r * 0.6, Palette.ROLE.get(role, Palette.STONE), role,
							caught)
				1:
					if picture != null:
						FxPen.texture_rect(ci, picture, Rect2(c - Vector2(r, r) * 0.9, Vector2(r, r) * 1.8), false,
							Color(0.5, 0.5, 0.55) if caught else Color.WHITE)
				2:
					var out := str(m["standing"]) == "Out"
					var ring := FxSkin.ALARM if caught else (FxSkin.SUCCESS if out else FxSkin.ON_DARK_SOFT)
					FxPen.arc(ci, c, r, 0.0, TAU, 32, ring, UI.px(2.5))


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
			detail_label.text = Strings.t("RESULT_BANKED_SERVER", [int(v["banked"]), int(v["haul"]), int(v["fee"])])
			var keeper := KeeperPresenter.earned(v.get("keeper"))
			if keeper != "":
				detail_label.text += "\n" + keeper
			if v.get("gift", false):
				detail_label.text += "\n" + Strings.t("RESULT_INVITE_GIFT")
			check_label.text = Strings.t("RESULT_ACCEPTED_SERVER", replay_bytes)
		else:
			detail_label.text = Strings.t("RESULT_BANKED", int(v["banked"]))
			check_label.text = Strings.t("RESULT_ACCEPTED_LOCAL", replay_bytes)
		# The haul's count on the rule already says what was banked.
		detail_label.visible = not (detail_label.text == Strings.t("RESULT_BANKED", int(v["banked"])) and _haul > 0)
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
	if not shown:
		moment_card.visible = false
		return
	var row: Array = OUTCOME[grade]
	kicker_label.text = Strings.t("RESULT_KICKER_FOILED" if grade == "Foiled" else "RESULT_KICKER_DONE").to_upper()
	condition_label.text = Strings.t(row[0])
	chip_label.text = Strings.t("RESULT_FOILED_CHIP") if grade == "Foiled" else Strings.t("RESULT_MULTIPLIERS",
		[row[1], row[2]])
	var seconds := _ticks / RulebornReplay.ticks_per_second()
	subline_label.text = Strings.t("RESULT_SUBLINE", [seconds / 60, seconds % 60, _peak])
	subline_label.visible = _ticks > 0
	var m := _moment()
	moment_card.visible = _ticks > 0
	var at := int(m.get("tick", _ticks)) / RulebornReplay.ticks_per_second()
	moment_when.text = Strings.t("RESULT_MOMENT", [at / 60, at % 60])
	moment_label.text = _moment_words(m)
