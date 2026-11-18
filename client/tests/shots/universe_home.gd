extends SceneTree
## The home screen with its interface over the universe (§23.2), saved as a
## still (tools/render/shoot.sh). SHOT is the file; OUTER (outer realms, 6),
## ZOOM and FOCUS (as universe_zoom.gd), TEXT (the text size, 100) and TIME
## (seconds of animation) are optional; WHOLE shows the whole universe; RAIDS the
## raids not yet seen (2), on the Defence badge; NOTICE their notice too;
## MOST every amount at its widest; EMPTY a new Keeper's (`start`, with OUTER
## and RAIDS for the realms and raids); else the key frame's state (`keyframe`);
## LOCALE the language; CONTRAST high contrast; TALL the window's height in
## points over 540 wide (960 for 9:16). FIT checks that everything fits (see
## `fit`); the run fails where something does not. The cases it must pass are
## listed in docs/art/tracks/home-screen.md; among them, board 3b's H (AD-R39):
## at 200% the four side buttons and the realms' chips in pt_BR, pt_PT and fr
## with and without NOTICE, in en and de with it, and in en at TALL=900; and
## M26's states (MOST, EMPTY, RAIDS=99) at 200% in en, pt_BR and de; and 100%,
## 125%, 150% and 200% in en, pt_BR and de with and without NOTICE
## (docs/art/shots/home-screen/fit_home.sh, P4-S2-home-purse).
## QUIT shows the question the phone's back asks on home (App.GoBack), and
## FIT then checks it too (`asked`).


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
	if env.call("EMPTY", "") != "":
		start(store)
	elif env.call("MOST", "") == "":
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
	var go_back: App.GoBack = null
	if env.call("QUIT", "") != "":
		current_scene = screen
		go_back = App.GoBack.new()
		root.add_child(go_back)
		await process_frame
		go_back.back()
		for i in 20:
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
		if go_back != null:
			bad.append_array(asked(go_back))
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
## Keeper 24 with 1,240 experience to go, strain at 82% (Humming),
## 3.4k waiting to be collected, the essence garden full, four of the crew
## idle (the Crew tab's count), and Lantern Vale locked until Keeper 28
## (five outer realms open; OUTER, when given, keeps its own count).
static func keyframe(store: Store) -> void:
	if OS.get_environment("OUTER") == "":
		store.dispatch(&"universe_loaded", {"view": UniverseSample.view(5)})
	store.dispatch(&"keeper_loaded", {"view": {"level": 24, "xp": 22760, "toNext": 24000}})
	store.dispatch(&"weaving_loaded", {"view": {"stability": {"strain": 0.82, "band": 2}}})
	var crew: Array = UniverseSample.extras()["characters"]
	for kind: String in ["emberling", "rambler"]:
		crew.append({"kind": kind, "state": "idle", "home": "spire", "work": null})
	store.dispatch(&"roster_loaded", {"view": {"characters": crew, "producers": [
		{"kind": "star_well", "realm": "heart", "stored": 2000, "holds": 3200},
		{"kind": "aether_spring", "realm": "outer-2", "stored": 600, "holds": 1800},
		{"kind": "garden", "realm": "outer-4", "stored": 800, "holds": 860}]}})


## A new Keeper's home (M26's empty state): level 1, nothing in the purse,
## nothing waiting to be collected (so no Collect), no strain, the season
## track untouched.
static func start(store: Store) -> void:
	store.dispatch(&"keeper_loaded", {"view": {"level": 1, "xp": 0, "toNext": 100}})
	store.dispatch(&"wallet_loaded", {"balance": {"starlight": 0, "essence": 0}})
	store.dispatch(&"codex_loaded", {"view": {"aether": 0}})
	store.dispatch(&"league_loaded", {"view": {"renown": 0, "season": 1}})
	store.dispatch(&"weaving_loaded", {"view": {"stability": {"strain": 0.0, "band": 0}}})
	store.dispatch(&"roster_loaded", {"view": {"producers": [
		{"kind": "star_well", "realm": "heart", "stored": 0, "holds": 320}]}})
	store.dispatch(&"track_loaded", {"view": {"season": 1, "stars": 0, "claimed": 0, "tiers": [],
		"next": {"tier": 1, "cost": 100}}})


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


## Board 3's objections A and C (AD-R22, AD-R24) and board 3b's H (AD-R39):
## what home never drops at any text size, with or without the raid notice.
## Collect, while anything waits, with its whole rect inside the viewport; the
## goal, while there is one; the four side buttons; the chosen tab's name. One
## line each that fails.
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
	# The four side buttons, at every text size and with the notice up too
	# (board 3b's objection H): the key frames keep them at 200% as discs.
	for side: StringName in screen.sides:
		musts["side button %s" % side] = screen.sides[side]
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
## screen, nearer another than the pins' gap, or far from its island (S2-R20's
## first objection: a named pin further from its point than `NEAR` of its
## heights, a chip than `FAR`); or some realms named over the whole universe
## and others not.
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
	bad.append_array(kept(screen))
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
	var forms := {}
	for id: String in screen.world.islands:
		var pin := pins.realm_pin(id)
		if pin == null:
			continue
		if pin.is_visible_in_tree():
			named.append(id)
			boxes[id] = pin.get_global_rect()
			var mark: Vector2 = pins.global_position + (pin.get_meta("anchor", Vector2.ZERO) as Vector2)
			var words := (pin.get_child(0).get_child(1) as Control).visible
			forms["%s %s" % [words, (pin.get_child(0).get_child(0) as Control).visible]] = id
			var reach := pin.size.y * (UniversePins.NEAR if words or (pin.get_child(0).get_child(0) as Control).visible
				else UniversePins.FAR)
			var off := UniversePins._off(boxes[id], mark)
			if off > reach + 0.5:
				bad.append("pin %s %s %.0f px from its island's point %s (at most %.0f)" % [id, boxes[id], off, mark,
					reach])
		else:
			missing.append(id)
	if forms.size() > 1:
		# One form for every realm (AD's objection (b) on S2-R22).
		bad.append("realm pins in %d forms: %s" % [forms.size(), forms])
	if screen.world.zoom == 0 and not missing.is_empty():
		bad.append("realms %s named and %s not" % [named, missing])
	var ids := boxes.keys()
	for i in ids.size():
		var a: Rect2 = boxes[ids[i]]
		if not whole.encloses(a):
			bad.append("pin %s %s off the screen" % [ids[i], a])
		for j in range(i + 1, ids.size()):
			if a.grow(UniversePins.pin_gap() - 1.0).intersects(boxes[ids[j]]):
				bad.append("pin %s %s within %.0f px of pin %s %s" % [ids[i], a, UniversePins.pin_gap(), ids[j],
					boxes[ids[j]]])
		for key: String in shown:
			if a.grow(-0.5).intersects(shown[key]):
				bad.append("pin %s %s over %s %s" % [ids[i], a, key, shown[key]])
	return bad


## AD's objections (a) and (c) on S2-R22, kept: the chosen tab's raised
## picture clear of the goal and Collect, and at 100% text the purse's three
## pills in one row. One line each that fails.
static func kept(screen: Home) -> Array[String]:
	var bad: Array[String] = []
	var tabs := screen.tabs
	if tabs != null and tabs.buttons.has(tabs.active):
		var tile := (tabs.buttons[tabs.active] as Control).find_child("Tile", true, false) as Control
		var foot := {"goal": screen.goal_card, "collect": screen.collect_button}
		if tile != null:
			for t: TextureRect in tile.find_children("*", "TextureRect", false, false):
				var at := t.get_global_rect()
				for key: String in foot:
					var c := foot[key] as Control
					if t.is_visible_in_tree() and c != null and c.is_visible_in_tree() \
							and at.grow(-1.0).intersects(c.get_global_rect()):
						bad.append("the chosen tab's picture %s over %s %s" % [at, key, c.get_global_rect()])
	if Settings.text_scale < 150:
		var rows := {}
		for k: String in screen.pills:
			var pill := screen.pills[k] as Control
			if pill.is_visible_in_tree():
				rows[roundi(pill.get_global_rect().position.y)] = k
		# From 125% text two rows where the row of three does not fit at its
		# least (S2-R44); at 100% always one.
		var most := 1
		if Settings.text_scale > 100 and not three_fit(screen):
			most = 2
		if rows.size() > most:
			bad.append("the purse in %d rows at %d%% text: %s" % [rows.size(), Settings.text_scale, rows])
	return bad


## Whether the purse's three pills could share one row: their amounts, baked
## or live, at full size or no smaller than home lets them, and the least
## gaps, within the purse's width.
static func three_fit(screen: Home) -> bool:
	var amounts: Array = []
	for k: String in UniversePurse.ORDER:
		var l := (screen.pills[k] as Control).find_child("Amount", true, false) as Label
		if l == null or not l.has_meta("points"):
			return true
		amounts.append(l)
	return HomeParts.amounts_fit_at_all(amounts, HomeParts.purse_pills(screen.pills, 3),
		HomeParts.row_room(screen.purse, 3, Home.PURSE_GAP_LEAST), Home.BAKED_LEAST, Home.AMOUNT_LEAST)


## The question the phone's back asks on home, once it shows: its Quit and
## Stay on the screen, each a whole touch target, side by side, Stay the
## primary and focused. One line each that fails.
static func asked(go_back: App.GoBack) -> Array[String]:
	var bad: Array[String] = []
	if not is_instance_valid(go_back.question):
		return ["no question"]
	var whole := Rect2(Vector2.ZERO, go_back.question.get_viewport_rect().size)
	var keys := {}
	for key: String in ["Quit", "Stay"]:
		var b := go_back.question.find_child(key, true, false) as Button
		if b == null or not b.is_visible_in_tree():
			bad.append("no %s" % key)
			continue
		keys[key] = b
		var at := b.get_global_rect()
		if not whole.grow(1.0).encloses(at):
			bad.append("%s %s off the screen" % [key, at])
		if at.size.y < UI.px(UI.CONTROL_POINTS) - 0.5 or at.size.x < UI.px(UI.CONTROL_POINTS) - 0.5:
			bad.append("%s %s under a touch target" % [key, at.size])
	if keys.size() == 2:
		var stay := keys["Stay"] as Button
		if not stay.get_meta("primary", false) or go_back.question.get_viewport().gui_get_focus_owner() != stay:
			bad.append("Stay not the primary and focused")
		if absf(stay.get_global_rect().position.y - (keys["Quit"] as Control).get_global_rect().position.y) > 1.0:
			bad.append("Quit and Stay not side by side")
	return bad
