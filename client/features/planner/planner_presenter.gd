class_name PlannerPresenter
extends RefCounted
## The heist planner in words (§23.2: "Entry (any edge tile, or a fault),
## route, crew of 3 to 5 with resting characters unavailable, Sage, casts,
## the load target (12.5), clock, unfamiliar laws flagged"). §12.5's limits
## at the Keeper's level are the server's (GET /v1/keeper's plan); each
## crew member's manifest fields are the home's; the target's laws and clock
## are its card's. While the player is protected, Start says what raiding a
## player ends (§12.3).

const PIP_ON := "●"


## §12.5's limits as the server sent them, or level 1's until it has.
static func limits(keeper: Dictionary) -> Dictionary:
	var given: Variant = (keeper.get("view", {}) as Dictionary).get("plan")
	return given if given is Dictionary else {"crew": 3, "casts": 1, "sage": false, "load": [50, 100, 10]}


static func screen(planner: Dictionary, keeper: Dictionary, roster: Dictionary, sages: Dictionary,
		codex: Dictionary, observatory: Dictionary) -> Dictionary:
	var card: Dictionary = planner.get("target", {})
	var characters: Array = (roster.get("view", {}) as Dictionary).get("characters", [])
	var out := {"ready": not card.is_empty() and not (roster.get("view", {}) as Dictionary).is_empty()}
	if not out["ready"]:
		return out
	var lim := limits(keeper)
	var most := int(lim["crew"])
	out["title"] = ObservatoryPresenter.title(card)
	out["clock"] = LandingPresenter.clock(int(card.get("clock", 150)))
	out["entry"] = Strings.t("PLAN_ENTRY")
	out["route"] = ""
	out["faults"] = ""
	# §23.2's "Entry (any edge tile, or a fault), route": across a universe,
	# any outer realm's edge or a fault, realm by realm to the Heart, on the
	# clock of the realm landed in (§5.4).
	if card.get("across", false):
		var mmss := func(s: int) -> String: return "%d:%02d" % [s / 60, s % 60]
		out["entry"] = Strings.t("PLAN_ENTRY_ACROSS")
		out["route"] = Strings.t("PLAN_ROUTE", maxi(1, int(card.get("depth", 1))))
		out["clock"] = Strings.t("PLAN_CLOCK_RANGE", [mmss.call(int(card.get("clock", 150))),
			mmss.call(int(card.get("clock_longest", card.get("clock", 150))))])
		var at := PackedStringArray()
		for realm: String in card.get("fault_realms", []):
			at.append(Strings.t("OBS_OUTER_REALM", int(realm.get_slice("-", 1))))
		if not at.is_empty():
			out["faults"] = Strings.t("OBS_FAULTS_FROM", ", ".join(at))
	out["laws"] = laws(card, codex)
	# The crew: every character, the resting ones unavailable.
	var chosen: Array = planner.get("crew", [])
	var crew: Array[Dictionary] = []
	var named := RosterPresenter.names(characters)
	for c: Dictionary in characters:
		var id := int(c["id"])
		var resting := str(c.get("state", "")) == "resting"
		var picked := id in chosen
		var name := str(named[id])
		var why := ""
		if resting:
			why = Strings.t("PLAN_RESTING")
		elif not picked and chosen.size() >= most:
			why = Strings.t("PLAN_CREW_FULL", most)
		var words := Strings.t("PLAN_MEMBER_IN" if picked else "PLAN_MEMBER", [name, int(c.get("level", 1))])
		crew.append({"id": id, "key": "crew:%d" % id, "item": "crew:%d" % id, "action": words,
			"spoken": words, "can": why == "", "why": why, "picked": picked, "resting": resting})
	out["crew"] = crew
	out["crew_count"] = Strings.t("PLAN_CREW", [chosen.size(), most])
	out["sages"] = sage_options(planner, lim, sages)
	out["casts"] = cast_options(planner, lim, codex)
	out["casts_count"] = Strings.t("PLAN_CASTS", [(planner.get("casts", []) as Array).size(), int(lim["casts"])])
	var filled := int(planner.get("load", 100))
	var steps: Array = lim["load"]
	out["load"] = Strings.t("PLAN_LOAD", filled)
	out["load_down"] = filled > int(steps[0])
	out["load_up"] = filled < int(steps[1])
	out["protected"] = Strings.t("OBS_PROTECTED") if (observatory.get("view", {}) as Dictionary).get("protected", false) \
		and card.get("kind") == "player" else ""
	var why := ""
	if chosen.size() < 3 or chosen.size() > most or crew.any(func(c: Dictionary) -> bool:
			return c["picked"] and c["resting"]):
		why = Strings.t("PLAN_NEEDS_CREW", [3, most])
	out["start"] = {"key": "start", "item": "start", "action": Strings.t("PLAN_START"),
		"spoken": Strings.t("PLAN_START_SPOKEN", out["title"]), "can": why == "", "why": why}
	out["plan"] = plan(planner, characters, sages)
	return out


## The target's laws, each one the Codex has not met flagged (§23.2).
static func laws(card: Dictionary, codex: Dictionary) -> Dictionary:
	var met := {}
	var v: Dictionary = codex.get("view", {})
	for l: Dictionary in v.get("laws", []):
		met[str(l["law"])] = true
	for a: Dictionary in v.get("albums", []):
		for l: Dictionary in a.get("laws", []):
			if l.get("known", false):
				met[str(l["law"])] = true
	var all: Array = (card.get("realm", {}) as Dictionary).get("laws", [])
	var unfamiliar := all.filter(func(l: String) -> bool: return not met.has(l))
	var line := Strings.t("SCOUT_LAWS", HarmonyPresenter.laws(all)) if not all.is_empty() \
		else Strings.t("SCOUT_NO_LAWS")
	return {"line": line,
		"unfamiliar": Strings.t("PLAN_UNFAMILIAR", HarmonyPresenter.laws(unfamiliar)) if not unfamiliar.is_empty() else "",
		"ids": unfamiliar}


## §12.5's Sage: none, or one unlocked and not the Heart's guardian, from
## Keeper level 2.
static func sage_options(planner: Dictionary, lim: Dictionary, sages: Dictionary) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	var picked := str(planner.get("sage", ""))
	var none := Strings.t("PLAN_NO_SAGE")
	out.append({"id": "", "key": "sage:", "item": "sage:", "action": (PIP_ON + " " if picked == "" else "") + none,
		"spoken": none, "can": true, "why": ""})
	for s: Dictionary in (sages.get("view", {}) as Dictionary).get("sages", []):
		var id := str(s["id"])
		var why := ""
		if not lim.get("sage", false):
			why = Strings.t("PLAN_SAGE_LEVEL")
		elif not s.get("unlocked", false):
			why = Strings.t("SAGE_UNLOCKS", int(s.get("unlocks_at", 1)))
		elif s.get("guardian", false):
			why = Strings.t("PLAN_SAGE_GUARDING")
		var name := Strings.term("SAGE", id)
		out.append({"id": id, "key": "sage:" + id, "item": "sage:" + id,
			"action": (PIP_ON + " " if picked == id else "") + name, "spoken": name, "can": why == "", "why": why})
	return out


## §12.5's casts: restored laws, as many as the Keeper's slots.
static func cast_options(planner: Dictionary, lim: Dictionary, codex: Dictionary) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	var carried: Array = planner.get("casts", [])
	for l: Dictionary in (codex.get("view", {}) as Dictionary).get("laws", []):
		if int(l.get("tier", 0)) < 1:
			continue
		var law := str(l["law"])
		var on := law in carried
		var why := ""
		if not on and carried.size() >= int(lim["casts"]):
			why = Strings.t("PLAN_CASTS_FULL", int(lim["casts"]))
		var words := Strings.t("PLAN_CAST_IN" if on else "PLAN_CAST", Strings.term("LAW", law))
		out.append({"law": law, "key": "cast:" + law, "item": "cast:" + law, "action": words, "spoken": words,
			"can": why == "", "why": why})
	return out


## The plan as the heist takes it: the crew's ids in portrait order, the
## manifest the replay carries (§12.5: each member's kind, form, level and
## traits, then the Sage and the casts, as replay.rs writes them), and the
## load target.
static func plan(planner: Dictionary, characters: Array, sages: Dictionary) -> Dictionary:
	var ids: Array = planner.get("crew", [])
	var bytes := PackedByteArray()
	for id: Variant in ids:
		for c: Dictionary in characters:
			if int(c["id"]) == int(id):
				var w: Dictionary = c.get("wire", {})
				var traits: Array = w.get("traits", [])
				bytes.append_array(PackedByteArray([int(w.get("kind", 0)), int(w.get("form", 0)), int(w.get("level", 1)),
					traits.size()]))
				for t: Variant in traits:
					bytes.append(int(t))
	var order: Array = ((sages.get("view", {}) as Dictionary).get("sages", []) as Array).map(
		func(s: Dictionary) -> String: return str(s["id"]))
	var sage := str(planner.get("sage", ""))
	bytes.append(order.find(sage) + 1 if sage != "" else 0)
	var casts: Array = planner.get("casts", [])
	var law_ids := RulebornStability.law_ids()
	bytes.append(casts.size())
	for law: Variant in casts:
		bytes.append(law_ids.find(str(law)))
	return {"crew": ids.map(func(i: Variant) -> int: return int(i)), "manifest": bytes,
		"load": int(planner.get("load", 100))}
