extends SceneTree
## The kit's sampler (T3): every terrain feature of §6.2 on one island, in a
## realm (REALM, default heart), saved as a still (tools/render/shoot.sh).
## SHOT is the file; HOUR, ZOOM, PITCH and TURN are optional.
func _initialize() -> void:
	var w := 540
	var h := 960
	root.size = Vector2i(w, h)
	var ex := RulebornIsland.new()
	ex.reset(int(OS.get_environment("LEVEL")) if OS.get_environment("LEVEL") != "" else 9)
	var side := ex.side()
	# Every feature but the tunnel, row by row with a gap between.
	var ids := ["rock_pillar", "ruin_wall", "ruin_wall", "fence", "fence", "fog_bank", "tall_grass", "stream", "stream",
		"bush", "hedge", "hedge", "tree", "thicket", "boulder", "gravel_path", "gravel_path", "scree", "crystal_outcrop",
		"lantern_post", "shade_canopy", "ember_vent", "lava_crack", "static_stone", "statue", "hot_spring", "arch",
		"marsh", "flower_meadow", "ice_sheet", "pond", "pond", "bell_post", "stepping_stones", "bounce_mushroom",
		"updraft_vent", "pit", "moss", "climbing_vines", "waterfall", "rapids"]
	var k := 0
	for y in range(1, side - 1, 2):
		for x in range(1, side - 1):
			if k < ids.size():
				ex.set_ground(x, y, ids[k])
				k += 1
	# Raised ground with a ramp and stairs up to it.
	for xy: Array in [[side - 4, side - 3], [side - 3, side - 3], [side - 2, side - 3], [side - 3, side - 2],
			[side - 2, side - 2]]:
		ex.set_ground(xy[0], xy[1], "raised_ground")
	ex.set_ground(side - 5, side - 3, "ramp")
	ex.set_ground(side - 4, side - 2, "stairs")
	ex.dig_tunnel(1, side - 2, 4, side - 2)
	print("placed ", k, " of ", ids.size(), " side ", side, " ", ex.problems())
	var replay := RulebornReplay.new()
	replay.start("7", 4500, 3, ex.bytes())
	var view := WorldView.new()
	view.size = Vector2(w, h)
	view.realm_type = OS.get_environment("REALM") if OS.get_environment("REALM") != "" else "heart"
	root.add_child(view)
	view.set_sky_hour(int(OS.get_environment("HOUR")) if OS.get_environment("HOUR") != "" else 12)
	view.show_replay(replay)
	if OS.get_environment("TURN") != "":
		view.turn(int(OS.get_environment("TURN")))
	if OS.get_environment("ZOOM") != "":
		view.set_zoom(int(OS.get_environment("ZOOM")))
	if OS.get_environment("PITCH") != "":
		view.pitch = float(OS.get_environment("PITCH"))
		view.set_zoom(view.zoom)
	for i in 4:
		await process_frame
	var img := view.viewport.get_texture().get_image()
	img.save_png(OS.get_environment("SHOT"))
	print("saved ", img.get_size())
	quit()
