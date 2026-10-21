class_name OverlayFacts
extends RefCounted
## A target's free facts (§12.4) as the design shows them: pills of icons and
## counts, never sentences. Each pill says the presenter's own sentence to a
## screen reader, so what is heard is what the words said before. The
## Observatory, the scout report and the planner share these.

## §5.5's bands, in order, as the kit's icons name them.
const BANDS := ["quiet", "steady", "humming", "brimming", "strained", "cracking", "breaking"]


## A universe's size, Renown, loot, strain and faults (`card`, the server's
## card), each as a pill; `spoken` is the presenter's lines for them.
static func universe(card: Dictionary, spoken: Array, with_loot := true) -> Array[Control]:
	var said: String = spoken[0] if not spoken.is_empty() else ""
	var out: Array[Control] = [OverlayHud.pill("screens/universe", str(int(card.get("realms", 1))), said)]
	if with_loot:
		out.append(OverlayHud.pill("heiststatus/lootbag", "~" + ShopPresenter.grouped(int(card.get("loot", 0))), said))
	if card.get("renown") != null:
		out.append(OverlayHud.pill("resources/renown", ShopPresenter.grouped(int(card["renown"])), said))
	var band := clampi(int(card.get("band", 0)), 0, BANDS.size() - 1)
	var strain := Strings.t("OBS_STRAIN", [str(roundi(float(card.get("strain", 0.0)) * 100.0)) + "%",
		WeavingPresenter.band_name(band), int(card.get("faults", 0))])
	out.append(OverlayHud.pill("stabilitybands/" + BANDS[band],
		"%d%%" % roundi(float(card.get("strain", 0.0)) * 100.0), strain))
	if int(card.get("faults", 0)) > 0:
		out.append(OverlayHud.pill("stabilitybands/fault", str(int(card["faults"])), strain))
	return out


## A realm's laws as pills: each law's mark and name.
static func laws(realm: Dictionary) -> Array[Control]:
	var out: Array[Control] = []
	for l: String in realm.get("laws", []):
		out.append(OverlayHud.pill(OverlayHud.law_icon(l), Strings.term("LAW", l), Strings.term("LAW", l)))
	return out


## A realm's guards by role and wards by kind, as counted pills, and its
## watch.
static func defence(realm: Dictionary) -> Array[Control]:
	var out: Array[Control] = []
	var guards: Dictionary = realm.get("guards", {})
	for role: String in _sorted(guards):
		out.append(OverlayHud.pill("crewroles/" + role.to_lower(), "×%d" % int(guards[role]),
			Strings.t("SCOUT_COUNT", [Strings.term("ROLE", role), int(guards[role])])))
	var wards: Dictionary = realm.get("wards", {})
	for kind: String in _sorted(wards):
		out.append(OverlayHud.pill(OverlayHud.ward_icon(kind), "×%d" % int(wards[kind]),
			Strings.t("SCOUT_COUNT", [Strings.term("WARD", kind), int(wards[kind])])))
	var watch: Array = realm.get("watch", [1.0, 1.0])
	var a := roundi(float(watch[0]) * 100.0)
	var b := roundi(float(watch[1]) * 100.0)
	out.append(OverlayHud.pill("heiststatus/visioncone", "%d%%" % a if a == b else "%d–%d%%" % [a, b],
		Strings.t("SCOUT_WATCH", [a, b])))
	return out


## The entry fee as a Starlight pill, or "free".
static func fee(card: Dictionary) -> Control:
	var f := int(card.get("fee", 0))
	return OverlayHud.pill("resources/starlight", ShopPresenter.grouped(f) if f > 0 else "0",
		ObservatoryPresenter.fee(card))


static func _sorted(d: Dictionary) -> Array:
	var keys := d.keys()
	keys.sort()
	return keys
