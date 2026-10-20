extends SceneTree
## The seven realms' looks (§21.4) at three hours (§21.2: day 12, dusk 19,
## night 23), each on the same small island, as one grid of stills
## (tools/render/shoot.sh): a row a realm, a column an hour. SHOT is the
## file. Optional: REALMS (comma list), HOURS (comma list), CELL ("WxH" of a
## still, default 270x480), ZOOM (0 the whole rock, the default) and PITCH
## (default the home camera's 35°); SPAN widens the camera by a factor; FOV
## turns it to a perspective camera of that field of view;
## FEATURES=1 dresses the grid.
const ALL := ["heart", "skyfield", "crystalline", "tidehold", "emberreach", "verdant", "lanternvale"]


func _initialize() -> void:
	_go()


static func _env_list(key: String, fallback: Array) -> Array:
	var v := OS.get_environment(key)
	if v == "":
		return fallback
	var out := []
	for s: String in v.split(","):
		out.append(s.strip_edges())
	return out


func _go() -> void:
	var realms := _env_list("REALMS", ALL)
	var hours := _env_list("HOURS", ["12", "19", "23"])
	var cell := Vector2i(270, 480)
	if OS.get_environment("CELL") != "":
		var parts := OS.get_environment("CELL").split("x")
		cell = Vector2i(int(parts[0]), int(parts[1]))
	var zoom := int(OS.get_environment("ZOOM")) if OS.get_environment("ZOOM") != "" else 0
	var pitch := float(OS.get_environment("PITCH")) if OS.get_environment("PITCH") != "" else WorldView.HOME_PITCH
	root.size = Vector2i(cell.x * hours.size(), cell.y * realms.size())
	var views: Array[WorldView] = []
	for r in realms.size():
		for h in hours.size():
			var replay := RulebornReplay.new()
			replay.start("7", 4500, 3, _island(OS.get_environment("FEATURES") == "1"))
			var view := WorldView.new()
			view.realm_type = str(realms[r])
			view.heist = false
			view.pitch = pitch
			view.zoom = zoom
			view.position = Vector2(cell.x * h, cell.y * r)
			view.size = Vector2(cell)
			root.add_child(view)
			view.set_sky_hour(int(hours[h]))
			view.show_replay(replay)
			view.set_zoom(zoom)
			if OS.get_environment("SPAN") != "":
				view.camera.size *= float(OS.get_environment("SPAN"))
			if OS.get_environment("FOV") != "":
				# A perspective camera, as the heist's follow camera may be.
				view.camera.projection = Camera3D.PROJECTION_PERSPECTIVE
				view.camera.fov = float(OS.get_environment("FOV"))
			views.append(view)
	for i in 6:
		await process_frame
	await RenderingServer.frame_post_draw
	var out := Image.create(cell.x * hours.size(), cell.y * realms.size(), false, Image.FORMAT_RGB8)
	for v: WorldView in views:
		var img := v.viewport.get_texture().get_image()
		img.convert(Image.FORMAT_RGB8)
		out.blit_rect(img, Rect2i(Vector2i.ZERO, img.get_size()), Vector2i(v.position))
	var info := "%d triangles, %d draw calls (last view)" % [
		RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_PRIMITIVES_IN_FRAME),
		RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_DRAW_CALLS_IN_FRAME)]
	print(info)
	out.save_png(OS.get_environment("SHOT"))
	print("saved ", out.get_size())
	quit()


## A plain island, or one dressed as world_shot's.
static func _island(dressed: bool) -> PackedByteArray:
	var ex := RulebornIsland.new()
	ex.reset(3)
	if dressed:
		var put := {"tree": [[1, 1], [2, 5], [9, 2]], "hedge": [[4, 3], [5, 3], [6, 3]], "rock_pillar": [[8, 8]],
			"pond": [[10, 6], [10, 7]], "boulder": [[3, 6]], "flower_meadow": [[7, 10], [8, 10]],
			"lantern_post": [[5, 9]]}
		for id: String in put:
			for xy: Array in put[id]:
				ex.set_ground(xy[0], xy[1], id)
	return ex.bytes()
