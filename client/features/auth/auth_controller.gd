class_name AuthController
extends RefCounted
## Signing in and out, as the account panel asks (scripts/auth_panel.gd,
## docs/security/auth.md).
##
## A sign-out, on a phone someone else may pick up next: everything waiting
## is sent first if the server answers; the server ends the session (or every
## session); the tokens go; what still could not be sent — §24.12's queue,
## a heist played offline — is parked on the phone under this account,
## never sent as anyone else and never dropped, and the player is told how
## many; the lease stock, the session events not yet sent and every state the
## store held go with the account; and the app starts again from nothing
## (`reset`). The same account signing in again gets its parked heists back.

## How the app starts again from nothing once signed out: App sets it to
## build its services anew, so no cached private state outlives the account;
## it is given the panel's status to show in the new ones.
var reset: Callable
var services: Services


func _init(s: Services) -> void:
	services = s
	services.auth.account_changed.connect(_park_for)


## The session now speaks for another account: what `previous` queued waits
## under it, never sent as the new one (SEC-29).
func _park_for(previous: String, _now: String) -> void:
	services.outbox.park(parked_path(previous))


func _account() -> String:
	var held := str(services.store.get_slice(AppState.SESSION).get("account", ""))
	return held if held != "" else services.auth.last_account


## Where an account's parked queue is kept, beside the outbox itself.
func parked_path(account: String) -> String:
	return "%s-parked-%s.json" % [services.outbox.path.get_basename(), account.validate_filename()]


## The panel's status as the session stands, without asking anything.
func refresh_status() -> void:
	var st := "first"
	if services.auth.signed_out():
		st = "signed_out"
	elif services.auth.fresh() and _account() != "":
		st = "signed_in"
	elif services.auth.remembered() or _account() != "":
		st = "offline" if not services.api.online() else "signed_in"
	services.store.dispatch(&"auth_status", {"status": st})


## The player signs in: the platform asked, the session made, what this
## account parked on signing out put back in the queue and sent.
func sign_in() -> Result:
	services.store.dispatch(&"auth_status", {"status": "signing_in"})
	var r := await services.auth.sign_in()
	if not r.ok:
		var unreachable := r.code in ["offline", "unreachable", "timeout", "request_failed"]
		services.store.dispatch(&"auth_status", {"status": "offline" if unreachable and services.auth.remembered()
			else "failed", "reason": r.code})
		return r
	var account := str(r.value.get("account", ""))
	services.store.dispatch(&"signed_in", {"account": account})
	services.store.dispatch(&"auth_status", {"status": "signed_in"})
	if services.outbox.unpark(parked_path(account)) > 0:
		await services.outbox.flush(services.api)
	await devices()
	return r


## The account's devices and ways to sign in (the panel's lists): each
## device's kind, model, country and last use, and which platforms sign in
## to it, with the one this device could add.
func devices() -> Result:
	var r := await services.api.get_json("/v1/session/devices")
	if r.ok:
		var v: Dictionary = r.value
		var list: Array = v.get("devices", [])
		var identities: Array = v.get("identities", [])
		services.store.dispatch(&"auth_devices", {"devices": list.size(), "list": list,
			"identities": identities, "platforms": services.auth.platform.platforms()})
	return r


## One other device of the list signed out, by its id in the server's list
## (this one signs out with sign_out, which also parks what waits).
func end_device(id: int) -> Result:
	return await _done(await _end({"device": id}), "")


## Every other device of this account signed out; this one stays.
func sign_out_others() -> Result:
	return await _done(await _end({"others": true}), "")


## /v1/session/end sent with a live access token. Api neither renews nor
## retries a /v1/session/* call (so a sign-out never signs in again), and
## the server refuses a stale token or none: the session is made live
## first, as a step-up does (RB-04).
func _end(body: Dictionary) -> Result:
	var live := await services.auth.ensure()
	if not live.ok:
		return live
	return await services.api.post_json("/v1/session/end", body)


## Another platform's identity linked to this account (AuthSession.link).
func link(platform: String) -> Result:
	return await _done(await services.auth.link(platform), "AUTH_LINKED", platform)


## A linked platform removed (AuthSession.unlink).
func unlink(platform: String) -> Result:
	return await _done(await services.auth.unlink(platform), "AUTH_UNLINKED", platform)


## The panel told how an account change went — `said` with the platform's
## name, or the failure in words — and its lists asked again.
func _done(r: Result, said: String, platform := "") -> Result:
	var words := ""
	if not r.ok:
		words = Errors.message("AUTH_ACTION_FAILED", r.code)
	elif said != "":
		words = Strings.t(said, AuthPresenter.platform_name(platform))
	services.store.dispatch(&"auth_notice", {"notice": words, "failed": not r.ok})
	await devices()
	return r


## What signing out now would leave waiting, after sending what can be sent:
## the number the confirm names (AuthPresenter.confirm).
func before_sign_out() -> int:
	if services.api.online() and not services.auth.signed_out() and services.outbox.pending() > 0:
		await services.outbox.flush(services.api)
	var n := services.outbox.pending()
	services.store.dispatch(&"auth_pending", {"pending": n})
	return n


## The player confirmed: this device signs out, or every device with
## `everywhere`. Answers the server's Result; the phone forgets the
## session whatever it says.
func sign_out(everywhere := false) -> Result:
	var account := _account()
	await before_sign_out()
	if services.api.online() and services.auth.fresh():
		await services.send_events()
	# With no account ever signed in on this phone nothing could have been
	# sent anyway; the queue waits as it is.
	var parked := services.outbox.park(parked_path(account)) if account != "" else services.outbox.pending()
	# The leases were this account's, the events its sessions'.
	while not services.heists.stock.take().is_empty():
		pass
	services.notices.sent(services.notices.pending().size())
	var told := await services.auth.sign_out(everywhere)
	services.store.dispatch(&"signed_out")
	var shown := {"status": "signed_out", "parked": parked, "owed": services.auth.revocation_owed()}
	services.store.dispatch(&"auth_status", shown)
	if reset.is_valid():
		reset.call(shown)
	return told
