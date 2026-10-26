extends SceneTree
## The look's share of §21.3's budgets, part by part: for each realm and each
## detail level (WorldLook.Detail), the triangles and draw calls of every
## piece the look adds round a grid of GRID tiles (default 12). Runs headless
## (`godot --headless --path client -s res://tests/shots/look_budget.gd`) or
## through tools/render/shoot.sh, which also saves a still of the last realm.
const ALL := ["heart", "skyfield", "crystalline", "tidehold", "emberreach", "verdant", "lanternvale"]


func _initialize() -> void:
	var g := int(OS.get_environment("GRID")) if OS.get_environment("GRID") != "" else 12
	var parts := OS.get_environment("PARTS") == "1"
	for realm: String in ALL:
		var line := realm
		for detail: int in [WorldLook.Detail.FULL, WorldLook.Detail.LIGHT]:
			var world := Node3D.new()
			root.add_child(world)
			var look := WorldLook.new(world)
			look.detail = detail
			var statics := Node3D.new()
			world.add_child(statics)
			look.island(statics, Vector2i(g, g), 5, RealmPalette.of(realm), realm)
			var all := LookTests.count(world)
			line += "  %s %d tris / %d calls" % ["full" if detail == WorldLook.Detail.FULL else "light", all.x, all.y]
			if parts:
				for c: Node in statics.get_children():
					var inst := (c as MultiMeshInstance3D).multimesh.instance_count if c is MultiMeshInstance3D else 1
					print("    %-6s %-14s %4d x %6d" % ["full" if detail == 0 else "light", c.name, inst, _one(c)])
			world.free()
		print(line)
	quit()


## The triangles one piece draws, every instance counted.
static func _one(n: Node) -> int:
	if n is MeshInstance3D and (n as MeshInstance3D).mesh != null:
		return (n as MeshInstance3D).mesh.surface_get_array_len(0) / 3
	if n is MultiMeshInstance3D:
		var mm := (n as MultiMeshInstance3D).multimesh
		return mm.mesh.surface_get_array_len(0) / 3 * mm.instance_count
	return 0
