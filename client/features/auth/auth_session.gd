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
## - a renewal the server never decided (unreachable, failing) is not
##   tried again at once: the next automatic one waits 2 s, then 4, 8 …
##   up to 5 minutes, with jitter so phones that lost the server together
##   do not return together; one the server held back waits the seconds
##   it named, whoever asks. The player's own tap skips the first wait only;
## - a sign-in names the device's kind and model, for the account's devices
##   list (never anything that names the player);
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
## The first and the longest wait after a renewal that could not be made.
const BACKOFF_FIRST_MS := 2000
const BACKOFF_MOST_MS := 5 * 60 * 1000
## The kinds the server's devices list words (auth.mjs DEVICES).
const DEVICE_KINDS := ["iphone", "ipad", "android_phone", "android_tablet", "pc", "other"]

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
## A number in [0, 1) for the jitter; a test makes it fixed.
var jitter: Callable = func() -> float: return randf()
var _signed_out := false
var _busy := false
## The wait after a failed renewal, doubling; when it is over, on the
## monotonic clock; and whether the server set it (Retry-After).
var _backoff_ms := 0
var _held_until := 0
var _held_by_server := false
var _held_code := ""


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
func ensure(force := false, player := false) -> Result:
	if _signed_out:
		return Result.failure("signed_out")
	if not force and fresh():
		return Result.success({"account": account})
	if held_ms() > 0 and (_held_by_server or not player):
		return Result.failure(_held_code, {"retryAfter": ceili(held_ms() / 1000.0)})
	if _busy:
		var waited: Array = [null]
		var done := func(r: Result) -> void: waited[0] = r
		renewed.connect(done, CONNECT_ONE_SHOT)
		while waited[0] == null:
			await (Engine.get_main_loop() as SceneTree).process_frame
		return waited[0]
	_busy = true
	var out := await _renew(force)
	_after(out)
	_busy = false
	renewed.emit(out)
	return out


## How long, in milliseconds, before a renewal is tried again: 0 when it
## may be now.
func held_ms() -> int:
	return maxi(0, _held_until - Time.get_ticks_msec())


## The wait a renewal's answer sets: none after a success or a decision
## (a refusal the platform answers); the server's own when it held this
## back; else the next of 2 s, 4 s … 5 minutes, at half to all of it.
func _after(out: Result) -> void:
	if out.ok or not Outbox.transient(out) or out.code == "session_refused":
		_backoff_ms = 0
		_held_until = 0
		_held_by_server = false
		return
	_held_code = out.code
	if out.code == "too_many_requests":
		_held_by_server = true
		_held_until = Time.get_ticks_msec() + maxi(1, int(out.detail.get("retryAfter", 1))) * 1000
		return
	_held_by_server = false
	_backoff_ms = BACKOFF_FIRST_MS if _backoff_ms == 0 else mini(_backoff_ms * 2, BACKOFF_MOST_MS)
	_held_until = Time.get_ticks_msec() + int(_backoff_ms * (0.5 + 0.5 * float(jitter.call())))


## The player chose to sign in: on the first launch, after signing out, or
## after a sign-in that failed.
func sign_in() -> Result:
	_signed_out = false
	_write()
	return await ensure(true, true)


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
	var proof := await prove(platform.primary())
	if not proof.ok:
		return proof
	var r := await api.post_json("/v1/session", {"credential": proof.value, "device": device()})
	return _adopt(r.value) if r.ok else r


## A fresh proof of `which` platform, with the server's nonce first where
## it carries one: each is taken once.
func prove(which: String) -> Result:
	var nonce := ""
	if platform.needs_nonce_for(which):
		var n := await api.post_json("/v1/session/nonce", {})
		if not n.ok:
			return n
		nonce = str((n.value as Dictionary).get("nonce", ""))
	return await platform.credential_for(which, nonce)


## `adding`'s identity linked to this account, which a fresh proof of the
## platform this device signs in with vouches for (auth.mjs link): a stolen
## access token alone links nothing. Answers the account's identities.
func link(adding: String) -> Result:
	return await _step_up("/v1/session/link", adding)


## `which` platform's link removed, vouched for by the platform that stays.
func unlink(which: String) -> Result:
	return await _step_up("/v1/session/unlink", which)


func _step_up(route: String, which: String) -> Result:
	var live := await ensure()
	if not live.ok:
		return live
	var current := await prove(platform.primary())
	if not current.ok:
		return current
	var body := {"current": current.value}
	if route.ends_with("/link"):
		var adding := await prove(which)
		if not adding.ok:
			return adding
		body["credential"] = adding.value
	else:
		body["platform"] = which
	return await api.post_json(route, body)


## What this device says it is, for its account's devices list: a kind
## from DEVICE_KINDS and its model as the system names it. Nothing that
## names the player, and no identifier.
static func device() -> Dictionary:
	var model := OS.get_model_name()
	var kind := "other"
	match OS.get_name():
		"iOS":
			kind = "ipad" if model.begins_with("iPad") else "iphone"
		"Android":
			# Three and a half inches across the short side: past it, a tablet.
			var dpi := maxf(float(DisplayServer.screen_get_dpi()), 1.0)
			var short := float(mini(DisplayServer.screen_get_size().x, DisplayServer.screen_get_size().y))
			kind = "android_tablet" if short / dpi >= 3.5 else "android_phone"
		"Windows", "macOS", "Linux", "FreeBSD":
			kind = "pc"
	if model == "GenericDevice":
		model = ""
	return {"kind": kind, "model": model.left(32)}


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
