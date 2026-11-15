extends SceneTree
## Motion shot: a screen change (curve `screen`; P2-AIA-motion-2). The map
## screen leaves and the results screen arrives, both started on the same
## frame as a router would, every frame for 400 ms (full: the old screen
## fades out over 160 ms, the new one fades in from 0.985 of its size over
## 180 ms; reduced: the new one fades in over 150 ms, no change of size).
## Frames and measures to FRAMES (motion_rig.gd).

const Rig := preload("res://tests/shots/motion_rig.gd")
const W := 1080
const H := 2340


func _initialize() -> void:
	_go()


func _go() -> void:
	var rig := Rig.new(self, Vector2i(W, H))
	var old := _screen(Tokens.color("sky_top"), "The map", "Your crew waits at the gate.", "Start the heist", "")
	var new := _screen(Tokens.color("stone"), "Results", "The vault is yours.", "Collect",
		"season/tierreward")
	for s: Control in [old, new]:
		rig.stage.add_child(s)
	new.modulate.a = 0.0
	await rig.settle()
	var probe := func() -> Dictionary:
		return {"old": {"alpha": old.modulate.a, "scale": old.scale.x},
			"new": {"alpha": new.modulate.a, "scale": new.scale.x}}
	rig.shoot(probe)
	Motion.screen_out(old)
	Motion.screen_in(new)
	await rig.run(0.4, probe)
	rig.finish("screen")


## A screen filling the stage: its ground, a title, a line, a picture and a
## gold button.
func _screen(ground: Color, title: String, line: String, action: String, picture: String) -> Control:
	var s := Control.new()
	s.size = Vector2(W, H)
	var bg := ColorRect.new()
	bg.color = ground
	bg.size = Vector2(W, H)
	s.add_child(bg)
	var col := VBoxContainer.new()
	col.position = Vector2(UI.px(16), UI.px(40))
	col.size = Vector2(W - UI.px(32), H - UI.px(80))
	col.alignment = BoxContainer.ALIGNMENT_CENTER
	col.add_theme_constant_override("separation", UI.px(14))
	var t := UI.title(title)
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(t)
	var l := UI.label(line, -1.0, true)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(l)
	if picture != "":
		var p := Icons.view(picture, 96.0)
		p.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		col.add_child(p)
	var b := UI.button(action, func() -> void: pass, true)
	b.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	col.add_child(b)
	s.add_child(col)
	return s
