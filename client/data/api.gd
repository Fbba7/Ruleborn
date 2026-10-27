class_name Api
extends RefCounted
## server/'s edge functions (server/src/http.mjs), called through a
## `Transport`. Every call returns a `Result`: the parsed answer, or a failure
## named by the server's own refusal reason, so the code the player's error
## message is chosen by is the code the server wrote. Repositories are the
## only callers; no screen calls the network.

var transport: Transport
var base := ""
var token := ""
var action_log: ActionLog
## How a session is had again: Services sets it to sign in with the
## platform's credential, answering the sign-in's `Result`. A call made with
## no session, or refused for an expired one (the server's sessions last an
## hour), signs in and is made again, once, so no screen has to remember to
## sign in. A sign-in the server holds back (too_many_requests, G44) is the
## call's answer, with its wait, not a session refused.
var reauth: Callable
## Whether the token held has reached its renewal (AuthSession.stale): a
## call then renews first rather than be refused. Unset, a token is used
## until refused.
var stale: Callable


func _init(t: Transport, url: String, l: ActionLog) -> void:
	transport = t
	base = url.trim_suffix("/")
	action_log = l


func online() -> bool:
	return base != ""


## HTTPS, or HTTP to this machine's own loopback for the tests: the stores are
## told everything is encrypted in transit (server/declarations.md), and a
## session token is not sent in the clear.
static func secure(url: String) -> bool:
	if url == "" or url.begins_with("https://"):
		return true
	if not url.begins_with("http://"):
		return false
	# The whole authority is the loopback and at most a port, and no "@" or
	# backslash anywhere, which a URL reader may take as ending a userinfo:
	# "localhost:1@host" names another host (SR-06).
	if url.contains("@") or url.contains("\\"):
		return false
	return RegEx.create_from_string("^http://(127\\.0\\.0\\.1|localhost)(:\\d{1,5})?([/?#]|$)").search(url) != null


## A call answered with bytes: a bundle, a replay.
func raw(method: HTTPClient.Method, path: String, body := PackedByteArray()) -> Result:
	if not online():
		return Result.failure("offline")
	# The session's own routes never sign in to be made: they are how.
	var signing := method == HTTPClient.METHOD_POST and (path == "/v1/session" or path.begins_with("/v1/session/"))
	var renew := token == "" or (stale.is_valid() and bool(stale.call()))
	if renew and not signing and reauth.is_valid():
		var signed: Result = await reauth.call()
		if signed.code == "too_many_requests":
			return signed
	var first := await _raw(method, path, body)
	if first.ok or first.code != "session_refused" or signing or not reauth.is_valid():
		return first
	var again: Result = await reauth.call()
	if not again.ok:
		return again if again.code == "too_many_requests" else first
	return await _raw(method, path, body)


func _raw(method: HTTPClient.Method, path: String, body: PackedByteArray) -> Result:
	var headers: PackedStringArray = []
	if token != "":
		headers.append("Authorization: Bearer " + token)
	if method != HTTPClient.METHOD_GET:
		headers.append("Content-Type: application/octet-stream")
	var r: Dictionary = await transport.send(method, base + path, headers, body)
	if r.has("error"):
		return _failed(path, str(r["error"]), {})
	var status: int = r["status"]
	if status >= 400:
		var said: Variant = JSON.parse_string((r["body"] as PackedByteArray).get_string_from_utf8())
		var reason: String = str(said.get("error", "status_%d" % status)) if said is Dictionary else "status_%d" % status
		# The status rides with the server's own detail: a 5xx the server
		# answered with a reason is still one it never decided (Outbox).
		var detail: Dictionary = (said as Dictionary).duplicate() if said is Dictionary else {}
		detail["status"] = status
		return _failed(path, reason, detail)
	return Result.success(r["body"])


## A call answered with JSON, sent `body` as JSON when it is not null.
func json(method: HTTPClient.Method, path: String, body: Variant = null) -> Result:
	var bytes := PackedByteArray() if body == null else JSON.stringify(body).to_utf8_buffer()
	var r := await raw(method, path, bytes)
	if not r.ok:
		return r
	var parsed: Variant = JSON.parse_string((r.value as PackedByteArray).get_string_from_utf8())
	if not (parsed is Dictionary or parsed is Array):
		return _failed(path, "malformed_response", {})
	return Result.success(parsed)


func get_json(path: String) -> Result:
	return await json(HTTPClient.METHOD_GET, path)


## A GET that needs no session — the word lists, §20.2's protections — which
## the first launch makes before any account exists (§25.2): no sign-in, and
## no token sent.
func public_json(path: String) -> Result:
	if not online():
		return Result.failure("offline")
	var held := token
	token = ""
	var r := await _raw(HTTPClient.METHOD_GET, path, PackedByteArray())
	token = held
	if not r.ok:
		return r
	var parsed: Variant = JSON.parse_string((r.value as PackedByteArray).get_string_from_utf8())
	if not (parsed is Dictionary or parsed is Array):
		return _failed(path, "malformed_response", {})
	return Result.success(parsed)


func post_json(path: String, body: Variant = {}) -> Result:
	return await json(HTTPClient.METHOD_POST, path, body)


func _failed(path: String, code: String, detail: Dictionary) -> Result:
	# The route alone, as the server logs it: a path can carry a token.
	action_log.add("failure", code, {"route": "/".join(path.split("/", false).slice(0, 2))})
	return Result.failure(code, detail)
