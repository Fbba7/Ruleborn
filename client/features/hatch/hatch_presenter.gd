class_name HatchPresenter
extends RefCounted
## Hatching in words (§23.2's Hatch: "Ready births and the Nursery's three
## places, the Essence price, the kind's odds by 11.9's weights, the form and
## its odds on a tie, the two traits rolled, and naming from word lists,
## offered the first time one hatches with a free outfit; a stray found in a
## heist is offered here at the same price"). Every odd and price is the
## server's answer (the home view); this only says them.


static func screen(slice: Dictionary, words: Dictionary, now_ms: int, pick := {}) -> Dictionary:
	var v: Dictionary = slice.get("view", {})
	var code := str(slice.get("error", ""))
	var out := {"ready": not v.is_empty(), "busy": str(slice.get("busy", "")),
		"error": "" if code == "" else Errors.message("HATCH_FAILED", code)}
	if v.is_empty():
		out["said"] = ""
		return out
	var cost := int(v.get("next_birth", 0))
	var essence := int(v.get("essence", 0))
	out["header"] = Strings.t("HATCH_HEADER", [ShopPresenter.grouped(cost), ShopPresenter.grouped(essence)])
	var nurseries: Array[Dictionary] = []
	for n: Dictionary in v.get("nurseries", []):
		nurseries.append(nursery(n, v, cost, essence, now_ms))
	out["nurseries"] = nurseries
	out["none"] = Strings.t("HATCH_NO_NURSERY", UniversePresenter.building_name("nursery")) if nurseries.is_empty() \
		else ""
	var strays: Array[Dictionary] = []
	for s: Dictionary in v.get("strays", []):
		strays.append(stray(s, essence))
	out["strays"] = strays
	out["newborn"] = newborn(slice.get("last", {}), v, words, pick)
	out["said"] = said(slice.get("last", {}), v, words)
	return out


## "25%": odds as a whole percentage.
static func percent(odds: float) -> String:
	return str(roundi(odds * 100.0)) + "%"


## A form's odds: one note for certain, or each tied note's share.
static func forms(odds: Array) -> String:
	var lead := odds.filter(func(f: Dictionary) -> bool: return float(f["odds"]) > 0.0)
	if lead.size() == 1:
		return Strings.t("HATCH_FORM_CERTAIN", FormsPresenter.note_name(str(lead[0]["note"])))
	return " · ".join(lead.map(func(f: Dictionary) -> String:
		return Strings.t("HATCH_ODDS", [FormsPresenter.note_name(str(f["note"])), percent(float(f["odds"]))])))


## The time to a Nursery's next birth, by the minute begun.
static func next_in(ms: int) -> String:
	var minutes := maxi(1, ceili(ms / 60000.0))
	if minutes < 60:
		return Strings.t("HATCH_NEXT_MINUTES", minutes)
	return Strings.t("HATCH_NEXT_HOURS", [minutes / 60, minutes % 60])


## One Nursery: its births ready of the three it holds, when the next comes,
## each kind's odds and the form's, and the hatch button at the price.
static func nursery(n: Dictionary, v: Dictionary, cost: int, essence: int, now_ms: int) -> Dictionary:
	var realm := str(n["realm"])
	var title := Strings.t("HATCH_NURSERY", [UniversePresenter.building_name("nursery"),
		RosterPresenter.realm_label(realm, v)])
	var ready := int(n["ready"])
	var next: Variant = n.get("next_at")
	var kinds: Array[String] = []
	for k: Dictionary in n.get("kinds", []):
		if float(k["odds"]) > 0.0:
			kinds.append(Strings.t("HATCH_ODDS", [RosterPresenter.kind_name(str(k["kind"])), percent(float(k["odds"]))]))
	var price := ShopPresenter.grouped(cost)
	var why := ""
	if ready < 1:
		why = Strings.t("HATCH_NONE_READY")
	elif essence < cost:
		why = Strings.t("HATCH_NEEDS", price)
	return {"realm": realm, "title": title, "ready": Strings.t("HATCH_READY", [ready, int(n["holds"])]),
		"next": next_in(int(next) - now_ms) if next != null and ready < int(n["holds"]) else "",
		"kinds": kinds, "forms": forms(n.get("forms", [])),
		"button": {"key": "birth:" + realm, "item": "birth:" + realm, "action": Strings.t("HATCH_BUTTON", price),
			"spoken": Strings.t("HATCH_BUTTON_SPOKEN", [title, price]), "can": why == "", "why": why, "cost": price,
			"args": {"realm": realm}}}


## A heist's stray: its kind, the law it was born under, its three traits,
## its form's odds, and the choice to take it in at a birth's price or let
## it go.
static func stray(s: Dictionary, essence: int) -> Dictionary:
	var id := int(s["id"])
	var kind := RosterPresenter.kind_name(str(s["kind"]))
	var cost := int(s["cost"])
	var price := ShopPresenter.grouped(cost)
	var law: Variant = s.get("law")
	return {"id": id, "title": Strings.t("HATCH_STRAY", kind),
		"born": Strings.t("HATCH_BORN_UNDER", Strings.term("LAW", str(law))) if law is String else "",
		"traits": traits(s.get("traits", [])), "forms": forms(s.get("forms", [])),
		"take": {"key": "stray:%d" % id, "item": "stray:%d" % id, "action": Strings.t("HATCH_TAKE", price),
			"spoken": Strings.t("HATCH_TAKE_SPOKEN", [kind, price]), "can": essence >= cost,
			"why": "" if essence >= cost else Strings.t("HATCH_NEEDS", price), "cost": price, "args": {"stray": id}},
		"decline": {"key": "decline:%d" % id, "item": "decline:%d" % id, "action": Strings.t("HATCH_DECLINE"),
			"spoken": Strings.t("HATCH_DECLINE_SPOKEN", kind), "can": true, "why": "", "args": {"decline": id}}}


static func traits(ids: Array) -> String:
	return Strings.t("HATCH_TRAITS", ", ".join(ids.map(func(t: String) -> String: return Strings.term("TRAIT", t))))


## The ruleborn the last birth or stray brought: its name, form, the traits
## it rolled, the first hatch's outfit, and the name the word lists offer
## (`pick`'s words, or its own). {} when the last change brought none.
static func newborn(last: Variant, v: Dictionary, words: Dictionary, pick: Dictionary) -> Dictionary:
	if not (last is Dictionary) or not ((last as Dictionary).get("what", {}) as Dictionary).has("born"):
		return {}
	var what: Dictionary = (last as Dictionary)["what"]
	var born := int(what["born"])
	var c := {}
	for x: Dictionary in v.get("characters", []):
		if int(x["id"]) == born:
			c = x
	if c.is_empty():
		return {}
	var named := RosterPresenter.names(v.get("characters", []), words)
	var form := str(c.get("form", ""))
	var adjective := int(pick.get("adjective", 0))
	var noun := int(pick.get("noun", 0))
	var offered := SocialPresenter.word_name(words, adjective, noun)
	return {"id": born, "title": Strings.t("HATCH_JOINED" if what["do"] == "stray" else "HATCH_HATCHED", named[born]),
		"form": Strings.t("FORMS_FORM", [FormsPresenter.note_name(form), Strings.t("FORM_QUIRK_" + form.to_upper())])
			if form != "" else "",
		"traits": traits(c.get("traits", [])), "outfit": Strings.t("HATCH_OUTFIT") if what.get("first", false) else "",
		"naming": not words.is_empty(), "name": Strings.t("HATCH_NAME", offered) if offered != "" else "",
		"give": {"key": "name:%d" % born, "item": "name:%d" % born, "action": Strings.t("HATCH_NAME_GIVE"),
			"spoken": Strings.t("HATCH_NAME", offered), "can": offered != "", "why": "",
			"args": {"id": born, "adjective": adjective, "noun": noun}}}


## What the last change came to, when the newborn's card does not say it.
static func said(last: Variant, v: Dictionary, words: Dictionary) -> String:
	if not (last is Dictionary) or (last as Dictionary).is_empty():
		return ""
	var what: Dictionary = (last as Dictionary).get("what", {})
	match str(what.get("do", "")):
		"decline":
			return Strings.t("HATCH_LET_GO")
		"name":
			return Strings.t("HATCH_NAMED", RosterPresenter.names(v.get("characters", []), words).get(int(what["id"]), ""))
	return ""
