class_name SagePresenter
extends RefCounted
## The Sage hall in words (§11.7, §23.2: "Powers and what each fifth level
## adds, the level (the Keeper's), guardian choice"): each Sage's heist
## powers and at-home effect from its card, every fifth level's gain marked
## reached or not at the Keeper's level, when a locked Sage unlocks, and the
## choice of which Sage guards the Heart. Which Sage is unlocked is the
## server's answer; this only says it.

## §11.7: "Every fifth level improves one power", from 5 to 40.
const FIFTH := [5, 10, 15, 20, 25, 30, 35, 40]


static func screen(slice: Dictionary) -> Dictionary:
	var v: Dictionary = slice.get("view", {})
	var code := str(slice.get("error", ""))
	var out := {"ready": not v.is_empty(), "busy": str(slice.get("busy", "")),
		"error": "" if code == "" else Errors.message("SAGE_FAILED", code), "said": said(slice.get("last", {}))}
	if v.is_empty():
		return out
	var level := int(v["level"])
	out["header"] = Strings.t("SAGE_HEADER", level)
	var guardian: Variant = v.get("guardian")
	out["guard"] = Strings.t("SAGE_STATIONED", sage_name(str(guardian))) if guardian is String \
		else Strings.t("SAGE_NONE_ON_GUARD")
	var sages: Array[Dictionary] = []
	for s: Dictionary in v.get("sages", []):
		sages.append(sage(s, level))
	out["sages"] = sages
	return out


static func sage_name(id: String) -> String:
	return Strings.term("SAGE", id)


## One Sage: its name, whether it is unlocked or the level it unlocks at,
## its powers and at-home effect, each fifth level's gain, and the guard
## button.
static func sage(s: Dictionary, level: int) -> Dictionary:
	var id := str(s["id"])
	var key := id.to_upper()
	var levels: Array[Dictionary] = []
	for lv: int in FIFTH:
		var k := "SAGE_LEVEL_%d_%s" % [lv, key]
		if Strings.rows().has(k):
			var reached := level >= lv
			levels.append({"level": lv, "reached": reached,
				"text": Strings.t("SAGE_LEVEL_REACHED" if reached else "SAGE_LEVEL_AHEAD", [lv, Strings.t(k)])})
	var unlocked := bool(s["unlocked"])
	var guarding := bool(s.get("guardian", false))
	return {"id": id, "name": sage_name(id), "unlocked": unlocked, "guarding": guarding,
		"lock": Strings.t("SAGE_UNLOCKED") if unlocked else Strings.t("SAGE_UNLOCKS", int(s["unlocks_at"])),
		"powers": Strings.t("SAGE_POWERS", Strings.t("SAGE_POWERS_" + key)),
		"home": Strings.t("SAGE_AT_HOME", Strings.t("SAGE_HOME_" + key)), "levels": levels,
		"button": guard_button(id, unlocked, guarding, int(s["unlocks_at"]))}


## The guard choice: a Sage on guard can be taken off; an unlocked one put
## on, in another's place; a locked one waits and says until when.
static func guard_button(id: String, unlocked: bool, guarding: bool, unlocks_at: int) -> Dictionary:
	if guarding:
		return {"key": "guard:none", "item": "guard:" + id, "action": Strings.t("SAGE_RECALL"),
			"spoken": Strings.t("SAGE_RECALL_SPOKEN", sage_name(id)), "can": true, "why": "", "sage": null}
	return {"key": "guard:" + id, "item": "guard:" + id, "action": Strings.t("SAGE_STATION"),
		"spoken": Strings.t("SAGE_STATION_SPOKEN", sage_name(id)), "can": unlocked,
		"why": "" if unlocked else Strings.t("SAGE_UNLOCKS", unlocks_at), "sage": id}


## What the last change came to.
static func said(last: Variant) -> String:
	if not (last is Dictionary) or not (last as Dictionary).has("guardian"):
		return ""
	var g: Variant = (last as Dictionary)["guardian"]
	return Strings.t("SAGE_STATIONED", sage_name(str(g))) if g is String else Strings.t("SAGE_NONE_ON_GUARD")
