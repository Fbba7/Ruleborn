class_name WeavingPresenter
extends RefCounted
## Weaving in words (§23.2: "Two or three recommended laws, ranked with one
## that harmonises first, one that clashes last, then the cheapest, each
## compared by its points, the band after weaving and the harmonies and
## clashes it would make; stability bar with its seven bands; the harmonies
## and clashes a law would cause before it's woven; the weave's price and
## time on its button (5.6), priced by the server's one function"). Every
## number is the server's answer, priced by the simulation (TD.14); this
## only says them.

## §5.5's seven bands, Quiet to Breaking.
const BANDS := 7


static func screen(slice: Dictionary, now_ms: int) -> Dictionary:
	var v: Dictionary = slice.get("view", {})
	var code := str(slice.get("error", ""))
	var out := {"ready": not v.is_empty(), "busy": str(slice.get("busy", "")),
		"error": "" if code == "" else Errors.message("WEAVING_FAILED", code), "said": said(slice.get("last", {})),
		"confirming": UniversePresenter.confirming(slice.get("confirming", {})),
		"refused": refused(slice.get("refused", {}))}
	if v.is_empty():
		return out
	out["header"] = Strings.t("WEAVING_AETHER", ShopPresenter.grouped(int(v.get("aether", 0))))
	out["bar"] = bar(v.get("stability", {}))
	var realms: Array[Dictionary] = []
	for r: Dictionary in v.get("realms", []):
		realms.append(realm(r, now_ms))
	out["realms"] = realms
	return out


static func band_name(band: int) -> String:
	return Strings.t("WEAVING_BAND_%d" % clampi(band, 0, BANDS - 1))


## Points to two places at most, in the language's numbers: 8.4, 11.97, 116.
static func points(x: float) -> String:
	var hundredths := roundi(x * 100.0)
	var whole := hundredths / 100
	var part := hundredths % 100
	if part == 0:
		return ShopPresenter.grouped(whole)
	var digits := "%02d" % part
	return ShopPresenter.grouped(whole) + Strings.t("NUMBER_DECIMAL") + digits.trim_suffix("0")


## A time in minutes, as the weaving button says it.
static func duration(minutes: int) -> String:
	if minutes < 60:
		return Strings.t("WEAVING_MINUTES", minutes)
	if minutes % 60 == 0:
		return Strings.t("WEAVING_HOURS", minutes / 60)
	return Strings.t("WEAVING_HOURS_MINUTES", [minutes / 60, minutes % 60])


static func minutes_until(at_ms: int, now_ms: int) -> int:
	return maxi(1, ceili((at_ms - now_ms) / 60000.0))


## §5.5's bar: the seven bands, the one strain is in marked and its effect
## said, and the strain itself against capacity.
static func bar(st: Dictionary) -> Dictionary:
	var band := int(st.get("band", 0))
	var bands: Array[Dictionary] = []
	for i in BANDS:
		bands.append({"name": band_name(i), "current": i == band})
	return {"band": band, "bands": bands, "name": band_name(band), "effect": Strings.t("WEAVING_EFFECT_%d" % band),
		"percent": str(roundi(float(st.get("strain", 0.0)) * 100.0)) + "%", "share": float(st.get("strain", 0.0)),
		"total": points(float(st.get("total", 0.0))), "capacity": points(float(st.get("capacity", 0.0))),
		"strain": Strings.t("WEAVING_STRAIN", [str(roundi(float(st.get("strain", 0.0)) * 100.0)) + "%",
			points(float(st.get("total", 0.0))), points(float(st.get("capacity", 0.0))), band_name(band)])}


## The crown, or the realm's name: the Heart, or its type.
static func realm_title(r: Dictionary) -> String:
	if str(r["realm"]) == "crown":
		return Strings.t("WEAVING_CROWN")
	return UniversePresenter.realm_name(str(r.get("type", "")))


## A realm's slots, what each holds, and its offers: the recommended first,
## then every other restored law.
static func realm(r: Dictionary, now_ms: int) -> Dictionary:
	var name := str(r["realm"])
	var slots: Array[Dictionary] = []
	var free := 0
	for s: Dictionary in r.get("slots", []):
		var n := int(s["slot"])
		var law: Variant = s.get("law")
		if law is String:
			var law_name := Strings.term("LAW", law)
			var text := Strings.t("WEAVING_SLOT_WEAVING", [n, law_name, duration(minutes_until(int(s["ready_at"]), now_ms))]) \
				if s.get("weaving", false) else Strings.t("WEAVING_SLOT_LAW", [n, law_name, int(s["tier"])])
			slots.append({"n": n, "law": law, "state": "weaving" if s.get("weaving", false) else "woven",
				"tier": int(s.get("tier", 1)), "text": text, "out": {"key": "unweave:%s:%d" % [name, n],
				"item": "unweave:%s:%d" % [name, n],
				"action": Strings.t("WEAVING_UNWEAVE"), "spoken": Strings.t("WEAVING_UNWEAVE_SPOKEN", [law_name, n]),
				"can": true, "why": "", "args": {"realm": name, "slot": n}}})
		elif s.get("rests_until") != null:
			var rest := duration(minutes_until(int(s["rests_until"]), now_ms))
			slots.append({"n": n, "state": "resting", "text": Strings.t("WEAVING_SLOT_RESTING", [n, rest]),
				"out": {}})
		else:
			slots.append({"n": n, "state": "empty", "text": Strings.t("WEAVING_SLOT_EMPTY", n), "out": {}})
			if free == 0:
				free = n
	# §5.1: the crown's slots open with the Spire.
	if r.get("opens_at") != null:
		slots.append({"state": "locked", "text": Strings.t("WEAVING_CROWN_OPENS", int(r["opens_at"])), "out": {}})
	var by_law := {}
	# A realm with no slots yet offers nothing to weave in them.
	var offers: Array = r.get("offers", []) if not (r.get("slots", []) as Array).is_empty() else []
	for o: Dictionary in offers:
		by_law[o["law"]] = offer(o, name, free)
	var recommended: Array[Dictionary] = []
	for law: String in r.get("recommended", []):
		if by_law.has(law):
			recommended.append(by_law[law])
	var others: Array[Dictionary] = []
	for o: Dictionary in offers:
		if not (o["law"] in r.get("recommended", [])):
			others.append(by_law[o["law"]])
	return {"realm": name, "title": realm_title(r), "slots": slots, "recommended": recommended, "others": others,
		"type": str(r.get("type", "")) if r.get("type") is String else ""}


static func notes(ids: Array) -> String:
	return ", ".join(ids.map(func(n: String) -> String: return Strings.term("NOTE", n)))


## One law woven here: its points and the band after weaving, the harmonies
## and clashes it would make, and its button with the price and time.
static func offer(o: Dictionary, realm_id: String, free: int) -> Dictionary:
	var law := str(o["law"])
	var law_name := Strings.term("LAW", law)
	var lines: Array[String] = []
	if not (o.get("harmonies", []) as Array).is_empty():
		lines.append(Strings.t("WEAVING_HARMONISES", notes(o["harmonies"])))
	if not (o.get("clashes", []) as Array).is_empty():
		lines.append(Strings.t("WEAVING_CLASHES", notes(o["clashes"])))
	if int(o.get("resonances", 0)) > 0:
		lines.append(Strings.t("WEAVING_RESONANCE", int(o["resonances"])))
	if int(o.get("chords", 0)) > 0:
		lines.append(Strings.t("WEAVING_CHORD", int(o["chords"])))
	var price := ShopPresenter.grouped(int(o["price"]))
	var time := duration(int(o["minutes"]))
	var no: Variant = o.get("refused")
	var why := Errors.text(str(no)) if no is String else ("" if free > 0 else Strings.t("WEAVING_NO_SLOT"))
	var key := "weave:%s:%s" % [realm_id, law]
	var title := Strings.t("WEAVING_OFFER", [law_name, points(float(o["points"])), band_name(int(o["band"]))])
	return {"law": law, "title": title, "lines": lines, "band": int(o["band"]), "key": key, "item": key,
		"name": law_name, "points": points(float(o["points"])), "band_name": band_name(int(o["band"])),
		"harmonies": o.get("harmonies", []), "clashes": o.get("clashes", []), "resonances": int(o.get("resonances", 0)),
		"chords": int(o.get("chords", 0)), "price": price, "time": time,
		"action": Strings.t("WEAVING_BUTTON", [price, time]),
		"spoken": Strings.t("WEAVING_BUTTON_SPOKEN", [law_name, price, time]), "can": why == "", "why": why,
		"cost": price, "args": {"realm": realm_id, "slot": free, "law": law}}


## What the last change came to.
static func said(last: Variant) -> String:
	if not (last is Dictionary) or (last as Dictionary).is_empty():
		return ""
	var what: Dictionary = last
	match str(what.get("do", "")):
		"weave":
			return Strings.t("WEAVING_WOVEN", Strings.term("LAW", str(what["law"])))
		"unweave":
			return Strings.t("WEAVING_UNWOVEN")
	return ""


## A weave the phone kept offline that the server refused, and why.
static func refused(r: Variant) -> String:
	if not (r is Dictionary) or (r as Dictionary).is_empty():
		return ""
	var d: Dictionary = r
	var what: Dictionary = d["what"] if d["what"] is Dictionary else {}
	var law := Strings.term("LAW", str(what["law"])) if what.has("law") else Strings.t("WEAVING_UNWEAVE")
	return Strings.t("WEAVING_OFFLINE_REFUSED", [law, Errors.text(str(d["code"]))])
