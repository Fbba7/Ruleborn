extends "res://tests/run.gd"
## The kit's tests alone (tests/ui_kit_tests.gd): a quick check outside the
## whole run.


func _run() -> void:
	Settings.path = "user://settings-test.cfg"
	DirAccess.remove_absolute(Settings.path)
	Settings.restore()
	Settings.change(func() -> void: Settings.locale = "en")
	_services()
	_seed()
	await UiKitTests.new(self, check).run()
	quit()
