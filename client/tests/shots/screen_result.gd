extends SceneTree
## The result screen after a golden heist, the island in 3D behind the
## outcome card (tools/render/shoot.sh). SHOT is the file; GOLDEN and HOUR
## are optional; CONTRAST is high contrast, and FIT fails the run when any
## words do not fit (P2-S1-result-1). The still is taken once the reward
## sequence has ended, at rest.
##
## STRIP=<folder> records the reward sequence instead (P2-S1-result-2): the
## screen's tweens stepped by a thirtieth of a second a frame, whatever the
## renderer's speed, each frame saved whole (full_NNN.png) and cut to the
## hero and the reward tiles (crop_NNN.png). REDUCED records its
## reduced-motion form.

## A recorded frame's length, in seconds.
const STEP := 1.0 / 30.0
## How long a strip runs before the reward starts and after it ends.
const LEAD := 0.3
const TAIL := 0.4


func _initialize() -> void:
	_go()


func _go() -> void:
	cast()
	WorldView.heist_perspective = OS.get_environment("ORTHO") == ""
	# A phone's frame of its own, so the still is 1080 by 2340 whatever the
	# window does.
	var frame := SubViewport.new()
	frame.size = Vector2i(1080, 2340)
	frame.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(frame)
	App.services = Fixtures.answered(Services.build(frame, "", null, "user://outbox-shot.json"))
	if OS.get_environment("LOCALE") != "":
		Strings.set_locale(OS.get_environment("LOCALE"))
	if OS.get_environment("TEXT") != "":
		Settings.text_scale = int(OS.get_environment("TEXT"))
		Settings.apply()
	if OS.get_environment("CONTRAST") != "":
		# Only set, never cleared: the guard's high-contrast shot sets it
		# before this script runs.
		Settings.high_contrast = true
		Settings.apply()
	# The golden clean heist on the fixture realm: what the result shows when
	# a heist pays. GOLDEN picks another.
	var golden := OS.get_environment("GOLDEN") if OS.get_environment("GOLDEN") != "" else "planned-clean"
	var replay := FileAccess.get_file_as_bytes("res://goldens/%s.rbh" % golden)
	App.services.store.dispatch(&"heist_started", {})
	var verdict := RulebornReplay.validate(replay, PackedByteArray())
	if OS.get_environment("SERVER") != "":
		# SERVER: the server's settle answer as HeistController.settled reads
		# it, with the design's split (Starlight, Essence, Renown) and fee.
		var paid := str(verdict.get("grade", "")) != "Foiled"
		verdict.merge({"server": true, "haul": 3115, "fee": 2840, "fee_returned": 2840 if paid else 0,
			"starlight": 2310 if paid else 0, "essence": 805 if paid else 0, "renown": 15 if paid else -8,
			"token": "shot", "rest": {"crew": 5, "minutes": 180 if not paid else 45}}, true)
	App.services.store.dispatch(&"heist_finished", {"replay": replay, "verdict": verdict})
	var strip := OS.get_environment("STRIP")
	if OS.get_environment("REDUCED") != "":
		Settings.reduced_motion = true
	var screen: Control = load("res://scenes/result_screen.tscn").instantiate()
	(screen as ResultScreen).hold_reward = strip != ""
	frame.add_child(screen)
	if (screen as ResultScreen).world_view != null:
		var hour := int(OS.get_environment("HOUR")) if OS.get_environment("HOUR") != "" else 18
		(screen as ResultScreen).world_view.set_sky_hour(hour)
	settle(root)
	for i in 30:
		await process_frame
	if strip != "":
		await record(screen as ResultScreen, frame, strip)
		quit()
		return
	# The page at rest: the reward played out and its sprites gone.
	var waited := 0
	while not (screen as ResultScreen).reward_done and waited < 1200:
		await process_frame
		waited += 1
	if not (screen as ResultScreen).reward_done:
		print("reward FAIL: still playing after %d frames" % waited)
		quit(1)
		return
	for i in 3:
		await process_frame
	await RenderingServer.frame_post_draw
	if OS.get_environment("FIT") != "":
		var bad := fit(screen)
		for b: String in bad:
			print("fit FAIL ", b)
		print("fit ", "ok" if bad.is_empty() else "FAIL")
		if not bad.is_empty():
			quit(1)
			return
	# §21.3's budgets, as the renderer counted the frame.
	print("budget: %d draw calls, %d primitives" % [
		RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_DRAW_CALLS_IN_FRAME),
		RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_PRIMITIVES_IN_FRAME)])
	frame.get_texture().get_image().save_png(OS.get_environment("SHOT"))
	print("wrote ", verdict)
	quit()


## The reward sequence frame by frame into `dir`: every tween of the tree
## held and stepped by STEP (the landings' own tweens too, as they start),
## from LEAD before the reward to TAIL after it.
func record(screen: ResultScreen, frame: SubViewport, dir: String) -> void:
	DirAccess.make_dir_recursive_absolute(dir)
	screen.set_process(false)
	_hold()
	var t := 0.0
	var ended := -1.0
	var n := 0
	while t < 8.0:
		if n == roundi(LEAD / STEP):
			screen.start_reward()
			_hold()
		if n > roundi(LEAD / STEP) and screen.reward_done and ended < 0.0:
			ended = t
		if ended >= 0.0 and t - ended >= TAIL:
			break
		await process_frame
		await RenderingServer.frame_post_draw
		var image := frame.get_texture().get_image()
		image.save_png(dir.path_join("full_%03d.png" % n))
		image.get_region(_cut(screen, image.get_size())).save_png(dir.path_join("crop_%03d.png" % n))
		for tw: Tween in get_processed_tweens():
			if tw.is_valid():
				tw.custom_step(STEP)
		_hold()
		t += STEP
		n += 1
	print("strip: %d frames, the reward over in %.2f s" % [n, ended - LEAD])


## Every tween of the tree held, to be stepped by hand.
func _hold() -> void:
	for tw: Tween in get_processed_tweens():
		if tw.is_valid() and tw.is_running():
			tw.pause()


## The frame cut to the hero and the reward tiles, the coins' whole flight,
## across the phone's width.
static func _cut(screen: ResultScreen, size: Vector2i) -> Rect2i:
	var top := screen.grade_icon.get_global_rect().position.y - 160.0
	var tiles: Control = screen.haul_tile
	if screen.reward_row.visible:
		tiles = screen.reward_row
	var foot := tiles.get_global_rect().end.y + 60.0
	var y := clampi(int(top), 0, size.y - 1)
	return Rect2i(0, y, size.x, clampi(int(foot) - y, 1, size.y - y))


## What does not fit on `screen`, one line each: a label's words wider than
## a label that does not wrap, a label outside its panel, or anything wider
## than the phone (the page scrolls down, never across).
static func fit(screen: Control) -> Array[String]:
	var bad: Array[String] = []
	var wide := screen.size.x
	for l: Label in screen.find_children("*", "Label", true, false):
		if not l.is_visible_in_tree() or l.text == "":
			continue
		var at := l.get_global_rect()
		var font := l.get_theme_font("font")
		var words := 0.0
		for line: String in l.text.split("\n"):
			words = maxf(words, font.get_string_size(line, HORIZONTAL_ALIGNMENT_LEFT, -1,
				l.get_theme_font_size("font_size")).x)
		if l.autowrap_mode == TextServer.AUTOWRAP_OFF and not l.clip_text and words > at.size.x + 1.0:
			bad.append("%s %s: %.0f px of words in %.0f" % [l.get_path(), l.text, words, at.size.x])
		if l.clip_text and words > at.size.x + 1.0:
			bad.append("%s %s: cut, %.0f px of words in %.0f" % [l.get_path(), l.text, words, at.size.x])
		var p := l.get_parent()
		while p != null and not p is PanelContainer:
			p = p.get_parent()
		if p != null and not (p as Control).get_global_rect().grow(1.0).encloses(at):
			bad.append("%s %s: %s outside its panel %s" % [l.get_path(), l.text, at, (p as Control).get_global_rect()])
		if at.position.x < -1.0 or at.end.x > wide + 1.0:
			bad.append("%s %s: %s off the phone's width" % [l.get_path(), l.text, at])
	for b: Button in screen.find_children("*", "Button", true, false):
		var at := b.get_global_rect()
		if not b.is_visible_in_tree():
			continue
		if at.position.x < -1.0 or at.end.x > wide + 1.0:
			bad.append("%s %s: %s off the phone's width" % [b.get_path(), b.text, at])
		# A button's longest word must fit its room: its width less its
		# padding and its icon (a word too long is cut, or wraps by letters).
		var room := at.size.x - b.get_theme_stylebox("normal").get_minimum_size().x
		if b.icon != null:
			var mark := float(b.icon.get_width())
			if b.get_theme_constant("icon_max_width") > 0:
				mark = minf(mark, b.get_theme_constant("icon_max_width"))
			room -= mark + b.get_theme_constant("h_separation")
		var font := b.get_theme_font("font")
		var font_px := b.get_theme_font_size("font_size")
		for word: String in b.text.split(" ", false):
			var w := font.get_string_size(word, HORIZONTAL_ALIGNMENT_LEFT, -1, font_px).x
			if w > room + 1.0:
				bad.append("%s %s: the word %s is %.0f px in %.0f" % [b.get_path(), b.text, word, w, room])
	# The whole haul on the first screen, inside the viewport and above the
	# actions, whatever the text size and language (AD's objection B).
	var result := screen as ResultScreen
	if result.reward_row.visible:
		var top := screen.size.y
		if not result._ending.is_empty():
			top = minf(top, (result._ending[0] as Control).get_global_rect().position.y)
		for kind: String in result.reward_labels:
			var tile := (result.reward_labels[kind] as Label).get_parent().get_parent() as Control
			if tile.get_global_rect().end.y > top + 1.0:
				bad.append("reward %s: ends at %.0f px, under the first screen's %.0f" % [kind,
					tile.get_global_rect().end.y, top])
	return bad


## The integrator's cast of character models, until the app sets one: each
## role's default kind, guards as Glass Golems in the guard form (CAST).
static func cast() -> void:
	if WorldView.figure_maker.is_valid() or OS.get_environment("CAST") == "":
		return
	var kinds := {"Scout": &"featherkin", "Breaker": &"rambler", "Carrier": &"skyskipper", "Warden": &"mossbear",
		"Mender": &"hourkeeper", "guard": &"glassgolem"}
	WorldView.figure_maker = func(role: String, _height: float) -> Node3D:
		var c := CreatureModel.make(kinds.get(role, &"featherkin"))
		if c != null and role == "guard":
			c.set_guard(true)
		return c


## Let each character model's clip play on as it would have in real time,
## since a shot runs a heist's seconds in a few frames.
func settle(node: Node) -> void:
	for c in node.find_children("*", "CreatureModel", true, false):
		var p: AnimationPlayer = (c as CreatureModel).player()
		if p != null:
			p.advance(2.0)
