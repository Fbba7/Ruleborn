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
var _owed := 0.0
var _alarm := 0
var _live_wards := -1
var _pylons := -1
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
			hint_label.text = Errors.message("HEIST_NONE", "island_does_not_load")
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
	hint_label.text = Strings.t("HEIST_ASKING")
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
		hint_label.text = Errors.message("HEIST_NONE", problem)
		offline_prompt = UI.row(-1.0, true)
		offline_prompt.add_child(UI.button(Strings.t("OFFLINE_TRY_AGAIN"), func() -> void: start_online(services), true))
		column_node.add_child(offline_prompt)
		return
	if not Outbox.transient(Result.failure(problem)):
		hint_label.text = Errors.message("HEIST_NONE", problem)
		return
	_offer_offline(services)


## §24.12's exception, recommended against: the stocked lease is played on the
## phone, its haul shown as confirming until the server confirms it.
func _offer_offline(services: Services) -> void:
	var stocked := services.heists.stock.count() > 0
	hint_label.text = Strings.t("OFFLINE_RECOMMEND" if stocked else "OFFLINE_NONE")
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
		hint_label.text = Strings.t("HEIST_CHECKING")
		var played := await services.workshop_flow.submit(str(play["token"]), replay)
		services.store.dispatch(&"heist_verdict", WorkshopController.settled(played, local))
	elif not lease.is_empty():
		hint_label.text = Strings.t("HEIST_CHECKING")
		var plan: Dictionary = services.store.get_slice(AppState.HEIST).get("plan", {})
		var answer := await services.heists.submit(str(lease["token"]), replay, plan.get("crew", []))
		var settled := HeistController.settled(answer, local)
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
	hud.show_state(controller.world)
	_feel(controller.world)
	var me: Dictionary = controller.world.crew()[controller.selected]
	hint_label.text = Strings.t("HEIST_SKIFF_HINT") if controller.calling_skiff else \
		Strings.t("HEIST_HINT", Strings.term("ROLE", me["role"]))
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
	(hint_label.get_parent() as Control).visible = not choosing
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
		b.accessibility_name = Strings.t("HEIST_CREW_CHOSEN" if chosen else "HEIST_CREW", role)
		b.tooltip_text = b.accessibility_name
	if pause_button != null:
		pause_button.accessibility_name = Strings.t("HEIST_RESUME" if paused else "HEIST_PAUSE")
		pause_button.tooltip_text = pause_button.accessibility_name
		pause_button.set_meta("icon", "play" if paused else "pause")
		FxSkin.redraw(pause_button)
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
	card.add_child(FxSkin.label(words, UI.TEXT_POINTS + 6.0, "parchment", true))
	(card.get_child(0) as Label).autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
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
	gait_menu = FxSkin.panel("parchment", 18.0, 8.0)
	var row := HBoxContainer.new()
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_theme_constant_override("separation", UI.px(6))
	gait_menu.add_child(row)
	# The designs' order, quietest first: Crouch, Walk, Run.
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
	view.tapped.connect(func(at: Vector2) -> void:
		close_gait_menu()
		controller.tap_tile(view.tile_at(at)))
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
	column = lower
	hint_label = FxSkin.label("", 13.0)
	hint_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var hint := FxSkin.panel("glass", 14.0, 6.0)
	hint.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	hint.custom_minimum_size.x = UI.px(240)
	hint.add_child(hint_label)

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

	# §21.8: the crew's portraits at the bottom left, Get out at the bottom
	# right with the other orders above it, all above the corners §21.1 keeps
	# clear; mirrored for a left-handed player (§20.8).
	column.add_child(FxSkin.camera_row(view))
	# §21.8 as the designs lay it out: the crew's portraits at the bottom
	# left; at the bottom right a column of round orders (Halt and Drop, the
	# gait with its name beneath) standing on a round red Get out. Mirrored
	# for a left-handed player (§20.8).
	# With §20.8's large text the orders stand over the portraits rather
	# than beside them, so neither runs off the phone.
	var band: BoxContainer = HBoxContainer.new()
	if Settings.text_scale > 130:
		band = VBoxContainer.new()
	band.mouse_filter = Control.MOUSE_FILTER_IGNORE
	band.add_theme_constant_override("separation", UI.px(6))
	if Settings.left_handed:
		band.layout_direction = Control.LAYOUT_DIRECTION_RTL
	var crew_row := UI.row(2.0, true)
	crew_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	crew_row.alignment = FlowContainer.ALIGNMENT_BEGIN
	crew_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	crew_row.size_flags_vertical = Control.SIZE_SHRINK_END
	crew_node = crew_row
	band.add_child(crew_row)
	var crew := controller.world.crew()
	for i in crew.size():
		var b := FxPortrait.new(str(crew[i]["role"]), controller.select.bind(i))
		crew_buttons.append(b)
		crew_row.add_child(b)
	# With large text a rehearsal's pause stands at the end of the portraits,
	# low in reach, rather than under the taller HUD.
	if Settings.text_scale > 130 and pause_button != null:
		pause_button.reparent(crew_row)
	var right := VBoxContainer.new()
	right.mouse_filter = Control.MOUSE_FILTER_IGNORE
	right.add_theme_constant_override("separation", UI.px(4))
	right.size_flags_vertical = Control.SIZE_SHRINK_END
	actions_node = right
	# With large text every order stands on one row (wrapping if it must),
	# so the hand's controls stay low in the thumb's reach (§21.1).
	var large := Settings.text_scale > 130
	var small: Container = HBoxContainer.new()
	if large:
		small = UI.row(4.0, true)
	small.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if small is FlowContainer:
		(small as FlowContainer).alignment = FlowContainer.ALIGNMENT_END
	else:
		(small as HBoxContainer).alignment = BoxContainer.ALIGNMENT_END
		small.add_theme_constant_override("separation", UI.px(4))
	small.add_child(_order(Strings.t("HEIST_HALT"), controller.halt, "halt"))
	small.add_child(_order(Strings.t("HEIST_DROP"), controller.drop_half, "drop"))
	right.add_child(small)
	var main: Container = small
	if not large:
		main = HBoxContainer.new()
		main.mouse_filter = Control.MOUSE_FILTER_IGNORE
		(main as HBoxContainer).alignment = BoxContainer.ALIGNMENT_END
		main.add_theme_constant_override("separation", UI.px(6))
	# The designs' Cast and Get out: rounded squares with an icon over their
	# word. The gait stands where Cast does (the build has no casts yet).
	gait_button = _square(Strings.term("GAIT", "Walk"), controller.next_gait, "leather")
	gait_button.set_meta("icon", "Walk")
	var feet := FxDraw.new(func(ci: Control) -> void:
		FxIcons.order(ci, ci.size * 0.5, minf(ci.size.x, ci.size.y), str(gait_button.get_meta("icon", "")),
			FxSkin.ON_DARK))
	feet.custom_minimum_size = Vector2.ONE * UI.px(28)
	(gait_button.get_meta("box") as VBoxContainer).add_child(feet)
	(gait_button.get_meta("box") as VBoxContainer).move_child(feet, 0)
	main.add_child(gait_button)
	var go := _square(Strings.t("HEIST_GET_OUT"), controller.get_out, "red")
	var skiff := Icons.view("heistcontrols/getout", 28.0)
	(go.get_meta("box") as VBoxContainer).add_child(skiff)
	(go.get_meta("box") as VBoxContainer).move_child(skiff, 0)
	main.add_child(go)
	if not large:
		right.add_child(main)
	band.add_child(right)
	if band is VBoxContainer:
		band.move_child(right, 0)
		right.size_flags_horizontal = Control.SIZE_FILL
		# The hint as wide as the phone, so it takes fewer lines.
		hint.size_flags_horizontal = Control.SIZE_FILL
	actions_band = band
	column.add_child(band)
	# The hint on the bottom line, under the hand's controls (the designs').
	column.add_child(hint)
	# Clear of the bottom corners, where §21.1 puts nothing to tap.
	column.add_child(FxSkin.corner_clear())


## A small order (Halt, Drop): a leather square with its drawn icon, named
## in words for a screen reader and on a long press.
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


## The designs' square order (Cast, Get out): a rounded square in the kit's
## `look`, an icon over its word inside it; the screen puts the icon in the
## VBox under meta "box". Its word is meta "words"; a screen reader hears it.
func _square(words: String, call: Callable, look: String) -> Button:
	var b := UI.action("", call, look, words)
	b.tooltip_text = words
	b.custom_minimum_size = Vector2(UI.px(66), UI.px(60))
	b.size_flags_vertical = Control.SIZE_SHRINK_END
	UI.dress(b, look, 16.0)
	var box := VBoxContainer.new()
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 0)
	box.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var l := FxSkin.label(words, 14.0)
	l.add_theme_constant_override("outline_size", UI.px(3))
	box.add_child(l)
	b.add_child(box)
	b.set_meta("box", box)
	b.set_meta("words", l)
	# As wide as its word needs with §20.8's large text, never narrower than
	# the designs' square.
	var fit := func() -> void:
		b.custom_minimum_size = Vector2(maxf(UI.px(66), l.get_minimum_size().x + UI.px(14)),
			maxf(UI.px(60), l.get_minimum_size().y + UI.px(36)))
	fit.call()
	l.minimum_size_changed.connect(fit)
	return b


## A HUD button in the kit's material: leather, gold for the main action,
## red for leaving ("alarm"); a button asked for on parchment is leather.
func _button(words: String, call: Callable, kind := "leather", _radius := 16.0) -> Button:
	var look: String = {"gold": "gold", "alarm": "red"}.get(kind, "leather")
	var b := UI.action(words, call, look)
	UI.fit(b)
	return b
