extends SceneTree
## The cloud wipe between realms (UniverseWipe) over the map, held at AMOUNT
## (0 open, 1 shut; 0.6 by default), saved as a still (tools/render/shoot.sh).


func _initialize() -> void:
	var view := UniverseView.new()
	root.add_child(view)
	view.size = Vector2(1080, 2340)
	view.show_universe(UniverseSample.view(6), UniverseSample.extras())
	view.focus_realm("heart", 1)
	for i in 8:
		await process_frame
	var wipe: UniverseWipe = view.find_children("*", "UniverseWipe", true, false)[0]
	var amount := OS.get_environment("AMOUNT")
	wipe.set_amount(float(amount) if amount != "" else 0.6)
	for i in 3:
		await process_frame
	root.get_texture().get_image().save_png(OS.get_environment("SHOT"))
	quit()
