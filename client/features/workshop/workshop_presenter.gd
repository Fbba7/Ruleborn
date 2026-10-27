class_name WorkshopPresenter
extends RefCounted
## What the Workshop screens show, from the store: plain data, no nodes.

## The lists, and the player's own.
const LISTS := ["top", "new", "featured", "mine"]


## An island as a card: its name, realm level, completions and ratings, who
## made it (no one, once they deleted their account, F43), and what the
## player may do with it.
static func item(i: Dictionary, me: String) -> Dictionary:
	var r: Dictionary = i.get("ratings", {})
	var creator: Variant = i.get("creator")
	var mine := creator != null and str(creator) == me
	var count := int(r.get("count", 0))
	var by := Strings.t("WORKSHOP_BY_NOBODY")
	if mine:
		by = Strings.t("WORKSHOP_BY_YOU")
	elif creator != null:
		by = SocialPresenter.who(str(creator), me)
	return {
		"id": str(i["id"]), "mine": mine, "name": SocialPresenter.named(i.get("name", "")),
		"title": Strings.t("WORKSHOP_ITEM", [SocialPresenter.named(i.get("name", "")), int(i.get("realmLevel", 1))]),
		"stats": Strings.t("WORKSHOP_STATS", [_number(i.get("completions", 0)), _number(i.get("remixes", 0))]),
		"ratings": Strings.t("WORKSHOP_RATINGS", [_one(r.get("fun")), _one(r.get("cleverness")),
			_one(r.get("fairness")), _number(count)]) if count > 0 else Strings.t("WORKSHOP_UNRATED"),
		"by": by,
		"remix": Strings.t("WORKSHOP_A_REMIX") if i.get("remixOf") != null else "",
		"featured": Strings.t("WORKSHOP_FEATURED") if i.get("featured", false) else "",
		"withdrawn": Strings.t("WORKSHOP_WITHDRAWN") if i.get("withdrawn", false) else "",
		"removed": _removed(i.get("removed")),
		"listed": not i.get("withdrawn", false) and i.get("removed") == null,
		# §17.8: another player's island offers to block its creator.
		"creator": str(creator) if creator != null and not mine else "",
		"fun": _one(r.get("fun")), "cleverness": _one(r.get("cleverness")), "fairness": _one(r.get("fairness")),
		"rated": count > 0, "completions": _number(i.get("completions", 0)), "remixes": _number(i.get("remixes", 0)),
	}


## The Workshop screen: the tabs the player may open, the list on show, the
## creator's ladder on their own list, and what the last action came to.
static func screen(w: Dictionary, me: String) -> Dictionary:
	var list := str(w.get("list", "top"))
	var items: Array[Dictionary] = []
	for i: Dictionary in w.get("items", []):
		items.append(item(i, me))
	var tabs: Array[String] = []
	for l: String in LISTS:
		if not w.get("curated", false) or l in ["featured", "mine"]:
			tabs.append(l)
	var ladder: Dictionary = w.get("ladder", {})
	return {"list": list, "tabs": tabs, "items": items, "error": str(w.get("error", "")),
		"busy": bool(w.get("busy", false)), "said": said(w),
		"empty": items.is_empty() and bool(w.get("loaded", false)) and not w.get("busy", false),
		"title": Strings.t("WORKSHOP_LIST_" + list.to_upper()),
		"ladder": _ladder(ladder) if list == "mine" and not ladder.is_empty() else ""}


## What the last action came to, in the player's words.
static func said(w: Dictionary) -> String:
	var done := str(w.get("done", ""))
	var last: Dictionary = w.get("last", {})
	match done:
		"":
			return ""
		"played":
			return Strings.t("WORKSHOP_CLEARED" if last.get("cleared", false) else "WORKSHOP_NOT_CLEARED")
		"published":
			return Strings.t("WORKSHOP_DONE_PUBLISHED", SocialPresenter.named(last.get("name", "")))
		"rated":
			return Strings.t("WORKSHOP_DONE_RATED")
		"reported":
			return Strings.t("WORKSHOP_DONE_REPORTED")
		"remixed":
			return Strings.t("WORKSHOP_DONE_REMIXED")
		"withdrawn":
			return Strings.t("WORKSHOP_DONE_WITHDRAWN")
		"blocked":
			return Strings.t("WORKSHOP_DONE_BLOCKED")
		"terms":
			return Strings.t("WORKSHOP_DONE_TERMS")
	return ""


## §20.11's terms-of-use gate: shown until the player has accepted the
## current terms, once the server has said which they are.
## The link is a path on the game's own server, which the screen puts after
## its address: anything else the answer names — `@host`, `.host`, a whole
## URL — would open another site, so it is the terms' own path instead
## (the security review's SR-06).
static func terms(w: Dictionary) -> Dictionary:
	var t: Dictionary = w.get("terms", {})
	var show := not t.is_empty() and not bool(t.get("accepted", false))
	var url := str(t.get("url", "/terms"))
	if RegEx.create_from_string("^/[a-z/]+$").search(url) == null:
		url = "/terms"
	return {"show": show, "text": Strings.t("WORKSHOP_TERMS", str(t.get("version", ""))) if show else "",
		"url": url}


## §18.6: the island just rehearsed may be published once it is cleared, on
## the clock and in no era a raid would face, as the server asks — each
## rehearsal is. The name is made from the word lists.
static func publishing(heist: Dictionary, w: Dictionary, adjective: int, noun: int) -> Dictionary:
	var v: Dictionary = heist.get("verdict", {})
	var replay: PackedByteArray = heist.get("replay", PackedByteArray())
	var can: bool = bool(heist.get("testing", false)) and not replay.is_empty() and WorkshopController.clears(v) \
		and not heist.get("published", false)
	var words: Dictionary = w.get("words", {})
	return {"can": can, "named": not words.is_empty(),
		"name": SocialPresenter.word_name(words, adjective, noun),
		"remix": Strings.t("WORKSHOP_PUBLISH_REMIX") if Draft.remix_of() != "" else ""}


## The island just played, to rate: its name, and each score as said aloud.
static func rating(w: Dictionary, scores: Dictionary) -> Dictionary:
	var played: Dictionary = w.get("played", {})
	var out := {"id": str(played.get("id", "")), "name": SocialPresenter.named(played.get("name", ""))}
	for aspect: String in ["fun", "cleverness", "fairness"]:
		out[aspect] = Strings.t("WORKSHOP_SCORE_" + aspect.to_upper(), int(scores[aspect]))
	return out


static func _ladder(l: Dictionary) -> String:
	var level: Variant = l.get("level")
	var where := Strings.t("WORKSHOP_LEVEL", Strings.term("CREATOR", str(level))) if level != null \
		else Strings.t("WORKSHOP_NO_LEVEL")
	return Strings.t("WORKSHOP_LADDER", [where, _number(l.get("completions", 0)), _number(l.get("featured", 0))])


## A count in the player's way of writing numbers. A completion from the
## creator's own constellation counts a quarter (§18.7), so a count may be
## fractional: its whole part is grouped as any other.
static func _number(v: Variant) -> String:
	var hundredths := int(roundf(float(v) * 100.0))
	var whole := ShopPresenter.grouped(floori(hundredths / 100.0))
	if hundredths % 100 == 0:
		return whole
	return whole + Strings.t("NUMBER_DECIMAL") + ("%02d" % (hundredths % 100))


static func _one(v: Variant) -> String:
	return "—" if v == null else ("%.1f" % float(v)).replace(".", Strings.t("NUMBER_DECIMAL"))


static func _removed(r: Variant) -> String:
	if not (r is Dictionary):
		return ""
	return Strings.t("WORKSHOP_REMOVED", Strings.term("REMOVAL", str((r as Dictionary).get("reason", "unfair"))))
