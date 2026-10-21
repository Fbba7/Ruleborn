extends SceneTree
## One of T10's menu and meta screens with its tests' sample state
## (tools/render/shoot.sh). SCREEN names the route; SCROLL scrolls its list;
## TEXT sets the text size in percent; LOCALE the language.
func _initialize() -> void:
	_go()


func _go() -> void:
	root.size = Vector2i(1080, 2340)
	var name := OS.get_environment("SCREEN")
	if OS.get_environment("LOCALE") != "":
		Strings.set_locale(OS.get_environment("LOCALE"))
	if OS.get_environment("TEXT") != "":
		Settings.text_scale = int(OS.get_environment("TEXT"))
	App.services = Fixtures.answered(Services.build(root, "", null, "user://outbox-shot.json"))
	App.services.router.change = func(_path: String) -> void: pass
	App.services.store.dispatch(&"navigated", {"name": StringName(name), "params": ScreenShots.params(name)})
	var screen: Control = load(Router.ROUTES[StringName(name)]).instantiate()
	root.add_child(screen)
	await process_frame
	ScreenShots.fill(name, App.services.store)
	for i in 8:
		await process_frame
	if OS.get_environment("SCROLL") != "":
		for s: ScrollContainer in screen.find_children("*", "ScrollContainer", true, false):
			s.scroll_vertical = int(OS.get_environment("SCROLL"))
		for i in 3:
			await process_frame
	if OS.get_environment("HIDE") != "":
		var by_name := OS.get_environment("HIDE").begins_with("@")
		for c: Control in screen.find_children(OS.get_environment("HIDE").trim_prefix("@") if by_name else "*",
				"" if by_name else OS.get_environment("HIDE"), true, false):
			c.visible = false
		await process_frame
		await process_frame
	if OS.get_environment("NAMED") != "":
		for c: Control in screen.find_children(OS.get_environment("NAMED"), "", true, false):
			print(c.name, " ", c.get_combined_minimum_size())
			for k: Node in c.find_children("*", "Control", true, false):
				if (k as Control).get_combined_minimum_size().x > 200:
					print("  ", k.name, " ", k.get_class(), " ", (k as Control).get_combined_minimum_size())
	if OS.get_environment("WIDE") != "":
		for c: Control in screen.find_children("*", "Control", true, false):
			if c.get_combined_minimum_size().x > 1000:
				print(c.get_path(), " ", c.get_class(), " ", c.get_combined_minimum_size().x)
			if c.get_combined_minimum_size().x > 200 and c is Label:
				print("L ", (c as Label).text, " ", c.get_combined_minimum_size().x)
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(OS.get_environment("SHOT"))
	print("calls ", RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_DRAW_CALLS_IN_FRAME))
	quit()
