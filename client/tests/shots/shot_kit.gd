class_name ShotKit
extends RefCounted
## What every screen shot does once its screen is up: the sky's hour from
## HOUR, the words folded away with FOLD, a few frames for the world to
## settle, the frame saved to SHOT, and each world's triangles and draw
## calls printed (§21.3's budgets).


static func settle(tree: SceneTree, screen: Control) -> void:
	await tree.process_frame
	var hour := int(OS.get_environment("HOUR")) if OS.get_environment("HOUR") != "" else 12
	for v: Node in screen.find_children("*", "SubViewportContainer", true, false):
		if v.get_parent() is WorldView:
			(v.get_parent() as WorldView).set_sky_hour(hour)
	if OS.get_environment("FOLD") != "":
		for b: Node in screen.find_children("*", "Button", true, false):
			if b.has_meta("fold"):
				(b as Button).pressed.emit()
	for i in 6:
		await tree.process_frame
	await RenderingServer.frame_post_draw
	tree.root.get_texture().get_image().save_png(OS.get_environment("SHOT"))
	for v: Node in screen.find_children("*", "SubViewportContainer", true, false):
		if v.get_parent() is WorldView:
			var rid := (v.get_parent() as WorldView).viewport.get_viewport_rid()
			var visible := RenderingServer.VIEWPORT_RENDER_INFO_TYPE_VISIBLE
			var shadow := RenderingServer.VIEWPORT_RENDER_INFO_TYPE_SHADOW
			print("budget %s: %d triangles, %d draw calls (+%d in shadows)" % [screen.name,
				RenderingServer.viewport_get_render_info(rid, visible, RenderingServer.VIEWPORT_RENDER_INFO_PRIMITIVES_IN_FRAME),
				RenderingServer.viewport_get_render_info(rid, visible, RenderingServer.VIEWPORT_RENDER_INFO_DRAW_CALLS_IN_FRAME),
				RenderingServer.viewport_get_render_info(rid, shadow, RenderingServer.VIEWPORT_RENDER_INFO_DRAW_CALLS_IN_FRAME)])
	print("wrote")
