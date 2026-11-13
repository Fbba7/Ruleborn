extends RefCounted
## The kit tests' checks of Motion (tests/ui_kit_tests.gd; report.md steps 4
## and 8): the baked curves it reads and the tokens that stand in for them,
## the press, the reward sequence, the idle shine and the screen change, each
## timed frame by frame (150 to 250 ms a step, easing out, nothing past its
## end value) and in its reduced form (§21.8, §20.8). A helper, not a shot.
## Each function returns what is wrong, one line each.

## The kit's token timings that are motion steps (§21.8: 150 to 250 ms).
const TIMINGS := ["fade_ms", "rise_ms", "pop_ms", "sheet_ms", "press_ms", "screen_fade_ms", "bar_fill_ms"]
## A path with no manifest, so Motion falls back to the tokens.
const NOWHERE := "res://tests/no_motion.json"
## Slack for a float compared frame to frame.
const EPS := 0.0001


## `probe`'s value each frame for `seconds`, as [seconds since the start, value].
static func frames(tree: SceneTree, seconds: float, probe: Callable) -> Array:
	var seen := []
	var start := Time.get_ticks_msec()
	while Time.get_ticks_msec() - start < int(seconds * 1000.0):
		await tree.process_frame
		seen.append([(Time.get_ticks_msec() - start) / 1000.0, probe.call()])
	return seen


## Whether each axis of the samples' Vector3 only moves its way in `way` (-1
## down, 1 up, 0 either): an ease out that never passes its end value and
## never turns back.
static func steady(seen: Array, way: Vector3) -> bool:
	for i: int in range(1, seen.size()):
		var d: Vector3 = ((seen[i][1] as Vector3) - (seen[i - 1][1] as Vector3)) * way
		if minf(d.x, minf(d.y, d.z)) < -EPS:
			return false
	return true


## Every token timing and every baked step: 150 to 250 ms (or an instant
## step, 0 ms with no easing), Motion's seconds for it the same, and its easing
## rising from 0 to 1 with nothing past 1. Then that Motion reads the baked
## curves and sprites, and the tokens stand in with no manifest.
static func curves() -> Array:
	var bad := []
	for n: String in TIMINGS:
		var ms := Motion._ms(n) * 1000.0
		if ms < 150.0 - EPS or ms > 250.0 + EPS:
			bad.append("the token %s is %.0f ms" % [n, ms])
	var motions: Dictionary = Motion._curves().get("motions", {})
	for m: String in motions:
		for form: String in ["full", "reduced"]:
			for part: String in motions[m].get(form, {}):
				var list: Variant = motions[m][form][part]
				for st: Variant in (list if list is Array else []):
					bad.append_array(_step("%s.%s.%s.%s" % [m, form, part, st["name"]], st as Dictionary))
	var keys := motions.keys()
	keys.sort()
	if keys != ["press", "reward", "screen", "shine"]:
		bad.append("the baked motions are %s" % [keys])
	var down := Motion.steps("press", "full", "down")
	if down.size() != 3 or not is_equal_approx(Motion.seconds(down[0]), 0.15):
		bad.append("the press does not go down over the baked curve's 150 ms: %s" % [down])
	if not is_equal_approx(float(Motion.value("press", "reduced", "down", []).back()["to"]), 0.88):
		bad.append("the reduced press does not darken to the baked 0.88")
	for s: String in ["coin__face__normal", "burst__rays__normal", "shine__sweep__normal"]:
		if Motion.sprite(s) == null:
			bad.append("no baked sprite %s" % s)
	Motion.read_file(NOWHERE)
	var fb := Motion.steps("press", "full", "down")
	if fb.size() != 2 or not is_equal_approx(Motion.seconds(fb[0]), Motion._ms("press_ms")) \
			or not is_equal_approx(float(fb[1]["to"]), Tokens.number("motion", "press_squash")):
		bad.append("with no manifest the press is not the tokens' press_ms and press_squash: %s" % [fb])
	for part: Array in [["press", "reduced", "down"], ["screen", "full", "in"], ["screen", "reduced", "in"],
			["shine", "full", "steps"], ["reward", "full", "payoff"], ["reward", "reduced", "steps"]]:
		var steps := Motion.steps(part[0], part[1], part[2])
		if steps.is_empty():
			bad.append("with no manifest %s has no steps" % [part])
		for st: Dictionary in steps:
			bad.append_array(_step("the fallback's %s %s" % [part, st.get("name", "")], st))
	if Motion.sprite("coin__face__normal") != null:
		bad.append("with no manifest a sprite is still drawn")
	Motion.read_file()
	return bad


## A press and its release, sampled every frame, in full and reduced: the box
## sinks onto its drop (press 0 to 1), the button squashes to 0.96 and darkens
## to 0.9 (reduced: no squash, darkens to 0.88), all easing out from the first
## frame and settling by 250 ms, then back to rest.
static func press(tree: SceneTree) -> Array:
	var bad := []
	var b := UI.button("press", func() -> void: pass)
	tree.root.add_child(b)
	await tree.process_frame
	var box := RbBox.of(b)
	var probe := func() -> Vector3: return Vector3(b.scale.x, box.press, box.self_modulate.r)
	# A first press and release unsampled: the first frame a button is drawn
	# pressed can be a long one, which no curve keeps to.
	Motion.press(b, true)
	await frames(tree, 0.1, probe)
	Motion.press(b, false)
	await frames(tree, 0.26, probe)
	for reduced: bool in [false, true]:
		var form := "reduced" if reduced else "full"
		Settings.reduced_motion = reduced
		Motion.press(b, true)
		var down: Array = await frames(tree, 0.26, probe)
		Motion.press(b, false)
		var up: Array = await frames(tree, 0.26, probe)
		var low := Vector3(1.0 if reduced else 0.96, 1.0, 0.88 if reduced else 0.9)
		if (down[0][1] as Vector3).y > 0.99 or (up[0][1] as Vector3).y < 0.01:
			bad.append("the %s press changes at once, not over its curve" % form)
		if not steady(down, Vector3(-1, 1, -1)) or not steady(up, Vector3(1, -1, 1)):
			bad.append("the %s press turns back or passes its end: %s" % [form, (down + up).map(
				func(s: Array) -> Vector3: return s[1])])
		if (down + up).any(func(s: Array) -> bool: return (s[1] as Vector3).x < low.x - EPS):
			bad.append("the %s press squashes below %.2f" % [form, low.x])
		if not (down.back()[1] as Vector3).is_equal_approx(low):
			bad.append("the %s press ends down at %s, not %s" % [form, down.back()[1], low])
		if not (up.back()[1] as Vector3).is_equal_approx(Vector3(1.0, 0.0, 1.0)):
			bad.append("the %s press ends up at %s, not at rest" % [form, up.back()[1]])
	Settings.reduced_motion = false
	b.queue_free()
	return bad


## The reward sequence of a common and an epic prize and its reduced form,
## sampled every frame: its sprites, the prize's and the counter's sizes, the
## counter's value, and the layer freed at the end.
static func reward(tree: SceneTree) -> Array:
	var bad := []
	var prize := Control.new()
	prize.position = Vector2(240, 400)
	prize.size = Vector2(120, 120)
	var counter := Label.new()
	counter.position = Vector2(420, 40)
	counter.text = "10"
	for n: Control in [prize, counter]:
		tree.root.add_child(n)
	await tree.process_frame
	var tiers: Dictionary = Motion.value("reward", "full", "tiers", {})
	# Each run's sprites: rays, ring, the tier's sparkles and dust, and a coin
	# for each of the 5 gained; reduced, the one coin.
	for run: Array in [["common", false], ["epic", false], ["common", true]]:
		var tier: String = run[0]
		var reduced: bool = run[1]
		var name := "the reduced reward" if reduced else "the %s reward" % tier
		Settings.reduced_motion = reduced
		var start := int(counter.text)
		Motion.reward(prize, counter, start, start + 5, tier)
		var layer := prize.get_child(prize.get_child_count(true) - 1, true)
		var t: Dictionary = tiers.get(tier, {})
		var want := 1 if reduced else 2 + int(t.get("sparkles", 0)) + int(t.get("dust", 0)) + 5
		var drawn := layer.get_children().filter(func(n: Node) -> bool:
			return n is TextureRect and (n as TextureRect).texture != null)
		if layer.name != "Reward" or layer.get_child_count() != want or drawn.size() != want:
			bad.append("%s draws %d sprites (%d with a texture), not %d" % [name, layer.get_child_count(),
				drawn.size(), want])
		var seen: Array = await frames(tree, 0.6 if reduced else 2.0,
			func() -> Vector3: return Vector3(prize.scale.x, counter.scale.x, int(counter.text)))
		for i: int in seen.size():
			var v: Vector3 = seen[i][1]
			if v.x < 0.94 - EPS or v.x > 1.0 + EPS or (reduced and not is_equal_approx(v.x, 1.0)):
				bad.append("%s's prize is at %.3f of its size" % [name, v.x])
			if v.y < 1.0 - EPS or v.y > 1.06 + EPS or (reduced and not is_equal_approx(v.y, 1.0)):
				bad.append("%s's counter pulses to %.3f" % [name, v.y])
			if i > 0 and v.z < (seen[i - 1][1] as Vector3).z:
				bad.append("%s's counter rolls down" % name)
			if reduced and seen[i][0] < 0.34 and v.z != start:
				bad.append("%s's counter changes before 350 ms" % name)
		if not (seen.back()[1] as Vector3).is_equal_approx(Vector3(1.0, 1.0, start + 5)):
			bad.append("%s ends at %s, not at rest on %d" % [name, seen.back()[1], start + 5])
		if is_instance_valid(layer):
			bad.append("%s's layer is not freed" % name)
		if bad.size() > 12:
			break
	Settings.reduced_motion = false
	prize.queue_free()
	counter.queue_free()
	return bad


## The idle shine of a primary button: none under reduced motion or in high
## contrast; the baked band, hidden through the first wait, at most 0.6 bright,
## sweeping across the face, then gone until the next period; a disabled
## button shows none.
static func shine(tree: SceneTree) -> Array:
	var bad := []
	var b := UI.button("go", func() -> void: pass, true)
	tree.root.add_child(b)
	await tree.process_frame
	Settings.reduced_motion = true
	if Motion.shine(b) != null:
		bad.append("a shine under reduced motion")
	Settings.reduced_motion = false
	Tokens.high_contrast = true
	if Motion.shine(b) != null:
		bad.append("a shine in high contrast")
	Tokens.high_contrast = false
	var layer := Motion.shine(b)
	if layer == null:
		b.queue_free()
		return bad + ["no shine on a primary button"]
	var band := layer.get_child(0) as TextureRect
	if band == null or band.texture == null:
		b.queue_free()
		return bad + ["the shine draws no baked band"]
	var first := float(Motion.value("shine", "full", "first_wait_ms", 0)) / 1000.0
	var seen: Array = await frames(tree, first + 0.35,
		func() -> Vector2: return Vector2(band.modulate.a if band.visible else 0.0, band.position.x))
	var xs := []
	for s: Array in seen:
		var v: Vector2 = s[1]
		if s[0] < first - 0.02 and v.x > 0.0:
			bad.append("the band shows at %.2f s, before its first wait" % s[0])
		if v.x > 0.6 + EPS:
			bad.append("the band is %.2f bright" % v.x)
		if v.x > 0.0:
			xs.append(v.y)
	if xs.size() < 2 or float(xs.max()) - float(xs.min()) < b.size.x * 0.5:
		bad.append("the band does not sweep across the face: %s" % [xs])
	if (seen.back()[1] as Vector2).x > 0.0:
		bad.append("the band is still showing after its sweep")
	var loop: Variant = layer.get_meta("motion_shine", null)
	if not loop is Tween or (loop as Tween).get_loops_left() != -1:
		bad.append("the shine does not repeat once a period")
	b.disabled = true
	Motion._shine_ready(b, layer, band)
	if band.visible:
		bad.append("a disabled button shines")
	b.queue_free()
	return bad


## A screen arriving and leaving: from alpha 0 and 0.985 of its size to
## alpha 1 at full size within 250 ms, then to alpha 0; reduced, alpha only.
static func screens(tree: SceneTree) -> Array:
	var bad := []
	var s := Control.new()
	s.size = Vector2(200, 300)
	tree.root.add_child(s)
	for reduced: bool in [false, true]:
		var form := "reduced" if reduced else "full"
		Settings.reduced_motion = reduced
		Motion.screen_in(s)
		var from := Vector2(s.modulate.a, s.scale.x)
		var seen: Array = await frames(tree, 0.26, func() -> Vector3: return Vector3(s.modulate.a, s.scale.x, 0.0))
		if not from.is_equal_approx(Vector2(0.0, 1.0 if reduced else 0.985)):
			bad.append("the %s screen arrives from %s" % [form, from])
		if not steady(seen, Vector3.ONE) or not (seen.back()[1] as Vector3).is_equal_approx(Vector3(1.0, 1.0, 0.0)):
			bad.append("the %s screen does not settle at full size and alpha: %s" % [form, seen.back()[1]])
		Motion.screen_out(s)
		var out: Array = await frames(tree, 0.26, func() -> Vector3: return Vector3(s.modulate.a, 0.0, 0.0))
		if not steady(out, -Vector3.ONE) or not is_zero_approx((out.back()[1] as Vector3).x):
			bad.append("the %s screen does not fade out" % form)
	Settings.reduced_motion = false
	s.queue_free()
	return bad


## One step: its time in range and Motion's seconds for it, and its easing.
static func _step(where: String, st: Dictionary) -> Array:
	var ms := float(st.get("ms", -1))
	if ms == 0.0 and st.get("easing", "") == "none":
		return [] if Motion.seconds(st) == 0.0 else ["%s is instant but not to Motion" % where]
	var bad := []
	if ms < 150.0 or ms > 250.0 or not is_equal_approx(Motion.seconds(st), ms / 1000.0):
		bad.append("%s takes %.0f ms (Motion: %.3f s)" % [where, ms, Motion.seconds(st)])
	var last := 0.0
	for k: int in 21:
		var e := Motion._eased(st, k / 20.0)
		if e < last - EPS or e > 1.0 + EPS:
			bad.append("%s's easing turns back or overshoots at %.2f" % [where, k / 20.0])
			break
		last = e
	if not is_equal_approx(last, 1.0):
		bad.append("%s's easing ends at %.3f" % [where, last])
	return bad
