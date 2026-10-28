class_name UiKitTests
extends RefCounted
## The interface kit (§21.8, §20.8): every material, gradient, type role and
## font the tokens name resolves; a dressed control keeps its own size and
## says what its words sit on; the three faces load with tabular figures
## where numbers change; every icon in the manifest loads; a button squashes
## when pressed and changes at once under reduced motion; and every control
## the kit makes meets §21.1's 48 points.

var tree: SceneTree
var check: Callable


func _init(t: SceneTree, c: Callable) -> void:
	tree = t
	check = c


func run() -> void:
	_tokens()
	_fonts()
	await _boxes()
	await _press()
	_motion()
	_icons()
	await _tab_words()
	await _small_disc()
	await _pieces()


func _tokens() -> void:
	var bad := []
	for hc: bool in [false, true]:
		Tokens.high_contrast = hc
		for m: String in Tokens.materials():
			var spec := Tokens.material(m)
			if Tokens.gradient(str(spec["fill"])).get_point_count() < 2:
				bad.append("%s's fill" % m)
			if (spec["text_bg"] as Array).is_empty():
				bad.append("%s has no text_bg" % m)
			if hc and not m.begins_with("night") and m != "scrim" and float((spec["line"] as Array)[1]) < 3.0:
				bad.append("%s's outline in high contrast" % m)
		if hc and Tokens.color("text_on_night_2") != Tokens.color("text_on_night"):
			bad.append("secondary text is not raised to primary in high contrast")
	Tokens.high_contrast = false
	for role: String in Tokens.type_roles():
		if float(Tokens.type_role(role)["points"]) < Tokens.number("size", "smallest_points"):
			bad.append("type role %s is under 13 points" % role)
	check.call("every material, gradient and type role the kit names resolves, none under 13 points, and high "
			+ "contrast makes 3-point outlines and raises secondary text to primary (§21.8, §20.8)",
		bad.is_empty(), "; ".join(bad))


func _fonts() -> void:
	var ts := TextServerManager.get_primary_interface()
	var ui := Tokens.font("ui", 900, true) as FontVariation
	var faces := [Tokens.font("ui", 600), Tokens.font("title"), Tokens.font("display")].all(
		func(f: Font) -> bool: return f is FontVariation and (f as FontVariation).base_font is FontFile)
	var heaviest := int(ui.variation_opentype.get(ts.name_to_tag("wght"), 0)) == 800
	var tabular := int(ui.opentype_features.get(ts.name_to_tag("tnum"), 0)) == 1
	# Tabular figures: every digit the same width.
	var widths := {}
	for d: String in "0123456789":
		widths[ui.get_string_size(d, HORIZONTAL_ALIGNMENT_LEFT, -1, 48).x] = true
	var ledger := FileAccess.file_exists("res://ui/fonts/LEDGER.md") and ["manrope", "lilita_one", "marcellus"].all(
		func(f: String) -> bool: return FileAccess.file_exists("res://ui/fonts/%s/OFL.txt" % f))
	check.call("the three faces load (Manrope, Marcellus, Lilita One), 900 is drawn at 800, numbers that change "
			+ "have tabular figures, and each font has its OFL licence in the ledger (§21.8, §21.11)",
		faces and heaviest and tabular and widths.size() == 1 and ledger,
		"faces %s, 800 %s, tnum %s %s, ledger %s" % [faces, heaviest, tabular, widths.keys(), ledger])


func _boxes() -> void:
	var screen := Control.new()
	tree.root.add_child(screen)
	var column := UI.frame(screen)
	var card := UI.plate(UI.label("words"))
	column.add_child(card)
	var main := UI.button("go", func() -> void: pass, true)
	column.add_child(main)
	var red := UI.button("out", func() -> void: pass, false, Palette.ALARM)
	column.add_child(red)
	await tree.process_frame
	await tree.process_frame
	var box := RbBox.of(card)
	var kept := card.get_child_count() == 1 and box != null and box.get_parent() == card
	var drawn := box != null and box.quad().size.x > card.size.x and is_equal_approx(
		(box.material as ShaderMaterial).get_shader_parameter("box_size").x, card.size.x)
	var said: bool = card.get_meta("text_bg", []) == Tokens.material("card")["text_bg"] \
		and main.get_meta("rb_material", "") == "gold" and red.get_meta("rb_material", "") == "red"
	var sized := [main, red].all(func(b: Button) -> bool:
		return minf(b.size.x, b.size.y) >= UI.CONTROL_POINTS * UI.PX_PER_POINT - 0.5)
	# A script that dresses a kit control in its own fill wins: the box steps aside.
	var own := StyleBoxFlat.new()
	own.bg_color = Color.WHITE
	card.add_theme_stylebox_override("panel", own)
	var aside := box._flat() == own
	screen.queue_free()
	await tree.process_frame
	check.call("a dressed control keeps its own children and size, draws its material past its edges, says what "
			+ "its words sit on, meets 48 points, and gives way to a script's own fill (§21.8, §21.1)",
		kept and drawn and said and sized and aside, "%s %s %s %s %s" % [kept, drawn, said, sized, aside])


func _press() -> void:
	var b := UI.button("press", func() -> void: pass)
	tree.root.add_child(b)
	await tree.process_frame
	Settings.reduced_motion = true
	Motion.press(b, true)
	var at_once := RbBox.of(b).press == 1.0 and b.scale == Vector2.ONE
	Motion.press(b, false)
	Settings.reduced_motion = false
	Motion.press(b, true)
	await tree.create_timer(0.3).timeout
	var squashed := b.scale.x < 1.0 and b.scale.x >= Tokens.number("motion", "press_squash") - 0.001
	Motion.press(b, false)
	await tree.create_timer(0.3).timeout
	var back := b.scale.is_equal_approx(Vector2.ONE) and is_zero_approx(RbBox.of(b).press)
	b.queue_free()
	var bounded := Tokens.number("motion", "press_ms") <= Tokens.number("motion", "longest_ms") \
		and Tokens.number("motion", "pop_ms") <= Tokens.number("motion", "longest_ms")
	check.call("a pressed button squashes slightly and sinks onto its drop within 250 ms, easing out, and back; "
			+ "under reduced motion the change is immediate (§21.8, §20.8)", at_once and squashed and back and bounded,
		"%s %s %s %s" % [at_once, squashed, back, bounded])


func _motion() -> void:
	var bad := []
	for name: String in ["fade_ms", "rise_ms", "pop_ms", "sheet_ms", "press_ms", "screen_fade_ms", "bar_fill_ms"]:
		var seconds := Motion._ms(name)
		if seconds < 0.15 - 0.0001 or seconds > 0.25 + 0.0001:
			bad.append("%s %.0f ms" % [name, seconds * 1000.0])
	check.call("every interface movement the kit makes takes 150 to 250 ms (§21.8), a bar's fill included",
		bad.is_empty(), "; ".join(bad))


func _icons() -> void:
	var missing := []
	for name: String in Icons.names():
		if not ResourceLoader.exists(str(Icons._paths[name])):
			missing.append(name)
	var known := Icons.has("resources/starlight") and Icons.has("hud/home") and Icons.has("schools/matter") \
		and Icons.texture("schools/matter") != null
	check.call("every icon in the manifest exports from the design and loads, the six school marks among them "
			+ "(§21.8)", missing.is_empty() and known and Icons.names().size() > 300,
		"%d missing %s, known %s" % [missing.size(), missing.slice(0, 5), known])


func _tab_words() -> void:
	var bad := []
	var was := Settings.text_scale
	var locale := TranslationServer.get_locale()
	for case: Array in [[100, "en"], [150, "en"], [200, "en"], [100, "de"], [150, "pt_BR"], [200, "de"]]:
		var scale: int = case[0]
		Strings.set_locale(str(case[1]))
		Settings.text_scale = scale
		var screen := Control.new()
		screen.size = Vector2(1080, 2340)
		tree.root.add_child(screen)
		var column := UI.frame(screen)
		column.add_child(UI.grow())
		var tabs := KitTabs.make("friends", {"heist": 4})
		column.add_child(tabs)
		for i: int in 4:
			await tree.process_frame
		for id: String in tabs.buttons:
			var b: Button = tabs.buttons[id]
			var r := b.get_global_rect()
			if r.position.x < -0.5 or r.end.x > screen.size.x + 0.5:
				bad.append("%d%% %s outside the screen" % [scale, id])
			var l: Label = tabs._labels[id]
			if l.is_visible_in_tree() and tabs._need(l) > l.size.x + 1.0:
				bad.append("%d%% %s cut (%.0f in %.0f)" % [scale, id, tabs._need(l), l.size.x])
			if scale == 100 and case[1] == "en" and not l.is_visible_in_tree():
				bad.append("100%% %s hidden" % id)
		var chosen: Label = tabs._labels["friends"]
		if not chosen.is_visible_in_tree():
			bad.append("%d%% %s the chosen tab's word hidden" % [scale, case[1]])
		elif chosen.get_theme_font_size("font_size") < mini(UI.text_px(15), UI.px(15) * 3 / 2):
			bad.append("%d%% %s the chosen tab's word under 150%%" % [scale, case[1]])
		screen.queue_free()
		await tree.process_frame
	Settings.text_scale = was
	Strings.set_locale(locale)
	check.call("the tab bar shows every name whole at 100% text, and at 150% and 200% each name whole or not at all, "
			+ "the chosen tab's kept at 150% or more, every tab on the screen, in English, German and Portuguese "
			+ "(§20.8, §21.8, §20.6)", bad.is_empty(), "; ".join(bad))


func _small_disc() -> void:
	var screen := Control.new()
	tree.root.add_child(screen)
	var action := KitControls.round_action("hud/crew", "Crew", func() -> void: pass, false, 48, "2", "leather", 36)
	screen.add_child(action)
	await tree.process_frame
	await tree.process_frame
	var b := action.find_children("*", "Button", true, false)[0] as Button
	var box := RbBox.of(b)
	var hit := minf(b.size.x, b.size.y) >= UI.px(UI.CONTROL_POINTS) - 0.5
	var drawn := box != null and is_equal_approx((box.material as ShaderMaterial).get_shader_parameter("box_size").x,
		float(UI.px(36)))
	var said := "hit %s %s, drawn %s" % [hit, b.size, drawn]
	screen.queue_free()
	await tree.process_frame
	check.call("a round action can draw its disc smaller than its hit area, which stays 48 points (§21.1)",
		hit and drawn, said)


## The pieces this wave added, each built on a phone-sized screen: every
## button they hold is 48 points or more (§21.1), every word 13 points or
## more (§21.8), and each sits inside the screen at 200% text (§20.8).
func _pieces() -> void:
	var bad := []
	var was := Settings.text_scale
	var picture := Icons.texture("screens/heist")
	for scale: int in [100, 200]:
		Settings.text_scale = scale
		var screen := Control.new()
		screen.size = Vector2(1080, 2340)
		tree.root.add_child(screen)
		var column := UI.frame(screen)
		var none := func() -> void: pass
		var pieces: Array[Control] = [
			KitHud.loot([["Room", "1,840"], ["Left", "2,600"]], 0.6, 0.8, "Load to 80%"),
			KitHud.sage(picture, "The Archivist", "Cast", none),
			KitHud.crew(picture, "Pip", 0.8, 1, none, "motion"),
			KitSocial.avatar(null, "KO", "Kofi", "Raiding", "alarm", none),
			KitSocial.feed_row(null, "LE", "Lea", "Challenge", "gold", "40 min", "Sent you her Lantern Vale.", picture,
				"Play", none),
			KitSocial.log_row(null, "MA", "Marta", "Held", "success", "2 h ago · held them 2:31", "Denied 3,300",
				"success", "Report", none),
			KitCards.album_card("laws/bounce", "Brittle stone", "matter", "common", "In Skyfield", "10"),
			KitCards.product(picture, "Emote", "Tip of the Hat", "120", none, "round_violet", 128.0, "resources/renown"),
			KitControls.tile("Medium", "Glass", "motion", none),
			KitStatus.hint("Tap crew, then ground · hold ground to sneak or run"),
			KitPanels.quest("screens/heist", "Rehearse your defence", 0, 1, "+30", "currencies/seasonstars", "Claim", none,
				"Swap", none),
			KitCards.law_disc("laws/sleepwalk", "Sleepwalk", "spirit"),
			KitCards.stat("crewroles/scout", "Stealth", "6", "+1", 6, 10, 1),
			KitControls.token("lawnotes/hush", "Hush form, hatched", true, false, none),
			KitHud.streak(["M", "T", "W", "T", "F", "S"], 4, 4, "alerts/seasonreward", "+100", ["kept", "today", "later"]),
			KitCards.build_card("resources/starlight", "Star Well", "Makes Starlight.", "resources/starlight", "1,200",
				"3 / 4", none),
			KitPanels.album("motion", "Motion", "Chapter I", "3 of 4", Control.new()),
		]
		for piece: Control in pieces:
			column.add_child(piece)
		for i: int in 3:
			await tree.process_frame
		var least := UI.px(UI.CONTROL_POINTS) - 0.5
		for piece: Control in pieces:
			for b: Node in piece.find_children("*", "Button", true, false):
				var r := (b as Button).get_global_rect()
				if minf(r.size.x, r.size.y) < least:
					bad.append("%d%% %s button %s" % [scale, piece.name, r.size])
			for l: Node in piece.find_children("*", "Label", true, false):
				if (l as Label).get_theme_font_size("font_size") < UI.text_px(13) - 0.5 and (l as Label).text != "":
					bad.append("%d%% %s '%s' small" % [scale, piece.name, (l as Label).text])
			# Its least width inside the phone's side margins: a piece that
			# asks for more pushes the whole column past the edge.
			var room := screen.size.x - 2.0 * UI.px(Tokens.number("size", "safe_side_points"))
			if piece.get_global_rect().end.x > screen.size.x + 0.5 or piece.get_combined_minimum_size().x > room + 0.5:
				bad.append("%d%% %s wider than the phone (%.0f)" % [scale, piece.name, piece.get_combined_minimum_size().x])
		screen.queue_free()
		await tree.process_frame
	Settings.text_scale = was
	check.call("this wave's pieces (loot, Sage, crew key, friend, feed and log rows, cards, tile, hint, quest, "
			+ "album) meet 48 points and 13 points and stay on the screen at 200% text (§21.1, §21.8, §20.8)",
		bad.is_empty(), "; ".join(bad))
