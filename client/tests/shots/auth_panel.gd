extends SceneTree
## The account panel on Settings' Account tab, on a phone's frame
## (tools/render/shoot.sh). STATE picks what it shows: "signed_in" (three
## devices, Google linked; the default), "linkable" (one device, Google
## offered), "confirm" (the sign out everywhere dialog, one heist waiting),
## "device" (signing out another device asks first), "signed_out" (one
## heist parked) or "failed". SHOT is the file.


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
	if state in ["signed_in", "linkable", "confirm", "device"]:
		s.api.token = "shot"
		s.store.dispatch(&"signed_in", {"account": "shot"})
		s.store.dispatch(&"auth_status", {"status": "signed_in"})
	var screen: SettingsScreen = (load("res://scenes/settings.tscn") as PackedScene).instantiate()
	screen.tab_shown = "account"
	root.add_child(screen)
	for _i: int in 3:
		await process_frame
	var panel: AuthPanel = screen.find_child("AuthPanel", true, false)
	match state:
		"signed_in", "confirm", "device":
			s.store.dispatch(&"auth_devices", {"devices": 3, "list": [
				{"id": 7, "current": true, "via": "gc", "device": "iphone", "model": "iPhone 15", "place": "PT",
					"idleHours": 0},
				{"id": 5, "current": false, "via": "gc", "device": "ipad", "model": "iPad Air", "place": "PT",
					"idleHours": 26},
				{"id": 3, "current": false, "via": "gp", "device": "android_phone", "model": "Pixel 8", "place": "ES",
					"idleHours": 5 * 24 + 3}],
				"identities": [{"platform": "gc", "primary": true, "linkedAt": null},
					{"platform": "gp", "primary": false, "linkedAt": 0}], "platforms": ["gc", "gp"]})
			if state == "confirm":
				panel.ask(true, 1)
			elif state == "device":
				panel.ask_change("device", 3, "Pixel 8")
		"linkable":
			s.store.dispatch(&"auth_devices", {"devices": 1, "list": [
				{"id": 7, "current": true, "via": "gc", "device": "iphone", "model": "iPhone 15", "place": "PT",
					"idleHours": 0}],
				"identities": [{"platform": "gc", "primary": true, "linkedAt": null}], "platforms": ["gc", "gp"]})
		"signed_out":
			s.store.dispatch(&"auth_status", {"status": "signed_out", "parked": 1, "owed": false})
		"failed":
			s.store.dispatch(&"auth_status", {"status": "failed", "reason": "platform_identity_refused"})
	await ShotKit.settle(self, screen)
	print("wrote ", state)
	quit()
