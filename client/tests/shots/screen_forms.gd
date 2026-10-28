extends SceneTree
## The Forms album with FormsTests sample (tools/render/shoot.sh).
func _initialize() -> void:
	_go()


func _go() -> void:
	root.size = Vector2i(1080, 2340)
	# TEXT=200 and HC=1 render §20.8's larger text and high contrast.
	if OS.get_environment("TEXT") != "":
		Settings.text_scale = int(OS.get_environment("TEXT"))
	Settings.high_contrast = OS.get_environment("HC") != ""
	Settings.apply()
	App.services = Fixtures.answered(Services.build(root, "", null, "user://outbox-shot.json"))
	var screen: FormsScreen = load("res://scenes/forms.tscn").instantiate()
	root.add_child(screen)
	await process_frame
	App.services.store.dispatch(&"forms_loaded", {"view": album()})
	for i in 60:
		await process_frame
		if Portrait.settled() and i > 6:
			break
	screen.stage.moving = false
	screen.stage.at_time(1.5)
	if OS.get_environment("SCROLL") != "":
		(screen.body.get_parent() as ScrollContainer).scroll_vertical = int(OS.get_environment("SCROLL"))
	for i in 4:
		await process_frame
	await RenderingServer.frame_post_draw
	# §21.3's budget, as RenderingServer counts the frame.
	print("draw calls ", RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_DRAW_CALLS_IN_FRAME),
		", primitives ", RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_PRIMITIVES_IN_FRAME))
	root.get_texture().get_image().save_png(OS.get_environment("SHOT"))
	print("wrote")
	quit()


## The album as the server sends it: every kind's three forms (§11.10's 54),
## FormsTests' sample first, a few more hatched, the rest still missing.
static func album() -> Dictionary:
	var v := FormsTests.sample()
	var forms: Array = v["forms"]
	var have := {"skyskipper": [1, 1, 0], "rambler": [1, 0, 0], "glass_golem": [0, 1, 0], "bloomling": [2, 1, 1]}
	for kind: String in StageHeroFigure.KINDS:
		if kind in ["featherkin", "mossbear"] or str(StageHeroFigure.KINDS[kind][1]) == "":
			continue
		var owned: Array = have.get(kind, [0, 0, 0])
		for i in 3:
			forms.append({"kind": kind, "note": ["hush", "spark", "echo"][i], "owned": owned[i]})
	return v
