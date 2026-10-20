extends SceneTree
func _initialize() -> void:
	var view := UniverseView.new()
	root.add_child(view)
	view.size = Vector2(1080, 2340)
	view.show_universe({"realms": [{"realm": "heart", "type": "Heart", "level": 3, "buildings": []}]}, {"band": 0})
	view.set_zoom(0)
	if OS.get_environment("NOGAL") != "":
		view.statics.get_node("Galaxy").visible = false
	for i in 10:
		await process_frame
	root.get_texture().get_image().save_png(OS.get_environment("SHOT"))
	quit()
