class_name UniverseWhole
extends RefCounted
## The whole universe in a handful of meshes. Over the whole universe every
## island's rock, dressing, shades and far buildings and every fixed link is
## on the screen at once, each its own mesh (and its outline pass) so a realm
## seen close can swap its island and the others can be culled; drawn that way
## the map alone is over a hundred draw calls. At zoom 0 these merged copies
## stand in, one mesh per material, so the home stays under §21.3's 150 calls
## with its interface. Same triangles; the counts are not added twice.

## Each merged layer: the meta its sources carry, and whether it casts shadow.
const LAYERS := ["whole_body", "whole_hero", "whole_shades", "whole_far", "whole_link"]


## The merged copies of every mesh under `statics` marked with one of
## `LAYERS`, added to `statics` and hidden until `show` asks for them.
static func build(statics: Node3D) -> Array[MeshInstance3D]:
	var out: Array[MeshInstance3D] = []
	for layer: String in LAYERS:
		var st := SurfaceTool.new()
		var first: MeshInstance3D = null
		for node in statics.find_children("*", "MeshInstance3D", true, false):
			var mi := node as MeshInstance3D
			if not mi.has_meta(layer) or mi.mesh == null:
				continue
			first = mi if first == null else first
			for k in mi.mesh.get_surface_count():
				st.append_from(mi.mesh, k, mi.global_transform if mi.is_inside_tree() else _placed(mi))
		if first == null:
			continue
		var whole := MeshInstance3D.new()
		whole.name = layer.capitalize().replace(" ", "")
		whole.mesh = st.commit()
		whole.material_override = first.material_override
		whole.cast_shadow = first.cast_shadow
		whole.extra_cull_margin = 40.0
		whole.visible = false
		whole.set_meta("whole", true)
		statics.add_child(whole)
		out.append(whole)
	return out


## The merged copies shown over the whole universe (`on`), the meshes they
## stand for hidden while they are; otherwise left as the view set them.
static func show(statics: Node3D, whole: Array[MeshInstance3D], on: bool) -> void:
	if whole.is_empty():
		return
	for w: MeshInstance3D in whole:
		w.visible = on
	# The far buildings' own switch is the view's (`_show_lods`); the rest
	# are only ever hidden here.
	for node in statics.find_children("*", "MeshInstance3D", true, false):
		for layer: String in LAYERS:
			if node.has_meta(layer) and (on or layer != "whole_far"):
				(node as MeshInstance3D).visible = not on


## A mesh's place from its parents' transforms, before it is in the tree.
static func _placed(mi: Node3D) -> Transform3D:
	var t := mi.transform
	var n := mi.get_parent()
	while n is Node3D:
		t = (n as Node3D).transform * t
		n = n.get_parent()
	return t
