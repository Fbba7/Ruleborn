class_name DefencesPresenter
extends RefCounted
## The defence log in words (§13.2, §23.2: "raids on you, each with its
## report (the haul denied, how long the defence held, where the crew was
## seen, what fired; 13.2), Trace"). Each raid is held when it was Foiled and
## leaked otherwise, Partial counted apart (§12.9, G69). Every number is the
## server's; a fact the server did not record says so.


static func screen(slice: Dictionary) -> Dictionary:
	var v: Dictionary = slice.get("view", {})
	var code := str(slice.get("error", ""))
	var out := {"ready": not v.is_empty(), "busy": str(slice.get("busy", "")),
		"error": "" if code == "" else Errors.message("DEFENCES_FAILED", code)}
	if v.is_empty():
		return out
	var s: Dictionary = v.get("season", {})
	out["header"] = Strings.t("DEFENCES_SEASON", [int(s.get("held", 0)), int(s.get("leaked", 0)),
		int(s.get("partial", 0))])
	var raids: Array[Dictionary] = []
	for r: Dictionary in v.get("raids", []):
		raids.append(raid(r))
	out["raids"] = raids
	if raids.is_empty():
		out["empty"] = Strings.t("DEFENCES_EMPTY")
	return out


## A raid's outcome in words: held or leaked, and its grade.
static func outcome(r: Dictionary) -> String:
	var grade := Strings.term("GRADE", str(r.get("grade", "foiled")))
	return Strings.t("DEFENCES_HELD", grade) if r.get("held", false) else Strings.t("DEFENCES_LEAKED", grade)


## Seconds as the heist clock says them: 1:35.
static func clock(seconds: int) -> String:
	return "%d:%02d" % [seconds / 60, seconds % 60]


## One raid's report: who, the outcome, the haul denied, how long the
## defence held, who was caught, the share earned, and its two buttons.
static func raid(r: Dictionary) -> Dictionary:
	var title := Strings.t("DEFENCES_RAIDER", int((r.get("raider", {}) as Dictionary).get("keeper_level", 1)))
	var lines: Array[String] = [outcome(r)]
	lines.append(Strings.t("DEFENCES_DENIED", ShopPresenter.grouped(int(r["denied"]))) if r.get("denied") != null
		else Strings.t("DEFENCES_DENIED_UNKNOWN"))
	lines.append(Strings.t("DEFENCES_HELD_FOR", clock(int(r["held_seconds"]))) if r.get("held_seconds") != null
		else Strings.t("DEFENCES_HELD_UNKNOWN"))
	lines.append(Strings.t("DEFENCES_CAUGHT", int(r.get("caught", 0))))
	if r.get("defence") is Dictionary and int(r["defence"]["total"]) > 0:
		lines.append(Strings.t("DEFENCES_SHARE", ShopPresenter.grouped(int(r["defence"]["total"]))))
	var heist := str(r.get("heist", ""))
	var kept := str(r.get("replay", "gone")) == "kept"
	var watch := {}
	if kept:
		watch = {"key": "watch:" + heist, "item": "watch:" + heist, "action": Strings.t("DEFENCES_WATCH"),
			"spoken": Strings.t("DEFENCES_WATCH_SPOKEN", title), "can": true, "why": ""}
	else:
		lines.append(Strings.t("DEFENCES_REPLAY_GONE"))
	var trace := {}
	if r.get("trace") is Dictionary:
		trace = {"key": "trace:" + heist, "item": "trace:" + heist, "action": Strings.t("DEFENCES_TRACE"),
			"spoken": Strings.t("DEFENCES_TRACE_SPOKEN", title), "can": true, "why": ""}
	return {"heist": heist, "title": title, "new": bool(r.get("new", false)), "lines": lines, "watch": watch,
		"trace": trace, "raid": r}


## The home's button for the log, with the raid badge's count.
static func place(unseen: int) -> String:
	return Strings.t("HOME_DEFENCES_NEW", unseen) if unseen > 0 else Strings.t("HOME_DEFENCES")
