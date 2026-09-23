extends SceneTree
## The client's tests, headless, as TAP: `ok N - name` or `not ok N - name`.
## client/status.py runs them and writes client/status.json, which is what
## tools/completion.py reads — results, not claims.

## A test that errors stops its coroutine, and a stopped coroutine never
## quits; so the run has a deadline, and missing it is a failure.
const DEADLINE_SECONDS := 120.0
const SCREENS := ["home", "heist_screen", "result_screen", "replay_screen"]

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
	var goldens := ReplayScreen.find_goldens()

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
	var log := heist.world.commands().map(func(c): return [c["tick"], c["actor"], c["kind"], c["x"], c["y"]])
	var want := [[now, 1, HeistScreen.Kind.MOVE_TO, 4 * 256 + 128, 5 * 256 + 128],
		[now, 1, HeistScreen.Kind.CRACK, 0, 0], [now, 1, HeistScreen.Kind.LOAD, 70, 0],
		[now, 1, HeistScreen.Kind.SKIFF, 13 * 256 + 128, 7 * 256 + 128]]
	check("every tap on the heist screen makes the one command it names, stamped with the tick it was made",
		log == want, "got %s" % [log])

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

	# §21.1's control rules and §21.8's smallest text, on every screen, in a
	# phone's portrait frame: §21.1's 9:19.5 and an older 9:16. A headless run
	# has no screen, so the window is set to each.
	var screens := {}
	for s in SCREENS:
		screens[s] = await _mount(s)
		screens[s].set_process(false)
		screens[s].visible = false
	for aspect in [[9, 19.5], [9, 16]]:
		root.size = Vector2i(540, int(540 * aspect[1] / aspect[0]))
		var problems := []
		for s in SCREENS:
			for other in SCREENS:
				screens[other].visible = other == s
			await process_frame
			await process_frame
			for p in _control_problems(screens[s]):
				problems.append("%s: %s" % [s, p])
		check("every control on every screen is 48 points or more, in the lower two-thirds, clear of corners and safe areas (§21.1), at %s:%s" % aspect,
			problems.is_empty(), "; ".join(problems))

	var small := []
	for s in SCREENS:
		for l in screens[s].find_children("*", "Label", true, false):
			var size_px: int = l.get_theme_font_size("font_size")
			if size_px < 13 * UI.PX_PER_POINT:
				small.append("%s %s at %d px" % [s, l.name, size_px])
	check("no text on any screen is smaller than 13 points (§21.8)", small.is_empty(), ", ".join(small))

	print("1..%d" % _n)
	quit(1 if _failed else 0)


func _control_problems(screen: Control) -> Array:
	var frame := screen.get_viewport_rect().size
	var point := UI.PX_PER_POINT
	var problems := []
	if frame.y <= frame.x:
		problems.append("the frame is %s, not portrait" % frame)
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
