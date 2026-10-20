class_name StageHeroTests
extends RefCounted
## The character screens' 3D (§21.3, §21.6): every stand-in figure inside
## the character budget in every look, a kind's facts read from its key,
## the stage standing what it is asked to, and portraits cached.

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
	var shaded := (stage.figures[1].get_child(0) as MeshInstance3D).material_override is StandardMaterial3D
	var hall := stage.figures.size() == 2 and stage.scenery.get_child_count() > 0 and stage.school == "spirit"
	stage.act(1)
	var acting: bool = stage.get("_actions")[1] >= 0.0
	stage.free()
	check.call("the hero stage stands a kind in its forms and guard form side by side, the Sages in their hall with a "
		+ "locked one in silhouette, and a tap plays an action (23.2)", four and shaded and hall and acting,
		"%s %s %s %s" % [four, shaded, hall, acting])


func _portraits() -> void:
	var a := Portrait.of("featherkin")
	var b := Portrait.of("featherkin")
	var c := Portrait.of("featherkin", "hush")
	check.call("a portrait is made once a kind and look and shared (21.3)", a == b and a != c and a.get_width() == 256)
