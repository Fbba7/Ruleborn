class_name SecurityTests
extends RefCounted
## The game's files on the phone are data, and the session's tokens go to the
## configured server only (security finding SEC-30): a settings file that
## names an object builds none, the settings the game writes still read back,
## a queued request whose route names another host is dropped, and the API
## sends no path that could move the URL to another host.

## The file a script planted in the settings would write if it ran.
const RAN := "user://security-test-ran.txt"

var tree: SceneTree
var check: Callable


func _init(t: SceneTree, c: Callable) -> void:
	tree = t
	check = c


func run() -> void:
	var kept := Settings.path
	_settings_build_nothing()
	_settings_read_back()
	Settings.path = kept
	Settings.read_file()
	_outbox_keeps_its_own_routes()
	await _api_sends_to_its_server_only()


func _write(path: String, text: String) -> void:
	var f := FileAccess.open(path, FileAccess.WRITE)
	f.store_string(text)
	f.close()


func _settings_build_nothing() -> void:
	Settings.path = "user://settings-security-test.cfg"
	DirAccess.remove_absolute(RAN)
	var source := "extends RefCounted\nfunc _init() -> void:\n\tvar f := FileAccess.open(\"%s\", FileAccess.WRITE)\n" % RAN \
		+ "\tf.store_string(\"ran\")\n"
	_write(Settings.path, "[general]\n\nlocale=Object(RefCounted,\"script\":Object(GDScript,\"script/source\":\"%s\"))\n"
		% source.c_escape() + "\n[volume]\n\nmusic=3\n\n[access]\n\ntext_scale=Object(RefCounted,\"script\":null)\n")
	Settings.read_file()
	var ran := FileAccess.file_exists(RAN)
	check.call("a settings file that names an object builds none and runs no script: the value is skipped, "
			+ "the setting is its default, and the plain values beside it still count (SEC-30)",
		not ran and Settings.locale in Strings.LOCALES and Settings.text_scale == 100 and int(Settings.volume["music"]) == 3,
		"ran %s, locale %s, text %s, music %s" % [ran, Settings.locale, Settings.text_scale, Settings.volume["music"]])
	DirAccess.remove_absolute(RAN)
	DirAccess.remove_absolute(Settings.path)


## What `save` writes, `read_file` reads back the same, every kind of value.
func _settings_read_back() -> void:
	Settings.path = "user://settings-security-test.cfg"
	DirAccess.remove_absolute(Settings.path)
	var steps := Settings.text_steps()
	var holds := Settings.hold_steps()
	Settings.locale = "pt_BR"
	Settings.volume = {"music": 0, "effects": 4, "alerts": 10}
	Settings.reduced_motion = true
	Settings.haptics = false
	Settings.text_scale = steps[steps.size() - 1]
	Settings.high_contrast = true
	Settings.hold_ms = holds[0]
	Settings.left_handed = true
	Settings.slow_rehearsals = true
	Settings.banners_stay = true
	Settings.camera_buttons = true
	Settings.save()
	Settings.locale = "en"
	Settings.volume = Settings.DEFAULT_VOLUME.duplicate()
	for flag: String in ["reduced_motion", "high_contrast", "left_handed", "slow_rehearsals", "banners_stay",
			"camera_buttons"]:
		Settings.set_flag(flag, false)
	Settings.haptics = true
	Settings.text_scale = 100
	Settings.hold_ms = Settings.hold_default()
	Settings.read_file()
	var flags: Array[bool] = []
	for flag: String in ["reduced_motion", "high_contrast", "left_handed", "slow_rehearsals", "banners_stay",
			"camera_buttons"]:
		flags.append(Settings.flag(flag))
	check.call("the settings the game saves read back as they were: the language, each volume, every switch, "
			+ "the text size and the hold time",
		Settings.locale == "pt_BR" and Settings.volume == {"music": 0, "effects": 4, "alerts": 10}
			and not Settings.haptics and flags.size() == 6 and not flags.has(false)
			and Settings.text_scale == steps[steps.size() - 1] and Settings.hold_ms == holds[0],
		"%s %s %s %s %s %s" % [Settings.locale, Settings.volume, Settings.haptics, flags, Settings.text_scale,
			Settings.hold_ms])
	Settings.locale = "en"
	DirAccess.remove_absolute(Settings.path)


func _outbox_keeps_its_own_routes() -> void:
	var path := "user://outbox-security-test.json"
	var items := []
	for route: String in ["@example.invalid/v1/x", "/v1@example.invalid/x", "//example.invalid/v1/x",
			"/v1//example.invalid", "https://example.invalid/v1/x", "/v1/heists/ab\nHost: x",
			"/v1/heists/0a1b2c", "/v1/heists/0a1b2c?crew=1,2", "/v1/workshop/plays/0a1b", "/v1/shop/receipts",
			"/v1/offline"]:
		items.append({"key": route, "route": route, "body": "", "json": false})
	_write(path, JSON.stringify(items))
	var outbox := Outbox.new(path)
	check.call("a queued request whose route could name another host is dropped as the queue is read; the "
			+ "game's own routes, a crew's query among them, are kept (SEC-30)",
		outbox.pending() == 5 and outbox.has("/v1/heists/0a1b2c?crew=1,2") and outbox.has("/v1/offline")
			and outbox.has("/v1/shop/receipts") and not outbox.has("@example.invalid/v1/x"),
		str(outbox.pending()))
	DirAccess.remove_absolute(path)


func _api_sends_to_its_server_only() -> void:
	var transport := FakeTransport.new()
	transport.on("GET /v1/balance", {"starlight": 1})
	var api := Api.new(transport, "https://edge.example", ActionLog.new())
	api.token = "TOKEN-SECRET"
	var refused: Array[String] = []
	for path: String in ["@example.invalid/x", "/v1@example.invalid/x", "/v1//example.invalid/x", "x/v1/balance"]:
		var r := await api.raw(HTTPClient.METHOD_GET, path)
		refused.append(r.code)
	var asked := transport.calls.size()
	var fine := await api.get_json("/v1/balance")
	check.call("the API sends a path that could move the URL to another host nowhere, and the session's token "
			+ "with it; its own routes go as before (SEC-30)",
		asked == 0 and refused == ["bad_route", "bad_route", "bad_route", "bad_route"] and fine.ok
			and transport.calls.size() == 1,
		"%s calls, %s, %s" % [asked, refused, fine])
