extends SceneTree
## The account panel on a phone's frame (tools/render/shoot.sh). STATE picks
## what it shows: "signed_in" (on two devices, the default), "confirm" (the
## sign out everywhere dialog, one heist waiting), "signed_out" (one heist
## parked) or "failed". SHOT is the file.


func _initialize() -> void:
	_go()


func _go() -> void:
	root.size = Vector2i(1080, 2340)
	Settings.path = "user://settings-shot.cfg"
	Settings.restore()
	Settings.locale = "en"
	Settings.apply()
	App.services = Fixtures.answered(Services.build(root, "", null, "user://outbox-shot-auth.json"))
	var state := OS.get_environment("STATE") if OS.get_environment("STATE") != "" else "signed_in"
	var s := App.services
	if state in ["signed_in", "confirm"]:
		s.api.token = "shot"
		s.store.dispatch(&"signed_in", {"account": "shot"})
	var screen := Control.new()
	screen.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(screen)
	var column := UI.frame(screen)
	column.add_child(UI.title(Strings.t("SETTINGS_TITLE")))
	var panel := AuthPanel.new()
	column.add_child(panel)
	for _i: int in 3:
		await process_frame
	match state:
		"signed_in":
			s.store.dispatch(&"auth_devices", {"devices": 2})
		"confirm":
			s.store.dispatch(&"auth_devices", {"devices": 2})
			panel.ask(true, 1)
		"signed_out":
			s.store.dispatch(&"auth_status", {"status": "signed_out", "parked": 1, "owed": false})
		"failed":
			s.store.dispatch(&"auth_status", {"status": "failed", "reason": "platform_identity_refused"})
	await ShotKit.settle(self, screen)
	print("wrote ", state)
	quit()
