class_name AuthTests
extends RefCounted
## Signing in and out on the phone (docs/security/auth.md): the refresh token
## in secret storage and nowhere else, renewed before its hour and on the
## monotonic clock, one renewal at a time, the platform asked with the
## server's nonce, and a sign-out that ends the session, forgets every token
## and private state, keeps the unsent queue for the account and never signs
## in again by itself. No token reaches a log or a file. Then the same
## against the local server.

const ACCESS := "a1.k0.acc1.7.9999999999999.ACCESS-SECRET-MAC"
const REFRESH := "r1.k0.7.0.REFRESH-SECRET-MAC"
const REFRESH_2 := "r1.k0.7.1.REFRESH-SECRET-TWO"

var tree: SceneTree
var check: Callable
var server_url := ""


func _init(t: SceneTree, c: Callable, url: String) -> void:
	tree = t
	check = c
	server_url = url


func run() -> void:
	await _signs_in_and_keeps_the_refresh_token_secret()
	await _refreshes_before_the_hour()
	await _one_renewal_at_a_time()
	await _refused_refresh_asks_the_platform()
	await _google_nonce()
	await _sign_out_clears_everything()
	await _sign_out_offline_is_owed()
	await _signed_back_in_gets_the_queue_back()
	_words()
	_pinning()
	await _panel()
	if server_url != "":
		await _against_server()


## Services on a fake network, with the platform's storage and identity faked.
func _fake(name: String) -> Array:
	var outbox := "user://outbox-auth-%s-test.json" % name
	for suffix: String in ["", "-auth", "-leases", "-parked-acc1", "-notices"]:
		DirAccess.remove_absolute(outbox.get_basename() + suffix + ".json")
	var transport := FakeTransport.new()
	var s := Fixtures.answered(Services.build(tree.root, "https://edge.example", transport, outbox))
	s.router.change = func(_path: String) -> void: pass
	var vault := FakeSecureStore.new()
	var platform := FakePlatformIdentity.new()
	s.auth = AuthSession.new(s.api, vault, platform, s.auth.path)
	s.api.stale = s.auth.stale
	transport.on("POST /v1/session", {"account": "acc1", "token": ACCESS, "expiresIn": 3600, "refreshToken": REFRESH})
	transport.on("POST /v1/session/refresh", {"account": "acc1", "token": ACCESS + "2", "expiresIn": 3600,
		"refreshToken": REFRESH_2})
	transport.on("POST /v1/session/end", {"ended": 1})
	transport.on("GET /v1/session", {"account": "acc1", "devices": 2})
	transport.on("PUT /v1/age", {"ageBand": "18+"})
	transport.on("GET /v1/balance", {"starlight": 1, "essence": 2})
	return [s, transport, vault, platform]


func _routes(t: FakeTransport) -> Array[String]:
	var out: Array[String] = []
	for c: Dictionary in t.calls:
		out.append(str(c["route"]))
	return out


func _bearer(call: Dictionary) -> String:
	for h: String in call["headers"]:
		if h.begins_with("Authorization: Bearer "):
			return h.trim_prefix("Authorization: Bearer ")
	return ""


## Every file the tests' services keep, read: none may hold a token.
func _files_hold(s: Services, secret: String) -> Array[String]:
	var found: Array[String] = []
	var base := s.outbox.path.get_basename()
	for f: String in DirAccess.get_files_at("user://"):
		var p := "user://" + f
		if p.begins_with(base) and FileAccess.get_file_as_string(p).contains(secret):
			found.append(p)
	return found


func _signs_in_and_keeps_the_refresh_token_secret() -> void:
	var f := _fake("in")
	var s: Services = f[0]
	var vault: FakeSecureStore = f[2]
	var r := await s.auth_flow.sign_in()
	var plain := SecureStore.new()
	plain.write("k", "v")
	check.call("a sign-in keeps the access token in memory and the refresh token in the platform's secret "
			+ "storage only, never a plain file; without the platform's plugin, nothing outlives the launch",
		r.ok and s.api.token == ACCESS and vault.read(AuthSession.REFRESH_KEY) == REFRESH and s.auth.fresh()
			and _files_hold(s, REFRESH).is_empty() and _files_hold(s, ACCESS).is_empty()
			and not plain.persistent() and SecureStore.new().read("k") == ""
			and str(s.store.get_slice(AuthState.AUTH)["status"]) == "signed_in"
			and int(s.store.get_slice(AuthState.AUTH)["devices"]) == 2,
		"%s %s %s" % [r, s.api.token, _files_hold(s, REFRESH)])
	s.close()


func _refreshes_before_the_hour() -> void:
	var f := _fake("refresh")
	var s: Services = f[0]
	var t: FakeTransport = f[1]
	var vault: FakeSecureStore = f[2]
	await s.auth_flow.sign_in()
	# The hour nearly out, as the monotonic clock counts it: the next call renews first.
	s.auth.expires_at = Time.get_ticks_msec() + AuthSession.EARLY_MS - 1
	t.calls.clear()
	var b := await s.account.balance()
	var routes := _routes(t)
	check.call("a token at its last minute is refreshed before the call, the refresh token spent and replaced, "
			+ "timed on the engine's monotonic clock rather than the phone's",
		b.ok and routes.slice(0, 1) == ["POST /v1/session/refresh"] and routes.has("GET /v1/balance")
			and _bearer(t.calls[t.calls.size() - 1]) == ACCESS + "2" and vault.read(AuthSession.REFRESH_KEY) == REFRESH_2
			and not routes.has("POST /v1/session"),
		str(routes))
	s.close()


func _one_renewal_at_a_time() -> void:
	var f := _fake("once")
	var s: Services = f[0]
	var t: FakeTransport = f[1]
	await s.auth_flow.sign_in()
	t.calls.clear()
	var results: Array[Result] = []
	var go := func() -> void: results.append(await s.auth.ensure(true))
	go.call()
	go.call()
	await go.call()
	while results.size() < 3:
		await tree.process_frame
	var refreshes := _routes(t).count("POST /v1/session/refresh")
	check.call("three calls that find the session stale at once share one refresh: two would look like a stolen "
			+ "refresh token and end the session",
		refreshes == 1 and results.all(func(r: Result) -> bool: return r.ok), "%d %s" % [refreshes, results])
	s.close()


func _refused_refresh_asks_the_platform() -> void:
	var f := _fake("refused")
	var s: Services = f[0]
	var t: FakeTransport = f[1]
	var vault: FakeSecureStore = f[2]
	var platform: FakePlatformIdentity = f[3]
	vault.write(AuthSession.REFRESH_KEY, "r1.k0.7.3.SPENT")
	t.then("POST /v1/session/refresh", [[{"error": "internal"}, 503]])
	var down := await s.auth.ensure(true)
	var kept := vault.read(AuthSession.REFRESH_KEY)
	t.then("POST /v1/session/refresh", [[{"error": "session_refused"}, 401]])
	var r := await s.auth.ensure(true)
	check.call("a refresh the server never decided keeps its token for the next try; a refused one is "
			+ "forgotten and the platform asked again, silently",
		not down.ok and kept == "r1.k0.7.3.SPENT" and r.ok and platform.asked.size() == 1
			and s.api.token == ACCESS and vault.read(AuthSession.REFRESH_KEY) == REFRESH,
		"%s %s %s" % [down, r, platform.asked])
	s.close()


func _google_nonce() -> void:
	var f := _fake("nonce")
	var s: Services = f[0]
	var t: FakeTransport = f[1]
	var platform: FakePlatformIdentity = f[3]
	platform.nonce = true
	platform.answer = {"idToken": "g.token.sig"}
	t.on("POST /v1/session/nonce", {"nonce": "n1.k0.abc.123.MAC", "expiresIn": 300})
	var r := await s.auth.ensure(true)
	var sent: Variant = JSON.parse_string((t.calls[t.calls.size() - 1]["body"] as PackedByteArray).get_string_from_utf8())
	check.call("Google's proof is asked for with the server's nonce first, and sent as the platform gave it (24.8)",
		r.ok and _routes(t) == ["POST /v1/session/nonce", "POST /v1/session"] and platform.asked == ["n1.k0.abc.123.MAC"]
			and sent is Dictionary and (sent as Dictionary)["credential"] == {"idToken": "g.token.sig"},
		"%s %s" % [_routes(t), platform.asked])
	s.close()


func _sign_out_clears_everything() -> void:
	var f := _fake("out")
	var s: Services = f[0]
	var t: FakeTransport = f[1]
	var vault: FakeSecureStore = f[2]
	await s.auth_flow.sign_in()
	# A heist played offline, waiting; a lease in stock; a session event unsent.
	t.on("POST /v1/heists/lease-1", {"error": "internal"}, 503)
	s.outbox.put("lease-1", "/v1/heists/lease-1", PackedByteArray([1, 2, 3]))
	s.heists.stock.add("bundle-1", {"token": "lease-2", "expiresAt": 1}, PackedByteArray([4]))
	s.notices.start(1000)
	var reset: Array[Dictionary] = []
	s.auth_flow.reset = func(shown: Dictionary) -> void: reset.append(shown)
	t.calls.clear()
	var pending := await s.auth_flow.before_sign_out()
	var told := await s.auth_flow.sign_out()
	var end: Dictionary = {}
	for c: Dictionary in t.calls:
		if c["route"] == "POST /v1/session/end":
			end = c
	var parked := Outbox.new(s.auth_flow.parked_path("acc1"))
	var again := await s.auth.ensure()
	var later := AuthSession.new(s.api, vault, FakePlatformIdentity.new(), s.auth.path)
	var routes_after := _routes(t)
	check.call("signing out ends the session on the server with its own token, forgets every token, empties the "
			+ "lease stock and unsent events, keeps the unsent heist for this account and says so, starts the app "
			+ "again from nothing, and never signs in again by itself, this launch or the next",
		told.ok and pending == 1 and _bearer(end) == ACCESS and s.api.token == ""
			and vault.read(AuthSession.REFRESH_KEY) == "" and s.outbox.pending() == 0 and parked.pending() == 1
			and parked.has("lease-1") and s.heists.stock.count() == 0 and s.notices.pending().is_empty()
			and reset.size() == 1 and reset[0]["status"] == "signed_out" and int(reset[0]["parked"]) == 1
			and str(s.store.get_slice(AppState.SESSION)["account"]) == "" and again.code == "signed_out"
			and later.signed_out() and not routes_after.has("POST /v1/session") and _files_hold(s, ACCESS).is_empty(),
		"%s %s %s %s" % [told, pending, routes_after, reset])
	# And no token in the log of everything the player did.
	var logged := s.store.action_log.dump()
	check.call("no token reaches the app's log: actions and failures name routes and codes, never a token",
		not logged.contains(ACCESS) and not logged.contains(REFRESH) and not logged.contains("SECRET-MAC")
			and logged.contains("v1/heists"), logged.substr(0, 300))
	s.close()


func _sign_out_offline_is_owed() -> void:
	var f := _fake("offline")
	var s: Services = f[0]
	var t: FakeTransport = f[1]
	var vault: FakeSecureStore = f[2]
	await s.auth_flow.sign_in()
	s.auth_flow.reset = func(_shown: Dictionary) -> void: pass
	s.auth.expires_at = 1          # the hour out: the refresh token proves the session
	t.offline = true
	var told := await s.auth_flow.sign_out(true)
	var owed := s.auth.revocation_owed()
	var shown: Dictionary = s.store.get_slice(AuthState.AUTH)
	t.offline = false
	t.calls.clear()
	await s.auth_flow.sign_in()
	var first: Dictionary = t.calls[0] if not t.calls.is_empty() else {}
	var body: Variant = JSON.parse_string((first.get("body", PackedByteArray()) as PackedByteArray).get_string_from_utf8())
	check.call("a sign-out with no network still forgets the session on the phone, and the server is told — "
			+ "everywhere, with the refresh token alone — before anything else once it answers",
		not told.ok and owed and s.api.token == ACCESS and bool(shown["owed"])
			and str(first.get("route", "")) == "POST /v1/session/end" and _bearer(first) == ""
			and body is Dictionary and (body as Dictionary)["refreshToken"] == REFRESH and (body as Dictionary)["everywhere"]
			and not s.auth.revocation_owed() and vault.read(AuthSession.REVOKE_KEY) == "",
		"%s %s %s" % [told, owed, _routes(t)])
	s.close()


func _signed_back_in_gets_the_queue_back() -> void:
	var f := _fake("back")
	var s: Services = f[0]
	var t: FakeTransport = f[1]
	await s.auth_flow.sign_in()
	s.auth_flow.reset = func(_shown: Dictionary) -> void: pass
	t.offline = true
	s.outbox.put("lease-9", "/v1/heists/lease-9", PackedByteArray([9]))
	await s.auth_flow.sign_out()
	t.offline = false
	t.on("POST /v1/heists/lease-9", {"validated": true})
	t.calls.clear()
	await s.auth_flow.sign_in()
	check.call("the same account signing in again gets the heists it left waiting back, and sends them",
		_routes(t).has("POST /v1/heists/lease-9") and s.outbox.pending() == 0
			and not FileAccess.file_exists(s.auth_flow.parked_path("acc1")), str(_routes(t)))
	s.close()


func _words() -> void:
	var statuses: Array[String] = []
	var raw := false
	for st: String in AuthState.STATUSES:
		var v := AuthPresenter.panel({"status": st, "reason": "too_many_requests", "devices": 3, "parked": 2,
			"owed": true})
		statuses.append(str(v["line"]))
		raw = raw or str(v["line"]).contains("too_many_requests") or str(v["line"]) == ""
	var failed := AuthPresenter.panel({"status": "failed", "reason": "platform_identity_refused"})
	var confirm := AuthPresenter.confirm(false, 2)
	var everywhere := AuthPresenter.confirm(true, 0)
	check.call("every sign-in state reads as words — first launch, signing in, signed in, offline, a failure with "
			+ "its reason, signed out — and each sign-out's confirm names what still waits to be sent",
		not raw and str(failed["line"]).contains(Errors.text("platform_identity_refused"))
			and str(confirm["words"]).contains("2") and str(everywhere["title"]) == Strings.t("AUTH_SIGN_OUT_ALL")
			and str(everywhere["words"]).contains(Strings.t("AUTH_LOST_DEVICE"))
			and not str(confirm["words"]).contains(Strings.t("AUTH_LOST_DEVICE"))
			and not str(everywhere["words"]).contains(Strings.t("AUTH_CONFIRM_PENDING", 0)),
		" | ".join(statuses))


func _pinning() -> void:
	var crypto := Crypto.new()
	var key := crypto.generate_rsa(2048)
	var cert := crypto.generate_self_signed_certificate(key, "CN=pin.example,O=Ruleborn test")
	var path := "user://pins-test.pem"
	cert.save(path)
	var junk := "user://pins-junk-test.pem"
	FileAccess.open(junk, FileAccess.WRITE).store_string("not a certificate")
	check.call("the server's certificate can be pinned: a PEM file of the authority its chain ends at becomes "
			+ "the only trust, and none, or one that cannot be read, leaves the platform's own",
		HttpTransport.pinned(path) != null and HttpTransport.pinned("") == null
			and HttpTransport.pinned("user://no-such.pem") == null and HttpTransport.pinned(junk) == null
			and not Api.secure("http://edge.example") and Api.secure("https://edge.example"))


func _panel() -> void:
	var f := _fake("panel")
	var s: Services = f[0]
	var held := App.services
	App.services = s
	await s.auth_flow.sign_in()
	var screen := Control.new()
	tree.root.add_child(screen)
	var panel := AuthPanel.new()
	screen.add_child(panel)
	await tree.process_frame
	var buttons := {}
	for b: Button in panel.find_children("*", "Button", true, false):
		buttons[str(b.get_meta("auth", ""))] = b
	var shown := buttons.has("sign_out") and buttons.has("sign_out_everywhere")
	(buttons["sign_out_everywhere"] as Button).pressed.emit()
	for _i: int in 4:
		await tree.process_frame
	var dialog := screen.find_child("Dialog", true, false)
	var cancel: Button = null
	if dialog != null:
		for b: Button in dialog.find_children("*", "Button", true, false):
			if b.get_meta("auth", "") == "cancel":
				cancel = b
	var asked := dialog != null and cancel != null
	var safe_focused := asked and cancel.has_focus()
	if asked:
		cancel.pressed.emit()
	await tree.process_frame
	var closed := dialog == null or not is_instance_valid(dialog) or dialog.is_queued_for_deletion()
	check.call("the account panel offers sign out and sign out everywhere when signed in, and asks first in a "
			+ "dialog whose safe answer is the one focused; cancelled, nothing is signed out",
		shown and asked and safe_focused and closed and s.auth.fresh() and not s.auth.signed_out(),
		"%s asked=%s focused=%s closed=%s" % [buttons.keys(), asked, safe_focused, closed])
	screen.queue_free()
	App.services = held
	s.close()


## The whole round trip against server/src/main.mjs, with its stubbed sign-in.
func _against_server() -> void:
	var outbox := "user://outbox-auth-server-test.json"
	DirAccess.remove_absolute(outbox.get_basename() + "-auth.json")
	var s := Fixtures.answered(Services.build(tree.root, server_url, null, outbox))
	s.router.change = func(_path: String) -> void: pass
	var vault := FakeSecureStore.new()
	var platform := FakePlatformIdentity.new()
	platform.answer = "test:auth"
	s.auth = AuthSession.new(s.api, vault, platform, s.auth.path)
	s.api.stale = s.auth.stale
	s.auth_flow.reset = func(_shown: Dictionary) -> void: pass
	var r := await s.auth_flow.sign_in()
	var first := s.api.token
	var refresh := vault.read(AuthSession.REFRESH_KEY)
	s.auth.expires_at = Time.get_ticks_msec() + 1
	var b := await s.account.balance()
	var rotated := vault.read(AuthSession.REFRESH_KEY)
	var second := s.api.token
	var told := await s.auth_flow.sign_out()
	# The token signed out with, tried again by hand: the server refuses it.
	s.api.token = second
	var after := await s.api.raw(HTTPClient.METHOD_GET, "/v1/balance")
	s.api.token = ""
	check.call("against the server: signed in with the platform, refreshed before the hour with the refresh "
			+ "token rotated, and signed out — the token refused at once after",
		r.ok and first != "" and refresh.begins_with("r1.") and b.ok and rotated != refresh and second != first
			and told.ok and after.code == "session_refused",
		"%s %s %s %s" % [r, b, told, after])
	s.close()
