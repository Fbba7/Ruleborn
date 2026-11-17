extends SceneTree
## The gate's flow walker (P3-AD-flow-2, docs/art/ui-quality/gate/boards/
## flow-2.md): a flow walked on the app's own router and buttons, a still at
## each step. Copy it into client/tests/shots/ to run it (it is not committed
## there), then
##
##   FLOW=result OUT=dir bash tools/render/shoot.sh client/tests/shots/flow_walk.gd dir/last.png
##
## FLOW: "result" (home's Heist tab, the heist offline on the fixture realm,
## its clock played out, the result, Home), "character" (home's Crew tab, the
## roster, a character, the character's back, the roster's Islands tab) or
## "settings" (the Keeper's plate, the menu's Settings, the access tab, one
## step larger text, Back). TEXT, LOCALE and CONTRAST as universe_home.gd.
## OUT is the folder for the stills, one per step (NN-step.png); each step
## prints the route, the scene and what the step checks.

var _out := ""
var _n := 0


func _initialize() -> void:
	_go()


func _env(k: String, d: String) -> String:
	return OS.get_environment(k) if OS.get_environment(k) != "" else d


func _go() -> void:
	_out = _env("OUT", "/tmp/flow")
	DirAccess.make_dir_recursive_absolute(_out)
	Settings.path = "user://settings-flow.cfg"
	if FileAccess.file_exists(Settings.path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(Settings.path))
	Settings.restore()
	Settings.text_scale = int(_env("TEXT", "100"))
	Settings.high_contrast = _env("CONTRAST", "") != ""
	Settings.locale = _env("LOCALE", "en")
	Settings.apply()
	Settings.save()
	App.services = Fixtures.answered(Services.build(root, "", null, "user://outbox-flow.json"))
	var store := App.services.store
	UniverseSample.fill(store, 6, 2, false)
	preload("res://tests/shots/universe_home.gd").keyframe(store)
	store.dispatch(&"roster_loaded", {"view": ShotData.roster()})
	Home._dismissed = 2
	App.services.router.go(&"home")
	await _settle(40)
	await _shot("home")
	match _env("FLOW", "result"):
		"result":
			await _result()
		"character":
			await _character()
		"settings":
			await _settings()
	print("flow done")
	quit()


func _result() -> void:
	var home := current_scene as Home
	var purse_before := _texts(home.purse)
	print("  purse before ", purse_before)
	(home.tabs.buttons["heist"] as Button).pressed.emit()
	await _settle(30)
	await _shot("heist")
	var heist := current_scene as HeistScreen
	if heist == null:
		print("  FLOW FAIL the Heist tab did not open the heist")
		return
	print("  heist playing ", heist.playing, " testing ", heist.rehearsal)
	heist.controller.land_here()
	heist.controller.advance(150)
	heist._refresh()
	await _settle(10)
	await _shot("heist-played")
	heist.finish()
	await _settle(60)
	await _shot("result")
	var verdict: Dictionary = App.services.store.get_slice(AppState.HEIST)["verdict"]
	print("  verdict ", verdict.keys())
	if not await _press(Strings.t("COMMON_HOME")):
		return
	await _settle(40)
	await _shot("home-after")
	home = current_scene as Home
	if home != null:
		print("  purse after ", _texts(home.purse))


func _character() -> void:
	var home := current_scene as Home
	(home.tabs.buttons["crew"] as Button).pressed.emit()
	await _settle(30)
	await _shot("roster")
	var roster := current_scene
	var scroll := _first_scroll(roster)
	if scroll != null:
		scroll.scroll_vertical = 400
		await _settle(5)
		print("  roster scrolled to ", scroll.scroll_vertical)
	var id := str(ShotData.roster()["characters"][1]["id"])
	App.services.router.go(&"character", {"id": id})
	await _settle(30)
	await _shot("character")
	for b: Button in current_scene.find_children("*", "Button", true, false):
		# The character's back is named for where it goes (the roster), not Back.
		var to := Strings.t("HOME_ROSTER")
		if b.is_visible_in_tree() and (b.get_meta("back", false) or b.accessibility_name == to
				or b.tooltip_text == to):
			print("  back button ", b.accessibility_name, " ", b.tooltip_text)
			b.pressed.emit()
			break
	await _settle(30)
	await _shot("roster-again")
	scroll = _first_scroll(current_scene)
	if scroll != null:
		print("  roster scroll after back ", scroll.scroll_vertical)
	var tabs: Array = current_scene.find_children("*", "KitTabs", true, false)
	if tabs.is_empty():
		print("  FLOW FAIL no tab bar on ", current_scene.name)
		return
	(tabs[0].buttons["islands"] as Button).pressed.emit()
	await _settle(40)
	await _shot("home-after")


func _settings() -> void:
	var home := current_scene as Home
	home.keeper_plate.pressed.emit()
	await _settle(10)
	await _shot("menu")
	home.menu.picked.emit(&"settings")
	await _settle(30)
	await _shot("settings")
	var screen := current_scene
	screen.tab_shown = "access"
	screen._build()
	await _settle(10)
	await _shot("settings-access")
	var before := Settings.text_scale
	screen.text_step(1)
	await _settle(10)
	await _shot("settings-larger")
	print("  text ", before, " -> ", Settings.text_scale)
	if not await _press(Strings.t("SCREEN_BACK")):
		return
	await _settle(40)
	await _shot("home-after")
	print("  home text ", Settings.text_scale, " tab kept ", "n/a")
	home = current_scene as Home
	if home != null:
		home.keeper_plate.pressed.emit()
		await _settle(5)
		home.menu.picked.emit(&"settings")
		await _settle(30)
		print("  settings opens on ", current_scene.tab_shown)
		await _shot("settings-again")


## Frames for the screen to settle: its scene changed, laid out, animated.
func _settle(frames: int) -> void:
	for i in frames:
		await process_frame


func _shot(step: String) -> void:
	await RenderingServer.frame_post_draw
	_n += 1
	var file := "%s/%02d-%s.png" % [_out, _n, step]
	root.get_texture().get_image().save_png(file)
	var scene: String = str(current_scene.name) if current_scene != null else "none"
	print("step %02d %s route=%s scene=%s" % [_n, step, App.services.router.current(), scene])


## Presses the visible button that says `words`, as a tap would.
func _press(words: String) -> bool:
	for b: Button in current_scene.find_children("*", "Button", true, false):
		if b.is_visible_in_tree() and (b.text == words or b.accessibility_name == words
				or words in _texts(b)):
			print("  press ", words)
			b.pressed.emit()
			return true
	print("  FLOW FAIL no button '", words, "' on ", current_scene.name)
	for b: Button in current_scene.find_children("*", "Button", true, false):
		if b.is_visible_in_tree():
			print("    button '", b.text, "' ", _texts(b))
	return false


static func _texts(n: Node) -> Array[String]:
	var out: Array[String] = []
	if n == null:
		return out
	for l: Label in n.find_children("*", "Label", true, false):
		if l.is_visible_in_tree() and l.text != "":
			out.append(l.text)
	return out


static func _first_scroll(n: Node) -> ScrollContainer:
	for s: ScrollContainer in n.find_children("*", "ScrollContainer", true, false):
		if s.is_visible_in_tree():
			return s
	return null
