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


## How many devices are signed in to this account (the panel's line).
func devices() -> Result:
	var r := await services.api.get_json("/v1/session")
	if r.ok:
		services.store.dispatch(&"auth_devices", {"devices": int(r.value.get("devices", 0))})
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
