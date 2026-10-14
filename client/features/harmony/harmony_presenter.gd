class_name HarmonyPresenter
extends RefCounted
## The Harmony view in words (§23.2: "Notes on every law, harmonies and
## clashes in each realm, discovered resonances and chords, and an unnamed
## line for an undiscovered one that sounds"). Each line names its laws and
## what it does to their cost (§5.5), from the server's factors; a resonance
## or chord the server sends no name for is unnamed (§8.6).


static func screen(slice: Dictionary) -> Dictionary:
	var v: Dictionary = slice.get("view", {})
	var code := str(slice.get("error", ""))
	var out := {"ready": not v.is_empty(), "busy": bool(slice.get("busy", false)),
		"error": "" if code == "" else Errors.message("HARMONY_FAILED", code)}
	if v.is_empty():
		return out
	var st: Dictionary = v.get("stability", {})
	out["header"] = Strings.t("HARMONY_STRAIN", [str(roundi(float(st.get("strain", 0.0)) * 100.0)) + "%",
		WeavingPresenter.band_name(int(st.get("band", 0)))])
	var realms: Array[Dictionary] = []
	for r: Dictionary in v.get("realms", []):
		realms.append(realm(r))
	out["realms"] = realms
	return out


## A factor as the percentage it takes off or puts on: 0.85 is 15, 1.25 is 25.
static func percent(factor: float) -> int:
	return absi(roundi((1.0 - factor) * 100.0))


static func laws(ids: Array) -> String:
	return ", ".join(ids.map(func(l: String) -> String: return Strings.term("LAW", l)))


static func notes(names: Array) -> String:
	return ", ".join(names.map(func(n: String) -> String: return Strings.term("NOTE", n)))


## One realm: each law with its notes, then every combination its laws make.
static func realm(r: Dictionary) -> Dictionary:
	var law_lines: Array[String] = []
	for l: Dictionary in r.get("laws", []):
		law_lines.append(Strings.t("HARMONY_LAW_CROWNED" if l.get("crowned", false) else "HARMONY_LAW",
			[Strings.term("LAW", str(l["law"])), notes(l.get("notes", []))]))
	var lines: Array[String] = []
	for h: Dictionary in r.get("harmonies", []):
		lines.append(Strings.t("HARMONY_HARMONY", [Strings.term("NOTE", str(h["note"])), laws(h["laws"]),
			percent(float(h["factor"]))]))
	for c: Dictionary in r.get("clashes", []):
		var pair: Array = c["notes"]
		lines.append(Strings.t("HARMONY_CLASH", [Strings.term("NOTE", str(pair[0])), Strings.term("NOTE", str(pair[1])),
			laws(c["laws"]), percent(float(c["factor"]))]))
	for x: Dictionary in r.get("resonances", []):
		var n := percent(float(x["factor"]))
		lines.append(Strings.t("HARMONY_RESONANCE", [str(x["name"]), laws(x["laws"]), n]) if x.get("name") is String
			else Strings.t("HARMONY_RESONANCE_UNNAMED", [laws(x["laws"]), n]))
	for c: Dictionary in r.get("chords", []):
		var n := percent(float(c["factor"]))
		lines.append(Strings.t("HARMONY_CHORD", [str(c["name"]), notes(c["notes"]), laws(c["laws"]), n])
			if c.get("name") is String
			else Strings.t("HARMONY_CHORD_UNNAMED", [notes(c["notes"]), laws(c["laws"]), n]))
	if law_lines.is_empty():
		law_lines.append(Strings.t("HARMONY_EMPTY"))
	elif lines.is_empty():
		lines.append(Strings.t("HARMONY_NONE"))
	return {"realm": r["realm"], "title": UniversePresenter.realm_name(str(r.get("type", ""))), "laws": law_lines,
		"lines": lines}
