class_name SharePresenter
extends RefCounted
## The share sheet in words (§23.2: "The 15-second clip, challenge link,
## invite gift, age-band limits (20.7); no posting to the Beacon and no
## grading of moments"). §20.7 by band: a 13-to-15's challenge goes to
## in-game friends only, and clips stay in the game; a 16-to-17's clip
## leaves it after a confirmation; an adult's goes anywhere. §17.6's personal
## invite brings both players a matching cosmetic at the friend's first
## heist. The clip is TD.46's; deep links are not built (TD.23).


static func screen(slice: Dictionary, band: String) -> Dictionary:
	var link: Dictionary = slice.get("link", {})
	var code := str(slice.get("error", ""))
	var out := {"busy": bool(slice.get("busy", false)),
		"error": Errors.message("SHARE_FAILED", code) if code != "" else "",
		"limits": limits(band)}
	out["make"] = {"key": "make", "item": "make", "action": Strings.t("SHARE_MAKE"), "spoken": Strings.t("SHARE_MAKE"),
		"can": true, "why": ""}
	out["copied"] = Strings.t("SHARE_COPIED") if slice.get("copied", false) else ""
	var invite: Dictionary = slice.get("invite", {})
	out["gift"] = Strings.t("SHARE_INVITE_GIFT")
	out["invite"] = {"key": "invite", "item": "invite", "action": Strings.t("SHARE_INVITE"),
		"spoken": Strings.t("SHARE_INVITE"), "can": true, "why": ""}
	out["invitation"] = invitation(invite) if not invite.is_empty() else ""
	out["copy_invite"] = {} if invite.is_empty() else {"key": "copy_invite", "item": "copy_invite",
		"action": Strings.t("SHARE_COPY_INVITE"), "spoken": Strings.t("SHARE_COPY_INVITE"), "can": true, "why": ""}
	out["code"] = str(link.get("challenge", "")).to_upper()
	if link.is_empty():
		out["link"] = Strings.t("SHARE_NO_LINK")
		out["copy"] = {}
		return out
	out["link"] = message(link)
	out["copy"] = {"key": "copy", "item": "copy", "action": Strings.t("SHARE_COPY"), "spoken": Strings.t("SHARE_COPY"),
		"can": true, "why": ""}
	return out


## What is pasted for an invite: its code and how a friend accepts it.
static func invitation(invite: Dictionary) -> String:
	return Strings.t("SHARE_INVITE_MESSAGE", str(invite.get("invite", "")))


## What is pasted: the challenge's code and how a friend opens it.
static func message(link: Dictionary) -> String:
	return Strings.t("SHARE_MESSAGE", str(link.get("challenge", "")))


## §20.7's limits for the player's band, in words.
static func limits(band: String) -> Array[String]:
	var out: Array[String] = []
	match band:
		"13-15":
			out = [Strings.t("SHARE_LIMIT_CHALLENGE_FRIENDS"), Strings.t("SHARE_LIMIT_CLIP_NO")]
		"16-17":
			out = [Strings.t("SHARE_LIMIT_CHALLENGE_ANYONE"), Strings.t("SHARE_LIMIT_CLIP_CONFIRM")]
		_:
			out = [Strings.t("SHARE_LIMIT_CHALLENGE_ANYONE"), Strings.t("SHARE_LIMIT_CLIP_YES")]
	return out
