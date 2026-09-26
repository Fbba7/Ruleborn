class_name Result
extends RefCounted
## What every call that can fail returns: a value, or a failure named by one
## code. A code is the server's own refusal reason ("monthly_cap",
## "lease_expired"), or the client's ("unreachable", "malformed_response"), so
## a failure is found by searching for the one word the player saw
## (`Errors.message`) in both halves of the codebase.

var ok: bool
var value: Variant
var code: String
## What came with a failure: the HTTP status, the server's own detail.
var detail: Dictionary


func _init(is_ok: bool, v: Variant = null, c := "", d := {}) -> void:
	ok = is_ok
	value = v
	code = c
	detail = d


static func success(v: Variant = null) -> Result:
	return Result.new(true, v)


static func failure(c: String, d := {}) -> Result:
	return Result.new(false, null, c, d)


func _to_string() -> String:
	return "ok(%s)" % [value] if ok else "failed(%s %s)" % [code, detail]
