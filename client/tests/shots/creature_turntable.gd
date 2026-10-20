extends SceneTree
## One kind at three angles in its idle and once in an action pose, saved as a
## still (tools/render/shoot.sh). KIND is the kind (featherkin by default),
## CLIP the action (its ability), FORM a form (base, hush, spark, echo), GUARD=1
## the guard form, PORTRAIT=1 a close three-quarter view framed like the design's
## portraits (art/design/stills/portraits), EXPR an expression.


func _initialize() -> void:
	var w := 1200
	var h := 480
	var portrait := OS.get_environment("PORTRAIT") == "1"
	if portrait:
		w = 512
		h = 512
	var vp := SubViewport.new()
	vp.size = Vector2i(w, h)
	vp.own_world_3d = true
	vp.msaa_3d = Viewport.MSAA_4X
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(vp)
	var world := Node3D.new()
	vp.add_child(world)
	var look := WorldLook.new(world)
	look.set_hour(int(OS.get_environment("HOUR")) if OS.get_environment("HOUR") != "" else 12)
	var kind := StringName(OS.get_environment("KIND") if OS.get_environment("KIND") != "" else "featherkin")
	var action := StringName(OS.get_environment("CLIP") if OS.get_environment("CLIP") != "" else "ability")
	var form := StringName(OS.get_environment("FORM") if OS.get_environment("FORM") != "" else "base")
	var models: Array[CreatureModel] = []
	var n := 1 if portrait else 4
	var tall := 1.0
	for i in n:
		var c := CreatureModel.make(kind, 4 if portrait else 0)
		if c == null:
			quit(1)
			return
		tall = c.height()
		world.add_child(c)
		models.append(c)
		var facing: Array[Vector3] = [Vector3(0.55, 0, 1), Vector3(1, 0, 0), Vector3(-0.4, 0, -1), Vector3(0.7, 0, 1)]
		c.place(Vector3(0.0 if portrait else (float(i) - 1.5) * tall * 1.25, 0, 0), facing[0] if portrait else facing[i])
		c.set_form(form)
		c.set_guard(OS.get_environment("GUARD") == "1")
		if i == 3:
			c.play(action)
		elif OS.get_environment("EXPR") != "":
			c.set_expression(StringName(OS.get_environment("EXPR")))
	var cam := Camera3D.new()
	world.add_child(cam)
	if portrait:
		cam.fov = 26.0
		_aim(cam, Vector3(0, tall * 0.72, tall * 2.1), Vector3(0, tall * 0.6, 0))
	else:
		cam.fov = 24.0
		_aim(cam, Vector3(0, tall * 1.25, tall * 7.6), Vector3(0, tall * 0.48, 0))
	var ground := MeshInstance3D.new()
	var disc := CylinderMesh.new()
	disc.top_radius = tall * 4.0
	disc.bottom_radius = tall * 4.0
	disc.height = 0.02
	ground.mesh = disc
	var gm := StandardMaterial3D.new()
	gm.albedo_color = Color("#A9C77A")
	ground.material_override = gm
	ground.position.y = -0.011
	if OS.get_environment("GROUND") != "0" and not portrait:
		world.add_child(ground)
	var t := float(OS.get_environment("T")) if OS.get_environment("T") != "" else 0.9
	for i in 3:
		await process_frame
	for c: CreatureModel in models:
		c.player().seek(t if c.clip != action else t * 0.5, true)
	for i in 3:
		await process_frame
	var img := vp.get_texture().get_image()
	img.save_png(OS.get_environment("SHOT"))
	print("saved ", img.get_size(), " ", kind, " tris ", models[0].info.get("triangles"))
	quit()


func _aim(cam: Camera3D, from: Vector3, to: Vector3) -> void:
	cam.transform = Transform3D(Basis.looking_at(to - from, Vector3.UP), from)
