class_name ResultScreen
extends Control
## What a heist came to (§23.2's result screen: "Grade, loot kept, … replay"),
## read from the check the server would make, never from what the device
## claims: the grade is the re-simulation's (§24.12). A cleared rehearsal
## offers to publish the island (§18.6); a Workshop play, to rate it.

var grade_label: Label
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
	box.add_theme_constant_override("separation", UI.px(6))
	card.add_child(box)
	grade_label = FxSkin.label("", UI.TITLE_POINTS + 8.0, "parchment", true)
	detail_label = FxSkin.label("", UI.TEXT_POINTS, "parchment")
	detail_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	check_label = FxSkin.label("", 14.0, "parchment")
	check_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	# The grade's stars over it: three for Clean, down to none for Foiled.
	box.add_child(FxDraw.new(_draw_stars, Vector2(0, UI.px(30))))
	box.add_child(grade_label)
	# The haul, counting up beside a coin, on the rule under the grade.
	counter = FxDraw.new(_draw_rule, Vector2(0, UI.px(30)))
	box.add_child(counter)
	box.add_child(detail_label)
	box.add_child(check_label)
	column.add_child(card)
	var actions := UI.row()
	actions.mouse_filter = Control.MOUSE_FILTER_IGNORE
	actions.add_child(_button(Strings.t("RESULT_WATCH"), func() -> void: App.services.router.go(&"replay"), "gold"))
	var play: Dictionary = heist["workshop"]
	if heist["testing"]:
		actions.add_child(_button(Strings.t("RESULT_BUILDER"), func() -> void: App.services.router.go(&"builder")))
		# §18.6: a cleared rehearsal is the clear the Workshop publishes with.
		if WorkshopController.clears(heist["verdict"]) and not heist["published"]:
			actions.add_child(_button(Strings.t("RESULT_PUBLISH"), func() -> void:
				App.services.router.go(&"workshop", {"publish": true})))
	elif not play.is_empty():
		# §18.6: a play the server has checked may rate the island.
		var v: Dictionary = heist["verdict"]
		if v.get("ok", false) and v.get("server", false):
			actions.add_child(_button(Strings.t("RESULT_RATE"), func() -> void:
				App.services.router.go(&"workshop", {"rate": true})))
		again_button = _button(Strings.t("RESULT_AGAIN"), play_again.bind(str(play["id"])))
		actions.add_child(again_button)
	else:
		actions.add_child(_button(Strings.t("RESULT_AGAIN"), func() -> void:
			App.services.store.dispatch(&"heist_started", {})
			App.services.router.go(&"heist")))
	actions.add_child(_button(Strings.t("COMMON_HOME"), func() -> void: App.services.router.go(&"home"), "card"))
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
		ci.draw_rect(Rect2(Vector2.ZERO, ci.size), FxSkin.CARD_BOTTOM))
	sky.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(sky)
	var bytes: PackedByteArray = heist["replay"]
	var r := RulebornReplay.new()
	if bytes.is_empty() or not r.load(bytes, heist.get("island", PackedByteArray())):
		return
	while r.step():
		pass
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
	# A heist that paid: the crew that got away celebrates on the island,
	# where character models stand in for them.
	var v0: Dictionary = heist["verdict"]
	if v0.get("ok", false) and str(v0.get("grade", "")) in ["Clean", "Loud", "Partial"]:
		var crew := r.crew()
		# The island as a diorama: no bars or marks over it.
		world_view.anchors.visible = false
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
		ci.draw_colored_polygon(pts, Color(1.0, 0.86, 0.45, 0.26 if k % 2 == 0 else 0.14))


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
		ci.draw_line(Vector2(ci.size.x * 0.12, y), Vector2(ci.size.x * 0.88, y), FxSkin.PARCH_INK, 2.0, true)
		return
	var shown := _haul if Settings.reduced_motion else int(_haul * clampf((_clock - 0.6) / 1.0, 0.0, 1.0))
	var font := FxSkin.numbers()
	var px := int(ci.size.y * 0.95)
	var words := "+%d" % shown
	var w := font.get_string_size(words, HORIZONTAL_ALIGNMENT_LEFT, -1, px).x
	var r := ci.size.y * 0.36
	var x := ci.size.x * 0.5 - (w + r * 2.6) * 0.5
	ci.draw_line(Vector2(ci.size.x * 0.06, y), Vector2(x - r, y), FxSkin.PARCH_INK, 2.0, true)
	ci.draw_line(Vector2(x + w + r * 3.6, y), Vector2(ci.size.x * 0.94, y), FxSkin.PARCH_INK, 2.0, true)
	FxIcons.coin(ci, Vector2(x + r, y), r)
	var base := Vector2(x + r * 2.6, y + px * 0.36)
	ci.draw_string_outline(font, base, words, HORIZONTAL_ALIGNMENT_LEFT, -1, px, maxi(4, px / 6), FxSkin.INK_LINE)
	ci.draw_string(font, base, words, HORIZONTAL_ALIGNMENT_LEFT, -1, px, FxSkin.GOLD)


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
		UI.set_status(check_label, "confirming" if v.get("confirming", false) else "success", check_label.text)
	else:
		grade_label.text = Strings.t("RESULT_NOT_ACCEPTED")
		detail_label.text = Errors.message("RESULT_REFUSED", str(v.get("refused", "")))
		# A Workshop play stakes and pays nothing: refused, it does not count.
		var nothing := "RESULT_PAID_NOTHING" if by_server else "RESULT_WOULD_PAY_NOTHING"
		UI.set_status(check_label, "alarm", Strings.t("RESULT_PLAY_NOT_COUNTED" if v.get("workshop", false) else nothing))
