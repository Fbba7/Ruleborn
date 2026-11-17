extends SceneTree
## Motion shot: the idle shine (curve `shine`; P2-AIA-motion-2). A gold
## primary button, every frame for 3.6 s: after the first 800 ms wait a soft
## band sweeps across its face over 250 ms, and again each 2.4 s. None under
## reduced motion (FORM=reduced) or in high contrast (HC=1): the frames stay
## still. Frames and measures to FRAMES (motion_rig.gd).

const Rig := preload("res://tests/shots/motion_rig.gd")
const W := 960
const H := 320


func _initialize() -> void:
	_go()


func _go() -> void:
	var rig := Rig.new(self, Vector2i(W, H))
	var b := UI.button("Play", func() -> void: pass, true)
	b.custom_minimum_size.x = UI.px(200)
	rig.stage.add_child(b)
	await rig.settle()
	b.position = (Vector2(W, H) - b.size) * 0.5
	await rig.settle()
	var held: Array = [null]
	var probe := func() -> Dictionary:
		var layer: Control = held[0]
		if layer == null or not is_instance_valid(layer) or layer.get_child_count() == 0:
			return {"layer": false, "shown": false, "alpha": 0.0, "x": 0.0, "width": b.size.x}
		var band := layer.get_child(0) as TextureRect
		return {"layer": true, "shown": band.visible and band.modulate.a > 0.001, "alpha": band.modulate.a,
			"x": band.position.x + band.size.x * 0.5, "width": b.size.x}
	rig.shoot(probe)
	held[0] = Motion.shine(b)
	await rig.run(3.6, probe)
	rig.finish("shine", {"first_wait_ms": Motion.value("shine", "full", "first_wait_ms", 0),
		"period_ms": Motion.value("shine", "full", "period_ms", 0)})
