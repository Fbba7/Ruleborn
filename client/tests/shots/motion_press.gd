extends SceneTree
## Motion shot: the press (curve `press`; P2-AIA-motion-2). A gold primary
## and a leather button pressed together and let go at 300 ms, every frame
## to 700 ms, in the form FORM says (full: sinks, squashes to 0.96 and
## darkens to 0.9 over 150 ms, back over 180 ms; reduced: sinks and darkens
## to 0.88, no squash). Frames and their measures to FRAMES (motion_rig.gd).

const Rig := preload("res://tests/shots/motion_rig.gd")
const RELEASE_FRAME := 18


func _initialize() -> void:
	_go()


func _go() -> void:
	var rig := Rig.new(self, Vector2i(960, 320))
	var gold := UI.button("Collect", func() -> void: pass, true)
	var leather := UI.button("Back", func() -> void: pass)
	for b: Button in [gold, leather]:
		b.custom_minimum_size.x = UI.px(130)
		rig.stage.add_child(b)
	await rig.settle()
	gold.position = Vector2(60, (320 - gold.size.y) * 0.5)
	leather.position = Vector2(960 - 60 - leather.size.x, (320 - leather.size.y) * 0.5)
	await rig.settle()
	var probe := func() -> Dictionary:
		var row := {}
		for pair: Array in [["gold", gold], ["leather", leather]]:
			var b: Button = pair[1]
			var box := RbBox.of(b)
			row[pair[0]] = {"scale": b.scale.x, "press": box.press, "value": box.self_modulate.r}
		return row
	rig.shoot(probe)
	for b: Button in [gold, leather]:
		Motion.press(b, true)
	await rig.run(0.7, probe, {RELEASE_FRAME: func() -> void:
		for b: Button in [gold, leather]:
			Motion.press(b, false)})
	rig.finish("press", {"release_frame": RELEASE_FRAME})
