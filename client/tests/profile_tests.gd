class_name ProfileTests
extends RefCounted
## The Profile and stats (§18.5, §20.2, §23.2; TD.24): its words headless, the
## flows through a FakeTransport, the screen as drawn, and the profile
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
	await _flows()
	await _on_screen()
	await _online()


## A profile as GET /v1/profile answers for an adult, private.
static func sample() -> Dictionary:
	var records := []
	for id: String in ["fastest_escape", "fewest_alarms", "most_guards_slept_past", "fewest_caught", "most_realms",
			"biggest_haul", "longest_defence", "favourite_edge", "favourite_law", "minutes_a_day"]:
		records.append({"id": id, "value": null})
	records[0]["value"] = 50000
	records[3]["value"] = 0
	records[5]["value"] = 1840
	records[6]["value"] = 140000
	return {"keeper_level": 7,
		"renown": {"season": 3, "renown": 1250, "league": "ember", "division": 2, "next": 1500},
		"seasons": [{"season": 2, "renown": 980, "league": "dust"}],
		"heists": {"clean": 4, "loud": 2, "partial": 1, "foiled": 3},
		"defences": {"held": 5, "leaked": 2, "partial": 1},
		"records": records,
		"badges": [{"id": "first_heist", "count": 10, "mark": 1, "grade": "gold"},
			{"id": "ghost", "count": 26, "mark": 50, "grade": "silver"},
			{"id": "hoarder", "count": 600, "mark": 5000, "grade": "bronze"},
			{"id": "paradox", "count": 0, "mark": 1, "grade": null}],
		"titles": [{"school": "Motion", "steps": 4, "total": 12, "titles": 1}],
		"log": [{"heist": "h2", "island": "b2", "at": 2, "mode": "raid", "grade": "clean", "haul": 1840, "replay": "kept"},
			{"heist": "h1", "island": "b1", "at": 1, "mode": "raid", "grade": "foiled", "haul": 0, "replay": "gone"}],
		"band": "18+", "public": false, "can_share": true}


func _words() -> void:
	var p := ProfilePresenter.screen({"view": sample(), "busy": "", "error": ""})
	check.call("the profile shows Renown and league over time and never a rating, heists by each outcome's name, and "
			+ "defences held and leaked with Partial apart (12.9, 12.15, 23.2)",
		p["header"].begins_with("Keeper level 7 · ") and (p["renown"] as Array).size() == 2
			and p["renown"][1] == "Season 2: Renown 980, Dust"
			and p["heists"] == "Heists: Clean 4, Loud 2, Partial 1, Foiled 3"
			and p["defences"] == "Defences: held 5, leaked 2 (1 partial)" and not str(p).to_lower().contains("rating"),
		"%s | %s | %s" % [p.get("header"), p.get("renown"), p.get("heists")])
	var r: Array = p["records"]
	check.call("the profile's ten records say each value, times as a clock, and a record with no fact yet says so "
			+ "(13.2, 23.2)",
		r.size() == 10 and r[0] == "Fastest escape: 0:50" and r[3] == "Fewest crew caught: 0"
			and r[5] == "Biggest haul: 1,840" and r[6] == "Longest defence held: 2:20"
			and r[1] == "Fewest alarms in a heist: not recorded yet",
		"%s" % [r])
	check.call("each badge shows its count against its mark and the grade reached, and titles come from mastery "
			+ "only (18.5)",
		p["badges"] == ["First heist: 10 of 1 · gold", "Ghost: 26 of 50 · silver", "Hoarder: 600 of 5,000 · bronze",
			"Paradox: 0 of 1 · not yet"]
			and p["titles"] == ["Motion: 1 titles, 4 of 12 mastery steps"],
		"%s | %s" % [p["badges"], p["titles"]])
	var minor := sample()
	minor["band"] = "13-15"
	minor["can_share"] = false
	var m := ProfilePresenter.screen({"view": minor})
	var shown := sample()
	shown["public"] = true
	var s := ProfilePresenter.screen({"view": shown})
	check.call("the battle log offers each heist's replay while it is kept; a 13-to-15 profile is locked private with "
			+ "no sharing, and anyone else's switch shows or hides it (20.2, 23.2)",
		p["log"][0]["text"] == "Clean heist · haul 1,840" and not (p["log"][0]["watch"] as Dictionary).is_empty()
			and p["log"][1]["text"].ends_with(" · replay gone") and (p["log"][1]["watch"] as Dictionary).is_empty()
			and m["share"] == {"locked": "Your profile stays private at your age, with no sharing"}
			and p["share"]["button"]["action"] == "Show my profile" and p["share"]["button"]["on"]
			and s["share"]["state"] == "Other players can see your profile" and not s["share"]["button"]["on"],
		"%s | %s" % [m["share"], s["share"]])


func _flows() -> void:
	var transport := FakeTransport.new()
	var s := Fixtures.answered(Services.build(tree.root, "https://edge.example", transport,
		"user://outbox-profile-test.json"))
	s.api.token = "t"
	transport.on("GET /v1/profile", sample())
	await s.profile_flow.load_profile()
	var shown := sample()
	shown["public"] = true
	transport.on("PUT /v1/profile", shown)
	await s.profile_flow.share(true)
	var sent: Dictionary = JSON.parse_string((transport.calls[-1]["body"] as PackedByteArray).get_string_from_utf8())
	var after: Dictionary = s.store.get_slice(ProfileState.PROFILE)
	transport.on("PUT /v1/profile", {"error": "profile_private_at_this_age"}, 409)
	await s.profile_flow.share(true)
	var refused: Dictionary = s.store.get_slice(ProfileState.PROFILE)
	check.call("the profile is fetched, its switch is sent to the server, and a refusal keeps the profile on show and "
			+ "says why (20.2)",
		sent == {"public": true} and after["view"]["public"] == true and refused["error"] == "profile_private_at_this_age"
			and ProfilePresenter.screen(refused)["error"]
				== "The profile could not answer: at your age your profile stays private",
		"%s %s" % [sent, refused["error"]])
	s.close()


func _on_screen() -> void:
	var services: Services = App.services
	var screen: ProfileScreen = await mount.call("profile")
	for i in 5:
		await tree.process_frame
	services.store.dispatch(&"profile_loaded", {"view": sample()})
	var heists := screen.body.find_children("*", "Label", true, false).filter(
		func(l: Label) -> bool: return l.has_meta("heist")).map(func(l: Label) -> String: return l.get_meta("heist"))
	var keys := screen.find_children("*", "Button", true, false).map(
		func(b: Button) -> String: return str(b.get_meta("key", ""))).filter(func(k: String) -> bool: return k != "")
	screen.queue_free()
	await tree.process_frame
	check.call("the profile screen draws the record, the battle log with its replays and the visibility switch (23.2)",
		heists == ["h2", "h1"] and keys == ["watch:h2", "share"], "%s %s" % [heists, keys])


func _online() -> void:
	var name := "against the server: a new Keeper's profile is private, with no heists or defences, the starting "
	name += "laws a bronze Law hunter and no first heist yet (18.5, 20.2)"
	if server_url == "":
		check.call(name, false, "no server: run through client/status.py, which starts one")
		return
	var s := Fixtures.answered(Services.build(tree.root, server_url, null, "user://outbox-test-profile.json"))
	s.router.change = func(_path: String) -> void: pass
	var me := await s.account.sign_in("test:profile")
	if not me.ok:
		check.call(name, false, "sign-in refused: %s" % me.code)
		s.close()
		return
	await s.profile_flow.load_profile()
	var v: Dictionary = s.store.get_slice(ProfileState.PROFILE)["view"]
	var badges := {}
	for b: Dictionary in v.get("badges", []):
		badges[b["id"]] = b.get("grade")
	var none := ["clean", "loud", "partial", "foiled"].all(func(g: String) -> bool:
		return int((v.get("heists", {}) as Dictionary).get(g, -1)) == 0)
	check.call(name,
		v.get("public") == false and none and badges.get("law_hunter") == "bronze" and badges.get("first_heist") == null
			and (v.get("records", []) as Array).size() == 10,
		"%s %s" % [badges, v.get("heists")])
	s.close()
