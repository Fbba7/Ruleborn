class_name OverlayPins
extends Control
## Words and numbers pinned to the realm (the diorama's `pin`, projected
## every frame from a point in the world): a building's level, a law's name
## over its pylon, a guard's role over its post. Each pin is a control laid
## over the view, kept the size the interface sets (§21.8's 13 points at
## least), so it reads at any zoom; it hangs above its point by its tip.

var view: StageView
var _pins: Array[Dictionary] = []


func _init(on: StageView) -> void:
	view = on
	name = "Pins"
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)


## A pin showing `node` over the world point `at`.
func pin(node: Control, at: Vector3) -> Control:
	node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(node)
	_pins.append({"node": node, "at": at})
	return node


func clear() -> void:
	for p: Dictionary in _pins:
		(p["node"] as Node).queue_free()
	_pins.clear()


func count() -> int:
	return _pins.size()


func _process(_delta: float) -> void:
	place()


## Every pin over its point: centred on it, its bottom edge at it.
func place() -> void:
	if view == null or view.camera == null:
		return
	var scale_to := Vector2.ONE
	var vp := view.viewport.size
	if vp.x > 0 and vp.y > 0:
		scale_to = view.size / Vector2(vp)
	for p: Dictionary in _pins:
		var node: Control = p["node"]
		var at: Vector3 = p["at"]
		if not view.in_front(at):
			node.visible = false
			continue
		node.visible = true
		var s := view.project(at) * scale_to + view.position - position
		var box := node.get_combined_minimum_size()
		node.size = box
		node.position = (s - Vector2(box.x / 2.0, box.y)).round()
