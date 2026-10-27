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


## A platform's name: "Game Center" or "Google".
static func platform_name(platform: String) -> String:
	return Strings.t("AUTH_VIA_GC" if platform == "gc" else "AUTH_VIA_GP")


## A device of the list as a row: `{id, current, title, line, spoken}`.
## Its model as it named itself, else its kind in words; then when it was
## last used (not for this device, which the panel marks), the country in
## words (never an address), and the platform it signed in with.
static func device_row(d: Dictionary) -> Dictionary:
	var kind := str(d.get("device", "other"))
	var named := str(d.get("model", "")) if d.get("model") != null else ""
	var title := named if named != "" else Strings.t("AUTH_KIND_" + kind.to_upper())
	var current := bool(d.get("current", false))
	# This device says so on its own mark (the panel's pill), and in what a
	# screen reader says.
	var parts: Array[String] = []
	if not current:
		parts.append(seen(int(d.get("idleHours", 0))))
	parts.append(place(d.get("place")))
	if d.get("via") != null:
		parts.append(platform_name(str(d["via"])))
	var line := " · ".join(parts)
	return {"id": int(d.get("id", 0)), "current": current, "title": title, "line": line,
		"kind": kind, "spoken": "%s. %s%s" % [title, Strings.t("AUTH_THIS_DEVICE") + ". " if current else "",
			line.replace(" · ", ". ")]}


## When a device was last used, in words, from the whole hours since that
## the server counted (its clock, not this phone's).
static func seen(hours: int) -> String:
	if hours < 1:
		return Strings.t("AUTH_SEEN_NOW")
	if hours < 24:
		return Strings.t("AUTH_SEEN_HOURS", hours)
	if hours < 48:
		return Strings.t("AUTH_SEEN_DAY")
	return Strings.t("AUTH_SEEN_DAYS", hours / 24)


## A country's ISO code in words, as the engine names it; unknown, said so.
static func place(code: Variant) -> String:
	var c := str(code) if code != null else ""
	if c.length() != 2:
		return Strings.t("AUTH_PLACE_UNKNOWN")
	var named := TranslationServer.get_country_name(c)
	return named if named != "" else Strings.t("AUTH_PLACE_UNKNOWN")


## The ways to sign in as rows: `{platform, title, line, action}` — each
## platform the account signs in with (the one it was made with, and a link
## this device may remove: never the one it signs in with, which vouches),
## then a platform this device can prove and the account lacks, offered.
static func methods(slice: Dictionary, device_primary: String) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	var have: Array[String] = []
	for i: Variant in slice.get("identities", []):
		var ident: Dictionary = i
		var p := str(ident.get("platform", ""))
		have.append(p)
		var primary := bool(ident.get("primary", false))
		out.append({"platform": p, "title": platform_name(p),
			"line": Strings.t("AUTH_METHOD_PRIMARY" if primary else "AUTH_METHOD_LINKED"),
			"action": "unlink" if not primary and p != device_primary else ""})
	for p: Variant in slice.get("platforms", []):
		if str(p) not in have and not have.is_empty():
			var k := "AUTH_LINK_" + str(p).to_upper()
			out.append({"platform": str(p), "title": Strings.t(k), "line": Strings.t(k + "_LINE"),
				"action": "link"})
	return out


## The confirm for ending one device, every other, or removing a platform:
## `{title, words, yes, no}`.
static func confirm_change(what: String, name := "") -> Dictionary:
	match what:
		"device":
			return {"title": Strings.t("AUTH_SIGN_OUT"), "words": Strings.t("AUTH_CONFIRM_DEVICE_WORDS", name),
				"yes": Strings.t("AUTH_SIGN_OUT"), "no": Strings.t("AUTH_CANCEL")}
		"others":
			return {"title": Strings.t("AUTH_SIGN_OUT_OTHERS"), "words": Strings.t("AUTH_CONFIRM_OTHERS_WORDS"),
				"yes": Strings.t("AUTH_SIGN_OUT_OTHERS"), "no": Strings.t("AUTH_CANCEL")}
	return {"title": Strings.t("AUTH_CONFIRM_UNLINK_TITLE", name), "words": Strings.t("AUTH_CONFIRM_UNLINK_WORDS"),
		"yes": Strings.t("AUTH_UNLINK"), "no": Strings.t("AUTH_KEEP")}


## An action's words.
static func action(name: String) -> String:
	return Strings.t({"sign_in": "AUTH_SIGN_IN", "sign_out": "AUTH_SIGN_OUT",
		"sign_out_everywhere": "AUTH_SIGN_OUT_ALL", "retry": "AUTH_TRY_AGAIN", "sign_out_others": "AUTH_SIGN_OUT_OTHERS",
		"link": "AUTH_LINK", "unlink": "AUTH_UNLINK", "end_device": "AUTH_SIGN_OUT"}[name])
