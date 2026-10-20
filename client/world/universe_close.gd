class_name UniverseClose
extends RefCounted
## The realm seen close on the universe map, drawn as T2 draws a realm's
## island (`WorldLook.island`: the diorama's painted meadow, strata cliffs,
## roots and vines, falls, the meadow's tufts, pebbles and flowers, the
## realm's signature dressing) instead of the map's light rock. It is the
## same island the realm view draws, at the same size for the same grid, so
## swooping in on a realm shows the place itself.
##
## T2's look is made for one realm's own sky; its light, fog and vignette
## are built on a stand-in that is never drawn, and only the island's pieces
## are kept, under the map's own night light.


## The island of `isl`'s realm, `tiles` across, as a node to stand at its
## place on the map; its triangles are in its "triangles" meta.
static func build(isl: UniverseIsland, tiles: int) -> Node3D:
	var stand_in := Node3D.new()
	var look := WorldLook.new(stand_in)
	var node := Node3D.new()
	node.name = "Close"
	look.island(node, Vector2i(tiles, tiles), isl.island_seed, RealmPalette.of(isl.key), isl.key)
	stand_in.free()
	node.position = isl.at
	node.set_meta("triangles", triangles(node))
	return node


## The triangles a node's meshes and instances draw.
static func triangles(node: Node3D) -> int:
	var total := 0
	for c in node.find_children("*", "GeometryInstance3D", true, false):
		if c is MeshInstance3D and (c as MeshInstance3D).mesh is ArrayMesh:
			total += _count((c as MeshInstance3D).mesh as ArrayMesh)
		elif c is MultiMeshInstance3D and (c as MultiMeshInstance3D).multimesh.mesh is ArrayMesh:
			var mm := (c as MultiMeshInstance3D).multimesh
			total += mm.instance_count * _count(mm.mesh as ArrayMesh)
	return total


static func _count(m: ArrayMesh) -> int:
	var n := 0
	for s in m.get_surface_count():
		var index := m.surface_get_array_index_len(s)
		n += (index if index > 0 else m.surface_get_array_len(s)) / 3
	return n
