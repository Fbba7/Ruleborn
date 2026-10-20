extends SceneTree
## §21.7's movement signatures on T1's characters, as a still
## (tools/render/shoot.sh): one character a law walking in its gait
## (LawFxCreature), side by side, with its law's name under it. KIND picks the
## character (default the first ruleborn), SECONDS the moment (default 0.6),
## LAWS the laws (comma-separated).

func _initialize() -> void:
	_go()


func _go() -> void:
	var laws: Array = ["", "half_gravity", "frictionless", "heavy_ground", "brittle_stone", "tilt", "spores"]
	if OS.get_environment("LAWS") != "":
		laws = Array(OS.get_environment("LAWS").split(","))
	var w := 220 * laws.size()
	root.size = Vector2i(w, 360)
	var vp := SubViewport.new()
	vp.size = Vector2i(w, 360)
	vp.own_world_3d = true
	vp.msaa_3d = Viewport.MSAA_2X
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(vp)
	var world := Node3D.new()
	vp.add_child(world)
	var look := WorldLook.new(world)
	look.set_hour(12)
	var cam := Camera3D.new()
	cam.projection = Camera3D.PROJECTION_ORTHOGONAL
	cam.size = 2.6
	world.add_child(cam)
	cam.look_at_from_position(Vector3(0, 3.2, 8.0), Vector3(0, 0.55, 0), Vector3.UP)
	var ground := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(40, 8)
	ground.mesh = plane
	var gm := StandardMaterial3D.new()
	gm.albedo_color = Color("#CFE3A0")
	ground.material_override = gm
	world.add_child(ground)
	var kinds := CreatureModel.kinds("ruleborn")
	if kinds.is_empty():
		kinds = CreatureModel.kinds()
	var kind := OS.get_environment("KIND") if OS.get_environment("KIND") != "" else kinds[0]
	var seconds := float(OS.get_environment("SECONDS")) if OS.get_environment("SECONDS") != "" else 0.6
	var models: Array[CreatureModel] = []
	for k in laws.size():
		var c := CreatureModel.make(StringName(kind))
		world.add_child(c)
		var span := cam.size * float(w) / 360.0
		c.place(Vector3((k + 0.5) * span / laws.size() - span / 2.0, 0, 0), Vector3.RIGHT)
		c.play(&"walk")
		models.append(c)
		var tag := Label3D.new()
		tag.text = str(laws[k]).replace("_", " ") if laws[k] != "" else "no law"
		tag.font_size = 40
		tag.pixel_size = 0.005
		tag.modulate = Palette.INK
		tag.outline_modulate = Palette.PAPER
		tag.outline_size = 10
		tag.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		tag.position = c.position + Vector3(0, 1.05, 0)
		world.add_child(tag)
	for i in 3:
		await process_frame
	for k in laws.size():
		var which: Array = [] if laws[k] == "" else [laws[k]]
		LawFxCreature.apply(models[k], which, seconds, true)
		models[k].player().seek(seconds, true)
	for i in 2:
		await process_frame
	await RenderingServer.frame_post_draw
	vp.get_texture().get_image().save_png(OS.get_environment("SHOT"))
	print("wrote ", kind)
	quit()
