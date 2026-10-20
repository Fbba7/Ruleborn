class_name StageHero
extends Control
## A small 3D stage for a character, or a few side by side (§21.3, §23.2):
## each on a patch of its school's realm floating in the menus' night, lit
## by §21.3's look from three points — a warm key, a cool fill from the
## sky, and a rim in the school's colour (§21.2) — turning slowly to show
## its shape. A drag spins it; a tap plays an action. The Character screen,
## the Sage hall, Forms and Hatch stand their characters here.

## Emitted with the figure's index when the player taps one.
signal tapped(index: int)

## §21.3 asks for an ink outline on characters; the design's handoff notes
## say the owner had it removed. One switch, defaulting to §21.3.
const INKED := true
## The sway either side of the three-quarter view, in radians, and its
## period in seconds: slow enough to read the shape, never the back.
const SWAY := 0.55
const SWAY_SECONDS := 9.0
## A drag's turn, in radians a pixel, and how fast a spin settles.
const DRAG_TURN := 0.012
const SETTLE := 2.2
## How long a tapped action plays, in seconds.
const ACTION_SECONDS := 0.9
const FOV := 24.0
## §21.3's three points: a warm key from above and in front, the night's
## violet as the fill (shade is never black), and a rim from behind.
const KEY := Color("#FFE6C8")
const KEY_ENERGY := 0.8
const FILL := Color("#8E7FD8")
const FILL_ENERGY := 0.42
const RIM_ENERGY := 0.6

static var _toon: Shader = load("res://world/toon.gdshader")
static var _outline: Shader = load("res://world/outline.gdshader")

var backdrop: StageHeroBackdrop
var container: SubViewportContainer
var viewport: SubViewport
var world: Node3D
var camera: Camera3D
var key_light: DirectionalLight3D
var rim_light: DirectionalLight3D
## One turntable a figure: its pedestal and the figure on it.
var tables: Array[Node3D] = []
var figures: Array[Node3D] = []
var kinds: Array[String] = []
## The stage's school, whose colour is in the glow and the rim.
var school := "motion"
## Seconds the stage has run; a shot sets it, so a still is the same each time.
var time := 0.0
## Whether the stage moves by itself (§20.8's reduced motion stills it).
var moving := true
var _spin := 0.0
var _spin_speed := 0.0
var _press := Vector2.ZERO
var _pressed := false
var _dragged := 0.0
var _actions: Array[float] = []


func _init() -> void:
	clip_contents = true
	mouse_filter = Control.MOUSE_FILTER_PASS
	backdrop = StageHeroBackdrop.new()
	add_child(backdrop)
	container = SubViewportContainer.new()
	container.stretch = true
	container.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(container)
	viewport = SubViewport.new()
	viewport.own_world_3d = true
	viewport.transparent_bg = true
	viewport.msaa_3d = Viewport.MSAA_4X
	viewport.handle_input_locally = false
	container.add_child(viewport)
	world = Node3D.new()
	viewport.add_child(world)
	_light()
	camera = Camera3D.new()
	camera.fov = FOV
	camera.near = 0.05
	camera.far = 60.0
	world.add_child(camera)
	moving = not Settings.reduced_motion


## The figure for a kind in a look ("" for its own, a note's name for that
## form, "guard" for its guard form). Until the characters' models land this
## is a stand-in (StageHeroSculpt); swapping it is this one line.
static func make_figure(kind: String, look := "") -> Node3D:
	return _stand_in(kind, look)


## A material in §21.3's look, its rim in `rim`; inked when INKED.
static func toon(rim: Color, inked := INKED) -> ShaderMaterial:
	var m := ShaderMaterial.new()
	m.shader = _toon
	m.set_shader_parameter("glow_from_alpha", 1.0)
	m.set_shader_parameter("rim_colour", rim.lightened(0.45))
	m.set_shader_parameter("rim_strength", 0.5)
	if inked:
		var o := ShaderMaterial.new()
		o.shader = _outline
		o.set_shader_parameter("width_px", 2.0)
		m.next_pass = o
	return m


## Stands `list` of kinds on the stage, side by side, each in its look from
## `looks` (the same index; "" when missing); the stage takes the first
## one's school.
func show_kinds(list: Array, looks: Array = []) -> void:
	for t in tables:
		t.queue_free()
	tables.clear()
	figures.clear()
	kinds.clear()
	_actions.clear()
	if list.is_empty():
		return
	school = StageHeroFigure.school(StageHeroFigure.key(str(list[0])))
	var rim: Color = Palette.SCHOOL.get(school, Palette.MOTION)
	backdrop.set_glow(rim)
	rim_light.light_color = rim.lightened(0.25)
	var gap := 0.0
	for k: Variant in list:
		gap = maxf(gap, StageHeroFigure.height(StageHeroFigure.key(str(k))))
	gap = maxf(gap * 0.95, 0.75)
	for i in list.size():
		var kind := StageHeroFigure.key(str(list[i]))
		var table := Node3D.new()
		table.position = Vector3((i - (list.size() - 1) / 2.0) * gap, 0, 0)
		world.add_child(table)
		var h := StageHeroFigure.height(kind)
		var own_school := StageHeroFigure.school(kind)
		var ground := MeshInstance3D.new()
		ground.mesh = StageHeroFigure.pedestal(own_school, maxf(0.42, h * 0.55))
		ground.material_override = toon(rim, false)
		table.add_child(ground)
		var blob := StageHeroFigure.shadow_disc()
		blob.scale = Vector3.ONE * h * 0.75
		blob.position.y = 0.045
		table.add_child(blob)
		var figure := make_figure(kind, str(looks[i]) if i < looks.size() else "")
		figure.position.y = 0.04
		table.add_child(figure)
		tables.append(table)
		figures.append(figure)
		kinds.append(kind)
		_actions.append(-1.0)
	_frame()
	_pose()


## Plays the tapped action on figure `index`: a hop and a twirl for a
## stand-in, the model's ability clip once the models land.
func act(index: int) -> void:
	if index < 0 or index >= figures.size():
		return
	_actions[index] = 0.0
	if figures[index].has_method("play"):
		figures[index].call("play", "ability")


## Sets the stage's clock, for a still that is the same every time.
func at_time(seconds: float) -> void:
	time = seconds
	backdrop.time = seconds
	_pose()
	backdrop.queue_redraw()


func _process(delta: float) -> void:
	if not is_visible_in_tree():
		return
	if moving:
		time += delta
		backdrop.advance(delta)
	for i in _actions.size():
		if _actions[i] >= 0.0:
			_actions[i] += delta
			if _actions[i] > ACTION_SECONDS:
				_actions[i] = -1.0
	if not _pressed:
		_spin_speed = lerpf(_spin_speed, 0.0, clampf(delta * SETTLE, 0.0, 1.0))
		_spin += _spin_speed * delta
		_spin = lerpf(_spin, 0.0, clampf(delta * 0.6, 0.0, 1.0))
	_pose()


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and (event as InputEventMouseButton).button_index == MOUSE_BUTTON_LEFT:
		var b := event as InputEventMouseButton
		if b.pressed:
			_pressed = true
			_press = b.position
			_dragged = 0.0
		elif _pressed:
			_pressed = false
			if _dragged < 12.0:
				var i := _nearest(b.position)
				act(i)
				tapped.emit(i)
	elif event is InputEventMouseMotion and _pressed:
		var m := event as InputEventMouseMotion
		_dragged += absf(m.relative.x)
		if absf(m.relative.x) > absf(m.relative.y):
			_spin += m.relative.x * DRAG_TURN
			_spin_speed = m.relative.x * DRAG_TURN * 30.0
			accept_event()


## The figure whose turntable is nearest a point on the stage.
func _nearest(at: Vector2) -> int:
	var best := 0
	var best_d := INF
	var scale_by := Vector2(viewport.size) / maxf(1.0, size.x) if size.x > 0.0 else Vector2.ONE
	for i in tables.size():
		var p := camera.unproject_position(tables[i].global_position + Vector3.UP * 0.4)
		var d := (p / maxf(scale_by.x, 0.001)).distance_to(at)
		if d < best_d:
			best_d = d
			best = i
	return best


func _light() -> void:
	var env := Environment.new()
	env.background_mode = Environment.BG_CLEAR_COLOR
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = FILL
	env.ambient_light_energy = FILL_ENERGY
	env.tonemap_mode = Environment.TONE_MAPPER_LINEAR
	var env_node := WorldEnvironment.new()
	env_node.environment = env
	world.add_child(env_node)
	key_light = DirectionalLight3D.new()
	key_light.light_color = KEY
	key_light.light_energy = KEY_ENERGY
	key_light.shadow_enabled = true
	key_light.directional_shadow_mode = DirectionalLight3D.SHADOW_ORTHOGONAL
	key_light.directional_shadow_max_distance = 8.0
	key_light.rotation_degrees = Vector3(-42, 28, 0)
	world.add_child(key_light)
	rim_light = DirectionalLight3D.new()
	rim_light.light_energy = RIM_ENERGY
	rim_light.rotation_degrees = Vector3(-18, 200, 0)
	world.add_child(rim_light)


## Places the camera so every figure and its ground fit, a little below
## centre, as the design's hero view frames one.
func _frame() -> void:
	var tall := 0.0
	for k: String in kinds:
		tall = maxf(tall, StageHeroFigure.height(k))
	var wide := (tables[-1].position.x - tables[0].position.x) + tall * 1.3 if tables.size() > 1 else tall * 1.3
	var aspect := maxf(0.2, size.x / maxf(1.0, size.y)) if size.y > 0.0 else 1.0
	var need_h := maxf(tall * 1.75, wide / aspect)
	var dist := need_h * 0.5 / tan(deg_to_rad(FOV) * 0.5)
	var target := Vector3(0, tall * 0.42, 0)
	camera.position = target + Vector3(0, 0.32, 1.0).normalized() * dist
	camera.look_at(target)


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED and not tables.is_empty():
		_frame()


## Each figure's turn, breath and action at the stage's time.
func _pose() -> void:
	var sway := SWAY * sin(time * TAU / SWAY_SECONDS) if moving else 0.0
	for i in tables.size():
		var table := tables[i]
		table.rotation.y = -0.45 + sway * 0.6 + _spin + i * 0.0
		var f := figures[i]
		var beat := time * 2.2 + i * 1.3
		var breath := sin(beat) * 0.025 if moving else 0.0
		f.scale = Vector3(1.0 - breath * 0.5, 1.0 + breath, 1.0 - breath * 0.5)
		f.position.y = 0.04
		f.rotation.y = 0.0
		var a: float = _actions[i] if i < _actions.size() else -1.0
		if a >= 0.0:
			var u := a / ACTION_SECONDS
			var hop := sin(clampf(u * 1.25, 0.0, 1.0) * PI)
			var squash := 0.18 * (sin(u * PI * 4.0) * (1.0 - u))
			f.position.y += hop * StageHeroFigure.height(kinds[i]) * 0.45
			f.rotation.y = TAU * clampf(u * 1.25, 0.0, 1.0)
			f.scale = Vector3(1.0 + squash, 1.0 - squash, 1.0 + squash)


## The stand-in: StageHeroSculpt's figure for the kind, grown to its height.
static func _stand_in(kind: String, look: String) -> Node3D:
	var root := Node3D.new()
	var mi := MeshInstance3D.new()
	mi.mesh = StageHeroSculpt.of(kind, look)
	var rim: Color = Palette.SCHOOL.get(StageHeroFigure.school(kind), Palette.MOTION)
	mi.material_override = toon(rim)
	mi.scale = Vector3.ONE * StageHeroFigure.height(kind)
	root.add_child(mi)
	root.set_meta("kind", kind)
	root.set_meta("look", look)
	return root
