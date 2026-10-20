extends SceneTree
## The kit's buildings (T3): §10.1's kinds in rows, each at §21.5's four
## looks (levels 1, 4, 7 and 10) left to right, in a realm (REALM, default
## heart), saved as a still (tools/render/shoot.sh). ROWS picks the kinds by
## their place in BuildingKit.KINDS ("0-5", the default "0-16"); SHOT is the
## file, PITCH and HOUR optional.
func _initialize() -> void:
	_shoot()


func _shoot() -> void:
	var w := int(OS.get_environment("W")) if OS.get_environment("W") != "" else 960
	var h := int(OS.get_environment("H")) if OS.get_environment("H") != "" else 1280
	root.size = Vector2i(w, h)
	var rows := (OS.get_environment("ROWS") if OS.get_environment("ROWS") != "" else "0-16").split("-")
	var first := int(rows[0])
	var last := int(rows[rows.size() - 1])
	var realm := OS.get_environment("REALM") if OS.get_environment("REALM") != "" else "heart"
	var colours := RealmPalette.of(realm)
	var vp := SubViewport.new()
	vp.size = Vector2i(w, h)
	vp.own_world_3d = true
	vp.msaa_3d = Viewport.MSAA_2X
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(vp)
	var world := Node3D.new()
	vp.add_child(world)
	var look := WorldLook.new(world)
	look.set_hour(int(OS.get_environment("HOUR")) if OS.get_environment("HOUR") != "" else 12)
	var g := Geo.new()
	var fine := Geo.new()
	var panes := Geo.new()
	var count := last - first + 1
	var spacing := 4.2
	var grass := Geo.new()
	grass.painted = true
	var span := Vector2(4 * spacing, count * spacing)
	var z := Vector4.ZERO
	var up := Vector3.UP
	var c: Color = colours["grass"]
	var a := Vector3(-span.x / 2.0, 0, -span.y / 2.0)
	grass.tri_painted([a, a + Vector3(span.x, 0, span.y), a + Vector3(span.x, 0, 0)], [up, up, up], [c, c, c], [z, z, z])
	grass.tri_painted([a, a + Vector3(0, 0, span.y), a + Vector3(span.x, 0, span.y)], [up, up, up], [c, c, c], [z, z, z])
	var tris := []
	for r in count:
		var kind: String = BuildingKit.KINDS[first + r]
		for col in 4:
			var lvl: int = BuildingKit.LOOKS[col]
			var side := 3 if kind == "keeper_s_spire" else 2
			var mid := Vector3(-span.x / 2.0 + spacing * (col + 0.5), 0, -span.y / 2.0 + spacing * (r + 0.5))
			var before := g.triangles + fine.triangles
			BuildingKit.build(g, kind, mid, side, lvl, colours, fine, panes)
			tris.append("%s@%d=%d" % [kind, lvl, g.triangles + fine.triangles - before])
	print("triangles ", tris)
	var ground_mat := RealmKit.material("ground")
	for pair: Array in [[grass.mesh(), ground_mat], [g.mesh(), RealmKit.material("toon", true)],
			[fine.mesh(), RealmKit.material("toon")], [panes.mesh(), RealmKit.material("clear")]]:
		var mi := MeshInstance3D.new()
		mi.mesh = pair[0]
		mi.material_override = pair[1]
		world.add_child(mi)
	var cam := Camera3D.new()
	cam.projection = Camera3D.PROJECTION_ORTHOGONAL
	cam.size = maxf(span.y * 0.62 + 2.5, span.x * float(h) / w * 1.05)
	world.add_child(cam)
	var pitch := deg_to_rad(float(OS.get_environment("PITCH")) if OS.get_environment("PITCH") != "" else 35.0)
	var aim := Vector3(0, 1.6, -0.8)
	cam.look_at_from_position(Vector3(0, sin(pitch), cos(pitch)) * 40.0 + aim, aim)
	for i in (int(OS.get_environment("FRAMES")) if OS.get_environment("FRAMES") != "" else 4):
		await process_frame
	vp.get_texture().get_image().save_png(OS.get_environment("SHOT"))
	print("saved")
	quit()
