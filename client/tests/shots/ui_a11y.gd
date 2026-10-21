extends "res://tests/run.gd"
## The accessibility tests alone, for working on the kit quickly:
## `godot --headless --path client -s res://tests/shots/ui_a11y.gd`.
## SCREENS=a,b limits them to those screens.


func _run() -> void:
	Settings.path = "user://settings-test.cfg"
	DirAccess.remove_absolute(Settings.path)
	Settings.restore()
	Settings.change(func() -> void: Settings.locale = "en")
	_services()
	var only := OS.get_environment("SCREENS")
	var screens: Array = SCREENS if only == "" else Array(only.split(","))
	await UiKitTests.new(self, check).run()
	await A11yTests.new(self, check, _mount, _control_problems, screens).run()
	print("# %d failed" % _failed)
	quit(1 if _failed > 0 else 0)
