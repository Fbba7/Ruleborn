class_name ScreenDraw
extends RefCounted
## Shapes gathered into one triangle array and drawn in one call: the
## Compatibility renderer gives every anti-aliased circle, arc and polygon a
## draw call of its own, and §21.3 allows a screen under 150.

var pts := PackedVector2Array()
var cols := PackedColorArray()
var idx := PackedInt32Array()


func circle(c: Vector2, r: float, col: Color, segments := 24) -> void:
	arc(c, 0.0, r, 0.0, TAU, col, segments)


## A ring segment from `inner` to `outer` radius, from angle `from` to `to`.
func arc(c: Vector2, inner: float, outer: float, from: float, to: float, col: Color, segments := 24) -> void:
	var base := pts.size()
	for i: int in segments + 1:
		var a := from + (to - from) * float(i) / float(segments)
		var d := Vector2(cos(a), sin(a))
		pts.append(c + d * outer)
		pts.append(c + d * inner)
		cols.append(col)
		cols.append(col)
	for i: int in segments:
		var k := base + i * 2
		idx.append_array([k, k + 1, k + 2, k + 1, k + 3, k + 2])


## Any simple polygon, triangulated.
func polygon(points: PackedVector2Array, col: Color) -> void:
	var tris := Geometry2D.triangulate_polygon(points)
	var base := pts.size()
	for p: Vector2 in points:
		pts.append(p)
		cols.append(col)
	for t: int in tris:
		idx.append(base + t)


## A closed outline of `width` round a polygon.
func outline(points: PackedVector2Array, col: Color, width: float) -> void:
	var n := points.size()
	for i: int in n:
		var a := points[i]
		var b := points[(i + 1) % n]
		var side := (b - a).orthogonal().normalized() * width * 0.5
		var base := pts.size()
		pts.append_array([a - side, a + side, b - side, b + side])
		cols.append_array([col, col, col, col])
		idx.append_array([base, base + 1, base + 2, base + 1, base + 3, base + 2])
		circle(a, width * 0.5, col, 6)


func flush(ci: RID) -> void:
	if not idx.is_empty():
		RenderingServer.canvas_item_add_triangle_array(ci, idx, pts, cols)
	pts = PackedVector2Array()
	cols = PackedColorArray()
	idx = PackedInt32Array()
