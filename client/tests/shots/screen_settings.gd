extends SceneTree
## The settings screen (tools/render/shoot.sh): TAB picks the tab ("access",
## key frame 05's, by default; "game" or "account"); SCROLL scrolls; TEXT=200
## and HC=1 render §20.8's larger text and high contrast; LOCALE picks the
## words (pt_BR); SIGNED=1 signs the account in (its devices and ways to
## sign in on the account tab); FIT=1 fails the run if any words do not fit
## (and writes what it found to the still's .fit.txt); RECORD=1 writes the
## still's shot record beside it, named as key frame 05's
## (art/ui/keyframes/05-settings.shot.json, docs/art/ui-quality/gate/shots.md).
func _initialize() -> void:
	_go()


func _go() -> void:
	root.size = Vector2i(1080, 2340)
	_environment()
	App.services = Fixtures.answered(Services.build(root, "", null, "user://outbox-shot.json"))
	if OS.get_environment("SIGNED") != "":
		_signed_in()
	App.services.router.go(&"settings")
	await process_frame
	var screen: SettingsScreen = null
	for i in 10:
		await process_frame
		for c in root.get_children():
			if c is SettingsScreen:
				screen = c
		if screen != null:
			break
	if screen == null:
		screen = load("res://scenes/settings.tscn").instantiate()
		root.add_child(screen)
	# The screen reads the saved settings as it opens: the shot's own again.
	_environment()
	screen.tab_shown = OS.get_environment("TAB") if OS.get_environment("TAB") != "" else "access"
	screen._build()
	for i in 6:
		await process_frame
	if OS.get_environment("SIGNED") != "":
		_devices()
		for i in 4:
			await process_frame
	if OS.get_environment("SCROLL") != "":
		screen.list_scroll.scroll_vertical = int(OS.get_environment("SCROLL"))
	for i in 4:
		await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(OS.get_environment("SHOT"))
	if OS.get_environment("RECORD") != "":
		write_record(screen, OS.get_environment("SHOT"))
	if OS.get_environment("FIT") != "":
		var bad := fit(screen)
		var said := ""
		for b: String in bad:
			said += "fit FAIL %s\n" % b
		said += "fit %s\n" % ("ok" if bad.is_empty() else "FAIL")
		print(said.strip_edges())
		# shoot.sh keeps only the run's last lines, and the leaks Godot reports
		# at exit can push these out: the fit checks read them from beside the still.
		var out := FileAccess.open(OS.get_environment("SHOT").get_basename() + ".fit.txt", FileAccess.WRITE)
		out.store_string(said)
		out.close()
		if not bad.is_empty():
			quit(1)
			return
	# §21.3's budget, as RenderingServer counts the frame.
	print("draw calls ", RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_DRAW_CALLS_IN_FRAME),
		", primitives ", RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_PRIMITIVES_IN_FRAME))
	print("wrote")
	quit()


func _environment() -> void:
	Settings.text_scale = int(OS.get_environment("TEXT")) if OS.get_environment("TEXT") != "" else 100
	Settings.high_contrast = OS.get_environment("HC") != ""
	Settings.locale = OS.get_environment("LOCALE") if OS.get_environment("LOCALE") != "" else "en"
	Settings.apply()


## SIGNED=1: the account signed in, as auth_panel.gd's shot signs it in
## (a token, so AuthPanel's refresh keeps it signed in), before the screen
## builds.
func _signed_in() -> void:
	var s := App.services
	s.api.token = "shot"
	s.store.dispatch(&"signed_in", {"account": "shot"})
	s.store.dispatch(&"auth_status", {"status": "signed_in"})


## SIGNED=1, once AuthPanel has built: two devices, this phone and a nameless
## Android phone, with Game Center and Google Play both linked, as the
## server's session list reads (auth_tests.gd's), so the account tab shows
## its Devices and Methods sections.
func _devices() -> void:
	App.services.store.dispatch(&"auth_devices", {"devices": 2, "list": [
		{"id": 7, "current": true, "via": "gc", "device": "iphone", "model": "iPhone 15", "place": "PT", "idleHours": 0},
		{"id": 3, "current": false, "via": "gp", "device": "android_phone", "model": null, "place": null,
			"idleHours": 50}],
		"identities": [{"platform": "gc", "primary": true, "linkedAt": null},
			{"platform": "gp", "primary": false, "linkedAt": 0}],
		"platforms": ["gc", "gp"]})


## What does not fit on `screen`, one line each: a label's widest line wider
## than the label when it does not wrap, or its widest word when it does (a
## word broken in two, board 5's E), the label outside the panel it sits in,
## or the label off the screen's sides (the scroll runs below its foot); a
## button's words wider than its room the same two ways.
static func fit(screen: SettingsScreen) -> Array[String]:
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
		var word := _widest_word(l.text, font, l.get_theme_font_size("font_size"))
		if l.autowrap_mode != TextServer.AUTOWRAP_OFF and word > at.size.x + 1.0:
			bad.append("%s %s: a word of %.0f px broken in %.0f" % [l.get_path(), l.text, word, at.size.x])
		var p := l.get_parent()
		while p != null and not p is PanelContainer:
			p = p.get_parent()
		if p != null and not (p as Control).get_global_rect().grow(1.0).encloses(at):
			bad.append("%s %s: %s outside its panel %s" % [l.get_path(), l.text, at,
				(p as Control).get_global_rect()])
		if at.position.x < -1.0 or at.end.x > wide_x + 1.0:
			bad.append("%s %s: %s off the screen" % [l.get_path(), l.text, at])
	# A button's words wider than the button where they do not wrap, and its
	# widest word where they do.
	for b: Button in screen.find_children("*", "Button", true, false):
		if not b.is_visible_in_tree() or b.text == "":
			continue
		var words := b.get_theme_font("font").get_string_size(b.text, HORIZONTAL_ALIGNMENT_LEFT, -1,
			b.get_theme_font_size("font_size")).x
		if b.autowrap_mode != TextServer.AUTOWRAP_OFF:
			words = _widest_word(b.text, b.get_theme_font("font"), b.get_theme_font_size("font_size"))
		var room := b.size.x
		var box := b.get_theme_stylebox("normal")
		if box != null:
			room -= box.content_margin_left + box.content_margin_right
		if b.icon != null:
			room -= b.get_theme_constant("icon_max_width") + b.get_theme_constant("h_separation")
		if words > room + 1.0:
			bad.append("%s %s: %.0f px of words in %.0f" % [b.get_path(), b.text, words, room])
		if b.get_global_rect().end.x > wide_x + 1.0:
			bad.append("%s %s: off the screen" % [b.get_path(), b.text])
	return bad


## The still's shot record, from the frame it was saved from, so the gate's
## crops cut the controls this still shows, named as key frame 05's: the
## title's plate, the tabs as one row, the two A buttons, the size figure,
## the law's sample, the marks' card, each switch row and the back button,
## and every other button and the words of 20 points and more, in points of
## the 390 x 845 frame. Cards holding buttons are left out: a button inside a
## listed card would have no ground left for value-steps. What the scroll
## hides is left out too.
static func write_record(screen: SettingsScreen, shot: String) -> void:
	var frame := Vector2(390, 845)
	var img := screen.get_viewport().get_texture().get_image()
	var scale := frame.x / float(img.get_width())
	var to_px := screen.get_viewport().get_final_transform()
	var scroll := screen.list_scroll
	var seen := to_px * scroll.get_global_rect()
	var controls := []
	for c: Control in screen.find_children("*", "Control", true, false):
		if not c.is_visible_in_tree() or _inside(c):
			continue
		var r := to_px * (c.get_global_transform_with_canvas() * Rect2(Vector2.ZERO, c.size))
		if r.size.x < 8.0 or r.size.y < 8.0 or r.position.y > img.get_height() or r.end.y < 0.0:
			continue
		if scroll.is_ancestor_of(c) and not seen.grow(1.0).encloses(r):
			continue
		var kind := ""
		var name := ""
		var interactive := true
		if c.name == "Segments":
			kind = "row"
			for b: Button in c.find_children("*", "Button", true, false):
				name += (" " if name != "" else "") + (b.text if b.text != "" else b.accessibility_name)
		elif c.name == "Head":
			kind = "set-head"
			name = _words(c)
			interactive = false
		elif c is PanelContainer and c.get_parent() is VBoxContainer and c.get_parent().get_parent() is PanelContainer \
				and c.find_children("*", "BaseButton", true, false).is_empty() and c.get_child(0) is HBoxContainer \
				and c.find_children("*", "TextureRect", true, false).size() > 0:
			kind = "sample"
			name = _words(c)
			interactive = false
		elif c is PanelContainer and c.find_children("*", "GridContainer", true, false).size() > 0 \
				and c.find_children("*", "BaseButton", true, false).is_empty():
			kind = "shapes"
			name = _words(c)
			interactive = false
		elif c is BaseButton:
			var tag := str(c.get_meta("setting", ""))
			kind = "size-a" if tag in ["text-", "text+"] else "switch-row" if c.has_meta("on") \
				else "back" if c.get_meta("back", false) else "button"
			name = c.accessibility_name
			if name == "" and c is Button:
				name = (c as Button).text
		elif c == screen.text_label:
			kind = "size-mid"
			name = str(screen.text_label.get_meta("numerals", screen.text_label.get_meta("spoken", "")))
			interactive = false
		elif c is Label and (c as Label).get_theme_font_size("font_size") >= UI.text_px(20):
			kind = "words"
			name = (c as Label).text
			interactive = false
		if kind == "" or name.strip_edges() == "":
			continue
		var entry := {"name": "%s %d: %s" % [kind, controls.size() + 1, name.replace("\n", " ").left(80)],
			"rect": [snappedf(r.position.x * scale, 0.01), snappedf(r.position.y * scale, 0.01),
				snappedf(r.size.x * scale, 0.01), snappedf(r.size.y * scale, 0.01)]}
		if not interactive:
			entry["interactive"] = false
		controls.append(entry)
	var record := {"image": shot.get_file(), "frame_pt": [frame.x, frame.y],
		"text_scale": float(Settings.text_scale) / 100.0, "controls": controls}
	var f := FileAccess.open(shot.get_basename() + ".shot.json", FileAccess.WRITE)
	f.store_string(JSON.stringify(record, " ") + "\n")
	f.close()
	print("record ", controls.size(), " controls")


## The widest single word of `text` in `font` at `size`, in pixels.
static func _widest_word(text: String, font: Font, size: int) -> float:
	var widest := 0.0
	for line: String in text.split("\n"):
		for word: String in line.split(" ", false):
			widest = maxf(widest, font.get_string_size(word, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x)
	return widest


## A panel's words, in order, on one line.
static func _words(c: Control) -> String:
	var name := ""
	for l: Label in c.find_children("*", "Label", true, false):
		if l.text != "":
			name += (" " if name != "" else "") + l.text
	return name


## Whether `c` is part of something recorded whole: a button, the tabs, the
## title's plate, the sample or the marks' card.
static func _inside(c: Control) -> bool:
	var p := c.get_parent()
	while p != null:
		if p is BaseButton or p.name in ["Segments", "Head"]:
			return true
		if p is PanelContainer and p.find_children("*", "GridContainer", true, false).size() > 0 \
				and p.find_children("*", "BaseButton", true, false).is_empty():
			return true
		if p is PanelContainer and p.get_parent() is VBoxContainer and p.get_parent().get_parent() is PanelContainer \
				and p.find_children("*", "BaseButton", true, false).is_empty() and p.get_child_count() > 1 \
				and p.get_child(p.get_child_count() - 1) is HBoxContainer:
			return true
		p = p.get_parent()
	return false
