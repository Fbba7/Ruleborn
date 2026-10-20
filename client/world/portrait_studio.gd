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
	size = Vector2i(SIZE, SIZE)
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


func ask(kind: String, look: String, texture: ImageTexture) -> void:
	_jobs.append([kind, look, texture])
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
	while not _jobs.is_empty():
		var job: Array = _jobs.pop_front()
		var kind: String = job[0]
		var look: String = job[1]
		var figure := StageHero.make_figure(kind, "" if look == "shadow" else look)
		if look == "shadow":
			_shadow(figure)
		figure.rotation.y = -0.35
		world.add_child(figure)
		_frame(kind)
		render_target_update_mode = SubViewport.UPDATE_ONCE
		await RenderingServer.frame_post_draw
		var image := get_texture().get_image()
		if image != null and not image.is_empty():
			image.convert(Image.FORMAT_RGBA8)
			(job[2] as ImageTexture).set_image(image)
		figure.queue_free()
	_busy = false


## Head and shoulders: the top two-thirds of the figure, a little from the
## side and above, as the design's portraits frame it.
func _frame(kind: String) -> void:
	var h := StageHeroFigure.height(kind)
	var target := Vector3(0, h * 0.6, 0)
	var view_h := h * 0.95
	var dist := view_h * 0.5 / tan(deg_to_rad(camera.fov) * 0.5)
	camera.position = target + Vector3(0.0, 0.22, 1.0).normalized() * dist
	camera.look_at(target)


## A locked card's silhouette: the figure in one flat ink.
func _shadow(figure: Node3D) -> void:
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.albedo_color = Color("#2A1E52")
	for mi: MeshInstance3D in figure.find_children("*", "MeshInstance3D", true, false):
		mi.material_override = m
