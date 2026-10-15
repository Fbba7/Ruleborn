class_name ShareTests
extends RefCounted
## The share sheet (§17.6, §20.7, §23.2): its words by age band, the
## challenge link made and copied through a FakeTransport, the screen as
## drawn, and a link made against the server when one is named.

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
	await _on_screen()
	await _online()


func _words() -> void:
	var minor := SharePresenter.limits("13-15")
	var teen := SharePresenter.limits("16-17")
	var adult := SharePresenter.limits("18+")
	check.call("the share sheet says §20.7's limits for the player's band: a 13-to-15's challenge to in-game friends "
			+ "only and no clip outside the game, a 16-to-17's clip after a confirmation, an adult's anywhere (20.7)",
		minor == ["Challenges go to your in-game friends only", "Clips stay in the game"]
			and teen == ["Challenges go to anyone who has the code", "A clip leaves the game only after you confirm"]
			and adult[1] == "Clips can be shared anywhere",
		"%s | %s | %s" % [minor, teen, adult])
	var none := SharePresenter.screen({}, "18+")
	var made := SharePresenter.screen({"link": {"challenge": "a1b2c3", "bundle": "b"}, "copied": true}, "18+")
	check.call("before a link is made the sheet offers to make one; once made it shows the code and how a friend "
			+ "opens it, and says when it was copied; nothing posts to the Beacon or grades a moment (17.6, 23.2)",
		none["link"] == "No challenge link yet" and (none["copy"] as Dictionary).is_empty()
			and made["link"] == "Challenge me in Ruleborn: open Friends and enter the code a1b2c3"
			and made["copied"] == "Copied" and not str(made).contains("Beacon") and not str(made).to_lower().contains("grade"),
		"%s | %s" % [none["link"], made["link"]])


func _flows() -> void:
	var transport := FakeTransport.new()
	var s := Fixtures.answered(Services.build(tree.root, "https://edge.example", transport,
		"user://outbox-share-test.json"))
	s.api.token = "t"
	var pasted: Array[String] = []
	s.share_flow.clipboard = func(text: String) -> void: pasted.append(text)
	transport.on("POST /v1/challenges", {"challenge": "c0ffee", "bundle": "b", "expiresAt": 1}, 201)
	await s.share_flow.make_link()
	s.share_flow.copy()
	var slice: Dictionary = s.store.get_slice(ShareState.SHARE)
	transport.on("POST /v1/challenges", {"error": "no_island_to_share"}, 404)
	await s.share_flow.make_link()
	var refused: Dictionary = s.store.get_slice(ShareState.SHARE)
	check.call("a challenge link is made by the server and its code copied to paste; a refusal says why (17.6)",
		slice["link"].get("challenge") == "c0ffee" and slice["copied"]
			and pasted == ["Challenge me in Ruleborn: open Friends and enter the code c0ffee"]
			and refused["error"] == "no_island_to_share"
			and SharePresenter.screen(refused, "18+")["error"].ends_with("you have no island to share yet"),
		"%s %s %s" % [slice, pasted, refused["error"]])
	transport.on("POST /v1/friends/invites", {"invite": "f00d", "expiresAt": 1}, 201)
	await s.share_flow.make_invite()
	s.share_flow.copy("invite")
	var invited: Dictionary = s.store.get_slice(ShareState.SHARE)
	var sheet := SharePresenter.screen(invited, "18+")
	var won := HeistController.settled(Result.success({"validated": true, "verdict": {"grade": "clean", "banked": 10},
		"haul": {"total": 40}, "fee": 0, "inviteGift": {"cosmetic": "invite-gift", "friends": 1}}), {})
	check.call("a personal invite is made by the server and its code copied, with the matching cosmetic it brings "
			+ "both players at the friend's first heist, which the result then names (17.6)",
		invited["invite"].get("invite") == "f00d" and pasted[-1] == "Join me in Ruleborn: open Friends and enter the "
			+ "invite f00d" and sheet["gift"] == "Invite a friend: you both get a matching cosmetic when they play their "
			+ "first heist" and not (sheet["copy_invite"] as Dictionary).is_empty() and won["gift"]
			and not HeistController.settled(Result.success({"validated": true, "verdict": {"grade": "clean",
				"banked": 10}, "haul": {"total": 40}, "fee": 0}), {})["gift"],
		"%s %s %s" % [invited["invite"], pasted, sheet.get("gift")])
	s.close()


func _on_screen() -> void:
	var services: Services = App.services
	services.store.dispatch(&"share_link", {"link": {"challenge": "a1b2c3", "bundle": "b"}})
	var screen: ShareScreen = await mount.call("share")
	await tree.process_frame
	var keys := screen.find_children("*", "Button", true, false).map(
		func(b: Button) -> String: return str(b.get_meta("key", ""))).filter(func(k: String) -> bool: return k != "")
	var shown := screen.body.find_children("*", "Label", true, false).filter(
		func(l: Label) -> bool: return l.has_meta("link")).map(func(l: Label) -> String: return l.text)
	screen.queue_free()
	await tree.process_frame
	check.call("the share sheet screen draws the link's code with Make and Copy, and the band's limits (23.2)",
		keys == ["make", "copy", "invite"] and shown == ["Challenge me in Ruleborn: open Friends and enter the code a1b2c3"],
		"%s %s" % [keys, shown])


func _online() -> void:
	var name := "against the server: a Keeper with a published island makes a challenge link whose code opens that "
	name += "island (17.6)"
	if server_url == "":
		check.call(name, false, "no server: run through client/status.py, which starts one")
		return
	var s := Fixtures.answered(Services.build(tree.root, server_url, null, "user://outbox-test-share.json"))
	s.router.change = func(_path: String) -> void: pass
	var me := await s.account.sign_in("test:share")
	if not me.ok:
		check.call(name, false, "sign-in refused: %s" % me.code)
		s.close()
		return
	var island := LandingTests.island(false)
	var published := await s.api.raw(HTTPClient.METHOD_PUT, "/v1/islands/heart", island)
	await s.share_flow.make_link()
	var link: Dictionary = s.store.get_slice(ShareState.SHARE)["link"]
	var opened := await s.friends.open_challenge(str(link.get("challenge", "")))
	check.call(name,
		published.ok and str(link.get("challenge", "")).length() == 12 and opened.ok
			and str(opened.value.get("bundle", "")) == str(link.get("bundle", "-")),
		"%s %s %s" % [published.code, link, opened.code])
	s.close()
