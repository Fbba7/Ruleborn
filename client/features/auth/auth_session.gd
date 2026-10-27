class_name AuthSession
extends RefCounted
## The device's half of a session (docs/security/auth.md). §24.8 exchanges
## the platform's proof for "a short-lived signed token"; the server answers
## an access token for an hour and a refresh token, and this keeps them:
##
## - the access token in memory only (Api.token), renewed a minute before
##   the hour the server gave, timed on the engine's monotonic clock, so a
##   phone whose clock is wrong or changed neither keeps a dead token nor
##   drops a good one;
## - the refresh token in the platform's secret storage (SecureStore), never
##   a plain file; spent and replaced on every refresh;
## - when the refresh token is refused, the platform asked again, silently,
##   with the server's nonce first where the platform's proof carries one;
## - one renewal at a time: calls that find the session stale meanwhile wait
##   for it, so two refreshes never race and look like a stolen token;
## - signed out: nothing renews, and no call signs in again by itself, until
##   the player chooses to sign in. A sign-out the server could not hear
##   (offline) is remembered, its refresh token kept only to end it, and
##   sent before anything else the next time the server answers.
##
## No token is ever logged: Api logs a failure's route alone.

signal renewed(result: Result)

const FILE := "user://auth.json"
const REFRESH_KEY := "ruleborn.session.refresh"
const REVOKE_KEY := "ruleborn.session.revoke"
## How long before its hour is out an access token is renewed.
const EARLY_MS := 60 * 1000
## The server's hour, if an answer leaves it out.
const DEFAULT_SECONDS := 3600

var api: Api
var vault: SecureStore
var platform: PlatformIdentity
var path := FILE
## When the access token stops being fresh, on Time.get_ticks_msec(); 0 for a
## token whose life nobody said, which is used until it is refused.
var expires_at := 0
var account := ""
## The account this phone last signed in to, kept across launches: not a
## secret (an opaque id), so a sign-out made offline still parks the queue
## under the right account (AuthController).
var last_account := ""
var _signed_out := false
var _busy := false


func _init(a: Api, v: SecureStore, p: PlatformIdentity, file := FILE) -> void:
	api = a
	vault = v
	platform = p
	path = file
	_read()


## Whether the player signed out on this device and has not signed in since.
func signed_out() -> bool:
	return _signed_out


## Whether the access token held is good for another minute at least.
func fresh() -> bool:
	return api.token != "" and (expires_at == 0 or Time.get_ticks_msec() < expires_at - EARLY_MS)


## Whether a token is held that has reached its renewal (Api renews first).
func stale() -> bool:
	return api.token != "" and not fresh()


## Whether a refresh token is kept: the next launch needs no platform proof.
func remembered() -> bool:
	return vault.read(REFRESH_KEY) != ""


## The session: the token held while fresh; else the refresh token spent for
## a new pair; else the platform's proof exchanged for one. `force` renews
## whatever is held: the server refused it. Signed out, a failure.
func ensure(force := false) -> Result:
	if _signed_out:
		return Result.failure("signed_out")
	if not force and fresh():
		return Result.success({"account": account})
	if _busy:
		var waited: Array = [null]
		var done := func(r: Result) -> void: waited[0] = r
		renewed.connect(done, CONNECT_ONE_SHOT)
		while waited[0] == null:
			await (Engine.get_main_loop() as SceneTree).process_frame
		return waited[0]
	_busy = true
	var out := await _renew(force)
	_busy = false
	renewed.emit(out)
	return out


## The player chose to sign in: on the first launch, after signing out, or
## after a sign-in that failed.
func sign_in() -> Result:
	_signed_out = false
	_write()
	return await ensure(true)


## This device signed out — or every device, with `everywhere`. The server is
## told first, and whatever it answers this device forgets its tokens: a
## sign-out never fails on the phone. Answers the server's Result; one it
## never heard (offline) is sent when it next answers.
func sign_out(everywhere := false) -> Result:
	var refresh := vault.read(REFRESH_KEY)
	var told := Result.success({"ended": 0})
	if fresh():
		told = await api.post_json("/v1/session/end", {"everywhere": everywhere})
	elif refresh != "":
		told = await _end_with(refresh, everywhere)
	if not told.ok and Outbox.transient(told) and told.code != "session_refused" and refresh != "":
		vault.write(REVOKE_KEY, JSON.stringify({"refreshToken": refresh, "everywhere": everywhere}))
	forget()
	_signed_out = true
	_write()
	return told


## Every token this device holds, gone: the access token, the refresh token,
## and the time it was good until.
func forget() -> void:
	api.token = ""
	expires_at = 0
	account = ""
	vault.erase(REFRESH_KEY)


## Whether a sign-out is still owed to the server.
func revocation_owed() -> bool:
	return vault.read(REVOKE_KEY) != ""


func _renew(force: bool) -> Result:
	await send_revocation()
	if force:
		api.token = ""
		expires_at = 0
	var held := vault.read(REFRESH_KEY)
	if held != "":
		var r := await api.post_json("/v1/session/refresh", {"refreshToken": held})
		if r.ok:
			return _adopt(r.value)
		# Spent, reused, lapsed or ended: the platform proves it again. Anything
		# the server never decided keeps the token for the next try.
		if r.code != "session_refused" and r.code != "account_deleted":
			return r
		vault.erase(REFRESH_KEY)
	return await _with_platform()


func _with_platform() -> Result:
	var nonce := ""
	if platform.needs_nonce():
		var n := await api.post_json("/v1/session/nonce", {})
		if not n.ok:
			return n
		nonce = str((n.value as Dictionary).get("nonce", ""))
	var proof := await platform.credential(nonce)
	if not proof.ok:
		return proof
	var r := await api.post_json("/v1/session", {"credential": proof.value})
	return _adopt(r.value) if r.ok else r


func _adopt(answer: Variant) -> Result:
	var v: Dictionary = answer if answer is Dictionary else {}
	if str(v.get("token", "")) == "":
		return Result.failure("malformed_response")
	api.token = str(v["token"])
	expires_at = Time.get_ticks_msec() + int(v.get("expiresIn", DEFAULT_SECONDS)) * 1000
	account = str(v.get("account", ""))
	if account != last_account:
		last_account = account
		_write()
	var refresh := str(v.get("refreshToken", ""))
	if refresh != "":
		vault.write(REFRESH_KEY, refresh)
	else:
		vault.erase(REFRESH_KEY)
	return Result.success({"account": account})


## A sign-out the server did not hear, told now; kept again only if it still
## could not be.
func send_revocation() -> void:
	var held := vault.read(REVOKE_KEY)
	if held == "":
		return
	var owed: Variant = JSON.parse_string(held)
	if not owed is Dictionary:
		vault.erase(REVOKE_KEY)
		return
	var r := await _end_with(str(owed.get("refreshToken", "")), bool(owed.get("everywhere", false)))
	if r.ok or not Outbox.transient(r) or r.code == "session_refused":
		vault.erase(REVOKE_KEY)


## /v1/session/end proven by a refresh token alone, with no access token
## sent beside it (which would end that session instead).
func _end_with(refresh: String, everywhere: bool) -> Result:
	var held := api.token
	api.token = ""
	var r := await api.post_json("/v1/session/end", {"everywhere": everywhere, "refreshToken": refresh})
	api.token = held
	return r


func _read() -> void:
	if not FileAccess.file_exists(path):
		return
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	if parsed is Dictionary:
		_signed_out = bool((parsed as Dictionary).get("signed_out", false))
		last_account = str((parsed as Dictionary).get("account", ""))


## Only whether the player signed out and the account's opaque id: nothing
## secret is in this file.
func _write() -> void:
	var f := FileAccess.open(path, FileAccess.WRITE)
	if f == null:
		push_error("could not keep the sign-in state in %s" % path)
		return
	f.store_string(JSON.stringify({"signed_out": _signed_out, "account": last_account}))
