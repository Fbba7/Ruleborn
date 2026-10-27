class_name PortraitStudio
extends SubViewport
## The one offscreen viewport every portrait is drawn in (Portrait): a
## figure at a time, in the hero stage's light, framed head and shoulders
## as the design's portraits are, read back once into the portrait's
## texture.

## The pixel size portraits are drawn at, square.
const SIZE := 256

var world: Node3D
var camera: Camera3D
var _jobs: Array[Array] = []
var _busy := false


func _init() -> void:
	size = Vector2i(SIZE * 2, SIZE * 2)
	own_world_3d = true
	transparent_bg = true
	msaa_3d = Viewport.MSAA_4X
	render_target_update_mode = SubViewport.UPDATE_DISABLED
	world = Node3D.new()
	add_child(world)
	var env := Environment.new()
	env.background_mode = Environment.BG_CLEAR_COLOR
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = StageHero.FILL
	env.ambient_light_energy = StageHero.FILL_ENERGY
	env.tonemap_mode = Environment.TONE_MAPPER_LINEAR
	var env_node := WorldEnvironment.new()
	env_node.environment = env
	world.add_child(env_node)
	var key := DirectionalLight3D.new()
	key.light_color = StageHero.KEY
	key.light_energy = StageHero.KEY_ENERGY
	key.rotation_degrees = Vector3(-38, 30, 0)
	world.add_child(key)
	var rim := DirectionalLight3D.new()
	rim.light_color = Color("#BFD8FF")
	rim.light_energy = StageHero.RIM_ENERGY
	rim.rotation_degrees = Vector3(-18, 200, 0)
	world.add_child(rim)
	camera = Camera3D.new()
	camera.fov = 22.0
	world.add_child(camera)


func ask(kind: String, look: String, texture: ImageTexture, bust := false) -> void:
	_jobs.append([kind, look, texture, bust])
	if not _busy:
		_run.call_deferred()


func idle() -> bool:
	return not _busy and _jobs.is_empty()


func _run() -> void:
	if _busy or not is_inside_tree():
		if not is_inside_tree() and not _busy:
			await tree_entered
			_run()
		return
	_busy = true
	await get_tree().process_frame
	while not _jobs.is_empty():
		var job: Array = _jobs.pop_front()
		var kind: String = job[0]
		var look: String = job[1]
		var figure := StageHero.make_figure(kind, "" if look == "shadow" else look)
		if look == "shadow":
			StageHero.shade(figure)
		figure.rotation.y = -0.35
		world.add_child(figure)
		_frame(kind, figure)
		var image: Image = null
		# The first draw after the viewport joins the tree can come back
		# empty; one more try then.
		for _attempt in 2:
			render_target_update_mode = SubViewport.UPDATE_ONCE
			await RenderingServer.frame_post_draw
			image = get_texture().get_image()
			if image != null and not image.is_empty() and image.get_used_rect().size.x > 0:
				break
		if image != null and not image.is_empty():
			image.convert(Image.FORMAT_RGBA8)
			(job[2] as ImageTexture).set_image(crop_bust(image) if bool(job[3]) else crop(image))
		figure.queue_free()
	_busy = false


## The whole figure, with room to spare: the portrait is cut from what is
## drawn (crop), so a kind's own height or props never mis-frame it.
func _frame(kind: String, _figure: Node3D) -> void:
	var h := StageHeroFigure.height(kind)
	var view_h := h * 2.2
	var target := Vector3(0, h * 0.62, 0)
	var dist := view_h * 0.5 / tan(deg_to_rad(camera.fov) * 0.5)
	camera.position = target + Vector3(0.0, 0.22, 1.0).normalized() * dist
	camera.look_at(target)


## A portrait cut from a render: a square from the top of what was drawn,
## the whole figure with a little air above, as the design's cards stand
## theirs; then SIZE across.
static func crop(image: Image) -> Image:
	var used := _body(image)
	if used.size.x < 4 or used.size.y < 4:
		image.resize(SIZE, SIZE, Image.INTERPOLATE_LANCZOS)
		return image
	# A tall, thin one (a heron) is cut above its feet, as the design does.
	var side := int(clampf(maxf(minf(used.size.y * 1.0, used.size.x * 2.2), used.size.x * 1.12), 8.0,
		float(image.get_width())))
	var x := clampi(int(used.position.x + used.size.x / 2.0 - side / 2.0), 0, image.get_width() - side)
	var y := clampi(used.position.y - int(side * 0.06), 0, image.get_height() - side)
	var out := image.get_region(Rect2i(x, y, side, side))
	out.resize(SIZE, SIZE, Image.INTERPOLATE_LANCZOS)
	return out


## A bust cut from a render: head and shoulders, square, centred on the
## head rather than on the whole figure, so a staff or a tail held out to
## one side never pulls the face off-centre. A round frame (the heist's
## crew row) fills with the face, as the design's portraits do.
static func crop_bust(image: Image) -> Image:
	var used := _body(image)
	if used.size.x < 4 or used.size.y < 4:
		return crop(image)
	# Ears, a crest or a flame stay in: the top is what is drawn at all.
	var top := mini(used.position.y, image.get_used_rect().position.y)
	var tall := used.end.y - top
	var side := int(clampf(minf(tall * 0.95, maxf(used.size.x * 0.9, tall * 0.62)), 8.0,
		float(mini(image.get_width(), image.get_height()))))
	# The head's middle: where the top fifth of the figure is drawn.
	var band := Rect2i(used.position.x, top, used.size.x, maxi(1, int(tall * 0.25)))
	var sum := 0.0
	var count := 0.0
	for y in range(band.position.y, band.end.y, 4):
		for x in range(band.position.x, band.end.x, 4):
			if image.get_pixel(x, y).a > 0.4:
				sum += x
				count += 1.0
	var mid := sum / count if count > 0.0 else used.position.x + used.size.x / 2.0
	var x := clampi(int(mid - side / 2.0), 0, image.get_width() - side)
	var y := clampi(top - int(side * 0.05), 0, image.get_height() - side)
	var out := image.get_region(Rect2i(x, y, side, side))
	out.resize(SIZE, SIZE, Image.INTERPOLATE_LANCZOS)
	return out


## Where the figure is drawn, leaving out a stray glint or a thin antenna
## tip: columns and rows with little drawn in them are trimmed from the
## edges, judged on a 64-pixel copy so it costs next to nothing.
static func _body(image: Image) -> Rect2i:
	var n := 64
	var small := image.duplicate() as Image
	small.resize(n, n, Image.INTERPOLATE_BILINEAR)
	var cols := PackedInt32Array()
	var rows := PackedInt32Array()
	cols.resize(n)
	rows.resize(n)
	for y in n:
		for x in n:
			if small.get_pixel(x, y).a > 0.4:
				cols[x] += 1
				rows[y] += 1
	var lo := Vector2i(n, n)
	var hi := Vector2i(-1, -1)
	for i in n:
		if cols[i] >= 2:
			lo.x = mini(lo.x, i)
			hi.x = maxi(hi.x, i)
		if rows[i] >= 2:
			lo.y = mini(lo.y, i)
			hi.y = maxi(hi.y, i)
	if hi.x < lo.x or hi.y < lo.y:
		return image.get_used_rect()
	var k := float(image.get_width()) / n
	return Rect2i(Vector2i(int(lo.x * k), int(lo.y * k)), Vector2i(int((hi.x - lo.x + 1) * k), int((hi.y - lo.y + 1) * k)))
