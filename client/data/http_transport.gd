class_name HttpTransport
extends Transport
## Godot's HTTPRequest, one a call, with a timeout: a train in a tunnel
## answers nothing rather than an error, and a call that never returns would
## hold a screen forever (§24.12).

const TIMEOUT_SECONDS := 15.0
## The project setting naming the certificates the server's chain is pinned
## to: a PEM file of the authority (or intermediate) it ends at.
const PINS_SETTING := "ruleborn/tls_pins"

## The pinned trust, read once; null for the platform's own authorities.
static var _pins: TLSOptions
static var _pins_read := false


## The server is trusted only through the certificates the build pins, when
## it pins any (docs/security/auth.md): a proxy's certificate, or one an
## authority mis-issued, is refused even where the phone trusts its issuer.
## Unpinned, the platform's own authorities, with the host name checked.
static func pins() -> TLSOptions:
	if not _pins_read:
		_pins_read = true
		_pins = pinned(str(ProjectSettings.get_setting(PINS_SETTING, "")))
	return _pins


## TLS options trusting only the certificates in the PEM file at `path`; null
## if there is none, or it is not one.
static func pinned(path: String) -> TLSOptions:
	if path == "" or not FileAccess.file_exists(path):
		return null
	var chain := X509Certificate.new()
	if chain.load(path) != OK:
		push_error("the pinned certificates in %s could not be read" % path)
		return null
	return TLSOptions.client(chain)


func send(method: HTTPClient.Method, url: String, headers: PackedStringArray,
		body: PackedByteArray) -> Dictionary:
	var request := HTTPRequest.new()
	request.timeout = TIMEOUT_SECONDS
	# The server never redirects, and Godot would send the token on to
	# wherever a redirect points, in the clear too (T12's SR-27).
	request.max_redirects = 0
	if pins() != null:
		request.set_tls_options(pins())
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
