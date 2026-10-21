class_name A11yTests
extends RefCounted
## §20.8's accessibility set and §21.8's and §21.10's checks, on every
## screen: contrast by both models in both contrast modes, 200% text, colour
## blindness, nothing carried by colour alone, a name for everything a screen
## reader reaches, left-handed controls, rehearsal pause and pace, haptics,
## banners, and the island in grayscale. run.gd lends `check`, `mount` (a
## screen by its scene name, awaited) and `problems` (§21.1's layout rules).

var tree: SceneTree
var check: Callable
var mount: Callable
var problems: Callable
var screens: Array


func _init(t: SceneTree, c: Callable, m: Callable, p: Callable, s: Array) -> void:
	tree = t
	check = c
	mount = m
	problems = p
	screens = s


func run() -> void:
	_token_pairs()
	await _every_word()
	await _large_text()
	_colour_blindness()
	_not_colour_alone()
	await _named()
	_settings()
	await _left_handed()
	await _rehearsal()
	await _haptics()
	await _banners()
	_grayscale_island()


func _set_contrast(on: bool) -> void:
	Settings.high_contrast = on
	Settings.apply()


## What a node and every canvas item above it multiply its colours by: a
## faded control's words are faded too.
func _tint(c: CanvasItem) -> Color:
	var t := c.self_modulate
	var n: Node = c
	while n is CanvasItem:
		t *= (n as CanvasItem).modulate
		n = n.get_parent()
	return t


## Behind a word, for each state it is drawn in — a button's normal, hover,
## pressed and focus fills; else the nearest panel — over each end of the
## sky, faded as the node is. A disabled control is exempt (WCAG 1.4.3).
func _backgrounds(c: Control) -> Array[Color]:
	var fills: Array[Color] = []
	var n: Node = c
	while n != null and fills.is_empty():
		# A control drawn by a ScreenBox names the colours behind its words.
		if n is Control and n.has_meta("behind"):
			fills.assign(n.get_meta("behind"))
		elif n is Button:
			for state: String in ["normal", "hover", "pressed", "focus"]:
				var box := (n as Button).get_theme_stylebox(state)
				if box is StyleBoxFlat and (box as StyleBoxFlat).bg_color.a > 0.0:
					fills.append((box as StyleBoxFlat).bg_color)
		elif n is PanelContainer:
			var box := (n as PanelContainer).get_theme_stylebox("panel")
			if box is StyleBoxFlat and (box as StyleBoxFlat).bg_color.a > 0.0:
				fills.append((box as StyleBoxFlat).bg_color)
		n = n.get_parent()
	var tint := _tint(c)
	var out: Array[Color] = []
	var skies: Array[Color] = [Palette.SKY_TOP, Palette.SKY_BOTTOM]
	# A screen on the night backdrop (ScreenKit) names its own sky.
	var top: Node = c
	while top.get_parent() is Control:
		top = top.get_parent()
	if top.has_meta("sky"):
		skies.assign(top.get_meta("sky"))
	for sky: Color in skies:
		if fills.is_empty():
			out.append(sky)
		for f in fills:
			var faded := Color(f.r * tint.r, f.g * tint.g, f.b * tint.b, f.a * tint.a)
			out.append(ColourCheck.over(faded, sky))
	return out


func _token_pairs() -> void:
	var bad := []
	for hc: bool in [false, true]:
		_set_contrast(hc)
		# [words, behind them (Color() the sky), bold]: body text, a control's
		# words, and the marks drawn on the realm on their paper halo.
		var pairs := {
			"body text on a panel": [Palette.INK, Palette.PANEL, false],
			"a title on the sky": [Palette.INK, Color(), false, UI.TITLE_POINTS],
			"a main action's words": [Palette.INK, Palette.MOTION, true],
			"alarm words on a panel": [Palette.ALARM_TEXT, Palette.PANEL, false],
			"success words on a panel": [Palette.SUCCESS_TEXT, Palette.PANEL, false],
			"words on the alarm fill": [Palette.ON_ALARM, Palette.ALARM_FILL, true],
			"a guard's mark on its halo": [RealmView.mark_colour(), Palette.PAPER, true],
			"an alerted guard's mark on its halo": [RealmView.mark_colour("Alerted"), Palette.PAPER, true],
		}
		for name: String in pairs:
			for sky: Color in [Palette.SKY_TOP, Palette.SKY_BOTTOM]:
				var bg: Color = pairs[name][1]
				bg = sky if bg == Color() else ColourCheck.over(bg, sky)
				var fg: Color = pairs[name][0]
				var points: float = pairs[name][3] if pairs[name].size() > 3 else UI.TEXT_POINTS
				if not ColourCheck.readable(fg, bg, points, pairs[name][2]):
					bad.append("%s%s: %.2f:1, Lc %.0f" % [name, " (high contrast)" if hc else "",
						ColourCheck.ratio(fg, bg), ColourCheck.apca(fg, bg)])
	_set_contrast(false)
	check.call("every colour the client puts words in reads at 4.5:1 and at APCA's level for its size and weight, "
			+ "the realm's marks on their halo included, in both contrast modes (§21.8, §20.8)",
		bad.is_empty(), "; ".join(bad))


func _every_word() -> void:
	var bad := []
	for hc: bool in [false, true]:
		_set_contrast(hc)
		for sname: String in screens:
			var screen: Control = await mount.call(sname)
			screen.set_process(false)
			for c in screen.find_children("*", "", true, false):
				if not (c is Label or c is Button) or not (c as Control).is_visible_in_tree() or str(c.text) == "":
					continue
				if c is BaseButton and (c as BaseButton).disabled:
					continue
				var tint := _tint(c)
				var bgs := _backgrounds(c)
				var fg := (c as Control).get_theme_color("font_color")
				# The words, faded as the node is, over what is behind them.
				fg = ColourCheck.over(Color(fg.r * tint.r, fg.g * tint.g, fg.b * tint.b, fg.a * tint.a), bgs[0])
				var points := float(c.get_meta("points", UI.TEXT_POINTS))
				var bold := bool(c.get_meta("bold", false))
				for bg in bgs:
					if not ColourCheck.readable(fg, bg, points, bold):
						bad.append("%s%s: %s %.2f:1 Lc %.0f" % [sname, " (hc)" if hc else "", c.text,
							ColourCheck.ratio(fg, bg), ColourCheck.apca(fg, bg)])
						break
			screen.queue_free()
			await tree.process_frame
	_set_contrast(false)
	check.call("on every screen, every word reads against what is behind it, in every state a control is drawn "
			+ "in and faded as it is, in both contrast modes (§21.8, §21.10)", bad.is_empty(), "; ".join(bad))


func _large_text() -> void:
	var bad := []
	var was := tree.root.size
	tree.root.size = Vector2i(540, 1170)
	for scale: int in [150, 200]:
		Settings.text_scale = scale
		for locale: String in Strings.LOCALES:
			Strings.set_locale(locale)
			for sname: String in screens:
				var screen: Control = await mount.call(sname)
				screen.set_process(false)
				await tree.process_frame
				for p: String in problems.call(screen):
					bad.append("%d%% %s %s: %s" % [scale, locale, sname, p])
				screen.queue_free()
				await tree.process_frame
	Settings.text_scale = 100
	Strings.set_locale("en")
	tree.root.size = was
	check.call("every screen works with text at 150% and 200%: nothing wider than the phone, every control "
			+ "in reach (§20.8, §21.1)", bad.is_empty(), "; ".join(bad))


func _colour_blindness() -> void:
	var bad := []
	var schools := Tokens.schools()
	var shapes := {}
	for s in schools:
		shapes[Tokens.shape(s)] = true
	if shapes.size() != schools.size() or schools.size() != 6:
		bad.append("%d schools, %d shapes" % [schools.size(), shapes.size()])
	for form: String in ColourCheck.SIMULATIONS:
		for i in schools.size():
			for j in range(i + 1, schools.size()):
				var a: Color = ColourCheck.simulate(Palette.SCHOOL[schools[i]], form)
				var b: Color = ColourCheck.simulate(Palette.SCHOOL[schools[j]], form)
				if ColourCheck.delta_e(a, b) < ColourCheck.DISTINCT_DELTA_E:
					bad.append("%s: %s and %s" % [form, schools[i], schools[j]])
	check.call("the six schools stay apart for the three common forms of colour blindness, and each has a shape "
			+ "of its own (§20.8, §21.2)", bad.is_empty(), "; ".join(bad))


func _not_colour_alone() -> void:
	var bad := []
	# Wards: each school's shape draws differently.
	var outlines := {}
	for s in Tokens.schools():
		var pts := RealmView.shape_points(Tokens.shape(s), Vector2.ZERO, 10.0)
		outlines[str(pts)] = s
	if outlines.size() != Tokens.schools().size():
		bad.append("two schools draw the same shape")
	# Guards: states that share a ring colour have different marks.
	for a: String in Palette.GUARD_STATE:
		for b: String in Palette.GUARD_STATE:
			if a < b and Palette.GUARD_STATE[a] == Palette.GUARD_STATE[b] \
					and RealmView.GUARD_MARK[a] == RealmView.GUARD_MARK[b] and not (a in ["Unaware", "Returning"]
					and b in ["Unaware", "Returning"]):
				bad.append("guards %s and %s look alike" % [a, b])
			if a < b and RealmView.GUARD_MARK[a] == RealmView.GUARD_MARK[b] \
					and Palette.GUARD_STATE[a] != Palette.GUARD_STATE[b]:
				bad.append("guards %s and %s differ by colour alone" % [a, b])
	# Crew: each role's letters differ, in every language.
	for locale: String in Strings.LOCALES:
		Strings.set_locale(locale)
		var letters := {}
		for role: String in Palette.ROLE:
			letters[Strings.term("ROLE", role).substr(0, 2)] = role
		if letters.size() != Palette.ROLE.size():
			bad.append("two roles share their letters in %s" % locale)
	Strings.set_locale("en")
	# Statuses: each has its own glyph.
	var glyphs := {}
	for k: String in UI.GLYPH:
		glyphs[UI.GLYPH[k]] = k
	if glyphs.size() != UI.GLYPH.size():
		bad.append("two statuses share a glyph")
	check.call("nothing is carried by colour alone: wards by their school's shape, guards by a mark, crew by "
			+ "their role's letters, a status by its glyph (§20.8)", bad.is_empty(), "; ".join(bad))


func _named() -> void:
	var bad := []
	var letter := RegEx.create_from_string("[A-Za-zÀ-ÖØ-öø-ÿ]")
	var described := false
	for sname: String in screens:
		var screen: Control = await mount.call(sname)
		screen.set_process(false)
		await tree.process_frame
		for b in screen.find_children("*", "BaseButton", true, false):
			# What Godot says for a button: its accessibility name, or its text.
			var name := str((b as Control).accessibility_name)
			if name == "" and b is Button:
				name = (b as Button).text
			if name.length() <= 2 and not name.is_empty() and (b as Control).accessibility_name == "":
				name = ""   # two letters or a symbol are not a name
			if not letter.search(name):
				bad.append("%s: a control named \"%s\"" % [sname, name])
		for v in screen.find_children("*", "RealmView", true, false):
			described = described or str((v as Control).accessibility_name) != ""
		screen.queue_free()
		await tree.process_frame
	if not described:
		bad.append("no realm is described in words")
	check.call("every control a screen reader reaches has a name in words, and a realm is read in words "
			+ "(§20.8)", bad.is_empty(), "; ".join(bad))


func _settings() -> void:
	# A first launch follows the phone, whichever way it says.
	var asked := Settings.phone
	var from_phone: Array[bool] = []
	for says: bool in [true, false]:
		Settings.phone = func(_what: String) -> bool: return says
		DirAccess.remove_absolute(Settings.path)
		Settings.read_file()
		from_phone.append(Settings.high_contrast == says and Settings.reduced_motion == says)
	Settings.phone = asked
	Settings.change(func() -> void:
		Settings.text_scale = 175
		Settings.high_contrast = true
		Settings.left_handed = true
		Settings.slow_rehearsals = true
		Settings.banners_stay = true
		Settings.hold_ms = 2000
		Settings.reduced_motion = true)
	var contrast_applied := Palette.INK == Color("#000000")
	var still := UI.motion_ms(200) == 0.0
	Settings.text_scale = 100
	Settings.high_contrast = false
	Settings.left_handed = false
	Settings.slow_rehearsals = false
	Settings.banners_stay = false
	Settings.hold_ms = 1000
	Settings.reduced_motion = false
	Settings.read_file()
	var restored := [Settings.text_scale, Settings.high_contrast, Settings.left_handed, Settings.slow_rehearsals,
		Settings.banners_stay, Settings.reduced_motion, Settings.hold_ms] == [175, true, true, true, true, true, 2000]
	Settings.change(func() -> void:
		Settings.text_scale = 100
		Settings.high_contrast = false
		Settings.left_handed = false
		Settings.slow_rehearsals = false
		Settings.banners_stay = false
		Settings.hold_ms = 1000
		Settings.reduced_motion = false)
	check.call("high contrast and reduced motion start as the phone says; text size, contrast, left-handed "
			+ "controls, rehearsal pace, banners, hold time and motion are saved and restored, and take effect (§20.8)",
		from_phone == [true, true] and contrast_applied and still and restored and Palette.INK == Color("#221C3A"),
		"phone %s, contrast %s, still %s, restored %s" % [from_phone, contrast_applied, still, restored])


func _get_out(screen: Control) -> Array:
	var go: Button = null
	var gait: Button = null
	for b: Button in screen.find_children("*", "Button", true, false):
		if b.text == Strings.t("HEIST_GET_OUT"):
			go = b
		elif b.text == Strings.term("GAIT", "Walk"):
			gait = b
	return [go, gait]


func _left_handed() -> void:
	App.services.store.dispatch(&"heist_started", {})
	var right: Control = await mount.call("heist_screen")
	right.set_process(false)
	await tree.process_frame
	var r := _get_out(right)
	var right_ok: bool = r[0] != null and r[1] != null and r[0].global_position.x > r[1].global_position.x
	right.queue_free()
	Settings.left_handed = true
	var left: Control = await mount.call("heist_screen")
	left.set_process(false)
	await tree.process_frame
	var l := _get_out(left)
	var left_ok: bool = l[0] != null and l[1] != null and l[0].global_position.x < l[1].global_position.x
	left.queue_free()
	Settings.left_handed = false
	await tree.process_frame
	check.call("left-handed play mirrors the heist's controls: Get out moves to the other hand (§20.8)",
		right_ok and left_ok, "right-handed %s, left-handed %s" % [right_ok, left_ok])


func _rehearsal() -> void:
	App.services.store.dispatch(&"heist_started", {"island": PackedByteArray(), "testing": true})
	var screen: HeistScreen = await mount.call("heist_screen")
	screen.set_process(false)
	var t0 := screen.controller.world.tick()
	screen.toggle_pause()
	screen._process(2.0)
	var held := screen.controller.world.tick() == t0 and screen.paused
	screen.toggle_pause()
	Settings.slow_rehearsals = true
	var slow := is_equal_approx(screen.pace(), 0.75)
	Settings.slow_rehearsals = false
	var full := is_equal_approx(screen.pace(), 1.0)
	screen.queue_free()
	App.services.store.dispatch(&"heist_started", {})
	var raid: HeistScreen = await mount.call("heist_screen")
	raid.set_process(false)
	var no_pause := raid.pause_button == null
	raid.toggle_pause()
	no_pause = no_pause and not raid.paused
	raid.queue_free()
	await tree.process_frame
	check.call("a rehearsal can be paused at any time and run at 75%; a raid cannot be paused (§20.8)",
		held and slow and full and no_pause, "held %s, slow %s, full %s, raid unpaused %s" % [held, slow, full, no_pause])


func _haptics() -> void:
	var felt: Array[String] = []
	Haptics.player = func(kind: String, _pulses: Array) -> void: felt.append(kind)
	var b := UI.button("x", func() -> void: pass)
	b.pressed.emit()
	var cues := HeistScreen.cues(0, 1, 3, 2) + HeistScreen.cues(1, 1, 2, 2) + HeistScreen.cues(0, 0, -1, 4) \
		+ HeistScreen.cues(1, 1, 2, 2, 3, 2) + HeistScreen.cues(1, 1, 2, 2, -1, 3)
	Settings.haptics = false
	b.pressed.emit()
	Haptics.play("warning")
	Settings.haptics = true
	b.free()
	Haptics.player = Haptics._vibrate
	var patterns := Haptics.KINDS.all(func(k: String) -> bool: return not Tokens.list("haptics", k).is_empty())
	check.call("haptics: a light tap on a button, a warning as the alarm rises, a pulse as a ward or a pylon goes "
			+ "down, nothing when switched off (§21.8, §20.8)",
		felt == ["tap"] and cues == ["warning", "pulse", "pulse"] and patterns, "felt %s, cues %s" % [felt, cues])


func _banners() -> void:
	var gone := UI.banner("alarm", Strings.t("ERR_UNREACHABLE"), 30)
	tree.root.add_child(gone)
	Settings.banners_stay = true
	var kept := UI.banner("info", Strings.t("ERR_UNREACHABLE"), 30)
	tree.root.add_child(kept)
	Settings.banners_stay = false
	await tree.create_timer(0.2).timeout
	await tree.process_frame
	var words: Label = kept.find_children("*", "Label", true, false)[0]
	var ok := not is_instance_valid(gone) and is_instance_valid(kept) and words.text.begins_with(UI.GLYPH["info"]) \
		and words.accessibility_live == DisplayServer.LIVE_POLITE
	if is_instance_valid(kept):
		kept.queue_free()
	check.call("a banner leads with its glyph, is announced, goes by itself, or stays until dismissed when the "
			+ "player asks (§20.8)", ok)


func _grayscale_island() -> void:
	# What RealmView paints, read from the functions it paints with: a
	# headless run has no renderer to take §21.10's thumbnail, so the value
	# of every figure is measured against every ground it can stand on.
	var bad := []
	for hc: bool in [false, true]:
		_set_contrast(hc)
		var grounds := RealmView.grounds()
		var marks := {}
		for hero: int in RealmView.HERO:
			marks["feature %d's edge" % hero] = RealmView.edge_colour(hero)
		var figures := RealmView.figures()
		for f: String in figures:
			if f != "water ripple":
				marks[f] = figures[f]
		for m: String in marks:
			for g: String in grounds:
				var r := ColourCheck.ratio(marks[m], grounds[g])
				if r < 3.0:
					bad.append("%s on %s: %.2f:1%s" % [m, g, r, " (hc)" if hc else ""])
		var ripple := ColourCheck.ratio(figures["water ripple"], Palette.WATER)
		if ripple < 3.0:
			bad.append("water's ripples %.2f:1" % ripple)
	_set_contrast(false)
	check.call("the island keeps its figures by value: every feature that changes a route, each guard and the "
			+ "outlines of wards, the Vault and the crew stand 3:1 from every ground, and water's ripples from "
			+ "water, in both contrast modes (§21.10)", bad.is_empty(), "; ".join(bad))
