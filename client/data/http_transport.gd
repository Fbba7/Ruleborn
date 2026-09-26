class_name HttpTransport
extends Transport
## Godot's HTTPRequest, one a call, with a timeout: a train in a tunnel
## answers nothing rather than an error, and a call that never returns would
## hold a screen forever (§24.12).

const TIMEOUT_SECONDS := 15.0


func send(method: HTTPClient.Method, url: String, headers: PackedStringArray,
		body: PackedByteArray) -> Dictionary:
	var request := HTTPRequest.new()
	request.timeout = TIMEOUT_SECONDS
	add_child(request)
	if request.request_raw(url, headers, method, body) != OK:
		request.queue_free()
		return {"error": "request_failed"}
	var done: Array = await request.request_completed
	request.queue_free()
	if done[0] == HTTPRequest.RESULT_TIMEOUT:
		return {"error": "timeout"}
	if done[0] != HTTPRequest.RESULT_SUCCESS:
		return {"error": "unreachable"}
	return {"status": done[1], "body": done[3]}
