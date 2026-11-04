class_name UiKitTests
extends RefCounted
## The interface kit (§21.8, §20.8): every material, gradient, type role and
## font the tokens name resolves; a dressed control keeps its own size and
## says what its words sit on; the three faces load with tabular figures
## where numbers change; every icon in the manifest loads; a button squashes
## when pressed and changes at once under reduced motion; and every control
## the kit makes meets §21.1's 48 points. Every material maps onto one of the
## kit's 35 skins, every skin's switch is off as shipped, a skin switched on
## draws from the atlas, and a piece the atlas lacks falls back to the
## code-drawn box (kit-spec.md sections 6.7 and 8.2).

## The baked fixture kit (tests/fixtures/ui_kit, baked by tools/ui_bake from
## its own sources): the gold button's skin, the tertiary's parchment face
## and a tinted disc, normal and high contrast.
const FIXTURE := "res://tests/fixtures/ui_kit/kit.json"
## The catalogue sheet (kit-spec.md section 6.4).
const Catalogue := preload("res://tests/shots/ui_kit_catalogue.gd")
## The components whose baked faces are skins, and those skins' faces: once a
## skin has art, each of the component's baked states is a piece of it.
const SKINS_OF := {
	"K01": ["button_primary__box", "button_secondary__box", "button_tertiary__box",
		"button_tertiary__parchment", "button_danger__box"],
	"K02": ["button_primary__gold_round"],
	"K28": ["success__box"],
	"K29": ["success__box"],
}

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
	_skins()
	await _switch()
	await _fixture()
	_pages()
	_skies()
	await _catalogue()


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


func _skins() -> void:
	var bad := []
	for m: String in Tokens.materials():
		if KitSkin.skin(m) == "" and m not in KitSkin.BACKDROP:
			bad.append("%s maps onto no skin" % m)
	var shipped: Variant = JSON.parse_string(FileAccess.get_file_as_string(KitSkin.FAMILIES_FILE))
	var switches: Dictionary = shipped if shipped is Dictionary else {}
	if KitSkin.SKINS.size() != 35:
		bad.append("%d skins, not 35" % KitSkin.SKINS.size())
	for k: String in KitSkin.SKINS:
		if not switches.has(k):
			bad.append("no switch for %s" % k)
	for k: String in switches:
		if not KitSkin.SKINS.has(k):
			bad.append("a switch for no skin, %s" % k)
		elif switches[k] != false:
			bad.append("%s is switched on" % k)
	check.call("every material maps onto one of the kit's 35 skins or the backdrop, and kit_families.json holds "
			+ "one switch per skin, every one off (kit-spec.md sections 6.7, 8.2)", bad.is_empty(), "; ".join(bad))


func _switch() -> void:
	var bad := []
	KitSkin.reset()
	var screen := Control.new()
	screen.size = Vector2(1080, 2340)
	tree.root.add_child(screen)
	# Off, as shipped: the code-drawn box, and no face from the atlas.
	var off := PanelContainer.new()
	off.custom_minimum_size = Vector2(300, 200)
	screen.add_child(off)
	var off_box := KitSkin.panel(off, "card")
	if not off_box.piece().is_empty() or off_box.find_child("KitFace", true, false) != null:
		bad.append("a skin switched off draws from the atlas")
	if off_box.material == null or not off_box.material is ShaderMaterial:
		bad.append("a skin switched off lost the code-drawn box's shader")
	# On, with a small kit: the dark panel's box and the school disc.
	var img := Image.create(64, 64, false, Image.FORMAT_RGBA8)
	img.fill(Color.WHITE)
	var normal := ImageTexture.create_from_image(img)
	var high := ImageTexture.create_from_image(img)
	KitSkin.use({"format": 1, "family": "kit", "px_per_point": 6, "pieces": {
		"panel_dark__box__normal": {"x": 0, "y": 0, "w": 48, "h": 48, "slice": {"l": 12, "t": 12, "r": 12, "b": 12},
			"tint": false},
		"disc_school__box__normal": {"x": 48, "y": 0, "w": 16, "h": 16, "slice": null, "tint": true},
	}}, normal, high)
	KitSkin.switch("panel_dark", true)
	KitSkin.switch("disc_school", true)
	KitSkin.switch("button_primary", true)
	var on := PanelContainer.new()
	on.custom_minimum_size = Vector2(300, 200)
	screen.add_child(on)
	var on_box := KitSkin.panel(on, "card")
	var disc := PanelContainer.new()
	disc.custom_minimum_size = Vector2(96, 96)
	screen.add_child(disc)
	var disc_box := UI.dress(disc, "portrait_motion")
	# A skin on whose piece the atlas lacks: a disabled dark button, and the
	# gold, which this kit has no piece for at all.
	var lame := Button.new()
	lame.text = "Wait"
	lame.disabled = true
	screen.add_child(lame)
	var lame_box := KitSkin.button(lame, "card")
	var gold := Button.new()
	gold.text = "Play"
	screen.add_child(gold)
	var gold_box := KitSkin.button(gold, "gold")
	for i: int in 2:
		await tree.process_frame
	if on_box.piece().is_empty() or on_box.find_child("KitFace", true, false) == null:
		bad.append("the dark panel switched on does not draw from the atlas")
	if not bool(disc_box.piece().get("tint", false)):
		bad.append("a school's portrait does not take the neutral, tinted disc")
	if not off_box.piece().is_empty() or not off_box.find_child("KitFace", true, false) == null:
		bad.append("switching a skin on changed a box dressed before it")
	if not lame_box.piece().is_empty() or "panel_dark__card__disabled" not in KitSkin.missing:
		bad.append("a missing disabled face is not drawn by the code-drawn box and logged")
	if not gold_box.piece().is_empty() or "button_primary__gold__normal" not in KitSkin.missing:
		bad.append("a skin the atlas has no piece for is not drawn by the code-drawn box and logged")
	if KitSkin.missing.count("button_primary__gold__normal") != 1:
		bad.append("a missing piece is logged more than once")
	Tokens.high_contrast = true
	if KitSkin.atlas() != high:
		bad.append("high contrast does not take the _hc atlas")
	Tokens.high_contrast = false
	if KitSkin.atlas() != normal or not is_equal_approx(KitSkin.scale(), UI.PX_PER_POINT / 6.0):
		bad.append("the atlas or its scale is wrong")
	screen.queue_free()
	KitSkin.reset()
	await tree.process_frame
	check.call("a skin switched on draws its materials from the kit's atlas (its _hc twin in high contrast) and one "
			+ "switched off from the code-drawn box; a piece the atlas lacks falls back to the code-drawn box and "
			+ "is logged once (kit-spec.md section 6.7)", bad.is_empty(), "; ".join(bad))


## The colour at the middle of piece `p` in the page it is cut from.
static func _middle(p: Dictionary) -> Color:
	var tex := KitSkin.texture(p)
	if tex == null:
		return Color(0, 0, 0, 0)
	var at := Vector2i(int(p["x"]) + int(p["w"]) / 2, int(p["y"]) + int(p["h"]) / 2)
	return tex.get_image().get_pixelv(at)


func _fixture() -> void:
	var bad := []
	KitSkin.reset()
	if not KitSkin.use_files(FIXTURE):
		check.call("the baked fixture kit loads", false, FIXTURE)
		return
	var pieces: Dictionary = (JSON.parse_string(FileAccess.get_file_as_string(FIXTURE)) as Dictionary)["pieces"]
	for k: String in ["button_primary", "button_tertiary", "button_danger"]:
		KitSkin.switch(k, true)
	var screen := VBoxContainer.new()
	screen.size = Vector2(1080, 2340)
	tree.root.add_child(screen)
	var play := Button.new()
	play.text = "Play"
	screen.add_child(play)
	var play_box := KitSkin.button(play, "gold")
	var wait := Button.new()
	wait.text = "Wait"
	wait.disabled = true
	screen.add_child(wait)
	var wait_box := KitSkin.button(wait, "gold")
	# The tertiary on parchment takes its parchment face; on the dark card
	# the fixture has no face for it, and the code-drawn box draws it.
	var sheet := PanelContainer.new()
	screen.add_child(sheet)
	KitSkin.panel(sheet, "parchment")
	var rows := VBoxContainer.new()
	sheet.add_child(rows)
	var later := Button.new()
	later.text = "Later"
	rows.add_child(later)
	var later_box := KitSkin.button(later, "ghost")
	var gone := Button.new()
	gone.text = "Gone"
	gone.disabled = true
	rows.add_child(gone)
	var gone_box := KitSkin.button(gone, "ghost")
	var card := PanelContainer.new()
	screen.add_child(card)
	KitSkin.panel(card, "card")
	var skip := Button.new()
	skip.text = "Skip"
	card.add_child(skip)
	var skip_box := KitSkin.button(skip, "ghost")
	var leave := Button.new()
	leave.text = "Quit"
	screen.add_child(leave)
	var leave_box := KitSkin.button(leave, "red")
	for i: int in 2:
		await tree.process_frame
	var p := play_box.piece()
	if p != pieces["button_primary__box__normal"] or play_box.find_child("KitFace", true, false) == null:
		bad.append("the gold button switched on does not take the fixture's normal face")
	elif not _middle(p).is_equal_approx(Color("#E0B040")):
		bad.append("the gold's face is %s in the normal atlas, not #E0B040" % _middle(p).to_html(false))
	var drawn := false
	for sb: Variant in play_box._faces.values():
		drawn = drawn or (sb is StyleBoxTexture and (sb as StyleBoxTexture).texture == KitSkin.texture(p))
	if not drawn:
		bad.append("the gold's face is not drawn from the normal atlas")
	if wait_box.piece() != pieces["button_primary__box__disabled"]:
		bad.append("a disabled gold button does not take the disabled face")
	if later_box.piece() != pieces["button_tertiary__parchment__normal"]:
		bad.append("the tertiary on parchment does not take button_tertiary__parchment__normal")
	if not gone_box.piece().is_empty() or "button_tertiary__parchment__disabled" not in KitSkin.missing:
		bad.append("a missing parchment face is not drawn by the code-drawn box and logged")
	if not skip_box.piece().is_empty() or "button_tertiary__ghost__normal" not in KitSkin.missing:
		bad.append("the tertiary off parchment takes a face the fixture lacks, or is not logged")
	if not leave_box.piece().is_empty() or "button_danger__red__normal" not in KitSkin.missing:
		bad.append("a skin on whose pieces the atlas lacks is not drawn by the code-drawn box and logged")
	var normal := KitSkin.texture(p)
	Tokens.high_contrast = true
	play_box.queue_redraw()
	play_box._redraw()
	await tree.process_frame
	if KitSkin.texture(p) == normal or not _middle(p).is_equal_approx(Color("#000000")):
		bad.append("high contrast does not take the fixture's _hc twin (%s)" % _middle(p).to_html(false))
	drawn = false
	for sb: Variant in play_box._faces.values():
		drawn = drawn or (sb is StyleBoxTexture and (sb as StyleBoxTexture).texture == KitSkin.texture(p))
	if not drawn:
		bad.append("the gold's face is not drawn from the _hc atlas in high contrast")
	Tokens.high_contrast = false
	screen.queue_free()
	KitSkin.reset()
	await tree.process_frame
	check.call("a skin switched on draws from the baked fixture's atlas, normal and high contrast; the tertiary on "
			+ "parchment takes its parchment face (AIA-R9); a piece the atlas lacks falls back to the code-drawn "
			+ "box and is logged (kit-spec.md sections 4.1, 6.7)", bad.is_empty(), "; ".join(bad))


func _pages() -> void:
	var bad := []
	KitSkin.reset()
	var tex := func(c: Color) -> ImageTexture:
		var img := Image.create(16, 16, false, Image.FORMAT_RGBA8)
		img.fill(c)
		return ImageTexture.create_from_image(img)
	var one: ImageTexture = tex.call(Color.WHITE)
	var two: ImageTexture = tex.call(Color.RED)
	var two_hc: ImageTexture = tex.call(Color.BLACK)
	var pieces := {
		"badge__box__normal": {"x": 0, "y": 0, "w": 8, "h": 8, "slice": null, "tint": false, "page": 2},
		"badge__box__pressed": {"x": 0, "y": 0, "w": 8, "h": 8, "slice": null, "tint": false, "page": 3},
	}
	KitSkin.use({"format": 1, "family": "kit", "px_per_point": 6, "pieces": pieces}, one, one, [[two, two_hc]])
	KitSkin.switch("badge", true)
	var p := KitSkin.piece("badge")
	if p != pieces["badge__box__normal"] or KitSkin.texture(p) != two:
		bad.append("a piece on page 2 is not cut from page 2")
	Tokens.high_contrast = true
	if KitSkin.texture(p) != two_hc:
		bad.append("a piece on page 2 does not take page 2's _hc twin in high contrast")
	Tokens.high_contrast = false
	if not KitSkin.piece("badge", "pressed").is_empty() or "badge__badge__pressed" not in KitSkin.missing:
		bad.append("a piece on a page the atlas lacks is not drawn by the code-drawn box and logged")
	KitSkin.reset()
	check.call("a piece names the atlas page it is cut from (kit-spec.md section 6.6, AIA-R12)", bad.is_empty(),
			"; ".join(bad))


func _skies() -> void:
	var day := Tokens.sky("day")
	var ok := day == [Tokens.color("sky_top"), Tokens.color("sky_bottom")] \
		and Tokens.sky("dusk") == [Color("#6A4FC9"), Color("#F29C7B")] \
		and Tokens.sky("night") == [Color("#1A1433"), Color("#3A2B6B")]
	check.call("§21.2's day, dusk and night skies are tokens, top and bottom", ok,
		"day %s, dusk %s, night %s" % [day, Tokens.sky("dusk"), Tokens.sky("night")])


## Every (component, state) pair of kit-spec.md section 4 has a place on a
## catalogue page, no part is taller than a page, and every baked state of a
## skin with art is a piece inside both the normal and the high-contrast
## atlas, the catalogue drawing none from the code-drawn box (section 6.4).
func _catalogue() -> void:
	var bad := []
	var spec_file := ProjectSettings.globalize_path("res://") + "/../docs/art/ui-quality/kit-spec.md"
	var pairs := Catalogue.inventory(FileAccess.get_file_as_string(spec_file))
	if pairs.size() < 100:
		bad.append("section 4 reads as %d pairs" % pairs.size())
	var on := Catalogue.art_on()
	await Catalogue.lay_out(tree, func(_n: int, _screen: Control) -> void: pass)
	for pair: String in pairs:
		if not Catalogue.placed.has(pair):
			bad.append("%s has no place" % pair)
	for title: String in Catalogue.tall:
		bad.append("%s is taller than a page" % title)
	for lost: String in KitSkin.missing:
		bad.append("the catalogue drew %s from the code-drawn box" % lost)
	var kit: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(Catalogue.MANIFEST))
	var pieces: Dictionary = kit.get("pieces", {})
	var atlas: Dictionary = kit.get("atlas", {})
	for look: String in ["normal", "high_contrast"]:
		var img := Image.load_from_file(Catalogue.MANIFEST.get_base_dir() + "/" + str(atlas.get(look, "")))
		if img == null or img.get_size() != Vector2i(int(atlas.get("width", 0)), int(atlas.get("height", 0))):
			bad.append("the %s atlas is not the manifest's size" % look)
			continue
		for key: String in pieces:
			var p: Dictionary = pieces[key]
			var r := Rect2i(int(p["x"]), int(p["y"]), int(p["w"]), int(p["h"]))
			if not Rect2i(Vector2i.ZERO, img.get_size()).encloses(r) or r.size.x <= 0 or r.size.y <= 0:
				bad.append("%s lies outside the %s atlas" % [key, look])
	var mapped := []
	for id: String in SKINS_OF:
		for face: String in SKINS_OF[id]:
			var skin := face.get_slice("__", 0)
			mapped.append(skin)
			if skin not in on:
				continue
			for pair: String in pairs:
				var state := pair.get_slice(":", 1)
				if pair.begins_with(id + ":") and Catalogue.FACES.has(state) \
						and not pieces.has("%s__%s" % [face, Catalogue.FACES[state]]):
					bad.append("%s has no piece %s__%s" % [pair, face, Catalogue.FACES[state]])
	for skin: String in on:
		if skin not in mapped:
			bad.append("%s has art but no component in SKINS_OF" % skin)
	KitSkin.reset()
	check.call("every (component, state) pair of kit-spec.md section 4 has a place on the catalogue sheet, and "
			+ "each baked state of a skin with art is a piece in both atlases (section 6.4)", bad.is_empty(),
			"; ".join(bad.slice(0, 12)))
