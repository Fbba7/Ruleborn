extends SceneTree
## A heist with three laws woven, part-way through, as a still
## (tools/render/shoot.sh): LawFx attached to the world view, moved with the
## replay. LAWS (comma-separated, default Haste, Static and Aurora: a Spark
## harmony and the Tempest chord); TICKS (default 200); HOUR; ZOOM; PARADOX.

func _initialize() -> void:
	_go()


func _go() -> void:
	var w := 540
	var h := 960
	root.size = Vector2i(w, h)
	var laws: Array = ["haste", "static", "aurora"]
	if OS.get_environment("LAWS") != "":
		laws = Array(OS.get_environment("LAWS").split(","))
	var replay := RulebornReplay.new()
	replay.start("7", 4500, 3, island(laws))
	var view := WorldView.new()
	view.size = Vector2(w, h)
	root.add_child(view)
	view.set_sky_hour(int(OS.get_environment("HOUR")) if OS.get_environment("HOUR") != "" else 12)
	view.show_replay(replay)
	var fx := LawFx.attach(view, replay)
	if OS.get_environment("PARADOX") != "":
		fx.set_paradox(OS.get_environment("PARADOX"))
	var spots := replay.reaching()
	var s: Vector2i = spots[0] if spots.size() > 0 else Vector2i(0, 0)
	replay.give(0, 11, s.x * 256 + 128, s.y * 256 + 128)
	var ticks := int(OS.get_environment("TICKS")) if OS.get_environment("TICKS") != "" else 200
	for i in ticks:
		replay.step()
	view.show_replay(replay)
	view.describe()
	if OS.get_environment("ZOOM") != "":
		view.set_zoom(int(OS.get_environment("ZOOM")))
	fx.sync(replay.tick())
	fx.sync_world(replay)
	for b: Dictionary in [fx.budget(str(laws[0])), fx.budget(str(laws[1])), fx.budget(str(laws[2]))]:
		print(b)
	for i in 4:
		await process_frame
	var img := view.viewport.get_texture().get_image()
	img.save_png(OS.get_environment("SHOT"))
	print("saved ", img.get_size(), " draws ", RenderingServer.get_rendering_info(
		RenderingServer.RENDERING_INFO_TOTAL_DRAW_CALLS_IN_FRAME), " triangles ",
		RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_PRIMITIVES_IN_FRAME))
	quit()


## world_shot's dressed island, with `laws` woven round the middle.
static func island(laws: Array) -> PackedByteArray:
	var ex := RulebornIsland.new()
	ex.reset(3)
	var put := {"tree": [[1, 1], [2, 5], [9, 2]], "hedge": [[4, 3], [5, 3], [6, 3]], "rock_pillar": [[8, 8]],
		"tall_grass": [[2, 8], [3, 8], [2, 9]], "pond": [[10, 6], [10, 7]], "fog_bank": [[7, 1]],
		"crystal_outcrop": [[1, 10]], "lantern_post": [[5, 9]], "boulder": [[3, 6]], "flower_meadow": [[7, 10], [8, 10]],
		"raised_ground": [[9, 9], [10, 9], [9, 10]], "fence": [[3, 1], [4, 1]], "bush": [[6, 6]], "statue": [[4, 10]],
		"static_stone": [[11, 3]], "ruin_wall": [[0, 5]], "stepping_stones": [[10, 5]]}
	for id: String in put:
		for xy: Array in put[id]:
			ex.set_ground(xy[0], xy[1], id)
	ex.post_guard(0, 6, 4)
	ex.post_guard(1, 3, 7)
	ex.place_ward("static_coil", 8, 5)
	ex.place_ward("lantern_glare", 2, 3)
	var at: Array[Vector2i] = [Vector2i(9, 4), Vector2i(2, 2), Vector2i(7, 8), Vector2i(5, 6)]
	for k in laws.size():
		ex.weave(str(laws[k]), at[k % at.size()].x, at[k % at.size()].y)
	ex.place_building("hearth", 1, 6)
	return ex.bytes()
