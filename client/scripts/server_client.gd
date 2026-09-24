class_name ServerClient
extends Node
## The client's side of server/'s edge functions (server/src/http.mjs), over
## HTTP: a session, the target lists, bundles by hash, a lease, and the
## submission that the server re-simulates and settles (§24.12). Each call
## returns a Dictionary; a failed call carries "error".

var base := ""
var token := ""


func _init(url := "") -> void:
	base = url.trim_suffix("/")


func _call(method: HTTPClient.Method, path: String, body := PackedByteArray()) -> Dictionary:
	var request := HTTPRequest.new()
	add_child(request)
	var headers := PackedStringArray()
	if token != "":
		headers.append("Authorization: Bearer " + token)
	if method != HTTPClient.METHOD_GET:
		headers.append("Content-Type: application/octet-stream")
	if request.request_raw(base + path, headers, method, body) != OK:
		request.queue_free()
		return {"error": "request_failed"}
	var done: Array = await request.request_completed
	request.queue_free()
	if done[0] != HTTPRequest.RESULT_SUCCESS:
		return {"error": "unreachable"}
	return {"status": done[1], "body": done[3]}


func _json(method: HTTPClient.Method, path: String, body := PackedByteArray()) -> Dictionary:
	var r := await _call(method, path, body)
	if r.has("error"):
		return r
	var parsed = JSON.parse_string(r["body"].get_string_from_utf8())
	if not parsed is Dictionary:
		return {"error": "malformed_response", "status": r["status"]}
	if r["status"] >= 400:
		parsed["error"] = parsed.get("error", "status %d" % r["status"])
	return parsed


## §24.8: "Platform identity is exchanged for a short-lived signed token."
func sign_in(credential: String) -> Dictionary:
	var r := await _json(HTTPClient.METHOD_POST, "/v1/session",
		JSON.stringify({"credential": credential}).to_utf8_buffer())
	token = r.get("token", "")
	return r


## §24.8: the current target list for each band, by hash.
func targets() -> Dictionary:
	return await _json(HTTPClient.METHOD_GET, "/v1/targets")


## A bundle or a target list, by the hash it is stored under.
func fetch(hash: String) -> PackedByteArray:
	var r := await _call(HTTPClient.METHOD_GET, "/v1/bundles/" + hash)
	return r.get("body", PackedByteArray()) if r.get("status", 0) == 200 else PackedByteArray()


## §24.12: "a target snapshot, a seed, a single-use token and an expiry".
## The owner names whose island it is: two players can publish the same one.
func lease(bundle: String, owner := "") -> Dictionary:
	var body := {"bundle": bundle}
	if owner != "":
		body["owner"] = owner
	return await _json(HTTPClient.METHOD_POST, "/v1/leases", JSON.stringify(body).to_utf8_buffer())


## §24.12's Validate and Grant: what the server decided, and what it paid.
func submit(lease_token: String, replay: PackedByteArray) -> Dictionary:
	return await _json(HTTPClient.METHOD_POST, "/v1/heists/" + lease_token, replay)


func balance() -> Dictionary:
	return await _json(HTTPClient.METHOD_GET, "/v1/balance")


## The first island in the target lists that is not the player's own: the list
## file is fetched by hash, as §24.8 intends. §12.22's filters and ordering are
## not built, so the choice is the list's first entry.
func first_target(account: String) -> Dictionary:
	var index := await targets()
	if index.has("error"):
		return index
	for band in index:
		var list = JSON.parse_string((await fetch(index[band])).get_string_from_utf8())
		if list is Dictionary:
			for candidate in list.get("candidates", []):
				if candidate["owner"] != account:
					return candidate
	return {"error": "no_target"}
