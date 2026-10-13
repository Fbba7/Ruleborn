class_name UniversePresenter
extends RefCounted
## The universe in words (§5.2, §10.2): each realm, its buildings and their
## next levels, what there is room to build, and the next realm to open. What
## can be bought, and why not, is the server's answer; this only says it, so
## no rule is worked out twice.


## The screen: a header, one entry a realm, the next realm to open, and what
## the last purchase came to.
static func screen(slice: Dictionary) -> Dictionary:
	var v: Dictionary = slice.get("view", {})
	var out := {"ready": not v.is_empty(), "busy": str(slice.get("busy", "")),
		"error": _error(str(slice.get("error", "")), slice.get("detail", {})), "said": said(slice.get("last", {})),
		"confirming": confirming(slice.get("confirming", {})), "refused": refused(slice.get("refused", {}))}
	if v.is_empty():
		return out
	out["header"] = Strings.t("UNIVERSE_HEADER", [ShopPresenter.grouped(int(v["starlight"])), int(v["spire"]),
		int(v["keeper"])])
	var realms: Array[Dictionary] = []
	for r: Dictionary in v["realms"]:
		realms.append(realm(r))
	out["realms"] = realms
	out["open"] = opening(v.get("open"))
	return out


## What the phone built offline and the server has not yet confirmed (§24).
static func confirming(waiting: Variant) -> String:
	var n := (waiting as Dictionary).size() if waiting is Dictionary else 0
	return Strings.t("UNIVERSE_CONFIRMING", n) if n > 0 else ""


## The last thing built offline that the server refused, and why.
static func refused(r: Variant) -> String:
	if not (r is Dictionary) or (r as Dictionary).is_empty():
		return ""
	var d: Dictionary = r
	var what: Dictionary = d["what"] if d["what"] is Dictionary else {}
	var name := building_name(str(what.get("kind", ""))) if what.has("kind") else ""
	return Strings.t("UNIVERSE_OFFLINE_REFUSED", [name, _error(str(d["code"]), d.get("detail", {}))])


## A failure in words, with what it needed when the server said.
static func _error(code: String, detail: Variant) -> String:
	if code == "":
		return ""
	var d: Dictionary = detail if detail is Dictionary else {}
	if code == "needs_keeper_level" and d.has("needs"):
		return Strings.t("UNIVERSE_NEEDS_KEEPER", int(d["needs"]))
	if code == "needs_spire_level" and d.has("needs"):
		return Strings.t("UNIVERSE_NEEDS_SPIRE", int(d["needs"]))
	return Errors.message("UNIVERSE_FAILED", code)


## A realm's name: the Heart, or its type.
static func realm_name(type: String) -> String:
	return Strings.t("UNIVERSE_HEART") if type == "Heart" else Strings.term("REALM", type.replace(" ", "_"))


static func building_name(kind: String, fallback := "") -> String:
	var name := Strings.term("BUILDING", kind)
	return fallback if name == kind and fallback != "" else name


static func realm(r: Dictionary) -> Dictionary:
	var here: String = r["realm"]
	var title := Strings.t("UNIVERSE_HEART_TITLE", int(r["level"])) if here == "heart" \
		else Strings.t("UNIVERSE_REALM_TITLE", [realm_name(str(r["type"])), int(r["level"])])
	# A kind with more than one place in the realm is numbered.
	var count := {}
	for b: Dictionary in (r["buildings"] as Array) + (r["room"] as Array):
		count[b["kind"]] = int(count.get(b["kind"], 0)) + 1
	var rows: Array[Dictionary] = []
	for b: Dictionary in r["buildings"]:
		rows.append(building(here, b, int(count[b["kind"]]) > 1))
	var room: Array[Dictionary] = []
	for b: Dictionary in r["room"]:
		room.append(to_build(here, b, int(count[b["kind"]]) > 1))
	var raise: Variant = null
	if r.get("raise") is Dictionary:
		var to := int(r["level"]) + 1
		raise = offer("raise:%s:%d" % [here, to], Strings.t("UNIVERSE_RAISE_REALM", to), r["raise"],
			{"realm": here, "to": to})
	return {"key": here, "title": title, "rows": rows, "room": room, "raise": raise}


## A building on show, and its next level if it has one.
static func building(realm_id: String, b: Dictionary, numbered: bool) -> Dictionary:
	var name := _named(b, numbered)
	var line := Strings.t("UNIVERSE_LEVEL", [name, int(b["level"]), int(b["top"])])
	if not (b.get("next") is Dictionary):
		var top := Strings.t("UNIVERSE_AT_TOP", line)
		return {"key": "", "item": "", "text": top, "action": "", "can": false, "why": "", "spoken": top}
	var to := int(b["level"]) + 1
	var o := offer("build:%s:%s:%d:%d" % [realm_id, b["kind"], int(b["n"]), to],
		Strings.t("UNIVERSE_RAISE", to), b["next"],
		{"realm": realm_id, "kind": b["kind"], "n": int(b["n"]), "to": to})
	o["text"] = line
	o["spoken"] = Strings.t("UNIVERSE_SPOKEN", [line, o["spoken"]])
	return o


## A kind there is room to build.
static func to_build(realm_id: String, b: Dictionary, numbered: bool) -> Dictionary:
	var name := _named(b, numbered)
	var o := offer("build:%s:%s:%d:1" % [realm_id, b["kind"], int(b["n"])], Strings.t("UNIVERSE_BUILD", name), b,
		{"realm": realm_id, "kind": b["kind"], "n": int(b["n"]), "to": 1})
	o["text"] = name
	return o


static func _named(b: Dictionary, numbered: bool) -> String:
	var name := building_name(str(b["kind"]), str(b.get("name", "")))
	return Strings.t("UNIVERSE_NUMBERED", [name, int(b["n"])]) if numbered else name


## A purchase: its button's words and price, and, when it cannot be bought
## now, why — a Keeper level, a Spire level, or the Starlight — in words, not
## by a disabled button alone (§20.8).
## `item` names what is bought — a building, a realm's level, the opening —
## and stays the same after it is bought, so focus can return to it.
static func offer(key: String, action: String, o: Dictionary, args: Dictionary) -> Dictionary:
	var cost := ShopPresenter.grouped(int(o["cost"]))
	var needs: Dictionary = o.get("needs", {})
	var why := ""
	match str(o.get("blocked", "")):
		"keeper_level":
			why = Strings.t("UNIVERSE_NEEDS_KEEPER", int(needs.get("keeper", 0)))
		"spire_level":
			why = Strings.t("UNIVERSE_NEEDS_SPIRE", int(needs.get("spire", 0)))
		"starlight":
			why = Strings.t("UNIVERSE_NEEDS_STARLIGHT", cost)
	var priced := Strings.t("UNIVERSE_PRICE", [action, cost])
	var item := "open" if key.begins_with("open:") else ":".join(key.split(":").slice(0, -1))
	return {"key": key, "item": item, "action": priced, "can": why == "", "why": why, "cost": cost, "args": args,
		"spoken": priced if why == "" else Strings.t("UNIVERSE_BLOCKED", [priced, why])}


## The next realm to open, one button a type still unowned.
static func opening(o: Variant) -> Variant:
	if not (o is Dictionary):
		return null
	var d: Dictionary = o
	var rows: Array[Dictionary] = []
	for type: String in d["types"]:
		rows.append(offer("open:" + type, Strings.t("UNIVERSE_OPEN", realm_name(type)), d, {"type": type}))
	return {"title": Strings.t("UNIVERSE_OPEN_TITLE"), "rows": rows}


## What the last purchase came to: what it bought, and the Keeper experience.
static func said(last: Variant) -> String:
	if not (last is Dictionary) or (last as Dictionary).is_empty():
		return ""
	var l: Dictionary = last
	var what: Dictionary = l["what"]
	var line: String
	if what.has("realm"):
		line = Strings.t("UNIVERSE_OPENED", realm_name(str(what["realm"])))
	elif what.has("raise"):
		line = Strings.t("UNIVERSE_RAISED", int(what["to"]))
	else:
		line = Strings.t("UNIVERSE_BUILT", [building_name(str(what["kind"])), int(what["to"])])
	var keeper := KeeperPresenter.earned(l.get("keeper"))
	return line + ("\n" + keeper if keeper != "" else "")
