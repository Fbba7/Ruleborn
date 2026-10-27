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
