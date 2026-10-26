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
	if OS.get_environment("LAYOUT") != "":
		await _layout(screens)
	print("# %d failed" % _failed)
	quit(1 if _failed > 0 else 0)


## run.gd's layout sweep (§21.1) at both aspects and in every language.
func _layout(screens: Array) -> void:
	for aspect: Array in [[9, 19.5], [9, 16]]:
		root.size = Vector2i(540, int(540 * aspect[1] / aspect[0]))
		var problems := []
		for locale: String in Strings.LOCALES:
			Strings.set_locale(locale)
			for sname: String in screens:
				var screen: Control = await _mount(sname)
				screen.set_process(false)
				await process_frame
				await process_frame
				for p: Variant in _control_problems(screen):
					problems.append("%s %s: %s" % [locale, sname, p])
				screen.queue_free()
		check("every control on every screen is 48 points or more, in the lower two-thirds, clear of corners and "
				+ "safe areas (§21.1), at %s:%s" % aspect, problems.is_empty(), "; ".join(problems))
	Strings.set_locale("en")
