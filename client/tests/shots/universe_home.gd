extends SceneTree
## The home screen with its interface over the universe (§23.2), saved as a
## still (tools/render/shoot.sh). SHOT is the file; OUTER (outer realms, 6),
## ZOOM and FOCUS (as universe_zoom.gd), TEXT (the text size, 100) and TIME
## (seconds of animation) are optional; WHOLE shows the whole universe; RAIDS the
## raids not yet seen (2), on the Defence badge; NOTICE their notice too;
## MOST every amount at its widest (else the key frame's state, `keyframe`);
## LOCALE the language; CONTRAST high contrast; TALL the window's height in
## points over 540 wide (960 for 9:16). FIT checks that everything fits (see
## `fit`); the run fails where something does not.


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
	var raids := int(env.call("RAIDS", "2"))
	UniverseSample.fill(store, int(env.call("OUTER", "6")), raids, env.call("MOST", "") != "")
	if env.call("MOST", "") == "":
		keyframe(store)
	# The key frame's home has its raids on the Defence badge, the notice
	# already dismissed; NOTICE shows the notice as it arrives.
	Home._dismissed = 0 if env.call("NOTICE", "") != "" else raids
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
	if env.call("FIT", "") != "":
		var bad := fit(screen)
		for b: String in bad:
			print("fit FAIL ", b)
		print("fit ", "ok" if bad.is_empty() else "FAIL")
		if not bad.is_empty():
			# The still is saved all the same, to show what does not fit.
			root.get_texture().get_image().save_png(OS.get_environment("SHOT"))
			quit(1)
			return
	print("triangles ", screen.world.triangles, " draw calls ", screen.world.draw_calls(), " frame ",
		RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_PRIMITIVES_IN_FRAME), " prims ",
		RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_DRAW_CALLS_IN_FRAME), " calls")
	root.get_texture().get_image().save_png(OS.get_environment("SHOT"))
	print("wrote")
	quit()


## The key frame's state (art/ui/keyframes/01-home.*) over the sample's:
## Keeper 24 with 1,240 experience to go, strain at 82% (Humming), and
## 3.4k waiting to be collected, the essence garden full.
static func keyframe(store: Store) -> void:
	store.dispatch(&"keeper_loaded", {"view": {"level": 24, "xp": 22760, "toNext": 24000}})
	store.dispatch(&"weaving_loaded", {"view": {"stability": {"strain": 0.82, "band": 2}}})
	store.dispatch(&"roster_loaded", {"view": {"producers": [
		{"kind": "star_well", "realm": "heart", "stored": 2000, "holds": 3200},
		{"kind": "aether_spring", "realm": "outer-2", "stored": 600, "holds": 1800},
		{"kind": "garden", "realm": "outer-4", "stored": 800, "holds": 860}]}})


## Every canvas item under `top`, internal children (the kit's boxes and
## faces) included.
static func _all_inside(top: Node) -> Array:
	var out := []
	for c: Node in top.get_children(true):
		if c is CanvasItem:
			out.append(c)
		out.append_array(_all_inside(c))
	return out


## Rubric quality 9's scripted half: home shows a live character node in the
## toon look (the Keeper's companion, a CreatureModel), which moves (its clip
## plays, its stage draws every frame; held still only under reduced motion),
## and fills enough of its portrait to read as a shape (at least a third of
## the stage's picture is the figure). One line each that fails.
static func live(screen: Home) -> Array[String]:
	var bad: Array[String] = []
	var badge := screen.keeper_plate
	if badge == null or not badge.is_visible_in_tree():
		return ["no Keeper badge showing"]
	var model := badge.companion()
	if model == null or not model.is_inside_tree():
		return ["no live character on home"]
	var player := model.player()
	var moving := not Settings.reduced_motion
	if player == null or not player.is_playing() or (moving and is_zero_approx(player.speed_scale)):
		bad.append("the companion's clip does not play")
	if not String(model.clip).begins_with("idle"):
		bad.append("the companion plays %s, not an idle" % model.clip)
	var want := SubViewport.UPDATE_ALWAYS if moving else SubViewport.UPDATE_ONCE
	var stage := badge.stage()
	if stage.render_target_update_mode != want and not (not moving
			and stage.render_target_update_mode == SubViewport.UPDATE_DISABLED):
		bad.append("the companion's stage does not draw (mode %d)" % stage.render_target_update_mode)
	var img := stage.get_texture().get_image()
	if img == null or img.is_empty():
		bad.append("the companion's stage drew nothing")
		return bad
	var solid := 0
	var step := maxi(1, img.get_width() / 64)
	var seen := 0
	for y in range(0, img.get_height(), step):
		for x in range(0, img.get_width(), step):
			seen += 1
			if img.get_pixel(x, y).a > 0.5:
				solid += 1
	if solid < seen / 3:
		bad.append("the companion fills %d%% of its portrait" % (100 * solid / maxi(seen, 1)))
	return bad


## Board 3's objections A and C (AD-R22, AD-R24): what home never drops at any
## text size, with or without the raid notice. Collect, while anything waits,
## with its whole rect inside the viewport; the goal, while there is one; the
## chosen tab's name. One line each that fails.
static func must_show(screen: Home) -> Array[String]:
	var bad: Array[String] = []
	var view := screen.get_viewport_rect()
	var musts := {}
	var waits := false
	for p: Dictionary in App.services.store.get_slice(RosterState.ROSTER).get("view", {}).get("producers", []):
		waits = waits or int(p.get("stored", 0)) > 0
	if waits:
		musts["Collect"] = screen.collect_button
	if not screen.goal.is_empty():
		musts["goal"] = screen.goal_card
	var chosen := screen.tabs.buttons.get(screen.tabs.active, null) as Control
	if chosen != null:
		for l: Label in chosen.find_children("*", "Label", true, false):
			if l.get_parent() is VBoxContainer:
				musts["chosen tab's name"] = l
	for key: String in musts:
		var c := musts[key] as Control
		if not c.is_visible_in_tree():
			bad.append("%s hidden" % key)
		elif not view.grow(1.0).encloses(c.get_global_rect()):
			bad.append("%s %s not inside the viewport %s" % [key, c.get_global_rect(), view])
		elif c.get_global_rect().size.x < 1.0 or c.get_global_rect().size.y < 1.0:
			bad.append("%s has no size" % key)
	return bad


## What does not fit on home, one line each: a label's words wider than the
## label, or outside its panel or button, or off the screen; one of home's parts over
## another; a realm's pin over another pin or over home's parts, or off the
## screen; or some realms named over the whole universe and others not.
static func fit(screen: Home) -> Array[String]:
	var bad: Array[String] = []
	var whole := Rect2(Vector2.ZERO, screen.size)
	for l: Label in screen.find_children("*", "Label", true, false):
		if not l.is_visible_in_tree() or l.text == "" or screen.world.is_ancestor_of(l):
			continue
		var at := l.get_global_rect()
		var font := l.get_theme_font("font")
		var wide := 0.0
		for line: String in l.text.split("\n"):
			wide = maxf(wide, font.get_string_size(line, HORIZONTAL_ALIGNMENT_LEFT, -1,
				l.get_theme_font_size("font_size")).x)
		if l.autowrap_mode == TextServer.AUTOWRAP_OFF and not l.clip_text \
				and l.text_overrun_behavior == TextServer.OVERRUN_NO_TRIMMING and wide > at.size.x + 1.0:
			bad.append("%s %s: %.0f px of words in %.0f" % [l.get_path(), l.text, wide, at.size.x])
		var p := l.get_parent()
		while p != null and p != screen and not p is PanelContainer and not p is Button:
			p = p.get_parent()
		if (p is PanelContainer or p is Button) and not (p as Control).get_global_rect().grow(1.0).encloses(at):
			bad.append("%s %s: %s outside its panel %s" % [l.get_path(), l.text, at, (p as Control).get_global_rect()])
		if not whole.grow(1.0).encloses(at):
			bad.append("%s %s: %s off the screen" % [l.get_path(), l.text, at])
	var parts := {"keeper": screen.keeper_plate, "strain": screen.strain, "purse": screen.purse,
		"notice": screen.notice, "collect": screen.collect_button, "goal": screen.goal_card, "tabs": screen.tabs}
	for side: StringName in screen.sides:
		parts["side " + side] = screen.sides[side]
	var shown := {}
	for key: String in parts:
		var c := parts[key] as Control
		if c != null and c.is_visible_in_tree():
			shown[key] = c.get_global_rect()
	var keys := shown.keys()
	for i in keys.size():
		var a: Rect2 = shown[keys[i]]
		if not whole.grow(1.0).encloses(a):
			bad.append("%s %s off the screen" % [keys[i], a])
		for j in range(i + 1, keys.size()):
			# Strain in the purse's fourth place at large text: the purse's flow
			# keeps its places apart.
			var outer := parts[keys[i]] as Control
			var inner := parts[keys[j]] as Control
			if outer.is_ancestor_of(inner) or inner.is_ancestor_of(outer):
				continue
			if a.grow(-1.0).intersects(shown[keys[j]]):
				bad.append("%s %s over %s %s" % [keys[i], a, keys[j], shown[keys[j]]])
	bad.append_array(must_show(screen))
	bad.append_array(live(screen))
	var pins := screen.world.pins
	if not pins.is_visible_in_tree():
		# Over the whole universe every realm is marked, a numbered chip at the
		# least (board 3's objection C), never none.
		if screen.world.zoom == 0:
			bad.append("no realm marked over the whole universe")
		return bad
	var named: Array[String] = []
	var missing: Array[String] = []
	var boxes := {}
	for id: String in screen.world.islands:
		var pin := pins.realm_pin(id)
		if pin == null:
			continue
		if pin.is_visible_in_tree():
			named.append(id)
			boxes[id] = pin.get_global_rect()
		else:
			missing.append(id)
	if screen.world.zoom == 0 and not missing.is_empty():
		bad.append("realms %s named and %s not" % [named, missing])
	var ids := boxes.keys()
	for i in ids.size():
		var a: Rect2 = boxes[ids[i]]
		if not whole.encloses(a):
			bad.append("pin %s %s off the screen" % [ids[i], a])
		for j in range(i + 1, ids.size()):
			if a.grow(-0.5).intersects(boxes[ids[j]]):
				bad.append("pin %s %s over pin %s %s" % [ids[i], a, ids[j], boxes[ids[j]]])
		for key: String in shown:
			if a.grow(-0.5).intersects(shown[key]):
				bad.append("pin %s %s over %s %s" % [ids[i], a, key, shown[key]])
	return bad
