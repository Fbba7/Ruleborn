class_name StageLod
extends RefCounted
## Lower-detail levels for the meshes a realm screen draws on §21.1's home
## camera, so a realm keeps to §21.3's 25,000–40,000 triangles there. The
## island, the kit and the town are built in code with every detail the
## heist's close camera needs; at the home camera most of it is smaller than
## a pixel. Each mesh is given levels once (`ImporterMesh.generate_lods`, the
## same simplifier the importer runs on the characters), cached by the mesh
## it came from, and the renderer picks a level by its size on screen
## (`Viewport.mesh_lod_threshold`, which `StageView` sets).

## Meshes smaller than this many triangles are left alone: a level would save
## less than it costs.
const MIN_TRIANGLES := 600
## How much more detail the kit keeps than the characters at the same size:
## round trees and bushes show their facets long before a body does.
const KIT_BIAS := 8.0
## A character's body at the home camera: a few dozen pixels tall, read by
## its silhouette and colours, it takes its lower levels sooner than the kit.
const SKINNED_BIAS := 0.4
## The shaders of the broad shapes that simplify freely: the island's
## ground and rim, and the town's buildings.
const PLAIN_SHADERS := ["look_ground.gdshader", "kit_ground.gdshader", "toon.gdshader"]

## How many meshes the cache holds before it starts again.
const CACHE_LIMIT := 1024

## The mesh each source mesh became, by the source's instance id.
static var _made := {}


## Every mesh under `root` given its levels, once per source mesh. Returns
## how many meshes changed.
static func apply(root: Node) -> int:
	var changed := 0
	for n: Node in root.find_children("*", "", true, false):
		if n is MeshInstance3D:
			var mi := n as MeshInstance3D
			var lodded := of(mi.mesh)
			if lodded != mi.mesh:
				mi.mesh = lodded
				mi.lod_bias = _bias(mi)
				changed += 1
		elif n is MultiMeshInstance3D:
			var mm := (n as MultiMeshInstance3D).multimesh
			if mm != null:
				var lodded := of(mm.mesh)
				if lodded != mm.mesh:
					mm.mesh = lodded
					(n as MultiMeshInstance3D).lod_bias = KIT_BIAS
					changed += 1
	return changed


## `mesh` with lower-detail levels, or `mesh` itself where it has them
## already, is blended, or is too small to gain.
static func of(mesh: Mesh) -> Mesh:
	if mesh == null or not (mesh is ArrayMesh):
		return mesh
	var id := mesh.get_instance_id()
	if _made.has(id):
		return _made[id]
	if _made.size() > CACHE_LIMIT:
		# Each realm builds its own island: forget the last ones' meshes.
		_made.clear()
	var result := mesh
	if _worth(mesh as ArrayMesh):
		var im := ImporterMesh.from_mesh(_indexed(mesh as ArrayMesh))
		im.generate_lods(25.0, 60.0, [])
		var made := im.get_mesh()
		if made != null:
			made.resource_name = mesh.resource_name
			made.custom_aabb = (mesh as ArrayMesh).custom_aabb
			result = made
	_made[id] = result
	# The made mesh is its own answer, so it is never simplified twice.
	_made[result.get_instance_id()] = result
	return result


## The kit's features (trees, bushes, rocks: T3's toon pieces, merged into
## one mesh across the island) keep more detail than the ground and the
## buildings, since a round crown shows its facets first.
static func _bias(mi: MeshInstance3D) -> float:
	# A character's body reads by its silhouette and colours, not its facets.
	if mi.skin != null or mi.get_parent() is Skeleton3D:
		return SKINNED_BIAS
	var mat := mi.material_override
	if mat == null and mi.mesh.get_surface_count() > 0:
		mat = mi.mesh.surface_get_material(0)
	var shader := (mat as ShaderMaterial).shader if mat is ShaderMaterial else null
	return 1.0 if shader != null and shader.resource_path.get_file() in PLAIN_SHADERS else KIT_BIAS


## `mesh` with an index on every surface: the kit builds most of its meshes
## as loose triangles, and the simplifier needs an index to work on. It
## welds vertices by position itself.
static func _indexed(mesh: ArrayMesh) -> ArrayMesh:
	var out := ArrayMesh.new()
	for s: int in mesh.get_surface_count():
		var arrays := mesh.surface_get_arrays(s)
		if arrays[Mesh.ARRAY_INDEX] == null:
			var n := (arrays[Mesh.ARRAY_VERTEX] as PackedVector3Array).size()
			var idx := PackedInt32Array()
			idx.resize(n)
			for i: int in n:
				idx[i] = i
			arrays[Mesh.ARRAY_INDEX] = idx
		out.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays, [], {}, mesh.surface_get_format(s))
		out.surface_set_material(s, mesh.surface_get_material(s))
		out.surface_set_name(s, mesh.surface_get_name(s))
	return out


static func _worth(mesh: ArrayMesh) -> bool:
	if mesh.get_blend_shape_count() > 0:
		return false
	var triangles := 0
	for s: int in mesh.get_surface_count():
		if mesh.surface_get_primitive_type(s) != Mesh.PRIMITIVE_TRIANGLES:
			return false
		# A skinned mesh simplifies too: a level is only another index over
		# the same vertices, so its bones and weights ride along (the
		# characters at the home camera are a few dozen pixels tall).
		var arrays := mesh.surface_get_arrays(s)
		var idx: Variant = arrays[Mesh.ARRAY_INDEX]
		var verts: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
		triangles += (idx as PackedInt32Array).size() / 3 if idx != null else verts.size() / 3
	return triangles >= MIN_TRIANGLES
