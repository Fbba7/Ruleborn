extends SceneTree
## A menu screen on its backdrop (§21.2: "Menus stand on a night backdrop"),
## to judge the world and the interface as one picture
## (tools/render/shoot.sh). SCENE names the screen (default codex); with
## BACKDROP=1 its plain gradient is swapped for LookBackdrop.


func _initialize() -> void:
	_go()


func _go() -> void:
	root.size = Vector2i(1080, 2340)
	App.services = Fixtures.answered(Services.build(root, "", null, "user://outbox-shot.json"))
	var scene := OS.get_environment("SCENE") if OS.get_environment("SCENE") != "" else "codex"
	var screen: Control = load("res://scenes/%s.tscn" % scene).instantiate()
	root.add_child(screen)
	await process_frame
	if OS.get_environment("BACKDROP") == "1":
		LookBackdrop.dress(screen)
	await ShotKit.settle(self, screen)
	quit()
