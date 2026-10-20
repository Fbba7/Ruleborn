class_name LookPaint
extends RefCounted
## The island's two painted textures, drawn in code at start-up as the
## Screens v3 diorama draws them on a canvas (realm-diorama.js:489–497):
## a meadow of soft blots, upward brush strokes, grass tufts and a few
## flower dots, and a rock face of strata bands, pebbles and cracks. Both are
## grey, so the island's vertex colour paints them; both tile. Hand-painted
## gradients only, nothing photographic (§21.3); everything generated
## (§21.11). Each is drawn once a run and shared.

## The meadow's side in pixels, and the rock's width and height.
const GRASS := 256
const ROCK_W := 256
const ROCK_H := 128

static var _grass: ImageTexture
static var _rock: ImageTexture


## The meadow texture.
static func grass() -> ImageTexture:
	if _grass == null:
		_grass = ImageTexture.create_from_image(_grass_image())
	return _grass


## The strata texture of the rim bands and the rock cone.
static func rock() -> ImageTexture:
	if _rock == null:
		_rock = ImageTexture.create_from_image(_rock_image())
	return _rock


## A seeded random stream, the same on every phone.
static func _rng(s: int) -> RandomNumberGenerator:
	var r := RandomNumberGenerator.new()
	r.seed = s
	return r


static func _grass_image() -> Image:
	var n := GRASS
	var px := PackedByteArray()
	px.resize(n * n)
	var r := _rng(4211)
	# Soft blots of light and shade, as tileable value noise of two scales.
	var coarse := _lattice(r, 6)
	var fine := _lattice(r, 14)
	for y in n:
		for x in n:
			var u := float(x) / n
			var v := float(y) / n
			var blot := _sample(coarse, 6, u, v) * 0.65 + _sample(fine, 14, u, v) * 0.35
			px[y * n + x] = clampi(int(196.0 + (blot - 0.5) * 105.0), 0, 255)
	# Upward brush strokes, light and dark.
	for i in 2600:
		var x0 := r.randf() * n
		var y0 := r.randf() * n
		var l := 2.5 + r.randf() * 4.5
		var a := -PI / 2.0 + (r.randf() - 0.5) * 0.9
		var c := 255 if r.randf() < 0.55 else 112
		var alpha := 0.22 + r.randf() * 0.32
		var w := 1 if r.randf() < 0.6 else 2
		for s in int(l) + 1:
			var p := Vector2(x0, y0) + Vector2(cos(a), sin(a)) * s
			for d in w:
				_blend(px, n, n, int(p.x) + d, int(p.y), c, alpha)
	# Little fans of grass, darker and lighter.
	for i in 300:
		var x0 := r.randf() * n
		var y0 := r.randf() * n
		var dark := r.randf() < 0.55
		var blades := 3 + r.randi() % 3
		for k in blades:
			var a := -PI / 2.0 + (k - (blades - 1) / 2.0) * 0.35
			var l := 3.5 + r.randf() * 3.0
			for s in int(l) + 1:
				_blend(px, n, n, int(x0 + cos(a) * s), int(y0 + sin(a) * s), 72 if dark else 250, 0.4)
	# A few dots of flower.
	for i in 40:
		var x0 := int(r.randf() * n)
		var y0 := int(r.randf() * n)
		for d: Vector2i in [Vector2i(0, 0), Vector2i(1, 0), Vector2i(0, 1), Vector2i(1, 1)]:
			_blend(px, n, n, x0 + d.x, y0 + d.y, 255, 0.8)
	var img := Image.create_from_data(n, n, false, Image.FORMAT_L8, px)
	img.generate_mipmaps()
	return img


static func _rock_image() -> Image:
	var w := ROCK_W
	var h := ROCK_H
	var px := PackedByteArray()
	px.resize(w * h)
	px.fill(207)
	var r := _rng(907)
	# Strata: bands of stone, each with a dark seam beneath.
	var y := 0
	while y < h:
		var band := 4 + r.randi() % 11
		var v := 170 + r.randi() % 80
		for yy in range(y, mini(h, y + band)):
			for x in w:
				# A gentle lean along the band so it reads as rock, not ruled lines.
				px[yy * w + x] = v + int(6.0 * sin(x * 0.07 + y))
		for x in w:
			_blend(px, w, h, x, y + band - 1, 60, 0.35)
		y += band
	# Pebbles and lumps, lighter and darker.
	for i in 90:
		var cx := r.randf() * w
		var cy := r.randf() * h
		var rx := 6.0 + r.randf() * 25.0
		var ry := 3.0 + r.randf() * 8.0
		var c := 255 if r.randf() < 0.5 else 110
		for yy in range(int(cy - ry), int(cy + ry) + 1):
			for xx in range(int(cx - rx), int(cx + rx) + 1):
				var q := Vector2((xx - cx) / rx, (yy - cy) / ry)
				if q.length_squared() < 1.0:
					_blend(px, w, h, xx, yy, c, 0.28)
	# Cracks running down.
	for i in 30:
		var x := r.randf() * w
		var yy := r.randf() * h
		for k in 4:
			var nx := x + (r.randf() - 0.5) * 7.0
			var ny := yy + 3.0 + r.randf() * 6.0
			for s in 8:
				var p := Vector2(x, yy).lerp(Vector2(nx, ny), s / 8.0)
				_blend(px, w, h, int(p.x), int(p.y), 40, 0.4)
			x = nx
			yy = ny
	var img := Image.create_from_data(w, h, false, Image.FORMAT_L8, px)
	img.generate_mipmaps()
	return img


## Lays grey `c` over the pixel at (x, y), wrapped so the texture tiles.
static func _blend(px: PackedByteArray, w: int, h: int, x: int, y: int, c: int, alpha: float) -> void:
	var i := posmod(y, h) * w + posmod(x, w)
	px[i] = int(lerpf(px[i], c, alpha))


## A `cells` × `cells` lattice of random values, for tileable noise.
static func _lattice(r: RandomNumberGenerator, cells: int) -> PackedFloat32Array:
	var out := PackedFloat32Array()
	out.resize(cells * cells)
	for i in cells * cells:
		out[i] = r.randf()
	return out


## The lattice's value at (u, v) in [0, 1), smoothly between its cells and
## wrapping at the edges.
static func _sample(lat: PackedFloat32Array, cells: int, u: float, v: float) -> float:
	var x := u * cells
	var y := v * cells
	var x0 := floori(x)
	var y0 := floori(y)
	var fx := smoothstep(0.0, 1.0, x - x0)
	var fy := smoothstep(0.0, 1.0, y - y0)
	var i0 := posmod(x0, cells)
	var i1 := posmod(x0 + 1, cells)
	var j0 := posmod(y0, cells) * cells
	var j1 := posmod(y0 + 1, cells) * cells
	var top := lerpf(lat[j0 + i0], lat[j0 + i1], fx)
	var low := lerpf(lat[j1 + i0], lat[j1 + i1], fx)
	return lerpf(top, low, fy)
