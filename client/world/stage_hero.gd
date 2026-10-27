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
## How often a standing model plays its second idle, in seconds.
const IDLE2_EVERY := 7.0
## §21.3's three points: a warm key from above and in front, the night's
## violet as the fill (shade is never black), and a rim from behind.
const KEY := Color("#FFE6C8")
const KEY_ENERGY := 0.78
const FILL := Color("#C4BCEE")
const FILL_ENERGY := 0.62
const RIM_ENERGY := 0.6
## How much more a close view lifts a model's lit paint, and where its light
## steps begin (creature_look.gdshaderinc's `lift` and `ramp_bias`).
const CLOSE_LIFT := 1.7
const CLOSE_RAMP_BIAS := 0.34

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
## What stands round them all: a hall's floor and arches.
var scenery: Node3D
var figures: Array[Node3D] = []
var kinds: Array[String] = []
## The stage's school, whose colour is in the glow and the rim.
var school := "motion"
## Seconds the stage has run; a shot sets it, so a still is the same each time.
var time := 0.0
## Whether the stage moves by itself (§20.8's reduced motion stills it).
var moving := true
## Sky kept clear above the figures for words over the stage, as a share of
## the frame's height (the first launch's title).
var headroom := 0.0
var _spin := 0.0
var _spin_speed := 0.0
var _press := Vector2.ZERO
var _pressed := false
var _dragged := 0.0
var _actions: Array[float] = []
## Seconds since a hatch's reveal began, or below zero when none plays.
var _reveal := -1.0
var _shells: Array[Node3D] = []
## Seconds until the figures switch between their two idles (§21.6's "two
## idles"), so a character on a stage never loops one clip for long.
var _fidget := IDLE2_EVERY


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
	# The stage's foot fades into the page's night, so the island's roots
	# hang into the same dark the cards stand on and no edge shows.
	var foot := TextureRect.new()
	var fade := GradientTexture2D.new()
	fade.fill_from = Vector2(0, 0)
	fade.fill_to = Vector2(0, 1)
	fade.width = 4
	fade.height = 64
	var ramp := Gradient.new()
	ramp.set_color(0, Color(StageHeroBackdrop.NIGHT_FOOT, 0.0))
	ramp.set_color(1, StageHeroBackdrop.NIGHT_FOOT)
	fade.gradient = ramp
	foot.texture = fade
	foot.stretch_mode = TextureRect.STRETCH_SCALE
	foot.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	foot.anchor_left = 0.0
	foot.anchor_right = 1.0
	foot.anchor_top = 0.8
	foot.anchor_bottom = 1.0
	foot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(foot)
	world = Node3D.new()
	viewport.add_child(world)
	_light()
	scenery = Node3D.new()
	world.add_child(scenery)
	camera = Camera3D.new()
	camera.fov = FOV
	camera.near = 0.05
	camera.far = 60.0
	world.add_child(camera)
	moving = not Settings.reduced_motion


## The figure for a kind in a look ("" for its own, a note's name for that
## form, "guard" for its guard form): the design's model (CreatureModel)
## where the export has the kind, else StageHeroSculpt's stand-in. The model
## sits in a node of the stage's own, so the stage's sway and hop never fight
## its facing; `close` asks for its fur, as only a close view affords.
static func make_figure(kind: String, look := "", close := false) -> Node3D:
	# The export names a kind without its underscores ("glassgolem").
	var exported := kind.replace("_", "")
	if not CreatureModel.manifest().has(exported):
		return _stand_in(kind, look)
	var fur := int(((CreatureModel.manifest()[exported] as Dictionary).get("fur", {}) as Dictionary).get("shells", 0))
	var model := CreatureModel.make(StringName(exported), fur if close else 0)
	model.face(Vector3.BACK)
	if look in ["hush", "spark", "echo"]:
		model.set_form(StringName(look))
	elif look == "guard":
		model.set_guard(true)
	_close_look(model)
	var root := Node3D.new()
	root.add_child(model)
	root.set_meta("kind", kind)
	root.set_meta("look", look)
	root.set_meta("model", model)
	return root


## A material in §21.3's look, its rim in `rim`; inked when INKED. Ground
## is drawn a step darker than a figure, so the character is the brightest
## thing on the stage.
static func toon(rim: Color, inked := INKED, ground := false) -> ShaderMaterial:
	var m := ShaderMaterial.new()
	m.shader = _toon
	if ground:
		m.set_shader_parameter("tint", Color(0.8, 0.78, 0.84))
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
## `looks` (the same index; "" when missing; "shadow" for a silhouette, as a
## locked one shows); the stage takes the first one's school. `ground`
## "hall" stands them on one floor of flagstones under arches, "island" on
## one island together; otherwise each has its own patch.
func show_kinds(list: Array, looks: Array = [], ground := "") -> void:
	for t in tables:
		t.queue_free()
	for n in scenery.get_children():
		n.queue_free()
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
	var hall := ground == "hall"
	var shared := hall or ground == "island"
	gap = maxf(gap * (0.62 if shared else 0.95), 0.75)
	if shared:
		if hall:
			var hall_mesh := MeshInstance3D.new()
			hall_mesh.mesh = StageHeroFigure.hall(gap * list.size())
			# The floor in T2's painted stone, the look the realm's rock takes.
			var floor_paint := ShaderMaterial.new()
			floor_paint.shader = load("res://world/look_ground.gdshader")
			floor_paint.set_shader_parameter("paint", LookPaint.rock())
			floor_paint.set_shader_parameter("paint_strength", 0.7)
			floor_paint.set_shader_parameter("world_scale", 1.6)
			floor_paint.set_shader_parameter("tint", Color(0.82, 0.78, 0.8))
			hall_mesh.material_override = floor_paint
			scenery.add_child(hall_mesh)
		else:
			scenery.add_child(StageHeroFigure.realm_ground(school, gap * list.size() * 0.4))
	for i in list.size():
		var kind := StageHeroFigure.key(str(list[i]))
		var table := Node3D.new()
		var x := (i - (list.size() - 1) / 2.0) * gap
		# Together, they stand on an arc, the middle ones a little forward.
		table.position = Vector3(x, 0, 0) if not shared or hall else Vector3(x * 0.85, 0, 0.25 - absf(x) * 0.35)
		world.add_child(table)
		var h := StageHeroFigure.height(kind)
		var own_school := StageHeroFigure.school(kind)
		if not shared:
			if list.size() == 1:
				table.add_child(StageHeroFigure.realm_ground(own_school, maxf(0.3, h * 0.55)))
			else:
				# A row of figures shares §21.3's draw-call budget: each stands on
				# the one-mesh patch, not the realm's three-piece island.
				var patch := MeshInstance3D.new()
				patch.mesh = StageHeroFigure.pedestal(own_school, maxf(0.3, h * 0.4))
				patch.material_override = toon(rim, false, true)
				table.add_child(patch)
		var blob := StageHeroFigure.shadow_disc()
		blob.scale = Vector3.ONE * h * 0.75
		blob.position.y = 0.045
		table.add_child(blob)
		var look := str(looks[i]) if i < looks.size() else ""
		var figure := make_figure(kind, "" if look == "shadow" else look, list.size() == 1)
		if look == "shadow":
			shade(figure)
		figure.position.y = 0.04
		table.add_child(figure)
		tables.append(table)
		figures.append(figure)
		kinds.append(kind)
		_actions.append(-1.0)
	_frame()
	_pose()


## Far islands behind the stage, each a realm of one of `schools` as T2
## builds it, small with distance and hung at different heights: the
## universe a welcome stands in (the first launch). Cleared by show_kinds.
func add_far_islands(schools: Array) -> void:
	var span := 1.6 * maxf(1.0, float(tables.size()) * 0.5)
	for i: int in schools.size():
		var isle := StageHeroFigure.realm_ground(str(schools[i]), 0.55 + 0.15 * float(i % 2))
		var along := float(i) / maxf(1.0, float(schools.size() - 1))
		isle.position = Vector3(lerpf(-span, span, along), -0.2 + 0.7 * sin(float(i) * 2.3), -4.5 - 1.6 * float(i % 3))
		isle.rotation.y = float(i) * 1.7
		scenery.add_child(isle)


## What a figure takes up, in its own space: every mesh under it at rest,
## leaving out flat ones (a ground shadow); where the model has a skinned
## body, that body alone, so a staff or a lamp pole never shrinks the frame.
static func bounds(figure: Node3D) -> AABB:
	var out := AABB()
	var first := true
	var all := figure.find_children("*", "VisualInstance3D", true, false)
	var bodies := all.filter(func(v: Node) -> bool: return v.get_parent() is Skeleton3D)
	for vi: VisualInstance3D in (bodies if not bodies.is_empty() else all):
		var box := vi.get_aabb()
		if box.size.y < 0.02 or not vi.visible:
			continue
		var t := Transform3D()
		var n: Node = vi
		while n != null and n != figure:
			if n is Node3D:
				t = (n as Node3D).transform * t
			n = n.get_parent()
		box = t * box
		out = box if first else out.merge(box)
		first = false
	return out


## A locked one's silhouette: the figure in one flat night ink.
static func shade(figure: Node3D) -> void:
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.albedo_color = Color("#0E0A22")
	for mi: MeshInstance3D in figure.find_children("*", "MeshInstance3D", true, false):
		# A ground shadow stays a shadow, not a dark plate.
		if mi.get_aabb().size.y < 0.02:
			continue
		mi.material_override = m


## Plays the tapped action on figure `index`: a hop and a twirl for a
## stand-in, the model's ability clip once the models land.
func act(index: int, clip := &"ability") -> void:
	if index < 0 or index >= figures.size():
		return
	_actions[index] = 0.0
	var model: Variant = figures[index].get_meta("model", null)
	if model is CreatureModel:
		(model as CreatureModel).play(clip)


## A success to share (a level bought, a rest ended): every figure on the
## stage celebrates, with a hop.
func cheer() -> void:
	for i in figures.size():
		act(i, &"celebrate")


## A hatch's moment (§23.2's Hatch): the egg's shell bursts in two, a ring
## of light flares, and the newborn pops up with a squash and a twirl.
func reveal() -> void:
	if figures.is_empty():
		return
	if not moving:
		# Reduced motion's form: the newborn is simply there.
		return
	_reveal = 0.0
	for sh in _shells:
		if is_instance_valid(sh):
			sh.queue_free()
	_shells.clear()
	var rim: Color = Palette.SCHOOL.get(school, Palette.MOTION)
	for side: float in [-1.0, 1.0]:
		var mi := MeshInstance3D.new()
		mi.mesh = StageHeroSculpt.of("shell")
		var shell_paint := toon(rim)
		shell_paint.set_shader_parameter("tint", Color(0.84, 0.82, 0.86))
		mi.material_override = shell_paint
		mi.scale = Vector3.ONE * 0.45
		mi.set_meta("side", side)
		tables[0].add_child(mi)
		_shells.append(mi)
	act(0)
	var model: Variant = figures[0].get_meta("model", null)
	if model is CreatureModel:
		(model as CreatureModel).play(&"celebrate")


## Sets the stage's clock, for a still that is the same every time.
func at_time(seconds: float) -> void:
	time = seconds
	backdrop.time = seconds
	_pose()
	backdrop.queue_redraw()
	# Each model's clip too, held there while the stage is still.
	for f in figures:
		var model: Variant = f.get_meta("model", null)
		if not (model is CreatureModel):
			continue
		var p := (model as CreatureModel).player()
		if p.current_animation == "" or p.current_animation_length <= 0.0:
			continue
		p.seek(fmod(seconds, p.current_animation_length), true)
		if not moving:
			p.pause()


func _process(delta: float) -> void:
	if not is_visible_in_tree():
		return
	if moving:
		time += delta
		backdrop.advance(delta)
		_fidget -= delta
		if _fidget <= 0.0:
			_fidget = IDLE2_EVERY
			for f in figures:
				var model: Variant = f.get_meta("model", null)
				if not (model is CreatureModel):
					continue
				# The two idles take turns (both loop in the model).
				var c := model as CreatureModel
				if c.clip == &"idle":
					c.play(&"idle2")
				elif c.clip == &"idle2":
					c.play(&"idle")
	for i in _actions.size():
		if _actions[i] >= 0.0:
			_actions[i] += delta
			if _actions[i] > ACTION_SECONDS:
				_actions[i] = -1.0
				var model: Variant = figures[i].get_meta("model", null)
				if model is CreatureModel:
					(model as CreatureModel).play(&"idle")
	if _reveal >= 0.0:
		_reveal += delta
		if _reveal > 1.6:
			_reveal = -1.0
			for sh in _shells:
				if is_instance_valid(sh):
					sh.queue_free()
			_shells.clear()
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
	for i in figures.size():
		var b := bounds(figures[i])
		var top := b.end.y if b.size.y > 0.0 else StageHeroFigure.height(kinds[i])
		# A flier's clip lifts it off the ground: frame the hover too.
		tall = maxf(tall, top * (1.45 if kinds[i] in StageHeroFigure.FLIERS else 1.0))
	var wide := (tables[-1].position.x - tables[0].position.x) + tall * 0.95 if tables.size() > 1 else tall * 1.3
	var aspect := maxf(0.2, size.x / maxf(1.0, size.y)) if size.y > 0.0 else 1.0
	var need_h := maxf(tall * 1.75, wide / aspect) * (1.0 + headroom)
	var dist := need_h * 0.5 / tan(deg_to_rad(FOV) * 0.5)
	var target := Vector3(0, tall * (0.42 + headroom * 0.9), 0)
	var eye := target + Vector3(0, 0.32, 1.0).normalized() * dist
	camera.transform = Transform3D(Basis.looking_at(target - eye, Vector3.UP), eye)


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED and not tables.is_empty():
		_frame()


## Each figure's turn, breath and action at the stage's time.
func _pose() -> void:
	var sway := SWAY * sin(time * TAU / SWAY_SECONDS) if moving else 0.0
	for i in tables.size():
		var table := tables[i]
		table.rotation.y = -0.45 + sway * 0.6 + _spin
		var f := figures[i]
		var beat := time * 2.2 + i * 1.3
		var breath := sin(beat) * 0.025 if moving else 0.0
		f.scale = Vector3(1.0 - breath * 0.5, 1.0 + breath, 1.0 - breath * 0.5)
		f.position.y = 0.04
		f.rotation.y = 0.0
		f.rotation.z = 0.0
		if kinds[i] == "egg" and moving:
			# An egg about to hatch rocks now and then: three quick wobbles
			# every four seconds, dying away.
			var w := fposmod(time, 4.0)
			f.rotation.z = sin(w * 14.0) * 0.12 * exp(-w * 2.2) if w < 1.4 else 0.0
		var a: float = _actions[i] if i < _actions.size() else -1.0
		# Reduced motion (§20.8) keeps the clip and drops the hop and twirl.
		if a >= 0.0 and moving:
			var u := a / ACTION_SECONDS
			var hop := sin(clampf(u * 1.25, 0.0, 1.0) * PI)
			var squash := 0.18 * (sin(u * PI * 4.0) * (1.0 - u))
			f.position.y += hop * StageHeroFigure.height(kinds[i]) * 0.28
			f.rotation.y = TAU * clampf(u * 1.25, 0.0, 1.0)
			f.scale = Vector3(1.0 + squash, 1.0 - squash, 1.0 + squash)
	if _reveal >= 0.0 and not figures.is_empty():
		# The newborn grows out of the egg with one overshoot (§21.8 keeps
		# interface motion to 250 ms; this is the world's, not the interface's).
		var u := clampf(_reveal / 0.7, 0.0, 1.0)
		var grow := 1.0 + 0.25 * sin(u * PI) * (1.0 - u) if u > 0.4 else u / 0.4
		figures[0].scale *= maxf(0.01, grow)
		# A shell the stage cleared away (show_kinds) is gone from the list.
		_shells.assign(_shells.filter(func(x: Node3D) -> bool: return is_instance_valid(x)))
		for sh in _shells:
			var side: float = sh.get_meta("side")
			var t := _reveal
			sh.position = Vector3(side * t * 0.9, 0.3 + t * 1.4 - t * t * 1.6, 0.2 * t)
			sh.rotation = Vector3(0, 0, side * (PI * 0.5 + t * 4.0))
		backdrop.flash = clampf(1.0 - _reveal / 1.2, 0.0, 1.0)
	else:
		backdrop.flash = 0.0


## A close view's light on a model (the hero stage, portraits): the lit
## paint lifted further toward warm white and the light steps started
## earlier, so the model reads pale and soft as the design's portraits do,
## where the world keeps T1's values for a model seen from far above.
static func _close_look(model: CreatureModel) -> void:
	var m := model.material()
	if m == null:
		return
	var lift := float(m.get_shader_parameter("lift")) if m.get_shader_parameter("lift") != null else 0.5
	m.set_shader_parameter("lift", minf(0.95, lift * CLOSE_LIFT))
	m.set_shader_parameter("ramp_bias", CLOSE_RAMP_BIAS)


## The stand-in: StageHeroSculpt's figure for the kind, grown to its height.
static func _stand_in(kind: String, look: String) -> Node3D:
	var root := Node3D.new()
	var mi := MeshInstance3D.new()
	mi.mesh = StageHeroSculpt.of(kind, look)
	var rim: Color = Palette.SCHOOL.get(StageHeroFigure.school(kind), Palette.MOTION)
	var m := toon(rim)
	# The world's toon reads hot under the close view's brighter fill.
	m.set_shader_parameter("tint", Color(0.84, 0.82, 0.86))
	mi.material_override = m
	mi.scale = Vector3.ONE * StageHeroFigure.height(kind)
	root.add_child(mi)
	root.set_meta("kind", kind)
	root.set_meta("look", look)
	return root
