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
