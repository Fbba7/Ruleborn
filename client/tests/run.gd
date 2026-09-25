extends SceneTree
## The client's tests, headless, as TAP: `ok N - name` or `not ok N - name`.
## client/status.py runs them and writes client/status.json, which is what
## tools/completion.py reads — results, not claims.

## A test that errors stops its coroutine, and a stopped coroutine never
## quits; so the run has a deadline, and missing it is a failure.
const DEADLINE_SECONDS := 120.0
const SCREENS := ["home", "heist_screen", "result_screen", "replay_screen", "settings", "builder"]

var _n := 0
var _failed := 0


func _initialize() -> void:
	create_timer(DEADLINE_SECONDS).timeout.connect(func():
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


func _golden(name: String) -> PackedByteArray:
	return FileAccess.get_file_as_bytes("res://goldens/%s.rbh" % name)


func _mount(scene: String) -> Control:
	var node: Control = load("res://scenes/%s.tscn" % scene).instantiate()
	root.add_child(node)
	await process_frame
	return node


func _run() -> void:
	# The offline tests first, with no server; status.py names one for the end.
	var server_url := OS.get_environment("RULEBORN_SERVER")
	OS.unset_environment("RULEBORN_SERVER")
	# The tests' own settings file, so a run never touches a player's.
	Settings.path = "user://settings-test.cfg"
	BuilderScreen.path = "user://island-test.rbi"
	DirAccess.remove_absolute(BuilderScreen.path)
	DirAccess.remove_absolute(Settings.path)
	Settings.restore()
	Settings.change(func(): Settings.locale = "en")
	var goldens := ReplayScreen.find_goldens()

	# §20.6's two launch languages: every key a script asks for is in the
	# catalogue, in every language, with the same placeholders.
	check("every string a screen asks for is in the catalogue, in English and Brazilian Portuguese, with the same placeholders",
		_catalogue_problems().is_empty(), "; ".join(_catalogue_problems()))

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
		HeistScreen.lease_era({"era": null}) == "" and HeistScreen.lease_era({}) == ""
			and HeistScreen.lease_era({"era": "glass_moon"}) == "glass_moon"
			and in_era.set_era("glass_moon") and in_era.set_era("") and not in_era.set_era("<null>"))

	# The Data safety form's "encrypted in transit": no server but this
	# machine's own is spoken to over plain HTTP.
	check("the client speaks to a server over HTTPS only, plain HTTP to this machine's own for tests",
		Session.secure("https://edge.example/") and Session.secure("http://127.0.0.1:8787")
			and Session.secure("http://localhost/v1") and not Session.secure("http://edge.example")
			and not Session.secure("http://127.0.0.1.edge.example/") and not Session.secure("ftp://x"))

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
		replay_screen.grade_label.text.begins_with("Clean") and replay_screen.badge_label.text.begins_with("Matches"),
		"%s / %s" % [replay_screen.grade_label.text, replay_screen.badge_label.text])
	replay_screen.queue_free()

	# Taps become commands (§24.10: "a move or an ability with its tick, crew
	# member and target"): each control makes exactly one, stamped now.
	var heist: HeistScreen = await _mount("heist_screen")
	heist.set_process(false)
	heist.advance(90)
	var now := heist.world.tick()
	heist.select(1)
	heist.tap_tile(Vector2i(4, 5))
	heist.crack()
	heist.load_up(70)
	heist.get_out()
	heist.tap_tile(Vector2i(13, 7))
	# The landing the screen gives before its first step is not a tap.
	var log := heist.world.commands().filter(func(c): return int(c["kind"]) != HeistScreen.Kind.LAND) \
		.map(func(c): return [c["tick"], c["actor"], c["kind"], c["x"], c["y"]])
	var want := [[now, 1, HeistScreen.Kind.MOVE_TO, 4 * 256 + 128, 5 * 256 + 128],
		[now, 1, HeistScreen.Kind.CRACK, 0, 0], [now, 1, HeistScreen.Kind.LOAD, 70, 0],
		[now, 1, HeistScreen.Kind.SKIFF, 13 * 256 + 128, 7 * 256 + 128]]
	check("every tap on the heist screen makes the one command it names, stamped with the tick it was made",
		log == want, "got %s" % [log])

	# A tap is read by what is on the tile, and each is the one command the
	# player chose (§12.18): a guard is attacked, the Vault cracked, a pylon
	# broken, a ward disarmed. The gait button walks, crouches and runs.
	heist.begin(HeistScreen.SEED, HeistScreen.TICKS, HeistScreen.CREW)
	heist.select(1)
	var first: Dictionary = heist.world.guards()[1]
	var pylon := -1
	var features := heist.world.features()
	for i in features.size():
		if features[i] == RealmView.Tile.PYLON:
			pylon = i
			break
	var width := heist.world.size().x
	var ward: Dictionary = heist.world.wards()[0] if heist.world.wards().size() > 0 else {}
	heist.tap_tile(Vector2i(first["at"]))
	heist.tap_tile(Vector2i(heist.world.vault()["at"]))
	heist.tap_tile(Vector2i(pylon % width, pylon / width))
	if not ward.is_empty():
		heist.tap_tile(Vector2i(ward["at"]))
	heist.next_gait()
	heist.advance(1)
	heist.next_gait()
	heist.advance(1)
	heist.next_gait()
	heist.halt()
	heist.drop_half()
	var kinds := heist.world.commands().filter(func(c): return int(c["kind"]) != HeistScreen.Kind.LAND) \
		.map(func(c): return [c["kind"], c["x"]])
	var K := HeistScreen.Kind
	var expected := [[K.ATTACK, 1], [K.CRACK, 0], [K.BREAK, (pylon % width) * 256 + 128]]
	if not ward.is_empty():
		expected.append([K.DISARM, int(Vector2i(ward["at"]).x) * 256 + 128])
	expected += [[K.GAIT, 1], [K.GAIT, 2], [K.GAIT, 0], [K.HALT, 0], [K.DROP, 50]]
	check("a tap on a guard, the Vault, a pylon or a ward makes the command it calls for, and the gait button cycles walk, crouch, run",
		kinds == expected and pylon >= 0 and not ward.is_empty(), "got %s, wanted %s" % [kinds, expected])

	# §5.4: the crew lands together on the edge tile the player chose, and the
	# log says so at tick 0; once the heist has begun, it has landed.
	heist.begin(HeistScreen.SEED, HeistScreen.TICKS, HeistScreen.CREW)
	var spots := heist.world.landings()
	var spot: Vector2i = spots[spots.size() - 1] if spots.size() > 0 else Vector2i(-1, -1)
	var chose := heist.land(spot)
	heist.advance(1)
	var together := heist.world.crew().all(func(r): return Vector2i(r["at"]) == spot)
	var logged := heist.world.commands().filter(func(c): return int(c["kind"]) == HeistScreen.Kind.LAND)
	check("the crew lands together on the open edge tile the player chose, recorded at tick 0 (5.4)",
		chose and together and logged.size() == 1 and int(logged[0]["tick"]) == 0 and not heist.land(spots[0]),
		"spot %s, crew %s, log %s" % [spot, heist.world.crew().map(func(r): return r["at"]), logged])

	# And the heist it plays is the heist it records. The planned golden's
	# commands, given live at their ticks on the heist screen, must record the
	# golden byte for byte, which the server's check then grades Clean.
	var golden := RulebornReplay.new()
	golden.load(_golden("planned-clean"), PackedByteArray())
	heist.begin(golden.seed(), golden.ticks(), golden.crew_size())
	var pending := golden.commands()
	var k := 0
	while heist.playing:
		while k < pending.size() and int(pending[k]["tick"]) == heist.world.tick():
			var c: Dictionary = pending[k]
			heist.world.give(c["actor"], c["kind"], c["x"], c["y"])
			k += 1
		heist.advance(1)
	var v := Session.verdict
	check("a heist played live on the heist screen records the golden replay byte for byte, and the server's check grades it Clean",
		Session.replay == _golden("planned-clean") and v.get("ok", false) and v.get("grade") == "Clean",
		"%d bytes against %d; %s" % [Session.replay.size(), _golden("planned-clean").size(), v])
	var again := _play(Session.replay)
	check("the heist just played replays on this phone with every second agreeing",
		again != null and again.mismatch() == 0
			and again.seconds_agreed() * RulebornReplay.ticks_per_second() == again.ticks(),
		"mismatch %s" % (again.mismatch() if again else "unloadable"))
	var refused := RulebornReplay.validate(Session.replay.slice(0, Session.replay.size() - 4) + PackedByteArray([0, 0, 0, 0]), PackedByteArray())
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
		check("a heist leased from the server, played on the heist screen and submitted is re-simulated and paid by the server",
			false, "no server: run through client/status.py, which starts one")
	else:
		OS.set_environment("RULEBORN_SERVER", server_url)
		var online: HeistScreen = load("res://scenes/heist_screen.tscn").instantiate()
		root.add_child(online)
		online.set_process(false)
		for i in 600:
			if not online.lease.is_empty() or online.hint_label.text.begins_with("No heist"):
				break
			await process_frame
		var played := {}
		if not online.lease.is_empty():
			var go := func(seconds: int): online.advance(seconds * 30 - online.world.tick())
			online.land(Vector2i(0, 0))                   # where server/test lands it
			for step in [[0, Vector2i(6, 8)], [1, Vector2i(7, 9)], [2, Vector2i(5, 9)]]:
				online.select(step[0])
				online.tap_tile(step[1])
			go.call(15)
			for m in 3:
				online.select(m)
				online.crack()
			go.call(50)
			for m in 3:
				online.select(m)
				online.load_up(100)
			online.select(0)
			online.get_out()
			online.tap_tile(Vector2i(6, 11))
			go.call(62)
			for m in 3:
				online.select(m)
				online.tap_tile(Vector2i(6, 11))
			online.advance(int(online.lease["ticks"]))
			if Session.verdict.is_empty() or not Session.verdict.get("server", false):
				await online.finished
			played = Session.verdict
		# Vault level 3: 5,400 × 1 × 1 × 1 × 1 × fill 1 (server/test's figure).
		check("a heist leased from the server, played on the heist screen and submitted is re-simulated and paid by the server",
			played.get("ok", false) and played.get("grade") == "Clean" and int(played.get("haul", 0)) == 5400,
			"%s; %s" % [played, online.hint_label.text])
		online.queue_free()
		OS.unset_environment("RULEBORN_SERVER")
		await process_frame

	# §20.6's settings survive a relaunch: each change on the settings screen
	# is saved as it is made, and the next launch reads it back and applies it.
	var settings: SettingsScreen = await _mount("settings")
	var minus: Array = settings.find_children("*", "Button", true, false).filter(func(b): return b.text == "−")
	for i in 7:
		minus[0].pressed.emit()
	minus[1].pressed.emit()
	settings.motion_button.pressed.emit()
	settings.language_button.pressed.emit()
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
	check("settings changed on the settings screen are saved as they change and restored on the next launch: language, three volumes, reduced motion, haptics (§20.6)",
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
	Settings.change(func(): Settings.locale = "en")
	await process_frame

	# The builder (§13): ground on the grid, laws and their pylons, and a raid
	# on what was built — every edit through the simulation's own island.
	var builder: BuilderScreen = await _mount("builder")
	builder.tool = BuilderScreen.Tool.GROUND
	var laid := {Vector2i(2, 4): "rock_pillar", Vector2i(3, 4): "gravel_path",
		Vector2i(4, 4): "stream", Vector2i(5, 4): "raised_ground", Vector2i(6, 4): "tall_grass"}
	for at in laid:
		builder.kind = builder.kinds().find(laid[at])
		builder.tap_tile(at)
	var reread := RulebornIsland.new()
	var same := reread.read(builder.island.bytes())
	for at in laid:
		same = same and reread.ground(at.x, at.y) == laid[at] and builder.island.ground(at.x, at.y) == laid[at]
	var side := builder.island.side()
	var drawn := builder.preview.features()[4 * side + 2] == RealmView.Tile.ROCK_PILLAR \
		and builder.preview.surfaces()[4 * side + 4] == 2
	check("the builder lays §6.2's ground on the realm's grid, and the island it writes reads back the same",
		same and drawn and builder.island.problems().is_empty(), "%s" % builder.island.problems())

	builder.tool = BuilderScreen.Tool.LAW
	for step in [["haste", Vector2i(1, 10)], ["brittle_stone", Vector2i(11, 2)]]:
		builder.kind = builder.kinds().find(step[0])
		builder.tap_tile(step[1])
	var pylons := builder.island.occupant(1, 10) == "pylon:haste" and builder.island.occupant(11, 2) == "pylon:brittle_stone"
	var harmony := builder.together_label.text.contains(Strings.t("NOTE_SPARK"))
	var ready := not builder.raid_button.disabled
	builder.kind = builder.kinds().find("glowing_dark")
	builder.tap_tile(Vector2i(8, 8))
	var over := builder.island.problems().has("TooManyLaws") and builder.raid_button.disabled \
		and builder.status_label.text.contains(Strings.t("PROBLEM_TOOMANYLAWS"))
	var chord := "wild_hunt" in Array(builder.island.combos()["chords"])
	check("the builder weaves laws and places their pylons, holds the realm to its law slots, and names what the laws make together (§8.6)",
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
	builder.raid()
	var built := builder.island.bytes()
	var kept := FileAccess.get_file_as_bytes(BuilderScreen.path) == built
	builder.queue_free()
	await process_frame
	var own: HeistScreen = await _mount("heist_screen")
	own.set_process(false)
	var on_own := own.island == built and Session.testing
	own.advance(own.world.ticks())
	var judged := Session.verdict
	own.queue_free()
	await process_frame
	var after: ResultScreen = await _mount("result_screen")
	var way_back := after.find_children("*", "Button", true, false).any(
		func(b): return b.text == Strings.t("RESULT_BUILDER"))
	after.queue_free()
	Session.testing = false
	await process_frame
	check("a player can raid their own island from the builder: the heist plays it, the server's check judges it, and the result leads back",
		kept and on_own and judged.get("ok", false) and way_back, "%s" % judged)

	# No screen holds text of its own. In a pseudo-locale that wraps every
	# catalogue string in ⟦ ⟧, any word on screen that is not wrapped was typed
	# into a script rather than taken from the catalogue.
	var pseudo := Translation.new()
	pseudo.locale = "xx"
	for key in Strings.rows():
		pseudo.add_message(key, "⟦" + Strings.rows()[key]["en"] + "⟧")
	TranslationServer.add_translation(pseudo)
	Strings.set_locale("xx")
	Session.verdict = RulebornReplay.validate(_golden("planned-clean"), PackedByteArray())
	var bare := []
	for sname in SCREENS:
		var screen: Control = await _mount(sname)
		screen.set_process(false)
		await process_frame
		for c in screen.find_children("*", "", true, false):
			if (c is Label or c is Button) and c.visible:
				var text: String = c.text
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
	for aspect in [[9, 19.5], [9, 16]]:
		root.size = Vector2i(540, int(540 * aspect[1] / aspect[0]))
		var problems := []
		for locale in Strings.LOCALES:
			Strings.set_locale(locale)
			for sname in SCREENS:
				var screen: Control = await _mount(sname)
				screen.set_process(false)
				await process_frame
				await process_frame
				for p in _control_problems(screen):
					problems.append("%s %s: %s" % [locale, sname, p])
				screens[sname] = screen
				if locale != Strings.LOCALES[-1] or aspect[1] != 16:
					screen.queue_free()
		check("every control on every screen is 48 points or more, in the lower two-thirds, clear of corners and safe areas (§21.1), at %s:%s" % aspect,
			problems.is_empty(), "; ".join(problems))
	Strings.set_locale("en")

	var small := []
	for s in SCREENS:
		for l in screens[s].find_children("*", "Label", true, false):
			var size_px: int = l.get_theme_font_size("font_size")
			if size_px < 13 * UI.PX_PER_POINT:
				small.append("%s %s at %d px" % [s, l.name, size_px])
	check("no text on any screen is smaller than 13 points (§21.8)", small.is_empty(), ", ".join(small))

	print("1..%d" % _n)
	quit(1 if _failed else 0)


func _catalogue_problems() -> Array:
	var problems := []
	var rows: Dictionary = Strings.rows()
	var placeholder := RegEx.create_from_string("%[0-9]*[sd]")
	for key in rows:
		for locale in Strings.LOCALES:
			if rows[key].get(locale, "") == "":
				problems.append("%s has no %s" % [key, locale])
		var shape := placeholder.search_all(rows[key]["en"]).map(func(m): return m.get_string())
		for locale in Strings.LOCALES:
			var other := placeholder.search_all(rows[key].get(locale, "")).map(func(m): return m.get_string())
			if other != shape:
				problems.append("%s: %s has %s where en has %s" % [key, locale, other, shape])
	var asked := RegEx.create_from_string("Strings\\.t\\(\"([A-Za-z_0-9]+)\"\\s*[,)]")
	var dir := DirAccess.open("res://scripts")
	for f in dir.get_files():
		if not f.ends_with(".gd"):
			continue
		for m in asked.search_all(FileAccess.get_file_as_string("res://scripts/" + f)):
			if not rows.has(m.get_string(1)):
				problems.append("%s asks for %s, which the catalogue lacks" % [f, m.get_string(1)])
	return problems


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
	for c in screen.find_children("*", "Control", true, false):
		var w: float = c.get_combined_minimum_size().x
		widest = max(widest, w)
		# Name the rows that are too wide for the column they sit in.
		if c is HBoxContainer and w > frame.x - 2 * 16 * point:
			culprit += " [%s]" % ", ".join(c.get_children().map(func(k): return "%s %d px" % [k.get_class() if k.get("text") == null else k.text.replace("\n", " "), k.get_combined_minimum_size().x]))
	if widest > frame.x:
		problems.append("something asks for %d px of a %d px frame:%s" % [widest, frame.x, culprit])
	var buttons := screen.find_children("*", "Button", true, false)
	if buttons.is_empty():
		problems.append("no controls")
	for b in buttons:
		var r: Rect2 = b.get_global_rect()
		if min(r.size.x, r.size.y) < 48 * point - 0.5:
			problems.append("%s is %s across" % [b.text, r.size])
		if r.position.y < frame.y / 3.0:
			problems.append("%s is above the thumb zone" % b.text)
		if r.end.y > frame.y - 44 * point or r.position.y < 44 * point:
			problems.append("%s is inside a safe area" % b.text)
		var corner := Vector2(frame.x * 0.15, frame.y * 0.08)
		if (r.position.x < corner.x or r.end.x > frame.x - corner.x) and r.end.y > frame.y - corner.y:
			problems.append("%s is in a corner" % b.text)
		if r.position.x < 0 or r.end.x > frame.x:
			problems.append("%s is off the screen" % b.text)
	return problems
