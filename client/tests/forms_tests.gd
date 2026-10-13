class_name FormsTests
extends RefCounted
## The Forms album (§11.10, §23.2): its words headless, "Show mine", the
## screen as drawn, and the album against the server when one is named.

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
	_mine()
	await _on_screen()
	await _online()


## An album as GET /v1/forms answers, cut to two kinds: the Featherkin's
## three forms all had (two Echo), the Mossbear's none.
static func sample() -> Dictionary:
	var owned := {"featherkin": [1, 1, 2], "mossbear": [0, 0, 0]}
	var forms: Array = []
	for kind: String in owned:
		for i in 3:
			forms.append({"kind": kind, "note": ["hush", "spark", "echo"][i], "owned": owned[kind][i]})
	return {"forms": forms,
		"notes": [{"note": "hush", "laws": ["stillness", "glowing_dark"]}, {"note": "spark", "laws": ["heat_bloom"]},
			{"note": "echo", "laws": ["tidemark"]}],
		"outfits": [{"kind": "featherkin", "have": 3, "of": 3}, {"kind": "mossbear", "have": 0, "of": 3}],
		"sails": [{"note": "hush", "have": 1, "of": 18}, {"note": "spark", "have": 1, "of": 18},
			{"note": "echo", "have": 1, "of": 18}]}


func _words() -> void:
	var a := FormsPresenter.screen({"view": sample(), "busy": "", "error": "", "mine": false})
	var feather: Dictionary = a["kinds"][0]
	var moss: Dictionary = a["kinds"][1]
	var hush: Dictionary = a["notes"][0]
	check.call("the Forms album shows the forms by kind and note, which the player has, and each form's quirk "
			+ "(11.10, 23.2)",
		a["header"] == "3 of 6 forms hatched" and feather["title"] == "Featherkin" and moss["title"] == "Mossbear"
			and (feather["forms"] as Array).size() == 3
			and feather["forms"][0]["text"] == "✓ Hush · Noticed 10% later: you have 1"
			and feather["forms"][2]["text"].ends_with("you have 2")
			and moss["forms"][1]["text"] == "Spark · +5% power: not hatched yet",
		"%s" % [a["kinds"]])
	check.call("the Forms album says how to hatch each note's forms: the launch laws that carry it, woven in a "
			+ "Nursery's realm, with the note's look and symbol (11.10, 23.2)",
		hush["title"] == "Hush · symbol: A crescent"
			and hush["look"] == "Looks: Midnight colours and soft, silent edges"
			and hush["quirk"] == "Quirk: Noticed 10% later"
			and hush["how"] == "Laws that hatch it, woven in the realm with a Nursery: Stillness, Glowing dark"
			and a["notes"][2]["how"].ends_with(": Tidemark"),
		"%s" % [a["notes"]])
	check.call("the Forms album shows the outfit each kind's three forms unlock and the skiff sail each note "
			+ "across every kind unlocks, and how far each is (11.10, 23.2)",
		feather["outfit"] == "✓ All 3 forms: outfit unlocked"
			and moss["outfit"] == "0 of 3 forms: all of them unlock an outfit"
			and a["sails"][0] == "Hush in 1 of 18 kinds: every kind unlocks a skiff sail"
			and FormsPresenter.sail({"note": "echo", "have": 18, "of": 18}) == "✓ Echo in every kind: skiff sail unlocked",
		"%s | %s" % [feather["outfit"], a["sails"]])


func _mine() -> void:
	var store := Store.new()
	FormsState.register(store)
	store.dispatch(&"forms_loaded", {"view": sample()})
	store.dispatch(&"forms_mine", {"mine": true})
	var mine := FormsPresenter.screen(store.get_slice(FormsState.FORMS))
	store.dispatch(&"forms_failed", {"code": "offline"})
	var failed: Dictionary = store.get_slice(FormsState.FORMS)
	store.dispatch(&"forms_mine", {"mine": false})
	var all := FormsPresenter.screen(store.get_slice(FormsState.FORMS))
	check.call("the Forms album's Show mine keeps only the forms the player has, and Show all brings the rest "
			+ "back; a failure keeps the album on show (23.2)",
		(mine["kinds"] as Array).size() == 1 and (mine["kinds"][0]["forms"] as Array).size() == 3
			and mine["toggle"]["action"] == "Show all" and not mine["toggle"]["mine"]
			and (all["kinds"] as Array).size() == 2 and all["toggle"]["action"] == "Show mine"
			and failed["error"] == "offline" and not (failed["view"] as Dictionary).is_empty(),
		"%s | %s" % [mine["kinds"], all["toggle"]])


func _on_screen() -> void:
	var services: Services = App.services
	var screen: FormsScreen = await mount.call("forms")
	await tree.process_frame
	services.store.dispatch(&"forms_mine", {"mine": false})
	services.store.dispatch(&"forms_loaded", {"view": sample()})
	var lines := func() -> Array:
		return screen.body.find_children("*", "Label", true, false).filter(
			func(l: Label) -> bool: return l.has_meta("form")).map(func(l: Label) -> String: return l.get_meta("form"))
	var before: Array = lines.call()
	var words := screen.body.find_children("*", "Label", true, false).map(func(l: Label) -> String: return l.text)
	var named := screen.toggle.text == "Show mine"
	screen.toggle.pressed.emit()
	await tree.process_frame
	var after: Array = lines.call()
	var renamed := screen.toggle.text == "Show all"
	screen.toggle.pressed.emit()
	screen.queue_free()
	check.call("the Forms album screen draws each note, each kind's forms and the sails, and its Show mine button "
			+ "filters them (23.2)",
		before.size() == 6 and after.size() == 3 and after.has("featherkin/echo") and not after.has("mossbear/hush")
			and named and renamed and words.has("Hush · symbol: A crescent") and words.has("Skiff sails"),
		"%s | %s | %s" % [before, after, words])


func _online() -> void:
	var name := "against the server: the album holds the 54 forms, starts with the player's own three, and names "
	name += "the launch laws that hatch each note (11.10, 23.2)"
	if server_url == "":
		check.call(name, false, "no server: run through client/status.py, which starts one")
		return
	var s := Fixtures.answered(Services.build(tree.root, server_url, null, "user://outbox-test-forms.json"))
	s.router.change = func(_path: String) -> void: pass
	var me := await s.account.sign_in("test:forms")
	if not me.ok:
		check.call(name, false, "sign-in refused: %s" % me.code)
		s.close()
		return
	await s.forms_flow.load_album()
	var a: Dictionary = s.store.get_slice(FormsState.FORMS)
	var v: Dictionary = a["view"]
	var shown := FormsPresenter.screen(a)
	var owned := 0
	for f: Dictionary in v.get("forms", []):
		owned += int(f["owned"])
	check.call(name,
		a["error"] == "" and (v.get("forms", []) as Array).size() == 54 and owned == 3
			and (v.get("notes", []) as Array).size() == 3 and str(shown.get("header", "")).ends_with("of 54 forms hatched")
			and str(shown["notes"][0]["how"]).contains("Stillness"),
		"%s | %s" % [a["error"], shown.get("header")])
	s.close()
