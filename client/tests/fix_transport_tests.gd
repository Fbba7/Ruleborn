class_name FixTransportTests
extends RefCounted
## The November bug report's transport and session defects (FX4-1): the HTTP
## transport reaching the tree on a cold start (RB-27), a public call that
## leaves the session's token alone (RB-03), and ending other devices with a
## token that has gone stale (RB-04).

const ACCESS := "a1.k0.acc1.7.9999999999999.ACCESS-SECRET-MAC"
const RENEWED := ACCESS + "2"
const REFRESH := "r1.k0.7.0.REFRESH-SECRET-MAC"
const REFRESH_2 := "r1.k0.7.1.REFRESH-SECRET-TWO"

var tree: SceneTree
var check: Callable


## The server's rule for the session's own routes (server/src/auth_http.mjs):
## ending other devices needs a live access token; one ended by a refresh
## token alone needs none. A route in `slow` answers that many frames late,
## as a slow network does. Anything else answers as FakeTransport does.
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


## A node whose `_ready` builds the services the way App.ready does on a cold
## start (client/app/app.gd: Services.build on the parent, a real
## HttpTransport) and at once makes the first launch's call.
class Launcher:
	extends Node
	var server := ""
	var outbox := ""
	var built: Services
	var answer: Result

	func _ready() -> void:
		built = Services.build(get_parent(), server, null, outbox)
		answer = await built.api.public_json("/v1/words")


func _init(t: SceneTree, c: Callable) -> void:
	tree = t
	check = c


func run() -> void:
	await _transport_joins_the_tree_on_a_cold_start()
	await _public_call_leaves_the_token_alone()
	await _ending_by_refresh_leaves_the_token_alone()
	await _ending_other_devices_renews_a_stale_token()


func _fake(name: String, transport: FakeTransport) -> Services:
	var outbox := "user://outbox-fix-%s-test.json" % name
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


static func _routes(t: FakeTransport) -> Array[String]:
	var out: Array[String] = []
	for c: Dictionary in t.calls:
		out.append(str(c["route"]))
	return out


static func _bearer(call: Dictionary) -> String:
	for h: String in call["headers"]:
		if h.begins_with("Authorization: Bearer "):
			return h.trim_prefix("Authorization: Bearer ")
	return ""


## A token as the details name it: which one, never its text.
static func _said(token: String) -> String:
	return {ACCESS: "the first token", RENEWED: "the renewed token", "": "no token"}.get(token, "another token")


static func _call(t: FakeTransport, route: String) -> Dictionary:
	var i := _routes(t).find(route)
	return t.calls[i] if i >= 0 else {}


static func _until(done: Callable, frames := 600) -> void:
	while not done.call() and frames > 0:
		frames -= 1
		await (Engine.get_main_loop() as SceneTree).process_frame


## RB-27. Root readies its children before it is done setting them up, and
## Godot refuses a child added to a parent that is still busy doing so: a
## cold start builds the services from home's `_ready`, under root. The host
## here stands for root: the launcher is its child, built before the host
## enters the tree, so its `_ready` runs while the host is busy.
func _transport_joins_the_tree_on_a_cold_start() -> void:
	var server := TCPServer.new()
	var listening := server.listen(0, "127.0.0.1") == OK
	var port := server.get_local_port()
	var asked: Array[String] = []
	var host := Node.new()
	var launcher := Launcher.new()
	launcher.server = "http://127.0.0.1:%d" % port
	launcher.outbox = "user://outbox-fix-cold-test.json"
	host.add_child(launcher)
	tree.root.add_child(host)
	var peers: Array[StreamPeerTCP] = []
	var heard: Array[String] = []
	var frames := 600
	while launcher.answer == null and frames > 0 and listening:
		frames -= 1
		while server.is_connection_available():
			peers.append(server.take_connection())
			heard.append("")
		for i in peers.size():
			var peer := peers[i]
			peer.poll()
			if peer.get_status() != StreamPeerTCP.STATUS_CONNECTED:
				continue
			var n := peer.get_available_bytes()
			if n > 0:
				heard[i] += peer.get_utf8_string(n)
			if heard[i].contains("\r\n\r\n") and not asked.has(str(i)):
				asked.append(str(i))
				var reply := "{\"words\":[]}"
				peer.put_data((("HTTP/1.1 200 OK\r\nContent-Type: application/json\r\nContent-Length: %d\r\n"
					+ "Connection: close\r\n\r\n%s") % [reply.length(), reply]).to_utf8_buffer())
		await tree.process_frame
	var t := launcher.built.transport if launcher.built != null else null
	var in_tree := t != null and t.is_inside_tree()
	var r := launcher.answer
	check.call("RB-27: on a cold start the services built under a parent still readying its children put the "
			+ "HTTP transport in the tree, and the first call reaches the server and is answered",
		listening and in_tree and r != null and r.ok and asked.size() == 1
			and heard.size() > 0 and heard[0].begins_with("GET /v1/words "),
		"listening %s, transport in tree %s, answer %s, requests heard %s" % [listening, in_tree, r, asked.size()])
	for peer in peers:
		peer.disconnect_from_host()
	server.stop()
	if launcher.built != null:
		launcher.built.close()
	host.queue_free()
	await tree.process_frame


## RB-03. A public GET made while signed in, beside an authed call: neither
## the authed call nor the session sees the token go missing, and a renewal
## made meanwhile is not written over.
func _public_call_leaves_the_token_alone() -> void:
	var t := SessionServer.new()
	t.slow = {"/v1/words": 5}
	var s := _fake("public", t)
	await s.auth_flow.sign_in()
	t.calls.clear()
	var words: Array = [null]
	var load_words := func() -> void: words[0] = await s.api.public_json("/v1/words")
	load_words.call()
	var balance := await s.account.balance()
	await _until(func() -> bool: return words[0] != null)
	var routes := _routes(t)
	var beside := _bearer(_call(t, "GET /v1/balance"))
	var first_token := s.api.token
	var quiet := (words[0] != null and (words[0] as Result).ok and balance.ok
		and not routes.has("POST /v1/session/refresh") and not routes.has("POST /v1/session")
		and beside == ACCESS and _bearer(_call(t, "GET /v1/words")) == "" and first_token == ACCESS)
	# A renewal while the public call is out: the renewed token stays.
	words[0] = null
	load_words.call()
	var renewed := await s.auth.ensure(true)
	await _until(func() -> bool: return words[0] != null)
	var kept := renewed.ok and words[0] != null and s.api.token == RENEWED and s.auth.fresh()
	t.calls.clear()
	await s.account.balance()
	var after := _bearer(_call(t, "GET /v1/balance"))
	check.call("RB-03: a public GET while signed in sends no token and leaves the session's alone: a call beside "
			+ "it is sent with the token held and spends no refresh, and a renewal made meanwhile is kept",
		quiet and kept and after == RENEWED,
		"routes %s, balance sent with %s, token after %s; renewal kept %s, next call sent with %s" % [routes,
			_said(beside), _said(first_token), kept, _said(after)])
	s.close()


## RB-03, the same pattern in AuthSession._end_with: a sign-out owed to the
## server, told while another call is out.
func _ending_by_refresh_leaves_the_token_alone() -> void:
	var t := SessionServer.new()
	t.slow = {"/v1/session/end": 5}
	var s := _fake("owed", t)
	await s.auth_flow.sign_in()
	t.calls.clear()
	s.auth.vault.write(AuthSession.REVOKE_KEY, JSON.stringify({"refreshToken": "r1.k0.6.0.OLD", "everywhere": false}))
	var told: Array = [false]
	var tell := func() -> void:
		await s.auth.send_revocation()
		told[0] = true
	tell.call()
	var balance := await s.account.balance()
	await _until(func() -> bool: return told[0])
	var routes := _routes(t)
	var end := _call(t, "POST /v1/session/end")
	check.call("RB-03: a sign-out owed to the server is told with the refresh token alone, and a call beside it "
			+ "is sent with the session's token and spends no refresh",
		told[0] and balance.ok and not routes.has("POST /v1/session/refresh") and _bearer(end) == ""
			and not end.is_empty() and _bearer(_call(t, "GET /v1/balance")) == ACCESS and s.api.token == ACCESS
			and not s.auth.revocation_owed(),
		"routes %s, end sent with %s, balance sent with %s, token after %s" % [routes, _said(_bearer(end)),
			_said(_bearer(_call(t, "GET /v1/balance"))), _said(s.api.token)])
	s.close()


## RB-04. The account panel open past the hour, or a launch with only the
## refresh token: "sign out other devices" and "sign out" on one device renew
## the session first and are answered, not refused.
func _ending_other_devices_renews_a_stale_token() -> void:
	var cases: Array[String] = []
	for which: String in ["stale others", "missing others", "stale device", "missing device"]:
		var t := SessionServer.new()
		var s := _fake("end-" + which.replace(" ", "-"), t)
		await s.auth_flow.sign_in()
		# The server has let the first token lapse; only a renewed one is live.
		t.live = [RENEWED] as Array[String]
		if which.begins_with("stale"):
			s.auth.expires_at = Time.get_ticks_msec() + AuthSession.EARLY_MS - 1
		else:
			s.api.token = ""
			s.auth.expires_at = 0
		t.calls.clear()
		var r := (await s.auth_flow.sign_out_others() if which.ends_with("others")
			else await s.auth_flow.end_device(3))
		var routes := _routes(t)
		var end := _call(t, "POST /v1/session/end")
		var notice := str(s.store.get_slice(AuthState.AUTH)["notice"])
		if not (r.ok and routes.slice(0, 2) == ["POST /v1/session/refresh", "POST /v1/session/end"]
				and _bearer(end) == RENEWED and notice == "" and s.auth.fresh()):
			cases.append("%s: %s, routes %s, end sent with %s, notice '%s'" % [which, r, routes,
				_said(_bearer(end)), notice])
		s.close()
	check.call("RB-04: signing out other devices, or one of them, with a token past its hour or none at all "
			+ "renews the session first and is answered, never refused for the lapsed token",
		cases.is_empty(), "; ".join(cases))
