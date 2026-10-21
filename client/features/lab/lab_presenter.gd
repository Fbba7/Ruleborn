class_name LabPresenter
extends RefCounted
## The Resonance Lab in words (§23.2: "One chamber per Lab slot (10.2), each
## with two law slots for restored laws, its price on the button and its time
## after the Archivist's cut, the result, the hint after three empty
## experiments with one law (8.6), the third sphere's chord naming from Lab
## level 3 (8.5), paradox warning"). §8.5's third sphere names, once a day
## and free, a chord the player has woven or crossed. Every price, time and
## result is the server's; a resonance or chord is named by its content name.


static func screen(slice: Dictionary, now_ms: int) -> Dictionary:
	var v: Dictionary = slice.get("view", {})
	var code := str(slice.get("error", ""))
	var out := {"ready": not v.is_empty(), "busy": str(slice.get("busy", "")),
		"error": "" if code == "" else Errors.message("LAB_FAILED", code),
		"said": said(str(slice.get("said", "")))}
	if v.is_empty():
		return out
	var aether := int(v.get("aether", 0))
	out["header"] = Strings.t("LAB_HEADER", [int(v.get("level", 0)), ShopPresenter.grouped(aether)])
	var terms: Variant = v.get("terms")
	if not (terms is Dictionary):
		out["none"] = Strings.t("LAB_NONE")
		out["chambers"] = [] as Array[Dictionary]
		out["found"] = found(v)
		return out
	var t: Dictionary = terms
	var time := WeavingPresenter.duration(int(t.get("minutes", 0)))
	var cost := int(t.get("aether", 0))
	out["terms"] = Strings.t("LAB_TERMS_FIRST", time) if t.get("first", false) \
		else Strings.t("LAB_TERMS", [ShopPresenter.grouped(cost), time])
	out["sphere"] = sphere(v.get("sphere"))
	out["chords"] = Strings.t("LAB_CHORDS") if (out["sphere"] as Dictionary).is_empty() else ""
	var chambers: Array[Dictionary] = []
	for c: Dictionary in v.get("chambers", []):
		chambers.append(chamber(c, slice, t, aether, now_ms))
	out["chambers"] = chambers
	out["found"] = found(v)
	out["level"] = int(v.get("level", 0))
	out["aether"] = ShopPresenter.grouped(aether)
	out["finds"] = (v.get("found", []) as Array).map(func(f: Dictionary) -> Dictionary:
		return {"kind": str(f["kind"]), "id": str(f["id"]), "name": Strings.term("CHORD" if f["kind"] == "chord"
			else "RES", str(f["id"]))})
	out["hinted"] = (v.get("hinted", []) as Array).size()
	out["remaining"] = v.get("remaining", {})
	return out


static func said(what: String) -> String:
	if what == "started":
		return Strings.t("LAB_STARTED")
	if what.begins_with("named:"):
		return Strings.t("LAB_NAMED", Strings.term("CHORD", what.trim_prefix("named:")))
	return ""


## §8.5's third sphere: its button, free, waiting with why when it named one
## today or no chord woven or crossed is left; none below Lab level 3.
static func sphere(s: Variant) -> Dictionary:
	if not (s is Dictionary):
		return {}
	var why := ""
	if (s as Dictionary).get("today", false):
		why = Strings.t("LAB_SPHERE_TODAY")
	elif not (s as Dictionary).get("can", false):
		why = Strings.t("LAB_SPHERE_NONE")
	return {"key": "sphere", "item": "sphere", "action": Strings.t("LAB_SPHERE"),
		"spoken": Strings.t("LAB_SPHERE_SPOKEN"), "can": why == "", "why": why}


## The laws in chamber `n`'s spheres: those placed, or the first restored.
static func picks(slice: Dictionary, n: int) -> Array:
	var placed: Variant = (slice.get("picks", {}) as Dictionary).get(str(n))
	if placed is Array:
		return (placed as Array).duplicate()
	var restored: Array = (slice.get("view", {}) as Dictionary).get("restored", [])
	return restored.slice(0, 2)


## Sphere `slot`'s law moved `step` along the restored laws, past any that
## another sphere holds; the rest unchanged.
static func cycled(restored: Array, laws: Array, slot: int, step: int) -> Array:
	var out := laws.duplicate()
	if restored.is_empty() or slot < 0 or slot >= out.size():
		return out
	var at := restored.find(out[slot])
	for i in restored.size():
		at = posmod(at + step, restored.size())
		var law: String = restored[at]
		if law == out[slot] or law not in out:
			out[slot] = law
			return out
	return out


static func names(laws: Array) -> String:
	return HarmonyPresenter.laws(laws)


## One chamber: running with its time left, or idle with its spheres and the
## button that runs it; and its last result.
static func chamber(c: Dictionary, slice: Dictionary, t: Dictionary, aether: int, now_ms: int) -> Dictionary:
	var n := int(c.get("chamber", 1))
	var out := {"chamber": n, "title": Strings.t("LAB_CHAMBER", n), "lines": [] as Array[String],
		"slots": [] as Array[Dictionary], "run": {}}
	var lines: Array[String] = out["lines"]
	var running: Variant = c.get("running")
	if running is Dictionary:
		var r: Dictionary = running
		out["running"] = r.get("laws", [])
		out["left"] = WeavingPresenter.duration(WeavingPresenter.minutes_until(int(r.get("ready_at", 0)), now_ms))
		out["unstable"] = bool(r.get("unstable", false))
		lines.append(Strings.t("LAB_RUNNING", [names(r.get("laws", [])),
			WeavingPresenter.duration(WeavingPresenter.minutes_until(int(r.get("ready_at", 0)), now_ms))]))
		if r.get("unstable", false):
			lines.append(Strings.t("LAB_UNSTABLE"))
	if c.get("result") is Dictionary:
		lines.append_array(result(c["result"]))
		var got: Variant = (c["result"] as Dictionary).get("found")
		out["found"] = str(got) if got is String else ""
	if running is Dictionary:
		return out
	var laws := picks(slice, n)
	var slots: Array[Dictionary] = out["slots"]
	for i in laws.size():
		var law := Strings.term("LAW", str(laws[i]))
		slots.append({"slot": i, "law": str(laws[i]), "name": law, "text": Strings.t("LAB_SLOT", [i + 1, law]),
			"spoken": Strings.t("LAB_SLOT_SPOKEN", [i + 1, n, law]), "key": "slot:%d:%d" % [n, i]})
	var cost := int(t.get("aether", 0))
	var time := WeavingPresenter.duration(int(t.get("minutes", 0)))
	var action := Strings.t("LAB_RUN_FREE", time) if cost == 0 \
		else Strings.t("LAB_RUN", [ShopPresenter.grouped(cost), time])
	var why := ""
	if laws.size() < 2:
		why = Strings.t("LAB_NEEDS_LAWS")
	elif aether < cost:
		why = Strings.t("CODEX_NEEDS_AETHER", ShopPresenter.grouped(cost))
	out["run"] = {"key": "run:%d" % n, "item": "run:%d" % n, "action": action,
		"spoken": Strings.t("LAB_RUN_SPOKEN", [n, names(laws), action]), "can": why == "", "why": why,
		"cost": Strings.t("LAB_COST", ShopPresenter.grouped(cost)) if cost > 0 else ""}
	return out


## A finished experiment's result: what it found, or nothing, its pages, and
## any hint (§7.6, §8.6).
static func result(r: Dictionary) -> Array[String]:
	var lines: Array[String] = []
	var laws := names(r.get("laws", []))
	match str(r.get("found", "")):
		"resonance":
			lines.append(Strings.t("LAB_FOUND_RESONANCE", [Strings.term("RES", str(r["id"])), laws]))
		"chord":
			lines.append(Strings.t("LAB_FOUND_CHORD", [Strings.term("CHORD", str(r["id"])), laws]))
		_:
			lines.append(Strings.t("LAB_EMPTY", laws))
	var pages: Variant = r.get("pages")
	if pages is Dictionary:
		lines.append(Strings.t("LAB_PAGES", [int(pages["n"]), Strings.term("LAW", str(pages["law"]))]))
	var hint: Variant = r.get("hint")
	if hint is Dictionary:
		lines.append(Strings.t("LAB_HINT", [Strings.term("LAW", str(hint["law"])),
			Strings.t("SCHOOL_" + str(hint["school"]).to_upper())]))
	return lines


## What the Lab has found, by name; how many are hinted; and how many of
## launch's signature resonances remain in each school (§8.6).
static func found(v: Dictionary) -> Array[String]:
	var lines: Array[String] = []
	for f: Dictionary in v.get("found", []):
		var kind := str(f["kind"])
		lines.append(Strings.t("LAB_FOUND_CHORD_LINE", Strings.term("CHORD", str(f["id"]))) if kind == "chord"
			else Strings.t("LAB_FOUND_RES_LINE", Strings.term("RES", str(f["id"]))))
	if lines.is_empty():
		lines.append(Strings.t("LAB_FOUND_NONE"))
	var hinted := (v.get("hinted", []) as Array).size()
	if hinted > 0:
		lines.append(Strings.t("LAB_HINTED", hinted))
	var remaining: Dictionary = v.get("remaining", {})
	var parts: Array[String] = []
	for school: String in remaining:
		parts.append(Strings.t("LAB_REMAINING_SCHOOL", [Strings.t("SCHOOL_" + school.to_upper()),
			int(remaining[school])]))
	if not parts.is_empty():
		lines.append(Strings.t("LAB_REMAINING", ", ".join(parts)))
	return lines
