class_name FixAuditClientTests
extends RefCounted
## The client audit's proofs (FX4-4, docs/security/audit-2026-11/client.md):
## each finding the audit proved, by its id. A finding fixed here is a plain
## check that failed before its fix. One proven and not fixed here (its code
## is read-only for this task, or its fix is on the server) is a still-open
## check: it passes while the defect is there, and once the defect is fixed it
## fails and says to make it a plain check.

const ACCESS := "a1.k0.acc1.7.9999999999999.ACCESS-SECRET-MAC"
const RENEWED := ACCESS + "2"
const REFRESH := "r1.k0.7.0.REFRESH-SECRET-MAC"
const REFRESH_2 := "r1.k0.7.1.REFRESH-SECRET-TWO"

var tree: SceneTree
var check: Callable


## The server's rule for ending a session (server/src/auth_http.mjs): by
## bearer, only a live access token; by refresh token, no bearer needed. A
## route in `slow` answers that many frames late, as a slow network does.
class SessionServer:
	extends FakeTransport
	var live: Array[String] = []
	var slow: Dictionary = {}

	func send(method: HTTPClient.Method, url: String, headers: PackedStringArray,
			body: PackedByteArray) -> Dictionary:
		var path := ("/" + url.split("/", false, 2)[2] if url.contains("://") else url).get_slice("?", 0)
		for i in int(slow.get(path, 0)):
			await (Engine.get_main_loop() as SceneTree).process_frame
		var said: Variant = JSON.parse_string(body.get_string_from_utf8()) if body.size() > 0 else null
		var by_refresh := said is Dictionary and (said as Dictionary).has("refreshToken")
		if method == HTTPClient.METHOD_POST and path == "/v1/session/end" and not by_refresh:
			var bearer := ""
			for h: String in headers:
				if h.begins_with("Authorization: Bearer "):
					bearer = h.trim_prefix("Authorization: Bearer ")
			if not live.has(bearer):
				calls.append({"route": "POST /v1/session/end", "url": path, "headers": headers, "body": body})
				await (Engine.get_main_loop() as SceneTree).process_frame
				return {"status": 401, "body": JSON.stringify({"error": "session_refused"}).to_utf8_buffer()}
		return await super.send(method, url, headers, body)


func _init(t: SceneTree, c: Callable) -> void:
	tree = t
	check = c


func run() -> void:
	await _sign_out_during_a_renewal()
	await _sign_out_falls_back_to_the_refresh_token()
	_second_remix_keeps_the_players_island()
	await _second_preview_swaps_the_shown_law()
	await _swap_not_on_the_island_is_refused()
	await _swap_publish_is_refused_while_weaving()
	await _late_realm_load_is_dropped()
	await _first_target_prefers_a_curated_island()
	_outbox_reads_only_whole_items()
	await _study_is_sent_once()
	await _rehearsal_card_runs_its_own_crew()
	_action_log_keeps_no_account_ids()
	await _failed_blocks_keep_the_blocked_list()


## Audit finding <id>: proven, not fixed here. `holds` is whether the defect
## is still there: the check passes while it is, and once it is fixed the
## check fails and says to flip it into a plain check of the right behaviour.
func _still_open(id: String, name: String, holds: bool, detail: String) -> void:
	check.call("%s (open): %s" % [id, name], holds,
		("" if holds else "fixed now: make it a plain check. ") + detail)


func _fake(name: String, transport: FakeTransport) -> Services:
	var outbox := "user://outbox-audit-%s-test.json" % name
	for suffix: String in ["", "-auth", "-leases", "-notices"]:
		DirAccess.remove_absolute(outbox.get_basename() + suffix + ".json")
	var s := Fixtures.answered(Services.build(tree.root, "https://edge.example", transport, outbox))
	s.router.change = func(_path: String) -> void: pass
	s.auth = AuthSession.new(s.api, FakeSecureStore.new(), FakePlatformIdentity.new(), s.auth.path)
	s.api.stale = s.auth.stale
	s.auth_flow = AuthController.new(s)
	transport.on("POST /v1/session", {"account": "acc1", "token": ACCESS, "expiresIn": 3600, "refreshToken": REFRESH})
	transport.on("POST /v1/session/refresh", {"account": "acc1", "token": RENEWED, "expiresIn": 3600,
		"refreshToken": REFRESH_2})
	transport.on("POST /v1/session/end", {"ended": 1})
	transport.on("GET /v1/session", {"account": "acc1", "devices": 2})
	transport.on("GET /v1/session/devices", {"devices": [], "identities": []})
	transport.on("PUT /v1/age", {"ageBand": "18+"})
	transport.on("GET /v1/balance", {"starlight": 1, "essence": 2})
	transport.on("GET /v1/words", {"words": []})
	return s


## Services answered by `transport` and signed in with a bare token, as the
## feature tests build them.
func _plain(name: String, transport: FakeTransport) -> Services:
	var s := Fixtures.answered(Services.build(tree.root, "https://edge.example", transport,
		"user://outbox-audit-%s-test.json" % name))
	s.api.token = "t"
	s.router.change = func(_path: String) -> void: pass
	return s


static func _routes(t: FakeTransport) -> Array[String]:
	var out: Array[String] = []
	for c: Dictionary in t.calls:
		out.append(str(c["route"]))
	return out


static func _body(call: Dictionary) -> Dictionary:
	var said: Variant = JSON.parse_string((call["body"] as PackedByteArray).get_string_from_utf8()) \
		if (call["body"] as PackedByteArray).size() > 0 else null
	return said if said is Dictionary else {}


static func _until(done: Callable, frames := 600) -> void:
	while not done.call() and frames > 0:
		frames -= 1
		await (Engine.get_main_loop() as SceneTree).process_frame


## CLI-2: a renewal on its way when the player signs out. The sign-out ends
## the session it holds and forgets it; then the renewal's answer comes and
## is adopted, so the phone holds a live session after signing out (§20.1's
## sign-out, docs/security/auth.md). The sign-out waits for the renewal and
## ends the session the renewal brought.
func _sign_out_during_a_renewal() -> void:
	var t := SessionServer.new()
	var s := _fake("renewing", t)
	t.live = [ACCESS, RENEWED]
	await s.auth_flow.sign_in()
	t.slow = {"/v1/session/refresh": 12}
	var renewing := [true]
	var renew := func() -> void:
		await s.auth.ensure(true)
		renewing[0] = false
	renew.call()
	await s.auth_flow.sign_out()
	await _until(func() -> bool: return not renewing[0])
	var routes := _routes(t)
	var renewed_at := routes.rfind("POST /v1/session/refresh")
	var ended_at := routes.rfind("POST /v1/session/end")
	check.call("CLI-2: a sign-out while a renewal is on its way waits for it and ends the session it brought: the "
			+ "phone holds no token after signing out (20.1)",
		renewed_at >= 0 and ended_at > renewed_at and s.api.token == "" and not s.auth.remembered()
			and not s.auth.fresh(),
		"renewed at %d, ended at %d, token held %s, refresh kept %s" % [renewed_at, ended_at, s.api.token != "",
			s.auth.remembered()])
	s.close()


## CLI-5: the access token looks fresh to the phone (its clock does not run
## in deep sleep, so the server's lapse is not seen) but the server refuses
## it. The sign-out then gives up: the refresh token, alive for its full life,
## is never ended. It should end the session with the refresh token instead.
func _sign_out_falls_back_to_the_refresh_token() -> void:
	var t := SessionServer.new()
	var s := _fake("refused", t)
	t.live = [ACCESS]
	await s.auth_flow.sign_in()
	t.live = []
	var told := await s.auth.sign_out()
	var by_refresh := t.calls.filter(func(c: Dictionary) -> bool:
		return c["route"] == "POST /v1/session/end" and _body(c).get("refreshToken") == REFRESH)
	check.call("CLI-5: a sign-out whose access token the server refuses ends the session with the refresh token "
			+ "(20.1)",
		by_refresh.size() == 1 and told.ok,
		"ended by refresh token %d time(s), answered %s" % [by_refresh.size(), told.code])
	s.close()


## CLI-4: §18.6, a player's creation is never overwritten. The player's own
## island is kept when a remix replaces it; a second remix replaces the
## first, and the first remix, not the player's island, must be what goes.
func _second_remix_keeps_the_players_island() -> void:
	var was := Draft.path
	Draft.path = "user://island-audit-test.rbi"
	for f: String in [Draft.path, Draft._origin(), Draft._kept(), Draft._kept_origin()]:
		DirAccess.remove_absolute(f)
	var own := PackedByteArray([1, 1, 1])
	var first := PackedByteArray([2, 2, 2])
	var second := PackedByteArray([3, 3, 3])
	Draft.keep(own)
	Draft.start_remix(first, "w-first")
	Draft.start_remix(second, "w-second")
	var now := Draft.island()
	var origin := Draft.remix_of()
	Draft.restore()
	var back := Draft.island()
	var back_origin := Draft.remix_of()
	for f: String in [Draft.path, Draft._origin(), Draft._kept(), Draft._kept_origin()]:
		DirAccess.remove_absolute(f)
	Draft.path = was
	check.call("CLI-4: a second remix keeps the player's own island to restore, not the first remix (18.6)",
		now == second and origin == "w-second" and back == own and back_origin == "",
		"draft %s from %s; restored %s from '%s'" % [now, origin, back, back_origin])


## The Heart's curation loaded, its island published with Slow rivers.
func _curation(name: String, transport: FakeTransport) -> Services:
	var s := _plain(name, transport)
	transport.on("GET /v1/curation/heart", CurationTests.sample())
	transport.on("GET /v1/bundles/b-cur", CurationTests.island())
	transport.on("GET /v1/words", FirstTests.words())
	s.curation_flow.open("heart")
	await s.curation_flow.load_curation()
	return s


## CLI-6: two swaps previewed one after the other (G54). The second looks
## for the slot's woven law on the draft, which the first already changed, so
## the draft keeps the first law while the swap names the second: what is
## shown is not what is woven.
func _second_preview_swaps_the_shown_law() -> void:
	var transport := FakeTransport.new()
	var s := await _curation("preview", transport)
	s.curation_flow.preview_swap(1, "bloom")
	s.curation_flow.preview_swap(1, "half_gravity")
	var slice: Dictionary = s.store.get_slice(CurationState.CURATION)
	var island := CurationPresenter.draft_island(slice)
	var shown := island != null and CurationPresenter.pylon(island, "half_gravity") != CurationState.NO_POST
	var stale := island != null and CurationPresenter.pylon(island, "bloom") != CurationState.NO_POST
	check.call("CLI-6: a second swap previewed shows its own law on the draft, not the first one's (13.3, G54)",
		shown and not stale and slice["swap"] == {"slot": 1, "law": "half_gravity"},
		"half gravity shown %s, bloom left %s, swap %s" % [shown, stale, slice["swap"]])
	s.close()


## CLI-7: a swap whose slot's law has no pylon on the published island (a
## swap woven but not yet published, CLI-1, leaves the island with the old
## law) changes nothing on the draft, yet is taken as previewed: applying it
## spends the Aether on a weaving the island does not show.
func _swap_not_on_the_island_is_refused() -> void:
	var transport := FakeTransport.new()
	var s := await _curation("absent", transport)
	var view := CurationTests.sample()
	view["swaps"][0]["law"] = "embers"
	s.store.dispatch(&"curation_loaded", {"view": view, "fetch": false})
	s.curation_flow.preview_swap(1, "bloom")
	transport.on("POST /v1/weaving", {"weaving": {}})
	await s.curation_flow.apply_swap()
	var slice: Dictionary = s.store.get_slice(CurationState.CURATION)
	var woven := _routes(transport).has("POST /v1/weaving")
	check.call("CLI-7: a swap whose law is not on the island is refused at the preview, and nothing is woven (13.3)",
		not woven and (slice["swap"] as Dictionary).is_empty() and slice["error"] == "swap_not_on_island",
		"woven %s, swap %s, error '%s'" % [woven, slice["swap"], slice["error"]])
	s.close()


## CLI-1: a swap is woven (its Aether spent, the slot set to the new law,
## ready in §5.6's minutes) and the draft published at once; the server's
## island check (universe.mjs's publish, SR-16) takes only ready laws, so
## the publish is refused as law_not_woven and the island keeps the old
## pylon. The fake answers as the server does.
func _swap_publish_is_refused_while_weaving() -> void:
	var transport := FakeTransport.new()
	var s := await _curation("weaving", transport)
	s.curation_flow.preview_swap(1, "bloom")
	transport.on("POST /v1/weaving", {"weaving": {}})
	transport.on("PUT /v1/islands/heart", {"error": "island_not_publishable", "problems": ["law_not_woven"]}, 422)
	await s.curation_flow.apply_swap()
	var slice: Dictionary = s.store.get_slice(CurationState.CURATION)
	var sent := PackedByteArray()
	for c: Dictionary in transport.calls:
		if c["route"] == "PUT /v1/islands/heart":
			sent = c["body"]
	var island := RulebornIsland.new()
	var carried := not sent.is_empty() and island.read(sent) \
		and CurationPresenter.pylon(island, "bloom") != CurationState.NO_POST
	# Audit finding CLI-1
	_still_open("CLI-1", "a curation swap is woven and paid, then its publish is refused while it weaves (13.3, 5.6)",
		_routes(transport).has("POST /v1/weaving") and carried and slice["error"] == "island_not_publishable",
		"woven, published with bloom %s, error '%s'" % [carried, slice["error"]])
	s.close()


## CLI-10: the realm view opened on one realm, then another before the
## first's island came: the first load writes its island under the second
## realm, which then shows the Heart's island.
func _late_realm_load_is_dropped() -> void:
	var transport := FakeTransport.new()
	var s := _plain("realm", transport)
	var d := RealmTests.slices()
	transport.on("GET /v1/universe", d["universe"]["view"])
	transport.on("GET /v1/weaving", d["weaving"]["view"])
	transport.on("GET /v1/home", d["home"]["view"])
	transport.on("GET /v1/bundles/b-heart", LandingTests.island(true))
	s.realm_flow.open("heart")
	var loading := [true]
	var loader := func() -> void:
		await s.realm_flow.load_realm()
		loading[0] = false
	loader.call()
	s.store.dispatch(&"realm_opened", {"realm": "outer-1"})
	await _until(func() -> bool: return not loading[0])
	var slice: Dictionary = s.store.get_slice(RealmState.REALM)
	check.call("CLI-10: a realm's island that comes after another realm was opened is dropped, not shown as the "
			+ "other realm's (23.2)",
		slice["realm"] == "outer-1" and (slice["island"] as PackedByteArray).is_empty(),
		"realm %s, island %d bytes" % [slice["realm"], (slice["island"] as PackedByteArray).size()])
	s.close()


## CLI-11: the target list's fallback (§12.22): the game's own generated
## islands only when no player's island is there. A player's island still
## generated (curated, never authored, §13.3) is a player's island; only the
## generator's own are the fallback (the client twin of RB-06).
func _first_target_prefers_a_curated_island() -> void:
	var transport := FakeTransport.new()
	var s := _plain("target", transport)
	transport.on("GET /v1/targets", {"1": "list-1"})
	transport.on("GET /v1/bundles/list-1", {"candidates": [
		{"bundle": "gen", "owner": "the-game-generator", "origin": "generated"},
		{"bundle": "cur", "owner": "p2", "origin": "generated"}]})
	var r := await s.heists.first_target("p1")
	var got := str((r.value as Dictionary).get("bundle", "")) if r.ok and r.value is Dictionary else r.code
	check.call("CLI-11: the first target is a player's curated island before the game's own generated one (12.22)",
		got == "cur", "chose %s" % got)
	s.close()


## CLI-13: an outbox file with an item its reader takes but its sender
## cannot (no `json`, a key that is not a string): the flush stops at it, so
## nothing behind it is ever sent. The reader keeps whole items only.
func _outbox_reads_only_whole_items() -> void:
	var file := "user://outbox-audit-read-test.json"
	var f := FileAccess.open(file, FileAccess.WRITE)
	f.store_string(JSON.stringify([
		{"key": "k1", "route": "/v1/heists", "body": "AA=="},
		{"key": 5, "route": "/v1/heists", "body": "AA==", "json": false},
		{"key": "k3", "route": "/v1/heists", "body": 7, "json": false},
		{"key": "k4", "route": "/v1/heists", "body": "AA==", "json": true}]))
	f.close()
	var box := Outbox.new(file)
	var whole := true
	for i: Dictionary in box._items:
		whole = whole and i.get("key") is String and i.get("route") is String and i.get("body") is String \
			and i.get("json") is bool
	var kept := box._items.map(func(i: Dictionary) -> Variant: return i.get("key"))
	DirAccess.remove_absolute(file)
	check.call("CLI-13: the outbox reads only items it can send, with `json` false when it is missing",
		whole and kept == ["k1", "k4"], "kept %s, all whole %s" % [kept, whole])


## CLI-15: §7.6, one heist allows one study. Two taps on a study tile before
## the first answer came send two studies; the second's answer says the tile
## studied nothing.
func _study_is_sent_once() -> void:
	var transport := FakeTransport.new()
	var s := _plain("study", transport)
	transport.on("POST /v1/codex/study", {"studied": "bloom", "pages": 2})
	var was := App.services
	App.services = s
	var store: Store = s.store
	store.dispatch(&"heist_started", {"target": {"bundle": "b-x", "trace": false}})
	store.dispatch(&"heist_finished", {"replay": PackedByteArray(),
		"verdict": {"ok": true, "grade": "Clean", "banked": 0}})
	var result: ResultScreen = load("res://scenes/result_screen.tscn").instantiate()
	tree.root.add_child(result)
	await tree.process_frame
	result._verdict = {"token": "tok"}
	result._study("bloom")
	result._study("bloom")
	await _until(func() -> bool: return transport.calls.size() >= 2, 30)
	var sent := _routes(transport).count("POST /v1/codex/study")
	result.queue_free()
	store.dispatch(&"heist_started", {})
	await tree.process_frame
	App.services = was
	check.call("CLI-15: a study tile tapped twice before its answer sends one study (7.6)", sent == 1,
		"%d studies sent" % sent)
	s.close()


## CLI-18: the Rehearse tab, a cautious crew playing, then the greedy card
## tapped. The card's tap asks to run, and a run while one plays finishes the
## one playing: the greedy card shows the cautious crew's result.
func _rehearsal_card_runs_its_own_crew() -> void:
	var island := RulebornIsland.new()
	island.reset(3)
	var stage := StageRehearsal.new(island.bytes())
	tree.root.add_child(stage)
	await tree.process_frame
	var playing := stage.playing
	var greedy: Button = null
	for b: Button in (stage._cards["greedy"] as Control).find_children("*", "Button", true, false):
		if b.get_meta("style", "") == "greedy":
			greedy = b
	var found := greedy != null
	if found:
		greedy.pressed.emit()
	var runs := stage.runs
	var style := stage.style
	stage.queue_free()
	await tree.process_frame
	# Audit finding CLI-18
	_still_open("CLI-18", "a style card tapped while another crew plays shows that crew's result under its own name "
			+ "(13)",
		playing and found and style == "greedy" and runs == 1,
		"playing %s, card found %s, style %s, runs %d" % [playing, found, style, runs])


## CLI-22: §20.5, the defect report's action log carries no player's
## identifier. The store logs every action's short fields, the signed-in
## account and an accepted friend's among them.
func _action_log_keeps_no_account_ids() -> void:
	var actions := ActionLog.new()
	actions.add("action", "signed_in", {"account": "acc1"})
	actions.add("action", "friend_accepted", {"friend": "acc2"})
	actions.add("action", "share_invite", {"invite": "inv-123"})
	actions.add("action", "navigated", {"name": "shop"})
	var said := []
	for e: Dictionary in actions.entries():
		said.append_array((e["fields"] as Dictionary).values())
	check.call("CLI-22: the action log keeps no account id or invite code, and keeps a screen's name (20.5)",
		said == ["shop"], "%s" % [said])


## CLI-24: the friends screen loaded, two players blocked, then loaded again
## while the blocks call fails: the screen says nobody is blocked.
func _failed_blocks_keep_the_blocked_list() -> void:
	var transport := FakeTransport.new()
	var s := _plain("blocks", transport)
	transport.on("GET /v1/friends", [])
	transport.on("GET /v1/friends/feed", [])
	transport.on("GET /v1/blocks", [{"account": "ffee0011", "at": 1}, {"account": "ffee0022", "at": 2}])
	await s.social_flow.load_friends()
	var before: Array = s.store.get_slice(SocialState.FRIENDS).get("blocked", [])
	transport.on("GET /v1/blocks", {"error": "internal"}, 500)
	await s.social_flow.load_friends()
	var after: Array = s.store.get_slice(SocialState.FRIENDS).get("blocked", [])
	check.call("CLI-24: a blocks call that fails keeps the blocked players shown, not an empty list (17.8)",
		before.size() == 2 and after.size() == 2, "%d blocked, then %d" % [before.size(), after.size()])
	s.close()
