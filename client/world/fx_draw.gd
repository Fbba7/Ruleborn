class_name FxDraw
extends Control
## A HUD piece drawn in code: `painter` is called with this control each time
## it draws, so a meter, a bar or an icon is one small function. It never
## takes a tap.

var painter: Callable


func _init(paint: Callable = Callable(), minimum := Vector2.ZERO) -> void:
	painter = paint
	custom_minimum_size = minimum
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _draw() -> void:
	if painter.is_valid():
		painter.call(self)
