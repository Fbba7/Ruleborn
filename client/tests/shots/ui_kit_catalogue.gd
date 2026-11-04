extends SceneTree
## The kit's catalogue sheet (kit-spec.md section 6.4): every component of
## section 4 in every state, on phone-sized pages, one PNG a page. HC (any
## value), TEXT (100 or 200) and LOCALE (en or pt_BR) pick the variant; SHOT
## names page 1 (`...-01.png`). tools/ui_bake/catalogue.sh renders all eight.
## A cell is one (component, state) pair captioned with section 3's letters;
## D and L say why. Motion components add frame strips, full and reduced;
## skins with art draw from the atlas; a part taller than a page is drawn
## smaller to fit. ui_kit_tests.gd checks every pair has a place (`placed`).

const W := 1080
const H := 2340
## The narrowest a cell is, so a caption or a wrapping word keeps its words.
const CELL_MIN := 80
## How far a part may reach into the frame's bottom margin.
const SLACK := 6
const Art := preload("res://tests/shots/ui_kit_catalogue_art.gd")

## "K01:P" -> the page it is on, from the last lay_out().
static var placed: Dictionary = {}
## The parts taller than a whole page, from the last lay_out().
static var tall: Array[String] = []
static var _pending: Array[String] = []
static var _posts: Array[Callable] = []


func _initialize() -> void:
	_go()


func _go() -> void:
	root.size = Vector2i(W, H)
	Settings.path = "user://settings-shot.cfg"
	Settings.restore()
	Settings.locale = OS.get_environment("LOCALE") if OS.get_environment("LOCALE") != "" else "en"
	Settings.high_contrast = OS.get_environment("HC") != ""
	Settings.text_scale = int(OS.get_environment("TEXT")) if OS.get_environment("TEXT") != "" else 100
	Settings.reduced_motion = false
	Settings.banners_stay = true
	Settings.apply()
	Art.art_on()
	var shot := OS.get_environment("SHOT")
	var pages := await lay_out(self, func(n: int, _screen: Control) -> void:
		for i: int in 120:
			if Portrait.settled():
				break
			await process_frame
		for i: int in 4:
			await process_frame
		await RenderingServer.frame_post_draw
		var out := shot.replace("-01.png", "-%02d.png" % n)
		root.get_texture().get_image().save_png(out)
		print("wrote page %d: %s" % [n, out]))
	print("catalogue: %d pages, %d pairs placed%s" % [pages, placed.size(),
		"" if tall.is_empty() else ", taller than a page: " + ", ".join(tall)])
	if not KitSkin.missing.is_empty():
		print("catalogue: pieces missing: " + ", ".join(KitSkin.missing))
	quit()


## Lays every part out on pages of the phone's size in `tree`, calling
## `save` (n, screen) once a page is full and settled; returns the number of
## pages, and fills `placed` and `tall`.
static func lay_out(tree: SceneTree, save: Callable) -> int:
	placed = {}
	tall = []
	Art.drawn = []
	var all := parts()
	var n := 0
	var i := 0
	while i < all.size():
		n += 1
		var screen := Control.new()
		screen.name = "Catalogue"
		screen.size = Vector2(W, H)
		tree.root.add_child(screen)
		var column := UI.frame(screen)
		# The phone's size, whatever the window's is over its first frames.
		screen.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
		screen.size = Vector2(W, H)
		column.add_theme_constant_override("separation", UI.px(10))
		var heading := UI.label("", 13)
		heading.theme_type_variation = "Kicker"
		column.add_child(heading)
		for k: int in 3:
			await tree.process_frame
		var room := column.size.y
		_posts = []
		var ids: Array[String] = []
		while i < all.size():
			_pending = []
			var kept := _posts.size()
			var part: Control = (all[i][1] as Callable).call()
			column.add_child(part)
			# Wrapped words settle over a few frames; then the part's laid-out
			# bottom says whether it fits.
			for k: int in 3:
				await tree.process_frame
			var over := part.position.y + part.size.y > room + UI.px(SLACK)
			if over and not ids.is_empty():
				column.remove_child(part)
				part.free()
				_posts.resize(kept)
				break
			if over:
				tall.append(str(all[i][0]))
				part = _fit(column, part, room - part.position.y)
			for pair: String in _pending:
				if not placed.has(pair):
					placed[pair] = n
			var id := str(all[i][0]).get_slice(" ", 0)
			if id not in ids:
				ids.append(id)
			i += 1
		heading.text = "%s · %s · %s · %d%% · %d" % [" ".join(ids), Settings.locale,
			"HC" if Settings.high_contrast else "N", Settings.text_scale, n]
		for k: int in 3:
			await tree.process_frame
		for post: Callable in _posts:
			post.call()
		_posts = []
		for k: int in 2:
			await tree.process_frame
		await save.call(n, screen)
		screen.queue_free()
		await tree.process_frame
	return n


## Draws `part`, alone and taller than `room`, smaller, in a holder (a
## container would undo its scale).
static func _fit(column: Control, part: Control, room: float) -> Control:
	var at := part.size
	var holder := Control.new()
	part.reparent(holder, false)
	part.scale = Vector2.ONE * room / at.y
	part.size = at
	holder.custom_minimum_size = at * room / at.y
	column.add_child(holder)
	return holder


## Every (component, state) pair of kit-spec.md section 4, as "K01:N"; HC is
## every page's own mode, so it is left out. Read from the section's tables.
static func inventory(spec_text: String) -> Array[String]:
	var out: Array[String] = []
	var re := RegEx.create_from_string("^\\| (K\\d\\d) \\|[^|]*\\|[^|]*\\| ([A-Za-z ]+) \\|")
	for line: String in spec_text.split("\n"):
		var m := re.search(line)
		if m == null:
			continue
		for s: String in m.get_string(2).split(" ", false):
			if s != "HC":
				out.append("%s:%s" % [m.get_string(1), s])
	return out


# --- The parts, in section 4's order. Each is [title, builder]. ---------


static func parts() -> Array:
	var none := func() -> void: pass
	var t := func(key: String) -> String: return Strings.t(key)
	var out := []
	# K01: every face in its four baked states, then the primary's overlays.
	for face: Array in [["primary", "gold"], ["secondary", "leather"], ["tertiary", "ghost"],
			["tertiary on parchment", "ghost"], ["danger", "red"]]:
		out.append(["K01 Button (%s)" % face[0], func() -> Control:
			var r := _flow()
			for s: String in ["N", "P", "D", "L"]:
				r.add_child(_cell("K01", s, func() -> Control:
					var b := UI.action(t.call("SHOP_BUY"), none, face[1])
					if str(face[0]).ends_with("parchment"):
						return _on_parchment(b)
					return b, str(face[0])))
			return _part("K01 Button: %s" % face[0], [r])])
	out.append(["K01 Button (states)", func() -> Control:
		var r := _flow()
		for s: String in ["S", "A", "Ld", "RM"]:
			r.add_child(_cell("K01", s, func() -> Control: return UI.action(t.call("SHOP_BUY"), none, "gold"), "primary"))
		return _part("K01 Button", [r])])
	out.append(["K01 Button (press)", func() -> Control:
		return _part("K01 Button: press", _strip("K01", func() -> Control:
			return UI.action(t.call("SHOP_BUY"), none, "gold"),
			func(c: Control) -> void: Motion.press(c, true), Tokens.number("motion", "press_ms") * 0.6))])
	var round_main := func() -> Control:
		return KitControls.round_action("realmactions/build", t.call("HOME_PLAY"), none, true, 76)
	out.append(["K02 Big round action", func() -> Control:
		var r := _flow()
		r.add_child(_cell("K02", "N", func() -> Control:
			return KitControls.big_action("heistcontrols/getout", t.call("HEIST_GET_OUT"), none), "Get out"))
		for s: String in ["N", "P", "D", "L", "A", "Ld", "RM"]:
			r.add_child(_cell("K02", s, round_main, "main"))
		return _part("K02 Big round action", [r])])
	_motion(out, "K02 Big round action", round_main,
		func(c: Control) -> void: Motion.press(_target(c), true), Tokens.number("motion", "press_ms") * 0.6,
		false, false, true)
	out.append(["K03 Icon button", func() -> Control:
		var r := _flow()
		for s: String in ["N", "P", "D", "S", "A", "RM"]:
			r.add_child(_cell("K03", s, func() -> Control:
				return KitControls.icon_button("generalui/info", t.call("KIT_CLOSE"), none)))
		r.add_child(_cell("K03", "N", func() -> Control:
			return _on_parchment(KitControls.icon_button("generalui/info", "", none, "parchment")), "parchment"))
		return _part("K03 Icon button", [r])])
	out.append(["K04 Close and back", func() -> Control:
		var r := _flow()
		for s: String in ["N", "P", "RM"]:
			r.add_child(_cell("K04", s, func() -> Control: return KitNav.back(none), "back"))
			r.add_child(_cell("K04", s, func() -> Control:
				return KitControls.icon_button("generalui/close", t.call("KIT_CLOSE"), none), "close"))
		return _part("K04 Close and back", [r])])
	var sw := func(on: bool) -> Callable:
		return func() -> Control:
			return KitSwitch.make(on, t.call("KIT_ON"), t.call("KIT_OFF"), "", func(_on: bool) -> void: pass)
	out.append(["K05 Toggle", func() -> Control:
		var r := _flow()
		r.add_child(_cell("K05", "N", sw.call(true), "on"))
		r.add_child(_cell("K05", "N", sw.call(false), "off"))
		for s: String in ["P", "D", "RM"]:
			r.add_child(_cell("K05", s, sw.call(true), "on"))
		var row := _wide("K05", "N", func() -> Control:
			return KitControls.toggle_row("settingsandwellbeing/reducedmotion", t.call("SETTINGS_MOTION_ON"),
				t.call("SETTINGS_MOTION_OFF"), true, func(_on: bool) -> void: pass), "row")
		return _part("K05 Toggle", [r, row])])
	_motion(out, "K05 Toggle", sw.call(true),
		func(c: Control) -> void: (c as Button).button_pressed = false, Tokens.number("motion", "longest_ms"))
	out.append(["K06 Slider", func() -> Control:
		var r := _flow()
		for s: String in ["N", "P", "D", "RM"]:
			r.add_child(_cell("K06", s, func() -> Control:
				var slider := HSlider.new()
				slider.custom_minimum_size = Vector2(UI.px(150), UI.px(48))
				slider.value = 60
				return slider))
		return _part("K06 Slider", [r])])
	out.append(["K07 Segmented control", func() -> Control:
		var words := [t.call("KIT_ON"), t.call("KIT_OFF"), t.call("KIT_FULL")]
		var seg := func(chosen: int, light: bool) -> Callable:
			return func() -> Control:
				var s := KitNav.segmented(words, chosen, func(_i: int) -> void: pass, light)
				s.set_meta("target", s.find_children("*", "Button", true, false)[1])
				return s if not light else _on_parchment(s)
		var rows := []
		for s: String in ["N", "P", "D", "RM"]:
			rows.append(_wide("K07", s, seg.call(0, false), "dark"))
		rows.append(_wide("K07", "S", seg.call(1, false), "dark, the second chosen", true))
		rows.append(_wide("K07", "N", seg.call(0, true), "light"))
		return _part("K07 Segmented control", rows)])
	out.append(["K08 Chip", func() -> Control:
		var r := _flow()
		var chip := func(on: bool, light := false) -> Callable:
			return func() -> Control:
				var c := KitControls.chip(t.call("WORKSHOP_TAB_NEW"), on, none, "", Color(0, 0, 0, 0), light)
				return c if not light else _on_parchment(c)
		for s: String in ["N", "P", "D", "L", "RM"]:
			r.add_child(_cell("K08", s, chip.call(false)))
		r.add_child(_cell("K08", "S", chip.call(true), "on", true))
		r.add_child(_cell("K08", "N", chip.call(false, true), "light"))
		r.add_child(_cell("K08", "N", func() -> Control: return KitControls.school_button("time", false, none),
			"school"))
		r.add_child(_cell("K08", "N", func() -> Control:
			return KitControls.chip(t.call("COMMON_HOME"), false, none, "3", Tokens.color("success")), "count"))
		return _part("K08 Chip", [r])])
	var tabs := func(chosen: String, badges := {}) -> Callable:
		return func() -> Control:
			var b := KitNav.tabs(chosen, badges)
			b.set_meta("target", b.buttons["laws"])
			return b
	out.append(["K09 Tab bar", func() -> Control:
		var rows := [
			_wide("K09", "N", tabs.call("islands"), "islands chosen"),
			_wide("K09", "P", tabs.call("islands"), "laws held"),
			_wide("K09", "S", tabs.call("heist"), "heist chosen", true),
			_wide("K09", "A", tabs.call("islands", {"laws": 3, "crew": 1}), "badges", true),
			_wide("K09", "RM", tabs.call("islands")),
		]
		return _part("K09 Tab bar", rows)])
	_motion(out, "K09 Tab bar", tabs.call("islands"),
		func(c: Control) -> void: (c as KitTabs).choose("crew"), Tokens.number("motion", "pop_ms"), true, false, true)
	out.append(["K10 Hub control", func() -> Control:
		var hub := func(route: StringName) -> Callable:
			return func() -> Control:
				var h := ScreenNav.hub("laws", route)
				var bs := h.find_children("*", "Button", true, false)
				if bs.size() > 1:
					h.set_meta("target", bs[1])
				return h
		return _part("K10 Hub control", [_wide("K10", "N", hub.call(&"codex")), _wide("K10", "P", hub.call(&"codex")),
			_wide("K10", "S", hub.call(&"harmony"), "the second chosen", true), _wide("K10", "RM", hub.call(&"codex"))])])
	out.append(["K11 Text field", func() -> Control:
		var r := []
		for s: String in ["N", "D", "S", "Ld"]:
			r.append(_wide("K11", s, func() -> Control: return KitControls.search(t.call("SHOP_TITLE"))))
		return _part("K11 Text field", r)])
	out.append(["K12 Panel", func() -> Control:
		var r := _flow()
		for look: String in ["card", "card_gold", "glass"]:
			r.add_child(_cell("K12", "N", _panel.bind(look, t.call("SETTINGS_TITLE")), look))
		for s: String in ["S", "L", "RM"]:
			r.add_child(_cell("K12", s, _panel.bind("card", t.call("SETTINGS_TITLE")), "card"))
		return _part("K12 Panel", [r])])
	out.append(["K13 Parchment panel", func() -> Control:
		var r := _flow()
		r.add_child(_cell("K13", "N", _panel.bind("parchment", t.call("TRACK_CLAIM")), "plain"))
		r.add_child(_cell("K13", "N", _panel.bind("parchment_done", t.call("TRACK_CLAIM")), "done"))
		for s: String in ["S", "L"]:
			r.add_child(_cell("K13", s, _panel.bind("parchment", t.call("TRACK_CLAIM"))))
		return _part("K13 Parchment panel", [r])])
	out.append(["K14 Rank frame", func() -> Control:
		var r := _flow()
		var ranks := {"frame_oak": "LAW_RANK_COMMON", "frame_silver": "LAW_RANK_UNCOMMON",
			"frame_gold": "LAW_RANK_RARE", "frame_prismatic": "LAW_RANK_DEEP"}
		for look: String in ranks:
			r.add_child(_cell("K14", "N", _panel.bind(look, t.call(ranks[look])), look.trim_prefix("frame_")))
		for s: String in ["S", "L"]:
			r.add_child(_cell("K14", s, _panel.bind("frame_gold", t.call("LAW_RANK_RARE")), "gold"))
		return _part("K14 Rank frame", [r])])
	out.append(["K15 Well", func() -> Control:
		var r := _flow()
		r.add_child(_cell("K15", "N", func() -> Control:
			var card := UI.panel("card")
			var well := _panel("well", t.call("FRIENDS_FEED"))
			card.add_child(well)
			return card, "in a card"))
		return _part("K15 Well", [r])])
	var sheet := func(look: String) -> Callable:
		return func() -> Control:
			var s := KitPanels.sheet(t.call("SHOP_TITLE"), look)
			(s.get_meta("body") as VBoxContainer).add_child(UI.label(t.call("MAP_NO_ALERTS"), 16, true))
			return s
	out.append(["K16 Sheet", func() -> Control:
		var rows := [_wide("K16", "N", sheet.call("sheet"), "dark"), _wide("K16", "N", sheet.call("sheet_parchment"),
			"parchment"), _wide("K16", "RM", sheet.call("sheet"))]
		return _part("K16 Sheet", rows)])
	_motion(out, "K16 Sheet", sheet.call("sheet"),
		func(c: Control) -> void: Motion.sheet_in(c), Tokens.number("motion", "sheet_ms"), true, true, true)
	var popup := func() -> Control:
		var stage := Control.new()
		stage.custom_minimum_size = Vector2(UI.px(340), UI.px(230) * maxf(1.0, Settings.text_scale / 100.0))
		stage.clip_contents = true
		KitPanels.dialog(stage, t.call("SHOP_BUY"), t.call("ERR_NOT_ENOUGH_ESSENCE"),
			[UI.action(t.call("COMMON_DISMISS"), none, "gold")])
		return stage
	out.append(["K17 Popup", func() -> Control:
		var rows := [_wide("K17", "N", popup, "dialog"), _wide("K17", "RM", popup)]
		return _part("K17 Popup", rows)])
	_motion(out, "K17 Popup", popup, func(c: Control) -> void:
		var cards := c.find_children("*", "PanelContainer", true, false)
		if not cards.is_empty():
			Motion.pop(cards[0] as Control), Tokens.number("motion", "pop_ms"), false, false, true, 0.4)
	out.append(["K18 Header and top bar", func() -> Control:
		return _part("K18 Header and top bar", [
			_wide("K18", "N", func() -> Control: return KitNav.header(t.call("SHOP_TITLE"), t.call("FRIENDS_FEED")),
				"header"),
			_wide("K18", "N", func() -> Control:
				return KitNav.top_bar(t.call("SETTINGS_TITLE"), func() -> void: pass, "18+"), "top bar")])])
	out.append(["K19 Ribbon", func() -> Control:
		return _part("K19 Ribbon", [
			_wide("K19", "N", func() -> Control:
				return KitNav.hero(t.call("RESULT_LOOT"), t.call("SHOP_TITLE"), t.call("MAP_NO_ALERTS"), "×0.8"),
				"hero"),
			_wide("K19", "N", func() -> Control:
				return KitPanels.chapter("motion", t.call("KIT_TAB_LAWS"), "I", "3 / 4"), "chapter")])])
	out.append(["K20 List row", func() -> Control:
		var rows := []
		for s: String in ["N", "P", "D", "S", "L", "A"]:
			rows.append(_wide("K20", s, func() -> Control:
				return KitPanels.row("alerts/buildingready", t.call("HOME_COLLECT"), t.call("MAP_NO_ALERTS"),
					KitStatus.plate("12m"), func() -> void: pass)))
		return _part("K20 List row", rows)])
	out.append(["K21 Section heading", func() -> Control:
		return _part("K21 Section heading", [_wide("K21", "N", func() -> Control:
			return KitPanels.section(t.call("FRIENDS_FEED")))])])
	out.append(["K22 Scrim and backdrop", func() -> Control:
		var r := _flow()
		for look: String in ["night", "night_rays", "scrim"]:
			r.add_child(_cell("K22", "N", func() -> Control:
				var p := UI.panel(look)
				p.custom_minimum_size = Vector2(UI.px(100), UI.px(80))
				return p, look))
		return _part("K22 Scrim and backdrop", [r])])
	out.append(["K23 Currency pill", func() -> Control:
		var r := _flow()
		var pill := func(icon: String, amount: String, fraction: float, tone: String) -> Callable:
			return func() -> Control: return KitStatus.resource(icon, amount, fraction, Tokens.color(tone))
		r.add_child(_cell("K23", "N", pill.call("resources/starlight", "12,480", 0.62, "starlight"), "Starlight"))
		r.add_child(_cell("K23", "N", pill.call("resources/aether", "3,105", 0.95, "aether"), "Aether"))
		r.add_child(_cell("K23", "N", pill.call("resources/essence", "840", 0.2, "essence"), "Essence"))
		for s: String in ["P", "A", "RM"]:
			r.add_child(_cell("K23", s, pill.call("resources/starlight", "12,480", 0.62, "starlight")))
		return _part("K23 Currency pill", [r])])
	out.append(["K24 Counter", func() -> Control:
		var r := _flow()
		var counter := func(value: String) -> Callable:
			return func() -> Control:
				var l := UI.label(value, 30)
				l.theme_type_variation = "Display"
				return l
		r.add_child(_cell("K24", "N", counter.call("2,310")))
		r.add_child(_cell("K24", "N", func() -> Control: return KitStatus.xp(588, 600, "588 / 600"), "xp"))
		r.add_child(_cell("K24", "RM", counter.call("2,310"), "the final number at once"))
		var roll := _flow()
		for v: String in ["0", "580", "1,160", "1,740", "2,310"]:
			roll.add_child(_cell("K24", "N", counter.call(v), "roll"))
		var gold := _wide("K24", "N", Art.numerals.bind("num_gold"), "num_gold, every glyph")
		return _part("K24 Counter", [r, roll, gold])])
	var bar := func(tone: String) -> Callable:
		return func() -> Control:
			var p := KitStatus.progress(3, 5, "3 / 5", Tokens.color(tone))
			p.custom_minimum_size.x = UI.px(240)
			return p
	out.append(["K25 Progress bar", func() -> Control:
		var r := _flow()
		for tone: String in ["gold", "success", "alarm", "motion"]:
			r.add_child(_cell("K25", "N", bar.call(tone), tone))
		r.add_child(_cell("K25", "L", bar.call("gold")))
		r.add_child(_cell("K25", "RM", bar.call("gold")))
		return _part("K25 Progress bar", [r])])
	_motion(out, "K25 Progress bar", bar.call("gold"), func(c: Control) -> void:
		var b := c.find_children("*", "Range", true, false)
		if not b.is_empty():
			(b[0] as Range).value = 0.2
			Motion.fill(b[0] as Range, 0.9), Tokens.number("motion", "longest_ms"))
	out.append(["K26 Ring and dial", func() -> Control:
		var r := _flow()
		r.add_child(_cell("K26", "N", func() -> Control: return KitHud.dial("38", "min", 0.6), "dial"))
		r.add_child(_cell("K26", "N", func() -> Control:
			var ring := KitRing.new()
			ring.fraction = 0.35
			ring.custom_minimum_size = Vector2.ONE * UI.px(56)
			return ring, "ring"))
		r.add_child(_cell("K26", "RM", func() -> Control: return KitHud.dial("38", "min", 0.6), "dial"))
		return _part("K26 Ring and dial", [r])])
	out.append(["K27 Badge", func() -> Control:
		var r := _flow()
		r.add_child(_cell("K27", "N", func() -> Control: return KitStatus.badge("4"), "count"))
		r.add_child(_cell("K27", "N", func() -> Control: return KitStatus.badge("12"), "count"))
		r.add_child(_cell("K27", "A", Art.dot, "dot", true))
		return _part("K27 Badge", [r])])
	out.append(["K28 Tag and plate", func() -> Control:
		var r := _flow()
		r.add_child(_cell("K28", "N", func() -> Control: return KitStatus.tag(t.call("WORKSHOP_TAB_NEW")), "tag"))
		r.add_child(_cell("K28", "N", func() -> Control: return KitStatus.tag(t.call("WORKSHOP_TAB_NEW"), true),
			"tag, dark"))
		r.add_child(_cell("K28", "N", func() -> Control: return KitStatus.plate("LV 5"), "plate"))
		r.add_child(_cell("K28", "N", func() -> Control: return UI.status("success", t.call("SHOP_BUY")), "success"))
		r.add_child(_cell("K28", "N", func() -> Control: return UI.status("alarm", t.call("HUD_ALARM_WORD")), "alarm"))
		return _part("K28 Tag and plate", [r])])
	var banner := func(kind: String, key: String) -> Callable:
		return func() -> Control: return UI.banner(kind, t.call(key))
	out.append(["K29 Banner", func() -> Control:
		var rows := [_wide("K29", "N", banner.call("info", "MAP_NO_ALERTS"), "info"),
			_wide("K29", "N", banner.call("success", "SHOP_BUY"), "success"),
			_wide("K29", "N", banner.call("alarm", "ERR_NOT_ENOUGH_ESSENCE"), "alarm"),
			_wide("K29", "N", func() -> Control:
				return KitPanels.notice("alarm", "alerts/raided", t.call("HUD_ALARM_WORD"), t.call("MAP_NO_ALERTS"),
					t.call("COMMON_DISMISS"), func() -> void: pass), "notice"),
			_wide("K29", "RM", banner.call("info", "MAP_NO_ALERTS"))]
		return _part("K29 Banner", rows)])
	_motion(out, "K29 Banner", banner.call("success", "SHOP_BUY"),
		func(c: Control) -> void: Motion.pop(c), Tokens.number("motion", "pop_ms"), true, false, true)
	out.append(["K30 Info popover", func() -> Control:
		# None today: a stand-in from today's parts (an (i) control and a
		# small glass frame), so the pair has its place.
		var pop := func() -> Control:
			var v := VBoxContainer.new()
			v.add_child(KitControls.icon_button("generalui/info", "", none))
			var p := _panel("glass", t.call("ERR_NOT_ENOUGH_ESSENCE"))
			v.add_child(p)
			return v
		var r := _flow()
		r.add_child(_cell("K30", "N", pop, "stand-in, none today"))
		r.add_child(_cell("K30", "RM", pop, "stand-in, none today"))
		return _part("K30 Info popover", [r])])
	out.append(["K31 Heist clock and alarm meter", func() -> Control:
		var r := _flow()
		r.add_child(_cell("K31", "N", func() -> Control: return KitHud.clock("2:26"), "clock"))
		r.add_child(_cell("K31", "N", func() -> Control: return KitHud.clock("0:24", true), "clock, late"))
		r.add_child(_cell("K31", "N", func() -> Control:
			return KitHud.meter(4, 6, "%s 4 / 6" % t.call("HUD_ALARM_WORD")), "meter"))
		r.add_child(_cell("K31", "A", func() -> Control: return KitHud.clock("0:24", true), "clock"))
		r.add_child(_cell("K31", "RM", func() -> Control: return KitHud.clock("2:26"), "clock"))
		var alarm := _wide("K31", "N", func() -> Control: return KitHud.alarm(2, 6, t.call("HUD_ALARM_WORD")), "alarm")
		var digits := _flow()
		for finish: String in ["num_timer", "num_timer_red"]:
			digits.add_child(_wide("K31", "N", Art.numerals.bind(finish), "%s, every glyph" % finish))
		return _part("K31 Heist clock and alarm meter", [r, alarm, digits])])
	out.append(["K32 Pips", func() -> Control:
		var r := _flow()
		r.add_child(_cell("K32", "N", func() -> Control: return KitHud.pips(2, 2), "2 of 2"))
		r.add_child(_cell("K32", "N", func() -> Control: return KitHud.pips(1, 3), "1 of 3"))
		r.add_child(_cell("K32", "RM", func() -> Control: return KitHud.pips(1, 3)))
		return _part("K32 Pips", [r])])
	out.append(["K33 Hint", func() -> Control:
		return _part("K33 Hint", [_wide("K33", "N", func() -> Control: return KitStatus.hint(t.call("MAP_NO_ALERTS"))),
			_wide("K33", "RM", func() -> Control: return KitStatus.hint(t.call("MAP_NO_ALERTS")))])])
	out.append(["K34 Spinner", func() -> Control:
		# None today: one sprite turned, a quarter a frame; reduced, a still
		# mark with the word.
		var r := _flow()
		for turn: int in 4:
			r.add_child(_cell("K34", "", func() -> Control: return _spinner(turn * 90.0),
				"%d°%s" % [turn * 90, "" if Art.pieces.has(Art.OVERLAYS["Ld"]) else ", stand-in"]))
		var still := _flow()
		still.add_child(_cell("K34", "RM", func() -> Control:
			var h := HBoxContainer.new()
			h.add_child(_spinner(0.0))
			h.add_child(UI.label(t.call("COMMON_LOADING"), 15))
			return h, "a still mark and the word"))
		return _part("K34 Spinner", [_caption("full"), r, _caption("reduced"), still])])
	out.append(["K35 Empty state", func() -> Control:
		return _part("K35 Empty state", [_wide("K35", "N", func() -> Control:
			return ScreenParts.empty("generalui", "info", t.call("LAB_FOUND_NONE"), func() -> void: pass))])])
	out.append(["K36 Avatar", func() -> Control:
		var r := _flow()
		for s: String in ["N", "P", "S", "A"]:
			r.add_child(_cell("K36", s, func() -> Control:
				return KitSocial.avatar(Portrait.of("mossbear"), "KO", "Kofi", t.call("HUD_ROOM"), "alarm",
					func() -> void: pass)))
		r.add_child(_cell("K36", "N", func() -> Control:
			return KitSocial.avatar(null, "IN", "Ines", "", "", func() -> void: pass), "initials"))
		return _part("K36 Avatar", [r])])
	var card := func(chosen: bool) -> Callable:
		return func() -> Control:
			return KitCards.portrait(Portrait.of("skyskipper"), "Pip", 5, "motion", Tokens.color("success"),
				"crewroles/carrier", func() -> void: pass, chosen)
	out.append(["K37 Portrait disc", func() -> Control:
		var r := _flow()
		for s: String in ["N", "P", "D", "L"]:
			r.add_child(_cell("K37", s, card.call(false)))
		return _part("K37 Portrait disc", [r])])
	out.append(["K37 Portrait disc", func() -> Control:
		var r := _flow()
		for s: String in ["A", "RM"]:
			r.add_child(_cell("K37", s, card.call(false)))
		r.add_child(_cell("K37", "S", card.call(true), "chosen", true))
		r.add_child(_cell("K37", "N", func() -> Control:
			return KitHud.crew(Portrait.of("tidewalker"), "Mo", 0.7, 1, func() -> void: pass, "time"), "crew key"))
		return _part("K37 Portrait disc", [r])])
	out.append(["K38 Level disc", func() -> Control:
		var r := _flow()
		var disc := func() -> Control:
			var p := UI.panel("level_disc")
			p.custom_minimum_size = Vector2.ONE * UI.px(44)
			var l := UI.label("7", 18)
			l.theme_type_variation = "NumberM"
			p.add_child(l)
			return p
		r.add_child(_cell("K38", "N", disc))
		r.add_child(_cell("K38", "A", disc))
		r.add_child(_cell("K38", "N", func() -> Control:
			return KitHud.keeper(Icons.texture("crewroles/scout"), "Ines", 7, 0.64, "410"), "keeper"))
		var white := _wide("K38", "N", Art.numerals.bind("num_white"), "num_white, every glyph")
		return _part("K38 Level disc", [r, white])])
	out.append(["K39 Reward tile", func() -> Control:
		var r := _flow()
		var tile := func(icon: String, amount: String, key: String, tone: String) -> Callable:
			return func() -> Control: return KitCards.reward(icon, amount, t.call(key), tone)
		r.add_child(_cell("K39", "N", tile.call("resources/starlight", "+2,310", "RESULT_STARLIGHT", "gold"), "gold"))
		r.add_child(_cell("K39", "N", tile.call("resources/essence", "+805", "RESULT_ESSENCE", "green"), "green"))
		r.add_child(_cell("K39", "N", tile.call("resources/renown", "+15", "RESULT_RENOWN", "pink"), "pink"))
		for s: String in ["S", "L", "A", "RM"]:
			r.add_child(_cell("K39", s, tile.call("resources/starlight", "+2,310", "RESULT_STARLIGHT", "gold")))
		r.add_child(_cell("K39", "N", func() -> Control:
			return KitCards.season_reward("Common", "currencies/starglass", "600", func() -> void: pass, false,
				t.call("TRACK_CLAIM")), "season"))
		return _part("K39 Reward tile", [r])])
	out.append(["K40 Reward sequence", func() -> Control:
		return _part("K40 Reward sequence", _sequence())])
	out.append(["K41 Stat tile", func() -> Control:
		var r := _flow()
		for s: String in ["N", "A"]:
			r.add_child(_cell("K41", s, func() -> Control:
				return KitCards.stat("crewroles/scout", t.call("HUD_ROOM"), "6", "+1", 6, 10, 1)))
		return _part("K41 Stat tile", [r])])
	out.append(["K42 Streak and week tiles", func() -> Control:
		return _part("K42 Streak and week tiles", [
			_wide("K42", "N", func() -> Control:
				return KitHud.streak(["M", "T", "W", "T", "F", "S"], 4, 4, "alerts/seasonreward", "+100",
					["kept", "today", "later"]), "streak: done, today, later"),
			_wide("K42", "S", func() -> Control:
				return KitHud.week([60, 40, 55, 15, 38, 20, 48], ["M", "T", "W", "T", "F", "S", "S"], 4),
				"week, today chosen", true)])])
	out.append(["K43 Quest card", func() -> Control:
		var rows := []
		var quest := func(done: int) -> Callable:
			return func() -> Control:
				return KitPanels.quest("screens/heist", t.call("HOME_PLAY"), done, 1, "+40", "currencies/seasonstars",
					t.call("TRACK_CLAIM"), func() -> void: pass)
		rows.append(_wide("K43", "N", quest.call(0), "in progress"))
		rows.append(_wide("K43", "N", quest.call(1), "claim"))
		for s: String in ["P", "A", "Ld"]:
			rows.append(_wide("K43", s, quest.call(1)))
		return _part("K43 Quest card", rows)])
	out.append(["K44 Law card and law disc", func() -> Control:
		var r := _flow()
		var law := func() -> Control:
			return KitCards.law_card("laws/bounce", "Bounce", "motion", "common", "", 102, "12")
		for s: String in ["N", "P", "S", "L", "A"]:
			r.add_child(_cell("K44", s, law))
		r.add_child(_cell("K44", "N", func() -> Control:
			return KitCards.law_card("laws/halfgravity", "Half gravity", "time", "deep", "II", 102, "22"), "deep"))
		r.add_child(_cell("K44", "N", func() -> Control:
			return KitCards.law_disc("laws/sleepwalk", "Sleepwalk", "spirit"), "disc"))
		return _part("K44 Law card and law disc", [r])])
	for states: Array in [["N", "P", "D"], ["S", "L"]]:
		out.append(["K45 Product card", func() -> Control:
			var r := _flow()
			for s: String in states:
				r.add_child(_cell("K45", s, func() -> Control:
					return KitCards.product(Portrait.of("archivist"), t.call("WORKSHOP_TAB_NEW"), t.call("SHOP_BUY"),
						"120", func() -> void: pass, "round_violet", 112.0, "resources/renown")))
			return _part("K45 Product card", [r])])
	out.append(["K46 Loot panel", func() -> Control:
		var loot := func() -> Control:
			return KitHud.loot([[t.call("HUD_ROOM"), "1,840"], [t.call("HUD_LEFT"), "2,600"]], 0.62, 0.8, "80%")
		var r := _flow()
		r.add_child(_cell("K46", "N", loot))
		r.add_child(_cell("K46", "RM", loot))
		return _part("K46 Loot panel", [r])])
	out.append(["K47 Album, build and fact cards", func() -> Control:
		var r := _flow()
		var album := func() -> Control:
			return KitCards.album_card("laws/bounce", "Brittle stone", "matter", "common", "Skyfield", "10")
		for s: String in ["N", "P", "S", "L"]:
			r.add_child(_cell("K47", s, album, "album"))
		r.add_child(_cell("K47", "N", func() -> Control:
			return KitCards.build_card("resources/starlight", "Star Well", t.call("HOME_COLLECT"), "resources/starlight",
				"1,200", "3 / 4", func() -> void: pass), "build"))
		r.add_child(_cell("K47", "N", func() -> Control:
			var f := KitCards.fact("crewroles/carrier", t.call("HUD_ROOM"), t.call("RESULT_LOOT"), "motion")
			f.custom_minimum_size.x = UI.px(240)
			return f, "fact"))
		return _part("K47 Album, build and fact cards", [r])])
	return out


# --- Cells and states -----------------------------------------------------


## Appends `title`'s motion strip to `out` as parts of their own, the full
## motion and the reduced one apart when `apart` (a strip of big parts is
## taller than a page), each frame drawn at `shrink` of its size.
static func _motion(out: Array, title: String, make: Callable, start: Callable, ms: float,
		wide := false, loose := false, apart := false, shrink := 1.0) -> void:
	var id := title.get_slice(" ", 0)
	var halves: Array = [[false, true]]
	if apart:
		halves = [[false], [true]]
	for h: Array in halves:
		var which: Array[bool] = []
		which.assign(h)
		var name := "%s: motion" % title
		out.append([name, func() -> Control:
			return _part(name, _strip(id, make, start, ms, wide, loose, which, shrink))])


static func _part(title: String, rows: Array) -> VBoxContainer:
	var v := VBoxContainer.new()
	v.name = title.get_slice(" ", 0)
	v.add_theme_constant_override("separation", UI.px(6))
	var head := UI.label(title, 15)
	head.theme_type_variation = "BodyBold"
	head.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	head.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.add_child(head)
	for r: Control in rows:
		v.add_child(r)
	return v


static func _flow() -> HFlowContainer:
	var r := UI.row(12)
	r.alignment = FlowContainer.ALIGNMENT_BEGIN
	return r


static func _caption(text: String) -> Label:
	var l := UI.label(text, 13, true)
	l.theme_type_variation = "Secondary"
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return l


## A full-width cell (a bar, a row, a sheet).
static func _wide(id: String, state: String, make: Callable, caption := "", own := false) -> Control:
	var c := _cell(id, state, make, caption, own)
	c.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return c


## One (component, state) cell: the component `make` builds, put in `state`
## (unless `own`: `make` already shows it), with its caption under it.
static func _cell(id: String, state: String, make: Callable, caption := "", own := false) -> Control:
	if state != "":
		_pending.append("%s:%s" % [id, state])
	var was := Settings.reduced_motion
	Settings.reduced_motion = state == "RM"
	var c: Control = make.call()
	Settings.reduced_motion = was
	var stage := MarginContainer.new()
	stage.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	stage.add_child(c)
	var over := Control.new()
	over.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stage.add_child(over)
	var why := ""
	if not own:
		why = _apply(c, state, over)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", UI.px(2))
	v.add_child(stage)
	v.custom_minimum_size.x = UI.px(CELL_MIN * clampf(Settings.text_scale / 100.0, 1.0, 1.8))
	var bits := PackedStringArray()
	for w: String in [caption, state, why]:
		if w != "":
			bits.append(w)
	v.add_child(_caption(" · ".join(bits)))
	return v


## Puts `c` in `state`; returns why it is disabled or locked, if it is.
static func _apply(c: Control, state: String, over: Control) -> String:
	match state:
		"P":
			var target := _target(c)
			if target is BaseButton and not (target as BaseButton).toggle_mode:
				(target as BaseButton).toggle_mode = true
				(target as BaseButton).set_pressed_no_signal(true)
			_posts.append(func() -> void:
				target.pivot_offset = target.size * 0.5
				target.scale = Vector2.ONE * Tokens.number("motion", "press_squash")
				var box := RbBox.of(target)
				if box != null:
					box.press = 1.0)
		"D":
			var any := false
			for n: Node in [c] + c.find_children("*", "", true, false):
				if n is BaseButton:
					(n as BaseButton).disabled = true
					any = true
				elif n is LineEdit:
					(n as LineEdit).editable = false
					any = true
				elif n is Slider:
					(n as Slider).editable = false
					any = true
			var target := _target(c)
			if not (target is BaseButton) or not any:
				target.modulate.a = 0.5
			return Strings.t("ERR_NOT_ENOUGH_ESSENCE")
		"S":
			var box := RbBox.of(_target(c))
			if box != null and Art.pieces.has(Art.OVERLAYS["S"]):
				var target := _target(c)
				_posts.append(Art.rim.bind(target, over))
			elif box != null:
				box.set_chosen(true)
			elif _target(c) is LineEdit:
				_posts.append((_target(c) as LineEdit).grab_focus)
		"L":
			var target := _target(c)
			_posts.append(Art.lock.bind(target))
			var mark := TextureRect.new()
			var lock := Art.overlay(Art.OVERLAYS["L"])
			mark.texture = lock if lock != null else Icons.texture("generalui/lock")
			mark.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			mark.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			mark.size = Vector2.ONE * UI.px(22)
			mark.position = Vector2.ONE * -UI.px(4)
			over.add_child(mark)
			return Strings.t("SAGE_UNLOCKS") % 5 if Strings.t("SAGE_UNLOCKS").contains("%d") else Strings.t("SCREEN_SLOT_LOCKED")
		"A":
			var badge := KitStatus.badge("3")
			badge.set_anchors_preset(Control.PRESET_TOP_RIGHT)
			badge.grow_horizontal = Control.GROW_DIRECTION_BEGIN
			badge.position.y = -UI.px(6)
			over.add_child(badge)
		"Ld":
			for n: Node in [c] + c.find_children("*", "", true, false):
				if n is Label or n is Button or n is LineEdit:
					(n as CanvasItem).self_modulate.a = 0.0
			var centre := CenterContainer.new()
			centre.set_anchors_preset(Control.PRESET_FULL_RECT)
			centre.mouse_filter = Control.MOUSE_FILTER_IGNORE
			centre.add_child(_spinner(0.0))
			over.add_child(centre)
	return ""


## The control a state applies to: the one the component names (meta
## "target"), else the first control with a kit box, buttons first.
static func _target(c: Control) -> Control:
	if c.has_meta("target"):
		return c.get_meta("target")
	var all: Array = [c] + c.find_children("*", "Control", true, false)
	for n: Control in all:
		if n is BaseButton and RbBox.of(n) != null and RbBox.of(n).visible and n.name != "Tap":
			return n
	for n: Control in all:
		if RbBox.of(n) != null and RbBox.of(n).visible:
			return n
	return c


## `c` on a parchment panel, the ground the parchment faces are made for.
static func _on_parchment(c: Control) -> Control:
	var p := UI.panel("parchment")
	p.add_child(c)
	p.set_meta("target", _target(c))
	return p


static func _panel(look: String, words: String) -> PanelContainer:
	var p := UI.panel(look)
	p.custom_minimum_size = Vector2(UI.px(150), UI.px(64))
	p.add_child(UI.label(words, 15, true))
	return p


## The loading mark: one sprite, turned `degrees`.
static func _spinner(degrees: float) -> Control:
	var holder := Control.new()
	holder.custom_minimum_size = Vector2.ONE * UI.px(24)
	holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var mark := TextureRect.new()
	var ring := Art.overlay(Art.OVERLAYS["Ld"])
	mark.texture = ring if ring != null else Icons.texture("generalui/timer")
	mark.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	mark.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	mark.size = Vector2.ONE * UI.px(24)
	mark.pivot_offset = mark.size * 0.5
	mark.rotation_degrees = degrees
	holder.add_child(mark)
	return holder


# --- Motion strips --------------------------------------------------------


## A motion as two strips of five frames, full and reduced: each frame is
## its own copy of what `make` builds, `start` run on it once it is laid
## out, and its new tweens held at 0, 1/4, 1/2, 3/4 and the whole of `ms`.
## Records the component's RM pair. `wide`: one frame a line; `loose`: each
## frame on a stage of its own size, out of a container, so a slide travels.
static func _strip(id: String, make: Callable, start: Callable, ms: float, wide := false,
		loose := false, halves: Array[bool] = [false, true], shrink := 1.0) -> Array:
	_pending.append("%s:RM" % id)
	var out := []
	for reduced: bool in halves:
		out.append(_caption("%s: %s" % [id, "reduced motion" if reduced else "full motion"]))
		var row: Container = _flow()
		if wide:
			row = VBoxContainer.new()
		for k: int in 5:
			var at := ms * k / 4.0
			var was := Settings.reduced_motion
			Settings.reduced_motion = reduced
			var c: Control = make.call()
			Settings.reduced_motion = was
			var holder: Control = c
			if shrink < 1.0:
				# Out of a container a node keeps its scale: the frame is drawn
				# at `shrink` of its size, on a stage of that size.
				holder = Control.new()
				holder.add_child(c)
				c.scale = Vector2.ONE * shrink
				holder.custom_minimum_size = c.get_combined_minimum_size() * shrink
			elif loose:
				holder = Control.new()
				holder.clip_contents = true
				holder.add_child(c)
				holder.size_flags_horizontal = Control.SIZE_EXPAND_FILL
				# Out of a container, `c` takes the holder's width and its own
				# height at that width; the holder then keeps that height.
				holder.resized.connect(func() -> void:
					if holder.size.x < 1.0:
						return
					c.size = Vector2(holder.size.x, 0.0)
					holder.custom_minimum_size.y = c.size.y)
			var cell := VBoxContainer.new()
			cell.add_theme_constant_override("separation", UI.px(2))
			cell.add_child(holder)
			cell.add_child(_caption("%d ms" % roundi(at)))
			if wide:
				cell.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			row.add_child(cell)
			_posts.append(func() -> void:
				var tree := Engine.get_main_loop() as SceneTree
				var before := tree.get_processed_tweens()
				Settings.reduced_motion = reduced
				start.call(c)
				Settings.reduced_motion = was
				for tw: Tween in tree.get_processed_tweens():
					if tw not in before and tw.is_valid():
						tw.pause()
						tw.custom_step(at / 1000.0))
		out.append(row)
	return out


## K40, built from today's parts until its motion sprites come (report.md
## step 7): anticipation, burst, reveal, coin flight and counter roll, full;
## reduced, the reward at rest.
static func _sequence() -> Array:
	_pending.append("K40:RM")
	var tile := func() -> Control:
		return KitCards.reward("resources/starlight", "+2,310", Strings.t("RESULT_STARLIGHT"), "gold")
	var full := _flow()
	var beat := func(words: String, c: Control) -> void:
		var v := VBoxContainer.new()
		v.add_theme_constant_override("separation", UI.px(2))
		v.add_child(c)
		v.add_child(_caption(words))
		full.add_child(v)
	var a: Control = tile.call()
	a.modulate.a = 0.5
	a.set_meta("rest", true)
	_posts.append(func() -> void:
		a.pivot_offset = a.size * 0.5
		a.scale = Vector2.ONE * 0.92)
	beat.call("anticipation", a)
	var burst := UI.panel("night_rays")
	burst.custom_minimum_size = Vector2.ONE * UI.px(96)
	beat.call("burst", burst)
	var reveal := UI.panel("night_rays")
	reveal.add_child(tile.call())
	beat.call("reveal", reveal)
	var flight := Control.new()
	flight.custom_minimum_size = Vector2(UI.px(140), UI.px(96))
	for k: int in 4:
		var coin := TextureRect.new()
		coin.texture = Icons.texture("resources/starlight")
		coin.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		coin.size = Vector2.ONE * UI.px(22)
		var u := k / 3.0
		coin.position = Vector2(UI.px(8) + u * UI.px(100), UI.px(64) - sin(u * PI) * UI.px(56))
		coin.modulate.a = 0.4 + 0.2 * k
		flight.add_child(coin)
	beat.call("coin flight", flight)
	var roll := UI.label("1,160", 30)
	roll.theme_type_variation = "Display"
	beat.call("counter roll", roll)
	var still := _flow()
	var rest := VBoxContainer.new()
	rest.add_child(tile.call())
	rest.add_child(_caption("the reward at rest, no flight or roll"))
	still.add_child(rest)
	return [_caption("K40: full motion, stand-in from today's parts"), full, _caption("K40: reduced motion"), still]
