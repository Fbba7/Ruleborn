extends SceneTree
## §21.7's world signatures, one small realm a law, as one sheet of stills
## (tools/render/shoot.sh): the same realm each time — hedges, a ruin wall,
## a stream, a lantern, a static stone, two guards and a ward — with one law
## woven, LawFx attached and moved to the heist's tick TICKS (default 150).
## LAWS (comma-separated) picks the laws, default the 24 at launch, and a
## cell may weave several, joined by "+" ("haste+static+aurora"); COLS the
## sheet's columns; STEP ticks added cell by cell (a law repeated in LAWS
## then shows its motion over time); CELL the cell's width and height ("360x420"); ZOOM the view's zoom.

func _initialize() -> void:
	_go()


func _go() -> void:
	var laws: Array = Array(LawFx.LAUNCH)
	if OS.get_environment("LAWS") != "":
		laws = Array(OS.get_environment("LAWS").split(","))
	var cols := int(OS.get_environment("COLS")) if OS.get_environment("COLS") != "" else 4
	var cell := Vector2i(360, 420)
	if OS.get_environment("CELL") != "":
		var wh := OS.get_environment("CELL").split("x")
		cell = Vector2i(int(wh[0]), int(wh[1]))
	var ticks := float(OS.get_environment("TICKS")) if OS.get_environment("TICKS") != "" else 150.0
	var rows := ceili(laws.size() / float(cols))
	var sheet := Image.create(cell.x * cols, cell.y * rows, false, Image.FORMAT_RGB8)
	sheet.fill(Color("#171046"))
	root.size = cell
	for k in laws.size():
		var law: String = laws[k]
		var replay := RulebornReplay.new()
		replay.start("11", 4500, 3, island(law.split("+")))
		var view := WorldView.new()
		view.size = Vector2(cell)
		root.add_child(view)
		view.set_sky_hour(12)
		view.show_replay(replay)
		if OS.get_environment("ZOOM") != "":
			view.set_zoom(int(OS.get_environment("ZOOM")))
		var fx := LawFx.attach(view, replay)
		fx.source = null
		fx.sync(ticks + k * float(OS.get_environment("STEP") if OS.get_environment("STEP") != "" else "0"))
		fx.sync_world(replay)
		for i in 3:
			await process_frame
		await RenderingServer.frame_post_draw
		var img := view.viewport.get_texture().get_image()
		img.convert(Image.FORMAT_RGB8)
		sheet.blit_rect(img, Rect2i(Vector2i.ZERO, cell), Vector2i((k % cols) * cell.x, (k / cols) * cell.y))
		print("%s %s" % [law, fx.budget(law.split("+")[0])])
		view.queue_free()
		await process_frame
	sheet.save_png(OS.get_environment("SHOT"))
	print("saved ", sheet.get_size())
	quit()


## The sheet's realm: one of everything a signature dresses, the laws woven
## round the middle.
static func island(laws: PackedStringArray) -> PackedByteArray:
	var ex := RulebornIsland.new()
	ex.reset(1 if laws.size() == 1 else 3)
	var n := ex.side()
	var put := {"hedge": [[2, 2], [3, 2], [4, 2]], "ruin_wall": [[n - 3, 3], [n - 3, 4]], "tree": [[1, n - 3]],
		"stream": [[n - 2, n - 4], [n - 2, n - 3], [n - 3, n - 3]], "lantern_post": [[2, n - 2]],
		"static_stone": [[n - 2, 1]], "boulder": [[5, n - 2]], "tall_grass": [[1, 5], [1, 6]], "bush": [[n - 4, n - 2]]}
	for id: String in put:
		for xy: Array in put[id]:
			ex.set_ground(xy[0], xy[1], id)
	ex.post_guard(0, 3, 5)
	ex.post_guard(1, n - 4, 6)
	ex.place_ward("static_coil", 5, 3)
	var spots: Array[Vector2i] = [Vector2i(n / 2 - 1, n / 2 + 1), Vector2i(n / 2 + 2, n / 2 - 2), Vector2i(2, n / 2)]
	for k in laws.size():
		ex.weave(laws[k], spots[k % spots.size()].x, spots[k % spots.size()].y)
	return ex.bytes()
