extends SceneTree
## The eighteen ruleborn side by side to scale in their idle, in §21.6's order
## (three to a school), saved as a still (tools/render/shoot.sh). GROUP picks
## another group from the manifest (sage, visitor, paradox, anomaly, law,
## wildlife); SILHOUETTE=1 draws them black for the squint test (§21.6).


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
	var x := 0.0
	var models: Array[CreatureModel] = []
	for k: String in kinds:
		var c := CreatureModel.make(StringName(k))
		var r := maxf(0.25, float(c.info.get("radius", 0.3)))
		x += r
		world.add_child(c)
		c.place(Vector3(x, 0, 0), Vector3(0.35, 0, 1))
		x += r + 0.12
		models.append(c)
		if OS.get_environment("SILHOUETTE") == "1":
			c.material().set_shader_parameter("flash", Color(0.0, 0.0, 0.0, 1.0))
			c.material().set_shader_parameter("rim_strength", 0.0)
			c.material().set_shader_parameter("lift", 0.0)
	var span := x
	for c: CreatureModel in models:
		c.position.x -= span * 0.5
	var cam := Camera3D.new()
	world.add_child(cam)
	cam.projection = Camera3D.PROJECTION_ORTHOGONAL
	cam.size = maxf(span * float(h) / float(w) * 1.08, 1.7)
	var target := Vector3(0, cam.size * 0.4, 0)
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
