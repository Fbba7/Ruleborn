class_name SageTests
extends RefCounted
## The Sage hall (§11.7, §23.2): its reducers and words headless, the guard
## choice through a FakeTransport, the screen as drawn, and the hall against
## the server when one is named.

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
	_reducers()
	_words()
	await _flows()
	await _on_screen()
	await _online()


## The hall as the server answers GET /v1/sages for a Keeper 8: the
## Archivist on guard, the Tinkerer unlocked at 7, the other two locked.
static func sample(guardian: Variant = "the_archivist") -> Dictionary:
	var sages: Array = []
	for s: Array in [["the_archivist", 1], ["the_tinkerer", 7], ["the_gardener", 13], ["the_wanderer", 20]]:
		sages.append({"id": s[0], "unlocks_at": s[1], "unlocked": 8 >= int(s[1]), "guardian": s[0] == guardian})
	return {"level": 8, "guardian": guardian, "sages": sages}


func _reducers() -> void:
	var store := Store.new()
	SageState.register(store)
	store.dispatch(&"sages_loaded", {"view": sample()})
	store.dispatch(&"guardian_asked", {"key": "guard:the_tinkerer"})
	var asked: Dictionary = store.get_slice(SageState.SAGES)
	store.dispatch(&"sages_loaded", {"view": sample(null)})
	var held: Dictionary = store.get_slice(SageState.SAGES)
	store.dispatch(&"sages_failed", {"code": "sage_locked"})
	var failed: Dictionary = store.get_slice(SageState.SAGES)
	store.dispatch(&"guardian_set", {"view": sample("the_tinkerer")})
	var made: Dictionary = store.get_slice(SageState.SAGES)
	check.call("the Sage hall's reducers mark a change on its way, never let a fetch replace the hall a change "
			+ "will answer with, keep the hall on show when one fails, and take the server's hall when one is "
			+ "made (11.7)",
		asked["busy"] == "guard:the_tinkerer" and held["view"]["guardian"] == "the_archivist"
			and failed["error"] == "sage_locked" and failed["view"]["guardian"] == "the_archivist"
			and made["view"]["guardian"] == "the_tinkerer" and made["last"] == {"guardian": "the_tinkerer"}
			and made["busy"] == "",
		"%s | %s | %s" % [asked["busy"], failed, made])


func _words() -> void:
	var h := SagePresenter.screen({"view": sample(), "busy": "", "error": "", "last": {}})
	var archivist: Dictionary = h["sages"][0]
	var tinkerer: Dictionary = h["sages"][1]
	var gardener: Dictionary = h["sages"][2]
	var reached: Array = (archivist["levels"] as Array).filter(func(l: Dictionary) -> bool: return l["reached"])
	check.call("the Sage hall shows each Sage's powers and what each fifth level adds, those the Keeper's level "
			+ "has reached marked in words (11.7, 23.2)",
		archivist["name"] == "The Archivist" and archivist["powers"].begins_with("Heist powers: Suspend:")
			and archivist["home"].begins_with("At home: Lab experiments 20% faster.")
			and (archivist["levels"] as Array).size() == 8 and reached.size() == 1
			and archivist["levels"][0]["text"] == "✓ Level 5, reached: Reveal 3 uses"
			and archivist["levels"][1]["text"] == "Level 10: Suspend 12 s"
			and tinkerer["levels"][0]["text"] == "✓ Level 5, reached: Jam 15 s"
			and gardener["levels"][7]["text"].begins_with("Level 40: "),
		"%s" % [archivist])
	check.call("the Sage hall shows the Sages' level, which is the Keeper's, and when each locked Sage unlocks "
			+ "(11.7, 23.2)",
		h["header"] == "Your Sages are at level 8, the Keeper's" and archivist["lock"] == "Unlocked"
			and tinkerer["lock"] == "Unlocked" and gardener["lock"] == "Unlocks at Keeper level 13"
			and h["sages"][3]["lock"] == "Unlocks at Keeper level 20",
		"%s | %s" % [h["header"], gardener["lock"]])
	var none := SagePresenter.screen({"view": sample(null), "busy": "", "error": "", "last": {}})
	check.call("the Sage hall's guardian choice puts one unlocked Sage on guard at the Heart, in another's place, "
			+ "takes it off again, and a locked one waits and says until when (11.7, 23.2)",
		h["guard"] == "The Archivist is on guard at the Heart" and archivist["guarding"]
			and archivist["button"]["action"] == "Take off guard" and archivist["button"]["sage"] == null
			and tinkerer["button"]["action"] == "Put on guard at the Heart" and tinkerer["button"]["can"]
			and tinkerer["button"]["sage"] == "the_tinkerer"
			and tinkerer["button"]["spoken"] == "Put The Tinkerer on guard at the Heart"
			and not gardener["button"]["can"] and gardener["button"]["why"] == "Unlocks at Keeper level 13"
			and none["guard"] == "No Sage is on guard" and none["sages"][0]["button"]["sage"] == "the_archivist",
		"%s | %s" % [tinkerer["button"], gardener["button"]])


func _flows() -> void:
	var transport := FakeTransport.new()
	var s := Fixtures.answered(Services.build(tree.root, "https://edge.example", transport,
		"user://outbox-sage-test.json"))
	s.api.token = "t"
	transport.on("GET /v1/sages", sample())
	await s.sage_flow.load_sages()
	transport.on("PUT /v1/sages/guardian", sample("the_tinkerer"))
	await s.sage_flow.station("the_tinkerer")
	var sent: Dictionary = JSON.parse_string((transport.calls[-1]["body"] as PackedByteArray).get_string_from_utf8())
	var said: String = SagePresenter.screen(s.store.get_slice(SageState.SAGES))["said"]
	transport.on("PUT /v1/sages/guardian", {"error": "sage_locked", "unlocks_at": 13}, 409)
	await s.sage_flow.station("the_gardener")
	var refused: Dictionary = s.store.get_slice(SageState.SAGES)
	transport.on("PUT /v1/sages/guardian", sample(null))
	await s.sage_flow.station(null)
	var off: Dictionary = JSON.parse_string((transport.calls[-1]["body"] as PackedByteArray).get_string_from_utf8())
	check.call("a guard choice sends the Sage, or none, and shows the hall the server answers; a refusal keeps "
			+ "the hall on show and says why (11.7)",
		transport.calls[1]["route"] == "PUT /v1/sages/guardian" and sent == {"sage": "the_tinkerer"}
			and said == "The Tinkerer is on guard at the Heart" and refused["error"] == "sage_locked"
			and SagePresenter.screen(refused)["error"] == Errors.message("SAGE_FAILED", "sage_locked")
			and refused["view"]["guardian"] == "the_tinkerer" and off == {"sage": null}
			and s.store.get_slice(SageState.SAGES)["view"]["guardian"] == null,
		"%s | %s | %s | %s" % [sent, said, refused["error"], off])
	s.close()


func _on_screen() -> void:
	var services: Services = App.services
	var screen: SageHallScreen = await mount.call("sage_hall")
	await tree.process_frame
	services.store.dispatch(&"sages_loaded", {"view": sample()})
	var buttons := {}
	for b: Button in screen.find_children("*", "Button", true, false):
		if b.has_meta("key"):
			buttons[b.get_meta("key")] = b
	var reached := screen.body.find_children("*", "Label", true, false).filter(
		func(l: Label) -> bool: return l.has_meta("reached") and l.get_meta("reached"))
	var words := screen.body.find_children("*", "Label", true, false).map(func(l: Label) -> String: return l.text)
	var drawn: bool = screen.header_label.text == "Your Sages are at level 8, the Keeper's" \
		and screen.guard_label.text == "The Archivist is on guard at the Heart" \
		and buttons.has("guard:none") and buttons.has("guard:the_tinkerer") \
		and not (buttons["guard:the_tinkerer"] as Button).disabled and (buttons["guard:the_gardener"] as Button).disabled \
		and words.has("Unlocks at Keeper level 13") and reached.size() == 4 \
		and words.has("A Sage on guard stays home from heists")
	(buttons["guard:the_tinkerer"] as Button).pressed.emit()
	for i in 5:
		await tree.process_frame
	# Offline here: the choice is the server's to keep, and the screen says
	# it was not made.
	var tried: Dictionary = services.store.get_slice(SageState.SAGES)
	var shown := screen.status_label.text
	screen.queue_free()
	check.call("the Sage hall screen draws the level, each Sage's gains reached, the one on guard and the "
			+ "choice; a choice the server does not hear is said not to be made (11.7, 23.2)",
		drawn and tried["busy"] == "" and tried["error"] != "" and shown.begins_with(UI.GLYPH["alarm"])
			and tried["view"]["guardian"] == "the_archivist",
		"%s | %s | %s | %s" % [drawn, buttons.keys(), words, tried])


func _online() -> void:
	var name := "against the server: a new Keeper's hall has the Archivist alone unlocked and none on guard; the "
	name += "Archivist goes on guard, and a locked Sage is refused in words (11.7)"
	if server_url == "":
		check.call(name, false, "no server: run through client/status.py, which starts one")
		return
	var s := Fixtures.answered(Services.build(tree.root, server_url, null, "user://outbox-test-sages.json"))
	s.router.change = func(_path: String) -> void: pass
	var me := await s.account.sign_in("test:sages")
	if not me.ok:
		check.call(name, false, "sign-in refused: %s" % me.code)
		s.close()
		return
	await s.sage_flow.load_sages()
	var first: Dictionary = s.store.get_slice(SageState.SAGES)["view"]
	await s.sage_flow.station("the_archivist")
	var on: Dictionary = s.store.get_slice(SageState.SAGES)
	await s.sage_flow.station("the_wanderer")
	var locked: Dictionary = s.store.get_slice(SageState.SAGES)
	var unlocked: Array = (first.get("sages", []) as Array).map(func(x: Dictionary) -> bool: return x["unlocked"])
	check.call(name,
		int(first.get("level", 0)) == 1 and first.get("guardian") == null and unlocked == [true, false, false, false]
			and on["view"]["guardian"] == "the_archivist" and locked["error"] == "sage_locked"
			and SagePresenter.screen(locked)["error"] == Errors.message("SAGE_FAILED", "sage_locked"),
		"%s | %s | %s" % [first, on["view"].get("guardian"), locked["error"]])
	s.close()
