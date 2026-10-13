class_name FormsPresenter
extends RefCounted
## The Forms album in words (§11.10, §23.2: "54 forms by kind and note, how
## to hatch each, each form's quirk, the outfit and skiff sail each set
## unlocks, 'Show mine'"): each note's look, quirk, symbol and the launch
## laws that hatch it; each kind's three forms, which the player has, and
## how far its outfit is; each note's skiff sail. What the player has is the
## server's answer; this only says it.


static func screen(slice: Dictionary) -> Dictionary:
	var v: Dictionary = slice.get("view", {})
	var code := str(slice.get("error", ""))
	var mine := bool(slice.get("mine", false))
	var out := {"ready": not v.is_empty(), "busy": str(slice.get("busy", "")), "mine": mine,
		"error": "" if code == "" else Errors.message("FORMS_FAILED", code),
		"toggle": {"action": Strings.t("FORMS_SHOW_ALL" if mine else "FORMS_SHOW_MINE"), "mine": not mine}}
	if v.is_empty():
		return out
	var forms: Array = v.get("forms", [])
	var owned := forms.filter(func(f: Dictionary) -> bool: return int(f["owned"]) > 0).size()
	out["header"] = Strings.t("FORMS_HEADER", [owned, forms.size()])
	var notes: Array[Dictionary] = []
	for n: Dictionary in v.get("notes", []):
		notes.append(note(n))
	out["notes"] = notes
	var outfits := {}
	for o: Dictionary in v.get("outfits", []):
		outfits[o["kind"]] = o
	var kinds: Array[Dictionary] = []
	var by_kind := {}
	for f: Dictionary in forms:
		if mine and int(f["owned"]) == 0:
			continue
		var kind := str(f["kind"])
		if not by_kind.has(kind):
			by_kind[kind] = {"kind": kind, "title": RosterPresenter.kind_name(kind),
				"outfit": outfit(outfits.get(kind, {})), "forms": []}
			kinds.append(by_kind[kind])
		(by_kind[kind]["forms"] as Array).append(form(f))
	out["kinds"] = kinds
	var sails: Array[String] = []
	for s: Dictionary in v.get("sails", []):
		sails.append(sail(s))
	out["sails"] = sails
	return out


static func note_name(n: String) -> String:
	return Strings.term("NOTE", n)


## A note's page: its name and symbol, how its forms look, their quirk, and
## the launch laws that hatch them woven around a Nursery.
static func note(n: Dictionary) -> Dictionary:
	var id := str(n["note"])
	var key := id.to_upper()
	var laws: Array[String] = []
	for law: String in n.get("laws", []):
		laws.append(Strings.term("LAW", law))
	return {"note": id, "title": Strings.t("FORMS_NOTE_TITLE", [note_name(id), Strings.t("NOTE_SYMBOL_" + key)]),
		"look": Strings.t("FORMS_LOOK", Strings.t("FORM_LOOK_" + key)),
		"quirk": Strings.t("FORMS_QUIRK", Strings.t("FORM_QUIRK_" + key)),
		"how": Strings.t("FORMS_HOW", [UniversePresenter.building_name("nursery"), ", ".join(laws)])}


## One form: its note and quirk, and how many the player has.
static func form(f: Dictionary) -> Dictionary:
	var id := str(f["note"])
	var named := Strings.t("FORMS_FORM", [note_name(id), Strings.t("FORM_QUIRK_" + id.to_upper())])
	var n := int(f["owned"])
	return {"note": id, "owned": n,
		"text": Strings.t("FORMS_HAVE", [named, n]) if n > 0 else Strings.t("FORMS_MISSING", named)}


## A kind's outfit: its forms had of three, or unlocked.
static func outfit(o: Dictionary) -> String:
	if o.is_empty():
		return ""
	return Strings.t("FORMS_OUTFIT_DONE", int(o["of"])) if int(o["have"]) >= int(o["of"]) \
		else Strings.t("FORMS_OUTFIT", [int(o["have"]), int(o["of"])])


## A note's skiff sail: the kinds that have it, or unlocked.
static func sail(s: Dictionary) -> String:
	var n := note_name(str(s["note"]))
	return Strings.t("FORMS_SAIL_DONE", n) if int(s["have"]) >= int(s["of"]) \
		else Strings.t("FORMS_SAIL", [n, int(s["have"]), int(s["of"])])
