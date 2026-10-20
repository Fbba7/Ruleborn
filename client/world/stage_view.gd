class_name StageView
extends WorldView
## A realm on a screen that is not a heist (§21.1's home diorama: "orthographic,
## 35° pitch, rotatable in 90° steps"), drawn full-bleed behind the screen's
## panels. It is a `WorldView`, so the world is the heist's own, with its
## taps and gestures; this adds what a screen around it needs: the island
## framed in the part of the screen the panels leave open, scaled by the
## view's pinch zoom, and a slow breath of the camera so the diorama is never
## a still picture (§21.1: "gentle physical humour").



## The share of the view's height the panels cover at its bottom and top:
## the island is framed in what is left.
var cover_bottom := 0.0
var cover_top := 0.0
## How much room the grid takes: 1 fits its corners to the screen's width,
## more pulls the camera back, less brings it in past the edges.
var fill := 1.0
## How far above the grid's centre the camera looks, in metres on screen.
var look_up := 0.0
## Whether a second quick tap steps the zoom (`WorldView`'s double tap); a
## screen that acts on every tap, as the builder does, turns it off so two
## tiles tapped in a row are two edits and never a zoom.
var taps_zoom := true
## Layers a screen adds over the realm: tiles, ghosts, its own pieces.
var layers: Node3D
## The woven laws' world signatures (T8's `LawFx`, §21.7), when shown.
var law_fx: LawFx

var _breath := 0.0
## The laws' clock, for signatures with no heist behind them.
var _law_seconds := 0.0


func _init() -> void:
	super._init()
	heist = false
	pitch = HOME_PITCH
	layers = Node3D.new()
	layers.name = "Layers"
	world.add_child(layers)


func _process(delta: float) -> void:
	super._process(delta)
	_breath += delta
	fit()
	if law_fx != null and law_fx.source == null:
		_law_seconds += delta
		law_fx.sync(_law_seconds * LawFx.TPS)


## §21.7: every law woven in `r`'s realm, its world signature always on, so a
## player reads the island without a menu (T8's `LawFx.attach`).
func show_laws(r: RulebornReplay) -> void:
	_drop_laws()
	if r != null:
		law_fx = LawFx.attach(self, r)


## The signatures of `laws` over this realm with nothing placed: what a
## scout knows (§12.4). Their crowns and the threads between pylons stand on
## tiles, so they are left out; the realm still wears each law's look.
func show_bare_laws(laws: Array) -> void:
	_drop_laws()
	if laws.is_empty() or _size.x == 0:
		return
	law_fx = LawFx.new()
	law_fx.view = self
	law_fx.camera = camera
	law_fx.sun = sun
	law_fx.environment = environment
	world.add_child(law_fx)
	law_fx.build(LawFxSite.bare(_size, laws))
	for hidden: Node3D in [law_fx.crowns, law_fx.links]:
		if hidden != null:
			hidden.visible = false


func _drop_laws() -> void:
	if law_fx != null:
		law_fx.queue_free()
	law_fx = null


## The camera framed for the screen: `WorldView` frames it for a zoom level
## first, then the grid is fitted to the part of the screen the panels leave
## open, scaled by the pinch zoom. Done whenever `WorldView` frames, too, so
## a tap that redraws the realm never sees the camera between the two.
func _frame_camera() -> void:
	super._frame_camera()
	fit()


func fit() -> void:
	if camera == null:
		return
	# The panels' share of the height, the island lifted into the rest;
	# and a breath of a few centimetres, so the diorama is alive.
	var breath := 0.0 if Settings.reduced_motion else sin(_breath * 0.5) * 0.04
	if _size.x > 0 and size.y > 0.0:
		var diag := Vector2(_size).length()
		var open := maxf(0.2, 1.0 - cover_bottom - cover_top)
		var by_width := diag * fill / maxf(0.1, size.x / size.y)
		var by_height := (diag * sin(deg_to_rad(pitch)) + 2.5) * fill / open
		camera.size = maxf(by_width, by_height) * zoom_scale()
	camera.v_offset = (cover_top - cover_bottom) * 0.5 * camera.size + breath + look_up
	camera.h_offset = 0.0


## How far `WorldView`'s pinch and double tap have zoomed, as a share of
## the screen's own framing: 1 at the realm's zoom level, more drawn back to
## the whole rock, less closed in, smoothly between the levels.
func zoom_scale() -> float:
	var z := clampf(_zoom_f, 0.0, 2.0)
	var span: float = lerpf(ZOOM_SPAN[0], ZOOM_SPAN[1], z) if z <= 1.0 else lerpf(ZOOM_SPAN[1], ZOOM_SPAN[2], z - 1.0)
	return span / float(ZOOM_SPAN[1])


## A tap's release, as `WorldView` reads it, with the double tap left out
## where taps do not zoom.
func _release(at: Vector2) -> void:
	if not taps_zoom:
		_last_tap_ms = -10000
	super._release(at)


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
	if anchors != null:
		anchors.vault_shown = shown
		anchors.queue_redraw()
