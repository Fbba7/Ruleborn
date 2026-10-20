extends "res://tests/run.gd"
## The accessibility tests alone (tests/a11y_tests.gd), for the screens the
## law previews sit on: a quick check outside the whole run.


func _run() -> void:
	Settings.path = "user://settings-test.cfg"
	DirAccess.remove_absolute(Settings.path)
	Settings.restore()
	Settings.change(func() -> void: Settings.locale = "en")
	_services()
	_seed()
	await A11yTests.new(self, check, _mount, _control_problems, ["law", "harmony", "weaving"]).run()
	quit()
