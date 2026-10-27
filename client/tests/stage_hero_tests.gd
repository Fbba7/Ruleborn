class_name StageHeroTests
extends RefCounted
## The character screens' 3D (§21.3, §21.6): every stand-in figure inside
## the character budget in every look, a kind's facts read from its key,
## the stage standing what it is asked to — the design's model where the
## export has the kind — and portraits cached and cut from what is drawn.

var check: Callable


func _init(c: Callable) -> void:
	check = c


func run() -> void:
	_budgets()
	_kinds()
	_stage()
	_portraits()


func _budgets() -> void:
	var over := []
	for k: String in StageHeroFigure.KINDS:
		for look: String in ["", "hush", "spark", "echo", "guard"]:
			var m := StageHeroSculpt.of(k, look)
			var tris := m.surface_get_array_len(0) / 3 if m != null else 0
			if tris == 0 or tris > 6000:
				over.append("%s/%s %d" % [k, look, tris])
	check.call("every character's figure, in each form and its guard form, stays within §21.3's 6,000 triangles, "
		+ "one draw call (21.3, 21.6)", over.is_empty(), ", ".join(over))


func _kinds() -> void:
	var ok := StageHeroFigure.key("Glass Golem") == "glass_golem" and StageHeroFigure.key("the_archivist") == "archivist" \
		and StageHeroFigure.school("bloomling") == "life" and is_equal_approx(StageHeroFigure.height("mossbear"), 1.4) \
		and is_equal_approx(StageHeroFigure.height("archivist"), 1.5) and StageHeroFigure.role("emberling") == "Breaker"
	check.call("a kind's school, role and height are §11.11's and §21.6's, read from the server's key (21.6)", ok)


func _stage() -> void:
	var stage := StageHero.new()
	stage.show_kinds(["skyskipper", "skyskipper", "skyskipper", "skyskipper"], ["hush", "spark", "echo", "guard"])
	var four := stage.figures.size() == 4 and stage.school == "motion" and stage.kinds[0] == "skyskipper"
	stage.show_kinds(["the_archivist", "the_tinkerer"], ["", "shadow"], "hall")
	var shaded := stage.figures[1].find_children("*", "MeshInstance3D", true, false).any(
		func(mi: MeshInstance3D) -> bool: return mi.material_override is StandardMaterial3D)
	var modelled: bool = stage.figures[0].get_meta("model", null) is CreatureModel
	var hall := stage.figures.size() == 2 and stage.scenery.get_child_count() > 0 and stage.school == "spirit" \
		and modelled
	stage.act(1)
	var acting: bool = stage.get("_actions")[1] >= 0.0
	stage.cheer()
	var cheering: bool = (stage.get("_actions") as Array).all(func(a: float) -> bool: return a >= 0.0) \
		and (stage.figures[0].get_meta("model") as CreatureModel).clip == &"celebrate"
	stage.free()
	check.call("the hero stage stands a kind in its forms and guard form side by side, the Sages in their hall with a "
		+ "locked one in silhouette, a tap plays an action, and a success makes them celebrate (23.2)",
		four and shaded and hall and acting and cheering, "%s %s %s %s %s" % [four, shaded, hall, acting, cheering])


func _portraits() -> void:
	var a := Portrait.of("featherkin")
	var b := Portrait.of("featherkin")
	var c := Portrait.of("featherkin", "hush")
	var drawn := Image.create_empty(512, 512, false, Image.FORMAT_RGBA8)
	drawn.fill_rect(Rect2i(200, 100, 100, 300), Color.WHITE)
	drawn.fill_rect(Rect2i(10, 10, 2, 2), Color.WHITE)
	var cut := PortraitStudio.crop(drawn)
	check.call("a portrait is made once a kind and look and shared, cut square from the top of what is drawn, a "
		+ "stray glint left out (21.3)", a == b and a != c and a.get_width() == 256 and cut.get_width() == 256
		and cut.get_pixel(128, 40).a > 0.5 and cut.get_pixel(4, 4).a == 0.0)
	# A bust: a figure with a head (a round top) on a body, and a staff held
	# out to the right; the bust is centred on the head, not the staff.
	var figure := Image.create_empty(512, 512, false, Image.FORMAT_RGBA8)
	figure.fill_rect(Rect2i(180, 80, 80, 80), Color.WHITE)
	figure.fill_rect(Rect2i(160, 160, 120, 260), Color.WHITE)
	figure.fill_rect(Rect2i(380, 60, 12, 380), Color.WHITE)
	var head := PortraitStudio.crop_bust(figure)
	var bust := Portrait.bust("featherkin")
	var member := Portrait.of_member({"role": "Scout", "form": "hush"})
	check.call("a portrait for a round frame is head and shoulders, centred on the face and cached by kind and form, "
		+ "and a crew record finds its own (21.3, 21.8)",
		bust == Portrait.bust("featherkin") and bust != a and member == Portrait.bust("featherkin", "hush")
		and head.get_width() == 256 and head.get_pixel(128, 40).a > 0.5,
		"%s %s" % [head.get_pixel(128, 40), bust == a])
