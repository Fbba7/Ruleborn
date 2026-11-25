extends "res://tests/shots/screen_heist.gd"
## Phase 0's three heist style frames (docs/art/3d-quality/plan.md, section
## 6): the heist screen's still (screen_heist.gd, with all of its settings)
## with one of three looks laid over it in the shot only. The game's camera,
## scale and ground are not changed. STYLE picks the look:
## "a" the camera at 11 tiles across, figures at their true size;
## "b" today's camera (15 tiles) with crew and guards drawn GROW times larger
##     (1.4 if unset), as `readable_scale` would draw them;
## "c" both, with a quiet ground (no decoration on the walkable tiles, no
##     painted petals on the meadow) and fewer marks (the guards' words left
##     out), a stand-in for the one-marker language that does not exist yet.
## Without STYLE the still is screen_heist's own.

## The zoom between today's play camera (1, 15 tiles) and the close one
## (2, 7 tiles) that frames 11 tiles across (WorldView._frame_camera).
const ELEVEN := 1.5


## Called by screen_heist once the moment is played; the look goes on here.
func settle(node: Node) -> void:
	super.settle(node)
	var style := OS.get_environment("STYLE")
	var view: WorldView = node.find_children("*", "WorldView", true, false)[0]
	if style == "":
		if OS.get_environment("HEIGHTS") != "":
			heights(view)
		return
	if style == "a" or style == "c":
		view.zoom = 1
		view._zoom_f = ELEVEN
		view._frame_camera()
	if style == "b" or style == "c":
		var grow := float(OS.get_environment("GROW")) if OS.get_environment("GROW") != "" else 1.4
		for actor: Node3D in view._crew + view._guards:
			var figure := actor.get_node_or_null("Rig/Figure") as Node3D
			if figure != null:
				figure.scale *= grow
			if actor.has_meta("head"):
				actor.set_meta("head", float(actor.get_meta("head")) * grow)
	if OS.get_environment("HEIGHTS") != "":
		heights(view)
	if style == "c":
		quiet(view)
		if view.anchors.speech_layer != null:
			view.anchors.speech_layer.visible = false


## No decoration on the island's walkable tiles: every scattered piece whose
## place falls inside the tile grid is shrunk to nothing; the rim, the cliffs
## and the sky keep theirs. The meadow loses its painted petals. The
## laws' own signs (Bloom's drifting petals) stay: they say what holds there.
func quiet(view: WorldView) -> void:
	var half := Vector2(view._size) / 2.0
	var kept := 0
	var gone := 0
	for part: Node in view.find_children("Scatter*", "MultiMeshInstance3D", true, false):
		var mm := (part as MultiMeshInstance3D).multimesh
		if mm == null:
			continue
		var to_view: Transform3D = (
			view.world.global_transform.affine_inverse() * (part as Node3D).global_transform
		)
		for i in mm.visible_instance_count if mm.visible_instance_count >= 0 else mm.instance_count:
			var here: Vector3 = mm.get_instance_transform(i).origin
			var at: Vector3 = to_view * here
			if absf(at.x) <= half.x and absf(at.z) <= half.y:
				mm.set_instance_transform(i, Transform3D(Basis.from_scale(Vector3.ZERO), here))
				gone += 1
			else:
				kept += 1
	var plain := 0
	for node: Node in view.find_children("*", "MeshInstance3D", true, false):
		var mesh := node as MeshInstance3D
		for s in mesh.get_surface_override_material_count():
			var paint := mesh.get_active_material(s) as ShaderMaterial
			if paint != null and paint.get_shader_parameter("deco") != null:
				paint.set_shader_parameter("deco_scale", 0.0)
				plain += 1
	print(
		(
			"quiet: %d pieces gone from the walkable tiles, %d kept, %d meadows plain"
			% [gone, kept, plain]
		)
	)


## HEIGHTS: each figure's standing height on screen, in points (a
## 1080-pixel frame is 360 points wide): its feet and the top of its head
## (the "head" the marks stand on) projected through the camera.
func heights(view: WorldView) -> void:
	var cam: Camera3D = view.find_children("*", "Camera3D", true, false)[0]
	var points := 360.0 / float(cam.get_viewport().get_visible_rect().size.x)
	for role: String in ["crew", "guard"]:
		var tall: Array[float] = []
		for actor: Node3D in view._crew if role == "crew" else view._guards:
			var head := float(actor.get_meta("head", 1.0))
			var feet := cam.unproject_position(actor.global_position)
			var top := cam.unproject_position(actor.global_position + Vector3(0, head, 0))
			tall.append(snappedf(feet.distance_to(top) * points, 0.1))
		print("heights %s: %s" % [role, tall])
