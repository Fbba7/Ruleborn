class_name CharacterScreen
extends Control
## One ruleborn in detail (§23.2: "School, role, ability, traits, level,
## best work"): its card's words (§11.11), its traits and what each does
## (§11.3), its level against what its home allows (§11.4), where it lives
## and works, and what Essence can do for it now — the next level, or waking
## from a rest (§11.6) — each asked for twice, a first tap showing the price,
## because Essence spent is not given back. The character is the route's
## `id`; the roster is the store's. Drawn as the game shows it: the
## character on its hero stage in the in-game view, idling, a drag turning
## it and a tap playing its action; its three forms and its guard form side
## by side beneath (§21.6); the words on parchment and night cards (§21.8).

## The forms the strip beneath the hero shows, in §21.6's order, then the
## guard form.
const LOOKS := ["hush", "spark", "echo", "guard"]

var controller: RosterController
var id := 0
var title_label: Label
var body: VBoxContainer
var status_label: Label
## The hero stage, its level badge, and the strip of forms beneath it.
var stage: StageHero
## The forms and guard form as portraits rendered from the model (§21.3):
## four live models beside the hero would cost more than §21.3's budget.
var forms: HBoxContainer
var level_badge: PanelContainer
var forms_names: PanelContainer
var cards: VBoxContainer
## The spend tapped once, by its key: the next tap on it spends.
var confirm := ""
var clock: Callable = func() -> int: return int(Time.get_unix_time_from_system() * 1000)


func _ready() -> void:
	App.ready(self)
	controller = App.services.roster_flow
	id = int(App.services.store.get_slice(AppState.ROUTE)["params"].get("id", 0))
	_build()
	App.services.store.changed.connect(_on_changed)
	_refresh()
	if (App.services.store.get_slice(RosterState.ROSTER)["view"] as Dictionary).is_empty():
		await controller.load_roster()
	await controller.load_words()


func _on_changed(slice: StringName) -> void:
	if slice in [RosterState.ROSTER, WorkshopState.WORKSHOP] and is_inside_tree():
		_refresh()


func _build() -> void:
	var column := UI.frame(self)
	StageHeroSkin.night(self)
	title_label = UI.title("")
	column.add_child(StageHeroSkin.title(title_label))
	status_label = UI.status("info", "")
	column.add_child(StageHeroSkin.plate(status_label))
	body = UI.scroll(column)
	stage = StageHero.new()
	stage.custom_minimum_size = Vector2(0, UI.px(300))
	stage.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.add_child(stage)
	forms = HBoxContainer.new()
	forms.add_theme_constant_override("separation", UI.px(6))
	forms.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.add_child(forms)
	var names := HBoxContainer.new()
	for look: String in LOOKS:
		var l := UI.label(Strings.t("ROSTER_STATE_GUARDING") if look == "guard" else FormsPresenter.note_name(look),
			UI.TEXT_POINTS, true)
		l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		l.add_theme_color_override("font_color", StageHeroSkin.LIGHT)
		names.add_child(l)
	var strip := PanelContainer.new()
	var flat := StyleBoxFlat.new()
	flat.bg_color = StageHeroSkin.CARD
	flat.set_content_margin_all(UI.px(2))
	strip.add_theme_stylebox_override("panel", flat)
	strip.add_child(names)
	body.add_child(strip)
	forms_names = strip
	cards = VBoxContainer.new()
	cards.add_theme_constant_override("separation", UI.px(Tokens.number("size", "gap_points")))
	body.add_child(cards)
	var actions := UI.row(-1.0, true)
	actions.add_child(StageHeroSkin.button(UI.button(Strings.t("HOME_ROSTER"),
		func() -> void: App.services.router.go(&"roster"), true), true))
	column.add_child(UI.narrow(actions))


func _refresh() -> void:
	if not is_inside_tree():
		return
	var focused := get_viewport().gui_get_focus_owner()
	var focus_item := str(focused.get_meta("item", "")) if focused != null else ""
	var slice: Dictionary = App.services.store.get_slice(RosterState.ROSTER)
	var c := RosterPresenter.character(slice, id, clock.call(),
		App.services.store.get_slice(WorkshopState.WORKSHOP)["words"])
	if c["error"] != "":
		UI.set_status(status_label, "alarm", c["error"])
	elif c["missing"]:
		UI.set_status(status_label, "alarm", Strings.t("CHARACTER_MISSING"))
	elif c["said"] != "":
		UI.set_status(status_label, "success", c["said"])
	elif c["busy"] != "" or not c["ready"]:
		UI.set_status(status_label, "info", Strings.t("COMMON_LOADING"))
	else:
		UI.set_status(status_label, "info", "")
	status_label.get_parent().visible = status_label.text != ""
	for n in cards.get_children():
		cards.remove_child(n)
		n.queue_free()
	title_label.text = c.get("title", Strings.t("ROSTER_TITLE"))
	var shown: bool = c["ready"] and not c["missing"]
	stage.visible = shown
	forms.visible = shown
	forms_names.visible = shown
	if not shown:
		return
	_stand(str(RosterScreen.kinds_of(slice).get(id, "")), c)
	var busy: bool = c["busy"] != ""
	var card := VBoxContainer.new()
	card.add_child(UI.label(Strings.t("CHARACTER_SCHOOL_ROLE", [UI.school_mark(c["school"]), c["role"]]),
		UI.TEXT_POINTS, true))
	card.add_child(UI.label(c["ability"], UI.TEXT_POINTS, true))
	card.add_child(UI.label(c["best"], UI.TEXT_POINTS, true))
	cards.add_child(StageHeroSkin.plate(card, true))
	var traits := VBoxContainer.new()
	traits.add_child(StageHeroSkin.named(UI.label(Strings.t("CHARACTER_TRAITS"), UI.TEXT_POINTS, true)))
	for t: String in c["traits"]:
		traits.add_child(UI.label(t, UI.TEXT_POINTS, true))
	cards.add_child(StageHeroSkin.plate(traits))
	var now := VBoxContainer.new()
	now.add_child(RosterScreen.state_line(c))
	if c["where"] != "":
		now.add_child(UI.label(c["where"], UI.TEXT_POINTS, true))
	now.add_child(UI.label(c["lives"], UI.TEXT_POINTS, true))
	now.add_child(UI.label(c["level"], UI.TEXT_POINTS, true))
	if c["raise"] is Dictionary:
		now.add_child(_spend(c["raise"], busy, true))
	else:
		now.add_child(UI.label(Strings.t("CHARACTER_TOP_LEVEL"), UI.TEXT_POINTS, true))
	if c["wake"] is Dictionary:
		now.add_child(_spend(c["wake"], busy))
	var send := RosterScreen.offer(c["send"], busy, _send.bind(c))
	for b: Button in send.find_children("*", "Button", true, false):
		StageHeroSkin.button(b)
	now.add_child(send)
	cards.add_child(StageHeroSkin.plate(now))
	StageHeroSkin.cap_buttons(cards, get_viewport_rect().size.x - UI.px(64))
	if focus_item != "":
		for b: Button in find_children("*", "Button", true, false):
			if b.get_meta("item", "") == focus_item and b.is_visible_in_tree():
				b.grab_focus.call_deferred()
				break


## The character on its stage, its level on a badge, and its forms beneath.
func _stand(kind: String, c: Dictionary) -> void:
	if kind == "" or str(stage.get_meta("showing", "")) == kind:
		_badge(c)
		return
	stage.set_meta("showing", kind)
	stage.show_kinds([kind])
	for n in forms.get_children():
		n.queue_free()
	for look: String in LOOKS:
		var tile := StageHeroSkin.portrait_tile(kind, look, 96.0)
		tile.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		forms.add_child(tile)
	_badge(c)


## The level as a number in Lilita One on the stage's corner (§21.8).
func _badge(c: Dictionary) -> void:
	if level_badge != null:
		level_badge.queue_free()
	var slice: Dictionary = App.services.store.get_slice(RosterState.ROSTER)
	var level := 0
	for x: Dictionary in (slice.get("view", {}) as Dictionary).get("characters", []):
		if int(x["id"]) == id:
			level = int(x["level"])
	var school: Color = Palette.SCHOOL.get(str(c["school"]), Palette.MOTION)
	level_badge = PanelContainer.new()
	level_badge.mouse_filter = Control.MOUSE_FILTER_PASS
	level_badge.add_theme_stylebox_override("panel", StyleBoxEmpty.new())
	level_badge.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	stage.add_child(level_badge)
	StageHeroSkin.on_stage(level_badge, StageHeroSkin.badge(str(level), school.darkened(0.55), 28.0),
		Control.PRESET_TOP_LEFT)
	# §23.2's state on the stage, as the design's state pill puts it.
	StageHeroSkin.on_stage(level_badge, StageHeroSkin.pill(str(c["line"])), Control.PRESET_TOP_RIGHT)
	# The design's arrows through the roster, in its order, round at the ends.
	var ids: Array = RosterScreen.kinds_of(slice).keys()
	var at := ids.find(id)
	if ids.size() > 1 and at >= 0:
		var named := RosterPresenter.names((slice.get("view", {}) as Dictionary).get("characters", []),
			App.services.store.get_slice(WorkshopState.WORKSHOP)["words"])
		for step: int in [-1, 1]:
			var to: int = ids[posmod(at + step, ids.size())]
			var b := StageHeroSkin.button(UI.button("‹" if step < 0 else "›",
				func() -> void: App.services.router.go(&"character", {"id": to}), false, Color(),
				Strings.t("CHARACTER_PREVIOUS" if step < 0 else "CHARACTER_NEXT", str(named.get(to, "")))))
			b.set_meta("item", "step:%d" % step)
			b.add_theme_font_size_override("font_size", UI.text_px(30))
			b.set_meta("points", 30.0)
			for state: String in ["normal", "hover", "pressed", "focus", "disabled"]:
				(b.get_theme_stylebox(state) as StyleBoxFlat).set_corner_radius_all(UI.px(99))
			StageHeroSkin.on_stage(level_badge, b, Control.PRESET_CENTER_LEFT if step < 0 else Control.PRESET_CENTER_RIGHT)


## A spend's button: the first tap shows the price to confirm; the second
## spends.
func _spend(o: Dictionary, busy: bool, main := false) -> Control:
	var confirming: bool = confirm == o["key"]
	var shown := o.duplicate()
	if confirming:
		shown["action"] = Strings.t("CHARACTER_CONFIRM", o["cost"])
		shown["spoken"] = Strings.t("CHARACTER_CONFIRM_SPOKEN", [o["spoken"], o["cost"]])
	var r := RosterScreen.offer(shown, busy, _tap.bind(o))
	for b: Button in r.find_children("*", "Button", true, false):
		StageHeroSkin.button(b, main)
	return r


func _tap(o: Dictionary) -> void:
	if confirm != o["key"]:
		confirm = o["key"]
		_refresh()
		return
	confirm = ""
	var a: Dictionary = o["args"]
	if a.has("to"):
		await controller.level(int(a["id"]), int(a["to"]))
	else:
		await controller.wake(int(a["id"]))


func _send(c: Dictionary) -> void:
	var a: Dictionary = c["send"]["args"]
	if a.is_empty():
		return
	await controller.work(int(a["id"]), str(a["realm"]), str(a["kind"]), int(a["n"]), str(c["title"]))
