extends "res://tests/shots/screen_heist.gd"
## T14's proof (docs/art/ui-quality/report.md): screen_heist.gd's still with
## its HUD and crew row hidden and UiqHud, the HUD rebuilt on authored art,
## laid over the same moment. The same environment as screen_heist.gd
## (MANIFEST, CAST, MOMENT, ESTIMATE...); OLD keeps the game's own HUD and
## leaves UiqHud out, for the before. For a fair count of draw calls give
## HIDE=hud,actions_band too, which takes the game's HUD out of the frame.


## Called by screen_heist.gd once the moment is played, before the still.
func settle(node: Node) -> void:
	super.settle(node)
	if OS.get_environment("OLD") != "":
		return
	var screen: HeistScreen = node.find_children("*", "HeistScreen", true, false)[0]
	# Hidden by their alpha: the screen's refresh sets their visibility.
	screen.hud.modulate.a = 0.0
	screen.actions_band.modulate.a = 0.0
	var hud := UiqHud.new()
	screen.add_child(hud)
	hud.show_state(screen.controller.world, screen.crew_buttons, screen.hud.estimate, screen.controller.load_target)
	hud.set_sage(screen.hand.get("_picture"), str(screen.hand.get("_sage_id")).replace("the_", ""))
	# The portraits fill in over a few frames: show them again as they do.
	var again := func() -> void:
		hud.show_state(screen.controller.world, screen.crew_buttons, screen.hud.estimate,
			screen.controller.load_target)
	screen.get_tree().process_frame.connect(again)
