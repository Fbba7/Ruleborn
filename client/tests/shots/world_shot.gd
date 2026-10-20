extends SceneTree
## A heist on a dressed example island in 3D, saved as a still (tools/render/shoot.sh).
## SHOT is the file; HOUR, ZOOM and PITCH are optional.
func _initialize() -> void:
	var w := 540
	var h := 960
	root.size = Vector2i(w, h)
	var replay := RulebornReplay.new()
	var island := PackedByteArray()
	var ex := RulebornIsland.new()
	ex.reset(3)
	var put := {"tree": [[1, 1], [2, 5], [9, 2]], "hedge": [[4, 3], [5, 3], [6, 3]], "rock_pillar": [[8, 8]],
		"tall_grass": [[2, 8], [3, 8], [2, 9]], "pond": [[10, 6], [10, 7]], "fog_bank": [[7, 1]],
		"crystal_outcrop": [[1, 10]], "lantern_post": [[5, 9]], "boulder": [[3, 6]], "flower_meadow": [[7, 10], [8, 10]],
		"raised_ground": [[9, 9], [10, 9], [9, 10]], "fence": [[3, 1], [4, 1]], "bush": [[6, 6]], "statue": [[4, 10]],
		"bounce_mushroom": [[11, 3]], "ruin_wall": [[0, 5]], "lava_crack": [[6, 11]], "stepping_stones": [[10, 5]]}
	for id: String in put:
		for xy: Array in put[id]:
			ex.set_ground(xy[0], xy[1], id)
	ex.post_guard(0, 6, 4)
	ex.post_guard(1, 3, 7)
	ex.place_ward("static_coil", 8, 5)
	ex.place_ward("lantern_glare", 2, 3)
	ex.weave("bloom", 9, 4)
	ex.place_building("hearth", 1, 6)
	print(ex.problems())
	island = ex.bytes()
	replay.start("7", 4500, 3, island)
	var view := WorldView.new()
	view.size = Vector2(w, h)
	root.add_child(view)
	view.set_sky_hour(int(OS.get_environment("HOUR")) if OS.get_environment("HOUR") != "" else 12)
	view.show_replay(replay)
	var spots := replay.reaching()
	var s: Vector2i = spots[0] if spots.size() > 0 else Vector2i(0, 0)
	replay.give(0, 11, s.x * 256 + 128, s.y * 256 + 128)
	for i in 200:
		replay.step()
	view.show_replay(replay)
	view.describe()
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
