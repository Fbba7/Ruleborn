extends SceneTree
## The eighteen ruleborn side by side to scale in their idle, in §21.6's order
## (three to a school), saved as a still (tools/render/shoot.sh). GROUP picks
## another group from the manifest (sage, visitor, paradox, anomaly, law,
## wildlife); SILHOUETTE=1 draws them black for the squint test (§21.6);
## GUARD=1 dresses them as guards; FORM picks a form (hush, spark, echo).


func _initialize() -> void:
	var w := 1600
	var h := 520
	var vp := SubViewport.new()
	vp.size = Vector2i(w, h)
	vp.own_world_3d = true
	vp.msaa_3d = Viewport.MSAA_4X
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(vp)
	var world := Node3D.new()
	vp.add_child(world)
	var look := WorldLook.new(world)
	look.set_hour(12)
	var group := OS.get_environment("GROUP") if OS.get_environment("GROUP") != "" else "ruleborn"
	var order := ["featherkin", "skyskipper", "rambler", "glassgolem", "quarryback", "prismmite", "tidewalker",
		"hourkeeper", "stillwatch", "emberling", "stormhound", "sparkwright", "mossbear", "bloomling", "rootrunner",
		"echoplate", "lanternwisp", "soulmender"]
	var kinds: Array[String] = []
	if group == "ruleborn":
		for k: String in order:
			if CreatureModel.manifest().has(k):
				kinds.append(k)
	else:
		for k: String in CreatureModel.kinds(group):
			kinds.append(k)
	# Two rows when there are many, the second a row's height below the first.
	var per_row := kinds.size() if kinds.size() <= 10 else ceili(kinds.size() / 2.0)
	var tallest := 0.0
	for k: String in kinds:
		tallest = maxf(tallest, float((CreatureModel.manifest()[k] as Dictionary).get("height", 1.0)))
	var rows: Array[float] = [0.0, 0.0]
	var models: Array[CreatureModel] = []
	var row_of: Array[int] = []
	for i in kinds.size():
		var c := CreatureModel.make(StringName(kinds[i]))
		var r := maxf(0.25, float(c.info.get("radius", 0.3)))
		var row := 0 if i < per_row else 1
		rows[row] += r
		world.add_child(c)
		c.place(Vector3(rows[row], -float(row) * tallest * 1.3, 0), Vector3(0.35, 0, 1))
		rows[row] += r + 0.12
		models.append(c)
		row_of.append(row)
		c.set_guard(OS.get_environment("GUARD") == "1")
		if OS.get_environment("FORM") != "":
			c.set_form(StringName(OS.get_environment("FORM")))
		if OS.get_environment("SILHOUETTE") == "1":
			c.material().set_shader_parameter("flash", Color(0.0, 0.0, 0.0, 1.0))
			c.material().set_shader_parameter("rim_strength", 0.0)
			c.material().set_shader_parameter("lift", 0.0)
	var span := maxf(rows[0], rows[1])
	for i in models.size():
		models[i].position.x -= rows[row_of[i]] * 0.5
	var two := rows[1] > 0.0
	var cam := Camera3D.new()
	world.add_child(cam)
	cam.projection = Camera3D.PROJECTION_ORTHOGONAL
	cam.size = maxf(span * float(h) / float(w) * 1.06, tallest * (2.9 if two else 1.35))
	var target := Vector3(0, tallest * (0.05 if two else 0.55), 0)
	var from := target + Vector3(0, 0.7, 6.0)
	cam.transform = Transform3D(Basis.looking_at(target - from, Vector3.UP), from)
	for i in 3:
		await process_frame
	for c: CreatureModel in models:
		c.player().seek(0.8, true)
	for i in 3:
		await process_frame
	var img := vp.get_texture().get_image()
	img.save_png(OS.get_environment("SHOT"))
	print("saved ", img.get_size(), " ", kinds.size(), " kinds")
	quit()
