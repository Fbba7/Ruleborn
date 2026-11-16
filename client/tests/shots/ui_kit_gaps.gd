extends RefCounted
## The kit tests' checks of the calls that filled the catalogue's gaps
## (tests/ui_kit_tests.gd; S3-R22, S3-R24, S3-R26, S3-R27): the slider
## (K06), the confirm and info dialogs (K17), the info popover (K30) and the
## empty state (K35). A helper, not a shot: each check is said through the
## kit tests' `check`.


static func run(tree: SceneTree, check: Callable) -> void:
	var screen := Control.new()
	screen.size = Vector2(1080, 2340)
	tree.root.add_child(screen)
	await _slider(tree, screen, check)
	await _dialogs(tree, screen, check)
	await _popover(tree, screen, check)
	await _empty(tree, screen, check)
	screen.queue_free()
	await tree.process_frame


## The slider is named and says its value, in its own words or as a share.
static func _slider(tree: SceneTree, screen: Control, check: Callable) -> void:
	var bad := []
	var heard := []
	var s := KitControls.slider("Music", 60, func(v: float) -> void: heard.append(v))
	screen.add_child(s)
	await tree.process_frame
	if s.accessibility_name != "Music":
		bad.append("its name is '%s'" % s.accessibility_name)
	if s.accessibility_description != "60%":
		bad.append("at 60 it says '%s'" % s.accessibility_description)
	s.value = 25
	if s.accessibility_description != "25%" or heard != [25.0]:
		bad.append("moved to 25 it says '%s' and called back %s" % [s.accessibility_description, heard])
	if s.size.y < UI.px(UI.CONTROL_POINTS) - 0.5:
		bad.append("it is %.0f px tall, under 48 points" % s.size.y)
	var said := KitControls.slider("Size", 3, func(_v: float) -> void: pass, 1, 5, 1,
		func(v: float) -> String: return "level %d of 5" % v)
	if said.accessibility_description != "level 3 of 5":
		bad.append("its own words are '%s'" % said.accessibility_description)
	var half := KitControls.slider("Pan", 0, func(_v: float) -> void: pass, -10, 10)
	if half.accessibility_description != "50%":
		bad.append("0 between -10 and 10 says '%s'" % half.accessibility_description)
	s.queue_free()
	said.free()
	half.free()
	check.call("KitControls.slider (K06) is named for a screen reader and says its value in words, a share of its "
			+ "range or its caller's words, as it moves, calling back with each value, at least 48 points tall "
			+ "(kit-spec.md section 6.5; S3-R26; §20.8, §21.1)", bad.is_empty(), "; ".join(bad))


## A confirm and an info mark one action primary; a plain dialog is as before.
static func _dialogs(tree: SceneTree, screen: Control, check: Callable) -> void:
	var bad := []
	var none := func() -> void: pass
	var back := UI.action("Back", none)
	var buy := UI.action("Buy", none, "gold")
	var confirm := KitPanels.dialog(screen, "Buy it?", "It costs 10", [back, buy], "confirm")
	bad.append_array(_primary("confirm", confirm, buy, [back]))
	confirm.queue_free()
	var keep := UI.action("Keep", none, "gold")
	var spend := UI.action("Spend", none, "gold")
	var chosen := KitPanels.dialog(screen, "Spend?", "", [keep, spend], "confirm", 0)
	bad.append_array(_primary("confirm with the first chosen", chosen, keep, [spend]))
	chosen.queue_free()
	var info := KitPanels.dialog(screen, "Not enough", "Collect more first", [], "info")
	var dismiss := _buttons(info)
	if dismiss.size() != 1:
		bad.append("an info without actions has %d buttons, not its Dismiss" % dismiss.size())
	else:
		bad.append_array(_primary("info", info, dismiss[0], []))
		dismiss[0].pressed.emit()
		await tree.process_frame
		if is_instance_valid(info):
			bad.append("the info's Dismiss did not close it")
	var ok := UI.action("OK", none, "gold")
	var plain := KitPanels.dialog(screen, "Title", "Words", [ok])
	if plain.find_child("Ribbon", true, false) != null or ok.has_meta("primary"):
		bad.append("a plain dialog has a ribbon or a primary action")
	if RbBox.of(ok).look != "gold" or plain.name != "Dialog":
		bad.append("a plain dialog changed its action's look or its name")
	var heads := plain.find_children("*", "Label", true, false).filter(func(l: Label) -> bool:
		return l.text == "Title" and l.theme_type_variation == "Heading")
	if heads.size() != 1:
		bad.append("a plain dialog lost its heading")
	plain.queue_free()
	await tree.process_frame
	check.call("KitPanels.dialog's confirm and info (K17) set the title on a ribbon (K19) and mark one action "
			+ "primary, gold, every other leather: a confirm's last or the one named, an info's Dismiss, which "
			+ "closes it; a dialog called as before keeps its heading and its actions' looks (kit-spec.md section "
			+ "6.5; S3-R27)", bad.is_empty(), "; ".join(bad))


static func _primary(said: String, veil: Control, main: Button, others: Array) -> Array:
	var bad := []
	var ribbon := veil.find_child("Ribbon", true, false) as Control
	if ribbon == null or RbBox.of(ribbon) == null or RbBox.of(ribbon).look != "chapter":
		bad.append("%s: no ribbon title" % said)
	if not main.has_meta("primary") or RbBox.of(main).look != "gold":
		bad.append("%s: '%s' is not the primary gold action" % [said, main.text])
	for b: Button in others:
		if b.has_meta("primary") or RbBox.of(b).look == "gold":
			bad.append("%s: '%s' is gold or primary too" % [said, b.text])
	return bad


static func _buttons(c: Control) -> Array[Button]:
	var out: Array[Button] = []
	for n: Node in c.find_children("*", "Button", true, false):
		out.append(n as Button)
	return out


## A tap on the (i) opens its popover over the window; a tap closes it.
static func _popover(tree: SceneTree, screen: Control, check: Callable) -> void:
	var bad := []
	var i := KitPanels.info("About essence", "Essence buys characters")
	i.position = Vector2(500, 300)
	screen.add_child(i)
	await tree.process_frame
	if i.size.x < UI.px(UI.CONTROL_POINTS) - 0.5 or i.accessibility_name != "About essence":
		bad.append("the (i) is %.0f px or named '%s'" % [i.size.x, i.accessibility_name])
	i.pressed.emit()
	await tree.process_frame
	var layer := i.get_meta("open") as Control if i.has_meta("open") else null
	if layer == null or layer.get_parent() != tree.root:
		bad.append("a tap did not open the popover over the window")
	else:
		var pop := layer.find_child("Popover", true, false) as Control
		var tip := layer.find_child("Pointer", true, false) as Control
		var words := layer.find_children("*", "Label", true, false)
		if pop == null or tip == null or words.is_empty() or (words[0] as Label).text != "Essence buys characters":
			bad.append("the popover has no frame, pointer or words")
		elif pop.get_global_rect().position.y < i.get_global_rect().end.y - 1.0:
			bad.append("the popover covers its (i)")
		elif absf(pop.position.x + tip.position.x + float(tip.get_meta("x", 0.0)) - i.get_global_rect().get_center().x) > 1.0:
			bad.append("the pointer is not on the (i)")
		var tap := InputEventMouseButton.new()
		tap.button_index = MOUSE_BUTTON_LEFT
		tap.pressed = true
		tap.position = pop.get_global_rect().get_center() if pop != null else Vector2(10, 10)
		tap.global_position = tap.position
		tree.root.push_input(tap, true)
		var up := tap.duplicate() as InputEventMouseButton
		up.pressed = false
		tree.root.push_input(up, true)
		await tree.process_frame
		if is_instance_valid(layer) and not layer.is_queued_for_deletion() or i.has_meta("open"):
			bad.append("a tap on the popover did not close it")
	i.pressed.emit()
	await tree.process_frame
	i.pressed.emit()
	await tree.process_frame
	if i.has_meta("open"):
		bad.append("a second tap on the (i) did not close it")
	i.queue_free()
	await tree.process_frame
	check.call("KitPanels.info (K30): a tap on its (i), a 48-point control named for a screen reader, opens a small "
			+ "popup frame over the window under it, its pointer on the (i), and a tap on the frame or the (i) "
			+ "closes it (kit-spec.md section 6.5; S3-R22; §21.1, §21.8)", bad.is_empty(), "; ".join(bad))


## The empty state shows its icon and words and does its one action.
static func _empty(tree: SceneTree, screen: Control, check: Callable) -> void:
	var bad := []
	var acted := []
	var e := KitPanels.empty("generalui/info", "Nothing yet", "Try again", func() -> void: acted.append(true))
	screen.add_child(e)
	await tree.process_frame
	var go := e.get_meta("action") as Button if e.has_meta("action") else null
	if go == null or go.text != "Try again" or RbBox.of(go).look != "gold":
		bad.append("no gold action named Try again")
	else:
		go.pressed.emit()
		if acted != [true]:
			bad.append("its action did nothing")
	if e.find_children("*", "TextureRect", true, false).is_empty() or RbBox.of(e) == null:
		bad.append("no icon or no kit material")
	var said := e.find_children("*", "Label", true, false).filter(func(l: Label) -> bool:
		return l.text == "Nothing yet")
	if said.is_empty():
		bad.append("its words are missing")
	var bare := KitPanels.empty("", "Nothing yet")
	if bare.has_meta("action") or not bare.find_children("*", "Button", true, false).is_empty():
		bad.append("an empty state without an action has a button")
	bare.free()
	e.queue_free()
	check.call("KitPanels.empty (K35): its icon, its words and one gold action that does what its caller asked, on "
			+ "a card in the kit's materials; none when it has none to do (kit-spec.md section 6.5; S3-R24)",
			bad.is_empty(), "; ".join(bad))
