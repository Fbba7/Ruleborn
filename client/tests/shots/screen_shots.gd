class_name ScreenShots
extends RefCounted
## The sample state each of T10's screens is shot with: the screen tests' own
## samples, so a still shows what the tests check.


static func params(name: String) -> Dictionary:
	match name:
		"law":
			return {"law": "bloom"}
	return {}


static func fill(name: String, store: Store) -> void:
	match name:
		"codex":
			store.dispatch(&"codex_loaded", {"view": CodexTests.sample(), "changes": 0})
		"law":
			var v := CodexTests.sample()
			v["laws"] = [LawTests.bloom()]
			store.dispatch(&"codex_loaded", {"view": v, "changes": 0})
		"lab":
			store.dispatch(&"lab_loaded", {"view": LabTests.sample()})
		"weaving":
			store.dispatch(&"weaving_loaded", {"view": WeavingTests.sample()})
		"harmony":
			store.dispatch(&"harmony_loaded", {"view": HarmonyTests.sample()})
		"profile":
			store.dispatch(&"profile_loaded", {"view": ProfileTests.sample()})
		"track":
			store.dispatch(&"track_loaded", {"view": {"season": 1, "claimed": 3}})
			store.dispatch(&"wallet_loaded", {"balance": {"starlight": 11250, "essence": 500}})
		"shop":
			store.dispatch(&"wallet_loaded", {"balance": {"starlight": 11250, "essence": 500}})
