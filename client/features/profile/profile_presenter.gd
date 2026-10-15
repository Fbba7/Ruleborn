class_name ProfilePresenter
extends RefCounted
## The Profile and stats in words (§23.2: "Renown and league over time, never
## the internal rating (12.15); heists by each outcome's own name (12.9);
## defences held (Foiled) and leaked (Clean, Loud and Partial, Partial
## counted apart; 12.9); the designs' ten records …; the battle log with
## replays; collection and 18.5's badges. Private, with no sharing, for 13 to
## 15 (20.2)"). Every number is the server's; a record with no fact yet says
## so, and titles come from mastery only (§18.5).

const GRADES := ["clean", "loud", "partial", "foiled"]
## The records that are lengths of time, said as a clock.
const TIMED := ["fastest_escape", "longest_defence"]


static func screen(slice: Dictionary) -> Dictionary:
	var v: Dictionary = slice.get("view", {})
	var code := str(slice.get("error", ""))
	var out := {"ready": not v.is_empty(), "busy": str(slice.get("busy", "")),
		"error": "" if code == "" else Errors.message("PROFILE_FAILED", code)}
	if v.is_empty():
		return out
	var league := SocialPresenter.league({"view": v.get("renown", {})})
	out["header"] = Strings.t("PROFILE_HEADER", [int(v.get("keeper_level", 1)), league.get("place", "")])
	var renown: Array[String] = [str(league.get("renown", ""))]
	for s: Dictionary in v.get("seasons", []):
		renown.append(Strings.t("PROFILE_SEASON", [int(s["season"]), ShopPresenter.grouped(int(s["renown"])),
			Strings.term("LEAGUE", str(s["league"]))]))
	out["renown"] = renown
	var h: Dictionary = v.get("heists", {})
	var counts := PackedStringArray()
	for g: String in GRADES:
		counts.append(Strings.t("PROFILE_COUNT", [Strings.term("GRADE", g), int(h.get(g, 0))]))
	out["heists"] = Strings.t("PROFILE_HEISTS", ", ".join(counts))
	var d: Dictionary = v.get("defences", {})
	out["defences"] = Strings.t("PROFILE_DEFENCES", [int(d.get("held", 0)), int(d.get("leaked", 0)),
		int(d.get("partial", 0))])
	var records: Array[String] = []
	for r: Dictionary in v.get("records", []):
		records.append(record(r))
	out["records"] = records
	var badges: Array[String] = []
	for b: Dictionary in v.get("badges", []):
		badges.append(badge(b))
	out["badges"] = badges
	var titles: Array[String] = []
	for t: Dictionary in v.get("titles", []):
		titles.append(Strings.t("PROFILE_TITLES", [Strings.t("SCHOOL_" + str(t["school"]).to_upper()),
			int(t["titles"]), int(t["steps"]), int(t["total"])]))
	if titles.is_empty():
		titles.append(Strings.t("PROFILE_NO_TITLES"))
	out["titles"] = titles
	var battles: Array[Dictionary] = []
	for e: Dictionary in v.get("log", []):
		battles.append(entry(e))
	out["log"] = battles
	out["share"] = share(v)
	return out


## One record: its value in words, or that no fact is kept for it yet.
static func record(r: Dictionary) -> String:
	var id := str(r["id"])
	var name := Strings.t("PROFILE_RECORD_" + id.to_upper())
	if r.get("value") == null:
		return Strings.t("PROFILE_RECORD_NONE", name)
	var value := int(r["value"])
	var said := DefencesPresenter.clock(roundi(value / 1000.0)) if id in TIMED else ShopPresenter.grouped(value)
	return Strings.t("PROFILE_RECORD", [name, said])


## One badge: its count against its mark, and the grade it has reached.
static func badge(b: Dictionary) -> String:
	var name := Strings.t("PROFILE_BADGE_" + str(b["id"]).to_upper())
	var count := ShopPresenter.grouped(int(b["count"]))
	var mark := ShopPresenter.grouped(int(b["mark"]))
	var got: Variant = b.get("grade")
	var grade := Strings.t("PROFILE_GRADE_" + str(got).to_upper()) if got != null else Strings.t("PROFILE_GRADE_NONE")
	return Strings.t("PROFILE_BADGE", [name, count, mark, grade])


## A heist of the battle log, with Watch replay while it is kept.
static func entry(e: Dictionary) -> Dictionary:
	var heist := str(e["heist"])
	var text := Strings.t("PROFILE_LOG", [Strings.term("GRADE", str(e["grade"])), ShopPresenter.grouped(int(e["haul"]))])
	var watch := {}
	if str(e.get("replay", "gone")) == "kept":
		watch = {"key": "watch:" + heist, "item": "watch:" + heist, "action": Strings.t("DEFENCES_WATCH"),
			"spoken": Strings.t("PROFILE_WATCH_SPOKEN", text), "can": true, "why": ""}
	else:
		text += Strings.t("PROFILE_LOG_GONE")
	return {"heist": heist, "text": text, "watch": watch, "raid": e}


## §20.2's switch: locked private for 13 to 15, else the player's to flip.
static func share(v: Dictionary) -> Dictionary:
	if not v.get("can_share", false):
		return {"locked": Strings.t("PROFILE_PRIVATE_AT_AGE")}
	var on: bool = v.get("public", false)
	var words := Strings.t("PROFILE_HIDE") if on else Strings.t("PROFILE_SHOW")
	return {"state": Strings.t("PROFILE_SHOWN") if on else Strings.t("PROFILE_HIDDEN"),
		"button": {"key": "share", "item": "share", "action": words, "spoken": words, "can": true, "why": "", "on": not on}}
