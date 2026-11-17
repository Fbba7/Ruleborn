extends SceneTree
## Motion shot: the result screen's reward (curve `reward`; P2-AIA-motion-2).
## A season prize under a starglass counter going from 120 to 128, every
## frame for 2.2 s (0.6 s reduced), for the tier TIER says ("common", "rare"
## or "epic"; full: the prize gathers and charges for the tier's
## anticipation, bursts, is revealed, and eight coins fly in arcs onto the
## counter's icon, each landing rolling the figure beside it up and pulsing
## the icon (AD-R29: no coin covers the figure), on the result screen's
## sunburst (none in high contrast); reduced: the prize
## fades in, one coin lands and the counter shows 128 at 350 ms). HC=1 draws
## the sprites' high-contrast twins. Frames and measures to FRAMES.

const Rig := preload("res://tests/shots/motion_rig.gd")
const W := 720
const H := 960
const FROM := 120
const TO := 128


func _initialize() -> void:
	_go()


func _go() -> void:
	var rig := Rig.new(self, Vector2i(W, H))
	var tier := OS.get_environment("TIER") if OS.get_environment("TIER") != "" else "common"
	if not Tokens.high_contrast:
		# The result screen's still sunburst (KitNav.celebrate), for the epic
		# burst to reach onto; high contrast keeps the plain night, as there.
		var sky := Control.new()
		sky.size = Vector2(W, H)
		RbBox.dress(sky, "night_rays", 0)
		rig.stage.add_child(sky)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", UI.px(6))
	# The icon's place in the row; the icon itself stands over it outside the
	# container, which would put its scale back to 1 at every re-sort and so
	# cut its landing pulse short.
	var slot := Control.new()
	row.add_child(slot)
	var figure := UI.label(str(FROM), 22.0)
	figure.add_theme_font_override("font", UI.bold_font())
	row.add_child(figure)
	var plate := UI.plate(row)
	rig.stage.add_child(plate)
	var counter := Icons.view("currencies/starglass", 28.0)
	rig.stage.add_child(counter)
	slot.custom_minimum_size = counter.get_combined_minimum_size()
	var prize := Icons.view("season/tierreward", 96.0)
	rig.stage.add_child(prize)
	var title := UI.title("Season reward")
	title.custom_minimum_size.x = W - UI.px(32)
	rig.stage.add_child(title)
	await rig.settle()
	plate.position = Vector2(W - plate.size.x - UI.px(16), UI.px(16))
	await rig.settle()
	counter.position = slot.global_position
	prize.position = Vector2((W - prize.size.x) * 0.5, H * 0.58 - prize.size.y * 0.5)
	title.position = Vector2((W - title.size.x) * 0.5, prize.position.y + prize.size.y + UI.px(14))
	await rig.settle()
	var layer: Array = [null]
	var probe := func() -> Dictionary:
		var sprites := 0
		var lit := 0
		var alive := is_instance_valid(layer[0])
		if alive:
			for c: Node in (layer[0] as Node).get_children():
				sprites += 1
				if c is CanvasItem and (c as CanvasItem).visible and (c as CanvasItem).modulate.a > 0.001:
					lit += 1
		return {"prize": {"scale": prize.scale.x, "value": prize.self_modulate.r, "alpha": prize.modulate.a,
			"y": prize.position.y}, "counter": {"value": int(figure.text), "scale": counter.scale.x},
			"layer": alive, "sprites": sprites, "lit": lit}
	rig.shoot(probe)
	Motion.reward(prize, counter, FROM, TO, tier, func(v: int) -> void: figure.text = str(v))
	layer[0] = prize.get_child(prize.get_child_count(true) - 1, true)
	await rig.run(0.6 if Rig.form() == "reduced" else 2.2, probe)
	rig.finish("reward", {"tier": tier, "from": FROM, "to": TO, "rest_y": prize.position.y})
