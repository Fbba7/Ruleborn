extends SceneTree
## The six pylon crowns (§21.2: each school's shape on "Pylon crowns") side by
## side on PieceKit's pylon, close up, as a still (tools/render/shoot.sh).

func _initialize() -> void:
	_go()


func _go() -> void:
	root.size = Vector2i(900, 360)
	var vp := SubViewport.new()
	vp.size = Vector2i(900, 360)
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
	cam.size = 3.4
	world.add_child(cam)
	cam.look_at_from_position(Vector3(0, 1.5 + 6.0, 9.0), Vector3(0, 1.45, 0), Vector3.UP)
	var toon: Shader = load("res://world/toon.gdshader")
	var schools: Array[String] = ["motion", "matter", "time", "energy", "life", "spirit"]
	for k in schools.size():
		var x := (k - 2.5) * 1.35
		var pylon := MeshInstance3D.new()
		pylon.mesh = PieceKit.pylon()
		pylon.material_override = WorldView.material(toon, true)
		pylon.position = Vector3(x, 0, 0)
		world.add_child(pylon)
		var crown := MeshInstance3D.new()
		crown.mesh = LawFx.crown(schools[k])
		crown.material_override = WorldView.material(toon, true)
		crown.position = Vector3(x, LawFxCrown.HEIGHT, 0)
		crown.scale = Vector3.ONE * 1.5
		crown.rotation.y = -0.5
		world.add_child(crown)
	for i in 4:
		await process_frame
	await RenderingServer.frame_post_draw
	vp.get_texture().get_image().save_png(OS.get_environment("SHOT"))
	print("wrote")
	quit()
