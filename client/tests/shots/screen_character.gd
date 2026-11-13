extends SceneTree
## The Character screen for one of ShotData's roster (tools/render/shoot.sh):
## ID picks the character (5, a Skyskipper, by default); TAB the tab (0
## Heist, 1 Stats, 2 Compare); SCROLL scrolls; LOCALE picks the words
## (pt_BR); FIT=1 fails the run if any words do not fit; RECORD=1 writes
## the still's shot record beside it (docs/art/ui-quality/gate/shots.md).
func _initialize() -> void:
	_go()


func _go() -> void:
	root.size = Vector2i(1080, 2340)
	# TEXT=200 and HC=1 render §20.8's larger text and high contrast.
	if OS.get_environment("TEXT") != "":
		Settings.text_scale = int(OS.get_environment("TEXT"))
	Settings.high_contrast = OS.get_environment("HC") != ""
	if OS.get_environment("LOCALE") != "":
		Strings.set_locale(OS.get_environment("LOCALE"))
	Settings.apply()
	App.services = Fixtures.answered(Services.build(root, "", null, "user://outbox-shot.json"))
	App.services.store.dispatch(&"roster_loaded", {"view": ShotData.roster()})
	var id := int(OS.get_environment("ID")) if OS.get_environment("ID") != "" else 5
	App.services.router.go(&"character", {"id": id})
	await process_frame
	var screen: CharacterScreen = null
	for i in 10:
		await process_frame
		for c in root.get_children():
			if c is CharacterScreen:
				screen = c
		if screen != null:
			break
	if screen == null:
		screen = load("res://scenes/character.tscn").instantiate()
		root.add_child(screen)
	screen.clock = func() -> int: return RosterTests.NOW
	screen.tab = int(OS.get_environment("TAB")) if OS.get_environment("TAB") != "" else 0
	screen._refresh()
	for i in 60:
		await process_frame
		if Portrait.settled() and i > 30:
			break
	for s: StageHero in [screen.stage]:
		s.moving = false
		s.at_time(1.5)
	if OS.get_environment("SCROLL") != "":
		(screen.body.get_parent() as ScrollContainer).scroll_vertical = int(OS.get_environment("SCROLL"))
	for i in 4:
		await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(OS.get_environment("SHOT"))
	if OS.get_environment("RECORD") != "":
		write_record(screen, OS.get_environment("SHOT"))
	if OS.get_environment("FIT") != "":
		var bad := fit(screen)
		for b: String in bad:
			print("fit FAIL ", b)
		print("fit ", "ok" if bad.is_empty() else "FAIL")
		if not bad.is_empty():
			quit(1)
			return
	# §21.3's budget, as RenderingServer counts the frame.
	print("draw calls ", RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_DRAW_CALLS_IN_FRAME),
		", primitives ", RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_PRIMITIVES_IN_FRAME))
	print("wrote")
	quit()


## What does not fit on `screen`, one line each: a label's widest line wider
## than the label when it does not wrap, the label outside the panel it sits
## in, or the label off the screen's sides (the scroll runs below its foot).
static func fit(screen: CharacterScreen) -> Array[String]:
	var bad: Array[String] = []
	var wide_x := screen.size.x
	for l: Label in screen.find_children("*", "Label", true, false):
		if not l.is_visible_in_tree() or l.text == "":
			continue
		var at := l.get_global_rect()
		var font := l.get_theme_font("font")
		var wide := 0.0
		for line: String in l.text.split("\n"):
			wide = maxf(wide, font.get_string_size(line, HORIZONTAL_ALIGNMENT_LEFT, -1,
				l.get_theme_font_size("font_size")).x)
		if l.autowrap_mode == TextServer.AUTOWRAP_OFF and wide > at.size.x + 1.0:
			bad.append("%s %s: %.0f px of words in %.0f" % [l.get_path(), l.text, wide, at.size.x])
		var p := l.get_parent()
		while p != null and not p is PanelContainer:
			p = p.get_parent()
		if p != null and not (p as Control).get_global_rect().grow(1.0).encloses(at):
			bad.append("%s %s: %s outside its panel %s" % [l.get_path(), l.text, at,
				(p as Control).get_global_rect()])
		if at.position.x < -1.0 or at.end.x > wide_x + 1.0:
			bad.append("%s %s: %s off the screen" % [l.get_path(), l.text, at])
	return bad


## The still's shot record, from the frame it was saved from, so the gate's
## crops cut the controls this still shows: every button on screen and the
## words of 20 points and more, in points of the 390 x 845 frame, named by
## their words. Cards are left out: a button inside a listed card would
## have no ground left for value-steps.
static func write_record(screen: CharacterScreen, shot: String) -> void:
	var frame := Vector2(390, 845)
	var img := screen.get_viewport().get_texture().get_image()
	var img_w := float(img.get_width())
	var scale := frame.x / img_w
	var to_px := screen.get_viewport().get_final_transform()
	var controls := []
	var n := 0
	for c: Control in screen.find_children("*", "Control", true, false):
		if not c.is_visible_in_tree():
			continue
		var r := to_px * (c.get_global_transform_with_canvas() * Rect2(Vector2.ZERO, c.size))
		if r.size.x < 8.0 or r.size.y < 8.0 or r.position.y > img.get_height() or r.end.y < 0.0:
			continue
		var interactive := c is BaseButton
		var name := ""
		if interactive:
			name = str((c as Button).text) if c is Button else ""
			if c.accessibility_name != "":
				name = c.accessibility_name
			for l: Label in c.find_children("*", "Label", true, false):
				if name == "" and l.is_visible_in_tree():
					name = l.text
			if name == "":
				name = c.tooltip_text if c.tooltip_text != "" else str(c.name)
		elif c is Label and (c as Label).get_theme_font_size("font_size") >= UI.px(20):
			name = (c as Label).text
		else:
			continue
		n += 1
		var entry := {"name": "%s %d: %s" % [c.get_class().to_lower(), n, name.replace("\n", " ").left(80)],
			"rect": [snappedf(r.position.x * scale, 0.01), snappedf(r.position.y * scale, 0.01),
				snappedf(r.size.x * scale, 0.01), snappedf(r.size.y * scale, 0.01)]}
		if not interactive:
			entry["interactive"] = false
		controls.append(entry)
	var text := float(Settings.text_scale) / 100.0
	var record := {"image": shot.get_file(), "frame_pt": [frame.x, frame.y], "text_scale": text,
		"controls": controls}
	var f := FileAccess.open(shot.get_basename() + ".shot.json", FileAccess.WRITE)
	f.store_string(JSON.stringify(record, " ") + "\n")
	f.close()
	print("record ", controls.size(), " controls")
