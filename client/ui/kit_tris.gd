class_name KitTris
extends RefCounted
## Triangles with a colour at each corner, gathered and drawn at once: a
## kit control's discs, rings and bars in one draw call
## (`RenderingServer.canvas_item_add_triangle_array`), their edges feathered
## a pixel for smoothness.

var points := PackedVector2Array()
var colours := PackedColorArray()
var order := PackedInt32Array()


## A filled circle whose edge fades over one pixel.
func disc(c: Vector2, r: float, colour: Color) -> void:
	var n := clampi(int(r * 0.6), 16, 48)
	var base := points.size()
	points.append(c)
	colours.append(colour)
	var clear := Color(colour, 0.0)
	for k: int in n:
		var d := Vector2.from_angle(TAU * k / n)
		points.append(c + d * (r - 0.5))
		colours.append(colour)
		points.append(c + d * (r + 0.5))
		colours.append(clear)
	for k: int in n:
		var a := base + 1 + 2 * k
		var b := base + 1 + 2 * ((k + 1) % n)
		order.append_array([base, a, b, a, a + 1, b + 1, a, b + 1, b])


## A bar from `from` to the right, `long` long and `thick` thick, about
## its middle, its long edges fading over one pixel.
func bar(from: Vector2, long: float, thick: float, colour: Color) -> void:
	if long <= 0.0:
		return
	var base := points.size()
	var clear := Color(colour, 0.0)
	var h := thick * 0.5
	for edge: Array in [[-h - 0.5, clear], [-h + 0.5, colour], [h - 0.5, colour], [h + 0.5, clear]]:
		for x: float in [from.x, from.x + long]:
			points.append(Vector2(x, from.y + float(edge[0])))
			colours.append(edge[1])
	for row: int in 3:
		var a := base + 2 * row
		order.append_array([a, a + 1, a + 3, a, a + 3, a + 2])


## A ring between radii `inner` and `outer`, both edges feathered.
func ring(c: Vector2, inner: float, outer: float, colour: Color) -> void:
	var n := clampi(int(outer * 0.6), 24, 64)
	var base := points.size()
	var clear := Color(colour, 0.0)
	for k: int in n:
		var d := Vector2.from_angle(TAU * k / n)
		for at: Array in [[inner - 0.5, clear], [inner + 0.5, colour], [outer - 0.5, colour], [outer + 0.5, clear]]:
			points.append(c + d * float(at[0]))
			colours.append(at[1])
	for k: int in n:
		var a := base + 4 * k
		var b := base + 4 * ((k + 1) % n)
		for j: int in 3:
			order.append_array([a + j, a + j + 1, b + j + 1, a + j, b + j + 1, b + j])


## Draws everything gathered on `item` (a CanvasItem's `get_canvas_item()`).
func draw_on(item: RID) -> void:
	if not order.is_empty():
		RenderingServer.canvas_item_add_triangle_array(item, order, points, colours)
