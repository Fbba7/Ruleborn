class_name ScreenStrip
extends Container
## A row wider than the screen that the finger drags sideways (the Season
## track): its children side by side at their own widths, clipped to the
## strip, which asks for no width of its own, so the screen keeps its
## frame's width. It holds pictures and words; a control that must be
## reached stays in the list, never past the strip's edge.

var separation := 0.0
## How far the row is dragged, in pixels.
var offset := 0.0:
	set(v):
		offset = clampf(v, 0.0, maxf(0.0, _width() - size.x))
		queue_sort()
var _dragging := false


func _init() -> void:
	clip_contents = true
	mouse_filter = Control.MOUSE_FILTER_PASS


func _get_minimum_size() -> Vector2:
	var h := 0.0
	for c: Node in get_children():
		if c is Control and (c as Control).visible:
			h = maxf(h, (c as Control).get_combined_minimum_size().y)
	return Vector2(0.0, h)


func _width() -> float:
	var w := 0.0
	for c: Node in get_children():
		if c is Control and (c as Control).visible:
			w += (c as Control).get_combined_minimum_size().x + separation
	return maxf(0.0, w - separation)


func _notification(what: int) -> void:
	if what == NOTIFICATION_SORT_CHILDREN:
		var x := -offset
		for c: Node in get_children():
			if c is Control and (c as Control).visible:
				var k := c as Control
				var w := k.get_combined_minimum_size().x
				fit_child_in_rect(k, Rect2(Vector2(x, 0.0), Vector2(w, size.y)))
				x += w + separation


func _gui_input(event: InputEvent) -> void:
	if event is InputEventScreenDrag:
		offset -= (event as InputEventScreenDrag).relative.x
		accept_event()
	elif event is InputEventMouseMotion and (event as InputEventMouseMotion).button_mask & MOUSE_BUTTON_MASK_LEFT:
		offset -= (event as InputEventMouseMotion).relative.x
		accept_event()
	elif event is InputEventMouseButton and (event as InputEventMouseButton).pressed:
		match (event as InputEventMouseButton).button_index:
			MOUSE_BUTTON_WHEEL_DOWN, MOUSE_BUTTON_WHEEL_RIGHT:
				offset += UI.px(40)
			MOUSE_BUTTON_WHEEL_UP, MOUSE_BUTTON_WHEEL_LEFT:
				offset -= UI.px(40)
