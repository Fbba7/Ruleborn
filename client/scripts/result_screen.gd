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
var _haul := 0
var _clock := 0.0


func _ready() -> void:
	App.ready(self)
	var heist: Dictionary = App.services.store.get_slice(AppState.HEIST)
	_build_world(heist)
	var column := FxSkin.frame(self)[1]
	# The outcome on parchment, as the designs' result card: the grade in
	# Lilita One, outlined, then what was banked and how it was checked.
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
	box.add_child(grade_label)
	box.add_child(FxDraw.new(_draw_rule, Vector2(0, UI.px(10))))
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
	world_view.set_zoom(0)
	world_view.describe()
	var v: Dictionary = heist["verdict"]
	_haul = int(v.get("banked", 0)) if v.get("ok", false) else 0
	flight = FxDraw.new(_draw_flight)
	flight.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(flight)


## A thin ink rule with a coin at its middle, under the grade.
func _draw_rule(ci: Control) -> void:
	var y := ci.size.y * 0.5
	ci.draw_line(Vector2(ci.size.x * 0.12, y), Vector2(ci.size.x * 0.42, y), FxSkin.PARCH_INK, 2.0, true)
	ci.draw_line(Vector2(ci.size.x * 0.58, y), Vector2(ci.size.x * 0.88, y), FxSkin.PARCH_INK, 2.0, true)
	FxIcons.coin(ci, Vector2(ci.size.x * 0.5, y), ci.size.y * 0.45)


## §21.8: "rewards fly into their counter": coins rise from the island and
## arc into the card, a few at a time, for as long as there is loot to bring
## home; reduced motion shows them resting in the card instead.
func _draw_flight(ci: Control) -> void:
	if _haul <= 0 or detail_label == null:
		return
	var to := detail_label.get_global_rect().get_center() - ci.get_global_rect().position
	to.y -= detail_label.size.y * 0.5
	var from := Vector2(ci.size.x * 0.5, ci.size.y * 0.3)
	var count := clampi(_haul / 40, 4, 14)
	var r := UI.px(7)
	if Settings.reduced_motion:
		for k in 3:
			FxIcons.coin(ci, to + Vector2((k - 1) * r * 2.4, -r * 2.0), r)
		return
	for k in count:
		var u := fmod(_clock * 0.55 + float(k) / count, 1.0)
		var side := (float(k % 5) - 2.0) * ci.size.x * 0.06
		var p := from.lerp(to, u) + Vector2(side * sin(u * PI), -sin(u * PI) * ci.size.y * 0.12)
		FxIcons.coin(ci, p, r * (0.8 + 0.4 * sin(u * PI)))


func _process(delta: float) -> void:
	_clock += delta
	if world_view != null and not Settings.reduced_motion:
		# A slow sway of the island, the diorama on its stand.
		world_view.sway(sin(_clock * 0.25) * 0.5)
	if flight != null:
		flight.queue_redraw()


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
