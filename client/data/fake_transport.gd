class_name FakeTransport
extends Transport
## A server for tests: each route ("POST /v1/leases") answers what the test
## put there, and every call is kept, so a test asserts what was asked as
## well as what was shown. A route nobody set answers 404 no_such_route, as
## server/src/http.mjs does; `offline` answers nothing at all.

var routes: Dictionary = {}
var calls: Array[Dictionary] = []
var offline := false
## Answers given once each, in turn, before the route's own: [answer, status]
## pairs, for a server that changes its mind (a session that expires).
var _next: Dictionary = {}


## `answer` is a Dictionary (sent as JSON) or PackedByteArray, with `status`.
func on(route: String, answer: Variant, status := 200) -> void:
	routes[route] = {"status": status, "answer": answer}


func then(route: String, answers: Array) -> void:
	_next[route] = answers.duplicate()


func send(method: HTTPClient.Method, url: String, headers: PackedStringArray,
		body: PackedByteArray) -> Dictionary:
	var path := "/" + url.split("/", false, 2)[2] if url.contains("://") else url
	path = path.get_slice("?", 0)
	var verb: String = ["GET", "HEAD", "POST", "PUT", "DELETE"][method] if method <= 4 else "?"
	calls.append({"route": "%s %s" % [verb, path], "headers": headers, "body": body})
	await (Engine.get_main_loop() as SceneTree).process_frame
	if offline:
		return {"error": "unreachable"}
	var key := "%s %s" % [verb, path]
	if (_next.get(key, []) as Array).size() > 0:
		var once: Array = (_next[key] as Array).pop_front()
		var body_once: Variant = once[0]
		return {"status": once[1], "body": body_once if body_once is PackedByteArray
			else JSON.stringify(body_once).to_utf8_buffer()}
	var r: Variant = routes.get(key)
	if r == null:
		return {"status": 404, "body": JSON.stringify({"error": "no_such_route"}).to_utf8_buffer()}
	var answer: Variant = r["answer"]
	var bytes: PackedByteArray = answer if answer is PackedByteArray else JSON.stringify(answer).to_utf8_buffer()
	return {"status": r["status"], "body": bytes}
