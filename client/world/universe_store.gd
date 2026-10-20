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


static func view(store: Store) -> Dictionary:
	return store.get_slice(UniverseState.UNIVERSE).get("view", {})


static func extras(store: Store) -> Dictionary:
	var home: Dictionary = store.get_slice(RosterState.ROSTER).get("view", {})
	var weaving: Dictionary = store.get_slice(WeavingState.WEAVING).get("view", {})
	var stability: Dictionary = weaving.get("stability", {})
	var out := {"producers": home.get("producers", []), "band": int(stability.get("band", 0)),
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
