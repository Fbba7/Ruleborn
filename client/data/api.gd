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
	var host := url.trim_prefix("http://").get_slice("/", 0).get_slice(":", 0)
	return host == "127.0.0.1" or host == "localhost"


## A call answered with bytes: a bundle, a replay.
func raw(method: HTTPClient.Method, path: String, body := PackedByteArray()) -> Result:
	if not online():
		return Result.failure("offline")
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
		return _failed(path, reason, said if said is Dictionary else {"status": status})
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


func post_json(path: String, body: Variant = {}) -> Result:
	return await json(HTTPClient.METHOD_POST, path, body)


func _failed(path: String, code: String, detail: Dictionary) -> Result:
	# The route alone, as the server logs it: a path can carry a token.
	action_log.add("failure", code, {"route": "/".join(path.split("/", false).slice(0, 2))})
	return Result.failure(code, detail)
