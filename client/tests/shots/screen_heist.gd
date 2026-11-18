extends SceneTree
## The heist screen at a moment of a rehearsal on WorldTests' island
## (tools/render/shoot.sh). SHOT is the file; MOMENT picks the moment:
## "start" (just landed, the first orders given), "sneak" (the crew spread, a
## guard looking), "vault" (the crew at the Vault, cracking), "alarm" (a
## guard alerted, the alarm up), "pick" (the landing picker, before landing),
## "cross" (the swoop to another realm, at its middle), "escape" (Get out,
## the skiff called to the edge), "entry" (a realm's entry card), "hold" (the gait menu
## a held press opens). HOUR and ZOOM are optional; BUTTONS shows
## Settings' turn and zoom buttons, CONTRAST high contrast, LEFT left-handed
## play, TEXT a text size (150, 200), NAMES the names a long press shows,
## MANIFEST the design's planned crew of five with a Sage and a cast, and
## ESTIMATE a target card's rough loot estimate, FRAME_H the frame's height (1920 for
## 9:16), WHEEL "sage" or "cast" a
## wheel open. M26's fixture states: CREW a crew of 1 to 5 with MANIFEST
## (the plan's first CREW members), LONG the longest names the word list
## gives in the locale (server/src/words.json, adjective and noun, the widest
## five by letters), END the clock played on to its last seconds (red).

const LawShot := preload("res://tests/shots/law_heist.gd")
const TO := {"hold": [[4, 9], [3, 10], [4, 11]], "entry": [], "escape": [[2, 10], [3, 10], [2, 11]],
	"cross": [[4, 9], [3, 10], [4, 11]], "sneak": [[4, 9], [3, 10], [4, 11]], "vault": [[6, 10], [5, 10], [7, 10]],
	"alarm": [[5, 6], [3, 10], [4, 11]], "start": [[7, 8], [2, 10], [1, 10]]}
## The longest crew names each locale's word list makes (SocialPresenter.
## word_name over server/src/words.json): the five longest, each its own noun.
const LONGEST := {
	"en": ["Whispering Sanctuary", "Whispering Waterfall", "Whispering Crossing", "Whispering Fountain",
		"Whispering Mountain"],
	"pt_BR": ["Biblioteca Tempestuosa", "Santuário Sussurrante", "Travessia Sussurrante", "Labirinto Tempestuoso",
		"Fortaleza Sussurrante"],
	"de": ["Bernsteinfarbenes Leuchtfeuer", "Bernsteinfarbener Obstgarten", "Bernsteinfarbener Wasserfall",
		"Bernsteinfarbenes Labyrinth", "Bernsteinfarbene Bibliothek"],
}
const TICKS := {"hold": 150, "entry": 20, "escape": 120, "cross": 60, "start": 30, "sneak": 150, "vault": 300,
	"alarm": 150}


func _initialize() -> void:
	_go()


func _go() -> void:
	cast()
	WorldView.heist_perspective = OS.get_environment("ORTHO") == ""
	# A phone's frame of its own, so the still is 1080 by 2340 whatever the
	# window does.
	var frame := SubViewport.new()
	frame.size = Vector2i(1080, int(OS.get_environment("FRAME_H")) if OS.get_environment("FRAME_H") != "" else 2340)
	frame.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(frame)
	App.services = Fixtures.answered(Services.build(frame, "", null, "user://outbox-shot.json"))
	# The kit's layers on before the screen is built, as the app has them by
	# the time it opens the heist (AD-R55: the world's marker layer is lifted
	# with them, so the still shows the order the player sees).
	UI.root_theme()
	if OS.get_environment("LOCALE") != "":
		Strings.set_locale(OS.get_environment("LOCALE"))
	if OS.get_environment("TEXT") != "":
		Settings.text_scale = int(OS.get_environment("TEXT"))
		Settings.apply()
	Settings.camera_buttons = OS.get_environment("BUTTONS") != ""
	Settings.high_contrast = OS.get_environment("CONTRAST") != ""
	Settings.left_handed = OS.get_environment("LEFT") != ""
	Settings.text_scale = int(OS.get_environment("TEXT")) if OS.get_environment("TEXT") != "" else 100
	Settings.apply()
	var island := WorldTests.island()
	if OS.get_environment("LAWS") != "":
		# LAWS: these laws woven into law_heist's dressed island instead.
		island = LawShot.island(Array(OS.get_environment("LAWS").split(",")))
	App.services.store.dispatch(&"heist_started", {"island": island, "testing": true})
	var screen: HeistScreen = load("res://scenes/heist_screen.tscn").instantiate()
	frame.add_child(screen)
	await process_frame
	if OS.get_environment("MANIFEST") != "":
		# MANIFEST: the design's planned crew of five, each its own kind, with
		# the Archivist and one cast, named as the design names them.
		var law := Array(RulebornStability.law_ids()).find("glowing_dark")
		var plan := PackedByteArray()
		var size := clampi(int(OS.get_environment("CREW")), 1, 5) if OS.get_environment("CREW") != "" else 5
		for k: int in ([1, 6, 4, 3, 9] as Array).slice(0, size):
			plan.append_array(PackedByteArray([k, 0, 3, 0]))
		plan.append_array(PackedByteArray([1, 1, law]))
		screen.names_given = ["Pip", "Mo", "Bramble", "Hollow", "Ash"].slice(0, size)
		screen.begin(HeistController.SEED, HeistController.TICKS, size, island, "", plan)
		# ESTIMATE: the target card's rough loot estimate (§12.4).
		if OS.get_environment("ESTIMATE") != "":
			screen.hud.estimate = int(OS.get_environment("ESTIMATE"))
		screen.controller.load_target = 80
	if OS.get_environment("LONG") != "":
		var longest: Array = LONGEST.get(TranslationServer.get_locale(), LONGEST["en"])
		screen.names_given = longest.slice(0, screen.controller.world.crew().size())
		# The portraits are drawn again with these names at the next refresh.
		screen._crew_key = ""
	var view := screen.view
	view.set_sky_hour(int(OS.get_environment("HOUR")) if OS.get_environment("HOUR") != "" else 12)
	var moment := OS.get_environment("MOMENT") if OS.get_environment("MOMENT") != "" else "sneak"
	if moment == "pick":
		# §5.4's landing picker, before the crew lands.
		screen.set_process(false)
		screen._refresh()
		for i in 8:
			await process_frame
		await RenderingServer.frame_post_draw
		frame.get_texture().get_image().save_png(OS.get_environment("SHOT"))
		quit()
		return
	screen.controller.land_here()
	var to: Array = TO.get(moment, [])
	for i in to.size():
		var t: Array = to[i]
		screen.controller.world.give(i, HeistController.Kind.MOVE_TO, int(t[0]) * 256 + 128, int(t[1]) * 256 + 128)
	var total: int = TICKS.get(moment, 160)
	# Played in steps, so the screen sees each moment as the player would.
	for k in total / 10:
		screen.controller.advance(10)
		screen._refresh()
		view._process(1.0 / 3.0)
	if moment == "alarm":
		# The alarm up (board 1's objection E): it climbs a level each thirty
		# seconds (§12.17), so the heist plays on until it stands at ALARM (3 if
		# unset); then Pip steps toward the nearest guard for a second, so a
		# guard is turning to look, without the crew being caught.
		var world := screen.controller.world
		var want := int(OS.get_environment("ALARM")) if OS.get_environment("ALARM") != "" else 3
		for k in 400:
			if world.alarm() >= want:
				break
			screen.controller.advance(10)
			screen._refresh()
			view._process(1.0 / 3.0)
		var me: Vector2 = world.crew()[0]["at"]
		var near := Vector2(-1, -1)
		for g: Dictionary in world.guards():
			if not g["down"] and (near.x < 0 or me.distance_to(g["at"]) < me.distance_to(near)):
				near = g["at"]
		if near.x >= 0:
			world.give(0, HeistController.Kind.MOVE_TO, int(near.x * 256.0), int(near.y * 256.0))
		for k in 3:
			screen.controller.advance(10)
			screen._refresh()
			view._process(1.0 / 3.0)
		print("alarm ", world.alarm())
	if moment == "vault":
		screen.controller.select(0)
		screen.controller.tap_tile(screen.controller.world.vault()["at"])
		for k in 4:
			screen.controller.advance(10)
			screen._refresh()
			view._process(1.0 / 3.0)
	if moment == "escape":
		# Get out, and the skiff called to the south-west edge.
		screen.controller.get_out()
		screen.controller.tap_tile(Vector2i(1, 11))
		for k in 4:
			screen.controller.advance(10)
			screen._refresh()
			view._process(1.0 / 3.0)
	if OS.get_environment("END") != "":
		# END: the clock played on to its last seconds, where it turns red
		# (§21.8), stopped short of running out.
		var r := screen.controller.world
		var tps := RulebornReplay.ticks_per_second()
		while r.ticks() - r.tick() > 12 * tps:
			screen.controller.advance(10)
		screen._refresh()
		view._process(1.0 / 3.0)
		print("left ", (r.ticks() - r.tick()) / tps)
	if moment == "hold":
		# A held press on the ground: the gait menu at the finger.
		screen.open_gait_menu(view.screen_at(Vector2i(5, 8)))
	if moment == "entry":
		# §15.3's banner as the crew comes into a realm.
		screen.entry_card(HeistHud.realm(0, 0))
		# The still is taken at its full showing, past the fade in.
		screen.card.modulate.a = 1.0
		screen.card.set_process(false)
		for t in screen.get_tree().get_processed_tweens():
			t.pause()
	if moment == "cross":
		# §21.1's swoop between realms, caught at its middle.
		view.swoop()
		view._process(0.45)
		view.set_process(false)
	# The landing's drop from the whole realm is long over by the moment shot.
	view.set_zoom(int(OS.get_environment("ZOOM")) if OS.get_environment("ZOOM") != "" else 1)
	if OS.get_environment("NAMES") != "":
		# A long press: every crew member's name over its head.
		view.anchors.names_for = 60.0
	settle(root)
	screen.set_process(false)
	screen._refresh()
	# Portraits rendered from the models fill in over a few frames.
	for i in 40:
		await process_frame
	# Each guard's last words as they were said, which a heist's seconds
	# played in a few frames would have let fade.
	var guards := screen.controller.world.guards()
	for i in guards.size():
		if not guards[i]["down"]:
			view.anchors.say(i, str(guards[i]["state"]))
			view.anchors.speech.get(i, {})["t"] = 0.6
			# POP: a blow's number rising from each speaking guard, to judge
			# the two side by side.
			if OS.get_environment("POP") != "":
				view.anchors.pop(view._guards[i].position + Vector3(0, 1.0, 0), "-12", FxSkin.ALARM)
				view.anchors.pops[-1]["t"] = 0.25
	# WHEEL: the Sage's ("sage") or the casts' ("cast") wheel open (§12.7).
	if OS.get_environment("WHEEL") == "sage":
		screen.hand._open_sage()
	elif OS.get_environment("WHEEL") == "cast":
		screen.hand._open_casts()
	elif OS.get_environment("WHEEL") == "aim":
		# A cast chosen and waiting for its place on the world.
		screen._aim(HeistController.Kind.CAST, 0, "Glowing dark")
	await process_frame
	# HIDE: parts of the screen left out, to weigh each one's draw calls.
	for part: String in OS.get_environment("HIDE").split(",", false):
		(screen.get(part) as CanvasItem).visible = false
	await process_frame
	await RenderingServer.frame_post_draw
	if OS.get_environment("SIZES") != "":
		print("row ", screen.crew_node.size, " band ", screen.actions_band.size, " hand ", screen.hand.size,
			" frame ", frame.size, " screen ", screen.size, " ", screen.crew_buttons.map(func(b: Control) -> Vector2:
				return b.size), " hint ", screen.hint_label.size, " lines ", screen.hint_label.get_line_count(),
			" wants ", screen.hint_label.get_theme_font("font").get_string_size(screen.hint_label.text,
				HORIZONTAL_ALIGNMENT_LEFT, -1, screen.hint_label.get_theme_font_size("font_size")).x)
		print("hud ", screen.hud.get_global_rect(), " loot ", screen.hud.loot_panel.get_global_rect(),
			" tray ", screen.actions_band.get_global_rect(), " tip ",
			screen.hint_panel.get_global_rect() if screen.hint_panel.is_visible_in_tree() else Rect2())
		# PORTRAITS=dir: each portrait as drawn and its figure, to look at.
		var keep := OS.get_environment("PORTRAITS")
		if keep != "":
			for b: FxPortrait in screen.crew_buttons:
				if b.picture != null:
					b.picture.get_image().save_png(keep.path_join(b.letters + ".png"))
					b.figure().get_image().save_png(keep.path_join(b.letters + "-figure.png"))
		# Board 1's objection D: each portrait's figure and disc, in L*.
		for b: FxPortrait in screen.crew_buttons:
			for key: String in FxPortrait.measured:
				if key.begins_with(b.kind + "/"):
					print("portrait ", b.letters, " ", key, " ", FxPortrait.measured[key])
	if OS.get_environment("FIT") != "":
		# FIT: board 1's objection B as a check, at whatever TEXT and LOCALE
		# say; the run fails if anything does not fit.
		var bad := fit(screen)
		for b: String in bad:
			print("fit FAIL ", b)
		print("fit ", "ok" if bad.is_empty() else "FAIL")
		if not bad.is_empty():
			quit(1)
			return
	# §21.3's budgets, as the renderer counted the frame.
	print("budget: %d draw calls, %d primitives" % [
		RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_DRAW_CALLS_IN_FRAME),
		RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_PRIMITIVES_IN_FRAME)])
	frame.get_texture().get_image().save_png(OS.get_environment("SHOT"))
	print("wrote")
	quit()


## What does not fit on `screen`, one line each (board 1's objection B):
## a label's words wider than the label, or the label outside its panel; a
## HUD panel over another or over the crew's tray; a guard's bubble off the
## screen, over a panel, or drawn below the panels.
static func fit(screen: HeistScreen) -> Array[String]:
	var bad: Array[String] = []
	var whole := Rect2(Vector2.ZERO, screen.size)
	for root: Control in [screen.hud, screen.actions_band, screen.hint_panel]:
		for l: Label in root.find_children("*", "Label", true, false):
			if not l.is_visible_in_tree() or l.text == "":
				continue
			var at := l.get_global_rect()
			var font := l.get_theme_font("font")
			# A label broken by hand stands on its lines; its widest one is what
			# has to fit.
			var wide := 0.0
			for line: String in l.text.split("\n"):
				wide = maxf(wide, font.get_string_size(line, HORIZONTAL_ALIGNMENT_LEFT, -1,
					l.get_theme_font_size("font_size")).x)
			if l.autowrap_mode == TextServer.AUTOWRAP_OFF and wide > at.size.x + 1.0:
				bad.append("%s %s: %.0f px of words in %.0f" % [l.get_path(), l.text, wide, at.size.x])
			var p := l.get_parent()
			while p != null and not p is PanelContainer:
				p = p.get_parent()
			if p != null and not (p as Control).get_global_rect().grow(1.0).encloses(at):
				bad.append("%s %s: %s outside its panel %s" % [l.get_path(), l.text, at,
					(p as Control).get_global_rect()])
			if not whole.grow(1.0).encloses(at):
				bad.append("%s %s: %s off the screen" % [l.get_path(), l.text, at])
	var hud: Array[Control] = [screen.hud.clock_panel, screen.hud.alarm_panel, screen.hud.loot_panel]
	for c in screen.hud.laws_box.get_children():
		hud.append(c as Control)
	var tray := screen.actions_band.get_global_rect()
	for i in hud.size():
		if not hud[i].is_visible_in_tree():
			continue
		var a := hud[i].get_global_rect()
		if a.intersects(tray):
			bad.append("%s %s over the tray %s" % [hud[i].name, a, tray])
		for j in range(i + 1, hud.size()):
			if hud[j].is_visible_in_tree() and a.intersects(hud[j].get_global_rect()):
				bad.append("%s over %s" % [hud[i].name, hud[j].name])
	var anchors := screen.view.anchors
	var layer := anchors.speech_layer
	var top: Node = screen.actions_band
	while top.get_parent() != screen:
		top = top.get_parent()
	if layer == null or layer.get_parent() != screen or layer.get_index() < top.get_index():
		bad.append("the guards' words are drawn below the panels")
	# A bubble may lie over a panel's edge where the world shows no room for
	# it (it is drawn above the panels), but never over a panel's words (as
	# their lines stand) nor a portrait with its name and tag.
	var words: Array[Rect2] = []
	for root: Control in [screen.hud, screen.actions_band, screen.hint_panel]:
		for l: Label in root.find_children("*", "Label", true, false):
			if l.is_visible_in_tree() and l.text != "":
				words.append(FxAnchors.words_rect(l))
	for b: FxPortrait in screen.crew_buttons:
		if b.is_visible_in_tree():
			words.append(b.drawn_rect())
	for box: Rect2 in anchors.speech_boxes:
		var on := Rect2(box.position + layer.global_position, box.size)
		if not whole.encloses(on):
			bad.append("a bubble %s off the screen" % on)
		for r: Rect2 in words:
			if on.intersects(r):
				bad.append("a bubble %s over words %s" % [on, r])
	return bad


## The integrator's cast of character models, until the app sets one: each
## role's default kind, guards as Glass Golems in the guard form (CAST).
static func cast() -> void:
	if WorldView.figure_maker.is_valid() or OS.get_environment("CAST") == "":
		return
	var kinds := {"Scout": &"featherkin", "Breaker": &"rambler", "Carrier": &"skyskipper", "Warden": &"mossbear",
		"Mender": &"hourkeeper", "guard": &"glassgolem"}
	WorldView.figure_maker = func(role: String, _height: float) -> Node3D:
		var c := CreatureModel.make(kinds.get(role, &"featherkin"))
		if c != null and role == "guard":
			c.set_guard(true)
		return c


## Let each character model's clip play on as it would have in real time,
## since a shot runs a heist's seconds in a few frames.
func settle(node: Node) -> void:
	for c in node.find_children("*", "CreatureModel", true, false):
		var p: AnimationPlayer = (c as CreatureModel).player()
		if p != null:
			p.advance(2.0)
