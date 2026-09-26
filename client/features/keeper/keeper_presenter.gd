class_name KeeperPresenter
extends RefCounted
## The Keeper bar and a heist's experience, in words (§14.2): the level, ten
## pips filled by the share of the way to the next — the pips and the words
## say it, never a colour alone (§20.8) — and the numbers.

const PIPS := 10


static func bar(slice: Dictionary) -> Dictionary:
	var v: Dictionary = slice.get("view", {})
	if v.is_empty():
		return {"ready": false, "error": str(slice.get("error", ""))}
	var level := int(v.get("level", 1))
	var xp := int(v.get("xp", 0))
	var to_next: Variant = v.get("toNext")
	if to_next == null:
		var top := Strings.t("KEEPER_TOP", level)
		return {"ready": true, "title": Strings.t("KEEPER_TITLE", level), "pips": "●".repeat(PIPS),
			"progress": top, "spoken": top}
	var need := maxi(1, int(to_next))
	var filled := clampi(floori(PIPS * float(xp) / need), 0, PIPS)
	var progress := Strings.t("KEEPER_PROGRESS", [ShopPresenter.grouped(xp), ShopPresenter.grouped(need), level + 1])
	return {"ready": true, "title": Strings.t("KEEPER_TITLE", level),
		"pips": "●".repeat(filled) + "○".repeat(PIPS - filled), "progress": progress,
		"spoken": Strings.t("KEEPER_SPOKEN", [level, progress])}


## What a heist's answer says about the Keeper: the experience it earned and,
## if it climbed, the level reached. Empty for a heist that earned none.
static func earned(keeper: Variant) -> String:
	if not (keeper is Dictionary) or int((keeper as Dictionary).get("gained", 0)) <= 0:
		return ""
	var k: Dictionary = keeper
	var line := Strings.t("RESULT_KEEPER", ShopPresenter.grouped(int(k["gained"])))
	if int(k.get("levelled", 0)) > 0:
		line += "\n" + Strings.t("RESULT_KEEPER_UP", int(k["level"]))
	return line
