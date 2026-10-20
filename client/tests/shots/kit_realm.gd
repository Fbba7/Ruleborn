extends SceneTree
## A lived-in realm for the kit (T3): the Keeper's Spire, houses, a well, a
## garden, a library and more joined by gravel paths, with trees, hedges, a
## stream and a pond, on the home camera (§21.1's 35°), saved as a still
## (tools/render/shoot.sh). REALM (default heart), LEVEL (the buildings'
## level, default 5), HOUR, ZOOM, TURN and PITCH are optional; SHOT is the file.
func _initialize() -> void:
	_shoot()


func _shoot() -> void:
	var w := 540
	var h := 960
	root.size = Vector2i(w, h)
	var ex := RulebornIsland.new()
	ex.reset(9)
	var side := ex.side()
	var lvl := int(OS.get_environment("LEVEL")) if OS.get_environment("LEVEL") != "" else 5
	var placed := []
	for b: Array in [["keeper_s_spire", 5, 4], ["hearth", 1, 1], ["star_well", 9, 1], ["hearth", 11, 4],
			["garden", 1, 9], ["library", 10, 9], ["storehouse", 5, 10], ["nursery", 1, 5], ["observatory", 11, 12],
			["hearth", 8, 12]]:
		if ex.place_building(b[0], b[1], b[2]):
			placed.append(b)
	var put := {"gravel_path": [[2, 3], [3, 3], [4, 3], [5, 3], [6, 3], [7, 3], [8, 3], [9, 3], [10, 3], [6, 7], [6, 8],
		[6, 9], [3, 7], [4, 7], [5, 7], [7, 7], [8, 7], [9, 7], [10, 7], [10, 6], [3, 8], [3, 9], [11, 7], [11, 8],
		[7, 9], [8, 9], [9, 11], [9, 10], [3, 4], [3, 5], [3, 6], [11, 6], [12, 6], [12, 7]],
		"tree": [[0, 0], [4, 0], [13, 1], [0, 12], [13, 9], [4, 12], [12, 0], [7, 0]],
		"hedge": [[4, 9], [4, 10], [4, 11]], "pond": [[12, 2], [13, 2], [13, 3]],
		"stream": [[0, 7], [1, 7], [2, 7]], "lantern_post": [[4, 4], [9, 4], [8, 8], [2, 11]],
		"flower_meadow": [[5, 0], [6, 0], [0, 3], [7, 13], [6, 13]], "bush": [[8, 0], [12, 11], [3, 13]],
		"tall_grass": [[0, 9], [0, 10], [13, 12], [13, 13]], "boulder": [[10, 0]], "bell_post": [[9, 8]],
		"statue": [[5, 8]], "fence": [[0, 13], [1, 13], [2, 13]], "shade_canopy": [[7, 8]]}
	for id: String in put:
		for xy: Array in put[id]:
			ex.set_ground(xy[0], xy[1], id)
	print("placed ", placed.size(), " side ", side, " ", ex.problems())
	var replay := RulebornReplay.new()
	replay.start("7", 4500, 3, ex.bytes())
	var view := WorldView.new()
	view.size = Vector2(w, h)
	view.realm_type = OS.get_environment("REALM") if OS.get_environment("REALM") != "" else "heart"
	var known := []
	for b: Array in ex.buildings():
		known.append([b[0], b[1], b[2], b[3], lvl])
	view.buildings = known
	view.heist = false
	view.pitch = WorldView.HOME_PITCH
	root.add_child(view)
	view.set_sky_hour(int(OS.get_environment("HOUR")) if OS.get_environment("HOUR") != "" else 12)
	view.show_replay(replay)
	if OS.get_environment("TURN") != "":
		view.turn(int(OS.get_environment("TURN")))
	view.set_zoom(int(OS.get_environment("ZOOM")) if OS.get_environment("ZOOM") != "" else 1)
	if OS.get_environment("PITCH") != "":
		view.pitch = float(OS.get_environment("PITCH"))
		view.set_zoom(view.zoom)
	for i in 4:
		await process_frame
	var img := view.viewport.get_texture().get_image()
	img.save_png(OS.get_environment("SHOT"))
	print("saved ", img.get_size())
	quit()
