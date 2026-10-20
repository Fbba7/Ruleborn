extends SceneTree
## LawFx's tests alone, quickly, outside the whole run (tests/run.gd runs
## them too): `godot --headless --path client -s res://tests/shots/law_run_tests.gd`.


func _initialize() -> void:
	_go()


func _go() -> void:
	var say := func(n: String, ok: bool, d := "") -> void: print("ok " if ok else "NOT OK ", n, " ", d)
	await LawFxTests.new(self, say).run()
	quit()
