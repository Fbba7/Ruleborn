class_name HeistScreen
extends Control
## A heist, on screen: `HeistController` holds the heist and turns taps into
## commands; this screen draws it, forwards taps and buttons, runs the clock
## in real time, and when the clock runs out hands the replay to the heist
## repository, which checks it with the server (§24.12) — or, offline, the
## same check runs on the phone. A Workshop island is played on the seed and
## clock its play was given, and its replay goes to the Workshop (§18.6).
##
## §21.8 puts crew portraits at the bottom left and actions at the bottom
## right; both rows here sit above the corners, which §21.1 keeps clear, and
## the actions mirror for a left-handed player (§20.8). A rehearsal — the
## player's own island, raided from the builder — can be paused at any time
## and, if the player asks, runs at 75% (§20.8). The alarm rising, a pylon
## breaking and the escape each have a haptic form as well as a visual one.

signal finished

const Kind := HeistController.Kind
## §15.3: a realm's entry banner shows for about two seconds.
const ENTRY_SECONDS := 2.2

var controller := HeistController.new()
var playing := true

var view: WorldView
var hud: HeistHud
var hint_label: Label
## The hint's panel (KitStatus.hint), whose "Words" is hint_label.
var hint_panel: PanelContainer
## The HUD's top column, which the hint must not reach (_fit_hint).
var top_column_node: VBoxContainer
var gait_button: Button
var pause_button: Button
var crew_buttons: Array[FxPortrait] = []
## A rehearsal: the player's own island, from the builder.
var rehearsal := false
## Paused by the player, in a rehearsal only.
var paused := false


## The lease this heist is played under, when a server gave one.
var lease := {}
## The offer to play offline, while it is on screen (G41).
var offline_prompt: Control
var column_node: VBoxContainer

## §5.4's landing picker, shown in place of the action and crew rows until
## the crew lands.
var picker: Control
var landing: OverlayLanding
var picker_spot: Label
var picker_count: Label
var picker_clock: Label
## Across a universe: the realm of the choice on show, the realms and faults
## there are, and a step to the next realm.
var picker_realm: Label
var picker_across: Label
var next_realm_button: Button
var actions_node: Control
## The bottom right: the Sage, Cast and Get out (§21.8).
var hand: HeistHand
## A power, cast or ability chosen and waiting for a tap on the world:
## {kind, index, words}; empty when none waits.
var aiming := {}
## The crew's names in portrait order, when a caller gives them (a shot);
## else the roster's, by the plan.
var names_given: Array = []
## The row of the crew's portraits and Get out.
var actions_band: Control
var crew_node: Control
## The realm's entry card while it is on screen.
var card: PanelContainer
## The gait menu a held press opens, while it is open.
var gait_menu: PanelContainer
## Which realm the view is drawing, so a new one is drawn when the crew (or
## the picker) moves to another.
var _shown_realm := ""
var _crew_key := ""
var _owed := 0.0
var _alarm := 0
var _live_wards := -1
var _pylons := -1
## What the hint would say, whole; how far it has given way for room (0
## whole, 1 its first clause, 2 hidden); and where the controls stood when
## it last gave way.
var _hint_source := ""
var _hint_level := 0
var _hint_measured_at := -1.0
## The most health each crew member has shown, its health ring's whole.
var _most_health := {}


func _ready() -> void:
	App.ready(self)
	var services: Services = App.services
	var heist: Dictionary = services.store.get_slice(AppState.HEIST)
	rehearsal = heist["testing"]
	controller.world.start(HeistController.SEED, HeistController.TICKS, HeistController.CREW, PackedByteArray())
	_build()
	controller.changed.connect(_refresh)
	controller.clock_out.connect(finish)
	var play: Dictionary = heist["workshop"]
	if heist["testing"]:
		begin(HeistController.SEED, HeistController.TICKS, HeistController.CREW, heist["island"])
	elif not play.is_empty():
		# A Workshop island, on the seed and clock its play was given; one this
		# build cannot load is said, never swapped for the fixture realm.
		if not begin(str(play["seed"]), int(play["ticks"]), HeistController.CREW, heist["island"]):
			playing = false
			_set_hint(Errors.message("HEIST_NONE", "island_does_not_load"))
	elif not services.api.online():
		begin(HeistController.SEED, HeistController.TICKS, HeistController.CREW)
	else:
		await start_online(services)


## Online, as the owner answered G41: the rule. With no network, the
## exception: a prompt that recommends going online first, and a heist from
## the lease stock only if the player chooses it.
func start_online(services: Services) -> void:
	playing = false
	if offline_prompt != null:
		offline_prompt.queue_free()
	offline_prompt = null
	_set_hint(Strings.t("HEIST_ASKING"))
	var problem := await begin_online(services)
	if problem == "":
		# Online: send what waited, and keep the stock for next time.
		var sent := await services.outbox.flush(services.api)
		if sent > 0:
			column_node.add_child(UI.banner("success", Strings.t("OFFLINE_SENT", sent)))
		await services.heists.fill_stock(str(services.store.get_slice(AppState.SESSION)["account"]))
		return
	# Held back by the server (G44) is not offline: the server was reached,
	# and asked to wait; the player tries again, online.
	if problem == "too_many_requests":
		_set_hint(Errors.message("HEIST_NONE", problem))
		offline_prompt = UI.row(-1.0, true)
		offline_prompt.add_child(UI.button(Strings.t("OFFLINE_TRY_AGAIN"), func() -> void: start_online(services), true))
		column_node.add_child(offline_prompt)
		return
	if not Outbox.transient(Result.failure(problem)):
		_set_hint(Errors.message("HEIST_NONE", problem))
		return
	_offer_offline(services)


## §24.12's exception, recommended against: the stocked lease is played on the
## phone, its haul shown as confirming until the server confirms it.
func _offer_offline(services: Services) -> void:
	var stocked := services.heists.stock.count() > 0
	_set_hint(Strings.t("OFFLINE_RECOMMEND" if stocked else "OFFLINE_NONE"))
	offline_prompt = UI.row(-1.0, true)
	offline_prompt.add_child(UI.button(Strings.t("OFFLINE_TRY_AGAIN"), func() -> void: start_online(services), true))
	if stocked:
		offline_prompt.add_child(UI.button(Strings.t("OFFLINE_PLAY_ANYWAY"), func() -> void: play_stocked(services)))
	column_node.add_child(offline_prompt)


## A heist on the newest stocked lease, with no network.
func play_stocked(services: Services) -> bool:
	var item := services.heists.stock.take()
	if item.is_empty():
		return false
	if offline_prompt != null:
		offline_prompt.queue_free()
		offline_prompt = null
	lease = item["lease"]
	return begin(str(lease["seed"]), int(lease["ticks"]), HeistController.CREW, item["island"],
		HeistController.lease_era(lease))


## Start a fresh heist; see `HeistController.begin`.
func begin(seed_text: String, ticks: int, crew: int, realm := PackedByteArray(), era := "",
		manifest := PackedByteArray()) -> bool:
	# A new world: the next refresh only takes the haptic cues' baseline.
	_alarm = 0
	_live_wards = -1
	_pylons = -1
	if not controller.begin(seed_text, ticks, crew, realm, era, manifest):
		return false
	playing = true
	_shown_realm = ""
	view.show_replay(controller.world)
	_refresh()
	return true


## Start a heist across the universe a lease names; see
## `HeistController.begin_universe`.
func begin_universe(seed_text: String, crew: int, leased: Dictionary, bundle: PackedByteArray,
		islands: Array[PackedByteArray], era := "", manifest := PackedByteArray()) -> bool:
	_alarm = 0
	_live_wards = -1
	_pylons = -1
	if not controller.begin_universe(seed_text, crew, leased, bundle, islands, era, manifest):
		return false
	playing = true
	_shown_realm = ""
	_refresh()
	return true


## The lease's universe fetched by hash (§24.8), its bundle and each realm's
## island, in its order; an empty bundle if any is missing.
static func fetch_universe(services: Services, leased: Dictionary) -> Array:
	var bundle := await services.heists.fetch(str(leased["digest"]))
	var islands: Array[PackedByteArray] = []
	if not bundle.ok:
		return [PackedByteArray(), islands]
	for r: Dictionary in leased["realms"]:
		var island := await services.heists.fetch(str(r["bundle"]))
		if not island.ok:
			return [PackedByteArray(), islands]
		islands.append(island.value)
	return [bundle.value, islands]


## §24.12's Lease: sign in, take the first target from the lists, fetch its
## bundle and lease it — "a target snapshot, a seed, a single-use token and an
## expiry a day away". Returns "" or the code of what went wrong.
func begin_online(services: Services) -> String:
	var me := await services.session()
	if not me.ok:
		return me.code
	# The target chosen in the Observatory (§12.3), or the lists' first.
	var chosen: Dictionary = services.store.get_slice(AppState.HEIST).get("target", {})
	var target := Result.success(chosen) if not chosen.is_empty() \
		else await services.heists.first_target(str(me.value["account"]))
	if not target.ok:
		return target.code
	var bundle := await services.heists.fetch(str(target.value["bundle"]))
	if not bundle.ok:
		return bundle.code
	# §5.4: a target whose raid crosses a universe is leased across it.
	var leased := await services.heists.lease(str(target.value["bundle"]), str(target.value.get("owner", "")),
		bool(target.value.get("trace", false)), bool(target.value.get("across", false)))
	if not leased.ok:
		return leased.code
	lease = leased.value
	# §12.5: the planner's crew, Sage, casts and load target, when it made one.
	var plan: Dictionary = services.store.get_slice(AppState.HEIST).get("plan", {})
	var crew: int = (plan["crew"] as Array).size() if plan.has("crew") else HeistController.CREW
	if lease.get("universe") is Dictionary:
		var got: Array = await fetch_universe(services, lease["universe"])
		if (got[0] as PackedByteArray).is_empty():
			return "island_does_not_load"
		if not begin_universe(str(lease["seed"]), crew, lease["universe"], got[0], got[1],
				HeistController.lease_era(lease), plan.get("manifest", PackedByteArray())):
			return "island_does_not_load"
	elif not begin(str(lease["seed"]), int(lease["ticks"]), crew, bundle.value,
			HeistController.lease_era(lease), plan.get("manifest", PackedByteArray())):
		return "island_does_not_load"
	controller.load_target = int(plan.get("load", 100))
	# §12.4's free rough estimate of the loot, from the card the planner
	# opened on, until the Vault opens (12.6).
	var planned: Dictionary = services.store.get_slice(PlannerState.PLANNER).get("target", {})
	if str(planned.get("bundle", "")) == str(target.value["bundle"]) and planned.has("loot"):
		hud.estimate = int(planned["loot"])
	return ""


## Run `ticks` ticks of the clock; see `HeistController.advance`.
func advance(ticks: int) -> void:
	controller.advance(ticks)


## Write the heist down and have it checked: by the server, which re-simulates
## and settles it (§24.12), or — offline — by the same function on the phone.
## A submission the network cannot carry now waits in the outbox, and the
## result shows the phone's own check, marked confirming.
func finish() -> void:
	if not playing:
		return
	playing = false
	var services: Services = App.services
	var replay := controller.record()
	var local := RulebornReplay.validate(replay, controller.island) if controller.universe.is_empty() \
		else RulebornReplay.validate_universe(replay, controller.universe_bytes, controller.realm_islands)
	services.store.dispatch(&"heist_finished", {"replay": replay, "verdict": local})
	if local.get("ok", false) and str(local.get("grade", "")) != "Foiled":
		Haptics.play("success")
	var play: Dictionary = services.store.get_slice(AppState.HEIST)["workshop"]
	if not play.is_empty():
		_set_hint(Strings.t("HEIST_CHECKING"))
		var played := await services.workshop_flow.submit(str(play["token"]), replay)
		services.store.dispatch(&"heist_verdict", WorkshopController.settled(played, local))
	elif not lease.is_empty():
		_set_hint(Strings.t("HEIST_CHECKING"))
		var plan: Dictionary = services.store.get_slice(AppState.HEIST).get("plan", {})
		var answer := await services.heists.submit(str(lease["token"]), replay, plan.get("crew", []))
		var settled := HeistController.settled(answer, local)
		# The heist's token, which its one study names (§7.6).
		settled["token"] = str(lease["token"])
		services.store.dispatch(&"heist_verdict", settled)
		# §14.2: the experience it earned moves the Keeper bar; an answer the
		# server gave before is not news, so the bar is asked for afresh.
		if settled.get("keeper") is Dictionary:
			services.store.dispatch(&"keeper_earned", {"keeper": settled["keeper"]})
		elif answer.ok and answer.value is Dictionary and answer.value.get("repeated", false):
			await services.keeper_flow.load_keeper()
	finished.emit()
	if is_inside_tree():
		services.router.go.call_deferred(&"result")


## How fast the clock runs: a rehearsal at §20.8's 75% when the player asks.
func pace() -> float:
	return Tokens.number("motion", "rehearsal_pace") if rehearsal and Settings.slow_rehearsals else 1.0


func toggle_pause() -> void:
	if not rehearsal:
		return
	paused = not paused
	_refresh()


func _process(delta: float) -> void:
	if not playing or paused or controller.choosing:
		return
	_owed += delta * RulebornReplay.ticks_per_second() * pace()
	var whole := int(_owed)
	_owed -= whole
	controller.advance(whole)


# -- layout ---------------------------------------------------------------

func _refresh() -> void:
	if hud == null:
		return
	# A new realm on show — the picker's, or the crew's across a universe —
	# is drawn afresh.
	var key := "%s:%s:%s" % [controller.choosing, controller.world.realm_code(), controller.world.size()]
	if controller.choosing and not controller.universe.is_empty():
		key += ":%s:%s" % [controller.marks[controller.pick]["place"], controller.marks[controller.pick].get("fault", false)]
	if key != _shown_realm:
		_shown_realm = key
		view.show_replay(controller.world)
		if not controller.choosing:
			entry_card(HeistHud.realm(controller.world.realm_code(), controller.world.realms_to_go()))
	hud.load_target = controller.load_target
	hud.show_state(controller.world)
	_feel(controller.world)
	if _crew_shape(controller.world.crew()) != _crew_key:
		_build_crew()
	var me: Dictionary = controller.world.crew()[controller.selected]
	_set_hint(Strings.t("HEIST_SKIFF_HINT") if controller.calling_skiff else \
		(_aim_hint() if not aiming.is_empty() else Strings.t("HEIST_HINT_SHORT")))
	hand.armed = int(aiming.get("kind", 0)) if not aiming.is_empty() and int(aiming["kind"]) != Kind.ABILITY else 0
	hand.show_state(controller.world.sage(), controller.world.casts(), controller.world.tick())
	# Before the crew lands: where, and nothing else (§5.4).
	var choosing := controller.choosing
	picker.visible = choosing
	actions_node.visible = not choosing
	actions_band.visible = not choosing
	crew_node.visible = not choosing
	view.landing_marks = controller.shown_marks() if choosing else []
	view.landing_pick = controller.shown_pick()
	view.follow = [] if choosing else [controller.selected]
	view.chosen = -1 if choosing else controller.selected
	var across := not controller.universe.is_empty()
	picker_realm.visible = across
	picker_across.visible = across
	next_realm_button.visible = across
	if choosing:
		var p := LandingPresenter.picker(controller.marks, controller.pick, controller.world.size().x,
			controller.world.landing_reach(), controller.world.ticks() / RulebornReplay.ticks_per_second())
		hint_label.text = Strings.t("LANDING_HINT")
		picker_spot.text = p["spot"]
		picker_count.text = p["count"]
		picker_clock.text = p["clock"]
		picker_realm.text = p.get("realm", "")
		picker_across.text = p.get("across", "")
		landing.show_pick()
	hud.visible = not choosing
	(hint_panel.get_parent() as Control).visible = not choosing
	# §12.7: never more than eight things to tap; the gait's button stands
	# only while there is room under them (it is a held tap on the ground too).
	var taps := crew_buttons.size() + (1 if hand.sage_button.visible else 0) + 2 + (1 if pause_button != null else 0)
	# With §20.8's large text the gait is the held tap's alone, so the hand's
	# rows stay low in reach.
	gait_button.visible = taps < 8 and Settings.text_scale <= 130
	gait_button.accessibility_name = Strings.term("GAIT", me["gait"])
	gait_button.tooltip_text = gait_button.accessibility_name
	(gait_button.get_meta("words") as Label).text = gait_button.accessibility_name
	if str(gait_button.get_meta("icon", "")) != str(me["gait"]):
		gait_button.set_meta("icon", str(me["gait"]))
		for c in gait_button.find_children("*", "FxDraw", true, false):
			(c as FxDraw).queue_redraw()
	var crew := controller.world.crew()
	for i in crew_buttons.size():
		var b := crew_buttons[i]
		if i >= crew.size():
			b.visible = false
			continue
		var m: Dictionary = crew[i].duplicate()
		var role := Strings.term("ROLE", m["role"])
		_most_health[i] = maxi(int(_most_health.get(i, 0)), int(m["health"]))
		m["max_health"] = _most_health[i]
		# Chosen is said in the portrait's words and drawn as a gold ring and a
		# lift, never by fading the others.
		var chosen := i == controller.selected
		b.show_member(m, chosen)
		b.armed = not aiming.is_empty() and int(aiming["kind"]) == Kind.ABILITY and chosen
		var said := role if b.letters == role else "%s, %s" % [b.letters, role]
		b.accessibility_name = Strings.t("HEIST_CREW_CHOSEN" if chosen else "HEIST_CREW", said)
		if b.uses >= 0:
			b.accessibility_name += ", " + Strings.t("HEIST_USES_LEFT", b.uses)
		b.tooltip_text = b.accessibility_name
	if pause_button != null:
		# Nothing runs before the crew lands: the picker's title has the room.
		pause_button.visible = not choosing
		pause_button.accessibility_name = Strings.t("HEIST_RESUME" if paused else "HEIST_PAUSE")
		pause_button.tooltip_text = pause_button.accessibility_name
		pause_button.set_meta("icon", "play" if paused else "pause")
		FxSkin.redraw(pause_button)
	_fit_hint()
	view.describe()
	view.queue_redraw()


## §15.3's two-second banner as the crew lands in a realm or crosses into
## the next: the realm's name on a parchment card in the middle of the
## screen, rising in and fading away (reduced motion: shown, then gone).
## The HUD's top row keeps saying it after the card has gone.
func entry_card(words: String) -> void:
	if words == "" or not is_inside_tree():
		return
	if card != null and is_instance_valid(card):
		card.queue_free()
	card = UI.panel("parchment")
	card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	# The kit's heading on its parchment: the material's ink, wrapping.
	var title := UI.label(words, float(Tokens.type_role("heading")["points"]), true)
	title.theme_type_variation = "Heading"
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(title)
	card.set_anchors_preset(Control.PRESET_CENTER)
	card.custom_minimum_size.x = UI.px(260)
	card.grow_horizontal = Control.GROW_DIRECTION_BOTH
	card.grow_vertical = Control.GROW_DIRECTION_BOTH
	add_child(card)
	var shown := card
	var tw := create_tween()
	if not Settings.reduced_motion:
		shown.modulate.a = 0.0
		tw.tween_property(shown, "modulate:a", 1.0, UI.motion_ms(250) / 1000.0)
	tw.tween_interval(ENTRY_SECONDS)
	tw.tween_property(shown, "modulate:a", 0.0, UI.motion_ms(250) / 1000.0)
	tw.tween_callback(shown.queue_free)


## §12.18 as the designs draw it: hold the ground and a Crouch / Walk / Run
## menu opens at the finger; the gait chosen is the chosen crew member's, and
## it walks there at it. A plain tap sends at the last gait. Nothing here is
## only reachable by holding: the gait button does the same.
func open_gait_menu(at: Vector2) -> void:
	close_gait_menu()
	var tile := view.tile_at(at)
	if controller.choosing or tile.x < 0:
		return
	gait_menu = UI.panel("parchment")
	gait_menu.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var row := HBoxContainer.new()
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_theme_constant_override("separation", UI.px(6))
	gait_menu.add_child(row)
	var crew := controller.world.crew()
	var held := -1
	for i in crew.size():
		if Vector2i(crew[i]["at"]) == tile and crew[i]["standing"] == "Active":
			held = i
	if held >= 0:
		# §12.7: a held tap on a crew member offers Stop, Drop half and Drop
		# all, for that member.
		row.add_child(_button(Strings.t("HEIST_STOP"), func() -> void: _order_member(held, Kind.HALT, 0)))
		row.add_child(_button(Strings.t("HEIST_DROP_HALF"), func() -> void: _order_member(held, Kind.DROP, 50)))
		row.add_child(_button(Strings.t("HEIST_DROP_ALL"), func() -> void: _order_member(held, Kind.DROP, 100)))
	else:
		# The design's order, quietest first: Crouch, Walk, Run.
		for i: int in [1, 0, 2]:
			var g: String = HeistController.GAITS[i]
			var b := _button(Strings.term("GAIT", g), func() -> void: _go_at(i, tile), "leather")
			FxSkin.add_icon(b, g)
			row.add_child(b)
	add_child(gait_menu)
	gait_menu.reset_size()
	# Above the finger, kept on the screen.
	var place := at - Vector2(gait_menu.size.x * 0.5, gait_menu.size.y + UI.px(28))
	place.x = clampf(place.x, UI.px(8), size.x - gait_menu.size.x - UI.px(8))
	place.y = maxf(place.y, UI.px(80))
	gait_menu.position = place
	Haptics.play("tap")


func close_gait_menu() -> void:
	if gait_menu != null and is_instance_valid(gait_menu):
		gait_menu.queue_free()
	gait_menu = null


## One of a held crew member's orders (Stop, a drop), given to it.
func _order_member(member: int, kind: int, amount: int) -> void:
	close_gait_menu()
	controller.world.give(member, kind, amount, 0)
	controller.changed.emit()


## The chosen gait, then the walk to the held tile: two commands the player
## gave (§12.18).
func _go_at(gait_index: int, tile: Vector2i) -> void:
	close_gait_menu()
	controller.world.give(controller.selected, Kind.GAIT, gait_index, 0)
	controller.tap_tile(tile)
	controller.changed.emit()


## The haptic form of what the screen shows: a warning as the alarm rises, a
## pulse as a ward goes down (§21.8).
func _feel(r: RulebornReplay) -> void:
	var live := 0
	for w in r.wards():
		if w["live"]:
			live += 1
	var standing := 0
	for p in r.pylons():
		if p["standing"]:
			standing += 1
	for kind in cues(_alarm, r.alarm(), _live_wards, live, _pylons, standing):
		Haptics.play(kind)
	_alarm = r.alarm()
	_live_wards = live
	_pylons = standing


## The haptic cues between two moments: the alarm's level, the wards standing
## and the pylons standing, before and now (-1 before: nothing seen yet). A
## ward or a pylon going down is one pulse (§21.8).
static func cues(alarm_before: int, alarm: int, live_before: int, live: int, pylons_before := -1,
		pylons := -1) -> Array[String]:
	var out: Array[String] = []
	if alarm > alarm_before:
		out.append("warning")
	if (live_before >= 0 and live < live_before) or (pylons_before >= 0 and pylons < pylons_before):
		out.append("pulse")
	return out


func _build() -> void:
	# The world fills the screen (§21.8: the heist is played on the world);
	# the HUD floats over it inside §21.1's safe areas, and lets every tap it
	# does not take fall through to the world.
	view = WorldView.new()
	view.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	view.tapped.connect(_tap_world)
	view.held.connect(open_gait_menu)
	add_child(view)
	var columns := FxSkin.frame(self)
	var column := columns[0]
	var lower := columns[1]
	column_node = lower
	hud = HeistHud.new()
	column.add_child(hud)
	if rehearsal:
		# A rehearsal's pause (§20.8), under the law banner: not one of the
		# hand's orders.
		pause_button = _order(Strings.t("HEIST_PAUSE"), toggle_pause, "pause")
		pause_button.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
		column.add_child(pause_button)
	view.looted.connect(func(at: Vector2, amount: int) -> void: hud.fly_coins(at, amount / 20))
	var top_column := column
	top_column_node = top_column
	column = lower
	# The kit's tip (KitHud.tip, 02-heist.png's "Tap crew, then ground"):
	# leather, its words bold cream outlined in ink, whole and wrapping.
	hint_panel = KitHud.tip("")
	hint_label = hint_panel.get_node("Words") as Label
	var hint := hint_panel
	# The hint gives way when the columns meet, measured after each layout
	# (a refresh comes before the containers settle).
	for moving: Control in [top_column, lower]:
		moving.item_rect_changed.connect(func() -> void: _fit_hint.call_deferred())

	# The design's landing picker (T6's `OverlayLanding`), its header over
	# the world at the top while the crew chooses.
	landing = OverlayLanding.new(controller)
	picker = landing
	picker_realm = landing.realm_line
	picker_across = landing.across_line
	picker_spot = landing.spot_line
	picker_count = landing.count_line
	picker_clock = landing.clock_line
	next_realm_button = landing.next_realm
	top_column.add_child(landing.header)
	column.add_child(picker)

	# §21.8 as the design lays it out: the crew's portraits at the bottom
	# left; at the bottom right the Sage's disc over Cast over a red Get out
	# (HeistHand). Halt and the drops are a held tap on a crew member (§12.7);
	# the gait is a held tap on the ground, and a small button beside the
	# hint while the controls are under §12.7's eight. Mirrored for a
	# left-handed player (§20.8). With §20.8's large text the hand stands
	# over the portraits rather than beside them, so neither runs off the
	# phone.
	column.add_child(FxSkin.camera_row(view))
	var band: BoxContainer = HBoxContainer.new()
	if Settings.text_scale > 130:
		band = VBoxContainer.new()
	band.mouse_filter = Control.MOUSE_FILTER_IGNORE
	band.add_theme_constant_override("separation", UI.px(4))
	if Settings.left_handed:
		band.layout_direction = Control.LAYOUT_DIRECTION_RTL
	# The crew three to a row beside the hand, as the design's (a crew of
	# five stands three over two, never four over one); with large text one
	# flowing row under the hand's, the names, wider than their discs, apart.
	var crew_row: Container
	if Settings.text_scale <= 130:
		var grid := GridContainer.new()
		grid.columns = 3
		grid.add_theme_constant_override("h_separation", UI.px(4))
		grid.add_theme_constant_override("v_separation", UI.px(1))
		crew_row = grid
	else:
		var flow := UI.row(8.0, true)
		flow.alignment = FlowContainer.ALIGNMENT_BEGIN
		crew_row = flow
	crew_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	crew_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	crew_row.size_flags_vertical = Control.SIZE_SHRINK_END
	crew_node = crew_row
	band.add_child(crew_row)
	_build_crew()
	hand = HeistHand.new(_get_out)
	hand.host = self
	hand.chosen.connect(_aim)
	hand.put_away.connect(func() -> void:
		aiming = {}
		_refresh())
	_dress_hand()
	actions_node = hand
	band.add_child(hand)
	if band is HBoxContainer:
		# The Sage's disc beside Cast rather than over it, so the hand is
		# no taller than the crew's two rows and the tray leaves the world
		# its crew.
		var sage := hand.sage_button
		sage.reparent(band)
		band.move_child(sage, hand.get_index())
		sage.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	if band is VBoxContainer:
		# With large text the hand's buttons and the gait are one row that
		# wraps, under the portraits and lowest in reach; the hand keeps
		# them and their state.
		var flow := UI.row(4.0, true)
		flow.mouse_filter = Control.MOUSE_FILTER_IGNORE
		flow.alignment = FlowContainer.ALIGNMENT_END
		for c in hand.get_children():
			c.reparent(flow)
		band.add_child(flow)
		actions_node = flow
	# The crew and the hand on one tray of dark glass (the design's), so the
	# portraits and buttons keep their value step off the bright world.
	var tray := FxSkin.panel("glass", 14.0, 5.0)
	tray.name = "Tray"
	tray.add_child(band)
	actions_band = tray
	column.add_child(tray)
	# The hint over the tray (the design's), with the gait's small button
	# before it.
	var foot := HBoxContainer.new()
	foot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	foot.alignment = BoxContainer.ALIGNMENT_CENTER
	foot.add_theme_constant_override("separation", UI.px(6))
	if Settings.left_handed:
		foot.layout_direction = Control.LAYOUT_DIRECTION_RTL
	gait_button = _gait_pill()
	foot.add_child(gait_button)
	if Settings.text_scale > 130:
		# With §20.8's large text the gait joins the hand's row, so the
		# controls take one row fewer and stay low in reach.
		gait_button.reparent(actions_node)
		actions_node.move_child(gait_button, 0)
	hint.custom_minimum_size.x = UI.px(150)
	foot.add_child(hint)
	column.add_child(foot)
	column.move_child(foot, tray.get_index())
	# Clear of the bottom corners, where §21.1 puts nothing to tap.
	column.add_child(FxSkin.corner_clear())
	# The guards' words on a layer above the panels, moved off them where the
	# world has room, so a bubble is never clipped behind the HUD or the tray.
	var speech := Control.new()
	speech.name = "Speech"
	speech.mouse_filter = Control.MOUSE_FILTER_IGNORE
	speech.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(speech)
	if view.anchors != null:
		view.anchors.speech_layer = speech
		view.anchors.keep_off = _panel_rects.bind(speech)


## The rects of the panels a guard's bubble keeps off, in `layer`'s pixels:
## the HUD's, the hint's and the tray.
func _panel_rects(layer: Control) -> Array:
	var out: Array = []
	var panels: Array = [hud.clock_panel, hud.alarm_panel, hud.loot_panel, actions_band]
	if hud.laws_box != null:
		panels.append_array(hud.laws_box.get_children())
	if hint_panel != null:
		panels.append(hint_panel)
	for c: Variant in panels:
		var ctl := c as Control
		if ctl != null and ctl.is_visible_in_tree() and ctl.size.x > 0.0:
			var r := ctl.get_global_rect()
			r.position -= layer.global_position
			out.append(r)
	return out


## The crew's portraits, one a member the simulation has, each its kind's
## character and its name (the roster's, from the plan); built again when the
## crew changes (a planned crew of four or five, a Prism mite's split).
func _build_crew() -> void:
	for b in crew_buttons:
		b.queue_free()
	crew_buttons.clear()
	# Another crew: each portrait's whole health is learnt afresh.
	_most_health.clear()
	var crew := controller.world.crew()
	var names := crew_names()
	for i in crew.size():
		var kind := str(crew[i].get("kind", ""))
		var shown: String = names[i] if i < names.size() else (Strings.term("RULEBORN", kind) if kind != "" else "")
		var b := FxPortrait.new(str(crew[i]["role"]), _portrait_tapped.bind(i), kind, shown)
		crew_buttons.append(b)
		crew_node.add_child(b)
	# With large text a rehearsal's pause stands at the end of the portraits,
	# low in reach, rather than under the taller HUD.
	if Settings.text_scale > 130 and pause_button != null:
		if pause_button.get_parent() != crew_node:
			pause_button.reparent(crew_node)
		# After the portraits, as the crew may have been drawn afresh.
		crew_node.move_child(pause_button, -1)
	_crew_key = _crew_shape(crew)


## Each crew member's name, in portrait order: the roster's name for the
## character the plan put there, or none (the screen then says its kind).
func crew_names() -> Array:
	if not names_given.is_empty():
		return names_given
	var services: Services = App.services
	if services == null:
		return []
	var plan: Dictionary = services.store.get_slice(AppState.HEIST).get("plan", {})
	var roster: Dictionary = services.store.get_slice(RosterState.ROSTER).get("view", {})
	var characters: Array = roster.get("characters", [])
	var named := RosterPresenter.names(characters)
	var out := []
	for id: Variant in plan.get("crew", []):
		out.append(str(named.get(int(id), "")))
	return out


static func _crew_shape(crew: Array) -> String:
	return ",".join(crew.map(func(m: Dictionary) -> String: return "%s/%s" % [m["role"], m.get("kind", "")]))


## A tap on a portrait (§12.7): another member is chosen; the chosen one's
## ability is armed while it has a use left, and a tap on the world aims it
## (the device names the target, the simulation decides what it does). A
## second tap puts it down again.
func _portrait_tapped(i: int) -> void:
	close_gait_menu()
	hand.close_wheel()
	if i != controller.selected:
		aiming = {}
		controller.select(i)
		return
	var m: Dictionary = controller.world.crew()[i]
	if not aiming.is_empty() or str(m.get("kind", "")) == "" or int(m.get("uses", 0)) <= 0:
		aiming = {}
		_refresh()
		return
	_aim(Kind.ABILITY, i, crew_buttons[i].letters)


## A power, a cast or an ability chosen and waiting for its place on the
## world (§12.7's drag to aim, as a tap).
func _aim(kind: int, index: int, words: String) -> void:
	if index < 0:
		return
	aiming = {"kind": kind, "index": index, "words": words}
	controller.calling_skiff = false
	_refresh()


## A tap on the world: the aimed command at that tile if one waits, else
## what the tapped thing calls for (`HeistController.tap_tile`).
func _tap_world(at: Vector2) -> void:
	close_gait_menu()
	var tile := view.tile_at(at)
	if aiming.is_empty() or tile.x < 0:
		controller.tap_tile(tile)
		return
	var actor: int = controller.selected if int(aiming["kind"]) == Kind.ABILITY else int(aiming["index"])
	controller.world.give(actor, int(aiming["kind"]), tile.x * 256 + 128, tile.y * 256 + 128)
	aiming = {}
	controller.changed.emit()


## What the hint says while a choice waits to be aimed: where to tap, and
## how to put it away (its portrait, or the Sage's or Cast's button).
func _aim_hint() -> String:
	var key := "HEIST_AIM" if int(aiming["kind"]) == Kind.ABILITY else "HEIST_AIM_HAND"
	return Strings.t(key, str(aiming["words"]))


func _get_out() -> void:
	aiming = {}
	controller.get_out()


## The hand's two orders as the kit draws them (KitControls.big_action),
## in the hand's place and keeping its state: Cast, the main action, in gold
## and the largest thing to tap; Get out in leather, smaller, since red is
## the alarm's alone (the gate's colour roles; §21.8 names no colour for
## it). Each keeps its icon over its word at every text size.
func _dress_hand() -> void:
	var cast := _hand_order("heistcontrols/cast", Strings.t("HEIST_CAST"), hand._open_casts, "gold",
		Vector2(92, 76), 34.0)
	var go := _hand_order("heistcontrols/getout", Strings.t("HEIST_GET_OUT"), _get_out, "leather",
		Vector2(66, 54), 24.0)
	for pair: Array in [[hand.cast_button, cast], [hand.go_button, go]]:
		var old: Button = pair[0]
		var at := old.get_index()
		hand.remove_child(old)
		old.free()
		hand.add_child(pair[1])
		hand.move_child(pair[1], at)
	hand.cast_button = cast
	hand.go_button = go


## One of the hand's orders: the kit's big action at `least` points, its
## icon at `icon_points`, as wide and tall as its word needs with §20.8's
## large text. Its icon is meta "icon" and its word meta "words", as the
## hand's squares (HeistHand.show_state greys the icon, never the word).
func _hand_order(icon: String, words: String, call: Callable, look: String, least: Vector2,
		icon_points: float) -> Button:
	var b := KitControls.big_action(icon, words, call, look)
	b.tooltip_text = words
	b.size_flags_vertical = Control.SIZE_SHRINK_END
	b.size_flags_horizontal = Control.SIZE_SHRINK_END
	var column := b.get_child(b.get_child_count() - 1) as VBoxContainer
	var pic := column.get_node("Icon") as Control
	pic.custom_minimum_size = Vector2.ONE * UI.px(icon_points)
	pic.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	var l := column.get_child(column.get_child_count() - 1) as Label
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	b.set_meta("icon", pic)
	b.set_meta("words", l)
	var fit := func() -> void:
		# In the narrow text's single row a long phrase ("Sem lançamentos")
		# stands on two lines, so the tray keeps inside the frame (§21.1).
		# With §20.8's large text it does so too once it is too wide to
		# keep its row beside Get out, so the hand's row never wraps and
		# the tray stays under the loot (AD-R15).
		var wide := UI.px(least.x) * (1.5 if Settings.text_scale <= 130 else 2.2)
		if l.text.contains(" ") and l.get_minimum_size().x + UI.px(16) > wide:
			l.text = HeistHand.two_lines(l.text)
		b.custom_minimum_size = Vector2(maxf(UI.px(least.x), l.get_minimum_size().x + UI.px(16)),
			maxf(UI.px(least.y), l.get_minimum_size().y + UI.px(icon_points + 10.0)))
	fit.call()
	l.minimum_size_changed.connect(fit)
	return b


## The hint's words as `_refresh` has them, said whole unless `_fit_hint`
## found no room for them.
func _set_hint(words: String) -> void:
	if words != _hint_source:
		_hint_source = words
		_hint_level = 0
		_hint_measured_at = -1.0
	hint_label.text = words if _hint_level == 0 else words.get_slice(" · ", 0)
	hint_panel.visible = _hint_level < 2


## A hint too long for one line says only its first clause. §20.8's large
## text in a long language can stand the lower column (the hint over the
## controls) on the HUD's loot. The hint gives way, a step a layout: first it
## says only its first clause, then it hides; the loot and the controls never
## do. A new hint starts whole again.
func _fit_hint() -> void:
	if not playing or top_column_node == null or not hud.visible or _hint_level >= 2 or column_node.size.y <= 0.0 \
			or not is_visible_in_tree():
		return
	# A column whose box is not yet its content's height is mid-layout: its
	# place says nothing about room.
	for moving: Control in [top_column_node, column_node]:
		var safe := moving.get_parent_control()
		if not is_equal_approx(moving.size.y, moving.get_combined_minimum_size().y) \
				or not is_equal_approx(safe.size.y, safe.get_combined_minimum_size().y):
			return
	# A tip says one line: a hint that would wrap says its first clause, so
	# the tip over the tray stands no taller than the design's and the crew
	# on the world stay in sight.
	if _hint_level == 0 and hint_label.get_line_count() > 1 and " · " in _hint_source:
		_hint_level = 1
		_set_hint(_hint_source)
		return
	var low := column_node.global_position.y
	var top := top_column_node.get_global_rect().end.y + UI.px(Tokens.number("size", "gap_points"))
	# Once a step a layout: the containers settle a frame late.
	if low >= top or is_equal_approx(low, _hint_measured_at):
		return
	_hint_measured_at = low
	_hint_level += 2 if _hint_level == 0 and not " · " in _hint_source else 1
	_set_hint(_hint_source)


## The gait's small button: its footprints and its word, a tap steps it
## (walk, crouch, run).
func _gait_pill() -> Button:
	var b := UI.action("", controller.next_gait, "leather", Strings.term("GAIT", "Walk"))
	b.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	UI.dress(b, "leather", 14.0)
	var row := HBoxContainer.new()
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", UI.px(2))
	row.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var feet := FxDraw.new(func(ci: Control) -> void:
		FxIcons.order(ci, ci.size * 0.5, minf(ci.size.x, ci.size.y), str(b.get_meta("icon", "")), FxSkin.ON_DARK))
	feet.custom_minimum_size = Vector2.ONE * UI.px(22)
	row.add_child(feet)
	var l := UI.label(Strings.term("GAIT", "Walk"), 13.0)
	l.set_meta("bold", true)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(l)
	b.add_child(row)
	b.set_meta("icon", "Walk")
	b.set_meta("words", l)
	var fit := func() -> void:
		b.custom_minimum_size = Vector2(maxf(UI.px(UI.CONTROL_POINTS), l.get_minimum_size().x + UI.px(36)),
			UI.px(UI.CONTROL_POINTS))
	fit.call()
	l.minimum_size_changed.connect(fit)
	return b


## A small order (a rehearsal's Pause): a leather square with its drawn
## icon, named in words for a screen reader and on a long press.
func _order(words: String, call: Callable, icon: String) -> Button:
	var b := UI.action("", call, "leather", words)
	b.tooltip_text = words
	b.custom_minimum_size = Vector2.ONE * UI.px(UI.CONTROL_POINTS)
	b.size_flags_vertical = Control.SIZE_SHRINK_END
	UI.dress(b, "leather", 12.0)
	b.set_meta("icon", icon)
	var draw := FxDraw.new(func(ci: Control) -> void:
		FxIcons.order(ci, ci.size * 0.5, minf(ci.size.x, ci.size.y) * 0.55, str(b.get_meta("icon", icon)), FxSkin.ON_DARK))
	draw.set_anchors_preset(Control.PRESET_FULL_RECT)
	b.add_child(draw)
	return b


## A HUD button in the kit's material: leather, gold for the main action,
## red for leaving ("alarm"); a button asked for on parchment is leather.
func _button(words: String, call: Callable, kind := "leather", _radius := 16.0) -> Button:
	var look: String = {"gold": "gold", "alarm": "red"}.get(kind, "leather")
	var b := UI.action(words, call, look)
	UI.fit(b)
	return b
