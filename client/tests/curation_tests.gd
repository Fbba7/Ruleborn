class_name CurationTests
extends RefCounted
## Curation (§13.3, §23.2): its words and verbs headless, the flows through
## a FakeTransport, the screen as drawn, and a layout laid and curated
## against the server when one is named.

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
	_verbs()
	await _flows()
	await _on_screen()
	await _online()


## A Heart with two posts, tall grass east of the first, and Slow rivers'
## pylon.
static func island() -> PackedByteArray:
	var i := RulebornIsland.new()
	i.reset(3)
	i.set_ground(5, 4, "tall_grass")
	i.post_guard(0, 4, 4)
	i.post_guard(1, 7, 5)
	i.weave("slow_rivers", 9, 9)
	return i.bytes()


## The Heart's curation as GET /v1/curation/heart answers it.
static func sample() -> Dictionary:
	return {"realm": "heart", "type": "Heart", "level": 3, "vaultLevel": 1, "aether": 1000, "island": "b-cur",
		"origin": "generated", "seed": "11", "name": {"adjective": 1, "noun": 2}, "page": 0,
		"layouts": ["11", "22", "33"],
		"swaps": [{"slot": 1, "law": "slow_rivers", "offers": [
			{"law": "bloom", "tier": 1, "price": 160, "minutes": 10, "refused": null},
			{"law": "half_gravity", "tier": 1, "price": 200, "minutes": 10, "refused": "crowned"}]}]}


static func _slice(view: Dictionary, post := CurationState.NO_POST, swap := {}) -> Dictionary:
	var s := CurationState.fresh("heart")
	s["view"] = view
	s["base"] = island()
	s["draft"] = island()
	s["post"] = post
	s["swap"] = swap
	s["words"] = FirstTests.words()
	return s


func _words() -> void:
	var c := CurationPresenter.screen(_slice(sample()))
	var layouts: Array = c["layouts"]
	var none := sample()
	none["island"] = null
	none["origin"] = null
	none["name"] = null
	none["page"] = 1
	var n := CurationPresenter.screen(_slice(none))
	var authored := sample()
	authored["origin"] = "authored"
	check.call("curation names the island's origin and the band it is judged against, its name from the word lists, "
			+ "and the generator's layouts a page at a time, warning that one replaces the island (13.3, 12.22)",
		c["header"] == "%s, realm level 3" % UniversePresenter.realm_name("Heart")
			and c["origin"] == "A generated layout: judged against the generated band while only curation changes it"
			and c["name"] == "Named " + SocialPresenter.word_name(FirstTests.words(), 1, 2)
			and layouts.map(func(o: Dictionary) -> String: return o["action"])
				== ["Layout 1", "Layout 2", "Layout 3", "More layouts"]
			and layouts[0]["seed"] == "11" and layouts[0]["why"] == "a layout replaces this island"
			and CurationPresenter.origin(authored) == "Authored: its terrain is your own, judged against the authored band"
			and n["origin"] == "No defence here yet: pick one of the generator's layouts" and n["name"] == "Not named yet"
			and n["layouts"][0]["action"] == "Layout 4" and n["layouts"][0]["why"] == ""
			and (n["naming"] as Dictionary).is_empty(),
		"%s | %s | %s" % [c.get("origin"), layouts, n.get("layouts")])
	var posts: Array = c["posts"]
	var i := RulebornIsland.new()
	i.read(island())
	var way := Strings.t("CUR_FACE_" + CurationPresenter.WAYS[i.facing(4, 4)])
	var picked := CurationPresenter.screen(_slice(sample(), Vector2i(4, 4)))
	var dial: Array = picked["dial"]
	check.call("each guard post is named with its role, tile and facing; a picked one gets the four-way dial, its "
			+ "own facing greyed, and a move a tile each way onto open ground only (13.3, G56)",
		posts.size() == 2 and posts[0]["action"] == "Post 1: %s at 5, 5, facing %s" % [Strings.term("ROLE", "Scout"), way]
			and (c["dial"] as Array).is_empty() and picked["posts"][0]["picked"]
			and dial.map(func(o: Dictionary) -> String: return o["action"]) == ["Face north", "Face east", "Face south",
				"Face west", "Move toward north", "Move toward east", "Move toward south", "Move toward west"]
			and not dial[i.facing(4, 4)]["can"] and dial[4]["can"] and not dial[5]["can"],
		"%s | %s" % [posts, dial])
	var slot: Dictionary = c["laws"][0]
	var previewing := CurationPresenter.screen(_slice(sample(), CurationState.NO_POST, {"slot": 1, "law": "bloom"}))
	var p: Dictionary = previewing["laws"][0]
	var poor := sample()
	poor["aether"] = 100
	var short: Dictionary = CurationPresenter.laws(poor, {"slot": 1, "law": "bloom"}, "")[0]["apply"]
	check.call("each woven law offers each swap as a free preview, one it cannot be with why; a previewed swap says so "
			+ "and weaves on a button with §5.6's price and time, which waits while the Aether is short (G54, 5.6)",
		slot["text"] == "Slot 1: Slow rivers" and slot["offers"][0]["action"] == "Preview Bloom"
			and slot["offers"][0]["can"] and not slot["offers"][1]["can"]
			and slot["offers"][1]["why"] == "not here: that law is crowned, so it cannot be woven in a realm too"
			and (slot["apply"] as Dictionary).is_empty()
			and p["preview"] == "Preview: Bloom in place of Slow rivers, free until you apply it"
			and p["apply"]["action"] == "Weave it · 160 Aether · 10 min" and p["apply"]["can"]
			and not p["offers"][0]["can"] and not short["can"] and short["why"] == "needs 160 Aether",
		"%s | %s | %s" % [slot, p, short])


func _verbs() -> void:
	var i := RulebornIsland.new()
	i.read(island())
	var grounds := func(isl: RulebornIsland) -> Array:
		var out := []
		for y in isl.side():
			for x in isl.side():
				out.append(isl.ground(x, y))
		return out
	var before: Array = grounds.call(i)
	var facing := i.facing(4, 4)
	var onto_grass := CurationPresenter.moved(i, Vector2i(4, 4), Vector2i(5, 4))
	var onto_post := CurationPresenter.moved(i, Vector2i(4, 4), Vector2i(7, 5))
	var off_grid := CurationPresenter.moved(i, Vector2i(4, 4), Vector2i(-1, 4))
	var north := CurationPresenter.moved(i, Vector2i(4, 4), Vector2i(4, 3))
	var kept := i.occupant(4, 3) == "guard:0" and i.facing(4, 3) == facing and i.occupant(4, 4) == ""
	var turned := CurationPresenter.face(i, Vector2i(4, 3), (facing + 2) % 4) and i.facing(4, 3) == (facing + 2) % 4
	var swapped := CurationPresenter.swapped(i, "slow_rivers", "bloom")
	check.call("curation's verbs move a post a tile onto open ground only, keeping its role and facing, turn it on the "
			+ "four-way dial and swap a law on its pylon, and leave the terrain as it was (13.3, G56, G54)",
		not onto_grass and not onto_post and not off_grid and north and kept and turned and swapped
			and i.occupant(9, 9) == "pylon:bloom" and Array(i.laws()) == ["bloom"] and grounds.call(i) == before
			and CurationPresenter.pylon(i, "slow_rivers") == CurationState.NO_POST,
		"%s %s %s %s %s %s %s" % [onto_grass, onto_post, off_grid, north, kept, turned, swapped])


func _flows() -> void:
	var transport := FakeTransport.new()
	var s := Fixtures.answered(Services.build(tree.root, "https://edge.example", transport,
		"user://outbox-curation-test.json"))
	s.api.token = "t"
	s.router.change = func(_path: String) -> void: pass
	transport.on("GET /v1/curation/heart", sample())
	transport.on("GET /v1/bundles/b-cur", island())
	transport.on("GET /v1/words", FirstTests.words())
	s.curation_flow.open("heart")
	await s.curation_flow.load_curation()
	var loaded: Dictionary = s.store.get_slice(CurationState.CURATION)
	s.curation_flow.pick_post(Vector2i(4, 4))
	s.curation_flow.move_post(Vector2i(1, 0))
	var refused: Dictionary = s.store.get_slice(CurationState.CURATION)
	s.curation_flow.move_post(Vector2i(0, -1))
	var at: Vector2i = s.store.get_slice(CurationState.CURATION)["post"]
	s.curation_flow.face_post(2)
	var draft: PackedByteArray = s.store.get_slice(CurationState.CURATION)["draft"]
	transport.on("PUT /v1/islands/heart", {"bundle": "b-cur2"}, 201)
	await s.curation_flow.save()
	var sent := PackedByteArray()
	for c: Dictionary in transport.calls:
		if c["route"] == "PUT /v1/islands/heart":
			sent = c["body"]
	var i := RulebornIsland.new()
	i.read(sent)
	var saved: Dictionary = s.store.get_slice(CurationState.CURATION)
	check.call("curation loads the realm's view and its island by bundle; a post moves onto open ground and not onto "
			+ "grass, turns on the dial, and a save publishes the curated island and reloads (13.3, 24.8)",
		loaded["base"] == island() and loaded["busy"] == "" and not (loaded["words"] as Dictionary).is_empty()
			and refused["error"] == "post_cannot_move" and at == Vector2i(4, 3) and sent == draft
			and i.occupant(4, 3) == "guard:0" and i.facing(4, 3) == 2 and saved["said"] == "saved"
			and transport.calls[-2]["route"] == "GET /v1/curation/heart",
		"%s %s %s %s" % [refused["error"], at, i.occupant(4, 3), saved["said"]])
	s.curation_flow.preview_swap(1, "bloom")
	var preview: Dictionary = s.store.get_slice(CurationState.CURATION)
	var shown := RulebornIsland.new()
	shown.read(preview["draft"])
	var no_call := transport.calls.filter(func(c: Dictionary) -> bool: return c["route"] == "POST /v1/weaving").is_empty()
	transport.on("POST /v1/weaving", {"weaving": {}})
	await s.curation_flow.apply_swap()
	var woven: Dictionary = {}
	var published := PackedByteArray()
	for c: Dictionary in transport.calls:
		if c["route"] == "POST /v1/weaving":
			woven = JSON.parse_string((c["body"] as PackedByteArray).get_string_from_utf8())
		if c["route"] == "PUT /v1/islands/heart":
			published = c["body"]
	var after := RulebornIsland.new()
	after.read(published)
	var laid := sample()
	laid["seed"] = "22"
	laid["island"] = "b-cur"
	transport.on("POST /v1/curation/heart/layout", laid)
	await s.curation_flow.lay("22")
	var layout_sent: Dictionary = {}
	for c: Dictionary in transport.calls:
		if c["route"] == "POST /v1/curation/heart/layout":
			layout_sent = JSON.parse_string((c["body"] as PackedByteArray).get_string_from_utf8())
	transport.on("PUT /v1/curation/heart/name", sample())
	s.curation_flow.cycle_name("noun")
	await s.curation_flow.name_island()
	var named: Dictionary = {}
	for c: Dictionary in transport.calls:
		if c["route"] == "PUT /v1/curation/heart/name":
			named = JSON.parse_string((c["body"] as PackedByteArray).get_string_from_utf8())
	check.call("a swap previews on the draft at once and free, and applying it weaves through the server as a swap "
			+ "and publishes the island with the new pylon; a layout is laid by its seed and a name sent from the "
			+ "word lists (G54, 13.3, G58)",
		shown.occupant(9, 9) == "pylon:bloom" and no_call
			and woven == {"realm": "heart", "slot": 1.0, "law": "bloom", "swap": true}
			and after.occupant(9, 9) == "pylon:bloom" and layout_sent == {"seed": "22"}
			and named == {"adjective": 0.0, "noun": 1.0}
			and s.store.get_slice(CurationState.CURATION)["said"] == "named",
		"%s %s %s %s" % [woven, layout_sent, named, s.store.get_slice(CurationState.CURATION)["said"]])
	s.close()


func _on_screen() -> void:
	var services: Services = App.services
	var screen: CurationScreen = await mount.call("curation")
	for k in 5:
		await tree.process_frame
	services.store.dispatch(&"curation_loaded", {"view": sample()})
	services.store.dispatch(&"curation_island", {"island": island()})
	services.store.dispatch(&"curation_words", {"words": FirstTests.words()})
	var find := func(key: String) -> Button:
		for b: Button in screen.find_children("*", "Button", true, false):
			if b.get_meta("key", "") == key:
				return b
		return null
	var sections := screen.body.find_children("*", "VBoxContainer", true, false).filter(
		func(b: VBoxContainer) -> bool: return b.has_meta("section")).map(
		func(b: VBoxContainer) -> String: return b.get_meta("section"))
	(find.call("post:0") as Button).pressed.emit()
	await tree.process_frame
	var dial: bool = find.call("face:2") != null and find.call("move:0") != null
	var i := RulebornIsland.new()
	i.read(island())
	(find.call("face:%d" % ((i.facing(4, 4) + 1) % 4)) as Button).pressed.emit()
	await tree.process_frame
	var unsaved: bool = find.call("save") != null and find.call("revert") != null
	(find.call("swap:1:bloom") as Button).pressed.emit()
	await tree.process_frame
	var apply: Button = find.call("apply")
	var before := apply.text
	apply.pressed.emit()
	await tree.process_frame
	var confirm: String = (find.call("apply") as Button).text
	screen.queue_free()
	await tree.process_frame
	check.call("the curation screen draws the layouts, the posts — a tap brings up the dial — each law's swaps, the "
			+ "draft's save and revert once it changes, and a swap that spends on a second tap (13.3, 23.2)",
		sections == ["layouts", "posts", "law:1", "naming"] and dial and unsaved
			and before == "Weave it · 160 Aether · 10 min" and confirm == "Tap again to spend 160 Aether",
		"%s %s %s %s %s" % [sections, dial, unsaved, before, confirm])


func _online() -> void:
	var name := "against the server: a new Keeper's Heart is offered three layouts, one is laid as generated with "
	name += "its posts, and a post turned and saved keeps it generated (13.3, 12.22)"
	if server_url == "":
		check.call(name, false, "no server: run through client/status.py, which starts one")
		return
	var s := Fixtures.answered(Services.build(tree.root, server_url, null, "user://outbox-test-curation.json"))
	s.router.change = func(_path: String) -> void: pass
	var me := await s.account.sign_in("test:curation")
	if not me.ok:
		check.call(name, false, "sign-in refused: %s" % me.code)
		s.close()
		return
	s.curation_flow.open("heart")
	await s.curation_flow.load_curation()
	var first: Dictionary = s.store.get_slice(CurationState.CURATION)["view"]
	var seeds: Array = first.get("layouts", [])
	if seeds.is_empty():
		check.call(name, false, "no layouts: %s" % [s.store.get_slice(CurationState.CURATION)["error"]])
		s.close()
		return
	await s.curation_flow.lay(str(seeds[0]))
	var laid: Dictionary = s.store.get_slice(CurationState.CURATION)
	var drawn := CurationPresenter.draft_island(laid)
	var posts := CurationPresenter.posts(drawn) if drawn != null else []
	if not posts.is_empty():
		s.curation_flow.pick_post(posts[0]["at"])
		s.curation_flow.face_post((int(posts[0]["facing"]) + 1) % 4)
		await s.curation_flow.save()
	var saved: Dictionary = s.store.get_slice(CurationState.CURATION)
	check.call(name,
		first.get("island") == null and seeds.size() == 3 and laid["view"].get("origin") == "generated"
			and not posts.is_empty() and saved["said"] == "saved" and saved["view"].get("origin") == "generated"
			and saved["view"].get("island") != laid["view"].get("island"),
		"%s | %s | %s" % [first.get("origin"), laid["error"], saved["view"]])
	s.close()
