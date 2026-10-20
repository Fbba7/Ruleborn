class_name StageView
extends WorldView
## A realm on a screen that is not a heist (§21.1's home diorama: "orthographic,
## 35° pitch, rotatable in 90° steps"), drawn full-bleed behind the screen's
## panels. It is a `WorldView`, so the world is the heist's own; this adds
## what a screen around it needs: the island framed in the part of the
## screen the panels leave open, a tap told from a swipe, a swipe that turns
## the camera a quarter, and a slow breath of the camera so the diorama is
## never a still picture (§21.1: "gentle physical humour").

signal tapped(tile: Vector2i, at: Vector2)

## How far a press may move and still be a tap, in pixels.
const TAP_SLOP := 24.0

## The share of the view's height the panels cover at its bottom and top:
## the island is framed in what is left.
var cover_bottom := 0.0
var cover_top := 0.0
## How much room the grid takes: 1 fits its corners to the screen's width,
## more pulls the camera back, less brings it in past the edges.
var fill := 1.0
## How far above the grid's centre the camera looks, in metres on screen.
var look_up := 0.0
## Whether a sideways swipe turns the camera; a screen that paints with a
## drag turns it with its own control instead.
var swipe_turns := true
## Layers a screen adds over the realm: tiles, ghosts, its own pieces.
var layers: Node3D

var _press := Vector2.ZERO
var _pressed := false
var _clock := 0.0


func _init() -> void:
	super._init()
	heist = false
	pitch = HOME_PITCH
	layers = Node3D.new()
	layers.name = "Layers"
	world.add_child(layers)
	mouse_filter = Control.MOUSE_FILTER_STOP
	gui_input.connect(_on_input)


func _on_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and (event as InputEventMouseButton).button_index == MOUSE_BUTTON_LEFT:
		var e := event as InputEventMouseButton
		if e.pressed:
			_press = e.position
			_pressed = true
		elif _pressed:
			_pressed = false
			var moved := e.position - _press
			if moved.length() <= TAP_SLOP:
				tapped.emit(tile_at(e.position), e.position)
			elif swipe_turns and absf(moved.x) > absf(moved.y) * 1.5:
				turn(-1 if moved.x > 0 else 1)


func _process(delta: float) -> void:
	super._process(delta)
	_clock += delta
	if camera == null:
		return
	# The panels' share of the height, the island lifted into the rest;
	# and a breath of a few centimetres, so the diorama is alive.
	var breath := 0.0 if Settings.reduced_motion else sin(_clock * 0.5) * 0.04
	if _size.x > 0 and size.y > 0.0:
		var diag := Vector2(_size).length()
		var open := maxf(0.2, 1.0 - cover_bottom - cover_top)
		var by_width := diag * fill / maxf(0.1, size.x / size.y)
		var by_height := (diag * sin(deg_to_rad(pitch)) + 2.5) * fill / open
		camera.size = maxf(by_width, by_height)
	camera.v_offset = (cover_top - cover_bottom) * 0.5 * camera.size + breath + look_up
	camera.h_offset = 0.0


## The tile's centre on the ground, raised by `up`.
func tile_point(t: Vector2i, up := 0.0) -> Vector3:
	return world_at(Vector2(t) + Vector2(0.5, 0.5)) + Vector3(0, up, 0)


## Where a world point is drawn on this control, and whether it is in front
## of the camera.
func project(p: Vector3) -> Vector2:
	return camera.unproject_position(p)


func in_front(p: Vector3) -> bool:
	return not camera.is_position_behind(p)


func grid_size() -> Vector2i:
	return _size


func heights() -> PackedByteArray:
	return _heights


## The Vault shown or hidden: a scout knows a realm's counts, not where its
## Vault stands (§12.4).
func show_vault(shown: bool) -> void:
	if _vault != null:
		_vault.visible = shown
