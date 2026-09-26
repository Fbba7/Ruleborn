class_name WorkshopTests
extends RefCounted
## The Island Workshop (§18.6, §18.7, §20.7): its reducers and presenter
## headless, its flows against a FakeTransport, and — when run.gd names a
## server — a creator publishing a cleared rehearsal while another player
## finds it, plays it on the heist screen, and rates it.

var tree: SceneTree
var check: Callable
var server_url := ""


func _init(t: SceneTree, c: Callable, url: String) -> void:
	tree = t
	check = c
	server_url = url


func run() -> void:
	_reducers()
	_cards()
	_publishable()
	_settled()
	await _curated()
	await _remix_named()
	await _origin_gone()
	await _latest_list()
	await _two_players()


func _item(over := {}) -> Dictionary:
	var i := {"id": "i1", "bundle": "b1", "realmLevel": 3, "name": {"en": "Quiet Harbour", "pt_BR": "Porto Silencioso"},
		"creator": "ffee0011", "creatorLevel": "builder", "remixOf": null, "completions": 1512.25, "remixes": 7,
		"ratings": {"count": 3, "fun": 4.5, "cleverness": 3.0, "fairness": 5.0}, "featured": true,
		"withdrawn": false, "removed": null}
	i.merge(over, true)
	return i


func _reducers() -> void:
	var store := Store.new()
	WorkshopState.register(store)
	store.dispatch(&"workshop_listed", {"list": "new", "items": [_item()]})
	store.dispatch(&"workshop_asked")
	store.dispatch(&"workshop_failed", {"code": "no_such_island"})
	var failed: Dictionary = store.get_slice(WorkshopState.WORKSHOP)
	store.dispatch(&"workshop_playing", {"item": _item()})
	store.dispatch(&"workshop_done", {"what": "played", "answer": {"validated": true, "cleared": true}})
	var played: Dictionary = store.get_slice(WorkshopState.WORKSHOP)
	store.dispatch(&"workshop_asked")
	var asked: Dictionary = store.get_slice(WorkshopState.WORKSHOP)
	check.call("the Workshop reducers keep the list on show when a call fails and name the failure, keep the island "
			+ "played for rating, and a new call clears what the last one said",
		failed["list"] == "new" and failed["items"].size() == 1 and failed["error"] == "no_such_island"
			and not failed["busy"] and played["played"]["id"] == "i1" and played["done"] == "played"
			and played["error"] == "" and asked["done"] == "" and asked["busy"],
		"%s | %s | %s" % [failed, played, asked])


func _cards() -> void:
	var me := "a1b2c3d4"
	var got := {}
	for locale: String in Strings.LOCALES:
		Strings.set_locale(locale)
		got[locale] = WorkshopPresenter.item(_item(), me)
	Strings.set_locale("en")
	var c: Dictionary = got["en"]
	var gone := WorkshopPresenter.item(_item({"creator": null, "ratings": {"count": 0}, "featured": false,
		"withdrawn": true, "removed": {"at": 1, "reason": "copied"}}), me)
	var own := WorkshopPresenter.item(_item({"creator": me}), me)
	var screen := WorkshopPresenter.screen({"list": "mine", "items": [_item({"creator": me})], "curated": true,
		"loaded": true, "ladder": {"level": "builder", "completions": 1.25, "featured": 0}}, me)
	var empty := WorkshopPresenter.screen({"list": "top", "items": [], "loaded": true}, me)
	check.call("a Workshop card reads the island's name in the player's language, its realm level, completions "
			+ "(a quarter from the creator's constellation), remixes and ratings, and who made it; a deleted "
			+ "creator is no one (F43), a withdrawn or removed island says so and offers nothing; a 13-to-15 sees "
			+ "only the featured list and their own; the creator's level shows on their own list (§18.6, §18.7, §20.7)",
		c["title"].contains("Quiet Harbour") and c["title"].contains("3") and got["pt_BR"]["name"] == "Porto Silencioso"
			and c["stats"] == Strings.t("WORKSHOP_STATS", ["1,512.25", "7"])
			and c["ratings"] == Strings.t("WORKSHOP_RATINGS", ["4.5", "3.0", "5.0", "3"])
			and got["pt_BR"]["stats"].contains("1.512,25")
			and c["by"] == Strings.t("SOCIAL_KEEPER", "FFEE") and c["featured"] != "" and c["listed"]
			and gone["by"] == Strings.t("WORKSHOP_BY_NOBODY") and gone["ratings"] == Strings.t("WORKSHOP_UNRATED")
			and gone["removed"].contains(Strings.t("REMOVAL_COPIED")) and gone["withdrawn"] != "" and not gone["listed"]
			and own["mine"] and own["by"] == Strings.t("WORKSHOP_BY_YOU")
			and screen["tabs"] == ["featured", "mine"] and screen["ladder"].contains(Strings.t("CREATOR_BUILDER"))
			and screen["ladder"].contains("1.25") and empty["empty"] and empty["tabs"].size() == 4,
		"%s | %s | %s | %s" % [c, gone, screen, got["pt_BR"]])


func _publishable() -> void:
	var words := {"adjectives": [{"en": "Quiet", "pt_BR": {"m": "Silencioso", "f": "Silenciosa"}}],
		"nouns": [{"en": "Harbour", "pt_BR": "Porto", "gender": "m"}]}
	var w := {"words": words}
	var cleared := {"testing": true, "replay": PackedByteArray([1]), "verdict": {"ok": true, "grade": "Clean",
		"banked": 3}, "published": false}
	var foiled := cleared.duplicate()
	foiled["verdict"] = {"ok": true, "grade": "Foiled", "banked": 0}
	var empty := cleared.duplicate()
	empty["verdict"] = {"ok": true, "grade": "Clean", "banked": 0}
	var raid := cleared.duplicate()
	raid["testing"] = false
	var done := cleared.duplicate()
	done["published"] = true
	var p := WorkshopPresenter.publishing(cleared, w, 0, 0)
	check.call("a rehearsal may be published only once it clears the island — loot banked and out, as the server "
			+ "judges — and only once; a raid is never offered; the name is made from the word lists (§18.6)",
		p["can"] and p["name"] == "Quiet Harbour" and p["named"]
			and not WorkshopPresenter.publishing(foiled, w, 0, 0)["can"]
			and not WorkshopPresenter.publishing(empty, w, 0, 0)["can"]
			and not WorkshopPresenter.publishing(raid, w, 0, 0)["can"]
			and not WorkshopPresenter.publishing(done, w, 0, 0)["can"],
		str(p))


func _settled() -> void:
	var local := {"ok": true, "grade": "Clean", "banked": 3}
	var waiting := WorkshopController.settled(Result.success({"pending": true}), local)
	var counted := WorkshopController.settled(Result.success({"validated": true, "cleared": true, "counted": true,
		"verdict": {"grade": "clean", "banked": 3}}), local)
	var again := WorkshopController.settled(Result.success({"validated": true, "cleared": true, "counted": false,
		"repeated": true, "verdict": {"grade": "clean", "banked": 3}}), local)
	var wrong := WorkshopController.settled(Result.success({"validated": false, "reason": "wrong_seed"}), local)
	var refused := WorkshopController.settled(Result.failure("play_refused"), local)
	check.call("a Workshop play's answer reads as cleared and counted, or already counted, by the server; one still "
			+ "waiting shows the phone's own check as confirming; a play the server did not accept names why (§18.7, §24.12)",
		waiting["confirming"] and waiting["workshop"] and WorkshopController.clears(waiting)
			and counted["server"] and counted["cleared"] and counted["counted"] and counted["grade"] == "Clean"
			and not again["counted"] and WorkshopController.clears(again)
			and not wrong["ok"] and wrong["refused"] == "wrong_seed" and refused["refused"] == "play_refused"
			and Errors.text("play_refused") != Strings.t("ERR_UNKNOWN", "play_refused"),
		"%s | %s | %s | %s" % [waiting, counted, wrong, refused])


func _fake() -> Array:
	var transport := FakeTransport.new()
	var s := Fixtures.answered(Services.build(tree.root, "https://edge.example", transport,
		"user://outbox-workshop-test.json"))
	s.router.change = func(_path: String) -> void: pass
	s.api.token = "t"
	return [s, transport]


## §20.7: the server refuses a 13-to-15 every list but the featured one; the
## screen shows the featured list and offers only it and their own.
func _curated() -> void:
	var f := _fake()
	var s: Services = f[0]
	var transport: FakeTransport = f[1]
	transport.then("GET /v1/workshop", [[{"error": "curated_lists_only"}, 403]])
	transport.on("GET /v1/workshop", [_item()])
	await s.workshop_flow.show_list("top")
	var slice: Dictionary = s.store.get_slice(WorkshopState.WORKSHOP)
	var screen := WorkshopPresenter.screen(slice, "")
	var asked := transport.calls.filter(func(c: Dictionary) -> bool: return c["route"] == "GET /v1/workshop") \
		.map(func(c: Dictionary) -> String: return c["url"])
	check.call("a player aged 13 to 15, refused the top list, is shown the featured list and offered only it and "
			+ "their own islands, with no failure shown (§20.7)",
		slice["list"] == "featured" and slice["curated"] and slice["error"] == "" and screen["items"].size() == 1
			and screen["tabs"] == ["featured", "mine"] and asked.size() == 2 and asked[0].contains("list=top")
			and asked[1].contains("list=featured"),
		"%s | %s" % [slice, asked])
	s.close()


## §18.6: a remix becomes the builder's draft, and its publication names the
## original, once; the draft is its own island after that.
func _remix_named() -> void:
	var f := _fake()
	var s: Services = f[0]
	var transport: FakeTransport = f[1]
	var bytes := PackedByteArray([82, 66, 73, 1, 3])
	transport.on("POST /v1/workshop/orig1/remix", bytes)
	transport.on("POST /v1/workshop", _item({"id": "new1", "remixOf": "orig1"}), 201)
	transport.on("GET /v1/workshop/mine", [_item({"id": "new1", "remixOf": "orig1"})])
	var own := PackedByteArray([82, 66, 73, 1, 1])
	Draft.keep(own)
	var kept := await s.workshop_flow.remix("orig1")
	var drafted := Draft.island() == bytes and Draft.remix_of() == "orig1" and Draft.has_kept()
	# Swapped back and forth: the player's own island, then the remix again.
	var swapped := Draft.restore() and Draft.island() == own and Draft.remix_of() == "" and Draft.restore() \
		and Draft.island() == bytes and Draft.remix_of() == "orig1"
	s.store.dispatch(&"heist_started", {"island": bytes, "testing": true})
	s.store.dispatch(&"heist_finished", {"replay": PackedByteArray([9]), "verdict": {"ok": true, "grade": "Clean",
		"banked": 3}})
	var published := await s.workshop_flow.publish(bytes, PackedByteArray([9]), 1, 9)
	var sent: Dictionary = JSON.parse_string((transport.calls.filter(func(c: Dictionary) -> bool:
		return c["route"] == "POST /v1/workshop")[0]["body"] as PackedByteArray).get_string_from_utf8())
	var slice: Dictionary = s.store.get_slice(WorkshopState.WORKSHOP)
	check.call("a remixed island becomes the builder's draft, the player's own island kept to swap back, never "
			+ "overwritten; publishing it names the original once; after, the draft is its own island, the rehearsal "
			+ "is not offered again, and the player's own list shows (§18.6)",
		kept and drafted and swapped and published and sent["remixOf"] == "orig1" and int(sent["adjective"]) == 1
			and int(sent["noun"]) == 9 and Draft.remix_of() == "" and s.store.get_slice(AppState.HEIST)["published"]
			and slice["list"] == "mine" and slice["done"] == "published"
			and WorkshopPresenter.said(slice).contains("Quiet Harbour"),
		"%s %s %s %s | %s | %s" % [kept, drafted, swapped, published, sent, slice])
	DirAccess.remove_absolute(Draft.path)
	Draft.forget_origin()
	DirAccess.remove_absolute(Draft.path.get_basename() + "-kept.rbi")
	DirAccess.remove_absolute(Draft.path.get_basename() + "-kept-remix.txt")
	s.close()


## §18.6: an original removed since cannot be named, and the island is not
## refused for ever: it is published as the player's own.
func _origin_gone() -> void:
	var f := _fake()
	var s: Services = f[0]
	var transport: FakeTransport = f[1]
	Draft.start_remix(PackedByteArray([1, 2]), "gone1")
	transport.then("POST /v1/workshop", [[{"error": "no_such_island"}, 404]])
	transport.on("POST /v1/workshop", _item({"id": "own1"}), 201)
	transport.on("GET /v1/workshop/mine", [_item({"id": "own1"})])
	var published := await s.workshop_flow.publish(PackedByteArray([1, 2]), PackedByteArray([9]), 0, 0)
	var bodies := transport.calls.filter(func(c: Dictionary) -> bool: return c["route"] == "POST /v1/workshop") \
		.map(func(c: Dictionary) -> Dictionary:
			return JSON.parse_string((c["body"] as PackedByteArray).get_string_from_utf8()))
	check.call("a remix whose original was removed since is published as the player's own island, not refused "
			+ "for ever (§18.6)",
		published and bodies.size() == 2 and bodies[0].get("remixOf") == "gone1" and not bodies[1].has("remixOf")
			and Draft.remix_of() == "",
		"%s %s" % [published, bodies])
	DirAccess.remove_absolute(Draft.path)
	s.close()


## Two lists asked for in turn: the screen ends on the second, and the first's
## late answer is dropped.
func _latest_list() -> void:
	var f := _fake()
	var s: Services = f[0]
	var transport: FakeTransport = f[1]
	transport.then("GET /v1/workshop", [[[_item({"id": "from-new"})], 200], [[_item({"id": "from-featured"})], 200]])
	s.workshop_flow.show_list("new")
	await s.workshop_flow.show_list("featured")
	await tree.process_frame
	var slice: Dictionary = s.store.get_slice(WorkshopState.WORKSHOP)
	check.call("only the list asked for last is shown: tapping one list and then another ends on the second",
		slice["list"] == "featured" and slice["items"].size() == 1 and slice["items"][0]["id"] == "from-featured"
			and not slice["busy"],
		str(slice))
	s.close()


func _player(credential: String) -> Array:
	var s := Fixtures.answered(Services.build(tree.root, server_url, null,
		"user://outbox-%s.json" % credential.replace(":", "-")))
	s.router.change = func(_path: String) -> void: pass
	var me := await s.account.sign_in(credential)
	if me.ok:
		s.store.dispatch(&"signed_in", {"account": me.value["account"]})
	return [s, me]


## A heist screen on `services`, played to its end on the open Heart's plan.
func _played(services: Services, ticks: int) -> Dictionary:
	App.services = services
	var screen: HeistScreen = load("res://scenes/heist_screen.tscn").instantiate()
	tree.root.add_child(screen)
	screen.set_process(false)
	await tree.process_frame
	Plans.open_heart(screen, ticks)
	var heist: Dictionary = services.store.get_slice(AppState.HEIST)
	if heist["verdict"].is_empty() or (not heist["workshop"].is_empty() and not heist["verdict"].get("server", false)
			and not heist["verdict"].get("confirming", false)):
		await screen.finished
	screen.queue_free()
	return services.store.get_slice(AppState.HEIST)


func _two_players() -> void:
	var name := "against the server: a creator rehearses an island on the heist screen, clears it and publishes it "
	name += "named from the word lists; another player finds it among the new islands, plays it on the heist "
	name += "screen, clears it, sees the clear counted and rates it; the creator withdraws it and it leaves the "
	name += "lists (§18.6, §18.7)"
	if server_url == "":
		check.call(name, false, "no server: run through client/status.py, which starts one")
		return
	var before: Services = App.services
	var a: Array = await _player("test:workshop-a")
	var b: Array = await _player("test:workshop-b")
	var sa: Services = a[0]
	var sb: Services = b[0]
	if not a[1].ok or not b[1].ok:
		check.call(name, false, "sign-in refused: %s %s" % [a[1].code, b[1].code])
		sa.close()
		sb.close()
		return
	# An adult, who may browse every list; a new account is held to the most
	# protective band until the age check answers (§20.1, §20.7).
	await sb.account.set_age_band("18+")
	# The creator's island: the example Heart the server publishes.
	var target := await sa.heists.first_target(str(a[1].value["account"]))
	var island := PackedByteArray()
	if target.ok:
		var fetched := await sa.heists.fetch(str(target.value["bundle"]))
		if fetched.ok:
			island = fetched.value
	sa.store.dispatch(&"heist_started", {"island": island, "testing": true})
	var rehearsed := await _played(sa, HeistController.TICKS)
	await sa.workshop_flow.load_words()
	var offer := WorkshopPresenter.publishing(rehearsed, sa.store.get_slice(WorkshopState.WORKSHOP), 1, 9)
	var published := await sa.workshop_flow.publish(rehearsed["island"], rehearsed["replay"], 1, 9)
	var mine: Array = sa.store.get_slice(WorkshopState.WORKSHOP)["items"]
	var id := str(mine[-1]["id"]) if not mine.is_empty() else ""
	await sb.workshop_flow.show_list("new")
	var listed := (sb.store.get_slice(WorkshopState.WORKSHOP)["items"] as Array).any(
		func(i: Dictionary) -> bool: return str(i["id"]) == id)
	var heist := await sb.workshop_flow.play(id)
	var started := not heist.is_empty()
	var played := {}
	if started:
		sb.workshop_flow.start(heist)
		played = await _played(sb, int(sb.store.get_slice(AppState.HEIST)["workshop"].get("ticks", 0)))
	var v: Dictionary = played.get("verdict", {})
	await sb.workshop_flow.rate(id, 5, 4, 3)
	var rated: Dictionary = sb.store.get_slice(WorkshopState.WORKSHOP)
	await sa.workshop_flow.withdraw(id)
	var gone: Dictionary = sa.store.get_slice(WorkshopState.WORKSHOP)
	await sb.workshop_flow.show_list("new")
	var still := (sb.store.get_slice(WorkshopState.WORKSHOP)["items"] as Array).any(
		func(i: Dictionary) -> bool: return str(i["id"]) == id)
	check.call(name,
		a[1].ok and b[1].ok and offer["can"] and offer["name"] != "" and published and id != "" and listed and started
			and v.get("server", false) and v.get("workshop", false) and v.get("cleared", false)
			and v.get("counted", false) and rated["done"] == "rated" and int(rated["last"].get("count", 0)) == 1
			and gone["done"] == "withdrawn"
			and (gone["items"] as Array).any(func(i: Dictionary) -> bool: return i["id"] == id and i["withdrawn"])
			and not still,
		"offer %s, published %s, id %s, listed %s, played %s, rated %s, gone %s, still %s"
			% [offer, published, id, listed, v, rated, gone.get("done"), still])
	App.services = before
	sa.close()
	sb.close()
