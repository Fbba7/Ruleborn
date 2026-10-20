class_name StageHeroBackdrop
extends Control
## What stands behind a hero stage (§21.2, §21.8): the menus' night, a glow
## in the school's colour where the character stands, slow rays turning
## round it and a few motes drifting up. Drawn in 2D under the stage's
## transparent 3D, so it costs no draw calls in the 3D and no
## post-processing (§21.3).

## §21.2: "Menus stand on a night backdrop (#171046 to #2C3AA8)", deepened
## toward §21.8's dark card at the foot so the pedestal reads on it.
const NIGHT_TOP := Color("#2C2266")
const NIGHT_FOOT := Color("#140C30")
const RAYS := 14
const MOTES := 18

## The glow's colour, the school's (§21.2).
var glow := Color("#F2B43C")
## Where the glow is centred, as a fraction of the size.
var centre := Vector2(0.5, 0.52)
## How far the glow reaches, as a fraction of the shorter side.
var reach := 0.62
## A burst of light round the glow, 1 at its height (a hatch's reveal).
var flash := 0.0
## Seconds since the stage was shown: the rays' turn and the motes' drift.
var time := 0.0
var _glow_texture: GradientTexture2D
var _shade_texture: GradientTexture2D


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_preset(Control.PRESET_FULL_RECT)
	_glow_texture = GradientTexture2D.new()
	_glow_texture.fill = GradientTexture2D.FILL_RADIAL
	_glow_texture.fill_from = Vector2(0.5, 0.5)
	_glow_texture.fill_to = Vector2(1.0, 0.5)
	_glow_texture.width = 256
	_glow_texture.height = 256
	_shade_texture = GradientTexture2D.new()
	_shade_texture.fill_from = Vector2(0, 0)
	_shade_texture.fill_to = Vector2(0, 1)
	_shade_texture.width = 4
	_shade_texture.height = 128
	var shade := Gradient.new()
	shade.set_color(0, NIGHT_TOP)
	shade.set_color(1, NIGHT_FOOT)
	_shade_texture.gradient = shade
	set_glow(glow)


func set_glow(colour: Color) -> void:
	glow = colour
	var g := Gradient.new()
	# A deep core and a bright ring: a pale character reads as a shape against
	# it, as §21.1's silhouette rule asks, while the stage still glows.
	g.offsets = PackedFloat32Array([0.0, 0.4, 0.62, 1.0])
	g.colors = PackedColorArray([Color(colour.darkened(0.15), 0.42), Color(colour, 0.5),
		Color(colour.darkened(0.1), 0.22), Color(colour.darkened(0.4), 0.0)])
	_glow_texture.gradient = g
	queue_redraw()


func advance(delta: float) -> void:
	time += delta
	queue_redraw()


func _draw() -> void:
	var r := Rect2(Vector2.ZERO, size)
	draw_texture_rect(_shade_texture, r, false)
	var c := size * centre
	var span := minf(size.x, size.y) * reach
	# Rays: long thin wedges from the glow, turning once in two minutes; all
	# of them one mesh, so one draw call (§21.3's budget).
	var far := size.length()
	var ray_pts := PackedVector2Array()
	var ray_cols := PackedColorArray()
	for k in RAYS:
		var a := TAU * k / RAYS + time * TAU / 120.0
		var w := 0.07 if k % 2 == 0 else 0.04
		var col := Color(glow.lightened(0.4), 0.07 if k % 2 == 0 else 0.045)
		ray_pts.append_array([c, c + Vector2.from_angle(a - w) * far, c + Vector2.from_angle(a + w) * far])
		ray_cols.append_array([col, col, col])
	_draw_triangles(ray_pts, ray_cols)
	draw_texture_rect(_glow_texture, Rect2(c - Vector2.ONE * span * 1.25, Vector2.ONE * span * 2.5), false)
	if flash > 0.0:
		var ring := span * (1.6 - flash)
		draw_arc(c, ring, 0, TAU, 64, Color(Color.WHITE, 0.6 * flash), span * 0.08 * flash + 1.0)
		draw_texture_rect(_glow_texture, Rect2(c - Vector2.ONE * span * 1.6, Vector2.ONE * span * 3.2), false,
			Color(1, 1, 1, flash))
	# Motes: small sparks rising slowly through the glow, each on its own
	# beat; all of them one mesh too.
	var mote_pts := PackedVector2Array()
	var mote_cols := PackedColorArray()
	for k in MOTES:
		var seed_x := fposmod(sin(k * 12.9898) * 43758.5453, 1.0)
		var speed := 0.025 + 0.02 * fposmod(sin(k * 78.233) * 12345.678, 1.0)
		var y := 1.0 - fposmod(time * speed + k * 0.137, 1.0)
		var x := seed_x + 0.03 * sin(time * 0.8 + k)
		var fade := sin(PI * (1.0 - y))
		var p := Vector2(x * size.x, y * size.y)
		var radius := (1.5 + 2.0 * fposmod(k * 0.618, 1.0)) * size.x / 360.0
		_disc(mote_pts, mote_cols, p, radius * 2.2, Color(glow.lightened(0.5), 0.10 * fade))
		_disc(mote_pts, mote_cols, p, radius, Color(Color.WHITE, 0.55 * fade))
	_draw_triangles(mote_pts, mote_cols)


## A small disc as a fan of triangles, added to a batch.
static func _disc(pts: PackedVector2Array, cols: PackedColorArray, at: Vector2, radius: float, col: Color) -> void:
	for k in 8:
		pts.append_array([at, at + Vector2.from_angle(TAU * k / 8.0) * radius,
			at + Vector2.from_angle(TAU * (k + 1) / 8.0) * radius])
		cols.append_array([col, col, col])


## Draws a batch of coloured triangles in one call.
func _draw_triangles(pts: PackedVector2Array, cols: PackedColorArray) -> void:
	if pts.is_empty():
		return
	var indices := PackedInt32Array()
	indices.resize(pts.size())
	for i in pts.size():
		indices[i] = i
	RenderingServer.canvas_item_add_triangle_array(get_canvas_item(), indices, pts, cols)
