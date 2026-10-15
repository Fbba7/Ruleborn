class_name LawTests
extends RefCounted
## The law card (§7.7, §21.7, §23.2): its words headless, the Codex opening
## it, the screen as drawn, and the card against the server when one is
## named.

var tree: SceneTree
var check: Callable
var mount: Callable
var server_url := ""


func _init(t: SceneTree, c: Callable, m: Callable, url: String) -> void:
	tree = t
	check = c
	mount = m
	server_url = url


func run() -> void:
	_words()
	await _from_codex()
	await _online()


## Bloom as GET /v1/codex sends it: restored at tier I, 4 pages toward II.
static func bloom() -> Dictionary:
	return {"law": "bloom", "name": "Bloom", "school": "Life", "rank": "Common", "notes": ["Bloom", "Hush"],
		"chapter": 1, "open": true, "pages": 4, "tier": 1, "next": {"pages": 20, "aether": 2000, "spire": 4}}


func _words() -> void:
	var c := LawPresenter.card(bloom())
	var top := bloom()
	top["tier"] = 3
	top["next"] = null
	var t := LawPresenter.card(top)
	var met := bloom()
	met["tier"] = 0
	met["next"] = {"pages": 10}
	var m := LawPresenter.card(met)
	check.call("the law card shows the school's shape and name, the law's one-line rule and its notes as symbols "
			+ "(21.7, 23.2)",
		c["mark"] == UI.school_mark("life") and c["name"] == "Bloom"
			and c["rule"] == "Cut hedges regrow after 10 seconds."
			and c["notes"] == "Notes: A sprout (Bloom), A crescent (Hush)",
		"%s | %s | %s" % [c["mark"], c["rule"], c["notes"]])
	check.call("the law card shows the law's rank, its tier as pips, its pages toward the next step and §7.7's one "
			+ "weakness (7.6, 7.7, 23.5)",
		c["rank"] == "Rank: Common" and c["tier"] == "Tier ●○○ I" and c["tier_spoken"] == "Restored to tier 1 of 3"
			and c["pages"] == "Pages: 4 of 20 for the next step" and t["tier"] == "Tier ●●● III" and t["pages"] == "Pages: 4"
			and m["tier"] == "Tier ○○○ not restored" and m["pages"] == "Pages: 4 of 10 for the next step"
			and c["weakness"] == "Weakness: It hides the crew as readily as it blocks them.",
		"%s | %s | %s | %s" % [c["tier"], c["pages"], t["tier"], m["tier"]])


func _from_codex() -> void:
	var services: Services = App.services
	var routes: Array = []
	var change: Callable = services.router.change
	services.router.change = func(path: String) -> void: routes.append(path.get_file().get_basename())
	services.store.dispatch(&"codex_loaded", {"view": CodexTests.sample(), "changes": 0})
	var codex: CodexScreen = await mount.call("codex")
	await tree.process_frame
	services.store.dispatch(&"codex_loaded", {"view": CodexTests.sample(), "changes": 0})
	var card: Button = null
	for b: Button in codex.find_children("*", "Button", true, false):
		if b.get_meta("key", "") == "card:bloom":
			card = b
	var found := card != null
	if found:
		card.pressed.emit()
	var params: Dictionary = services.store.get_slice(AppState.ROUTE)["params"]
	codex.queue_free()
	await tree.process_frame
	var screen: LawScreen = await mount.call("law")
	await tree.process_frame
	var names := screen.box.find_children("*", "Label", true, false).filter(
		func(l: Label) -> bool: return l.has_meta("law")).map(func(l: Label) -> String: return l.get_meta("law"))
	var texts := screen.box.find_children("*", "Label", true, false).map(func(l: Label) -> String: return l.text)
	screen.queue_free()
	services.router.change = change
	await tree.process_frame
	check.call("a law met in the Codex opens its law card, which draws the card for that law (7.6, 23.2)",
		found and "law" in routes and params.get("law") == "bloom" and names == ["bloom"]
			and "Cut hedges regrow after 10 seconds." in texts,
		"%s %s %s" % [routes, params, names])


func _online() -> void:
	var name := "against the server: each law a new Keeper's Codex holds opens a law card with its rule, notes, rank, "
	name += "tier and weakness (7.7, 23.2)"
	if server_url == "":
		check.call(name, false, "no server: run through client/status.py, which starts one")
		return
	var s := Fixtures.answered(Services.build(tree.root, server_url, null, "user://outbox-test-law.json"))
	s.router.change = func(_path: String) -> void: pass
	var me := await s.account.sign_in("test:law")
	if not me.ok:
		check.call(name, false, "sign-in refused: %s" % me.code)
		s.close()
		return
	await s.codex_flow.load_codex()
	var codex: Dictionary = s.store.get_slice(CodexState.CODEX)
	var laws: Array = (codex["view"] as Dictionary).get("laws", [])
	var cards: Array = laws.map(func(l: Dictionary) -> Dictionary: return LawPresenter.from_codex(codex, str(l["law"])))
	var whole := true
	for c: Dictionary in cards:
		whole = whole and not c.is_empty() and not str(c["rule"]).begins_with("LAW_RULE") \
			and c["notes"] != "Notes: " and not str(c["weakness"]).contains("LAW_WEAKNESS")
	check.call(name, laws.size() >= 3 and whole, "%d laws, %s" % [laws.size(), cards.slice(0, 1)])
	s.close()
