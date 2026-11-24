extends SceneTree
## The client's tests, headless, as TAP: `ok N - name` or `not ok N - name`.
## client/status.py runs them and writes client/status.json, which is what
## tools/completion.py reads — results, not claims.

## A test that errors stops its coroutine, and a stopped coroutine never
## quits; so the run has a deadline, and missing it is a failure.
const DEADLINE_SECONDS := 480.0
## Phase 4b's screens (§26.8), each a row of tools/completion.py's; the
## landing picker is the heist screen's.
const PHASE_4B := ["map", "law", "realm", "weaving", "planner", "observatory", "scout", "roster", "character",
	"sage_hall", "codex", "lab", "curation", "defences", "first", "heist_screen", "harmony", "forms", "share",
	"profile", "hatch"]
const HEIST_SCENE := "res://scenes/heist_screen.tscn"
const SCREENS := ["home", "heist_screen", "result_screen", "replay_screen", "settings", "builder", "track", "shop",
	"social", "friends", "workshop", "age", "universe", "roster", "character", "sage_hall", "forms", "hatch", "weaving",
	"codex", "harmony", "observatory", "scout", "lab", "defences", "law", "profile", "planner", "map", "realm", "share",
	"first", "curation"]

## The tab routes whose screen shows no tab bar: the Observatory is an
## overlay, its top bar's back arrow going home (OverlayTop).
const WITHOUT_TABS := [&"observatory"]
## The routes with no back button yet, held to none until ScreenNav (S3-R38).
const NO_BACK := [&"age", &"heist", &"result", &"replay", &"builder", &"universe", &"hatch", &"curation",
	&"planner", &"map", &"realm", &"first", &"defences", &"scout"]

var _n := 0
var _failed := 0


func _initialize() -> void:
	create_timer(DEADLINE_SECONDS).timeout.connect(func() -> void:
		print("not ok %d - the tests finished inside %d seconds" % [_n + 1, DEADLINE_SECONDS])
		quit(1))
	_run()


func check(name: String, passed: bool, detail := "") -> void:
	_n += 1
	if passed:
		print("ok %d - %s" % [_n, name])
	else:
		_failed += 1
		print("not ok %d - %s" % [_n, name])
		if detail != "":
			print("  # " + detail)


func _play(bytes: PackedByteArray) -> RulebornReplay:
	var r := RulebornReplay.new()
	if not r.load(bytes, PackedByteArray()):
		return null
	while r.step():
		pass
	return r


## §5.4 against the server: the example universe's Heart (a generated Heart
## with one outer realm, server/src/main.mjs --example) leased across its
## realms, landed on the outer realm's edge from the picker, played out on the
## heist screen and re-simulated and settled by the server.
func _across_the_server(server_url: String) -> void:
	var name := "against the server: a raid leased across a universe of two realms lands on the outer realm from the " \
		+ "picker, is played on the heist screen and is re-simulated across both realms and settled by the server " \
		+ "(5.4, 24.12, T3.3)"
	if server_url == "":
		check(name, false, "no server: run through client/status.py, which starts one")
		return
	var s := _services(server_url)
	await s.session()
	var index := await s.heists.target_index()
	var target := {}
	var owners := {}
	for band: String in (index.value if index.ok else {}):
		var file := await s.heists.fetch(str(index.value[band]))
		var list: Variant = JSON.parse_string((file.value as PackedByteArray).get_string_from_utf8()) if file.ok else null
		for c: Dictionary in (list.get("candidates", []) if list is Dictionary else []):
			if not owners.has(c["owner"]):
				owners[c["owner"]] = []
			owners[c["owner"]].append(c)
	# The example universe's owner: the generator's own targets are listed
	# under one name for every realm, but belong to no universe.
	for owner: String in owners:
		var realms: Array = owners[owner].map(func(c: Dictionary) -> String: return str(c["realm"]))
		if owner != "the-game-generator" and "heart" in realms and "outer-1" in realms:
			target = owners[owner][realms.find("heart")]
	s.store.dispatch(&"heist_started", {"target": {"bundle": target.get("bundle", ""), "owner": target.get("owner", ""),
		"across": true}})
	var online: HeistScreen = load(HEIST_SCENE).instantiate()
	root.add_child(online)
	online.set_process(false)
	# The lease comes first, then the universe and its islands by hash: waited
	# for by the clock, since a headless frame takes about a millisecond.
	var until := Time.get_ticks_msec() + 30000
	while Time.get_ticks_msec() < until:
		if not online.controller.universe.is_empty() or online.hint_label.text.begins_with("No heist"):
			break
		await process_frame
	var picked := online.controller.choosing and not online.controller.universe.is_empty() \
		and online.picker_realm.text.begins_with("In outer realm 1")
	var played := {}
	if picked:
		online.controller.land_here()
		online.controller.advance(int(online.lease["universe"]["realms"][1]["ticks"]) + 30)
		if _heist()["verdict"].is_empty() or not _heist()["verdict"].get("server", false):
			await online.finished
		played = _heist()["verdict"]
	check(name, not target.is_empty() and picked and played.get("ok", false) and played.get("server", false),
		"%s | %s | %s | %s" % [target, picked, played, online.hint_label.text])
	online.queue_free()
	s.store.dispatch(&"heist_started", {})
	_services()
	await process_frame


## The heist slice of the store: what the result and replay screens read.
func _heist() -> Dictionary:
	return App.services.store.get_slice(AppState.HEIST)


## Services for a test run: no network unless `server` names one, the tests'
## own outbox file, and a router that records rather than changes scenes.
func _services(server := "") -> Services:
	if App.services != null:
		App.services.close()
	var s := Fixtures.answered(Services.build(root, server, null, "user://outbox-test.json"))
	s.router.change = func(_path: String) -> void: pass
	App.services = s
	return s


func _golden(name: String) -> PackedByteArray:
	return FileAccess.get_file_as_bytes("res://goldens/%s.rbh" % name)


## The screens drawn with something on them, so the checks that run over
## every screen read a roster and a character rather than an empty page: the
## roster tests' home, and the resting character's page.
func _seed() -> void:
	App.services.store.dispatch(&"roster_loaded", {"view": HatchTests.born()})
	App.services.store.dispatch(&"roster_changed", {"home": HatchTests.born(),
		"what": {"do": "birth", "born": 9, "first": true, "outfit": "hatch-outfit"}})
	App.services.store.dispatch(&"workshop_words", {"words": HatchTests.words()})
	App.services.store.dispatch(&"navigated", {"name": &"character", "params": {"id": 2, "law": "bloom"}})
	App.services.store.dispatch(&"sages_loaded", {"view": SageTests.sample()})
	App.services.store.dispatch(&"forms_loaded", {"view": FormsTests.sample()})
	App.services.store.dispatch(&"weaving_loaded", {"view": WeavingTests.sample()})
	App.services.store.dispatch(&"codex_loaded", {"view": CodexTests.sample()})
	App.services.store.dispatch(&"harmony_loaded", {"view": HarmonyTests.sample()})
	App.services.store.dispatch(&"observatory_loaded", {"view": ObservatoryTests.sample()})
	App.services.store.dispatch(&"observatory_chosen", {"bundle": "p1"})
	App.services.store.dispatch(&"lab_loaded", {"view": LabTests.sample()})
	App.services.store.dispatch(&"defences_loaded", {"view": DefencesTests.sample()})
	App.services.store.dispatch(&"profile_loaded", {"view": ProfileTests.sample()})
	App.services.store.dispatch(&"first_loaded", {"protections": FirstTests.protections(), "words": FirstTests.words()})
	App.services.store.dispatch(&"first_moved", {"beat": "protections"})
	App.services.store.dispatch(&"curation_loaded", {"view": CurationTests.sample()})
	App.services.store.dispatch(&"curation_island", {"island": CurationTests.island()})
	App.services.store.dispatch(&"curation_words", {"words": FirstTests.words()})


func _mount(scene: String) -> Control:
	var node: Control = load("res://scenes/%s.tscn" % scene).instantiate()
	root.add_child(node)
	await process_frame
	return node


## AD-R47 (flow board 2's F1): each tab's route opened through router.go, its
## scene swapped in as a player's move swaps it, at 100% and 200% text and in
## high contrast. Once laid out, its bob running, the chosen tab's picture
## stands in its tile: across it, its foot inside the tile and no further
## from the tile's foot than it rests and bobs; at larger text all of it
## inside the tile (AD-R38).
func _tab_routes() -> void:
	var router := App.services.router
	var was := router.change
	# The router's own change (`change_scene_to_file`): the screen enters the
	# tree before its first layout, as on the phone, where F1 showed.
	router.change = func(path: String) -> void:
		change_scene_to_file(path)
	var moving := Settings.reduced_motion
	Settings.reduced_motion = false
	var misses: Array[String] = []
	for look: Array in [[100, false], [200, false], [100, true]]:
		Settings.text_scale = look[0]
		Settings.high_contrast = look[1]
		Settings.apply()
		for tab: String in Router.TABS:
			router.go(Router.TABS[tab])
			await create_timer(0.3).timeout
			await process_frame
			var bars := _bars(current_scene)
			if bars.is_empty() != (Router.TABS[tab] in WITHOUT_TABS):
				misses.append("%s at %d%%: %s tab bar" % [tab, look[0], "a" if bars else "no"])
			for bar: KitTabs in bars:
				var miss := _out_of_tile(bar)
				if miss != "":
					misses.append("%s (%s) at %d%%%s: %s" % [Router.TABS[tab], bar.active, look[0],
						" hc" if look[1] else "", miss])
	unload_current_scene()
	await process_frame
	Settings.text_scale = 100
	Settings.high_contrast = false
	Settings.apply()
	Settings.reduced_motion = moving
	router.change = was
	check("AD-R47: on every tab route the router opens, at 100% and 200% text and in high contrast, the chosen "
		+ "tab's picture stands in its tile", misses.is_empty(), "; ".join(misses))


## AD-R50: each route that is no tab or hub segment shows one back button,
## ScreenNav's, which leaves it. AD-R51: the roster keeps its stage and scroll.
func _back_routes() -> void:
	var router := App.services.router
	var was := router.change
	router.change = func(path: String) -> void: change_scene_to_file(path)
	App.services.store.dispatch(&"roster_loaded", {"view": ShotData.roster()})
	var skip: Array = Router.TABS.values() + Router.HUBS.values().reduce(func(a: Array, h: Array) -> Array:
		return a + h.map(func(s: Dictionary) -> StringName: return s["route"]), [])
	var misses: Array[String] = []
	var seen := 0
	for route: StringName in Router.ROUTES.keys().filter(func(r: StringName) -> bool: return r not in skip):
		var backs := await _backs(router.go.bind(route, {"id": 2} if route == &"character" else {}))
		if backs.size() != (0 if route in NO_BACK else 1):
			misses.append("%s: %d back buttons" % [route, backs.size()])
		elif backs:
			seen += 1
			await _backs(backs[0].pressed.emit)
			var to: StringName = App.services.store.get_slice(AppState.ROUTE)["name"]
			if to == route or (route == &"character" and to != &"roster"):
				misses.append("%s: its back button went to %s" % [route, to])
	check("AD-R50: each route that is no tab or hub segment shows one back button, which leaves it (%d)" % seen,
		misses.is_empty() and seen > 0, "; ".join(misses))
	await _backs(router.go.bind(&"roster"))
	var left := current_scene as RosterScreen
	var pick: int = RosterScreen.kinds_of(App.services.store.get_slice(RosterState.ROSTER)).keys()[5]
	left._choose(pick)
	(left.body.get_parent() as ScrollContainer).scroll_vertical = 240
	var kept := left.kept()
	var backs := await _backs(left._open.bind(pick))
	for b: Button in backs.slice(0, 1):
		await _backs(b.pressed.emit)
	var back: Dictionary = current_scene.kept() if current_scene is RosterScreen else {}
	check("AD-R51: the roster keeps its stage's character and its scroll across a visit to one",
		backs.size() == 1 and kept["scroll"] > 0 and back == kept, "left as %s, came back as %s" % [kept, back])
	unload_current_scene()
	await process_frame
	router.change = was


## Does `act`, lets the scene it opens settle, and returns its back buttons.
func _backs(act: Callable) -> Array:
	act.call()
	await create_timer(0.4).timeout
	await process_frame
	return current_scene.find_children("*", "Button", true, false).filter(func(b: Button) -> bool:
		return b.is_visible_in_tree() and b.get_meta("back", false))


func _bars(n: Node) -> Array[KitTabs]:
	var found: Array[KitTabs] = []
	if n is KitTabs:
		found.append(n as KitTabs)
	for c: Node in n.get_children():
		found.append_array(_bars(c))
	return found


## Where the chosen tab's picture leaves its tile, or "" where it stands in it.
func _out_of_tile(bar: KitTabs) -> String:
	var pic := bar.picture_of(bar.active).get_global_rect()
	var tile := bar.tile_of(bar.active).get_global_rect()
	var slack := 1.0
	var rests := KitTabs.rest(true) + UI.PX_PER_POINT * KitTabs.BOB + slack
	var foot := tile.end.y - pic.end.y
	if pic.position.x < tile.position.x - slack or pic.end.x > tile.end.x + slack:
		return "picture %s across tile %s" % [pic, tile]
	if foot < -slack or foot > rests:
		return "picture's foot %.0f px over the tile's foot (%s in tile %s)" % [foot, pic, tile]
	if not KitTabs.lifts() and pic.position.y < tile.position.y - slack:
		return "picture %s over the top of tile %s" % [pic, tile]
	return ""


## AD-R59 (audit 1 row 18): the goal card's bar is the key frame's green
## progress fill in both looks, never gold (gold stays on Collect).
func _goal_bar() -> void:
	var tones: Array[Color] = []
	for hc: bool in [false, true]:
		Tokens.high_contrast = hc
		var card := KitHud.goal("", "Raise the Star Well", 2, 3, "")
		var bar: KitBar = null
		for n: Node in card.find_children("*", "Control", true, false):
			if n is KitBar:
				bar = n
		tones.append(bar._bottom if bar != null else Color())
		var counts := card.find_child("Progress", true, false).find_children("*", "Label", false, false)
		tones.append(Color.BLACK if counts.any(func(l: Label) -> bool: return l.visible) else Color.WHITE)
		card.free()
	Tokens.high_contrast = false
	var green := Tokens.color("green_bar")
	check("AD-R59: the goal card's bar is the green progress fill in both looks, and no count is written "
		+ "where none is given", tones == [green, Color.WHITE, green, Color.WHITE], str(tones))


func _run() -> void:
	# The offline tests first, with no server; status.py names one for the end.
	var server_url := OS.get_environment("RULEBORN_SERVER")
	OS.unset_environment("RULEBORN_SERVER")
	# The tests' own settings file, so a run never touches a player's.
	Settings.path = "user://settings-test.cfg"
	Draft.path = "user://island-test.rbi"
	DirAccess.remove_absolute(Draft.path)
	Draft.forget_origin()
	DirAccess.remove_absolute(Draft.path.get_basename() + "-kept.rbi")
	DirAccess.remove_absolute(Settings.path)
	Settings.restore()
	Settings.change(func() -> void: Settings.locale = "en")
	DirAccess.remove_absolute("user://outbox-test.json")
	_services()
	var goldens := ReplayScreen.find_goldens()

	# Every script compiles: one that does not otherwise shows up as a method
	# "missing" somewhere else, far from the line at fault.
	var broken: Array[String] = []
	for f: String in _scripts("res://") + _test_scripts():
		var script: GDScript = ResourceLoader.load(f, "GDScript", ResourceLoader.CACHE_MODE_IGNORE)
		if script == null or not script.can_instantiate():
			broken.append(f)
	check("every script compiles, with GDScript's warnings as errors", broken.is_empty(), ", ".join(broken))

	# The architecture's layers, headless (client/README.md).
	await CoreTests.new(self, check).run()

	# §20.8's accessibility set, on every screen, offline (tests/a11y_tests.gd).
	_seed()
	await A11yTests.new(self, check, _mount, _control_problems, SCREENS).run()
	StageHeroTests.new(check).run()
	await UiKitTests.new(self, check).run()
	await _tab_routes()
	await _back_routes()
	await SettingsTabTests.new(self, check).run()
	_goal_bar()

	# The game's languages (§20.6 and the owner's, D99): every key a script
	# asks for is in the catalogue, in every language, with the same
	# placeholders, and the catalogue's columns are the languages.
	var columns := FileAccess.open("res://i18n/strings.csv", FileAccess.READ).get_csv_line().slice(1)
	check("every string a screen asks for is in the catalogue, in each of the game's languages, "
			+ "with the same placeholders",
		_catalogue_problems().is_empty() and Array(columns) == Strings.LOCALES,
		"; ".join(_catalogue_problems()) + " columns %s" % columns)

	# A new player starts in the phone's language: Brazil's Portuguese or
	# Portugal's, the United States' English or Britain's, German, French,
	# and British English for any other.
	var phones := {"pt_BR": "pt_BR", "pt_PT": "pt_PT", "pt_AO": "pt_PT", "pt": "pt_PT", "en_US": "en_US",
		"en_GB": "en", "en_AU": "en", "en": "en", "de_DE": "de", "de_AT": "de", "fr_FR": "fr", "fr_CA": "fr",
		"es_ES": "en", "ja_JP": "en"}
	var picked := []
	for phone: String in phones:
		if Strings.locale_for(phone) != phones[phone]:
			picked.append("%s -> %s" % [phone, Strings.locale_for(phone)])
	var language_names := []
	for locale: String in Strings.LOCALES:
		Strings.set_locale(locale)
		language_names.append(Strings.t("LANGUAGE_" + locale))
	Strings.set_locale("en")
	check("a new player starts in the phone's language: Portuguese and English by region, German and French, "
			+ "British English otherwise, and the picker names each language in itself",
		picked.is_empty() and language_names == ["English (UK)", "English (US)", "Português (Brasil)",
			"Português (Portugal)", "Deutsch", "Français"], "%s / %s" % [picked, language_names])

	# §24.7: one simulation, compiled for every target. The client's build must
	# be the server's, rule for rule.
	var versions := {}
	for g in goldens:
		var r := RulebornReplay.new()
		r.load(_golden(g), PackedByteArray())
		versions[r.rules()] = true
	check("the client's simulation is the rules version every golden replay names",
		goldens.size() > 0 and versions.keys() == [RulebornReplay.rules_version()],
		"client %s, goldens %s" % [RulebornReplay.rules_version(), versions.keys()])

	# §18.3: the heist is played in the era its lease names, and a lease in
	# none sends null, which must reach the extension as no era, not "<null>".
	var in_era := RulebornReplay.new()
	check("a lease's era reaches the simulation as the lease names it, and none as none",
		HeistController.lease_era({"era": null}) == "" and HeistController.lease_era({}) == ""
			and HeistController.lease_era({"era": "glass_moon"}) == "glass_moon"
			and in_era.set_era("glass_moon") and in_era.set_era("") and not in_era.set_era("<null>"))

	# The Data safety form's "encrypted in transit": no server but this
	# machine's own is spoken to over plain HTTP.
	check("the client speaks to a server over HTTPS only, plain HTTP to this machine's own for tests",
		Api.secure("https://edge.example/") and Api.secure("http://127.0.0.1:8787")
			and Api.secure("http://localhost/v1") and not Api.secure("http://edge.example")
			and not Api.secure("http://127.0.0.1.edge.example/") and not Api.secure("ftp://x"))

	# §24.10: the checksums a replay carries, one a second, are the server's.
	var bad := []
	var seconds := 0
	for g in goldens:
		var r := _play(_golden(g))
		if r == null or r.mismatch() != 0 or r.seconds_agreed() * RulebornReplay.ticks_per_second() != r.ticks():
			bad.append(g)
		else:
			seconds += r.seconds_agreed()
	check("every golden replay re-simulates in the client, every second agreeing with its checksums",
		goldens.size() >= 5 and bad.is_empty(), "diverged: %s; %d seconds agreed" % [bad, seconds])

	var planned := _play(_golden("planned-clean"))
	var o := planned.outcome() if planned else {}
	check("the planned heist plays out Clean with every bag banked (§12.9)",
		o.get("grade") == "Clean" and o.get("banked") == o.get("capacity") and o.get("capacity", 0) > 0,
		str(o))

	# The replay screen, played to the end, shows the heist's grade.
	var replay_screen: ReplayScreen = await _mount("replay_screen")
	replay_screen.open_golden("planned-clean")
	replay_screen.advance(100000)
	check("the replay screen plays a golden to its end and shows its grade",
		replay_screen.grade_label.text.begins_with("Clean") and replay_screen.badge_label.text.contains("Matches"),
		"%s / %s" % [replay_screen.grade_label.text, replay_screen.badge_label.text])
	replay_screen.queue_free()

	# Taps become commands (§24.10: "a move or an ability with its tick, crew
	# member and target"): each control makes exactly one, stamped now.
	var heist: HeistScreen = await _mount("heist_screen")
	heist.set_process(false)
	heist.advance(90)
	var now := heist.controller.world.tick()
	heist.controller.select(1)
	heist.controller.tap_tile(Vector2i(4, 5))
	heist.controller.crack()
	heist.controller.load_up(70)
	heist.controller.get_out()
	heist.controller.tap_tile(Vector2i(13, 7))
	# The landing the screen gives before its first step is not a tap.
	var actions := heist.controller.world.commands() \
		.filter(func(c: Dictionary) -> bool: return int(c["kind"]) != HeistController.Kind.LAND) \
		.map(func(c: Dictionary) -> Array: return [c["tick"], c["actor"], c["kind"], c["x"], c["y"]])
	var want := [[now, 1, HeistController.Kind.MOVE_TO, 4 * 256 + 128, 5 * 256 + 128],
		[now, 1, HeistController.Kind.CRACK, 0, 0], [now, 1, HeistController.Kind.LOAD, 70, 0],
		[now, 1, HeistController.Kind.SKIFF, 13 * 256 + 128, 7 * 256 + 128]]
	check("every tap on the heist screen makes the one command it names, stamped with the tick it was made",
		actions == want, "got %s" % [actions])

	# A tap is read by what is on the tile, and each is the one command the
	# player chose (§12.18): a guard is attacked, the Vault cracked, a pylon
	# broken, a ward disarmed. The gait button walks, crouches and runs.
	heist.begin(HeistController.SEED, HeistController.TICKS, HeistController.CREW)
	heist.controller.select(1)
	var first: Dictionary = heist.controller.world.guards()[1]
	var pylon := -1
	var features := heist.controller.world.features()
	for i in features.size():
		if features[i] == RealmView.Tile.PYLON:
			pylon = i
			break
	var width := heist.controller.world.size().x
	var ward: Dictionary = heist.controller.world.wards()[0] if heist.controller.world.wards().size() > 0 else {}
	heist.controller.tap_tile(Vector2i(first["at"]))
	heist.controller.tap_tile(Vector2i(heist.controller.world.vault()["at"]))
	heist.controller.tap_tile(Vector2i(pylon % width, pylon / width))
	if not ward.is_empty():
		heist.controller.tap_tile(Vector2i(ward["at"]))
	heist.controller.next_gait()
	heist.advance(1)
	heist.controller.next_gait()
	heist.advance(1)
	heist.controller.next_gait()
	heist.controller.halt()
	heist.controller.drop_half()
	var kinds := heist.controller.world.commands() \
		.filter(func(c: Dictionary) -> bool: return int(c["kind"]) != HeistController.Kind.LAND) \
		.map(func(c: Dictionary) -> Array: return [c["kind"], c["x"]])
	var kinds_enum := HeistController.Kind
	var expected := [[kinds_enum.ATTACK, 1], [kinds_enum.CRACK, 0], [kinds_enum.BREAK, (pylon % width) * 256 + 128]]
	if not ward.is_empty():
		expected.append([kinds_enum.DISARM, int(Vector2i(ward["at"]).x) * 256 + 128])
	expected += [[kinds_enum.GAIT, 1], [kinds_enum.GAIT, 2], [kinds_enum.GAIT, 0], [kinds_enum.HALT, 0],
			[kinds_enum.DROP, 50]]
	check("a tap on a guard, the Vault, a pylon or a ward makes the command it calls for, "
			+ "and the gait button cycles walk, crouch, run",
		kinds == expected and pylon >= 0 and not ward.is_empty(), "got %s, wanted %s" % [kinds, expected])

	# §5.4: the crew lands together on the edge tile the player chose, and the
	# log says so at tick 0; once the heist has begun, it has landed.
	heist.begin(HeistController.SEED, HeistController.TICKS, HeistController.CREW)
	var spots := heist.controller.world.landings()
	var spot: Vector2i = spots[spots.size() - 1] if spots.size() > 0 else Vector2i(-1, -1)
	var chose := heist.controller.land(spot)
	heist.advance(1)
	var together := heist.controller.world.crew().all(func(r: Dictionary) -> bool: return Vector2i(r["at"]) == spot)
	var logged := heist.controller.world.commands() \
		.filter(func(c: Dictionary) -> bool: return int(c["kind"]) == HeistController.Kind.LAND)
	check("the crew lands together on the open edge tile the player chose, recorded at tick 0 (5.4)",
		chose and together and logged.size() == 1 and int(logged[0]["tick"]) == 0 and not heist.controller.land(spots[0]),
		"spot %s, crew %s, log %s"
			% [spot, heist.controller.world.crew().map(func(r: Dictionary) -> Variant: return r["at"]), logged])

	# And the heist it plays is the heist it records. The planned golden's
	# commands, given live at their ticks on the heist screen, must record the
	# golden byte for byte, which the server's check then grades Clean.
	var golden := RulebornReplay.new()
	golden.load(_golden("planned-clean"), PackedByteArray())
	heist.begin(golden.seed(), golden.ticks(), golden.crew_size())
	var pending := golden.commands()
	var k := 0
	while heist.playing:
		while k < pending.size() and int(pending[k]["tick"]) == heist.controller.world.tick():
			var c: Dictionary = pending[k]
			heist.controller.world.give(c["actor"], c["kind"], c["x"], c["y"])
			k += 1
		heist.advance(1)
	var v: Dictionary = _heist()["verdict"]
	check("a heist played live on the heist screen records the golden replay byte for byte, "
			+ "and the server's check grades it Clean",
		(_heist()["replay"] as PackedByteArray) == _golden("planned-clean") and v.get("ok", false)
			and v.get("grade") == "Clean",
		"%d bytes against %d; %s" % [(_heist()["replay"] as PackedByteArray).size(), _golden("planned-clean").size(), v])
	var again := _play((_heist()["replay"] as PackedByteArray))
	check("the heist just played replays on this phone with every second agreeing",
		again != null and again.mismatch() == 0
			and again.seconds_agreed() * RulebornReplay.ticks_per_second() == again.ticks(),
		"mismatch %s" % (str(again.mismatch()) if again else "unloadable"))
	var played_replay := _heist()["replay"] as PackedByteArray
	var altered := played_replay.slice(0, played_replay.size() - 4) + PackedByteArray([0, 0, 0, 0])
	var refused := RulebornReplay.validate(altered, PackedByteArray())
	check("a replay whose last checksum was altered is refused, as the server would refuse it",
		not refused.get("ok", true), str(refused))
	heist.queue_free()
	await process_frame

	# The result screen reads the check's verdict, never the device's claim:
	# an accepted heist shows the re-simulation's grade, a refused one pays
	# nothing.
	var result: ResultScreen = await _mount("result_screen")
	result.show_verdict(RulebornReplay.validate(_golden("planned-clean"), PackedByteArray()), 1)
	var accepted := result.grade_label.text == "Clean" and result.check_label.text.contains("accepted")
	result.show_verdict(refused, 1)
	var turned_away := result.grade_label.text == "Not accepted" and result.check_label.text.contains("nothing")
	check("the result screen shows the validator's verdict: the re-simulation's grade, or nothing paid when refused",
		accepted and turned_away, "%s / %s" % [result.grade_label.text, result.check_label.text])
	result.queue_free()

	# The whole loop against the server (§24.12): sign in, take a target from
	# §24.8's lists, lease it, play it through the heist screen's own controls,
	# submit, and read what the server re-simulated and paid. The plan is the
	# open example Heart's clean heist, the one server/test plays.
	if server_url == "":
		check("a heist leased from the server, played on the heist screen and submitted "
				+ "is re-simulated and paid by the server",
			false, "no server: run through client/status.py, which starts one")
	else:
		_services(server_url)
		var online: HeistScreen = load(HEIST_SCENE).instantiate()
		root.add_child(online)
		online.set_process(false)
		for i in 600:
			if not online.lease.is_empty() or online.hint_label.text.begins_with("No heist"):
				break
			await process_frame
		var played := {}
		if not online.lease.is_empty():
			Plans.open_heart(online, int(online.lease["ticks"]))
			if _heist()["verdict"].is_empty() or not _heist()["verdict"].get("server", false):
				await online.finished
			played = _heist()["verdict"]
		# Vault level 3: 11,250 × 1 × 1 × 1 × 1 × fill 1 (server/test's figure; B(V) at the owner's 5,000, F36).
		check("a heist leased from the server, played on the heist screen and submitted "
				+ "is re-simulated and paid by the server",
			played.get("ok", false) and played.get("grade") == "Clean" and int(played.get("haul", 0)) == 11250,
			"%s; %s" % [played, online.hint_label.text])
		# §14.2: the raid earned its raider 30 + 6 × Keeper 1, and the bar moved.
		var bar: Dictionary = App.services.store.get_slice(KeeperState.KEEPER)["view"]
		var asked := await App.services.account.keeper()
		check("a raid settled by the server earns its raider Keeper experience, and the Keeper bar moves with "
				+ "the answer, as the server keeps it (14.2)",
			played.get("keeper") is Dictionary and int(played["keeper"].get("gained", 0)) == 36
				and int(bar.get("xp", -1)) == int(played["keeper"]["xp"]) and asked.ok
				and int(asked.value["xp"]) == int(bar["xp"]) and int(asked.value["level"]) == int(bar["level"]),
			"%s | %s | %s" % [played.get("keeper"), bar, asked.value if asked.ok else asked.code])
		online.queue_free()
		_services()
		await process_frame
	await _across_the_server(server_url)

	# The season track, the shop and the wallet (tests/shop_tests.gd), and the
	# league, groups and friends (tests/social_tests.gd): headless, and
	# against the server when one is named.
	await ShopTests.new(self, check, server_url).run()
	await SocialTests.new(self, check, server_url).run()
	await WorkshopTests.new(self, check, server_url).run()
	await AgeTests.new(self, check, server_url).run()
	await AuthTests.new(self, check, server_url).run()
	await SecurityTests.new(self, check).run()
	await FixTests.new(self, check).run()
	# The client audit's second pass (FX3-7): the findings the first left unproven.
	await AuditClient2Tests.new(self, check, _mount).run()
	await KeeperTests.new(self, check, _mount).run()
	await NoticesTests.new(self, check).run()
	await UniverseTests.new(self, check, _mount, server_url).run()
	await RosterTests.new(self, check, _mount, server_url).run()
	await SageTests.new(self, check, _mount, server_url).run()
	await FormsTests.new(self, check, _mount, server_url).run()
	await HatchTests.new(self, check, _mount, server_url).run()
	StabilityTests.new(check).run()
	await WeavingTests.new(self, check, _mount, server_url).run()
	await CodexTests.new(self, check, _mount, server_url).run()
	await HarmonyTests.new(self, check, _mount, server_url).run()
	await ObservatoryTests.new(self, check, _mount, server_url).run()
	await LandingTests.new(self, check, _mount).run()
	await WorldTests.new(self, check).run()
	await CreatureTests.new(self, check).run()
	await LawFxTests.new(self, check).run()
	await LookTests.new(self, check).run()
	await HeistFxTests.new(self, check).run()
	A11yMotionTests.new(check).run()
	await StageTests.new(self, check, _mount).run()
	KitTests.new(check).run()
	await LabTests.new(self, check, _mount, server_url).run()
	await DefencesTests.new(self, check, _mount, server_url).run()
	await LawTests.new(self, check, _mount, server_url).run()
	await ProfileTests.new(self, check, _mount, server_url).run()
	await PlannerTests.new(self, check, _mount, server_url).run()
	await MapTests.new(self, check, _mount, server_url).run()
	await UniverseViewTests.new(self, check, _mount).run()
	await RealmTests.new(self, check, _mount, server_url).run()
	await ShareTests.new(self, check, _mount, server_url).run()
	await FirstTests.new(self, check, _mount, server_url).run()
	await CurationTests.new(self, check, _mount, server_url).run()
	# Online first, offline the exception (G41; tests/offline_tests.gd).
	await OfflineTests.new(self, check, _mount).run()

	# §20.6's settings survive a relaunch: each change on the settings screen
	# is saved as it is made, and the next launch reads it back and applies it.
	var settings: SettingsScreen = await _mount("settings")
	# The screen is built again after each change, so each tap finds its
	# button afresh.
	var tap := func(text: String, nth := 0) -> void:
		var found: Array = settings.find_children("*", "Button", true, false) \
			.filter(func(b: Button) -> bool: return b.text == text and b.is_inside_tree())
		found[nth].pressed.emit()
	for i in 7:
		tap.call("−", 0)
	tap.call("−", 1)
	tap.call(Strings.t("SETTINGS_MOTION_OFF"))
	# The language button goes through the languages in turn: from British
	# English to US English, and on to Brazilian Portuguese.
	tap.call(Strings.t("LANGUAGE_en"))
	tap.call(Strings.t("LANGUAGE_en_US"))
	await process_frame
	var saved := [Settings.locale, Settings.volume.duplicate(), Settings.reduced_motion, Settings.haptics]
	Settings.locale = ""
	Settings.volume = Settings.DEFAULT_VOLUME.duplicate()
	Settings.reduced_motion = false
	Strings.set_locale("en")
	Settings.read_file()
	var music := AudioServer.get_bus_index("Music")
	var effects := AudioServer.get_bus_index("Effects")
	var alerts := AudioServer.get_bus_index("Alerts")
	check("settings changed on the settings screen are saved as they change and restored on the next launch: "
			+ "language, three volumes, reduced motion, haptics (§20.6)",
		saved == [Settings.locale, Settings.volume, Settings.reduced_motion, Settings.haptics]
		and Settings.locale == "pt_BR" and TranslationServer.get_locale() == "pt_BR"
		and Settings.volume == {"music": 0, "effects": 7, "alerts": 10} and Settings.reduced_motion
		and AudioServer.is_bus_mute(music) and not AudioServer.is_bus_mute(alerts)
		and is_equal_approx(AudioServer.get_bus_volume_db(effects), linear_to_db(0.7))
		and is_equal_approx(AudioServer.get_bus_volume_db(alerts), 0.0),
		"saved %s, restored %s" % [saved, [Settings.locale, Settings.volume, Settings.reduced_motion, Settings.haptics]])
	settings.queue_free()
	DirAccess.remove_absolute(Settings.path)
	Settings.read_file()
	Settings.change(func() -> void: Settings.locale = "en")
	await process_frame

	# The builder (§13): ground on the grid, laws and their pylons, and a raid
	# on what was built — every edit through the simulation's own island.
	var builder: BuilderScreen = await _mount("builder")
	builder.tool = BuilderScreen.Tool.GROUND
	var laid := {Vector2i(2, 4): "rock_pillar", Vector2i(3, 4): "gravel_path",
		Vector2i(4, 4): "stream", Vector2i(5, 4): "raised_ground", Vector2i(6, 4): "tall_grass",
		Vector2i(7, 4): "hedge", Vector2i(8, 4): "lantern_post", Vector2i(2, 6): "hot_spring",
		Vector2i(3, 6): "boulder", Vector2i(4, 6): "bell_post", Vector2i(5, 6): "marsh",
		Vector2i(6, 6): "pit", Vector2i(7, 6): "moss"}
	for at: Vector2i in laid:
		builder.kind = builder.kinds().find(laid[at])
		builder.tap_tile(at)
	var reread := RulebornIsland.new()
	var same := reread.read(builder.island.bytes())
	for at: Vector2i in laid:
		same = same and reread.ground(at.x, at.y) == laid[at] and builder.island.ground(at.x, at.y) == laid[at]
	var side := builder.island.side()
	var drawn := builder.preview.features()[4 * side + 2] == RealmView.Tile.ROCK_PILLAR \
		and builder.preview.surfaces()[4 * side + 4] == 2
	check("the builder lays §6.2's ground on the realm's grid, and the island it writes reads back the same",
		same and drawn and builder.island.problems().is_empty(), "%s" % builder.island.problems())

	# The six with a direction (TD.38, G56): a second tap turns ground that
	# faces, a tunnel is tunnel_dug with a tap for each mouth, and the island carries
	# both; the realm view is given each facing and each tunnel to draw.
	var reach: Array = builder.palette["tunnel"]
	builder.kind = builder.kinds().find("ramp")
	builder.tap_tile(Vector2i(2, 8))
	builder.tap_tile(Vector2i(2, 8))
	builder.kind = builder.kinds().find("rapids")
	builder.tap_tile(Vector2i(3, 8))
	builder.kind = builder.kinds().find("tunnel")
	builder.tap_tile(Vector2i(5, 8))
	var tunnel_asked := builder.status_label.text == Strings.t("BUILDER_TUNNEL_END", reach)
	builder.tap_tile(Vector2i(9, 8))
	builder.tap_tile(Vector2i(0, 9))
	builder.tap_tile(Vector2i(10, 2))
	var tunnel_too_far := builder.status_label.text == Strings.t("BUILDER_TUNNEL_FAR", reach)
	var faced_turned := builder.island.facing(2, 8) == 1 and builder.island.facing(3, 8) == 0 \
		and builder.island.facing(2, 4) == -1
	var tunnel_dug := builder.island.ground(5, 8) == "tunnel" and builder.island.ground(9, 8) == "tunnel" \
		and builder.island.ground(0, 9) == ""
	var faced := RulebornIsland.new()
	var faced_carried := faced.read(builder.island.bytes()) and faced.facing(2, 8) == 1 \
		and faced.ground(9, 8) == "tunnel" and faced.ground(3, 8) == "rapids"
	var faced_shown := builder.preview.facings()[8 * side + 2] == 1 and builder.preview.facings()[8 * side + 4] == 255 \
		and builder.preview.tunnels() == [Vector2i(5, 8), Vector2i(9, 8)]
	check("the builder lays the six with a direction, turns them with a second tap, digs a tunnel mouth by mouth, "
			+ "and the island it writes carries both (6.2, G56)",
		tunnel_asked and tunnel_too_far and faced_turned and tunnel_dug and faced_carried and faced_shown
			and builder.island.problems().is_empty(),
		"%s %s %s %s %s %s %s" % [tunnel_asked, tunnel_too_far, faced_turned, tunnel_dug, faced_carried,
			faced_shown, builder.island.problems()])

	# §10.1's buildings, through the simulation's own island (TD.36): placed
	# on their footprints, named from any tile they cover, and carried in the
	# bundle the server holds to the buildings placed.
	var town := RulebornIsland.new()
	var placed := town.place_building("keeper_s_spire", 2, 2) and town.place_building("star_well", 7, 2) \
		and not town.place_building("vault", 5, 5) and not town.place_building("keeper_s_spire", 10, 0)
	var back := RulebornIsland.new()
	var carried := back.read(town.bytes()) \
		and back.buildings() == [["keeper_s_spire", 2, 2, 3], ["star_well", 7, 2, 2]]
	var named := town.occupant(4, 4) == "building:keeper_s_spire" and town.occupant(5, 5) == ""
	check("the island the builder edits places §10.1's buildings on their footprints, and its bundle carries them",
		placed and carried and named and town.problems().is_empty(), "%s / %s" % [back.buildings(), town.problems()])

	builder.tool = BuilderScreen.Tool.LAW
	for step: Array in [["haste", Vector2i(1, 10)], ["brittle_stone", Vector2i(11, 2)]]:
		builder.kind = builder.kinds().find(step[0])
		builder.tap_tile(step[1])
	var pylons := builder.island.occupant(1, 10) == "pylon:haste" \
		and builder.island.occupant(11, 2) == "pylon:brittle_stone"
	var harmony := builder.together_label.text.contains(Strings.t("NOTE_SPARK"))
	var ready := not builder.raid_button.disabled
	builder.kind = builder.kinds().find("glowing_dark")
	builder.tap_tile(Vector2i(8, 8))
	var over := builder.island.problems().has("TooManyLaws") and builder.raid_button.disabled \
		and builder.status_label.text.contains(Strings.t("PROBLEM_TOOMANYLAWS"))
	var chord := "wild_hunt" in Array(builder.island.combos()["chords"])
	check("the builder weaves laws and places their pylons, holds the realm to its law slots, "
			+ "and names what the laws make together (§8.6)",
		pylons and harmony and ready and over and chord,
		"%s / %s / %s" % [builder.status_label.text, builder.together_label.text, builder.island.combos()])

	builder.tool = BuilderScreen.Tool.ERASE
	builder.tap_tile(Vector2i(8, 8))
	builder.tool = BuilderScreen.Tool.WARD
	builder.kind = builder.kinds().find("time_snare")
	builder.tap_tile(Vector2i(9, 3))
	builder.tool = BuilderScreen.Tool.GUARD
	builder.kind = 1
	builder.tap_tile(Vector2i(8, 6))
	var posted := builder.island.facing(8, 6)
	builder.tap_tile(Vector2i(8, 6))
	check("a second tap on a guard post turns it a quarter: a held post faces where its owner sets it (G56)",
		posted >= 0 and builder.island.facing(8, 6) == (posted + 1) % 4
			and builder.island.occupant(8, 6) == "guard:1",
		"%d then %d" % [posted, builder.island.facing(8, 6)])
	builder.raid()
	var built := builder.island.bytes()
	var kept := FileAccess.get_file_as_bytes(Draft.path) == built
	builder.queue_free()
	await process_frame
	var own: HeistScreen = await _mount("heist_screen")
	own.set_process(false)
	var on_own: bool = own.controller.island == built and _heist()["testing"]
	# To the end: the step after the clock's last tick is the one that ends it.
	own.advance(own.controller.world.ticks() + 1)
	var judged: Dictionary = _heist()["verdict"]
	own.queue_free()
	await process_frame
	var after: ResultScreen = await _mount("result_screen")
	var way_back := after.find_children("*", "Button", true, false).any(
		func(b: Button) -> bool: return b.text == Strings.t("RESULT_BUILDER"))
	after.queue_free()
	App.services.store.dispatch(&"heist_started", {})
	await process_frame
	check("a player can raid their own island from the builder: the heist plays it, the server's check judges it, "
			+ "and the result leads back",
		kept and on_own and judged.get("ok", false) and way_back, "%s" % judged)

	# No screen holds text of its own. In a pseudo-locale that wraps every
	# catalogue string in ⟦ ⟧, any word on screen that is not wrapped was typed
	# into a script rather than taken from the catalogue.
	var pseudo := Translation.new()
	pseudo.locale = "xx"
	for key: String in Strings.rows():
		pseudo.add_message(key, "⟦" + Strings.rows()[key]["en"] + "⟧")
	TranslationServer.add_translation(pseudo)
	Strings.set_locale("xx")
	_seed()
	App.services.store.dispatch(&"heist_finished", {"replay": _golden("planned-clean"),
			"verdict": RulebornReplay.validate(_golden("planned-clean"), PackedByteArray())})
	var bare := []
	for sname: String in SCREENS:
		var screen: Control = await _mount(sname)
		screen.set_process(false)
		await process_frame
		for c in screen.find_children("*", "", true, false):
			if (c is Label or c is Button) and c.visible:
				# A status glyph or a chosen mark may lead the words (UI.status).
				var text: String = RegEx.create_from_string("^[^A-Za-zÀ-ÖØ-öø-ÿ⟦]+").sub(c.text, "")
				if RegEx.create_from_string("[A-Za-zÀ-ÖØ-öø-ÿ]").search(text) and not text.begins_with("⟦"):
					bare.append("%s: %s" % [sname, text.replace("\n", " ")])
		screen.queue_free()
	check("no screen shows a word that is not from the catalogue", bare.is_empty(), "; ".join(bare))
	TranslationServer.remove_translation(pseudo)
	await process_frame

	# §21.1's control rules and §21.8's smallest text, on every screen, in a
	# phone's portrait frame: §21.1's 9:19.5 and an older 9:16. A headless run
	# has no screen, so the window is set to each.
	# Both languages: Portuguese runs longer, and a label that fits in English
	# can push a row into a corner in Portuguese.
	var screens := {}
	# And phase 4b's screens in each language: no catalogue key shown bare and
	# no placeholder left unfilled (§20.6, D99).
	var untranslated := []
	var bare_key := RegEx.create_from_string("\\b[A-Z][A-Z0-9]+_[A-Z0-9_]+\\b|%[0-9]*[sd]")
	for sname: String in PHASE_4B:
		if not Router.ROUTES.values().has("res://scenes/%s.tscn" % sname):
			untranslated.append("%s is not a route" % sname)
	for aspect: Array in [[9, 19.5], [9, 16]]:
		root.size = Vector2i(540, int(540 * aspect[1] / aspect[0]))
		var problems := []
		for locale: String in Strings.LOCALES:
			Strings.set_locale(locale)
			for sname: String in SCREENS:
				var screen: Control = await _mount(sname)
				screen.set_process(false)
				await process_frame
				await process_frame
				for p: Variant in _control_problems(screen):
					problems.append("%s %s: %s" % [locale, sname, p])
				if aspect[1] == 19.5 and sname in PHASE_4B:
					for c in screen.find_children("*", "", true, false):
						if (c is Label or c is Button) and c.is_visible_in_tree() and bare_key.search(c.text):
							untranslated.append("%s %s: %s" % [locale, sname, c.text.replace("\n", " ")])
				screens[sname] = screen
				if locale != Strings.LOCALES[-1] or aspect[1] != 16:
					screen.queue_free()
		check(("every control on every screen is 48 points or more, in the lower two-thirds, "
				+ "clear of corners and safe areas (§21.1), at %s:%s") % aspect,
			problems.is_empty(), "; ".join(problems))
	Strings.set_locale("en")
	check("every phase 4b screen is in the router and, in each of the game's languages, shows no catalogue key bare "
			+ "and no placeholder unfilled (§20.6, D99)", untranslated.is_empty(), "; ".join(untranslated))

	var small := []
	for s: String in SCREENS:
		for l: Label in screens[s].find_children("*", "Label", true, false):
			var size_px: int = l.get_theme_font_size("font_size")
			if size_px < 13 * UI.PX_PER_POINT:
				small.append("%s %s at %d px" % [s, l.name, size_px])
	check("no text on any screen is smaller than 13 points (§21.8)", small.is_empty(), ", ".join(small))

	print("1..%d" % _n)
	# Statics are released before the engine is, or their objects outlive it.
	if App.services != null:
		App.services.close()
	App.services = null
	quit(1 if _failed else 0)


func _catalogue_problems() -> Array:
	var problems := []
	var rows: Dictionary = Strings.rows()
	var placeholder := RegEx.create_from_string("%[0-9]*[sd]")
	for key: String in rows:
		for locale: String in Strings.LOCALES:
			if rows[key].get(locale, "") == "":
				problems.append("%s has no %s" % [key, locale])
		var shape := placeholder.search_all(rows[key]["en"]).map(func(m: RegExMatch) -> String: return m.get_string())
		for locale: String in Strings.LOCALES:
			var other := placeholder.search_all(rows[key].get(locale, "")) \
				.map(func(m: RegExMatch) -> String: return m.get_string())
			if other != shape:
				problems.append("%s: %s has %s where en has %s" % [key, locale, other, shape])
	var asked := RegEx.create_from_string("Strings\\.t\\(\"([A-Za-z_0-9]+)\"\\s*[,)]")
	# Every script the app is built from, not the tests.
	for f: String in _scripts("res://"):
		for m in asked.search_all(FileAccess.get_file_as_string(f)):
			if not rows.has(m.get_string(1)):
				problems.append("%s asks for %s, which the catalogue lacks" % [f, m.get_string(1)])
	return problems


func _test_scripts() -> Array[String]:
	var out: Array[String] = []
	for f in DirAccess.get_files_at("res://tests"):
		if f.ends_with(".gd") and f != "run.gd":
			out.append("res://tests/" + f)
	return out


func _scripts(dir: String) -> Array[String]:
	var out: Array[String] = []
	var d := DirAccess.open(dir)
	if d == null:
		return out
	for f in d.get_files():
		if f.ends_with(".gd"):
			out.append(dir.path_join(f))
	for sub in d.get_directories():
		if not sub.begins_with(".") and sub not in ["tests", "ext", "bin", "goldens"]:
			out.append_array(_scripts(dir.path_join(sub)))
	return out


func _control_problems(screen: Control) -> Array:
	var frame := screen.get_viewport_rect().size
	var point := UI.PX_PER_POINT
	var problems := []
	if frame.y <= frame.x:
		problems.append("the frame is %s, not portrait" % frame)
	# Nothing may ask for more width than the phone has: a label that will not
	# wrap stretches the whole column and pushes every row off-centre.
	var widest := 0.0
	var culprit := ""
	var widest_leaf := ""
	var leaf_w := 0.0
	for c in screen.find_children("*", "Control", true, false):
		var w: float = c.get_combined_minimum_size().x
		widest = max(widest, w)
		# The widest words that will not wrap are usually the ones to fix.
		if (c is Label and (c as Label).autowrap_mode == TextServer.AUTOWRAP_OFF and not (c as Label).clip_text
				or c is Button and (c as Button).autowrap_mode == TextServer.AUTOWRAP_OFF and (c as Button).text != "") \
				and w > leaf_w:
			leaf_w = w
			widest_leaf = " (widest words: %s, %d px)" % [_control_name(screen, c), w]
		# Name the rows that are too wide for the column they sit in.
		if c is HBoxContainer and w > frame.x - 2 * 16 * point:
			var describe := func(k: Variant) -> String:
				var label: String = k.get_class() if k.get("text") == null else k.text.replace("\n", " ")
				return "%s %d px" % [label, k.get_combined_minimum_size().x]
			culprit += " [%s]" % ", ".join(c.get_children().map(describe))
	if widest > frame.x:
		problems.append("something asks for %d px of a %d px frame:%s%s" % [widest, frame.x, culprit, widest_leaf])
	var buttons := screen.find_children("*", "Button", true, false)
	if buttons.is_empty():
		problems.append("no controls")
	for b in buttons:
		# A hidden control is not one the player can reach.
		if not (b as Control).is_visible_in_tree():
			continue
		var r: Rect2 = b.get_global_rect()
		if min(r.size.x, r.size.y) < 48 * point - 0.5:
			problems.append("%s is %s across" % [_control_name(screen, b), r.size])
		if r.position.x < 0 or r.end.x > frame.x:
			problems.append("%s is off the screen" % _control_name(screen, b))
		# A control in a scrolling list is wherever the player scrolls it; the
		# place rules hold for what does not move.
		if _scrolls(b):
			continue
		# §21.1: the thumb zone binds frequently used controls; one marked
		# otherwise (home's Keeper badge, its strain) keeps the other rules.
		if r.position.y < frame.y / 3.0 and b.get_meta("frequent", true):
			problems.append("%s is above the thumb zone" % b.text)
		if r.end.y > frame.y - 44 * point or r.position.y < 44 * point:
			problems.append("%s is inside a safe area" % _control_name(screen, b))
		var corner := Vector2(frame.x * 0.15, frame.y * 0.08)
		if (r.position.x < corner.x or r.end.x > frame.x - corner.x) and r.end.y > frame.y - corner.y:
			problems.append("%s is in a corner at %s of %s" % [_control_name(screen, b), r, frame])
	return problems


## A control as a failure names it: its words, or what a screen reader says
## for it, then its path from the screen.
func _control_name(screen: Control, c: Node) -> String:
	var words := str(c.get("text")) if c.get("text") != null else ""
	if words == "":
		words = str((c as Control).accessibility_name)
	return "\"%s\" (%s %s)" % [words.replace("\n", " "), c.get_class(), str(screen.get_path_to(c))]


func _scrolls(c: Node) -> bool:
	var p := c.get_parent()
	while p != null:
		if p is ScrollContainer:
			return true
		p = p.get_parent()
	return false
