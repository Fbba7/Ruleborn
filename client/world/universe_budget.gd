class_name UniverseBudget
extends RefCounted
## §21.3's budget on the universe map, held to what is drawn: the triangles
## of every mesh and layer of instances on show whose box the camera's view
## reaches, as the phone's main pass draws them.

## The triangles inside the camera's view now: every mesh and instance
## layer on show whose box the view reaches (what the phone draws in the
## main pass; §21.3's budget is held to this at every zoom).
static func drawn(world: Node3D, camera: Camera3D) -> int:
	var planes := camera.get_frustum()
	var total := 0
	for node in world.find_children("*", "GeometryInstance3D", true, false):
		var g := node as GeometryInstance3D
		if not g.is_visible_in_tree():
			continue
		var box := g.global_transform * g.get_aabb()
		var inside := true
		for plane: Plane in planes:
			var out := true
			for k in 8:
				if not plane.is_point_over(box.get_endpoint(k)):
					out = false
					break
			if out:
				inside = false
				break
		if inside:
			total += count(g)
	return total


## The triangles one mesh or layer of instances draws.
static func count(g: GeometryInstance3D) -> int:
	var mesh: Mesh = null
	var times := 1
	if g is MeshInstance3D:
		mesh = (g as MeshInstance3D).mesh
	elif g is MultiMeshInstance3D and (g as MultiMeshInstance3D).multimesh != null:
		mesh = (g as MultiMeshInstance3D).multimesh.mesh
		times = (g as MultiMeshInstance3D).multimesh.visible_instance_count
		if times < 0:
			times = (g as MultiMeshInstance3D).multimesh.instance_count
	if not (mesh is ArrayMesh):
		return 0
	var n := 0
	for k in mesh.get_surface_count():
		var index := (mesh as ArrayMesh).surface_get_array_index_len(k)
		n += (index if index > 0 else (mesh as ArrayMesh).surface_get_array_len(k)) / 3
	return n * times
