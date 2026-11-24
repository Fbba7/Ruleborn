class_name AuditClient2Tests
extends RefCounted
## The client audit's second pass (FX3-7, docs/security/audit-2026-11/client.md):
## the findings the first pass left unproven, each proven or rejected here by
## its id. The audit fixes nothing, so a proven finding is a still-open check:
## it passes while the defect is there, and once the defect is fixed it fails
## and says to make it a plain check. A rejected finding is a plain check of
## the behaviour that shows it is not a defect.

const NOW := 1_000_000_000

var tree: SceneTree
var check: Callable
var mount: Callable


## A server for these proofs. A route in `slow` answers that many frames
## late, as a slow network does. With `slots` on, POST /v1/offline makes each
## weave against the slots it has filled so far and refuses one whose slot is
## taken `slot_taken`, as server/src/weaving.mjs does (its line 203).
class SlowServer:
	extends FakeTransport
	var slow: Dictionary = {}
	var slots := false
	var woven: Dictionary = {}

	func send(method: HTTPClient.Method, url: String, headers: PackedStringArray,
			body: PackedByteArray) -> Dictionary:
		var path := ("/" + url.split("/", false, 2)[2] if url.contains("://") else url).get_slice("?", 0)
		for i in int(slow.get(path, 0)):
			await (Engine.get_main_loop() as SceneTree).process_frame
		if slots and not offline and method == HTTPClient.METHOD_POST and path == "/v1/offline":
			calls.append({"route": "POST /v1/offline", "url": path, "headers": headers, "body": body})
			await (Engine.get_main_loop() as SceneTree).process_frame
			var said: Dictionary = AuditClient2Tests._parse(body)
			var results: Array = []
			for a: Dictionary in said.get("actions", []):
				var at := "%s:%d" % [str(a.get("realm", "")), int(a.get("slot", 0))]
				if woven.has(at):
					results.append({"refused": "slot_taken"})
				else:
					woven[at] = str(a.get("law", ""))
					results.append({"confirmed": true})
			return {"status": 200, "body": JSON.stringify({"results": results, "universe": {}, "home": {},
				"weaving": {}}).to_utf8_buffer()}
		return await super.send(method, url, headers, body)


func _init(t: SceneTree, c: Callable, m: Callable) -> void:
	tree = t
	check = c
	mount = m


func run() -> void:
	await _offline_heist_plays_another_crew()
	await _offline_weaves_aim_at_one_slot()
	await _offline_builds_of_one_building()
	await _collect_all_clears_another_changes_busy()
	await _replay_shows_orders_from_its_end()
	await _replay_of_another_crew_keeps_the_old_one()
	await _planner_drops_the_cards_owner()
	await _defences_trace_drops_across_and_owner()
	await _heist_not_playing_takes_orders()
	await _held_vault_offers_gaits_and_cracks()
	await _held_menu_is_not_modal()
	_short_words_bold_at_any_size()
	_heart_draws_the_spire_twice()
	_full_realm_loses_a_building()
	await _notice_pulse_overshoots()
	await _locked_control_still_acts()
	_curtains_hang_from_part_of_the_rim()
	_heart_pool_on_the_grid()


## Audit finding <id>: proven, not fixed here. `holds` is whether the defect
## is still there: the check passes while it is, and once it is fixed the
## check fails and says to flip it into a plain check of the right behaviour.
func _still_open(id: String, name: String, holds: bool, detail: String) -> void:
	check.call("%s (open): %s" % [id, name], holds,
		("" if holds else "fixed now: make it a plain check. ") + detail)


## Services answered by `transport` and signed in with a bare token, as the
## feature tests build them; the outbox starts empty.
func _plain(name: String, transport: FakeTransport) -> Services:
	var outbox := "user://outbox-audit2-%s-test.json" % name
	for suffix: String in ["", "-auth", "-leases", "-notices"]:
		DirAccess.remove_absolute(outbox.get_basename() + suffix + ".json")
	var s := Fixtures.answered(Services.build(tree.root, "https://edge.example", transport, outbox))
	s.api.token = "t"
	s.router.change = func(_path: String) -> void: pass
	return s


static func _parse(body: PackedByteArray) -> Dictionary:
	var said: Variant = JSON.parse_string(body.get_string_from_utf8()) if body.size() > 0 else null
	return said if said is Dictionary else {}


static func _sent(t: FakeTransport, route: String) -> Array:
	return t.calls.filter(func(c: Dictionary) -> bool: return c["route"] == route)


static func _until(done: Callable, frames := 600) -> void:
	while not done.call() and frames > 0:
		frames -= 1
		await (Engine.get_main_loop() as SceneTree).process_frame


## The weaving view of weaving_tests.gd, with both of the Heart's slots free.
static func _two_free() -> Dictionary:
	var view := WeavingTests.sample()
	view["realms"][1]["slots"] = [{"slot": 1, "law": null, "rests_until": null},
		{"slot": 2, "law": null, "rests_until": null}]
	return view


## The offer for `law` in the Heart, as the Weaving screen shows it now: its
## button's args are what a tap weaves (weaving_screen.gd line 452).
static func _heart_offer(s: Services, law: String) -> Dictionary:
	var w := WeavingPresenter.screen(s.store.get_slice(WeavingState.WEAVING), NOW)
	for r: Dictionary in w["realms"]:
		if r["realm"] != "heart":
			continue
		for o: Dictionary in (r["recommended"] as Array) + (r["others"] as Array):
			if o["law"] == law:
				return o
	return {}


# Audit finding CLI-3.
## CLI-3: §12.5's Start makes the planner's plan the heist's crew. Online,
## the heist screen plays the plan's crew and manifest (heist_screen.gd lines
## 242-253). A stocked lease played with no network (§24.12) begins with
## HeistController.CREW and no manifest (line 169), but `finish` submits the
## plan's crew ids (line 291) and heist_repository.gd puts them in the
## submission's ?crew=. The plan here names four characters: the heist plays
## three, and the submission names four, which server/src/home.mjs line 665
## refuses `crew_mismatch` on reconnection, so the haul is lost. With three
## ids the server takes it, and rests characters that played as nobody.
func _offline_heist_plays_another_crew() -> void:
	var t := SlowServer.new()
	var s := _plain("crew", t)
	t.offline = true
	var was: Services = App.services
	App.services = s
	s.store.dispatch(&"heist_started", {"target": {"bundle": "b9"}, "plan": {"crew": [12, 15, 19, 21]}})
	s.heists.stock.add("b9", {"token": "t9", "seed": "7", "ticks": 4500, "expiresAt": 1}, PackedByteArray())
	var screen: HeistScreen = await mount.call("heist_screen")
	screen.set_process(false)
	for i in 10:
		await tree.process_frame
	var played := screen.play_stocked(s)
	var crew := screen.controller.world.crew_size()
	await screen.finish()
	var urls: Array = _sent(t, "POST /v1/heists/t9").map(func(c: Dictionary) -> String: return str(c["url"]))
	_still_open("CLI-3", "a stocked heist played offline after the planner's Start plays three default crew with "
			+ "no manifest, and submits the plan's four ids, which the server refuses crew_mismatch (§12.5, §24.12)",
		played and crew == 3 and urls.has("/v1/heists/t9?crew=12,15,19,21"),
		"played %s, crew %d, sent %s" % [played, crew, urls])
	screen.queue_free()
	App.services = was
	s.close()
	await tree.process_frame


# Audit finding CLI-19.
## CLI-19: §24.12 lets the device weave offline, confirmed on reconnection. The
## Heart has two free slots; the player weaves Stillness and then Bloom with
## no network. A queued weave leaves the view as it was (weaving_state.gd's
## `queued`), and the presenter aims every offer at the first free slot of
## that view (weaving_presenter.gd lines 110-113 and 166). So both weaves
## name slot 1, and on reconnection the server weaves the first and refuses
## the second `slot_taken`, though slot 2 was free all along.
func _offline_weaves_aim_at_one_slot() -> void:
	var t := SlowServer.new()
	t.slots = true
	var s := _plain("weave-slots", t)
	t.on("GET /v1/weaving", _two_free())
	await s.weaving_flow.load_weaving()
	t.offline = true
	var first := _heart_offer(s, "stillness")
	await s.weaving_flow.weave(str(first["args"]["realm"]), int(first["args"]["slot"]), str(first["args"]["law"]))
	var second := _heart_offer(s, "bloom")
	await s.weaving_flow.weave(str(second["args"]["realm"]), int(second["args"]["slot"]), str(second["args"]["law"]))
	var kept := s.outbox.pending()
	t.offline = false
	await s.outbox.flush(s.api)
	var slots: Array = []
	for c: Dictionary in _sent(t, "POST /v1/offline"):
		for a: Dictionary in _parse(c["body"]).get("actions", []):
			slots.append(int(a.get("slot", 0)))
	var refused: Dictionary = s.store.get_slice(WeavingState.WEAVING)["refused"]
	_still_open("CLI-19", "two weaves queued offline in a realm with two free slots both name its first free "
			+ "slot, so the second is refused slot_taken on reconnection (§24.12, §5.6)",
		kept == 2 and slots == [1, 1] and str(refused.get("code", "")) == "slot_taken",
		"queued %d, slots sent %s, refused %s" % [kept, slots, refused])
	s.close()


# Audit finding CLI-20 (rejected).
## CLI-20 was suspected: two offline builds of the same building collapse
## into one outbox key, so the second is lost. Rejected: the key names every
## field of the action (universe_controller.gd line 52: realm, kind, n and
## level), and the outbox keeps the first of two items with one key
## (outbox.gd line 35). A queued build leaves the view as it was, so a second
## tap on the same button is the same action. The server would refuse that
## one `not_the_next_level` (server/src/universe.mjs line 267), so keeping
## one is right. A build of another building, or to another level, has its
## own key and is kept.
func _offline_builds_of_one_building() -> void:
	var t := SlowServer.new()
	var s := _plain("builds", t)
	t.offline = true
	await s.universe_flow.build("heart", "garden", 1, 2)
	await s.universe_flow.build("heart", "garden", 1, 2)
	var once := s.outbox.pending()
	await s.universe_flow.build("heart", "garden", 2, 2)
	await s.universe_flow.build("heart", "garden", 1, 3)
	check.call("CLI-20 (rejected): the same offline build tapped twice is kept once, as the server would refuse "
			+ "it the second time; another building, or another level, is kept beside it (§24.12, §10.2)",
		once == 1 and s.outbox.pending() == 3,
		"after two taps %d, after two more builds %d" % [once, s.outbox.pending()])
	s.close()


# Audit finding CLI-21.
## CLI-21: the roster's changes go one at a time: a second tap while one is
## on its way is ignored (roster_controller.gd line 109). `collect_all` takes
## no part in that guard (lines 91-106). A collect made while a level is on
## its way dispatches `roster_changed`, which clears the level's busy flag
## (roster_state.gd's `change_made`), so a second tap on the level goes out
## while the first is still on its way. And two `collect_all` at once (the
## Home screen left and opened again while its collect is on its way, so its
## new button is enabled, home.gd line 718) collect every producer twice.
func _collect_all_clears_another_changes_busy() -> void:
	var t := SlowServer.new()
	var s := _plain("collect", t)
	var home := {"characters": [{"id": 1, "level": 1}],
		"producers": [{"realm": "heart", "kind": "garden", "stored": 5000}]}
	t.on("GET /v1/home", home)
	t.on("POST /v1/home/collect", {"collected": {"resource": "essence", "made": 5, "kept": 2, "paid": 3},
		"home": home})
	t.on("POST /v1/home/characters/1/level", {"home": home})
	t.on("GET /v1/balance", {"starlight": 1, "essence": 2})
	await s.roster_flow.load_roster()
	t.slow = {"/v1/home/characters/1/level": 12}
	var going := [0]
	var level := func() -> void:
		going[0] += 1
		await s.roster_flow.level(1, 2)
		going[0] -= 1
	level.call()
	var busy_before := str(s.store.get_slice(RosterState.ROSTER)["busy"])
	await s.roster_flow.collect_all()
	var busy_after := str(s.store.get_slice(RosterState.ROSTER)["busy"])
	var still_going: bool = going[0] == 1
	level.call()
	await _until(func() -> bool: return going[0] == 0)
	var levels := _sent(t, "POST /v1/home/characters/1/level").size()
	# Two collects at once.
	t.slow = {"/v1/home/collect": 6}
	var collecting := [0]
	var collect := func() -> void:
		collecting[0] += 1
		await s.roster_flow.collect_all()
		collecting[0] -= 1
	var before := _sent(t, "POST /v1/home/collect").size()
	collect.call()
	collect.call()
	await _until(func() -> bool: return collecting[0] == 0)
	var collects := _sent(t, "POST /v1/home/collect").size() - before
	_still_open("CLI-21", "a collect made while a level is on its way clears the level's busy flag, so a second "
			+ "tap sends the level again; two collects at once collect each producer twice (§9.3, §11.4)",
		busy_before == "level:1:2" and still_going and busy_after == "" and levels == 2 and collects == 2,
		"busy %s, after the collect %s while the level was on its way %s, levels sent %d, collects sent %d" % [
			busy_before, busy_after, still_going, levels, collects])
	s.close()


## A heist of `crew` on the fixture realm, recorded: at tick 100 crew member
## 0 is sent to (8, 8) and member 1 calls the skiff to (1, 1); it plays on to
## tick 200. Loaded to be watched, as the replay screen loads one (its line
## 87), it stands at tick 0.
static func _recorded(crew: int) -> RulebornReplay:
	var live := RulebornReplay.new()
	live.start("7", 4500, crew, PackedByteArray())
	for i in 100:
		live.step()
	live.give(0, HeistController.Kind.MOVE_TO, 8 * 256, 8 * 256)
	live.give(1, HeistController.Kind.SKIFF, 1 * 256, 1 * 256)
	for i in 100:
		live.step()
	var watched := RulebornReplay.new()
	watched.load(live.record(), PackedByteArray())
	return watched


## A WorldView in the tree, its frames not run, showing `r`.
func _view(r: RulebornReplay) -> WorldView:
	var view := WorldView.new()
	view.set_process(false)
	tree.root.add_child(view)
	await tree.process_frame
	view.show_replay(r)
	return view


# Audit finding CLI-16.
## CLI-16: §5.4's skiff is where the last Get out called it, and the ground's
## goal ring is where the chosen crew member was last sent. Both read the
## replay's commands from its end (world_view.gd `_sync_skiff`, lines
## 732-747; fx_ground.gd `order_goal`, line 171) with no look at the tick.
## While a heist is played that is the same thing, as the log ends now. A
## replay loaded to be watched holds every command from the start, so at
## tick 0 the skiff already hovers where the crew calls it at tick 100, and
## crew member 0's ring marks a goal it is not sent to until then.
func _replay_shows_orders_from_its_end() -> void:
	var r := _recorded(3)
	var orders: Array = r.commands().map(func(c: Dictionary) -> String: return "%d:%d" % [c["tick"], c["kind"]])
	var view := await _view(r)
	view._sync_skiff(0.0)
	var skiff := view._skiff != null and view._skiff.visible
	var goal := FxGround.order_goal(view, 0)
	_still_open("CLI-16", "a replay watched from its start shows the skiff and crew member 0's goal ring at tick 0, "
			+ "where the crew calls and sends them only at tick 100 (§5.4, §21.8)",
		r.tick() == 0 and orders == ["100:%d" % HeistController.Kind.MOVE_TO, "100:%d" % HeistController.Kind.SKIFF]
			and skiff and goal == Vector2(8, 8),
		"tick %d, orders %s, skiff shown %s, goal %s" % [r.tick(), orders, skiff, goal])
	view.queue_free()
	await tree.process_frame


# Audit finding CLI-17.
## CLI-17: `show_replay` rebuilds its statics, and with them the crew's
## figures (`_build_statics` calls `_build_actors`, line 341), only when its
## key changes (lines 271-283): the island's size, features, heights,
## surfaces and realm. The crew is not in it. A five-crew replay shown after
## a three-crew one on the same island keeps the three figures, so two of
## the crew are never drawn, and `_place_actors` moves only the three.
func _replay_of_another_crew_keeps_the_old_one() -> void:
	var three := _recorded(3)
	var five := _recorded(5)
	var view := await _view(three)
	var before := view._crew.size()
	view.show_replay(five)
	var after := view._crew.size()
	var fresh := await _view(five)
	_still_open("CLI-17", "a five-crew replay shown after a three-crew one on the same island keeps three crew "
			+ "figures; a view that shows it first has five (§21.8)",
		before == 3 and five.crew().size() == 5 and after == 3 and fresh._crew.size() == 5,
		"figures before %d, after %d, the replay's crew %d, a fresh view's %d" % [before, after,
			five.crew().size(), fresh._crew.size()])
	view.queue_free()
	fresh.queue_free()
	await tree.process_frame


## CLI-8: the Observatory's card is one holder's island, and the lease names
## none, so server/src/service.mjs line 458 leases its first holder by
## account. The server's card carries no owner (observatory.mjs `card`), and
## the planner drops one if it did: Start's target is the bundle, the Trace
## and `across` only, and heist_screen.gd line 237 leases with its `owner`.
func _planner_drops_the_cards_owner() -> void:
	var s := _plain("owner", FakeTransport.new())
	var d := PlannerTests.slices()
	s.store.dispatch(&"keeper_loaded", {"view": d["keeper"]["view"]})
	s.store.dispatch(&"roster_loaded", {"view": d["roster"]["view"]})
	s.store.dispatch(&"sages_loaded", {"view": d["sages"]["view"]})
	s.store.dispatch(&"codex_loaded", {"view": d["codex"]["view"], "changes": 0})
	var card: Dictionary = (d["planner"]["target"] as Dictionary).duplicate(true)
	card["owner"] = "acct-b"
	s.observatory_flow.raid(card)
	for id: int in [1, 2, 3]:
		s.planner_flow.toggle(id)
	s.planner_flow.start()
	var target: Dictionary = s.store.get_slice(AppState.HEIST).get("target", {})
	_still_open("CLI-8", "a target card that names its owner is started with no owner, so the lease goes to the "
			+ "bundle's first holder, not the player the card showed (§12.4, §12.5)",
		target.get("bundle") == card["bundle"] and not target.has("owner"), "%s" % target)
	s.close()


## CLI-9: Defences' Trace (server/src/defences.mjs line 74) is the raider's
## bundle alone, with no `across`, where the Observatory's Trace card of the
## same raider has it. The controller passes on neither `across` nor an
## owner, so the Trace is leased as the Heart alone, where §5.4's skiffs
## cannot land, even when the raider's realms make a universe.
func _defences_trace_drops_across_and_owner() -> void:
	var s := _plain("trace", FakeTransport.new())
	s.defences_flow.trace({"heist": "h9", "trace": {"bundle": "r1", "across": true, "owner": "acct-r"}})
	var target: Dictionary = s.store.get_slice(AppState.HEIST).get("target", {})
	_still_open("CLI-9", "a Defences Trace is started as the raider's bundle and the Trace alone: a trace that says "
			+ "it crosses a universe, or names its raider, is leased as the Heart alone (§5.4, §12.3)",
		target == {"bundle": "r1", "trace": true}, "%s" % target)
	s.close()


## A heist screen in the tree with no network, after `heist_started` with
## `payload`, its frames not run; with it, the services it was given and the
## ones it replaced. `_close_heist` puts them back.
func _offline_heist(name: String, payload: Dictionary) -> Array:
	var t := SlowServer.new()
	var s := _plain(name, t)
	t.offline = true
	var was: Services = App.services
	App.services = s
	s.store.dispatch(&"heist_started", payload)
	var screen: HeistScreen = await mount.call("heist_screen")
	screen.set_process(false)
	for i in 10:
		await tree.process_frame
	return [screen, s, was]


func _close_heist(shown: Array) -> void:
	(shown[0] as HeistScreen).queue_free()
	App.services = shown[2]
	(shown[1] as Services).close()
	await tree.process_frame


## The kinds of `world`'s commands after the first `from`.
static func _kinds_after(world: RulebornReplay, from: int) -> Array:
	return world.commands().slice(from).map(func(c: Dictionary) -> int: return int(c["kind"]))


# Audit finding CLI-25.
## CLI-25: a Workshop island this build cannot load is said, never swapped
## for the fixture realm (heist_screen.gd lines 106-111): `playing` goes
## false and the hint says why. But `_ready` has already started the fixture
## realm (line 99), and no order checks `playing`: the gait pill
## (`controller.next_gait`), a tap on the world (`_tap_world`), a portrait
## and Get out all still give commands, and each one's `changed` runs
## `_refresh`, which writes the plain heist hint over the reason (lines
## 349-351) and shows the fixture realm (line 339). One tap on the gait pill
## and the island that does not load is gone from the screen, replaced by a
## realm that is not the player's.
func _heist_not_playing_takes_orders() -> void:
	var shown := await _offline_heist("noload", {"island": PackedByteArray([1, 2, 3]),
		"workshop": {"seed": "7", "ticks": 4500, "token": "w"}})
	var screen: HeistScreen = shown[0]
	var reason := Errors.message("HEIST_NONE", "island_does_not_load")
	var said := screen._hint_source
	var stopped := not screen.playing
	var before := screen.controller.world.commands().size()
	screen.controller.next_gait()
	await tree.process_frame
	var given := _kinds_after(screen.controller.world, before)
	_still_open("CLI-25", "a Workshop island that does not load says so and stops the heist, but the gait pill "
			+ "still gives the fixture realm's crew a command and the hint's reason is written over (§18.6)",
		stopped and said == reason and not screen.playing and given == [HeistController.Kind.GAIT]
			and screen._hint_source != reason,
		"stopped %s, said %s, given %s, now says %s" % [stopped, said == reason, given, screen._hint_source])
	await _close_heist(shown)


# Audit finding CLI-26.
## CLI-26: §12.7 and §12.5: a held tap on the Vault offers the load target
## (how full the crew loads before leaving, 50 to 100% in tens). The screen
## has no such menu: `open_gait_menu` (heist_screen.gd lines 462-498) offers
## Crouch, Walk and Run on every tile but an Active crew member's, the Vault
## too, and `_go_at` gives the gait and then `tap_tile` of the held tile,
## which on a shut Vault is a crack. So the player who holds the Vault to
## change the load and chooses Walk sets the gait and orders the crack, and
## the load target cannot be changed during a heist at all.
func _held_vault_offers_gaits_and_cracks() -> void:
	var shown := await _offline_heist("vault", {})
	var screen: HeistScreen = shown[0]
	var vault: Dictionary = screen.controller.world.vault()
	var before := screen.controller.world.commands().size()
	var load_was := screen.controller.load_target
	screen._go_at(0, Vector2i(vault["at"]))
	await tree.process_frame
	var given := _kinds_after(screen.controller.world, before)
	_still_open("CLI-26", "Walk, chosen from the held-tap menu on the Vault, sets the gait and cracks the Vault; "
			+ "the Vault's held tap offers gaits, not the load target (§12.5, §12.7)",
		not screen.controller.choosing and not bool(vault["open"])
			and given == [HeistController.Kind.GAIT, HeistController.Kind.CRACK]
			and screen.controller.load_target == load_was,
		"choosing %s, vault %s, given %s" % [screen.controller.choosing, vault, given])
	await _close_heist(shown)


# Audit finding CLI-27.
## CLI-27: §12.7: "Wheels and held-tap menus are modal: while one is open
## nothing else can be tapped." The gait menu is a panel that lets every tap
## through (`MOUSE_FILTER_IGNORE`, heist_screen.gd line 468) with nothing
## behind it to catch one, and the hand's Get out (`_get_out`, line 843)
## does not close it. Get out tapped while it is open arms the skiff call,
## so Walk then chosen on open ground gives the gait and calls the skiff to
## that tile, where the player asked for a walk.
func _held_menu_is_not_modal() -> void:
	var shown := await _offline_heist("modal", {})
	var screen: HeistScreen = shown[0]
	if screen.controller.choosing:
		screen.controller.land_here()
	screen.view.show_replay(screen.controller.world)
	var at := Vector2(-1, -1)
	var tile := Vector2i(-1, -1)
	var grid := screen.controller.world.size()
	for y in grid.y:
		for x in grid.x:
			var t := Vector2i(x, y)
			if tile.x < 0 and _open_ground(screen.controller, t) and screen.view.tile_at(screen.view.screen_at(t)) == t:
				at = screen.view.screen_at(t)
				tile = t
	screen.open_gait_menu(at)
	var menu := screen.gait_menu
	var lets_through := menu != null and menu.mouse_filter == Control.MOUSE_FILTER_IGNORE
	screen._get_out()
	var still_open := screen.gait_menu != null and is_instance_valid(screen.gait_menu)
	var before := screen.controller.world.commands().size()
	screen._go_at(0, tile)
	await tree.process_frame
	var given := _kinds_after(screen.controller.world, before)
	_still_open("CLI-27", "the held-tap menu lets taps through and stays open over Get out, so Walk then calls "
			+ "the skiff to the held tile (§12.7)",
		tile.x >= 0 and lets_through and still_open
			and given == [HeistController.Kind.GAIT, HeistController.Kind.SKIFF],
		"tile %s, lets through %s, open after Get out %s, given %s" % [tile, lets_through, still_open, given])
	await _close_heist(shown)


## Whether tile `t` holds nothing a tap acts on: no crew member, guard,
## Vault, pylon or ward (HeistController.tap_tile's walk).
static func _open_ground(c: HeistController, t: Vector2i) -> bool:
	for m: Dictionary in c.world.crew():
		if Vector2i(m["at"]) == t:
			return false
	for g: Dictionary in c.world.guards():
		if Vector2i(g["at"]) == t:
			return false
	for w: Dictionary in c.world.wards():
		if Vector2i(w["at"]) == t:
			return false
	if Vector2i(c.world.vault()["at"]) == t:
		return false
	return c.world.features()[t.y * c.world.size().x + t.x] == 0


# Audit finding CLI-28.
## CLI-28: colour_check.gd's contract (its lines 10-12) holds short words at
## 16 points bold, or 24 points regular, to Lc 60, and body text to Lc 75.
## `lc_needed` (lines 77-82) gives Lc 60 to any bold text, whatever its
## size: 13-point bold words pass the gate's check at Lc 60, where the
## contract asks Lc 75 below 16 points.
func _short_words_bold_at_any_size() -> void:
	var asked := ColourCheck.lc_needed(13.0, true)
	_still_open("CLI-28", "13-point bold words are held to the short words' Lc 60, where the check's own contract "
			+ "keeps that for 16 points bold or more (§21.8)",
		asked == ColourCheck.MIN_LC_SHORT and ColourCheck.MIN_LC_SHORT < ColourCheck.MIN_LC_BODY,
		"asked Lc %s at 13 points bold, short %s, body %s" % [asked, ColourCheck.MIN_LC_SHORT,
			ColourCheck.MIN_LC_BODY])


## The universe island of `realm`, built with `buildings`, each
## {kind, n, level}, as server/src/universe.mjs `buildings()` sends them.
static func _island_with(realm: Dictionary, buildings: Array) -> UniverseIsland:
	var island := UniverseIsland.new(realm, Vector3.ZERO)
	island.build(Geo.new(), Geo.new(), UniversePaint.new(), UniversePaint.new(), UniversePaint.new(), buildings)
	return island


# Audit finding CLI-29.
## CLI-29: the Heart's middle is its Spire, drawn as the citadel, and its pin
## (`places["keeper_s_spire:1"]`) is set above it (universe_island.gd lines
## 380-383). The server lists the Spire among the Heart's buildings
## (universe.mjs `buildings()`, and facts.json's STARTING_HEART first of all), and
## the loop after (lines 385-406) skips nothing: it draws the Spire again at
## the first ring spot and moves its pin there, off the citadel.
func _heart_draws_the_spire_twice() -> void:
	var start: Array = []
	for kind: String in ["keeper_s_spire", "vault", "star_well", "aether_spring", "garden", "hearth"]:
		start.append({"kind": kind, "n": 1, "level": 1})
	var heart := _island_with({"realm": "heart", "type": "Heart", "level": 3}, start)
	var pin: Vector3 = heart.places.get("keeper_s_spire:1", Vector3.ZERO)
	var drawn := heart._near_jobs.filter(func(j: Array) -> bool: return j[0] == "keeper_s_spire").size()
	_still_open("CLI-29", "the Heart's starting buildings draw the Spire a second time at a ring spot and move its "
			+ "pin off the citadel (§21.4)",
		pin != heart.at + Vector3(0, 11.0, 0) and Vector2(pin.x, pin.z).length() > 1.0 and drawn == 1,
		"pin %s, citadel at %s, spire drawn near %d" % [pin, heart.at, drawn])


# Audit finding CLI-30.
## CLI-30: an island has 16 building spots (universe_island.gd `RINGS`:
## 1 + 6 + 9), and `_buildings` stops at the last (line 386). A realm full
## at level 1 holds 17 (universe.mjs `allowed()`: one each of the nine outer
## kinds, but eight wards, WARD_LIMITS[0]), so the last the server sends,
## sorted by kind and n, is not drawn and has no pin: ward 8. The Heart,
## whose middle spot is the citadel, has 15 for up to 22.
func _full_realm_loses_a_building() -> void:
	var full: Array = []
	for kind: String in ["aether_spring", "anchor_stone", "garden", "guardian_post", "hearth", "law_pylon",
			"nursery", "star_well", "storehouse"]:
		full.append({"kind": kind, "n": 1, "level": 1})
	for n in range(1, 9):
		full.append({"kind": "ward", "n": n, "level": 1})
	var realm := _island_with({"realm": "outer-1", "type": "Verdant", "level": 1}, full)
	_still_open("CLI-30", "a realm full at level 1 has 17 buildings and 16 spots: its eighth ward is not drawn and "
			+ "has no pin (§10.3, §21.4)",
		full.size() == 17 and realm.places.size() == 16 and realm.places.has("ward:7")
			and not realm.places.has("ward:8"),
		"%d buildings, %d places, ward:8 %s" % [full.size(), realm.places.size(), realm.places.has("ward:8")])


# Audit finding CLI-31.
## CLI-31: §21.8: every interface movement takes 150 to 250 ms, easing out,
## without overshoot. `KitStatus.notice`'s pulse (kit_status.gd lines
## 543-547) grows the mark to 1.15 and back over `pop_ms` each way, 500 ms
## in all, on TRANS_SINE's default ease in and out, and reads the raw token
## rather than `Motion._ms`'s clamp. No screen calls `notice` yet.
func _notice_pulse_overshoots() -> void:
	var was := Settings.reduced_motion
	Settings.reduced_motion = false
	var host := Button.new()
	host.size = Vector2(80, 40)
	tree.root.add_child(host)
	var mark := KitStatus.notice(host, "3")
	var top := 1.0
	var began := Time.get_ticks_msec()
	var back := -1
	for i in 600:
		await tree.process_frame
		top = maxf(top, mark.scale.x)
		if top > 1.01 and is_equal_approx(mark.scale.x, 1.0):
			back = Time.get_ticks_msec() - began
			break
	_still_open("CLI-31", "a notice mark pulses to 1.15 times its size and back over about 500 ms, eased in and out, "
			+ "where interface movement takes 150 to 250 ms, eased out, without overshoot (§21.8)",
		top > 1.1 and back > 400,
		"largest %.3f, back to size after %d ms" % [top, back])
	host.queue_free()
	Settings.reduced_motion = was
	await tree.process_frame


# Audit finding CLI-32.
## CLI-32: kit_status.gd `locked` lays a clear key over the control so "the
## control's own action never runs" (line 491). That holds for a tap; the
## control itself keeps its focus and is not disabled, so a keyboard or
## controller press on it (ui_accept) still runs its
## action. No screen locks a control with it yet.
func _locked_control_still_acts() -> void:
	var ran := [0]
	var b := UI.action("Go", func() -> void: ran[0] += 1)
	b.size = Vector2(120, 60)
	tree.root.add_child(b)
	await tree.process_frame
	KitStatus.locked(b, "Opens at level 3")
	b.grab_focus()
	for down: bool in [true, false]:
		var press := InputEventAction.new()
		press.action = &"ui_accept"
		press.pressed = down
		tree.root.push_input(press)
		await tree.process_frame
	_still_open("CLI-32", "a control under the lock still takes focus and runs its own action on ui_accept",
		b.focus_mode != Control.FOCUS_NONE and not b.disabled and ran[0] == 1,
		"focus mode %d, disabled %s, ran %d" % [b.focus_mode, b.disabled, ran[0]])
	b.queue_free()
	await tree.process_frame


# Audit finding CLI-33.
## CLI-33: the island's curtains (island_builder.gd `roots`, lines 361-373),
## the long roots under its rim, stand at `TAU * (i + ...) / 16` for i up to
## their count. With 16 that is the whole rim. Emberreach has 6, and the
## light detail level (`_few`) halves them, but the divisor stays 16: 6
## curtains hang from the first three-eighths of the rim and the rest has
## none, and at the light level a Verdant island's 8 hang from one half.
## The curtains reach below 4.8 m under the meadow, the other roots never.
func _curtains_hang_from_part_of_the_rim() -> void:
	var bare := {}
	for kind: String in ["verdant", "emberreach"]:
		for light: bool in [false, true]:
			var b := IslandBuilder.new(Vector2i(12, 12), 77, RealmPalette.of(kind), kind)
			b.light = light
			var roots: ArrayMesh = b.roots()[0]
			var hung := PackedInt32Array()
			hung.resize(16)
			for si in roots.get_surface_count():
				var points: PackedVector3Array = roots.surface_get_arrays(si)[Mesh.ARRAY_VERTEX]
				for p in points:
					if p.y < -4.8:
						hung[int(fposmod(atan2(p.z, p.x), TAU) / TAU * 16.0) % 16] += 1
			bare["%s%s" % [kind, " light" if light else ""]] = Array(hung).count(0)
	_still_open("CLI-33", "Emberreach's curtains, and every island's at the light detail level, hang from part of "
			+ "the rim, the rest bare (§21.4)",
		bare["verdant"] == 0 and bare["verdant light"] >= 6 and bare["emberreach"] >= 8,
		"sixteenths of the rim with no curtain: %s" % bare)


# Audit finding CLI-34.
## CLI-34: a waterfall's pool lies on the meadow between the grid and the
## rim, 1.2 m in from the edge, 0.8 m across its radius (island_builder.gd
## `waterfalls`, lines 841-848). The Heart's third fall is at PI * 1.25
## (`fall_angles`, line 824), the grid's corner, where the rim is barely
## further out than the corner itself: on a square grid, of any size, its
## pool's middle is about 0.2 m off the grid, so most of the pool lies over
## the corner tiles, where the crew stands and buildings are. Every other
## fall's pool is 2 m or more clear of the grid.
func _heart_pool_on_the_grid() -> void:
	var near := {}
	var clear := INF
	for side: int in [12, 16]:
		for kind: String in ["heart", "verdant", "tidehold"]:
			var b := IslandBuilder.new(Vector2i(side, side), 77, RealmPalette.of(kind), kind)
			for a in b.fall_angles():
				var r := b.edge(a) - 1.2
				var off := b.off_grid(cos(a) * r, sin(a) * r)
				if kind == "heart" and is_equal_approx(a, PI * 1.25):
					near[side] = off
				else:
					clear = minf(clear, off)
	_still_open("CLI-34", "the Heart's corner waterfall has its pool over the grid's corner tiles, on any square "
			+ "grid; every other fall's pool is clear of the grid (§21.4)",
		near.size() == 2 and near.values().all(func(o: float) -> bool: return o < 0.8) and clear >= 2.0,
		"corner pool's middle off the grid by %s, the others by at least %.2f, pool radius 0.8" % [near, clear])
