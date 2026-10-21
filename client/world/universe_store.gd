class_name UniverseStore
extends RefCounted
## What the universe map reads from the store, gathered from the slices that
## hold it, so every screen that shows the map shows the same thing: the
## server's universe (`UniverseState`), and from the others what each
## producer has ready (the home, `RosterState`), the raids not yet seen
## (`DefencesState`) and the strain band (`WeavingState`). Nothing is worked
## out here that a slice does not already say.

## The slices whose change the map redraws for.
const SLICES := [UniverseState.UNIVERSE, RosterState.ROSTER, DefencesState.DEFENCES, WeavingState.WEAVING]
## What each producer makes (§9.3).
const PRODUCES := {"star_well": "starlight", "aether_spring": "aether", "garden": "essence"}


static func view(store: Store) -> Dictionary:
	return store.get_slice(UniverseState.UNIVERSE).get("view", {})


static func extras(store: Store) -> Dictionary:
	var home: Dictionary = store.get_slice(RosterState.ROSTER).get("view", {})
	var weaving: Dictionary = store.get_slice(WeavingState.WEAVING).get("view", {})
	var stability: Dictionary = weaving.get("stability", {})
	var out := {"producers": home.get("producers", []), "characters": home.get("characters", []),
		"band": int(stability.get("band", 0)),
		"raids": int(store.get_slice(DefencesState.DEFENCES).get("unseen", 0))}
	if stability.has("strain"):
		out["strain"] = float(stability["strain"])
	return out


## The map in words, for a screen reader: each realm and its level, from the
## same words the universe screen says.
static func spoken(universe: Dictionary) -> String:
	var lines := PackedStringArray()
	for r: Dictionary in universe.get("realms", []):
		var level := int(r.get("level", 1))
		lines.append(Strings.t("UNIVERSE_HEART_TITLE", level) if str(r.get("realm", "")) == "heart"
			else Strings.t("UNIVERSE_REALM_TITLE", [UniversePresenter.realm_name(str(r.get("type", ""))), level]))
	return "\n".join(lines)


## Each resource's amount held (-1 where no slice has said it) and what its
## producers have ready of what they hold (§9.3), for home's resource row.
static func purse(store: Store) -> Dictionary:
	var wallet: Dictionary = store.get_slice(ShopState.WALLET)
	var known := bool(wallet.get("known", false))
	var codex: Dictionary = store.get_slice(CodexState.CODEX).get("view", {})
	var out := {"starlight": {"amount": int(wallet.get("starlight", 0)) if known else -1, "ready": 0, "holds": 0},
		"aether": {"amount": int(codex["aether"]) if codex.has("aether") else -1, "ready": 0, "holds": 0},
		"essence": {"amount": int(wallet.get("essence", 0)) if known else -1, "ready": 0, "holds": 0}}
	if not known:
		var universe := view(store)
		if universe.has("starlight"):
			out["starlight"]["amount"] = int(universe["starlight"])
	var home: Dictionary = store.get_slice(RosterState.ROSTER).get("view", {})
	for p: Dictionary in home.get("producers", []):
		var kind: String = PRODUCES.get(str(p.get("kind", "")), "")
		if kind != "":
			out[kind]["ready"] += int(p.get("stored", 0))
			out[kind]["holds"] += int(p.get("holds", 0))
	return out
