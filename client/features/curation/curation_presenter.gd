class_name CurationPresenter
extends RefCounted
## Curation in words (§13.3, §23.2: "Swap a law, move a post, turn a post,
## pick a different generated layout, name it"): the realm's island and the
## band its origin is judged against; the generator's layouts; each guard
## post with its role and facing, the picked one with the four-way dial and
## its moves; each woven law with what a swap would cost, previewed free and
## applied as a weave (G54); the draft's changes and why it cannot be saved;
## and the name from the word lists. The stealth-path count and the hold
## the server measures are G55's, and one guard's sight drawn hard-edged is
## the world's (§21.12): none of them is here.

## A move a tile along each way, in the dial's order.
const STEPS := [Vector2i(0, -1), Vector2i(1, 0), Vector2i(0, 1), Vector2i(-1, 0)]
const WAYS := ["NORTH", "EAST", "SOUTH", "WEST"]


## The draft as an island, or null when there is none.
static func draft_island(slice: Dictionary) -> RulebornIsland:
	var bytes: PackedByteArray = slice.get("draft", PackedByteArray())
	var island := RulebornIsland.new()
	if bytes.is_empty() or not island.read(bytes):
		return null
	return island


## Every guard post, in reading order: {at, row, facing}.
static func posts(island: RulebornIsland) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for y in island.side():
		for x in island.side():
			var o := str(island.occupant(x, y))
			if o.begins_with("guard:"):
				out.append({"at": Vector2i(x, y), "row": int(o.substr(6)), "facing": island.facing(x, y)})
	return out


## The tile of `law`'s pylon, or NO_POST.
static func pylon(island: RulebornIsland, law: String) -> Vector2i:
	for y in island.side():
		for x in island.side():
			if str(island.occupant(x, y)) == "pylon:" + law:
				return Vector2i(x, y)
	return CurationState.NO_POST


## The post on `from` moved to `to` with its role and facing, onto open
## ground only: a post set on a feature would take the feature away, an
## edit to the terrain.
static func moved(island: RulebornIsland, from: Vector2i, to: Vector2i) -> bool:
	var side := island.side()
	if to.x < 0 or to.y < 0 or to.x >= side or to.y >= side or str(island.occupant(to.x, to.y)) != "":
		return false
	if str(island.ground(to.x, to.y)) not in ["", "plain"]:
		return false
	var o := str(island.occupant(from.x, from.y))
	if not o.begins_with("guard:"):
		return false
	var facing := island.facing(from.x, from.y)
	island.clear(from.x, from.y)
	island.post_guard(int(o.substr(6)), to.x, to.y)
	return face(island, to, facing)


## What faces on `at` turned to `facing`, 0 north to 3 west.
static func face(island: RulebornIsland, at: Vector2i, facing: int) -> bool:
	for i in STEPS.size():
		if island.facing(at.x, at.y) == facing:
			return true
		island.turn(at.x, at.y)
	return island.facing(at.x, at.y) == facing


## `law` on the pylon `old` stands on, in its place.
static func swapped(island: RulebornIsland, old: String, law: String) -> bool:
	var at := pylon(island, old)
	if at == CurationState.NO_POST:
		return false
	island.clear(at.x, at.y)
	return island.weave(law, at.x, at.y)


## The law woven in slot `slot`, as the view's swaps name it.
static func slot_law(view: Dictionary, slot: int) -> String:
	for s: Dictionary in view.get("swaps", []):
		if int(s["slot"]) == slot:
			return str(s["law"])
	return ""


static func said(what: String) -> String:
	return Strings.t("CUR_SAID_" + what.to_upper()) if what != "" else ""


static func screen(slice: Dictionary) -> Dictionary:
	var v: Dictionary = slice.get("view", {})
	var busy := str(slice.get("busy", ""))
	var out := {"ready": not v.is_empty() and busy not in ["view", "island"],
		"busy": busy, "said": said(str(slice.get("said", ""))),
		"error": Errors.message("CUR_FAILED", str(slice["error"])) if str(slice.get("error", "")) != "" else ""}
	if not out["ready"]:
		return out
	out["header"] = Strings.t("CUR_HEADER", [UniversePresenter.realm_name(str(v.get("type", "Heart"))),
		int(v.get("level", 1))])
	out["origin"] = origin(v)
	out["name"] = Strings.t("CUR_NAMED", SocialPresenter.word_name(slice.get("words", {}),
		int(v["name"]["adjective"]), int(v["name"]["noun"]))) if v.get("name") is Dictionary \
		else Strings.t("CUR_UNNAMED")
	out["layouts"] = layouts(v, busy)
	var island := draft_island(slice)
	out["posts"] = [] as Array[Dictionary]
	out["dial"] = [] as Array[Dictionary]
	if island != null:
		_posts(out, island, slice["post"], busy)
	out["laws"] = laws(v, slice.get("swap", {}), busy)
	out["changes"] = changes(slice, island, busy)
	out["naming"] = naming(slice, v, busy)
	return out


## The island's origin and the band it is judged against (§12.22, §13.3).
static func origin(v: Dictionary) -> String:
	match v.get("origin"):
		"generated":
			return Strings.t("CUR_GENERATED")
		"authored":
			return Strings.t("CUR_AUTHORED")
	return Strings.t("CUR_NONE")


## The generator's layouts on this page, and the next page.
static func layouts(v: Dictionary, busy: String) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	var seeds: Array = v.get("layouts", [])
	var page := int(v.get("page", 0))
	var why := Strings.t("CUR_REPLACES") if v.get("island") is String else ""
	for i in seeds.size():
		var n := page * seeds.size() + i + 1
		out.append({"key": "layout:%d" % n, "item": "layout:%d" % n, "seed": str(seeds[i]),
			"action": Strings.t("CUR_LAYOUT", n), "spoken": Strings.t("CUR_LAYOUT_SPOKEN", n),
			"can": busy == "", "why": why if i == 0 else ""})
	out.append({"key": "more", "item": "more", "seed": "", "action": Strings.t("CUR_MORE"),
		"spoken": Strings.t("CUR_MORE"), "can": busy == "", "why": ""})
	return out


## Each post with its role, tile and facing; for the picked one, the dial
## that turns it and the moves a tile each way.
static func _posts(out: Dictionary, island: RulebornIsland, picked: Vector2i, busy: String) -> void:
	var list: Array[Dictionary] = out["posts"]
	var all := posts(island)
	for i in all.size():
		var p: Dictionary = all[i]
		var at: Vector2i = p["at"]
		var role := Strings.term("ROLE", BuilderScreen.GUARD_ROLES[int(p["row"]) % BuilderScreen.GUARD_ROLES.size()])
		var text := Strings.t("CUR_POST", [i + 1, role, at.x + 1, at.y + 1,
			Strings.t("CUR_FACE_" + WAYS[int(p["facing"]) % 4])])
		list.append({"key": "post:%d" % i, "item": "post:%d" % i, "at": at, "action": text,
			"spoken": text, "picked": at == picked, "can": busy == "", "why": ""})
	if picked == CurationState.NO_POST or not all.any(func(p: Dictionary) -> bool: return p["at"] == picked):
		return
	var dial: Array[Dictionary] = out["dial"]
	var facing := island.facing(picked.x, picked.y)
	for k in WAYS.size():
		var way := Strings.t("CUR_FACE_" + WAYS[k])
		dial.append({"key": "face:%d" % k, "item": "face:%d" % k, "facing": k,
			"action": Strings.t("CUR_TURN", way), "spoken": Strings.t("CUR_TURN_SPOKEN", way),
			"can": busy == "" and facing != k, "why": ""})
	for k in WAYS.size():
		var way := Strings.t("CUR_FACE_" + WAYS[k])
		var to: Vector2i = picked + STEPS[k]
		var probe := RulebornIsland.new()
		probe.read(island.bytes())
		var free := moved(probe, picked, to)
		dial.append({"key": "move:%d" % k, "item": "move:%d" % k, "step": STEPS[k],
			"action": Strings.t("CUR_MOVE", way), "spoken": Strings.t("CUR_MOVE_SPOKEN", way),
			"can": busy == "" and free, "why": ""})


## Each woven law with a preview of each swap, free, and the previewed one
## with its price and time on the button that weaves it (G54, §5.6).
static func laws(v: Dictionary, swap: Dictionary, busy: String) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	var aether := int(v.get("aether", 0))
	for s: Dictionary in v.get("swaps", []):
		var slot := int(s["slot"])
		var law := Strings.term("LAW", str(s["law"]))
		var offers: Array[Dictionary] = []
		var row := {"slot": slot, "text": Strings.t("CUR_SLOT", [slot, law]), "offers": offers, "apply": {}}
		for o: Dictionary in s.get("offers", []):
			var other := Strings.term("LAW", str(o["law"]))
			var previewed: bool = int(swap.get("slot", 0)) == slot and str(swap.get("law", "")) == str(o["law"])
			var why := Errors.message("CUR_REFUSED", str(o["refused"])) if o.get("refused") is String else ""
			offers.append({"key": "swap:%d:%s" % [slot, o["law"]],
				"item": "swap:%d:%s" % [slot, o["law"]], "law": str(o["law"]),
				"action": Strings.t("CUR_PREVIEW", other), "spoken": Strings.t("CUR_PREVIEW_SPOKEN", [other, law]),
				"can": busy == "" and why == "" and not previewed, "why": why})
			if previewed:
				var price := int(o.get("price", 0))
				var time := WeavingPresenter.duration(int(o.get("minutes", 0)))
				var short := Strings.t("CODEX_NEEDS_AETHER", ShopPresenter.grouped(price)) if aether < price else ""
				row["preview"] = Strings.t("CUR_PREVIEWING", [other, law])
				row["apply"] = {"key": "apply", "item": "apply",
					"action": Strings.t("CUR_APPLY", [ShopPresenter.grouped(price), time]),
					"spoken": Strings.t("CUR_APPLY_SPOKEN", [other, law, ShopPresenter.grouped(price), time]),
					"can": busy == "" and short == "", "why": short,
					"cost": Strings.t("LAB_COST", ShopPresenter.grouped(price)) if price > 0 else ""}
		out.append(row)
	return out


## The draft against the published island: unsaved or not, why it cannot be
## saved, and the save and revert buttons.
static func changes(slice: Dictionary, island: RulebornIsland, busy: String) -> Dictionary:
	var draft: PackedByteArray = slice.get("draft", PackedByteArray())
	if island == null or draft == slice.get("base", PackedByteArray()):
		return {}
	var problems := Array(island.problems())
	var why := ""
	if not problems.is_empty():
		why = Strings.t("BUILDER_BLOCKED", ", ".join(problems.map(func(p: Variant) -> String:
			return Strings.t("PROBLEM_" + str(p).to_upper()))))
	return {"line": Strings.t("CUR_UNSAVED"),
		"save": {"key": "save", "item": "save", "action": Strings.t("CUR_SAVE"), "spoken": Strings.t("CUR_SAVE"),
			"can": busy == "" and why == "", "why": why},
		"revert": {"key": "revert", "item": "revert", "action": Strings.t("CUR_REVERT"),
			"spoken": Strings.t("CUR_REVERT"), "can": busy == "", "why": ""}}


## The name being picked from the word lists, a word at a time, and the
## button that gives it; none until there is an island to name.
static func naming(slice: Dictionary, v: Dictionary, busy: String) -> Dictionary:
	var words: Dictionary = slice.get("words", {})
	if not (v.get("island") is String) or words.is_empty():
		return {}
	var pick: Dictionary = slice.get("pick", {"adjective": 0, "noun": 0})
	var name := SocialPresenter.word_name(words, int(pick["adjective"]), int(pick["noun"]))
	return {"name": name,
		"give": {"key": "name", "item": "name", "action": Strings.t("CUR_NAME_IT", name),
			"spoken": Strings.t("CUR_NAME_IT", name), "can": busy == "", "why": ""}}
