extends SceneTree
## The home screen with its interface over the universe (§23.2), saved as a
## still (tools/render/shoot.sh). SHOT is the file; OUTER (outer realms, 6),
## ZOOM and FOCUS (as universe_zoom.gd), TEXT (the text size, 100) and TIME
## (seconds of animation) are optional; WHOLE shows the whole universe; RAIDS the
## raids not yet seen (2); MOST every amount at its widest;
## LOCALE the language; CONTRAST high contrast; TALL the window's height in
## points over 540 wide (960 for 9:16).


func _initialize() -> void:
	_go()


func _go() -> void:
	var env := func(k: String, d: String) -> String: return OS.get_environment(k) if OS.get_environment(k) != "" else d
	# The shot's own settings, read before they are set, so home's restore
	# keeps them.
	Settings.path = "user://settings-shot.cfg"
	Settings.restore()
	Settings.text_scale = int(env.call("TEXT", "100"))
	Settings.high_contrast = env.call("CONTRAST", "") != ""
	Settings.locale = env.call("LOCALE", "en")
	Settings.apply()
	if env.call("TALL", "") != "":
		DisplayServer.window_set_size(Vector2i(540, int(env.call("TALL", "1170"))))
		root.size = Vector2i(540, int(env.call("TALL", "1170")))
	App.services = Fixtures.answered(Services.build(root, "", null, "user://outbox-shot.json"))
	var store := App.services.store
	UniverseSample.fill(store, int(env.call("OUTER", "6")), int(env.call("RAIDS", "2")), env.call("MOST", "") != "")
	var screen: Home = load("res://scenes/home.tscn").instantiate()
	root.add_child(screen)
	await process_frame
	var zoom := int(env.call("ZOOM", "0"))
	if zoom > 0:
		screen.world.focus_realm(env.call("FOCUS", "heart"), zoom)
	elif env.call("WHOLE", "") != "":
		await process_frame
		screen.world.show_whole()
	for i in maxi(4, int(float(env.call("TIME", "1.5")) * 30.0)):
		await process_frame
	# HIDE: "world" or "ui", to read what each costs of the frame's budget.
	match env.call("HIDE", ""):
		"world":
			screen.world.visible = false
		"ui":
			for c: Node in screen.get_children():
				if c is CanvasItem and c != screen.world:
					(c as CanvasItem).visible = false
			screen.world.pins.visible = false
	await process_frame
	await RenderingServer.frame_post_draw
	# PROBE: the frame's draw calls with each part of the interface hidden in turn.
	if env.call("PROBE", "") != "":
		var calls := func() -> int: return RenderingServer.get_rendering_info(
			RenderingServer.RENDERING_INFO_TOTAL_DRAW_CALLS_IN_FRAME)
		var whole: int = calls.call()
		var parts: Array[CanvasItem] = []
		for c: Node in screen.find_children("*", "CanvasItem", true, false):
			var item := c as CanvasItem
			if item.is_visible_in_tree() and item.get_parent() is Container and item.get_parent().get_parent() is Container:
				parts.append(item)
		parts.append(screen.world.pins)
		# Faded out, not hidden, so nothing else moves into its place.
		for item: CanvasItem in parts:
			item.modulate.a = 0.0
			await process_frame
			await RenderingServer.frame_post_draw
			var n: int = whole - calls.call()
			if n >= 4:
				print("  %d %s (%s)" % [n, item.name, item.get_class()])
			item.modulate.a = 1.0
		# And home's own parts by name, whatever they cost.
		var named := {"keeper": screen.keeper_plate, "strain": screen.strain, "purse": screen.purse,
			"notice": screen.notice, "collect": screen.collect_button, "goal": screen.goal_card, "tabs": screen.tabs}
		for side: StringName in screen.sides:
			named["side " + side] = [screen.sides[side]]
		named["sides"] = screen.sides.values()
		for key: String in named:
			var items: Array = named[key] if named[key] is Array else [named[key]]
			items = items.filter(func(i: Variant) -> bool: return i != null and (i as CanvasItem).is_visible_in_tree())
			if items.is_empty():
				continue
			for item: CanvasItem in items:
				item.modulate.a = 0.0
			await process_frame
			await RenderingServer.frame_post_draw
			print("  part %s %d" % [key, whole - calls.call()])
			for item: CanvasItem in items:
				item.modulate.a = 1.0
		# PROBE=kinds: within the purse, the side buttons and the notice, what
		# each kind of node costs across them (each kind faded with what it holds).
		if env.call("PROBE", "") == "kinds":
			for key: String in ["purse", "sides", "notice", "strain"]:
				var tops: Array = named[key] if named[key] is Array else [named[key]]
				var kinds := {}
				for top: Node in tops:
					for c: Node in _all_inside(top):
						var d := 0
						var n := c
						while n != top:
							n = n.get_parent()
							d += 1
						var kind := "%s/%s/%d" % [c.get_class(), String(c.name).rstrip("0123456789"), d]
						kinds[kind] = kinds.get(kind, []) + [c]
				for kind: String in kinds:
					for item: CanvasItem in kinds[kind]:
						item.modulate.a = 0.0
					await process_frame
					await RenderingServer.frame_post_draw
					print("  kind %s %s %d" % [key, kind, whole - calls.call()])
					for item: CanvasItem in kinds[kind]:
						item.modulate.a = 1.0
		await process_frame
		await RenderingServer.frame_post_draw
	print("triangles ", screen.world.triangles, " draw calls ", screen.world.draw_calls(), " frame ",
		RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_PRIMITIVES_IN_FRAME), " prims ",
		RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_DRAW_CALLS_IN_FRAME), " calls")
	root.get_texture().get_image().save_png(OS.get_environment("SHOT"))
	print("wrote")
	quit()


## Every canvas item under `top`, internal children (the kit's boxes and
## faces) included.
static func _all_inside(top: Node) -> Array:
	var out := []
	for c: Node in top.get_children(true):
		if c is CanvasItem:
			out.append(c)
		out.append_array(_all_inside(c))
	return out
