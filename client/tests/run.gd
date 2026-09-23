extends SceneTree
## The client's tests, headless, as TAP: `ok N - name` or `not ok N - name`.
## client/status.py runs them and writes client/status.json, which is what
## tools/completion.py reads — results, not claims.

var _n := 0
var _failed := 0


func check(name: String, passed: bool, detail := "") -> void:
	_n += 1
	if passed:
		print("ok %d - %s" % [_n, name])
	else:
		_failed += 1
		print("not ok %d - %s" % [_n, name])
		if detail != "":
			print("  # " + detail)


func _control_problems(screen: ReplayScreen) -> Array:
	var frame := screen.get_viewport_rect().size
	var point := ReplayScreen.PX_PER_POINT
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


func _play(name: String) -> RulebornReplay:
	var r := RulebornReplay.new()
	if not r.load(FileAccess.get_file_as_bytes("res://goldens/%s.rbh" % name), PackedByteArray()):
		return null
	while r.step():
		pass
	return r


## A test that errors stops its coroutine, and a stopped coroutine never
## quits; so the run has a deadline, and missing it is a failure.
const DEADLINE_SECONDS := 120.0


func _initialize() -> void:
	create_timer(DEADLINE_SECONDS).timeout.connect(func():
		print("not ok %d - the tests finished inside %d seconds" % [_n + 1, DEADLINE_SECONDS])
		quit(1))
	_run()


func _run() -> void:
	var goldens := ReplayScreen.find_goldens()

	# §24.7: one simulation, compiled for every target. The client's build must
	# be the server's, rule for rule.
	var versions := {}
	for g in goldens:
		var r := RulebornReplay.new()
		r.load(FileAccess.get_file_as_bytes("res://goldens/%s.rbh" % g), PackedByteArray())
		versions[r.rules()] = true
	check("the client's simulation is the rules version every golden replay names",
		goldens.size() > 0 and versions.keys() == [RulebornReplay.rules_version()],
		"client %s, goldens %s" % [RulebornReplay.rules_version(), versions.keys()])

	# §24.10: the checksums a replay carries, one a second, are the server's.
	var bad := []
	var seconds := 0
	for g in goldens:
		var r := _play(g)
		if r == null or r.mismatch() != 0 or r.seconds_agreed() * RulebornReplay.ticks_per_second() != r.ticks():
			bad.append(g)
		elif r != null:
			seconds += r.seconds_agreed()
	check("every golden replay re-simulates in the client, every second agreeing with its checksums",
		goldens.size() >= 5 and bad.is_empty(), "diverged: %s; %d seconds agreed" % [bad, seconds])

	var planned := _play("planned-clean")
	var o := planned.outcome() if planned else {}
	check("the planned heist plays out Clean with every bag banked (§12.9)",
		o.get("grade") == "Clean" and o.get("banked") == o.get("capacity") and o.get("capacity", 0) > 0,
		str(o))

	# The screen itself: played to the end, it shows the heist's grade.
	var screen: ReplayScreen = load("res://scenes/replay_screen.tscn").instantiate()
	root.add_child(screen)
	await process_frame
	screen.open_golden(goldens.find("planned-clean"))
	screen.advance(100000)
	check("the replay screen plays a golden to its end and shows its grade",
		screen.grade_label.text.begins_with("Clean") and screen.badge_label.text.begins_with("Matches"),
		"%s / %s" % [screen.grade_label.text, screen.badge_label.text])

	# §21.1's control rules, on every button the screen has, in a phone's
	# portrait frame: §21.1's 9:19.5 and an older 9:16. A headless run has
	# no screen, so the window is set to each.
	for aspect in [[9, 19.5], [9, 16]]:
		root.size = Vector2i(540, int(540 * aspect[1] / aspect[0]))
		await process_frame
		await process_frame
		var problems := _control_problems(screen)
		check("every control is 48 points or more, in the lower two-thirds, clear of corners and safe areas (§21.1), at %s:%s" % aspect,
			problems.is_empty(), "; ".join(problems))

	var small := []
	for l in screen.find_children("*", "Label", true, false):
		var size_px: int = l.get_theme_font_size("font_size")
		if size_px < 13 * ReplayScreen.PX_PER_POINT:
			small.append("%s at %d px" % [l.name, size_px])
	check("no text is smaller than 13 points (§21.8)", small.is_empty(), ", ".join(small))

	print("1..%d" % _n)
	quit(1 if _failed else 0)
