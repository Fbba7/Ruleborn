class_name Plans
extends RefCounted
## Heists the tests play through the heist screen's own controls.


## The open example Heart's clean heist, the one server/test plays
## (setup.mjs's openPlan), given at its seconds; then the clock runs out.
static func open_heart(screen: HeistScreen, ticks: int) -> void:
	var go := func(seconds: int) -> void: screen.advance(seconds * 30 - screen.controller.world.tick())
	screen.controller.land(Vector2i(0, 0))                   # where server/test lands it
	for step: Array in [[0, Vector2i(6, 8)], [1, Vector2i(7, 9)], [2, Vector2i(5, 9)]]:
		screen.controller.select(step[0])
		screen.controller.tap_tile(step[1])
	go.call(15)
	for m in 3:
		screen.controller.select(m)
		screen.controller.crack()
	go.call(50)
	for m in 3:
		screen.controller.select(m)
		screen.controller.load_up(100)
	screen.controller.select(0)
	screen.controller.get_out()
	screen.controller.tap_tile(Vector2i(6, 11))
	go.call(62)
	for m in 3:
		screen.controller.select(m)
		screen.controller.tap_tile(Vector2i(6, 11))
	screen.advance(ticks)
