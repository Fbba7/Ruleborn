class_name AuthState
extends RefCounted
## Signing in as the store holds it, for the account panel: where it stands
## — "first" (no account made yet: the first heist makes it, §25.2),
## "signing_in", "signed_in", "failed" with the failure's code, "offline"
## (signed in, the server out of reach), "signed_out" — the devices signed
## in (each one's kind, model, country and last use, as the server lists
## them), the platforms that sign in to the account and those this device
## can prove, the last account change's words, and what a sign-out left
## waiting on the phone. The tokens are never here: the store's actions go
## into the log (AuthSession holds them).

const AUTH := &"auth"
const STATUSES := ["first", "signing_in", "signed_in", "failed", "offline", "signed_out"]


static func register(store: Store) -> void:
	store.register(AUTH, {"status": "first", "reason": "", "devices": 0, "parked": 0, "pending": 0,
			"owed": false, "list": [], "identities": [], "platforms": [], "notice": "", "failed": false}, {
		&"auth_status": status,
		&"auth_devices": devices,
		&"auth_pending": pending,
		&"auth_notice": notice,
	})


## `{status, reason?, parked?, owed?}`: a status, and why when it failed.
static func status(s: Dictionary, p: Dictionary) -> Dictionary:
	assert(str(p["status"]) in STATUSES, "no sign-in status %s" % p["status"])
	var next := s.duplicate()
	next["status"] = str(p["status"])
	next["reason"] = str(p.get("reason", ""))
	if p.has("parked"):
		next["parked"] = int(p["parked"])
	if p.has("owed"):
		next["owed"] = bool(p["owed"])
	return next


## `{devices, list?, identities?, platforms?}`: the count, and the lists
## when the server sent them.
static func devices(s: Dictionary, p: Dictionary) -> Dictionary:
	var next := s.duplicate()
	next["devices"] = int(p["devices"])
	for k: String in ["list", "identities", "platforms"]:
		if p.has(k):
			next[k] = (p[k] as Array).duplicate(true)
	return next


## `{notice, failed}`: how the last account change went, in words.
static func notice(s: Dictionary, p: Dictionary) -> Dictionary:
	var next := s.duplicate()
	next["notice"] = str(p["notice"])
	next["failed"] = bool(p.get("failed", false))
	return next


## What would still wait on the phone if the player signed out now.
static func pending(s: Dictionary, p: Dictionary) -> Dictionary:
	var next := s.duplicate()
	next["pending"] = int(p["pending"])
	return next
