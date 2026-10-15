class_name FirstTests
extends RefCounted
## The first launch (§20.1, §20.2, §23.2; TD.26): its words by band, its beats
## kept on the phone through a FakeTransport, the screen as drawn, and the
## Keeper's name reaching the server once the account is made.

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
	await _beats()
	await _on_screen()
	await _online()


static func protections() -> Dictionary:
	return {"13-15": {"night": [21, 8], "cap": 25}, "16-17": {"night": [22, 8], "cap": 50},
		"18+": {"night": [22, 8], "cap": null}}


static func words() -> Dictionary:
	var w := HatchTests.words()
	return w


func _words() -> void:
	var minor := FirstPresenter.protections("13-15", protections())
	var teen := FirstPresenter.protections("16-17", protections())
	var adult := FirstPresenter.protections("18+", protections())
	check.call("the first launch sums up §20.2's protections for the band the age check answered, with its quiet "
			+ "night and spending cap as the server holds them (20.1, 20.2)",
		minor[0] == "At 13 to 15, the game keeps you safe like this:" and "No notifications from 21:00 to 8:00" in minor
			and "Spending capped at €25 a month" in minor and "Your profile is private, with no sharing" in minor
			and "Spending capped at €50 a month" in teen and "A play-time reminder you cannot turn off" in teen
			and "Notifications off from 22:00 to 8:00 unless you change it" in adult
			and adult[-1] == "No tracking and no ads",
		"%s | %s" % [minor, adult])
	var title := FirstPresenter.screen({"beat": "title"}, "")
	var name := FirstPresenter.screen({"beat": "name", "words": words(), "name": {"adjective": 1, "noun": 2}}, "18+")
	check.call("the first launch opens on the title, and asks for the Keeper's name from the word lists, saying "
			+ "raiders will see it (12.4, G58)",
		title["lines"][0] == "Ruleborn" and title["next"] == "Begin"
			and name["name"] == SocialPresenter.word_name(words(), 1, 2) and name["name"] != ""
			and name["lines"] == ["Pick your Keeper's name. Raiders will see it."],
		"%s | %s" % [title, name.get("name")])


func _beats() -> void:
	var transport := FakeTransport.new()
	var path := "user://outbox-first-test.json"
	DirAccess.remove_absolute(path.get_basename() + "-first.json")
	DirAccess.remove_absolute(path.get_basename() + "-age.json")
	var s := Services.build(tree.root, "https://edge.example", transport, path)
	var routes: Array[StringName] = []
	s.router.change = func(p: String) -> void: routes.append(StringName(p.get_file().get_basename()))
	transport.on("GET /v1/protections", protections())
	transport.on("GET /v1/words", words())
	var start := s.first.beat()
	await s.first_flow.resume()
	await s.first_flow.next()                       # the title done: the age check next
	var to_age := &"age" in routes and s.first.beat() == "age"
	s.age.answer("16-17")
	await s.first_flow.resume()                     # back from the age screen
	var at_protections := s.first.beat() == "protections"
	var shown: Array = FirstPresenter.screen(s.store.get_slice(FirstState.FIRST), s.age.band())["lines"]
	# A killed app: a new launch reads the same beat back.
	var relaunched := FirstLaunch.new(path.get_basename() + "-first.json").beat()
	await s.first_flow.next()
	s.first_flow.cycle("adjective")
	s.first_flow.cycle("noun")
	await s.first_flow.keep_name()
	var kept := s.first.name()
	var signed := false
	for c: Dictionary in transport.calls:
		signed = signed or str(c["route"]).begins_with("POST /v1/session")
	check.call("the first launch goes title, age check, protections, name, each beat kept on the phone so a killed "
			+ "app resumes there, with no account made; the name stays on the phone (20.1, 25.2, G58)",
		start == "title" and to_age and at_protections and "Spending capped at €50 a month" in shown
			and relaunched == "protections" and kept == {"adjective": 1, "noun": 1} and s.first.done()
			and &"home" in routes and not signed,
		"%s %s %s %s %s %s" % [start, routes, relaunched, kept, s.first.beat(), signed])
	s.close()


func _on_screen() -> void:
	var services: Services = App.services
	services.store.dispatch(&"first_loaded", {"protections": protections(), "words": words()})
	services.store.dispatch(&"first_moved", {"beat": "name"})
	var screen: FirstScreen = await mount.call("first")
	await tree.process_frame
	services.store.dispatch(&"first_moved", {"beat": "name"})
	var keys := screen.find_children("*", "Button", true, false).map(
		func(b: Button) -> String: return str(b.get_meta("key", ""))).filter(func(k: String) -> bool: return k != "")
	var beat := ""
	for b: VBoxContainer in screen.body.find_children("*", "VBoxContainer", true, false):
		if b.has_meta("beat"):
			beat = str(b.get_meta("beat"))
	screen.queue_free()
	await tree.process_frame
	check.call("the first launch screen draws one beat at a time, the name with a button for each word and one to "
			+ "keep it, and no skip (23.2)",
		beat == "name" and keys == ["cycle:adjective", "cycle:noun", "next"], "%s %s" % [beat, keys])


func _online() -> void:
	var name := "against the server: the first launch reads §20.2's protections and the word lists before any "
	name += "account, and the Keeper's name it kept reaches the server once the account is made (G58, 25.2)"
	if server_url == "":
		check.call(name, false, "no server: run through client/status.py, which starts one")
		return
	var path := "user://outbox-test-first.json"
	DirAccess.remove_absolute(path.get_basename() + "-first.json")
	var s := Services.build(tree.root, server_url, null, path)
	s.router.change = func(_p: String) -> void: pass
	s.age.answer("18+")
	await s.first_flow.load_words()
	var slice: Dictionary = s.store.get_slice(FirstState.FIRST)
	var read := (slice["words"] as Dictionary).has("adjectives") and (slice["protections"] as Dictionary).has("18+")
	s.first.set_name(3, 4)
	var me := await s.sign_in()
	var keeper := await s.api.get_json("/v1/keeper")
	var held: Variant = keeper.value.get("name") if keeper.ok else null
	check.call(name, read and me and s.first.sent() and held is Dictionary
		and int(held["adjective"]) == 3 and int(held["noun"]) == 4, "%s %s %s" % [read, me, held])
	s.close()
