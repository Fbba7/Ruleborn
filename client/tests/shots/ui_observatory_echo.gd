extends SceneTree
## The Observatory turned to its echo's card, whose corner ribbon is a pill
## in `round_violet`: a wide host of the skin `disc`, which keeps its
## code-drawn box (kit-spec.md section 8.2). tools/render/shoot.sh; HC and
## TEXT as ShotKit reads them.


func _initialize() -> void:
	_go()


func _go() -> void:
	root.size = Vector2i(1080, 2340)
	ShotKit.prepare()
	App.services = Fixtures.answered(Services.build(root, "", null, "user://outbox-shot.json"))
	var screen: Control = load("res://scenes/observatory.tscn").instantiate()
	root.add_child(screen)
	await process_frame
	App.services.store.dispatch(&"observatory_loaded", {"view": ObservatoryTests.sample()})
	for i: int in 40:
		await process_frame
	var found := false
	for page: int in 8:
		screen.call("_show_page", page)
		for i: int in 4:
			await process_frame
		for n: Node in screen.find_children("*", "RbBox", true, false):
			var box := n as RbBox
			if box.look == "round_violet" and box.is_visible_in_tree():
				var host := box.get_parent() as Control
				print("echo ribbon: page %d, host %d by %d, %s" % [page, host.size.x, host.size.y,
					"its code-drawn box" if box.piece().is_empty() else "a sprite"])
				found = true
		if found:
			break
	if not found:
		print("echo ribbon: not found")
	await ShotKit.settle(self, screen)
	quit()
