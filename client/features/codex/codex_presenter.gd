class_name CodexPresenter
extends RefCounted
## The Codex in words (§7.6, §18.5, §23.2): each school's album, its launch
## laws in chapter order, one not met yet a "?" that names nothing (D79); the
## milestones its restored laws reach; its mastery track; and each law's
## pages, tier and next step, with why it waits. Every number is the
## server's; this only says them.

## A tier as the game writes it: "tier III", never "mastered" (§18.5).
const ROMAN := ["0", "I", "II", "III"]
## §7.6's three milestones, in the order the album reaches them.
const MILESTONES := ["CODEX_MILESTONE_STAMP", "CODEX_MILESTONE_PENNANT", "CODEX_MILESTONE_CREST"]


static func screen(slice: Dictionary) -> Dictionary:
	var v: Dictionary = slice.get("view", {})
	var code := str(slice.get("error", ""))
	var out := {"ready": not v.is_empty(), "busy": str(slice.get("busy", "")),
		"error": "" if code == "" else Errors.message("CODEX_FAILED", code), "said": said(slice.get("last", {}))}
	if v.is_empty():
		return out
	out["header"] = Strings.t("CODEX_HEADER", [ShopPresenter.grouped(int(v.get("aether", 0))),
		int(v.get("keeper_level", 1)), int(v.get("spire", 1))])
	out["chapter"] = Strings.t("CODEX_CHAPTERS_OPEN") if v.get("next_chapter_at") == null \
		else Strings.t("CODEX_CHAPTER_NEXT", int(v["next_chapter_at"]))
	var working: Variant = v.get("working_on")
	out["working"] = Strings.t("CODEX_WORKING", Strings.term("LAW", working)) if working is String \
		else Strings.t("CODEX_WORKING_NONE")
	var tracks := {}
	for m: Dictionary in v.get("mastery", []):
		tracks[m["school"]] = m
	var albums: Array[Dictionary] = []
	for a: Dictionary in v.get("albums", []):
		albums.append(album(a, tracks.get(a["school"], {}), v))
	out["albums"] = albums
	return out


## One school's album: its name with its shape (§21.2), how many of its laws
## are restored, its milestones, its mastery track, and its laws.
static func album(a: Dictionary, m: Dictionary, v: Dictionary) -> Dictionary:
	var laws: Array = a.get("laws", [])
	var milestones: Array[String] = []
	var i := 0
	for ms: Dictionary in a.get("milestones", []):
		milestones.append(("✓ " if ms["reached"] else "○ ") + Strings.t(MILESTONES[mini(i, 2)], int(ms["at"])))
		i += 1
	var entries: Array[Dictionary] = []
	for l: Dictionary in laws:
		entries.append(entry(l, v))
	var marks: Dictionary = m.get("marks", {})
	return {"school": a["school"], "title": UI.school_mark(str(a["school"]).to_lower()),
		"count": Strings.t("CODEX_ALBUM", [int(a.get("restored", 0)), laws.size()]), "milestones": milestones,
		"mastery": Strings.t("CODEX_MASTERY", [int(m.get("steps", 0)), int(m.get("total", 0))]),
		"marks": Strings.t("CODEX_MASTERY_MARKS", [int(marks.get("title", 0)), int(marks.get("style", 0)),
			int(marks.get("last_title", 0))]),
		"laws": entries}


## One law of an album: a "?" until it is met; then its rank, pages and
## tier, the step that restores it or raises its tier with why that waits,
## and the button that marks it worked on.
static func entry(l: Dictionary, v: Dictionary) -> Dictionary:
	if not l.get("known", false):
		var text := Strings.t("CODEX_UNKNOWN") if l.get("open", false) \
			else Strings.t("CODEX_UNKNOWN_CLOSED", [int(l.get("chapter", 2)), int(v.get("next_chapter_at", 0))])
		return {"known": false, "text": text, "act": {}, "work": {}, "worked": false}
	var law := str(l["law"])
	var name := Strings.term("LAW", law)
	var rank := Strings.t("LAW_RANK_" + str(l["rank"]).to_upper())
	var tier := int(l["tier"])
	var pages := int(l["pages"])
	var next: Variant = l.get("next")
	var text := Strings.t("CODEX_LAW", [name, rank, ROMAN[tier], pages]) if tier > 0 \
		else Strings.t("CODEX_LAW_UNRESTORED", [name, rank, pages, int((next as Dictionary)["pages"])])
	var act := {}
	if next is Dictionary:
		act = step(law, name, tier, pages, next, l, v)
	var worked: bool = v.get("working_on") == law
	var work := {} if worked else {"key": "work:" + law, "item": "work:" + law, "action": Strings.t("CODEX_WORK_ON"),
		"spoken": Strings.t("CODEX_WORK_ON_SPOKEN", name), "can": true, "why": "", "args": {"law": law}}
	return {"known": true, "law": law, "text": text, "act": act, "work": work, "worked": worked,
		"worked_text": Strings.t("CODEX_WORKED") if worked else ""}


## The next step for a law met: restoring it at tier I, or its next tier, its
## price on the button and why it waits beside it.
static func step(law: String, name: String, tier: int, pages: int, next: Dictionary, l: Dictionary,
		v: Dictionary) -> Dictionary:
	var need := int(next["pages"])
	var why := ""
	if tier == 0:
		if not l.get("open", false):
			why = Strings.t("CODEX_CLOSED", [int(l.get("chapter", 2)), int(v.get("next_chapter_at", 0))])
		elif pages < need:
			why = Strings.t("CODEX_NEEDS_PAGES", [pages, need])
		return {"key": "restore:" + law, "item": "restore:" + law, "action": Strings.t("CODEX_RESTORE", need),
			"spoken": Strings.t("CODEX_RESTORE_SPOKEN", [name, need]), "cost": Strings.t("CODEX_PAGES", need),
			"can": why == "", "why": why, "args": {"law": law, "to": 1}}
	var to := tier + 1
	var aether := int(next.get("aether", 0))
	var price := ShopPresenter.grouped(aether)
	if int(v.get("spire", 1)) < int(next.get("spire", 0)):
		why = Strings.t("UNIVERSE_NEEDS_SPIRE", int(next["spire"]))
	elif pages < need:
		why = Strings.t("CODEX_NEEDS_PAGES", [pages, need])
	elif int(v.get("aether", 0)) < aether:
		why = Strings.t("CODEX_NEEDS_AETHER", price)
	return {"key": "tier:%s:%d" % [law, to], "item": "tier:%s:%d" % [law, to],
		"action": Strings.t("CODEX_TIER", [ROMAN[to], need, price]),
		"spoken": Strings.t("CODEX_TIER_SPOKEN", [name, ROMAN[to], need, price]),
		"cost": Strings.t("CODEX_TIER_COST", [need, price]), "can": why == "", "why": why,
		"args": {"law": law, "to": to}}


## What the last change came to.
static func said(last: Variant) -> String:
	if not (last is Dictionary) or (last as Dictionary).is_empty():
		return ""
	var what: Dictionary = last
	var name := Strings.term("LAW", str(what.get("law", "")))
	match str(what.get("do", "")):
		"restore":
			return Strings.t("CODEX_RESTORED", name)
		"tier":
			return Strings.t("CODEX_RAISED", [name, ROMAN[clampi(int(what.get("to", 2)), 0, 3)]])
		"work":
			return Strings.t("CODEX_WORKING_SET", name) if str(what.get("law", "")) != "" else ""
	return ""
