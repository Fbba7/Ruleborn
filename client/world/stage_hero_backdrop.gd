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
	g.offsets = PackedFloat32Array([0.0, 0.35, 0.7, 1.0])
	g.colors = PackedColorArray([Color(colour.lightened(0.35), 0.85), Color(colour, 0.5),
		Color(colour.darkened(0.2), 0.14), Color(colour.darkened(0.4), 0.0)])
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
	# Rays: long thin wedges from the glow, turning once in two minutes.
	var far := size.length()
	for k in RAYS:
		var a := TAU * k / RAYS + time * TAU / 120.0
		var w := 0.07 if k % 2 == 0 else 0.04
		var pts := PackedVector2Array([c, c + Vector2.from_angle(a - w) * far, c + Vector2.from_angle(a + w) * far])
		draw_colored_polygon(pts, Color(glow.lightened(0.4), 0.07 if k % 2 == 0 else 0.045))
	draw_texture_rect(_glow_texture, Rect2(c - Vector2.ONE * span * 1.25, Vector2.ONE * span * 2.5), false)
	# Motes: small sparks rising slowly through the glow, each on its own beat.
	for k in MOTES:
		var seed_x := fposmod(sin(k * 12.9898) * 43758.5453, 1.0)
		var speed := 0.025 + 0.02 * fposmod(sin(k * 78.233) * 12345.678, 1.0)
		var y := 1.0 - fposmod(time * speed + k * 0.137, 1.0)
		var x := seed_x + 0.03 * sin(time * 0.8 + k)
		var fade := sin(PI * (1.0 - y))
		var p := Vector2(x * size.x, y * size.y)
		var radius := (1.5 + 2.0 * fposmod(k * 0.618, 1.0)) * size.x / 360.0
		draw_circle(p, radius * 2.2, Color(glow.lightened(0.5), 0.10 * fade))
		draw_circle(p, radius, Color(Color.WHITE, 0.55 * fade))
