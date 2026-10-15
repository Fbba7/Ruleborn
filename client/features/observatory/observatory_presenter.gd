class_name ObservatoryPresenter
extends RefCounted
## The Observatory and the scout report in words (§12.3, §12.4, §23.2:
## "Three to six universes showing only the free scouting facts …, the reason
## each was offered …, echoes and generated targets labelled, a Trace pinned
## first and apart from the list, the entry fee"; "12.4's facts realm by
## realm … with nothing placed"). Every fact is the server's card; a card
## carries counts, never a tile, and never the rating that ordered it.


static func screen(slice: Dictionary) -> Dictionary:
	var v: Dictionary = slice.get("view", {})
	var code := str(slice.get("error", ""))
	var out := {"ready": not v.is_empty(), "busy": str(slice.get("busy", "")),
		"error": "" if code == "" else Errors.message("OBS_FAILED", code)}
	if v.is_empty():
		return out
	var aether := int(v.get("aether", 0))
	out["header"] = Strings.t("OBS_HEADER", [ShopPresenter.grouped(aether), int(v.get("size", 3))])
	out["protected"] = Strings.t("OBS_PROTECTED") if v.get("protected", false) else ""
	# §12.3: one more target while the Wanderer is at home (11.7).
	out["wanderer"] = Strings.t("OBS_WANDERER", Strings.t("SAGE_THE_WANDERER")) if v.get("wanderer", false) \
		else ""
	out["fallback"] = Strings.t("OBS_GENERATED_NOTE") if v.get("generated", false) \
		else (Strings.t("OBS_ECHOES_NOTE") if v.get("echoes", false) else "")
	var words: Dictionary = slice.get("words", {})
	out["trace"] = card(v["trace"], words) if v.get("trace") is Dictionary else {}
	var cards: Array[Dictionary] = []
	for c: Dictionary in v.get("targets", []):
		cards.append(card(c, words))
	out["cards"] = cards
	if cards.is_empty():
		out["empty"] = Strings.t("OBS_EMPTY")
	var cost := int((v.get("refresh", {}) as Dictionary).get("aether", 0))
	out["refresh"] = {"key": "refresh", "item": "refresh", "action": Strings.t("OBS_REFRESH", ShopPresenter.grouped(cost)),
		"spoken": Strings.t("OBS_REFRESH", ShopPresenter.grouped(cost)), "can": aether >= cost,
		"why": "" if aether >= cost else Strings.t("CODEX_NEEDS_AETHER", ShopPresenter.grouped(cost))}
	return out


## What a card is: a player's universe, an echo of one, the game's own
## island with its band, or a Trace.
static func title(c: Dictionary) -> String:
	match str(c.get("kind", "player")):
		"trace":
			return Strings.t("OBS_TRACE", int(c.get("keeper_level", 1)))
		"echo":
			return Strings.t("OBS_ECHO", int(c.get("keeper_level", 1)))
		"generated":
			var band: Array = c.get("success", [0.0, 0.0])
			return Strings.t("OBS_GENERATED", [roundi(float(band[0]) * 100.0), roundi(float(band[1]) * 100.0)])
	return Strings.t("OBS_PLAYER", int(c.get("keeper_level", 1)))


static func fee(c: Dictionary) -> String:
	var f := int(c.get("fee", 0))
	return Strings.t("OBS_FEE", ShopPresenter.grouped(f)) if f > 0 else Strings.t("OBS_NO_FEE")


## A target card: the free facts in a few lines, its fee and why it was
## offered, and its button to the scout report.
static func card(c: Dictionary, words := {}) -> Dictionary:
	var r: Dictionary = c.get("realm", {})
	var lines: Array[String] = [
		Strings.t("OBS_FACTS", [int(c.get("realms", 1)), int(c.get("renown", 0)) if c.get("renown") != null else 0,
			ShopPresenter.grouped(int(c.get("loot", 0)))]),
		Strings.t("OBS_STRAIN", [str(roundi(float(c.get("strain", 0.0)) * 100.0)) + "%",
			WeavingPresenter.band_name(int(c.get("band", 0))), int(c.get("faults", 0))]),
		Strings.t("OBS_REALM", [int(r.get("realm_level", 1)), (r.get("laws", []) as Array).size(),
			total(r.get("guards", {})), total(r.get("wards", {}))]),
		fee(c),
	]
	if str(c.get("kind", "")) != "trace":
		lines.append(Strings.t("OBS_REASON_" + str(c.get("reason", "fair")).to_upper()))
	# G58: the Keeper's name, from the word lists, a free fact (§12.4).
	var named: Variant = c.get("keeper_name")
	var name := SocialPresenter.word_name(words, int(named["adjective"]), int(named["noun"])) \
		if named is Dictionary else ""
	if name != "":
		lines.insert(0, Strings.t("OBS_KEEPER_NAME", name))
	var t := title(c)
	return {"bundle": c["bundle"], "kind": c.get("kind", "player"), "title": t, "lines": lines,
		"key": "scout:" + str(c["bundle"]), "item": "scout:" + str(c["bundle"]), "action": Strings.t("OBS_SCOUT"),
		"spoken": Strings.t("OBS_SCOUT_SPOKEN", t), "can": true, "why": "", "card": c}


static func total(counts: Variant) -> int:
	var n := 0
	if counts is Dictionary:
		for k: String in counts:
			n += int(counts[k])
	return n


## Counts by kind, in words: "1 Breaker, 2 Wardens" as "Breaker 1, Warden 2".
static func counted(counts: Dictionary, prefix: String) -> String:
	var parts: Array[String] = []
	var keys := counts.keys()
	keys.sort()
	for k: String in keys:
		parts.append(Strings.t("SCOUT_COUNT", [Strings.term(prefix, k), int(counts[k])]))
	return ", ".join(parts) if not parts.is_empty() else Strings.t("SCOUT_NONE")


## The scout report: the chosen card's facts realm by realm, nothing placed,
## and the button that raids it.
static func scout(slice: Dictionary) -> Dictionary:
	var v: Dictionary = slice.get("view", {})
	var chosen := str(slice.get("chosen", ""))
	var found: Dictionary = {}
	if v.get("trace") is Dictionary and str(v["trace"]["bundle"]) == chosen:
		found = v["trace"]
	for c: Dictionary in v.get("targets", []):
		if str(c["bundle"]) == chosen:
			found = c
	if found.is_empty():
		return {"ready": false}
	var r: Dictionary = found.get("realm", {})
	var watch: Array = r.get("watch", [1.0, 1.0])
	var laws: Array = r.get("laws", [])
	var lines: Array[String] = [
		Strings.t("SCOUT_REALM", [UniversePresenter.realm_name("Heart") if r.get("realm") == "heart"
			else Strings.t("SCOUT_OUTER"), int(r.get("realm_level", 1)), int(r.get("vault_level", 1))]),
		Strings.t("SCOUT_LAWS", ", ".join(laws.map(func(l: String) -> String: return Strings.term("LAW", l))))
			if not laws.is_empty() else Strings.t("SCOUT_NO_LAWS"),
		Strings.t("SCOUT_GUARDS", counted(r.get("guards", {}), "ROLE")),
		Strings.t("SCOUT_WARDS", counted(r.get("wards", {}), "WARD")),
		Strings.t("SCOUT_WATCH", [roundi(float(watch[0]) * 100.0), roundi(float(watch[1]) * 100.0)]),
		Strings.t("SCOUT_HIDDEN"),
	]
	var shown_card := card(found, slice.get("words", {}))
	var raid := {"key": "raid:" + chosen, "item": "raid:" + chosen,
		"action": Strings.t("SCOUT_RAID", fee(found)), "spoken": Strings.t("SCOUT_RAID", fee(found)),
		"can": true, "why": ""}
	return {"ready": true, "title": shown_card["title"], "facts": shown_card["lines"], "lines": lines, "raid": raid,
		"protected": Strings.t("OBS_PROTECTED") if v.get("protected", false) and found.get("kind") == "player" else "",
		"card": found}
