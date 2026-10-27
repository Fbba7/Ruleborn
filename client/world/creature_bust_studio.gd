extends SubViewport
## The one offscreen viewport CreatureBust draws in: a figure at a time in
## the hero light, turned a little as the design's portraits stand, framed
## on its own head and chest (the export's `head_top` and `chest` sockets)
## so a small kind and a tall one fill their discs alike; read back once,
## cut round and kept in the bust's texture.

## Drawn this many times larger than the bust, then shrunk, for clean edges.
const OVERSAMPLE := 2
## How much of a figure a bust shows: at least this share of its height,
## from the top of its head down (02-heist.png's crew show head and body to
## the hips), and never less than its head and chest in head spans.
const BODY := 0.8
const SPAN := 1.4
## Air above the head's top, as a share of the bust; the disc's ring cuts
## ears and flames as the design's does.
const HEADROOM := 0.07
## The Sages' disc stands its Sage lower, with the staff's lamp above
## (02-heist.png): a smaller share of the body, more air.
const SAGE_BODY := 0.66
const SAGE_HEADROOM := 0.3
## A kind's own framing where its proportions mislead: [the share of its
## height shown, as BODY; the headroom, as HEADROOM].
## The round owl and the stone-backed kinds are mostly head and back, so
## they show more of themselves.
const FRAME := {"featherkin": [1.08, 0.08], "quarryback": [1.1, 0.08], "glassgolem": [0.95, 0.07],
	"mossbear": [0.92, 0.07], "rambler": [0.98, 0.07], "emberling": [1.05, 0.04]}
## A Sage stands left of the middle, its staff's lamp at the right
## (02-heist.png's Sage disc), as a share of the bust.
const SAGE_ASIDE := 0.12
## The paint's lift toward warm white, against the hero view's: a disc is
## small, so the bust keeps more of its colour and its light steps.
const LIFT := 0.72
const RAMP_BIAS := 0.26
## The turn toward the light, radians: a three-quarter face.
const TURN := -0.32
## The camera's rise above the face, as a portrait looks a little down.
const RISE := 0.14

var world: Node3D
var camera: Camera3D
var _jobs: Array[Array] = []
var _busy := false


func _init() -> void:
	size = Vector2i(CreatureBust.SIZE * OVERSAMPLE, CreatureBust.SIZE * OVERSAMPLE)
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
	key.rotation_degrees = Vector3(-34, 28, 0)
	world.add_child(key)
	var rim := DirectionalLight3D.new()
	rim.light_color = Color("#BFD8FF")
	rim.light_energy = StageHero.RIM_ENERGY
	rim.rotation_degrees = Vector3(-18, 200, 0)
	world.add_child(rim)
	camera = Camera3D.new()
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.near = 0.05
	camera.far = 40.0
	world.add_child(camera)


func ask(kind: String, look: String, ground: Color, texture: ImageTexture) -> void:
	_jobs.append([kind, look, ground, texture])
	if not _busy:
		_run.call_deferred()


func idle() -> bool:
	return not _busy and _jobs.is_empty()


func _run() -> void:
	if _busy:
		return
	if not is_inside_tree():
		await tree_entered
	_busy = true
	await get_tree().process_frame
	while not _jobs.is_empty():
		var job: Array = _jobs.pop_front()
		var kind: String = job[0]
		var figure := StageHero.make_figure(kind, job[1], true)
		figure.rotation.y = TURN
		if job[1] != "guard":
			_drop_ink(figure)
		_deepen(figure)
		world.add_child(figure)
		# The bones' attachments take their places on the next frames.
		await get_tree().process_frame
		await get_tree().process_frame
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
			(job[3] as ImageTexture).set_image(round_cut(image, job[2]))
		figure.queue_free()
	_busy = false


## The camera on the head and body: from just over `head_top` down, centred
## between the head and the chest; a stand-in without sockets is framed on
## its height alone.
func _frame(kind: String, figure: Node3D) -> void:
	var model: CreatureModel = figure.get_meta("model", null)
	var entry: Dictionary = CreatureModel.manifest().get(kind, {})
	var tall := float(entry.get("body_height", entry.get("height", 1.0)))
	var top := Vector3(0, tall, 0)
	var chest := top * 0.6
	if model != null and model.socket(&"head_top") != null and model.socket(&"chest") != null:
		top = model.socket(&"head_top").global_position
		chest = model.socket(&"chest").global_position
	var sage := str(entry.get("group", "")) == "sage"
	var own: Array = FRAME.get(kind, [SAGE_BODY, SAGE_HEADROOM] if sage else [BODY, HEADROOM])
	var view := maxf(maxf(0.06, top.y - chest.y) * SPAN, tall * float(own[0]))
	var centre := Vector3((top.x + chest.x) * 0.5 + (view * SAGE_ASIDE if sage else 0.0),
		top.y + view * (float(own[1]) - 0.5), (top.z + chest.z) * 0.5)
	camera.size = view
	camera.position = centre + Vector3(0.0, RISE, 1.0).normalized() * 8.0
	camera.look_at(centre)


## The ink outline off: the design's portraits are drawn without one, and at
## a disc's size it reads as a dark seam inside the figure. A guard keeps its
## crimson ink, its form's mark.
static func _drop_ink(figure: Node3D) -> void:
	var model: CreatureModel = figure.get_meta("model", null)
	if model == null:
		return
	var m: Material = model.material()
	while m != null and m.next_pass != null:
		var next := m.next_pass as ShaderMaterial
		if next != null and next.shader != null and next.shader.resource_path.ends_with("creature_outline.gdshader"):
			m.next_pass = next.next_pass
		else:
			m = m.next_pass


## The hero view's paler paint taken back part way (LIFT, RAMP_BIAS).
static func _deepen(figure: Node3D) -> void:
	var model: CreatureModel = figure.get_meta("model", null)
	if model == null or model.material() == null:
		return
	var m := model.material()
	var lift: Variant = m.get_shader_parameter("lift")
	if lift != null:
		m.set_shader_parameter("lift", float(lift) * LIFT)
	m.set_shader_parameter("ramp_bias", RAMP_BIAS)


## A drawn bust shrunk to its size and cut to a circle, its edge feathered a
## pixel, so a disc can take it as it is; over a lit disc of `ground` when
## that is not clear: the colour lifted toward warm white at the middle and
## deepened at the rim, as the design's discs are.
static func round_cut(image: Image, ground: Color) -> Image:
	image.convert(Image.FORMAT_RGBA8)
	var side := CreatureBust.SIZE
	image.resize(side, side, Image.INTERPOLATE_LANCZOS)
	var r := side * 0.5
	var lit := Vector2(r, r * 0.8)
	var middle := ground.lerp(Color("#FFF4DC"), 0.55)
	var rim := ground.darkened(0.18)
	for y in side:
		for x in side:
			var p := Vector2(x + 0.5, y + 0.5)
			var d := p.distance_to(Vector2(r, r))
			var edge := clampf((r - d) / 1.5, 0.0, 1.0)
			if ground.a <= 0.0 and edge >= 1.0:
				continue
			var c := image.get_pixel(x, y)
			if ground.a > 0.0:
				var t := clampf(p.distance_to(lit) / (r * 1.15), 0.0, 1.0)
				var back := middle.lerp(ground, smoothstep(0.0, 0.75, t)).lerp(rim, smoothstep(0.75, 1.0, t))
				c = Color(back.lerp(Color(c, 1.0), c.a), 1.0)
			c.a *= edge
			image.set_pixel(x, y, c)
	return image
