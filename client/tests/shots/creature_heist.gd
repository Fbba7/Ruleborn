extends SceneTree
## Characters at the heist's scale (§21.1: "a closer follow camera at 50°
## showing about 12 tiles across"): a crew walking, running and carrying, one
## knocked out, guards in their sash and lantern, on a plain grid of 1 m tiles,
## saved as a still (tools/render/shoot.sh). T is the moment in the clips.

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
			var c := Color("#D9CDA8") if (x + z) % 2 == 0 else Color("#CFC29A")
			st.set_color(c)
			for p: Vector2 in [Vector2(0, 0), Vector2(1, 0), Vector2(1, 1), Vector2(0, 0), Vector2(1, 1), Vector2(0, 1)]:
				st.set_normal(Vector3.UP)
				st.add_vertex(Vector3(x - 6 + p.x, 0, z - 10 + p.y))
	ground.mesh = st.commit()
	world.add_child(ground)
	var models: Array[CreatureModel] = []
	for i in CREW.size():
		var c := CreatureModel.make(StringName(CREW[i][0]))
		world.add_child(c)
		c.place(Vector3(-3.5 + (i % 4) * 2.2, 0, -2.5 + (i / 4) * 2.4), Vector3(0.6, 0, 1))
		c.play(StringName(CREW[i][1]))
		models.append(c)
	for i in GUARDS.size():
		var g := CreatureModel.make(StringName(GUARDS[i][0]))
		world.add_child(g)
		g.place(Vector3(-3.0 + i * 3.0, 0, 3.2), Vector3(-0.3, 0, -1))
		g.set_guard(true)
		g.play(StringName(GUARDS[i][1]))
		models.append(g)
	var cam := Camera3D.new()
	world.add_child(cam)
	cam.projection = Camera3D.PROJECTION_ORTHOGONAL
	cam.keep_aspect = Camera3D.KEEP_WIDTH
	cam.size = 12.0
	var pitch := deg_to_rad(50.0)
	var from := Vector3(0, sin(pitch), cos(pitch)) * 30.0 + Vector3(0, 0, 0.5)
	cam.transform = Transform3D(Basis.looking_at(Vector3(0, 0, 0.5) - from, Vector3.UP), from)
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
