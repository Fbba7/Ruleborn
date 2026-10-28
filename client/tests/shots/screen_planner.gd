extends SceneTree
## The planner on a target across a universe, a fault open in its second
## outer realm (tools/render/shoot.sh).
func _initialize() -> void:
	_go()


func _go() -> void:
	root.size = Vector2i(1080, 2340)
	ShotKit.prepare()
	App.services = Fixtures.answered(Services.build(root, "", null, "user://outbox-shot.json"))
	var d := PlannerTests.slices()
	var card: Dictionary = d["planner"]["target"]
	card.merge({"across": true, "clock": 165, "clock_longest": 180, "depth": 2, "fault_realms": ["outer-2"]}, true)
	var store := App.services.store
	store.dispatch(&"keeper_loaded", {"view": d["keeper"]["view"]})
	store.dispatch(&"roster_loaded", {"view": d["roster"]["view"]})
	store.dispatch(&"sages_loaded", {"view": d["sages"]["view"]})
	store.dispatch(&"codex_loaded", {"view": d["codex"]["view"], "changes": 0})
	store.dispatch(&"planner_opened", {"card": card})
	var screen: Control = load("res://scenes/planner.tscn").instantiate()
	root.add_child(screen)
	await process_frame
	store.dispatch(&"planner_opened", {"card": card})
	# PTAB: another tab on show.
	if OS.get_environment("PTAB") != "":
		await process_frame
		(screen as PlannerScreen)._tab = OS.get_environment("PTAB")
		(screen as PlannerScreen)._refresh()
	await ShotKit.settle(self, screen)
	quit()
