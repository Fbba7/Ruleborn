class_name Motion
## Every interface movement, timed to §21.8: 150 to 250 milliseconds a step,
## easing out, never overshooting; a button squashes slightly when pressed
## and rewards fly into their counter. Each reads Settings.reduced_motion
## (§20.8) and gives its reduced form: an entrance becomes a 150 ms fade with
## no travel, a press sinks and darkens without squashing, a reward lands one
## coin, a loop does not start.
##
## The press, the reward sequence, the idle shine and the screen change read
## their steps from the curves the bake carries in ui/art/motion.json (from
## art/ui/motion/curves.json, held to §21.8 by check_curves.py) and draw that
## manifest's sprites; ui/tokens.json `motion` stands in for any curve the
## manifest lacks. The other movements are timed by the tokens alone. A node
## on its way in carries the meta "entering" until it has arrived, so a
## check of its colours judges it as it will stand.

## The baked motion family: its atlas, sprites and curves.
const MANIFEST := "res://ui/art/motion.json"
## The easings a curve may name, as Godot's: only those that never pass
## their end value (§21.8's "no overshoot"); any other reads as cubic out.
const TRANSITIONS := {"TRANS_LINEAR": Tween.TRANS_LINEAR, "TRANS_SINE": Tween.TRANS_SINE,
	"TRANS_QUAD": Tween.TRANS_QUAD, "TRANS_CUBIC": Tween.TRANS_CUBIC, "TRANS_QUART": Tween.TRANS_QUART,
	"TRANS_QUINT": Tween.TRANS_QUINT, "TRANS_EXPO": Tween.TRANS_EXPO, "TRANS_CIRC": Tween.TRANS_CIRC}
const EASES := {"EASE_IN": Tween.EASE_IN, "EASE_OUT": Tween.EASE_OUT, "EASE_IN_OUT": Tween.EASE_IN_OUT}
## A reward's coins, at most (the curve's "coins, at most 8").
const COINS_MOST := 8

## The manifest read, or {} before the first read or without one.
static var _manifest: Dictionary = {}
static var _read := false
static var _atlas: Texture2D = null
static var _atlas_hc: Texture2D = null
static var _sprites: Dictionary = {}


## Reads the motion manifest at `path` again (the tests point it at a file
## with no curves, to see the tokens stand in). Not `reload`: on a class
## name that would call the script's own Script.reload.
static func read_file(path := MANIFEST) -> void:
	_read = true
	_manifest = {}
	_atlas = null
	_atlas_hc = null
	_sprites = {}
	if not FileAccess.file_exists(path):
		return
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	if not parsed is Dictionary:
		push_warning("motion: %s is not a JSON object; the tokens time every motion" % path)
		return
	_manifest = parsed
	var atlas: Dictionary = _manifest.get("atlas", {})
	var dir := path.get_base_dir()
	for twin: String in ["normal", "high_contrast"]:
		var file := dir.path_join(str(atlas.get(twin, "")))
		var tex: Texture2D = load(file) if atlas.has(twin) and ResourceLoader.exists(file) else null
		if tex == null and atlas.has(twin) and FileAccess.file_exists(file):
			tex = ImageTexture.create_from_image(Image.load_from_file(file))
		if twin == "normal":
			_atlas = tex
		else:
			_atlas_hc = tex


static func _curves() -> Dictionary:
	if not _read:
		read_file()
	return _manifest.get("curves", {})


## The steps of `motion`'s `form` ("full" or "reduced") in `part` ("down",
## "payoff", "steps", ...), from the baked curves, or the tokens' stand-ins
## when the manifest has no such curve.
static func steps(motion: String, form: String, part: String) -> Array:
	var m: Dictionary = _curves().get("motions", {}).get(motion, {})
	var f: Variant = m.get(form, {})
	if f is Dictionary and (f as Dictionary).get(part) is Array:
		return (f as Dictionary)[part]
	return _fallback(motion, form, part)


## A number of `motion`'s `form` that is not a step (the shine's period, a
## reward tier's sizes), or `default`.
static func value(motion: String, form: String, key: String, default: Variant) -> Variant:
	var f: Variant = _curves().get("motions", {}).get(motion, {}).get(form, {})
	return (f as Dictionary).get(key, default) if f is Dictionary else default


## How long step `st` takes, in seconds: its ms held to §21.8's 150 to 250,
## or 0 for a step that sets its value at once (`ms` 0, easing "none").
static func seconds(st: Dictionary) -> float:
	if float(st.get("ms", 0.0)) <= 0.0 or str(st.get("easing", "")) == "none":
		return 0.0
	return clampf(float(st["ms"]), Tokens.number("motion", "shortest_ms"),
		Tokens.number("motion", "longest_ms")) / 1000.0


## Step `name` of `list`, or {}.
static func _named(list: Array, name: String) -> Dictionary:
	for st: Dictionary in list:
		if str(st.get("name", "")) == name:
			return st
	return {}


## The Godot transition and ease of step `st`'s easing, never one that
## overshoots.
static func _easing(st: Dictionary) -> Array:
	var e: Variant = _curves().get("easings", {}).get(str(st.get("easing", "cubic_out")), {})
	var g: Dictionary = (e as Dictionary).get("godot", {}) if e is Dictionary else {}
	if g.is_empty() or bool((e as Dictionary).get("overshoot", false)):
		return [Tween.TRANS_CUBIC, Tween.EASE_OUT]
	return [TRANSITIONS.get(str(g.get("trans", "")), Tween.TRANS_CUBIC), EASES.get(str(g.get("ease", "")), Tween.EASE_OUT)]


static func _shape(tw: PropertyTweener, st: Dictionary) -> PropertyTweener:
	var e := _easing(st)
	return tw.set_trans(e[0]).set_ease(e[1])


static func _eased(st: Dictionary, k: float) -> float:
	var e := _easing(st)
	return Tween.interpolate_value(0.0, 1.0, clampf(k, 0.0, 1.0), 1.0, e[0], e[1])


## A number a step names: a figure, or `tier.<key>` from the reward's tier.
static func _num(v: Variant, tier: Dictionary) -> float:
	if v is String and (v as String).begins_with("tier."):
		return float(tier.get((v as String).trim_prefix("tier."), 1.0))
	return float(v) if v is float or v is int else 1.0


static func _st(name: String, property: String, from: Variant, to: Variant, token: String, at_ms := 0.0,
		extra := {}) -> Dictionary:
	var st := {"name": name, "property": property, "from": from, "to": to, "at_ms": at_ms,
		"ms": Tokens.number("motion", token), "easing": "cubic_out"}
	st.merge(extra)
	return st


## The tokens' stand-ins for a curve the manifest lacks.
static func _fallback(motion: String, form: String, part: String) -> Array:
	var squash := Tokens.number("motion", "press_squash")
	var fade := Tokens.number("motion", "fade_ms")
	var rise := Tokens.number("motion", "rise_ms")
	var popped := Tokens.number("motion", "pop_ms")
	var prize := {"target": "prize"}
	var coin := {"target": "coin", "sprite": "coin__face__normal", "sprites": ["coin__face__normal"],
		"stagger_ms": Tokens.number("motion", "stagger_ms") * 2.0, "arc_points": 44}
	var counter := {"target": "counter"}
	var out: Array = []
	match [motion, form, part]:
		["press", "full", "down"]:
			out = [_st("sink", "travel_points", 0, 3, "press_ms"), _st("squash", "scale", 1, squash, "press_ms")]
		["press", "full", "up"]:
			out = [_st("rise", "travel_points", 3, 0, "press_ms"), _st("recover", "scale", squash, 1, "press_ms")]
		["press", "reduced", "down"]:
			out = [_st("sink", "travel_points", 0, 3, "fade_ms")]
		["press", "reduced", "up"]:
			out = [_st("rise", "travel_points", 3, 0, "fade_ms")]
		["screen", "full", "in"]:
			out = [_st("fade_in", "alpha", 0, 1, "screen_fade_ms"), _st("grow", "scale", 0.985, 1, "screen_fade_ms")]
		["screen", "full", "out"]:
			out = [_st("fade_out", "alpha", 1, 0, "screen_out_ms")]
		["screen", "reduced", "in"]:
			out = [_st("fade_in", "alpha", 0, 1, "fade_ms")]
		["screen", "reduced", "out"]:
			out = [_st("fade_out", "alpha", 1, 0, "fade_ms")]
		["shine", "full", "steps"]:
			out = [_st("sweep", "x_fraction", -0.3, 1.3, "longest_ms", 0.0, {"sprite": "shine__sweep__normal"}),
				_st("sweep_fade", "alpha", 0.6, 0, "fade_ms", Tokens.number("motion", "longest_ms") - fade)]
		["reward", "full", "anticipation"]:
			out = [_st("gather", "scale", 1, 0.94, "pop_ms", 0.0, prize),
				_st("charge", "self_modulate_value", 1, 1.3, "pop_ms", 0.0, {"target": "prize", "ends_at": "burst"})]
		["reward", "full", "payoff"]:
			out = [_st("unglow", "self_modulate_value", 1.3, 1, "pop_ms", 0.0, prize),
				_st("reveal_scale", "scale", 0.94, 1, "pop_ms", 0.0, prize),
				_st("coins_fly", "arc", "prize", "counter", "longest_ms", popped, coin),
				_st("coins_shrink", "scale", 1, 0.7, "longest_ms", popped, coin)]
		["reward", "full", "on_landing"]:
			out = [_st("counter_roll", "value", "shown", "share", "fade_ms", 0.0, counter),
				_st("counter_pulse_up", "scale", 1, 1.06, "fade_ms", 0.0, counter),
				_st("counter_pulse_down", "scale", 1.06, 1, "fade_ms", fade, counter)]
		["reward", "reduced", "steps"]:
			out = [_st("reveal_fade", "alpha", 0, 1, "fade_ms", 0.0, prize),
				_st("coin_land", "offset_points", -10, 0, "rise_ms", fade, coin),
				_st("coin_land_fade", "alpha", 1, 0, "fade_ms", rise, coin),
				{"name": "counter_set", "property": "value", "target": "counter", "from": "old", "to": "new",
					"at_ms": fade + rise, "ms": 0, "easing": "none"}]
	return out


## Sprite `name` of the baked motion family (its high-contrast twin when
## Tokens.high_contrast is on), or null when the manifest or its page is
## missing.
static func sprite(name: String) -> Texture2D:
	_curves()
	var page := _atlas_hc if Tokens.high_contrast and _atlas_hc != null else _atlas
	var p: Variant = _manifest.get("pieces", {}).get(name)
	if page == null or not p is Dictionary:
		return null
	var key := [name, page == _atlas_hc]
	if not _sprites.has(key):
		var a := AtlasTexture.new()
		a.atlas = page
		a.region = Rect2(float(p["x"]), float(p["y"]), float(p["w"]), float(p["h"]))
		_sprites[key] = a
	return _sprites[key]


## A sprite drawn at its baked size (the family's px_per_point turned into
## the kit's points), centred on (0, 0) of its parent, ignoring the mouse.
static func _view(name: String) -> TextureRect:
	var r := TextureRect.new()
	r.name = name
	r.texture = sprite(name)
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	r.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	r.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	var p: Dictionary = _manifest.get("pieces", {}).get(name, {"w": 24.0, "h": 24.0})
	var per := UI.PX_PER_POINT / float(_manifest.get("px_per_point", UI.PX_PER_POINT))
	r.size = Vector2(float(p["w"]), float(p["h"])) * per
	r.pivot_offset = r.size * 0.5
	r.position = -r.size * 0.5
	return r


static func _arrive(node: CanvasItem, t: Tween) -> Tween:
	node.set_meta("entering", true)
	t.finished.connect(func() -> void:
		if is_instance_valid(node):
			node.remove_meta("entering"))
	return t


static func _ms(name: String) -> float:
	return clampf(Tokens.number("motion", name), Tokens.number("motion", "shortest_ms"),
		Tokens.number("motion", "longest_ms")) / 1000.0


## A node arriving: it rises a little and fades in (the designs' rbRise),
## after `delay_ms`; under reduced motion it only fades.
static func enter(node: CanvasItem, delay_ms := 0.0) -> Tween:
	var t := node.create_tween()
	node.modulate.a = 0.0
	if delay_ms > 0.0:
		t.tween_interval(delay_ms / 1000.0)
	if Settings.reduced_motion:
		t.tween_property(node, "modulate:a", 1.0, _ms("fade_ms"))
		return _arrive(node, t)
	t.set_parallel(true)
	t.tween_property(node, "modulate:a", 1.0, _ms("rise_ms")).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	if node is Control and not ((node as Control).get_parent() is Container):
		var c := node as Control
		var at := c.position
		c.position.y += Tokens.number("motion", "rise_points") * UI.PX_PER_POINT
		t.tween_property(c, "position:y", at.y, _ms("rise_ms")).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	return _arrive(node, t)


## The children of `parent` entering one after another, each `stagger_ms`
## after the last, all inside §21.8's 250 ms.
static func cascade(parent: Node) -> void:
	var step := Tokens.number("motion", "stagger_ms")
	var i := 0
	for c: Node in parent.get_children():
		if c is CanvasItem:
			enter(c as CanvasItem, minf(i * step, Tokens.number("motion", "longest_ms") - Tokens.number("motion", "rise_ms")))
			i += 1


## A popped node (a badge, a toast, a dialog): it grows from 92% to its size,
## easing out with no overshoot, or fades under reduced motion.
static func pop(node: Control) -> Tween:
	var t := node.create_tween()
	node.modulate.a = 0.0
	if Settings.reduced_motion:
		t.tween_property(node, "modulate:a", 1.0, _ms("fade_ms"))
		return _arrive(node, t)
	node.pivot_offset = node.size * 0.5
	node.scale = Vector2.ONE * 0.92
	t.set_parallel(true)
	t.tween_property(node, "modulate:a", 1.0, _ms("pop_ms") * 0.7)
	t.tween_property(node, "scale", Vector2.ONE, _ms("pop_ms")).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	return _arrive(node, t)


## A sheet sliding up from the bottom edge by its own height, easing out, or
## fading.
static func sheet_in(node: Control) -> Tween:
	var t := node.create_tween()
	# A container places its children, so a sheet inside one fades in.
	if Settings.reduced_motion or node.get_parent() is Container:
		node.modulate.a = 0.0
		t.tween_property(node, "modulate:a", 1.0, _ms("fade_ms"))
		return _arrive(node, t)
	var at := node.position.y
	node.position.y = at + maxf(node.size.y, 1.0)
	t.tween_property(node, "position:y", at, _ms("sheet_ms")).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	return t


## A button pressed or let go (curve `press`): on touch-down its body sinks
## onto its drop, it squashes slightly and darkens; on release it comes back,
## from wherever it stands. Under reduced motion it sinks and darkens with no
## squash. Nothing grows past its rest size. The light haptic tap is the
## button's own (UI's `pressed`), so the press adds none.
static func press(button: Control, down: bool) -> Tween:
	var box := RbBox.of(button)
	var form := "reduced" if Settings.reduced_motion else "full"
	var list := steps("press", form, "down" if down else "up")
	var deepest := maxf(float(_named(steps("press", form, "down"), "sink").get("to", 3.0)), 0.001)
	var was: Variant = button.get_meta("motion_press") if button.has_meta("motion_press") else null
	if was is Tween and (was as Tween).is_valid():
		(was as Tween).kill()
	button.pivot_offset = button.size * 0.5
	var t := button.create_tween().set_parallel(true)
	button.set_meta("motion_press", t)
	var dark: CanvasItem = box if box != null else button
	var squashed := false
	for st: Dictionary in list:
		var at := float(st.get("at_ms", 0.0)) / 1000.0
		match str(st.get("property", "")):
			"travel_points":
				if box != null:
					_shape(t.tween_property(box, "press", clampf(_num(st["to"], {}) / deepest, 0.0, 1.0),
						seconds(st)), st).set_delay(at)
			"scale":
				squashed = true
				_shape(t.tween_property(button, "scale", Vector2.ONE * minf(_num(st["to"], {}), 1.0), seconds(st)),
					st).set_delay(at)
			"self_modulate_value":
				var v := clampf(_num(st["to"], {}), 0.0, 1.0)
				_shape(t.tween_property(dark, "self_modulate", Color(v, v, v, dark.self_modulate.a), seconds(st)),
					st).set_delay(at)
	if not squashed:
		button.scale = Vector2.ONE
	# A tween needs a step: with no body and no darken, an empty one.
	t.tween_interval(0.0)
	return t


## A bar's value moving to `to`, easing out within §21.8's 150 to 250 ms
## ("every interface movement"; the designs' 450 ms is held to 250); at
## once under reduced motion.
static func fill(bar: Range, to: float) -> void:
	if Settings.reduced_motion or not bar.is_inside_tree():
		bar.value = to
		return
	bar.create_tween().tween_property(bar, "value", to, _ms("bar_fill_ms")) \
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)


## A gentle bob (the active tab's icon), `amp` points up and down over the
## designs' 2.4 s; not started under reduced motion. Slow enough never to
## count as flashing (§20.8).
static func bob(node: CanvasItem, amp_points := 3.0) -> Tween:
	if Settings.reduced_motion:
		return null
	var t := node.create_tween().set_loops()
	var half := Tokens.number("motion", "bob_ms") / 2000.0
	var amp := amp_points * UI.PX_PER_POINT
	t.tween_property(node, "position:y", -amp, half).as_relative().set_trans(Tween.TRANS_SINE) \
		.set_ease(Tween.EASE_IN_OUT)
	t.tween_property(node, "position:y", amp, half).as_relative().set_trans(Tween.TRANS_SINE) \
		.set_ease(Tween.EASE_IN_OUT)
	return t


## A screen arriving (curve `screen`, `in`: a fade from 0.985 of its size),
## for the router to call on the screen it has just shown; a plain fade
## under reduced motion.
static func screen_in(screen: Control) -> Tween:
	return _screen(screen, "in")


## A screen leaving (curve `screen`, `out`): it fades out. The router frees
## it when the tween finishes.
static func screen_out(screen: Control) -> Tween:
	return _screen(screen, "out")


static func _screen(screen: Control, part: String) -> Tween:
	var list := steps("screen", "reduced" if Settings.reduced_motion else "full", part)
	var t := screen.create_tween().set_parallel(true)
	screen.pivot_offset = screen.size * 0.5
	for st: Dictionary in list:
		var at := float(st.get("at_ms", 0.0)) / 1000.0
		match str(st.get("property", "")):
			"alpha":
				screen.modulate.a = _num(st["from"], {})
				_shape(t.tween_property(screen, "modulate:a", _num(st["to"], {}), seconds(st)), st).set_delay(at)
			"scale":
				screen.scale = Vector2.ONE * _num(st["from"], {})
				_shape(t.tween_property(screen, "scale", Vector2.ONE * minf(_num(st["to"], {}), 1.0), seconds(st)),
					st).set_delay(at)
	if list.is_empty():
		screen.modulate.a = 1.0 if part == "in" else 0.0
		t.tween_interval(0.0)
	return _arrive(screen, t) if part == "in" else t


## A slow glow (the Heist tab's pulse): the node brightens a little and
## settles over the designs' 3.2 s, far below §20.8's three flashes a
## second; not started under reduced motion.
static func glow(node: CanvasItem) -> Tween:
	if Settings.reduced_motion:
		return null
	var t := node.create_tween().set_loops()
	var half := Tokens.number("motion", "glow_ms") / 2000.0
	t.tween_property(node, "self_modulate", Color(1.18, 1.14, 1.05), half).set_trans(Tween.TRANS_SINE) \
		.set_ease(Tween.EASE_IN_OUT)
	t.tween_property(node, "self_modulate", Color.WHITE, half).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	return t


## An idle shine on a primary button (curve `shine`): after a first wait a
## soft band (sprite shine__sweep) sweeps across its face once a period,
## only while the button is enabled and idle. Returns the clipped layer the
## band moves in, or null: none under reduced motion or in high contrast,
## where the band would blur the outline that mode keeps. The layer goes
## with the button.
static func shine(button: Control) -> Control:
	var list := steps("shine", "full", "steps")
	var sweep := _named(list, "sweep")
	if Settings.reduced_motion or Tokens.high_contrast or sweep.is_empty():
		return null
	var layer := Control.new()
	layer.name = "Shine"
	layer.clip_contents = true
	layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.set_anchors_preset(Control.PRESET_FULL_RECT)
	button.add_child(layer, false, Node.INTERNAL_MODE_BACK)
	var band := _view(str(sweep.get("sprite", "shine__sweep__normal")))
	band.position = Vector2.ZERO
	band.visible = false
	layer.add_child(band)
	var first := float(value("shine", "full", "first_wait_ms", Tokens.number("motion", "bob_ms") / 3.0)) / 1000.0
	# Never more often than §20.8's three times a second.
	var period := maxf(float(value("shine", "full", "period_ms", Tokens.number("motion", "bob_ms"))) / 1000.0,
		1.0 / Tokens.number("motion", "flash_hz_most"))
	var lasts := 0.0
	for st: Dictionary in list:
		lasts = maxf(lasts, float(st.get("at_ms", 0.0)) / 1000.0 + seconds(st))
	# The first wait runs once; then a round each period.
	var t := layer.create_tween()
	layer.set_meta("motion_shine", t)
	t.tween_interval(first)
	t.tween_callback(_shine_loop.bind(button, layer, band, list, lasts, period))
	return layer


static func _shine_loop(button: Control, layer: Control, band: TextureRect, list: Array, lasts: float,
		period: float) -> void:
	var t := layer.create_tween().set_loops()
	layer.set_meta("motion_shine", t)
	t.tween_callback(_shine_ready.bind(button, layer, band))
	t.tween_method(_shine_step.bind(band, layer, list), 0.0, lasts, lasts)
	t.tween_interval(maxf(period - lasts, 0.0))


## Before each round: the band shows only on an enabled, idle button (not
## pressed, not disabled), and is as tall as the button.
static func _shine_ready(button: Control, layer: Control, band: TextureRect) -> void:
	var idle := true
	if button is BaseButton:
		var b := button as BaseButton
		idle = not b.disabled and b.get_draw_mode() in [BaseButton.DRAW_NORMAL, BaseButton.DRAW_HOVER]
	band.visible = idle and not Tokens.high_contrast and not Settings.reduced_motion
	var aspect := 0.5
	if band.texture != null:
		aspect = band.texture.get_width() / maxf(band.texture.get_height(), 1.0)
	band.size = Vector2(layer.size.y * aspect, layer.size.y)


static func _shine_step(s: float, band: TextureRect, layer: Control, list: Array) -> void:
	for st: Dictionary in list:
		# Before its start a step holds its first value; after its end, its last.
		var k := (s - float(st.get("at_ms", 0.0)) / 1000.0) / maxf(seconds(st), 0.001)
		var v := lerpf(_num(st["from"], {}), _num(st["to"], {}), _eased(st, k))
		match str(st.get("property", "")):
			"x_fraction":
				band.position.x = v * layer.size.x - band.size.x * 0.5
			"alpha":
				band.modulate.a = v


## The result screen's reward (curve `reward`): `prize` gathers and charges
## for its `tier`'s anticipation ("common", "rare" or "epic"), bursts
## (rays, a ring, sparkles and dust, brighter and larger for a rarer tier),
## and is revealed; then up to eight coins fly in arcs from it into
## `counter`, turning as they go, and each landing rolls the counter up by
## its share and pulses it. Under reduced motion the prize fades in, one
## coin lands and the counter shows `to_value` at once (§20.8). `show` writes
## a number into the counter (default: a Label's text or a Range's value).
## Both must be in the tree. Returns the sequence's tween; its sprites go
## when it finishes.
static func reward(prize: Control, counter: Control, from_value: int, to_value: int, tier := "common",
		show := Callable()) -> Tween:
	var write := show if show.is_valid() else _show.bind(counter)
	counter.set_meta("motion_shown", from_value)
	var layer := Control.new()
	layer.name = "Reward"
	layer.top_level = true
	layer.z_index = 10
	layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	prize.add_child(layer, false, Node.INTERNAL_MODE_BACK)
	layer.global_position = prize.get_global_rect().get_center()
	prize.pivot_offset = prize.size * 0.5
	counter.pivot_offset = counter.size * 0.5
	var t := prize.create_tween().set_parallel(true)
	if Settings.reduced_motion:
		_reward_reduced(t, prize, counter, layer, to_value, write)
	else:
		_reward_full(t, prize, counter, layer, from_value, to_value, tier, write)
	t.chain().tween_callback(layer.queue_free)
	return t


## The counter showing `v`, remembered so the next landing rolls on from it.
static func _set_shown(v: float, counter: Control, write: Callable) -> void:
	if is_instance_valid(counter):
		counter.set_meta("motion_shown", int(round(v)))
		write.call(int(round(v)))


static func _show(v: int, counter: Control) -> void:
	if counter is Label:
		(counter as Label).text = str(v)
	elif counter is Range:
		(counter as Range).value = v


static func _reward_reduced(t: Tween, prize: Control, counter: Control, layer: Control, to_value: int,
		write: Callable) -> void:
	var list := steps("reward", "reduced", "steps")
	var coin: TextureRect = null
	for st: Dictionary in list:
		var at := float(st.get("at_ms", 0.0)) / 1000.0
		match [str(st.get("target", "")), str(st.get("property", ""))]:
			["prize", "alpha"]:
				prize.modulate.a = _num(st["from"], {})
				_shape(t.tween_property(prize, "modulate:a", _num(st["to"], {}), seconds(st)), st).set_delay(at)
			["coin", "offset_points"], ["coin", "alpha"]:
				if coin == null:
					coin = _view(str(st.get("sprite", "coin__face__normal")))
					coin.modulate.a = 0.0
					layer.add_child(coin)
					var here := counter.get_global_rect().get_center() - layer.global_position - coin.size * 0.5
					coin.position = here
					coin.set_meta("rest", here)
				if str(st["property"]) == "alpha":
					_shape(t.tween_property(coin, "modulate:a", _num(st["to"], {}), seconds(st)).from(
						_num(st["from"], {})), st).set_delay(at)
				else:
					var rest: Vector2 = coin.get_meta("rest")
					t.tween_callback(func() -> void: coin.modulate.a = 1.0).set_delay(at)
					_shape(t.tween_property(coin, "position:y", rest.y + UI.px(_num(st["to"], {})), seconds(st)).from(
						rest.y + UI.px(_num(st["from"], {}))), st).set_delay(at)
			["counter", "value"]:
				t.tween_callback(_set_shown.bind(float(to_value), counter, write)).set_delay(at + seconds(st))


static func _reward_full(t: Tween, prize: Control, counter: Control, layer: Control, from_value: int,
		to_value: int, tier_name: String, write: Callable) -> void:
	var tiers: Dictionary = value("reward", "full", "tiers", {})
	var tier: Dictionary = tiers.get(tier_name, tiers.get("common", {}))
	var burst := float(tier.get("anticipation_ms", Tokens.number("motion", "pop_ms"))) / 1000.0
	for st: Dictionary in steps("reward", "full", "anticipation"):
		var at := float(st.get("at_ms", 0.0)) / 1000.0
		if str(st.get("ends_at", "")) == "burst":
			at = maxf(burst - seconds(st), 0.0)
		_prize_step(t, prize, st, at)
	var coins: Array[TextureRect] = []
	var gained := to_value - from_value
	var n := clampi(gained, 0, COINS_MOST)
	var lands := burst
	for st: Dictionary in steps("reward", "full", "payoff"):
		var at := burst + float(st.get("at_ms", 0.0)) / 1000.0
		match str(st.get("target", "prize")):
			"prize":
				_prize_step(t, prize, st, at)
			"burst":
				_burst_step(t, layer, st, at, tier)
			"coin":
				if coins.is_empty() and n > 0:
					var frames: Array = st.get("sprites", ["coin__face__normal"])
					for i: int in n:
						var c := _view(str(frames[0]))
						c.modulate.a = 0.0
						layer.add_child(c)
						coins.append(c)
				var stagger := float(st.get("stagger_ms", 0.0)) / 1000.0
				for i: int in coins.size():
					var start := at + i * stagger
					if str(st.get("property", "")) == "arc":
						var share := from_value + int(round(float(gained) * (i + 1) / n))
						t.tween_callback(func() -> void: coins[i].modulate.a = 1.0).set_delay(start)
						t.tween_method(_coin_step.bind(coins[i], layer, prize, counter, st), 0.0, 1.0,
							seconds(st)).set_delay(start)
						t.tween_callback(_land.bind(coins[i], counter, share, write)).set_delay(start + seconds(st))
						lands = maxf(lands, start + seconds(st))
					elif str(st.get("property", "")) == "scale":
						_shape(t.tween_property(coins[i], "scale", Vector2.ONE * _num(st["to"], {}), seconds(st)).from(
							Vector2.ONE * _num(st["from"], {})), st).set_delay(start)
	if n == 0:
		t.tween_callback(_set_shown.bind(float(to_value), counter, write)).set_delay(lands)
	var after := 0.0
	for st: Dictionary in steps("reward", "full", "on_landing"):
		after = maxf(after, float(st.get("at_ms", 0.0)) / 1000.0 + seconds(st))
	t.tween_interval(lands + after)


## A step on the prize itself: its scale, brightness or rise.
static func _prize_step(t: Tween, prize: Control, st: Dictionary, at: float) -> void:
	var from := _num(st["from"], {})
	var to := _num(st["to"], {})
	match str(st.get("property", "")):
		"scale":
			_shape(t.tween_property(prize, "scale", Vector2.ONE * minf(to, 1.0), seconds(st)).from(
				Vector2.ONE * minf(from, 1.0)), st).set_delay(at)
		"self_modulate_value":
			_shape(t.tween_property(prize, "self_modulate", Color(to, to, to), seconds(st)).from(
				Color(from, from, from)), st).set_delay(at)
		"offset_points":
			# A container places its children: the prize inside one is not lifted.
			if not prize.get_parent() is Container:
				var y := prize.position.y
				_shape(t.tween_property(prize, "position:y", y + UI.px(to), seconds(st)).from(y + UI.px(from)),
					st).set_delay(at)
		"alpha":
			_shape(t.tween_property(prize, "modulate:a", to, seconds(st)).from(from), st).set_delay(at)


## A step of the burst: the rays and ring grow and fade, the sparkles and
## dust fly out evenly around the prize and fade.
static func _burst_step(t: Tween, layer: Control, st: Dictionary, at: float, tier: Dictionary) -> void:
	var name := str(st.get("sprite", ""))
	var count := int(_num(st.get("count", 1), tier)) if st.has("count") else 1
	var stagger := float(st.get("stagger_ms", 0.0)) / 1000.0
	for i: int in count:
		var key := "%s_%d" % [name, i]
		var r: TextureRect = layer.get_node_or_null(key)
		if r == null:
			r = _view(name)
			r.name = key
			r.modulate.a = 0.0
			r.set_meta("dir", Vector2.UP.rotated(TAU * i / count + (PI / count if name.contains("dot") else 0.0)))
			layer.add_child(r)
		var start := at + i * stagger
		var from := _num(st["from"], tier)
		var to := _num(st["to"], tier)
		match str(st.get("property", "")):
			"scale":
				t.tween_callback(func() -> void: r.modulate.a = minf(_num(tier.get("burst_value", 1.0), {}), 1.0)) \
					.set_delay(start)
				_shape(t.tween_property(r, "scale", Vector2.ONE * to, seconds(st)).from(Vector2.ONE * from), st) \
					.set_delay(start)
			"alpha":
				_shape(t.tween_property(r, "modulate:a", to, seconds(st)).from(minf(from, 1.0)), st).set_delay(start)
			"offset_points":
				var dir: Vector2 = r.get_meta("dir")
				t.tween_callback(func() -> void: r.modulate.a = 1.0).set_delay(start)
				_shape(t.tween_property(r, "position", -r.size * 0.5 + dir * UI.px(to), seconds(st)).from(
					-r.size * 0.5 + dir * UI.px(from)), st).set_delay(start)


## One frame of a coin's flight: along an arc from the prize to the middle
## of the counter, easing out, turning through its sprite strip.
static func _coin_step(k: float, coin: TextureRect, layer: Control, prize: Control, counter: Control,
		st: Dictionary) -> void:
	if not is_instance_valid(counter) or not is_instance_valid(prize):
		return
	var e := _eased(st, k)
	var from := prize.get_global_rect().get_center() - layer.global_position
	var end := counter.get_global_rect().get_center() - layer.global_position
	coin.position = from.lerp(end, e) + Vector2(0.0, -sin(e * PI) * UI.px(float(st.get("arc_points", 44)))) \
		- coin.size * 0.5
	var frames: Array = st.get("sprites", [])
	if frames.size() > 1:
		var i := int(k * seconds(st) * 1000.0 / maxf(float(st.get("frame_ms", 62)), 1.0)) % frames.size()
		coin.texture = sprite(str(frames[i]))


## A coin landing in `counter`: the counter rolls up to `to` and pulses,
## each from where it stands.
static func _land(coin: TextureRect, counter: Control, to: int, write: Callable) -> void:
	coin.visible = false
	if not is_instance_valid(counter):
		return
	var list := steps("reward", "full", "on_landing")
	for key: String in ["motion_roll", "motion_pulse"]:
		var was: Variant = counter.get_meta(key) if counter.has_meta(key) else null
		if was is Tween and (was as Tween).is_valid():
			(was as Tween).kill()
	var roll := counter.create_tween()
	var pulse := counter.create_tween().set_parallel(true)
	counter.set_meta("motion_roll", roll)
	counter.set_meta("motion_pulse", pulse)
	var shown := int(counter.get_meta("motion_shown", to))
	var rolled := false
	for st: Dictionary in list:
		var at := float(st.get("at_ms", 0.0)) / 1000.0
		match str(st.get("property", "")):
			"value":
				rolled = true
				var e := _easing(st)
				roll.tween_method(_set_shown.bind(counter, write), float(shown), float(to), seconds(st)) \
					.set_delay(at).set_trans(e[0]).set_ease(e[1])
			"scale":
				_shape(pulse.tween_property(counter, "scale", Vector2.ONE * _num(st["to"], {}), seconds(st)), st) \
					.set_delay(at)
	if not rolled:
		_set_shown(float(to), counter, write)
		roll.tween_interval(0.0)
	if list.is_empty():
		pulse.tween_interval(0.0)


## §21.8's "rewards fly into their counter": `node` (a coin, a loot bag)
## flies from `from` on the screen to the middle of `to` in an arc, easing
## out and shrinking a little, after `delay_ms`; it is freed when it lands.
## Under reduced motion, or with nowhere to fly, nothing flies: the node is
## freed at once and the counter's number says the change (§20.8). `node`
## must already be in the tree.
static func fly(node: Control, from: Vector2, to: Control, delay_ms := 0.0) -> Tween:
	if Settings.reduced_motion or not node.is_inside_tree() or not is_instance_valid(to) \
			or not to.is_inside_tree():
		node.queue_free()
		return null
	node.top_level = true
	node.z_index = 10
	node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	node.pivot_offset = node.size * 0.5
	node.global_position = from - node.size * 0.5
	var t := node.create_tween()
	if delay_ms > 0.0:
		node.modulate.a = 0.0
		t.tween_interval(delay_ms / 1000.0)
		t.tween_callback(func() -> void: node.modulate.a = 1.0)
	t.tween_method(_fly_step.bind(node, from, to), 0.0, 1.0, _ms("longest_ms"))
	t.tween_callback(node.queue_free)
	return t


static func _fly_step(k: float, node: Control, from: Vector2, to: Control) -> void:
	if not is_instance_valid(to):
		return
	var e := 1.0 - pow(1.0 - k, 3.0)
	var end := to.get_global_rect().get_center()
	node.global_position = from.lerp(end, e) + Vector2(0.0, -sin(k * PI) * UI.px(44)) - node.size * 0.5
	node.scale = Vector2.ONE * (1.0 - 0.3 * k)
