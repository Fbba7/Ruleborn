class_name OverlayRoute
extends Control
## A rehearsal's route over its island (§13, "Rehearsal and defence log"):
## each crew member's walk so far as the design's dashed green line with a
## dark edge, a red "!" where a guard reached Alerted on seeing the crew (the
## simulation's report), and the Vault's star. Drawn over the view in its
## own pixels, from the tiles the simulation gave: nothing here decides
## anything.

const DASH_POINTS := 7.0

var view: StageView
## Each crew member's tiles so far, in the simulation's tile units.
var trails: Array[PackedVector2Array] = []
## The tiles where the crew was seen, from the report.
var seen: Array[Vector2i] = []
var vault := Vector2(-1, -1)


func _init(on: StageView) -> void:
	view = on
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)


func clear() -> void:
	trails.clear()
	seen.clear()
	queue_redraw()


func _process(_delta: float) -> void:
	# The camera breathes and the island is framed as the card resizes.
	if not trails.is_empty() or vault.x >= 0:
		queue_redraw()


func _point(at: Vector2) -> Vector2:
	var p := view.world_at(at) + Vector3(0, 0.15, 0)
	var vp := Vector2(view.viewport.size)
	return view.project(p) * (view.size / vp.max(Vector2.ONE)) + view.position - position


func _draw() -> void:
	if view == null or view.replay == null or view.camera == null or view.viewport == null:
		return
	var wide := UI.px(5)
	var dash := UI.px(DASH_POINTS)
	var green := Tokens.color("success_light")
	var edge := Tokens.color("ink_deep")
	for trail: PackedVector2Array in trails:
		if trail.size() < 2:
			continue
		var line := PackedVector2Array()
		for at: Vector2 in trail:
			line.append(_point(at))
		draw_polyline(line, edge, wide + UI.px(3), true)
		draw_dashed_line_strip(line, green, wide, dash)
	if vault.x >= 0:
		var c := _point(vault)
		_star(c, UI.px(14), Tokens.color("gold"), edge)
	for t: Vector2i in seen:
		var c := _point(Vector2(t) + Vector2(0.5, 0.5))
		var r := UI.px(13)
		draw_circle(c, r + UI.px(4), Color(Tokens.color("alarm"), 0.3))
		draw_circle(c, r, Tokens.color("alarm"))
		draw_arc(c, r, 0, TAU, 24, Tokens.color("cream"), UI.px(2), true)
		var font := UI.bold_font()
		var size := UI.text_px(16)
		var w := font.get_string_size("!", HORIZONTAL_ALIGNMENT_CENTER, -1, size).x
		draw_string(font, c + Vector2(-w / 2.0, size * 0.36), "!", HORIZONTAL_ALIGNMENT_LEFT, -1, size,
			Tokens.color("cream"))


## A dashed line along the polyline's whole length, the dashes running on
## round its corners.
func draw_dashed_line_strip(line: PackedVector2Array, colour: Color, wide: float, dash: float) -> void:
	var on := true
	var left := dash
	for i in line.size() - 1:
		var a := line[i]
		var b := line[i + 1]
		var length := a.distance_to(b)
		var gone := 0.0
		while gone < length:
			var step := minf(left, length - gone)
			var p := a.lerp(b, gone / length)
			var q := a.lerp(b, (gone + step) / length)
			if on:
				draw_line(p, q, colour, wide, true)
			gone += step
			left -= step
			if left <= 0.0:
				on = not on
				left = dash
	if line.size() > 0:
		draw_circle(line[line.size() - 1], wide * 0.9, colour)


func _star(c: Vector2, r: float, fill: Color, edge: Color) -> void:
	var pts := PackedVector2Array()
	for i in 10:
		var a := -PI / 2.0 + i * PI / 5.0
		pts.append(c + Vector2(cos(a), sin(a)) * (r if i % 2 == 0 else r * 0.45))
	draw_colored_polygon(pts, fill)
	pts.append(pts[0])
	draw_polyline(pts, edge, UI.px(2), true)
