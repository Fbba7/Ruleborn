class_name ScreenBox
extends RefCounted
## The rounded outline the menu screens' code-drawn data shapes are built
## from (`ScreenBands`, `ScreenSwitch`). Its box drawing is gone: the menu
## screens' materials are the kit's (`ScreenKit` through `UI.dress` and
## `RbBox`, bars as `KitBar`), kit-spec.md section 8.1.

const STEPS := 6


## The outline of a rounded rectangle, clockwise from the top left.
static func outline(r: Rect2, rad: float) -> PackedVector2Array:
	var pts := PackedVector2Array()
	var corners := [Vector2(r.position.x + rad, r.position.y + rad), Vector2(r.end.x - rad, r.position.y + rad),
		Vector2(r.end.x - rad, r.end.y - rad), Vector2(r.position.x + rad, r.end.y - rad)]
	for k: int in 4:
		var start := PI + k * PI * 0.5
		for s: int in STEPS + 1:
			var a := start + PI * 0.5 * float(s) / float(STEPS)
			pts.append((corners[k] as Vector2) + Vector2(cos(a), sin(a)) * rad)
	return pts
