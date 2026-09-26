class_name SocialTests
extends RefCounted
## The league, constellations, crews and friends (§12.11, §17, §18.1):
## reducers and presenters headless, flows against a FakeTransport, and two
## players against the real server when run.gd names one.

var tree: SceneTree
var check: Callable
var server_url := ""


func _init(t: SceneTree, c: Callable, url: String) -> void:
	tree = t
	check = c
	server_url = url


func run() -> void:
	_reducers()
	_words()
	_names()
	await _refusals()
	await _two_players()


func _reducers() -> void:
	var store := Store.new()
	SocialState.register(store)
	store.dispatch(&"groups_loaded", {"constellation": null, "crew": {"id": "c1", "invite": "ab12", "members": [],
		"formed": false}})
	store.dispatch(&"groups_failed", {"code": "keeper_level_too_low"})
	var g: Dictionary = store.get_slice(SocialState.GROUPS)
	store.dispatch(&"friend_accepted", {"friend": "acc9"})
	store.dispatch(&"invite_made", {"invite": {"invite": "i1"}})
	store.dispatch(&"challenge_made", {"challenge": {"challenge": "c1"}})
	var last := SocialPresenter.friends(store.get_slice(SocialState.FRIENDS), "")
	store.dispatch(&"crew_changed", {"crew": null})
	var after: Dictionary = store.get_slice(SocialState.GROUPS)
	check.call("the league, groups and friends reducers keep what they had when a call fails, name the failure, "
			+ "read a null group as none, and the friends screen shows the latest outcome, not an older one",
		g["constellation"] == {} and g["crew"]["invite"] == "ab12" and g["error"] == "keeper_level_too_low"
			and g["known"] and after["crew"] == {} and store.get_slice(SocialState.FRIENDS)["accepted"] == "acc9"
			and last["last"] == "challenge" and last["challenge"].contains("c1"),
		"%s %s %s" % [g, after, last])


func _words() -> void:
	var me := "a1b2c3d4"
	var l := SocialPresenter.league({"view": {"season": 2, "renown": 1190, "league": "Tide", "division": 2,
		"floor": 176, "next": 1254}})
	var top := SocialPresenter.league({"view": {"season": 2, "renown": 900, "league": "Paradox", "division": null,
		"floor": 806, "next": null}})
	var g := SocialPresenter.groups({"known": true, "constellation": {"id": "x", "name": "Quiet Harbour",
		"members": [{"account": me, "role": "founder"}, {"account": "ffee0011", "role": "elder"}]},
		"crew": {"invite": "cafe", "members": [{"account": me}], "formed": false}}, me)
	var f := SocialPresenter.friends({"friends": [{"account": "ffee0011", "since": 1}],
		"feed": [{"raider": "ffee0011", "defender": me, "mode": "raid", "grade": "Clean"}]}, me)
	check.call("the league shows the place, the division in numerals, Renown and the way to the next league; groups "
			+ "name their members and roles, the player as \"you\"; the feed says who raided whom (§17, §18.1)",
		l["place"].contains("II") and l["renown"].contains("1,190") and l["next"].contains("64")
			and top["next"] == Strings.t("LEAGUE_TOP") and not top["place"].contains("I ")
			and g["founder"] and g["members"].size() == 2 and g["members"][0].contains(Strings.t("SOCIAL_YOU"))
			and g["crew"].contains("1") and f["friends"][0]["name"] == Strings.t("SOCIAL_KEEPER", "FFEE")
			and f["feed"][0].contains(Strings.t("SOCIAL_YOU")) and f["feed"][0].contains("Clean"),
		"%s | %s | %s | %s" % [l, top, g, f])


func _names() -> void:
	var words := {"adjectives": [{"en": "Quiet", "pt_BR": {"m": "Silencioso", "f": "Silenciosa"}}],
		"nouns": [{"en": "Harbour", "pt_BR": "Porto", "gender": "m"}, {"en": "Garden", "pt_BR": "Horta",
			"gender": "f"}]}
	var got := {}
	for locale: String in Strings.LOCALES:
		Strings.set_locale(locale)
		got[locale] = [SocialPresenter.word_name(words, 0, 0), SocialPresenter.word_name(words, 0, 1),
			SocialPresenter.named({"en": "Quiet Harbour", "pt_BR": "Porto Silencioso"})]
	Strings.set_locale("en")
	check.call("a name from the word lists reads in the player's language, as the server makes it: \"Quiet "
			+ "Harbour\", and in Portuguese the noun first with the adjective agreeing, \"Porto Silencioso\", "
			+ "\"Horta Silenciosa\" (D63)",
		got["en"] == ["Quiet Harbour", "Quiet Garden", "Quiet Harbour"]
			and got["pt_BR"] == ["Porto Silencioso", "Horta Silenciosa", "Porto Silencioso"], str(got))


func _refusals() -> void:
	var transport := FakeTransport.new()
	var s := Services.build(tree.root, "https://edge.example", transport, "user://outbox-social-test.json")
	transport.on("POST /v1/constellations", {"error": "keeper_level_too_low", "needs": 6}, 403)
	transport.on("POST /v1/friends/accept", {"error": "no_such_invite"}, 404)
	var c := SocialController.new(s)
	await c.found(0, 0)
	var g := SocialPresenter.groups(s.store.get_slice(SocialState.GROUPS), "")
	await c.accept("  nope  ")
	var f := SocialPresenter.friends(s.store.get_slice(SocialState.FRIENDS), "")
	var sent: Dictionary = JSON.parse_string((transport.calls[-1]["body"] as PackedByteArray).get_string_from_utf8())
	check.call("a refusal is shown in the player's words: founding below Keeper 6, an invite that does not exist; "
			+ "an invite code is sent without its spaces (§17.1, §17.6)",
		g["error"] == "keeper_level_too_low" and f["error"] == "no_such_invite" and sent == {"invite": "nope"}
			and Errors.text("keeper_level_too_low") != Strings.t("ERR_UNKNOWN", "keeper_level_too_low"),
		"%s %s %s" % [g["error"], f["error"], sent])
	s.close()


func _player(credential: String) -> Array:
	var s := Services.build(tree.root, server_url, null, "user://outbox-%s.json" % credential.replace(":", "-"))
	s.router.change = func(_path: String) -> void: pass
	var me := await s.account.sign_in(credential)
	if me.ok:
		s.store.dispatch(&"signed_in", {"account": me.value["account"]})
	return [s, me]


func _two_players() -> void:
	var name := "against the server, two players: one invites and the other accepts, and each lists the other; "
	name += "one starts a crew and the other joins it by its invite; the league shows this season (§12.11, §17.6, "
	name += "§17.7, §18.1)"
	if server_url == "":
		check.call(name, false, "no server: run through client/status.py, which starts one")
		return
	var a: Array = await _player("test:social-a")
	var b: Array = await _player("test:social-b")
	var sa: Services = a[0]
	var sb: Services = b[0]
	var ca := SocialController.new(sa)
	var cb := SocialController.new(sb)
	await ca.make_invite()
	var code := str(sa.store.get_slice(SocialState.FRIENDS)["invite"].get("invite", ""))
	await cb.accept(code)
	await ca.load_friends()
	var fa := SocialPresenter.friends(sa.store.get_slice(SocialState.FRIENDS), a[1].value["account"])
	var fb := SocialPresenter.friends(sb.store.get_slice(SocialState.FRIENDS), b[1].value["account"])
	await ca.start_crew()
	var invite := str(sa.store.get_slice(SocialState.GROUPS)["crew"].get("invite", ""))
	await cb.join_crew(invite)
	await ca.load_groups()
	var ga := SocialPresenter.groups(sa.store.get_slice(SocialState.GROUPS), a[1].value["account"])
	await ca.load_league()
	var l := SocialPresenter.league(sa.store.get_slice(SocialState.LEAGUE))
	check.call(name,
		a[1].ok and b[1].ok and code != "" and fa["friends"].size() == 1 and fb["friends"].size() == 1
			and fa["friends"][0]["account"] == b[1].value["account"] and ga["in_crew"]
			and ga["crew_members"].size() == 2 and ga["crew_invite"] == invite and l["ready"]
			and l["renown"].contains(str(int(sa.store.get_slice(SocialState.LEAGUE)["view"].get("season", -1)))),
		"%s | %s | %s | %s" % [fa, fb, ga, l])
	sa.close()
	sb.close()
