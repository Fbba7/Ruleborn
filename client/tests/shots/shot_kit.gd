class_name ShotKit
extends RefCounted
## What every screen shot does once its screen is up: the sky's hour from
## HOUR, a few frames for the world to settle, and the frame saved to SHOT.


static func settle(tree: SceneTree, screen: Control) -> void:
	await tree.process_frame
	var hour := int(OS.get_environment("HOUR")) if OS.get_environment("HOUR") != "" else 12
	for v: Node in screen.find_children("*", "SubViewportContainer", true, false):
		if v.get_parent() is WorldView:
			(v.get_parent() as WorldView).set_sky_hour(hour)
	for i in 6:
		await tree.process_frame
	await RenderingServer.frame_post_draw
	tree.root.get_texture().get_image().save_png(OS.get_environment("SHOT"))
	print("wrote")
