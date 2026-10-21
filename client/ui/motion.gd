class_name Motion
## Every interface movement, timed to §21.8: 150 to 250 milliseconds, easing
## out, never overshooting; a button squashes slightly when pressed. Each
## reads Settings.reduced_motion (§20.8) and gives its reduced form: an
## entrance becomes a 150 ms fade with no travel, a press changes at once, a
## loop does not start. Timings are ui/tokens.json `motion`. A node on its
## way in carries the meta "entering" until it has arrived, so a check of
## its colours judges it as it will stand.


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


## A popped node (a badge, a toast, a dialog): it grows from 92% to its size
## with no overshoot, or fades under reduced motion.
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
	t.tween_property(node, "scale", Vector2.ONE, _ms("pop_ms")).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
	return _arrive(node, t)


## A sheet sliding up from the bottom edge by its own height, or fading.
static func sheet_in(node: Control) -> Tween:
	var t := node.create_tween()
	# A container places its children, so a sheet inside one fades in.
	if Settings.reduced_motion or node.get_parent() is Container:
		node.modulate.a = 0.0
		t.tween_property(node, "modulate:a", 1.0, _ms("fade_ms"))
		return _arrive(node, t)
	var at := node.position.y
	node.position.y = at + maxf(node.size.y, 1.0)
	t.tween_property(node, "position:y", at, _ms("sheet_ms")).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
	return t


## A button pressed or let go: it squashes and its body sinks onto its drop
## (§21.8), easing out; under reduced motion the change is immediate.
static func press(button: Control, down: bool) -> void:
	var box := RbBox.of(button)
	var squash := Vector2.ONE * (Tokens.number("motion", "press_squash") if down else 1.0)
	button.pivot_offset = button.size * 0.5
	if Settings.reduced_motion:
		button.scale = Vector2.ONE
		if box != null:
			box.press = 1.0 if down else 0.0
		return
	var t := button.create_tween().set_parallel(true)
	var ms := _ms("press_ms") * (0.6 if down else 1.0)
	t.tween_property(button, "scale", squash, ms).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	if box != null:
		t.tween_property(box, "press", 1.0 if down else 0.0, ms).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)


## A bar's value moving to `to`: a value changing, not a transition, so it
## takes the designs' 450 ms; at once under reduced motion.
static func fill(bar: Range, to: float) -> void:
	if Settings.reduced_motion or not bar.is_inside_tree():
		bar.value = to
		return
	bar.create_tween().tween_property(bar, "value", to, Tokens.number("motion", "bar_fill_ms") / 1000.0) \
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


## A screen arriving (the designs' 160 ms fade from 0.985 scale), for the
## router to call on the screen it has just shown; a plain 150 ms fade under
## reduced motion.
static func screen_in(screen: Control) -> Tween:
	var t := screen.create_tween()
	screen.modulate.a = 0.0
	if Settings.reduced_motion:
		t.tween_property(screen, "modulate:a", 1.0, _ms("fade_ms"))
		return _arrive(screen, t)
	screen.pivot_offset = screen.size * 0.5
	screen.scale = Vector2.ONE * 0.985
	t.set_parallel(true)
	t.tween_property(screen, "modulate:a", 1.0, _ms("screen_fade_ms")).set_ease(Tween.EASE_OUT)
	t.tween_property(screen, "scale", Vector2.ONE, _ms("screen_fade_ms")).set_trans(Tween.TRANS_CUBIC) \
		.set_ease(Tween.EASE_OUT)
	return _arrive(screen, t)


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
