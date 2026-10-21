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
			store.dispatch(&"track_loaded", {"view": ShopTests.track_view()})
			store.dispatch(&"wallet_loaded", {"balance": {"starlight": 11250, "essence": 500}})
		"shop":
			store.dispatch(&"wallet_loaded", {"balance": {"starlight": 11250, "essence": 500}})
			store.dispatch(&"shop_loaded", {"catalogue": {"items": [
				{"id": "robe-aurora", "kind": "sage_robe", "price": 500},
				{"id": "skin-ember", "kind": "realm_skin", "price": 800},
				{"id": "sky-dusk", "kind": "sky_theme", "price": 300},
				{"id": "wave", "kind": "emote", "price": 100}],
				"owned": ["track-1-5", "season-1-ember"], "equipped": {"realm_skin": "season-1-ember"}}})
			store.dispatch(&"summary_loaded", {"summary": {"months": [{"month": "2026-10", "cents": 1100,
				"refunded": 0}], "left": 3900}})
		"friends":
			store.dispatch(&"friends_loaded", {"friends": [{"account": "kofi1234"}, {"account": "mira5678"},
				{"account": "juno9012"}],
				"feed": [{"raider": "kofi1234", "defender": "mira5678", "grade": "clean", "mode": "raid"},
					{"raider": "juno9012", "defender": "kofi1234", "grade": "foiled", "mode": "raid"},
					{"raider": "mira5678", "defender": "juno9012", "grade": "loud", "mode": "raid"}],
				"blocked": [{"account": "zzzz0000"}]})
			store.dispatch(&"invite_made", {"invite": {"invite": "k7q2px"}})
		"share":
			store.dispatch(&"share_link", {"link": {"challenge": "a1b2c3", "bundle": "b"}})
		"social":
			store.dispatch(&"league_loaded", {"view": {"season": 3, "renown": 1250, "league": "ember", "division": 2,
				"next": 1500}})
			store.dispatch(&"groups_loaded", {"constellation": {"name": "bright-harbour", "members": [
				{"account": "kofi1234", "role": "founder"}, {"account": "mira5678", "role": "member"}]},
				"crew": {"id": "c1", "invite": "ab12", "members": [{"account": "kofi1234"}], "formed": false}})
		"workshop":
			var island := func(id: String, en: String, level: int, featured: bool, remix: Variant) -> Dictionary:
				return {"id": id, "bundle": "b" + id, "realmLevel": level, "name": {"en": en}, "creator": "ffee0011",
					"creatorLevel": "builder", "remixOf": remix, "completions": 1512.25, "remixes": 7,
					"ratings": {"count": 3, "fun": 4.5, "cleverness": 3.0, "fairness": 5.0}, "featured": featured,
					"withdrawn": false, "removed": null}
			store.dispatch(&"workshop_listed", {"list": "new", "items": [island.call("i1", "Quiet Harbour", 3, true, null),
				island.call("i2", "Glass Maze", 4, false, "i1"), island.call("i3", "Ember Steps", 2, false, null)]})
