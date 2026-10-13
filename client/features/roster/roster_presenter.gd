class_name RosterPresenter
extends RefCounted
## The roster in words (§11.4 to §11.6, §23.2): every character's state as a
## symbol and a word (the screen adds its colour), how long a rest has left,
## where each works, and the one-tap reassign to the first producer with a
## free slot in §14.1's staffing order — the Heart's producers first, then
## each outer realm's in the order the realms opened. Prices and what a
## character may do are the server's answer; this only says them.

## Each state's symbol, so a state never rests on its colour (§20.8).
const MARK := {"working": "●", "guarding": "◆", "resting": "◐", "idle": "○"}
## The Spire's places, in the home view's words.
const SPIRE := "spire"
const GUARD_POST := "guardian_post"


## The screen: a header and one row a character.
static func screen(slice: Dictionary, now_ms: int) -> Dictionary:
	var v: Dictionary = slice.get("view", {})
	var out := {"ready": not v.is_empty(), "busy": str(slice.get("busy", "")),
		"error": error(str(slice.get("error", "")), slice.get("detail", {})), "said": said(slice.get("last", {}), v),
		"confirming": UniversePresenter.confirming(slice.get("confirming", {})),
		"refused": refused(slice.get("refused", {}), v)}
	if v.is_empty():
		return out
	var roster: Dictionary = v.get("roster", {})
	out["header"] = Strings.t("ROSTER_HEADER", [int(roster.get("used", 0)), int(roster.get("most", 0)),
		ShopPresenter.grouped(int(v.get("essence", 0)))])
	var named := names(v.get("characters", []))
	var rows: Array[Dictionary] = []
	for c: Dictionary in v.get("characters", []):
		rows.append(row(c, v, named, now_ms))
	out["rows"] = rows
	return out


## One character's row: its name, its state's mark and word, its rest timer,
## where it works, and the reassign button's words.
static func row(c: Dictionary, v: Dictionary, named: Dictionary, now_ms: int) -> Dictionary:
	var id := int(c["id"])
	var name: String = named.get(id, kind_name(str(c["kind"])))
	var st := state(c, now_ms)
	var line: String = "%s %s" % [st["mark"], st["word"]]
	if st["timer"] != "":
		line += " · " + st["timer"]
	var at := where(c, v)
	return {"id": id, "name": name, "state": str(c["state"]), "mark": st["mark"], "word": st["word"],
		"timer": st["timer"], "line": line, "where": at, "send": reassign(c, v, name),
		"spoken": Strings.t("ROSTER_OPEN_SPOKEN", [name, line if at == "" else line + ", " + at])}


## A state's symbol and word, and how long a rest has left.
static func state(c: Dictionary, now_ms: int) -> Dictionary:
	var s := str(c["state"])
	var timer := ""
	if s == "resting" and c.has("resting_until"):
		timer = back_in(int(c["resting_until"]) - now_ms)
	return {"mark": MARK.get(s, "?"), "word": Strings.t("ROSTER_STATE_" + s.to_upper()), "timer": timer}


## A rest's time left, by the minute begun: "back in 42 min", "back in 2 h 5 min".
static func back_in(ms: int) -> String:
	var minutes := maxi(1, ceili(ms / 60000.0))
	if minutes < 60:
		return Strings.t("ROSTER_BACK_MINUTES", minutes)
	return Strings.t("ROSTER_BACK_HOURS", [minutes / 60, minutes % 60])


## Each character's name: its kind's, numbered by the order it joined when
## the roster holds more than one of that kind.
static func names(characters: Array) -> Dictionary:
	var count := {}
	for c: Dictionary in characters:
		count[c["kind"]] = int(count.get(c["kind"], 0)) + 1
	var seen := {}
	var out := {}
	for c: Dictionary in characters:
		var kind := str(c["kind"])
		seen[kind] = int(seen.get(kind, 0)) + 1
		out[int(c["id"])] = kind_name(kind) if int(count[kind]) == 1 else "%s %d" % [kind_name(kind), int(seen[kind])]
	return out


static func kind_name(kind: String) -> String:
	return Strings.term("RULEBORN", kind)


## A realm's name from the home view's realms: the Heart, or its type.
static func realm_label(realm: String, v: Dictionary) -> String:
	for r: Dictionary in v.get("realms", []):
		if r["realm"] == realm:
			return UniversePresenter.realm_name(str(r["type"]))
	return UniversePresenter.realm_name("Heart") if realm == "heart" else realm


## Where a character lives: the Spire's places, or a realm's Hearth.
static func home_label(home: String, v: Dictionary) -> String:
	return UniversePresenter.building_name("keeper_s_spire") if home == SPIRE else realm_label(home, v)


## A building and its realm: "Star Well, The Heart"; a post numbered.
static func place(realm: String, kind: String, n: int, v: Dictionary) -> String:
	var building := UniversePresenter.building_name(kind)
	if kind == GUARD_POST and n > 1:
		building = "%s %d" % [building, n]
	return Strings.t("ROSTER_PLACE", [building, realm_label(realm, v)])


## Where a character works or guards, or "" when it does neither.
static func where(c: Dictionary, v: Dictionary) -> String:
	var w: Variant = c.get("work")
	if not (w is Dictionary):
		return ""
	var d: Dictionary = w
	return place(str(d["realm"]), str(d["kind"]), int(d.get("n", 1)), v)


## §14.1's staffing order: the producers by the order their realms opened,
## and within a realm in the server's order; the first with a slot no
## character holds — counted from the roster, since a slot stays held while
## its worker rests — that is not where `c` already works. {} when there is
## none.
static func first_unstaffed(v: Dictionary, c: Dictionary) -> Dictionary:
	var realms: Array = v.get("realms", [])
	var order := {}
	for i in realms.size():
		order[str(realms[i]["realm"])] = i
	var held := {}
	for other: Dictionary in v.get("characters", []):
		if other.get("work") is Dictionary:
			var at := "%s/%s" % [other["work"]["realm"], other["work"]["kind"]]
			held[at] = int(held.get(at, 0)) + 1
	var mine := "%s/%s" % [c["work"]["realm"], c["work"]["kind"]] if c.get("work") is Dictionary else ""
	var best := {}
	var best_rank := 1 << 30
	var producers: Array = v.get("producers", [])
	for i in producers.size():
		var p: Dictionary = producers[i]
		var at := "%s/%s" % [p["realm"], p["kind"]]
		var rank := int(order.get(str(p["realm"]), realms.size())) * producers.size() + i
		if at != mine and int(held.get(at, 0)) < int(p["slots"]) and rank < best_rank:
			best = p
			best_rank = rank
	return best


## The reassign button: one tap sends the character to the first producer
## with a free slot; with none, the button waits and says why.
static func reassign(c: Dictionary, v: Dictionary, name: String) -> Dictionary:
	var id := int(c["id"])
	var p := first_unstaffed(v, c)
	if p.is_empty():
		return {"key": "work:%d" % id, "item": "work:%d" % id, "action": Strings.t("ROSTER_SEND_WORK"),
			"spoken": Strings.t("ROSTER_SEND_WORK"), "can": false, "why": Strings.t("ROSTER_ALL_STAFFED"),
			"args": {}, "place": ""}
	var to := place(str(p["realm"]), str(p["kind"]), 1, v)
	return {"key": "work:%d:%s:%s" % [id, p["realm"], p["kind"]], "item": "work:%d" % id,
		"action": Strings.t("ROSTER_SEND", to), "spoken": Strings.t("ROSTER_SEND_SPOKEN", [name, to]),
		"can": true, "why": "", "args": {"id": id, "realm": str(p["realm"]), "kind": str(p["kind"]), "n": 1},
		"place": to}


## One character in detail (§23.2's Character screen): school, role,
## ability, traits, level, best work; where it lives and works; and what
## Essence can do for it now — the next level, or waking from a rest — at
## the prices the server says.
static func character(slice: Dictionary, id: int, now_ms: int) -> Dictionary:
	var v: Dictionary = slice.get("view", {})
	var out := {"ready": not v.is_empty(), "missing": false, "busy": str(slice.get("busy", "")),
		"error": error(str(slice.get("error", "")), slice.get("detail", {})), "said": said(slice.get("last", {}), v)}
	if v.is_empty():
		return out
	var found := {}
	for c: Dictionary in v.get("characters", []):
		if int(c["id"]) == id:
			found = c
	if found.is_empty():
		out["missing"] = true
		return out
	var c := found
	var kind := str(c["kind"])
	var r := row(c, v, names(v.get("characters", [])), now_ms)
	var traits: Array[String] = []
	for t: String in c.get("traits", []):
		traits.append(Strings.t("CHARACTER_TRAIT", [Strings.term("TRAIT", t), Strings.term("TRAIT_EFFECT", t)]))
	out.merge({"title": r["name"], "state": r["state"], "line": r["line"], "where": r["where"], "send": r["send"],
		"school": str(c["school"]).to_lower(), "role": Strings.term("ROLE", str(c["role"])),
		"ability": Strings.t("CHARACTER_ABILITY", Strings.term("ABILITY", kind)),
		"best": Strings.t("CHARACTER_BEST_AT", Strings.term("BEST_AT", kind)), "traits": traits,
		"level": Strings.t("CHARACTER_LEVEL", [int(c["level"]), int(c["top"])]),
		"lives": Strings.t("CHARACTER_LIVES", home_label(str(c["home"]), v)),
		"raise": raise_offer(c, r["name"]), "wake": wake_offer(c, r["name"])}, true)
	return out


## The next level, at the server's price; held back, in words, when the
## character's home allows no higher; null at the top, which the screen
## says (CHARACTER_TOP_LEVEL).
static func raise_offer(c: Dictionary, name: String) -> Variant:
	var next: Variant = c.get("next_level")
	var id := int(c["id"])
	if not (next is Dictionary):
		return null
	var n: Dictionary = next
	var cost := ShopPresenter.grouped(int(n["cost"]))
	var action := Strings.t("CHARACTER_RAISE", [int(n["to"]), cost])
	var blocked := str(n.get("blocked", "")) if n.get("blocked") != null else ""
	return {"key": "level:%d:%d" % [id, int(n["to"])], "item": "level:%d" % id, "action": action,
		"spoken": "%s: %s" % [name, action], "can": blocked == "",
		"why": Strings.t("CHARACTER_TOP") if blocked == "home_too_low" else "", "cost": cost,
		"args": {"id": id, "to": int(n["to"])}}


## Waking from a rest early, at the server's price; null when not resting.
static func wake_offer(c: Dictionary, name: String) -> Variant:
	if str(c["state"]) != "resting" or not c.has("wake_cost"):
		return null
	var id := int(c["id"])
	var cost := ShopPresenter.grouped(int(c["wake_cost"]))
	var action := Strings.t("CHARACTER_WAKE", cost)
	return {"key": "wake:%d" % id, "item": "wake:%d" % id, "action": action, "spoken": "%s: %s" % [name, action],
		"can": true, "why": "", "cost": cost, "args": {"id": id}}


## What the last change came to.
static func said(last: Variant, v: Dictionary) -> String:
	if not (last is Dictionary) or (last as Dictionary).is_empty():
		return ""
	var what: Dictionary = (last as Dictionary).get("what", {})
	match str(what.get("do", "")):
		"work":
			return Strings.t("ROSTER_SENT", [str(what.get("name", "")),
				place(str(what["realm"]), str(what["kind"]), int(what.get("n", 1)), v)])
		"level":
			return Strings.t("CHARACTER_RAISED", int(what["to"]))
		"wake":
			return Strings.t("CHARACTER_WOKEN")
	return ""


## Work the phone assigned offline that the server refused, and why.
static func refused(r: Variant, _v: Dictionary) -> String:
	if not (r is Dictionary) or (r as Dictionary).is_empty():
		return ""
	var d: Dictionary = r
	var what: Dictionary = d["what"] if d["what"] is Dictionary else {}
	return Strings.t("ROSTER_OFFLINE_REFUSED", [str(what.get("name", "")), Errors.text(str(d["code"]))])


## A failure in words.
static func error(code: String, _detail: Variant) -> String:
	return "" if code == "" else Errors.message("ROSTER_FAILED", code)
