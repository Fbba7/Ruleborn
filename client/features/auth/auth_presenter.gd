class_name AuthPresenter
extends RefCounted
## The account panel in words: where signing in stands, a failure's reason
## as words rather than a code (Errors), and the two sign-outs with what
## each confirm says — the heists still waiting are named, never dropped
## without the player told.


## `{line, kind, detail, actions}`: the status in words, its status kind
## (UI.status), a second line, and the actions offered — "sign_in",
## "sign_out", "sign_out_everywhere", "retry".
static func panel(slice: Dictionary) -> Dictionary:
	var st := str(slice.get("status", "first"))
	var reason := str(slice.get("reason", ""))
	var out := {"kind": "info", "detail": "", "actions": [] as Array[String]}
	match st:
		"first":
			out["line"] = Strings.t("AUTH_FIRST")
			out["detail"] = Strings.t("AUTH_FIRST_DETAIL")
		"signing_in":
			out["line"] = Strings.t("AUTH_SIGNING_IN")
			out["kind"] = "confirming"
		"signed_in":
			var n := int(slice.get("devices", 0))
			out["line"] = Strings.t("AUTH_SIGNED_IN")
			out["kind"] = "success"
			out["detail"] = Strings.t("AUTH_DEVICES", n) if n > 1 else ""
			out["actions"] = ["sign_out", "sign_out_everywhere"] as Array[String]
		"offline":
			out["line"] = Strings.t("AUTH_OFFLINE")
			out["detail"] = Strings.t("AUTH_OFFLINE_DETAIL")
			out["actions"] = ["sign_out"] as Array[String]
		"failed":
			out["line"] = Errors.message("AUTH_FAILED", reason if reason != "" else "unknown")
			out["kind"] = "alarm"
			out["actions"] = ["retry"] as Array[String]
		_:
			out["line"] = Strings.t("AUTH_SIGNED_OUT")
			var parked := int(slice.get("parked", 0))
			var lines: Array[String] = []
			if parked > 0:
				lines.append(Strings.t("AUTH_PARKED", parked))
			if bool(slice.get("owed", false)):
				lines.append(Strings.t("AUTH_OWED"))
			out["detail"] = "\n".join(lines)
			out["actions"] = ["sign_in"] as Array[String]
	return out


## What a sign-out's confirm says: `{title, words, yes}`. `pending` is what
## waits to be sent: kept on the phone for this account, and said so.
static func confirm(everywhere: bool, pending: int) -> Dictionary:
	var words := Strings.t("AUTH_CONFIRM_ALL_WORDS" if everywhere else "AUTH_CONFIRM_WORDS")
	if pending > 0:
		words += "\n" + Strings.t("AUTH_CONFIRM_PENDING", pending)
	# Sign out everywhere is what a lost phone needs; its own platform
	# sign-in would still prove the identity (docs/security/auth.md T9).
	if everywhere:
		words += "\n" + Strings.t("AUTH_LOST_DEVICE")
	return {"title": Strings.t("AUTH_SIGN_OUT_ALL" if everywhere else "AUTH_SIGN_OUT"), "words": words,
		"yes": Strings.t("AUTH_SIGN_OUT_ALL" if everywhere else "AUTH_SIGN_OUT")}


## An action's words.
static func action(name: String) -> String:
	return Strings.t({"sign_in": "AUTH_SIGN_IN", "sign_out": "AUTH_SIGN_OUT",
		"sign_out_everywhere": "AUTH_SIGN_OUT_ALL", "retry": "AUTH_TRY_AGAIN"}[name])
