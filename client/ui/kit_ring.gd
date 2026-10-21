class_name KitRing
extends Control
## A round picture in a ring that fills clockwise from the top (the
## Keeper's experience, a lockout sweeping round a portrait), or, as a
## `dot`, a pip that is full or hollow. Drawn with antialiased arcs.

## How much of the ring is filled, 0 to 1.
var fraction := 0.0:
	set(v):
		fraction = v
		queue_redraw()
## The picture inside the ring, cut round.
var picture: Texture2D = null:
	set(v):
		picture = v
		queue_redraw()
## A pip rather than a ring.
var dot := false


func _draw() -> void:
	var c := size * 0.5
	var r := minf(size.x, size.y) * 0.5
	var ink := Tokens.color("ink_line")
	var gold := Tokens.color("gold_top")
	if dot:
		draw_circle(c, r, ink, true, -1.0, true)
		draw_circle(c, r - maxf(1.5, r * 0.28), gold if fraction >= 0.5 else Tokens.color("card_bottom"), true, -1.0,
			true)
		return
	var line := maxf(2.0, r * 0.14)
	draw_circle(c, r, ink, true, -1.0, true)
	draw_circle(c, r - line * 0.5, Tokens.color("card_top"), true, -1.0, true)
	if picture != null:
		var inner := r - line * 1.2
		# The picture cut round: a polygon of the circle, textured.
		var points := PackedVector2Array()
		var uvs := PackedVector2Array()
		for i: int in 48:
			var a := TAU * i / 48.0
			var d := Vector2(cos(a), sin(a))
			points.append(c + d * inner)
			uvs.append(Vector2(0.5, 0.5) + d * 0.5)
		draw_colored_polygon(points, Color.WHITE, uvs, picture)
	draw_arc(c, r - line * 0.5, 0.0, TAU, 64, Color(Tokens.color("text_on_night_2"), 0.25), line, true)
	if fraction > 0.0:
		draw_arc(c, r - line * 0.5, -PI * 0.5, -PI * 0.5 + TAU * fraction, 64, gold, line, true)
	draw_arc(c, r, 0.0, TAU, 64, ink, maxf(1.5, UI.px(0.7)), true)
