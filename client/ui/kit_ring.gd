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
## A dial: a thick gold ring all round (the play-time ring), the fill
## drawn as a brighter arc over it.
var heavy := false
## A full pip's colour (gold if unset).
var tint := Color()
## The ground behind the picture, lit from above (a crew member's school,
## 02-heist.png); the card's violet if unset.
var ground := Color()
## The ring's band (leather for a crew member); the card's violet if unset.
var band := Color()
## How far the picture is drawn in, about `focus` (fractions of it): a
## head-and-shoulders portrait filling the disc as the designs crop it.
var zoom := 1.0
var focus := Vector2(0.5, 0.5)


func _draw() -> void:
	var c := size * 0.5
	var r := minf(size.x, size.y) * 0.5
	var ink := Tokens.color("ink_line")
	var gold := Tokens.color("gold_top")
	if dot:
		draw_circle(c, r, ink, true, -1.0, true)
		var full := tint if tint != Color() else gold
		draw_circle(c, r - maxf(1.5, r * 0.28), full if fraction >= 0.5 else Tokens.color("card_bottom"), true, -1.0,
			true)
		return
	if heavy:
		_heavy(c, r, ink, gold)
		return
	var line := maxf(2.0, r * (0.2 if band != Color() else 0.14))
	# Everything round the picture in two arrays of triangles, one under it
	# and one over: three draw calls with the picture, not eight.
	var under := KitTris.new()
	under.disc(c, r, ink)
	under.disc(c, r - line * 0.5, band if band != Color() else Tokens.color("card_top"))
	var inner := r - line * 1.2
	if ground != Color():
		under.disc(c, inner, ground.darkened(0.25))
		under.disc(c + Vector2(0, -inner * 0.2), inner * 0.78, ground.lightened(0.18))
	under.draw_on(get_canvas_item())
	if picture != null:
		# The picture cut round: a polygon of the circle, textured.
		var points := PackedVector2Array()
		var uvs := PackedVector2Array()
		for i: int in 48:
			var a := TAU * i / 48.0
			var d := Vector2(cos(a), sin(a))
			points.append(c + d * inner)
			uvs.append(focus + d * 0.5 / zoom)
		draw_colored_polygon(points, Color.WHITE, uvs, picture)
	var over := KitTris.new()
	if band != Color():
		# A gold line inside the leather band, as the designs edge a portrait.
		var w := maxf(1.0, UI.px(0.8))
		over.ring(c, r - line * 1.15 - w * 0.5, r - line * 1.15 + w * 0.5, Tokens.color("gold"))
	else:
		over.ring(c, r - line, r, Color(Tokens.color("text_on_night_2"), 0.25))
	over.ring(c, r - maxf(1.5, UI.px(0.7)), r, ink)
	over.draw_on(get_canvas_item())
	if fraction > 0.0:
		draw_arc(c, r - line * 0.5, -PI * 0.5, -PI * 0.5 + TAU * fraction, 64, gold, line, true)


func _heavy(c: Vector2, r: float, ink: Color, gold: Color) -> void:
	# The designs' play-time ring (19 Settings): a soft gold glow, a gold
	# halo outside an ink edge, a dark track filled clockwise from the top in
	# a gold that deepens as it goes, an ink-edged violet disc recessed in
	# it, and a cream marker where the fill ends.
	var halo := maxf(2.0, UI.px(1.2))
	var edge := maxf(1.5, UI.px(0.7))
	for i: int in 2:
		draw_circle(c, r + halo + UI.px(3.0 + 4.0 * i), Color(gold, 0.09), true, -1.0, true)
	draw_circle(c, r + halo, Color(Tokens.color("gold_bottom"), 0.55), true, -1.0, true)
	draw_circle(c, r, ink, true, -1.0, true)
	var track := r * 0.196
	var mid := r - track * 0.5
	draw_arc(c, mid, 0.0, TAU, 96, Tokens.paint("#0E0920"), track, true)
	if fraction > 0.0:
		# One polyline, its colour per point: a single draw call.
		var steps := maxi(2, int(72 * fraction))
		var from := Tokens.paint("#F9DE9C")
		var to := Tokens.paint("#F2B43C")
		var points := PackedVector2Array()
		var colours := PackedColorArray()
		for i: int in steps + 1:
			var a := -PI * 0.5 + TAU * fraction * i / steps
			points.append(c + Vector2(cos(a), sin(a)) * mid)
			colours.append(from.lerp(to, float(i) / steps))
		draw_polyline_colors(points, colours, track, true)
	var inner := r - track
	draw_circle(c, inner, ink, true, -1.0, true)
	# The disc lit from above: a fan from its light, a little over its
	# centre, out to its dark rim, smooth and one draw call.
	var light := c + Vector2(0, -inner * 0.3)
	var fan := PackedVector2Array([light])
	var shades := PackedColorArray([Tokens.paint("#3A2878")])
	for i: int in 49:
		var a := TAU * i / 48.0
		fan.append(c + Vector2(cos(a), sin(a)) * (inner - edge))
		shades.append(Tokens.paint("#1A1036"))
	draw_polygon(fan, shades)
	if fraction > 0.0 and fraction < 1.0:
		var end := -PI * 0.5 + TAU * fraction
		var at := c + Vector2(cos(end), sin(end)) * mid
		var dot_r := track * 0.62
		draw_circle(at, dot_r + UI.px(2), Color(Tokens.paint("#F9DE9C"), 0.35), true, -1.0, true)
		draw_circle(at, dot_r, ink, true, -1.0, true)
		draw_circle(at, dot_r - edge, Tokens.color("cream"), true, -1.0, true)
