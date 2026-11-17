class_name UniverseBadge
extends PanelContainer
## Home's top left (§21.8's home layout), from the kit's Keeper part
## (`KitHud.keeper`): the Keeper's portrait in a ring whose gold arc is the way
## to the next Keeper level (§14.2), the level on a gold plate at the ring's
## foot, "Keeper 24" in the display face, and Renown on a glass pill beneath,
## its gem before the number, so the number starts past the gem at every text
## size. The whole badge is one control (`KitLayout.tap`) that opens the menu
## of every screen, as the designs' portrait does. What it shows is said in
## words to a screen reader (§20.8).

signal pressed

## The portrait ring's size in points (the kit's Keeper part draws it at 52).
const RING := 76.0
## The stage's picture, in pixels a point of the ring: drawn larger than it
## shows, for clean edges.
const OVERSAMPLE := 2.0
## The companion's kind and its framing: the share of its height shown, from
## the top of its head down, and the air above it (as CreatureBust frames a
## bust), its turn toward the light and the camera's rise.
const KIND := "featherkin"
const BODY := 0.74
const HEADROOM := 0.1
const TURN := -0.32
const RISE := 0.14
## How far its idles may turn its head from its rest pose before the body turns
## back by the rest (AD's note on board 3): its face stays toward the camera,
## never its profile or its back, in a ring this small.
const YAW_LEAVE := 0.3
## The rim from behind, warm against the spirit's cool ground, so the figure's
## edge reads on its disc as the design's portraits are lit.
const RIM := Color("#FFD9A0")
## The paint's lift toward warm white against the hero view's, and where its
## light steps begin (as CreatureBust's studio deepens a bust).
const LIFT := 0.72
const RAMP_BIAS := 0.26
## How far the ring's ground is taken toward the night: a step darker than
## the light figure, so the figure is the brightest thing in its disc.
const GROUND_DEPTH := 0.3
const RIM_ENERGY := 0.9

var level := 0
## The share of the way to the next level, 0 to 1.
var share := 0.0
var title := ""
## Renown's number, or "" before the league has answered.
var renown := ""
## The kit's control over the whole badge.
var tap: Button
## The Keeper's companion, as the design's portrait shows it: the featherkin's
## head and shoulders (S2-R13), alive (rubric quality 9: home shows a live
## character node in the toon look). Its model stands in a small 3D stage of
## its own (`_stage`), lit by §21.3's three points with a warm rim from
## behind so it stands off the ring's ground, inked as §21.3 asks, and plays
## its two idles; the ring draws the stage's picture cut round.
var _face: Texture2D
var _stage: SubViewport
var _camera: Camera3D
var _model: CreatureModel
var _figure: Node3D
## The head's turn in the figure's own frame at rest, once the bones have
## placed it; NAN before.
var _rest_yaw := NAN
## Seconds until the idles take turns (§21.6's "two idles").
var _fidget := StageHero.IDLE2_EVERY
var _row: Control
var _box := UI.clear_box(0, 0)


func _init() -> void:
	_face = _live_face()
	add_theme_stylebox_override("panel", _box)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	accessibility_name = Strings.t("HOME_MENU")
	tap = KitLayout.tap(self, func() -> void: pressed.emit(), accessibility_name)
	# The menu is a secondary place (§21.1 binds only the frequent controls to
	# the thumb zone), and the check reads that on the button itself.
	tap.set_meta("frequent", false)


## What the Keeper bar says (KeeperPresenter.bar), and Renown if known.
func show_keeper(bar: Dictionary, xp_share: float, renown_text: String) -> void:
	level = int(bar.get("level", 0))
	share = clampf(xp_share, 0.0, 1.0)
	title = str(bar.get("title", ""))
	renown = renown_text
	accessibility_name = str(bar.get("spoken", title))
	tap.accessibility_name = accessibility_name
	if _row != null:
		_row.queue_free()
	_row = KitHud.keeper(_face, title, level, share, renown)
	var ring := _row.find_child("Portrait", true, false) as KitRing
	# The portrait large enough to read the character at a glance (§21.1's
	# dark shape at 32 points, with room round it), the badge's lead.
	ring.custom_minimum_size = Vector2.ONE * UI.px(RING)
	# The portrait on its school's colour, the spirit's teal, as the roster's
	# cards and the design's portrait set it.
	ring.ground = Tokens.color("spirit").darkened(GROUND_DEPTH)
	# Before the league answers there is no Renown to show, not an empty pill.
	var pill := _row.find_child("Pill", true, false) as Control
	if pill != null:
		pill.visible = renown != ""
		Home.home_figure(pill.find_child("Words", true, false) as Label, 16)
	# The name in the display face too, outlined in ink over the starfield, as
	# the design's "Keeper 24" is (S2-R12).
	for l: Label in _row.find_children("*", "Label", true, false):
		if l.text == title:
			Home.home_figure(l, 22)
	for c: Node in _row.find_children("*", "Control", true, false):
		(c as Control).mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_row)
	move_child(_row, 0)
	# The level's plate hangs below the ring's foot; the badge keeps room for
	# it beneath, so the row under the badge never covers the level.
	var plate := ring.get_child(0) as Control
	plate.resized.connect(_clear_plate.bind(plate), CONNECT_DEFERRED)
	_row.resized.connect(_clear_plate.bind(plate), CONNECT_DEFERRED)
	_clear_plate.call_deferred(plate)


func _clear_plate(plate: Control) -> void:
	if not is_instance_valid(plate) or not is_instance_valid(_row) or not plate.is_inside_tree():
		return
	var below := maxf(0.0, ceilf(plate.get_global_rect().end.y - _row.get_global_rect().end.y))
	if not is_equal_approx(_box.content_margin_bottom, below):
		_box.content_margin_bottom = below
		update_minimum_size()


## The companion's model, alive in the portrait, and the stage it is drawn in
## (for the shot's check that home's character exists and moves).
func companion() -> CreatureModel:
	return _model


func stage() -> SubViewport:
	return _stage


## The companion's stage: its own world, cleared to nothing so the ring's lit
## ground shows behind it; drawn every frame while the badge shows, once under
## reduced motion (§20.8), where the figure stands still.
func _live_face() -> Texture2D:
	_stage = SubViewport.new()
	_stage.name = "Companion"
	_stage.own_world_3d = true
	_stage.transparent_bg = true
	_stage.msaa_3d = Viewport.MSAA_4X
	_stage.size = Vector2i.ONE * int(ceilf(UI.px(RING) * OVERSAMPLE))
	var world := Node3D.new()
	_stage.add_child(world)
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
	rim.light_color = RIM
	rim.light_energy = RIM_ENERGY
	rim.rotation_degrees = Vector3(-14, 205, 0)
	world.add_child(rim)
	var figure := StageHero.make_figure(KIND, "", true)
	figure.rotation.y = TURN
	world.add_child(figure)
	_figure = figure
	_model = figure.get_meta("model", null)
	if _model != null:
		_model.play(&"idle")
		# The hero view's pale lift taken back, as the busts take it: at a
		# portrait's size the figure keeps its colour and its light steps.
		var m := _model.material()
		if m != null and m.get_shader_parameter("lift") != null:
			m.set_shader_parameter("lift", float(m.get_shader_parameter("lift")) * LIFT)
			m.set_shader_parameter("ramp_bias", RAMP_BIAS)
	_camera = Camera3D.new()
	_camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	_camera.near = 0.05
	_camera.far = 40.0
	world.add_child(_camera)
	_frame()
	add_child(_stage, false, Node.INTERNAL_MODE_BACK)
	visibility_changed.connect(_wake)
	_wake()
	return _stage.get_texture()


## The camera on the head and body, as CreatureBust frames a bust: from just
## over `head_top` down, centred between the head and the chest; before the
## bones have placed the sockets, on the kind's height alone.
func _frame() -> void:
	var entry: Dictionary = CreatureModel.manifest().get(KIND, {})
	var tall := float(entry.get("body_height", entry.get("height", 1.0)))
	var top := Vector3(0, tall, 0)
	var chest := top * 0.6
	if _model != null and _model.is_inside_tree() and _model.socket(&"head_top") != null \
			and _model.socket(&"chest") != null:
		top = _model.socket(&"head_top").global_position
		chest = _model.socket(&"chest").global_position
	var view := maxf(maxf(0.06, top.y - chest.y) * 1.4, tall * BODY)
	var centre := Vector3((top.x + chest.x) * 0.5, top.y + view * (HEADROOM - 0.5), (top.z + chest.z) * 0.5)
	_camera.size = view
	# The stage's world is its root, so the camera's own transform is its place.
	var at := centre + Vector3(0.0, RISE, 1.0).normalized() * 8.0
	_camera.transform = Transform3D(Basis.looking_at(centre - at), at)


func _ready() -> void:
	# The bones' attachments take their places over the first frames.
	await get_tree().process_frame
	await get_tree().process_frame
	if is_instance_valid(_camera):
		_frame()
	_rest_yaw = _head_yaw()


## Drawn only while the badge shows; under reduced motion the figure holds
## its first pose and the stage draws once.
func _wake() -> void:
	if _stage == null:
		return
	var still := Settings.reduced_motion
	if _model != null and _model.player() != null:
		_model.player().speed_scale = 0.0 if still else 1.0
	if not is_visible_in_tree() and is_inside_tree():
		_stage.render_target_update_mode = SubViewport.UPDATE_DISABLED
	elif still:
		_stage.render_target_update_mode = SubViewport.UPDATE_ONCE
	else:
		_stage.render_target_update_mode = SubViewport.UPDATE_ALWAYS


func _process(delta: float) -> void:
	if _model == null or Settings.reduced_motion:
		return
	_keep_facing()
	_fidget -= delta
	if _fidget <= 0.0:
		_fidget = StageHero.IDLE2_EVERY
		_model.play(&"idle2" if _model.clip == &"idle" else &"idle")


## The head's turn about the vertical, in the figure's own frame (its turn
## toward the light taken out); NAN while it has no head.
func _head_yaw() -> float:
	if _model == null or not _model.is_inside_tree() or _model.socket(&"head_top") == null:
		return NAN
	var ahead := _model.socket(&"head_top").global_transform.basis.z
	if Vector2(ahead.x, ahead.z).length() < 0.01:
		return NAN
	return wrapf(atan2(ahead.x, ahead.z) - _figure.rotation.y, -PI, PI)


## Where an idle turns the head further than YAW_LEAVE from its rest, the
## figure turns back by what is past it, so the face stays toward the camera.
func _keep_facing() -> void:
	if is_nan(_rest_yaw):
		return
	var now := _head_yaw()
	if is_nan(now):
		return
	var off := wrapf(now - _rest_yaw, -PI, PI)
	var past := signf(off) * maxf(0.0, absf(off) - YAW_LEAVE)
	_figure.rotation.y = TURN - past
