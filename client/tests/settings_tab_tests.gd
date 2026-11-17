class_name SettingsTabTests
extends RefCounted
## AD-R52 (flow board 2's F6): settings reopens on the tab last shown in the
## session, through the router as a player's moves open it. The tab is held
## in memory only (SettingsScreen.last_tab), never in Settings' file, so a
## fresh start opens on game. Here, not in run.gd, which stands at gdlint's
## 1000 lines; run.gd calls it in one line.

var tree: SceneTree
var check: Callable


func _init(t: SceneTree, c: Callable) -> void:
	tree = t
	check = c


## Opens settings, shows access, leaves to home, opens settings again and
## reads the tab shown; the same for account.
func run() -> void:
	var router := App.services.router
	var was := router.change
	router.change = func(path: String) -> void: tree.change_scene_to_file(path)
	await _go(&"settings")
	var seen: Array = [_shown()]
	var misses: Array[String] = []
	for key: String in ["access", "account"]:
		var tabs := tree.current_scene.find_children("*", "Button", true, false).filter(func(b: Button) -> bool:
			return b.get_meta("setting", "") == "tab_" + key)
		if tabs.size() != 1:
			misses.append("%d %s tabs" % [tabs.size(), key])
			continue
		(tabs[0] as Button).pressed.emit()
		await tree.process_frame
		await _go(&"home")
		if tree.current_scene is SettingsScreen:
			misses.append("still on settings after going home")
		await _go(&"settings")
		seen.append(_shown())
	var file := FileAccess.get_file_as_string(Settings.path) if FileAccess.file_exists(Settings.path) else ""
	check.call("AD-R52: through the router, settings opens first on game, then again on the tab last shown in "
		+ "the session (access, account), its rows shown, and the tab is not in Settings' file",
		misses.is_empty() and seen == ["game", "access", "account"] and not file.contains("tab"),
		"opened on %s; %s; file: %s" % [seen, "; ".join(misses), file.replace("\n", " ")])
	SettingsScreen.last_tab = "game"
	tree.unload_current_scene()
	await tree.process_frame
	router.change = was


## Goes to `route` and lets its scene settle.
func _go(route: StringName) -> void:
	App.services.router.go(route)
	await tree.create_timer(0.4).timeout
	await tree.process_frame


## The settings tab whose rows are on show, or what is shown instead.
func _shown() -> String:
	var screen := tree.current_scene as SettingsScreen
	if screen == null:
		return "no settings"
	var rows := screen.find_child("Tab" + screen.tab_shown.capitalize(), true, false) as Control
	return screen.tab_shown if rows != null and rows.is_visible_in_tree() else screen.tab_shown + " (hidden)"
