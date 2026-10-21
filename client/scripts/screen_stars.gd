class_name ScreenStars
extends Control
## The faint star dots of the design's night backdrop: fixed points, a few of
## them brighter, drawn once (no motion, so nothing to reduce).

const COUNT := 70


func _draw() -> void:
	var d := ScreenDraw.new()
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	for i: int in COUNT:
		var p := Vector2(rng.randf() * size.x, rng.randf() * size.y)
		var big := rng.randf() < 0.15
		var r := UI.px(1.0 if big else 0.55)
		d.circle(p, r, Color(1.0, 0.97, 0.9, 0.55 if big else 0.28), 6)
	d.circle(Vector2(size.x * 0.5, size.y * 0.16), size.x * 0.42, Color(0.55, 0.42, 1.0, 0.07), 48)
	d.flush(get_canvas_item())


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		queue_redraw()
