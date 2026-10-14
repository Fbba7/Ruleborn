class_name WeavingTests
extends RefCounted
## Weaving (§5.5, §5.6, §8, §23.2): its words headless, its changes through
## a FakeTransport, the screen as drawn, and weaving against the server when
## one is named.

const NOW := 1_000_000_000

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
	await _flows()
	await _offline()
	await _on_screen()
	await _online()


## A view as GET /v1/weaving answers: Slow rivers woven in the Heart, a
## slot free beside it, Verdant's one slot resting, and four restored laws
## offered, Honeycomb taking strain to Breaking.
static func sample() -> Dictionary:
	var offer := func(law: String, points: float, price: int, band: int, harmonies: Array, clashes: Array,
			resonances: int, refused: Variant) -> Dictionary:
		return {"law": law, "tier": 1, "points": points, "price": price, "minutes": 10, "harmonies": harmonies,
			"clashes": clashes, "resonances": resonances, "chords": 0, "band": band, "strain": 0.4, "refused": refused}
	var offers := [offer.call("bloom", 8.8, 352, 0, [], [], 1, null),
		offer.call("half_gravity", 10.5, 420, 1, [], ["flow"], 0, null),
		offer.call("stillness", 9.35, 374, 0, ["hush"], [], 0, null),
		offer.call("honeycomb", 40.0, 1600, 6, ["weight"], [], 0, "would_break")]
	return {"aether": 1250, "stability": {"capacity": 46.0, "total": 10.0, "draw": 0.0, "strain": 0.2174, "band": 0,
		"chords": []},
		"realms": [
			{"realm": "crown", "type": null, "slots": [], "opens_at": 2, "prices": {}, "offers": [],
				"recommended": []},
			{"realm": "heart", "type": "Heart", "slots": [{"slot": 1, "law": "slow_rivers", "tier": 1,
				"ready_at": NOW - 1, "weaving": false}, {"slot": 2, "law": null, "rests_until": null}],
				"offers": offers, "recommended": ["stillness", "bloom", "half_gravity"]},
			{"realm": "outer-1", "type": "Verdant", "slots": [{"slot": 1, "law": null,
				"rests_until": NOW + 30 * 60000}], "offers": [], "recommended": []}]}


func _words() -> void:
	var w := WeavingPresenter.screen({"view": sample(), "busy": "", "error": "", "last": {}}, NOW)
	var bar: Dictionary = w["bar"]
	var current: Array = (bar["bands"] as Array).filter(func(b: Dictionary) -> bool: return b["current"])
	check.call("Weaving shows the universe's stability as a bar of §5.5's seven bands, the current one marked in "
			+ "words with its effect, and strain against capacity (5.5, 23.2)",
		(bar["bands"] as Array).size() == 7 and current.size() == 1 and current[0]["name"] == "Quiet"
			and bar["bands"][6]["name"] == "Breaking" and bar["effect"] == "No effect"
			and bar["strain"] == "Strain 22%: 10 of 46 stability, Quiet"
			and WeavingPresenter.bar({"band": 2})["effect"] == "+10% production",
		"%s" % [bar])
	var heart: Dictionary = w["realms"][1]
	var rec: Array = heart["recommended"]
	check.call("Weaving recommends two or three laws for a realm, ranked: one that harmonises first, one that "
			+ "clashes last, then the cheapest, each compared by its points, the band after weaving and its "
			+ "harmonies and clashes (23.2, C48)",
		rec.size() == 3 and rec[0]["law"] == "stillness" and rec[2]["law"] == "half_gravity"
			and rec[0]["title"] == "Stillness: 9.35 points, Quiet after weaving"
			and rec[2]["title"] == "Half gravity: 10.5 points, Steady after weaving"
			and rec[0]["lines"] == ["Harmonises on Hush"] and rec[2]["lines"] == ["Clashes on Flow"]
			and (heart["others"] as Array).size() == 1,
		"%s" % [rec])
	var bloom: Dictionary = rec[1]
	var others: Dictionary = heart["others"][0]
	check.call("Weaving shows the harmonies, clashes and resonances every law would make before it is woven "
			+ "(8.2, 8.3, 8.4, 23.2)",
		bloom["lines"] == ["Resonances it would sound: 1"] and others["lines"] == ["Harmonises on Weight"]
			and WeavingPresenter.notes(["flow", "hush"]) == "Flow, Hush",
		"%s | %s" % [bloom, others])
	check.call("Weaving puts each weave's Aether price and weaving time on its button, the server's price for that "
			+ "weave, into the realm's first free slot (5.6, 23.2)",
		rec[0]["action"] == "Weave, 374 Aether, 10 min" and rec[0]["can"]
			and rec[0]["args"] == {"realm": "heart", "slot": 2, "law": "stillness"}
			and WeavingPresenter.duration(120) == "2 h" and WeavingPresenter.duration(130) == "2 h 10 min",
		"%s" % [rec[0]])
	check.call("a weave that would take strain into Breaking waits and says why (5.5)",
		not others["can"] and others["why"] == "it would take strain to Breaking"
			and others["title"].ends_with("Breaking after weaving"),
		"%s" % [others])
	var slots: Array = heart["slots"]
	var verdant: Dictionary = w["realms"][2]
	check.call("Weaving shows each realm's slots and the crown's: a law woven with its tier, a free slot, a resting "
			+ "one and when it frees (5.1, 5.6)",
		w["realms"][0]["title"] == "The crown" and slots[0]["text"] == "Slot 1: Slow rivers, tier 1"
			and slots[0]["out"]["action"] == "Take out" and slots[1]["text"] == "Slot 2: empty"
			and verdant["title"] == "Verdant" and verdant["slots"][0]["text"] == "Slot 1: resting, free in 30 min"
			and w["header"] == "1,250 Aether to weave with",
		"%s | %s" % [slots, verdant])
	_spire_levels()


## TD.20's gate: the Heart's and the Spire's slots at Spire levels 1, 2, 5
## and 6, as the server reports them (§5.1, D75): the Heart its two and no
## third, the crown none, one, two and two, each with when the next opens.
func _spire_levels() -> void:
	var seen := {}
	for at: Array in [[1, 0, 2], [2, 1, 5], [5, 2, null], [6, 2, null]]:
		var v := sample()
		var crown: Dictionary = v["realms"][0]
		var empty: Array[Dictionary] = []
		for n in int(at[1]):
			empty.append({"slot": n + 1, "law": null, "rests_until": null})
		crown["slots"] = empty
		crown["opens_at"] = at[2]
		# The Heart's four offers, none recommended here: a crown with a slot
		# lists them all, one with none lists nothing.
		crown["offers"] = (v["realms"][1]["offers"] as Array).duplicate()
		var w := WeavingPresenter.screen({"view": v, "busy": "", "error": "", "last": {}}, NOW)
		var drawn: Dictionary = w["realms"][0]
		seen[at[0]] = [(drawn["slots"] as Array).map(func(x: Dictionary) -> String: return x["text"]),
			(w["realms"][1]["slots"] as Array).size(), (drawn["others"] as Array).size()]
	check.call("Weaving shows the Heart's two slots and no third, and the crown's slots the Spire has opened, "
			+ "none at Spire level 1, one at 2, two at 5 and 6, with the level that opens the next (5.1, TD.20)",
		seen[1] == [["The next crown slot opens at Spire level 2"], 2, 0]
			and seen[2] == [["Slot 1: empty", "The next crown slot opens at Spire level 5"], 2, 4]
			and seen[5] == [["Slot 1: empty", "Slot 2: empty"], 2, 4] and seen[6] == seen[5],
		"%s" % [seen])


func _flows() -> void:
	var transport := FakeTransport.new()
	var s := Fixtures.answered(Services.build(tree.root, "https://edge.example", transport,
		"user://outbox-weaving-test.json"))
	s.api.token = "t"
	transport.on("GET /v1/weaving", sample())
	await s.weaving_flow.load_weaving()
	transport.on("POST /v1/weaving", {"weaving": sample()})
	await s.weaving_flow.weave("heart", 2, "stillness")
	var sent: Dictionary = JSON.parse_string((transport.calls[-1]["body"] as PackedByteArray).get_string_from_utf8())
	var said: String = WeavingPresenter.screen(s.store.get_slice(WeavingState.WEAVING), NOW)["said"]
	transport.on("POST /v1/weaving", {"error": "would_break", "strain": 1.3}, 409)
	await s.weaving_flow.weave("heart", 2, "honeycomb")
	var refused: Dictionary = s.store.get_slice(WeavingState.WEAVING)
	transport.on("DELETE /v1/weaving/heart/1", {"weaving": sample()})
	await s.weaving_flow.unweave("heart", 1)
	var out: String = WeavingPresenter.screen(s.store.get_slice(WeavingState.WEAVING), NOW)["said"]
	check.call("a weave sends the realm, slot and law and shows the view the server answers; a refusal keeps the "
			+ "view on show and says why; taking a law out rests the slot (5.5, 5.6)",
		sent.get("realm") == "heart" and int(sent.get("slot", 0)) == 2 and sent.get("law") == "stillness"
			and said == "Stillness is being woven"
			and refused["error"] == "would_break"
			and WeavingPresenter.screen(refused, NOW)["error"] == Errors.message("WEAVING_FAILED", "would_break")
			and not (refused["view"] as Dictionary).is_empty() and out == "Taken out; the slot rests an hour"
			and transport.calls[-1]["route"] == "DELETE /v1/weaving/heart/1",
		"%s | %s | %s" % [sent, said, out])
	s.close()


## §24: "The device may build, weave and assign work offline, confirmed on
## reconnection".
func _offline() -> void:
	var path := "user://outbox-weaving-offline-test.json"
	DirAccess.remove_absolute(path)
	var transport := FakeTransport.new()
	var s := Fixtures.answered(Services.build(tree.root, "https://edge.example", transport, path))
	s.api.token = "t"
	transport.on("GET /v1/weaving", sample())
	await s.weaving_flow.load_weaving()
	transport.offline = true
	await s.weaving_flow.weave("heart", 2, "stillness")
	var waiting: Dictionary = s.store.get_slice(WeavingState.WEAVING)
	var kept := s.outbox.pending()
	transport.offline = false
	var woven := sample()
	woven["aether"] = 876
	transport.on("POST /v1/offline", {"results": [{"confirmed": true}], "universe": {}, "home": {}, "weaving": woven})
	await s.outbox.flush(s.api)
	var after: Dictionary = s.store.get_slice(WeavingState.WEAVING)
	var sent: Array = transport.calls.filter(func(c: Dictionary) -> bool: return c["route"] == "POST /v1/offline")
	var body: Dictionary = JSON.parse_string((sent[0]["body"] as PackedByteArray).get_string_from_utf8()) \
		if not sent.is_empty() else {}
	var action: Dictionary = (body.get("actions", [{}]) as Array)[0]
	# A second, refused on reconnection: said, with its law and why.
	transport.offline = true
	await s.weaving_flow.weave("heart", 2, "bloom")
	transport.offline = false
	transport.on("POST /v1/offline", {"results": [{"refused": "would_break"}], "universe": {}, "home": {},
		"weaving": woven})
	await s.outbox.flush(s.api)
	var refused: String = WeavingPresenter.screen(s.store.get_slice(WeavingState.WEAVING), NOW)["refused"]
	check.call("a weave with no network waits in the outbox, shown as confirming, and is confirmed on "
			+ "reconnection with what is woven after it, or said refused and why (24, 5.6)",
		kept == 1 and (waiting["confirming"] as Dictionary).size() == 1
			and WeavingPresenter.screen(waiting, NOW)["confirming"] == Strings.t("UNIVERSE_CONFIRMING", 1)
			and action.get("do") == "weave" and action.get("realm") == "heart" and int(action.get("slot", 0)) == 2
			and action.get("law") == "stillness"
			and (after["confirming"] as Dictionary).is_empty() and int(after["view"]["aether"]) == 876
			and refused == "Bloom was not woven: it would take strain to Breaking" and s.outbox.pending() == 0,
		"%s | %s | %s | %s" % [kept, waiting["confirming"], action, refused])
	s.close()
	DirAccess.remove_absolute(path)


func _on_screen() -> void:
	var services: Services = App.services
	var screen: WeavingScreen = await mount.call("weaving")
	screen.clock = func() -> int: return NOW
	await tree.process_frame
	services.store.dispatch(&"weaving_loaded", {"view": sample()})
	var find := func(key: String) -> Button:
		for b: Button in screen.find_children("*", "Button", true, false):
			if b.get_meta("key", "") == key:
				return b
		return null
	var cells := screen.body.find_children("*", "Label", true, false).filter(
		func(l: Label) -> bool: return l.has_meta("band"))
	var marked := cells.filter(func(l: Label) -> bool: return l.get_meta("current"))
	var weave: Button = find.call("weave:heart:stillness")
	var breaking: Button = find.call("weave:heart:honeycomb")
	var drawn: bool = cells.size() == 7 and marked.size() == 1 and (marked[0] as Label).text == "● Quiet" \
		and weave != null and weave.text == "Weave, 374 Aether, 10 min" and breaking != null and breaking.disabled
	weave.pressed.emit()
	await tree.process_frame
	var asked: Button = find.call("weave:heart:stillness")
	var confirming: bool = asked != null and asked.text == "Tap again to spend 374 Aether" \
		and services.store.get_slice(WeavingState.WEAVING)["busy"] == ""
	screen.queue_free()
	await tree.process_frame
	check.call("the Weaving screen draws the seven bands with the current one marked, each law's comparison and its "
			+ "button; a weave into Breaking waits, and Aether is spent on a second tap (5.5, 5.6, 23.2)",
		drawn and confirming, "%s %s" % [drawn, confirming])
	await _held()


## §23.5's Weave: "A tap path too, and hold times adjustable" (§20.8). A
## hold let go early spends nothing; one held for the hold time weaves.
func _held() -> void:
	var services: Services = App.services
	var was := Settings.hold_ms
	Settings.hold_ms = 100
	var screen: WeavingScreen = await mount.call("weaving")
	screen.clock = func() -> int: return NOW
	await tree.process_frame
	services.store.dispatch(&"weaving_loaded", {"view": sample()})
	var key := "weave:heart:stillness"
	var find := func() -> Button:
		for b: Button in screen.find_children("*", "Button", true, false):
			if b.get_meta("key", "") == key:
				return b
		return null
	var how := screen.body.find_children("*", "Label", true, false).any(
		func(l: Label) -> bool: return l.text == "Hold a Weave button for 0.1 s, or tap it twice")
	var b: Button = find.call()
	b.button_down.emit()
	b.button_up.emit()
	b.pressed.emit()
	await tree.create_timer(0.2).timeout
	var early: bool = not services.outbox.has(WeavingController.OFFLINE + key) \
		and find.call().text == "Tap again to spend 374 Aether"
	screen.confirm = ""
	b = find.call()
	b.button_down.emit()
	await tree.create_timer(0.2).timeout
	for i in 3:
		await tree.process_frame
	# Offline here: the weave waits in the outbox to be confirmed (§24).
	var kept := services.outbox.has(WeavingController.OFFLINE + key)
	services.outbox.drop(WeavingController.OFFLINE + key)
	services.store.dispatch(&"weave_answered", {"key": key})
	screen.queue_free()
	await tree.process_frame
	Settings.hold_ms = was
	check.call("a Weave held for the hold time weaves and one let go sooner does not; a tap path is beside it, the "
			+ "screen says both, and the hold time is the player's to change (20.8, 23.5)",
		how and early and kept and Settings.hold_steps() == [500, 1000, 1500, 2000, 3000]
			and Settings.hold_default() == 1000 and SettingsScreen.seconds(1500) == "1.5",
		"how %s, early %s, kept %s" % [how, early, kept])


func _online() -> void:
	var name := "against the server: Weaving offers the starting laws at the simulation's prices, recommends them, "
	name += "and charges for a weave the price it showed (5.5, 5.6, TD.14)"
	if server_url == "":
		check.call(name, false, "no server: run through client/status.py, which starts one")
		return
	var s := Fixtures.answered(Services.build(tree.root, server_url, null, "user://outbox-test-weaving.json"))
	s.router.change = func(_path: String) -> void: pass
	var me := await s.account.sign_in("test:weaving")
	if not me.ok:
		check.call(name, false, "sign-in refused: %s" % me.code)
		s.close()
		return
	await s.weaving_flow.load_weaving()
	var v: Dictionary = s.store.get_slice(WeavingState.WEAVING)["view"]
	var heart: Dictionary = {}
	for r: Dictionary in v.get("realms", []):
		if r["realm"] == "heart":
			heart = r
	var offers: Array = heart.get("offers", [])
	var first: String = str((heart.get("recommended", []) as Array).front()) if heart.has("recommended") else ""
	var priced := 0
	for o: Dictionary in offers:
		if o["law"] == first:
			priced = int(o["price"])
	var before := int(v.get("aether", 0))
	var w := WeavingPresenter.screen(s.store.get_slice(WeavingState.WEAVING), NOW)
	if first != "":
		await s.weaving_flow.weave("heart", 1, first)
	var after: Dictionary = s.store.get_slice(WeavingState.WEAVING)
	check.call(name,
		offers.size() == 3 and (heart.get("recommended", []) as Array).size() >= 2 and priced > 0
			# A new Keeper has no Aether yet: the server's refusal names the
			# cost it would have charged, which is the price shown.
			and ((after["error"] == "not_enough_aether" and int(after["detail"].get("cost", -1)) == priced)
				or (after["error"] == "" and before - int(after["view"].get("aether", 0)) == priced))
			and str(w.get("bar", {}).get("name", "")) == "Quiet",
		"%s | %s | %s | %s %s" % [offers, first, priced, after["error"], after["detail"]])
	s.close()
