extends SceneTree
## A hero stage alone (tools/render/shoot.sh): KINDS is a comma list of
## kinds, LOOKS the looks to match; T the stage's time in seconds.
func _initialize() -> void:
	_go()


func _go() -> void:
	root.size = Vector2i(1080, 2340)
	var stage := StageHero.new()
	stage.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(stage)
	await process_frame
	var kinds := (OS.get_environment("KINDS") if OS.get_environment("KINDS") != "" else "featherkin").split(",")
	var looks := OS.get_environment("LOOKS").split(",") if OS.get_environment("LOOKS") != "" else PackedStringArray()
	stage.show_kinds(Array(kinds), Array(looks))
	stage.moving = false
	# KEY and FILL try other energies for the key light and the fill.
	if OS.get_environment("KEY") != "":
		stage.key_light.light_energy = float(OS.get_environment("KEY"))
	# PARAMS "name=value;…" set the creature shader's uniforms, to tune them.
	for pair: String in OS.get_environment("PARAMS").split(";", false):
		for m: CreatureModel in stage.world.find_children("*", "CreatureModel", true, false):
			var said := pair.get_slice("=", 1).split_floats(",")
			var value: Variant = said[0]
			if said.size() == 3:
				value = Vector3(said[0], said[1], said[2])
			m.material().set_shader_parameter(pair.get_slice("=", 0), value)
	if OS.get_environment("FILL") != "":
		for e: WorldEnvironment in stage.world.find_children("*", "WorldEnvironment", true, false):
			e.environment.ambient_light_energy = float(OS.get_environment("FILL"))
	stage.at_time(float(OS.get_environment("T")) if OS.get_environment("T") != "" else 1.0)
	for i in 4:
		await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(OS.get_environment("SHOT"))
	print("wrote")
	quit()
