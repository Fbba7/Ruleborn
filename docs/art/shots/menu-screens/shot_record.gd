extends SceneTree
## The settings screen's still and its shot record (docs/art/ui-quality/gate/shots.md),
## written from one render, so the gate's crops cut the controls the still shows.
## TAB picks the tab ("game" by default, the one the screen opens on).
##
## Run from the repository's root, after `bash client/build.sh`
## (tools/render/shoot.sh takes only scripts under client/):
##
##   G=$HOME/.cache/ruleborn/Godot_v4.7.2-stable_linux.x86_64
##   SHOT=$PWD/out.png TAB=access xvfb-run -a -s "-screen 0 1080x2340x24" "$G" \
##     --rendering-driver opengl3 --path client -s "$PWD/docs/art/shots/menu-screens/shot_record.gd"
##
## The record goes beside SHOT as <name>.shot.json: the title and every button
## on screen, in points of the 390 x 845 frame, named by their words.
const FRAME := Vector2(390, 845)


func _initialize() -> void:
	_go()


func _go() -> void:
	root.size = Vector2i(1080, 2340)
	App.services = Fixtures.answered(Services.build(root, "", null, "user://outbox-shot.json"))
	App.services.router.change = func(_path: String) -> void: pass
	App.services.store.dispatch(&"navigated", {"name": &"settings", "params": ScreenShots.params("settings")})
	var screen: Control = load(Router.ROUTES[&"settings"]).instantiate()
	root.add_child(screen)
	await process_frame
	ScreenShots.fill("settings", App.services.store)
	for i in 8:
		await process_frame
	# Settings restores the saved settings on opening, as screen_meta.gd does.
	Settings.text_scale = 100
	screen.set("tab_shown", OS.get_environment("TAB") if OS.get_environment("TAB") != "" else "game")
	screen.call("_build")
	for i in 6:
		await process_frame
	await RenderingServer.frame_post_draw
	var shot := OS.get_environment("SHOT")
	root.get_texture().get_image().save_png(shot)
	var img_w := float(root.get_texture().get_image().get_width())
	var scale := FRAME.x / img_w
	var to_px := root.get_final_transform()
	var controls := []
	var n := 0
	for c: Control in screen.find_children("*", "Control", true, false):
		if not c.is_visible_in_tree():
			continue
		var r := to_px * (c.get_global_transform_with_canvas() * Rect2(Vector2.ZERO, c.size))
		if r.size.x < 8.0 or r.size.y < 8.0 or r.position.y > img_w * FRAME.y / FRAME.x or r.end.y < 0.0:
			continue
		var interactive := c is BaseButton
		var name := ""
		if interactive:
			name = str((c as Button).text) if c is Button else ""
			for l: Label in c.find_children("*", "Label", true, false):
				if name == "" and l.is_visible_in_tree():
					name = l.text
			if name == "":
				name = c.tooltip_text if c.tooltip_text != "" else str(c.name)
		elif c is Label and (c as Label).get_theme_font_size("font_size") >= UI.px(20):
			name = (c as Label).text
		else:
			continue
		n += 1
		var entry := {"name": "%s %d: %s" % [c.get_class().to_lower(), n, name.replace("\n", " ").left(80)],
			"rect": [snappedf(r.position.x * scale, 0.01), snappedf(r.position.y * scale, 0.01),
				snappedf(r.size.x * scale, 0.01), snappedf(r.size.y * scale, 0.01)]}
		if not interactive:
			entry["interactive"] = false
		controls.append(entry)
	var record := {"image": shot.get_file(), "frame_pt": [FRAME.x, FRAME.y], "text_scale": 1, "controls": controls}
	var f := FileAccess.open(shot.get_basename() + ".shot.json", FileAccess.WRITE)
	f.store_string(JSON.stringify(record, " ") + "\n")
	f.close()
	print("controls ", controls.size())
	quit()
