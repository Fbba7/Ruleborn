extends SceneTree
## Characters at the heist's scale (§21.1: "a closer follow camera at 50°
## showing about 12 tiles across"): a crew walking, running and carrying, one
## knocked out, guards in their sash and lantern, on a plain grid of 1 m tiles,
## saved as a still (tools/render/shoot.sh). T is the moment in the clips.
## KINDS (comma-separated) instead stands those kinds in rows of six facing
## the camera, playing CLIP (idle), all in the guard form with GUARD=1.

const CREW := [["featherkin", "walk"], ["rambler", "carry"], ["stormhound", "run"], ["bloomling", "ko"],
	["tidewalker", "wade"], ["emberling", "celebrate"], ["mossbear", "walk"], ["prismmite", "leap"]]
const GUARDS := [["quarryback", "idle"], ["stillwatch", "walk"], ["soulmender", "idle2"]]


func _initialize() -> void:
	var w := 540
	var h := 960
	var vp := SubViewport.new()
	vp.size = Vector2i(w, h)
	vp.own_world_3d = true
	vp.msaa_3d = Viewport.MSAA_2X
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(vp)
	var world := Node3D.new()
	vp.add_child(world)
	var look := WorldLook.new(world)
	look.set_hour(12)
	var ground := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(16, 24)
	ground.mesh = plane
	var gm := ShaderMaterial.new()
	gm.shader = load("res://world/toon.gdshader")
	ground.material_override = gm
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for x in 12:
		for z in 20:
			# The Heart's painted meadow (realm_palette.gd), mottled per tile, or
			# GROUND=sand for the old plain grid.
			var c := Color("#7FA462") if (x + z) % 2 == 0 else Color("#789C5C")
			if OS.get_environment("GROUND") == "sand":
				c = Color("#D9CDA8") if (x + z) % 2 == 0 else Color("#CFC29A")
			c = c.lightened(0.06 * sin(float(x * 7 + z * 13)))
			st.set_color(c)
			for p: Vector2 in [Vector2(0, 0), Vector2(1, 0), Vector2(1, 1), Vector2(0, 0), Vector2(1, 1), Vector2(0, 1)]:
				st.set_normal(Vector3.UP)
				st.add_vertex(Vector3(x - 6 + p.x, 0, z - 10 + p.y))
	ground.mesh = st.commit()
	world.add_child(ground)
	var models: Array[CreatureModel] = []
	var crew: Array = CREW
	var guards: Array = GUARDS
	if OS.get_environment("KINDS") != "":
		crew = []
		guards = []
		var clip_name := OS.get_environment("CLIP") if OS.get_environment("CLIP") != "" else "idle"
		var i := 0
		for k: String in OS.get_environment("KINDS").split(","):
			var c := CreatureModel.make(StringName(k))
			world.add_child(c)
			c.place(Vector3(-3.6 + (i % 6) * 1.5 - (i / 6) * 0.9, 0, -3.6 + (i / 6) * 2.2 + (i % 6) * 0.3), Vector3(1, 0, 1))
			c.set_guard(OS.get_environment("GUARD") == "1")
			c.play(StringName(clip_name))
			if not c.guard:
				c.set_display_scale(c.readable_scale())
			models.append(c)
			i += 1
	for i in crew.size():
		var c := CreatureModel.make(StringName(crew[i][0]))
		world.add_child(c)
		c.place(Vector3(-3.5 + (i % 4) * 2.2, 0, -2.5 + (i / 4) * 2.4), Vector3(0.6, 0, 1))
		c.play(StringName(crew[i][1]))
		# As the heist draws the crew (world_view.gd): T1's readability scale.
		c.set_display_scale(c.readable_scale())
		models.append(c)
	for i in guards.size():
		var g := CreatureModel.make(StringName(guards[i][0]))
		world.add_child(g)
		g.place(Vector3(-3.0 + i * 3.0, 0, 3.2), Vector3(-0.3, 0, -1))
		g.set_guard(true)
		g.play(StringName(guards[i][1]))
		models.append(g)
	var cam := Camera3D.new()
	world.add_child(cam)
	# The heist's follow camera (world_view.gd): a narrow 22° perspective at
	# 50°, turned 45°, 10.5 tiles across the width; ORTHO=1 for the old view.
	var pitch := deg_to_rad(50.0)
	var span := 10.5 * float(h) / float(w)
	var yaw := deg_to_rad(45.0)
	var back := Vector3(sin(yaw) * cos(pitch), sin(pitch), cos(yaw) * cos(pitch))
	var aim := Vector3(0, 0, 0.5)
	if OS.get_environment("ORTHO") == "1":
		cam.projection = Camera3D.PROJECTION_ORTHOGONAL
		cam.keep_aspect = Camera3D.KEEP_WIDTH
		cam.size = 12.0
		back = Vector3(0, sin(pitch), cos(pitch))
		cam.look_at_from_position(aim + back * 30.0, aim, Vector3.UP)
	else:
		cam.fov = 22.0
		cam.look_at_from_position(aim + back * (span / (2.0 * tan(deg_to_rad(11.0)))), aim, Vector3.UP)
	var t := float(OS.get_environment("T")) if OS.get_environment("T") != "" else 0.4
	for i in 3:
		await process_frame
	for c: CreatureModel in models:
		c.player().seek(t, true)
	for i in 3:
		await process_frame
	var img := vp.get_texture().get_image()
	img.save_png(OS.get_environment("SHOT"))
	print("saved ", img.get_size())
	quit()
