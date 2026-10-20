class_name WorldView
extends RealmView
## The realm on the world, in 3D (§21.1: "Picture-book dioramas floating in
## a violet sky"; §21.3's one toon look): the island built round the
## simulation's grid, its ground and features from the realm kit, the Vault,
## pylons and wards, the crew and the guards where the simulation puts them,
## and the selected guard's sight drawn on the tiles it reaches, hard-edged
## (§21.12). It is a `RealmView`, so a screen uses it as one: the words a
## screen reader reads, the landing marks and the selected guard are the flat
## view's, and the flat view still draws under it where 3D cannot run.
##
## One tile is one metre; tile (x, y) of the simulation is centred at
## (x − w/2 + 0.5, h, y − h/2 + 0.5) (`world_at`). The camera is §21.1's:
## orthographic, at a 50° pitch in a heist and 35° at home, turned in 90°
## steps, with three zoom levels. In a heist it follows the crew members in
## `follow`, showing about 12 tiles across (§21.1), and a pinch shows the
## whole realm; a twist turns it a quarter, a double tap steps the zoom, and
## no action needs two fingers (§20.8).
##
## Over the world stand the HUD's world-anchored pieces (`FxAnchors`), the
## effects of what happens (`FxEvents`) and of the laws running (`FxLaws`).
## A tap that is not part of a gesture is `tapped`; a long press is `held`.

## A tap on the world at a point of the view, not part of a pinch or twist.
signal tapped(at: Vector2)
## A press held for §20.8's hold time.
signal held(at: Vector2)
## A crew member grabbed `amount` of loot, drawn at `at` (global, on the
## screen): the HUD flies coins from there into its counter (§21.8).
signal looted(at: Vector2, amount: int)

## §21.1's pitches: the heist's follow camera, and the home diorama's.
const HEIST_PITCH := 50.0
const HOME_PITCH := 35.0
## The heist camera's vertical field of view: the designs' realm and heist
## camera is a narrow 20°, close to orthographic but with a diorama's depth.
const HEIST_FOV := 22.0
## How much of the island a zoom level shows: the whole rock, the realm's
## grid (§21.1: "about 12 tiles across"), and a close-up.
const ZOOM_SPAN := [1.25, 1.0, 0.6]
## Ticks a second, for drawing between them.
const TPS := 30.0
## §21.1: the heist's follow camera shows "about 12 tiles across"; its close
## zoom, eight.
const FOLLOW_TILES := 12.0
const CLOSE_TILES := 8.0
## The hour a realm under Glowing dark is lit at.
const NIGHT := 23
## How aware each guard state is, for choosing whose sight to show.
const AWARE := {"Unaware": 0, "Returning": 0, "Suspicious": 1, "Investigating": 2, "Searching": 3, "Alerted": 4}
## A press that moves less than this many pixels is a tap.
const TAP_SLOP := 24.0
## How far a twist turns before it is a quarter turn.
const TWIST_RADIANS := 0.6

static var _toon: Shader = load("res://world/toon.gdshader")
static var _clear: Shader = load("res://world/toon_clear.gdshader")
static var _outline: Shader = load("res://world/outline.gdshader")
static var _water: Shader = load("res://world/water.gdshader")
static var _cache := {}
## Makes an actor's figure, a character model, from its role ("guard" for a
## guard) and its height: the integrator sets it to T1's `CreatureModel`. A
## model with a `play(clip)` method is played "idle", "walk", "run", "crouch"
## or "ko" by what the simulation says the actor is doing. Unset, the
## stand-in figures of `ActorBuilder` are drawn.
static var figure_maker: Callable = Callable()

## §21.4's realm type, which picks the palette; and whether this is a heist.
var realm_type := "heart"
var heist := true
var pitch := HEIST_PITCH
## The camera's quarter turns (§21.1: "rotatable in 90° steps") and zoom.
var turns := 0
var zoom := 1
## The hour the sky is drawn at (§21.2: the player's local time).
var hour := 12
## The crew members the heist camera follows; none frames the whole grid.
var follow: Array = []
## The crew member drawn as chosen, -1 for none.
var chosen := -1
## The crew members standing where a guard can see them, by index.
var in_sight := {}

var viewport: SubViewport
var container: SubViewportContainer
var world: Node3D
var camera: Camera3D
var sun: DirectionalLight3D
var look: WorldLook
var environment: Environment
var statics: Node3D
var actors: Node3D
var overlay: MeshInstance3D
var marks_node: MeshInstance3D
## The outline round the shown guard's sight, and the other guards' facings.
var sight_edge: MeshInstance3D
var anchors: FxAnchors
var events: FxEvents
var laws: FxLaws

var _static_key := ""
var _vault: MeshInstance3D
var _pylons: Array[MeshInstance3D] = []
var _wards: Array[MeshInstance3D] = []
var _walls: MeshInstance3D
## The crew's skiff, where Get out called it.
var _skiff: MeshInstance3D
var _crew: Array[Node3D] = []
var _guards: Array[Node3D] = []
## Each actor's place a tick ago and now, for drawing between ticks.
var _from: Dictionary = {}
var _to: Dictionary = {}
var _tick := -1
var _since := 0.0
## The camera's smooth state: where it looks, its zoom as a float between
## the three levels, its shake and a crossing's swoop.
var _aim := Vector3.ZERO
var _aimed := false
var _zoom_f := 1.0
var _shake := 0.0
var _swoop := 0.0
var _clock := 0.0
## The presses on the view now, by finger, and the press being read.
var _touches := {}
var _press_at := Vector2.ZERO
var _press_ms := 0
var _pressing := false
var _gesture := false
var _held_sent := false
var _last_tap_ms := -10000
var _last_tap_at := Vector2.ZERO
var _twist := 0.0
var _rings: MeshInstance3D
## Whether the crew had landed at the last reading: the landing drops the
## camera from the whole realm to the crew.
var _landed := false
var _intro: Tween


func _init() -> void:
	clip_contents = true
	container = SubViewportContainer.new()
	container.stretch = true
	container.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(container)
	viewport = SubViewport.new()
	viewport.own_world_3d = true
	viewport.msaa_3d = Viewport.MSAA_2X
	viewport.handle_input_locally = false
	container.add_child(viewport)
	world = Node3D.new()
	viewport.add_child(world)
	_build_stage()
	anchors = FxAnchors.new(self)
	add_child(anchors)
	events = FxEvents.new(self)
	mouse_filter = Control.MOUSE_FILTER_STOP


## The look (light, sky, fog: `WorldLook`) and the camera.
func _build_stage() -> void:
	look = WorldLook.new(world)
	environment = look.environment
	sun = look.sun
	camera = Camera3D.new()
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.near = 0.1
	camera.far = 200.0
	world.add_child(camera)
	statics = Node3D.new()
	world.add_child(statics)
	actors = Node3D.new()
	world.add_child(actors)
	overlay = MeshInstance3D.new()
	overlay.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	world.add_child(overlay)
	marks_node = MeshInstance3D.new()
	marks_node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	world.add_child(marks_node)
	sight_edge = MeshInstance3D.new()
	sight_edge.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	sight_edge.material_override = clear_material(0.9)
	world.add_child(sight_edge)
	_rings = MeshInstance3D.new()
	_rings.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_rings.material_override = clear_material(0.85)
	world.add_child(_rings)
	laws = FxLaws.new()
	world.add_child(laws)
	set_sky_hour(Time.get_datetime_dict_from_system()["hour"])


## §21.2: the sky follows the player's local time, and the light with it.
func set_sky_hour(when: int) -> void:
	hour = when
	# A realm under Glowing dark is lit as at night (§21.7).
	look.set_hour(NIGHT if laws != null and laws.dark() else when)


static func material(shader: Shader, outlined := false) -> ShaderMaterial:
	var m := ShaderMaterial.new()
	m.shader = shader
	if shader == _toon:
		m.set_shader_parameter("glow_from_alpha", 1.0)
	if outlined:
		var o := ShaderMaterial.new()
		o.shader = _outline
		m.next_pass = o
	return m


## The see-through material at `opacity`: rings, sight, marks on the ground.
static func clear_material(opacity: float) -> ShaderMaterial:
	var m := material(_clear)
	m.set_shader_parameter("opacity", opacity)
	return m


static func _instance(mesh: ArrayMesh, mat: Material, shadows := true) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = mat
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON if shadows \
		else GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return mi


func show_replay(r: RulebornReplay) -> void:
	super.show_replay(r)
	var key := "%s|%s|%s|%s|%s" % [_size, hash(_features), hash(_heights), hash(_surfaces), realm_type]
	if key != _static_key:
		_static_key = key
		_build_statics()
		_tick = -1
		_from.clear()
		_to.clear()
		events.reset()
		_aimed = false
		_landed = false
	_frame_camera()
	sync()


## Where the simulation's tile position `at` (in tiles, as RulebornReplay
## gives it) stands in the world, on the ground at that tile's height.
func world_at(at: Vector2) -> Vector3:
	var t := Vector2i(clampi(floori(at.x), 0, maxi(0, _size.x - 1)), clampi(floori(at.y), 0, maxi(0, _size.y - 1)))
	var i := t.y * _size.x + t.x
	var h := (_heights[i] if i >= 0 and i < _heights.size() else 0) * IslandBuilder.LEVEL
	return Vector3(at.x - _size.x / 2.0, h, at.y - _size.y / 2.0)


## The island, the realm's ground and features: built once a realm, merged
## into a few meshes (§21.3: "under 150 draw calls").
func _build_statics() -> void:
	for c in statics.get_children():
		c.queue_free()
	_pylons.clear()
	_wards.clear()
	if replay == null or _size.x == 0:
		return
	var colours := RealmPalette.of(realm_type)
	var seed_from := hash(_features) ^ (_size.x * 131 + _size.y)
	look.island(statics, _size, seed_from, colours)
	var kit := RealmKit.new(replay, colours)
	kit.build()
	for layer: Array in [[kit.ground.mesh(), material(_toon), true], [kit.hero.mesh(), material(_toon, true), true],
			[kit.clear.mesh(), material(_clear), false], [kit.water.mesh(), _water_material(false), false],
			[kit.lava.mesh(), _water_material(true), false]]:
		if layer[0] != null:
			statics.add_child(_instance(layer[0], layer[1], layer[2]))
	# The Vault, the pylons and the wards change as the heist goes, so each
	# is its own piece.
	_vault = _instance(PieceKit.vault(false), material(_toon, true))
	statics.add_child(_vault)
	for p: Dictionary in replay.pylons():
		var mi := _instance(PieceKit.pylon(), material(_toon, true))
		mi.position = world_at(p["at"])
		statics.add_child(mi)
		_pylons.append(mi)
	for w: Dictionary in replay.wards():
		var mi := _instance(PieceKit.ward(str(w["kind"])), material(_toon, true))
		mi.position = world_at(w["at"])
		statics.add_child(mi)
		_wards.append(mi)
	_walls = _instance(null, material(_clear), false)
	statics.add_child(_walls)
	_skiff = _instance(ActorBuilder.skiff(), material(_toon, true))
	_skiff.scale = Vector3.ONE * 1.4
	_skiff.visible = false
	statics.add_child(_skiff)
	var woven: Array[String] = []
	for p: Dictionary in replay.pylons():
		woven.append(str(p.get("law", "")))
	laws.build(woven, _size, self)
	_build_actors()


func _water_material(lava: bool) -> ShaderMaterial:
	var m := material(_water)
	if lava:
		m.set_shader_parameter("deep", Color("#C8401E"))
		m.set_shader_parameter("foam", Color("#FFC24A"))
		m.set_shader_parameter("glowing", 0.8)
	return m


## The crew and the guards, made once a heist and moved every tick. Each is
## a root the simulation places and turns, a "Rig" the animation bobs, leans
## and knocks over, and under it a "Body": today `ActorBuilder`'s figure; a
## character model replaces it without touching the rest.
func _build_actors() -> void:
	for c in actors.get_children():
		c.queue_free()
	_crew.clear()
	_guards.clear()
	for m: Dictionary in replay.crew():
		var role := str(m["role"])
		var root := _actor(role, ActorBuilder.HEIGHT.get(role, 1.0))
		var bag := _instance(ActorBuilder.sack(), material(_toon, true))
		bag.name = "Sack"
		bag.position = Vector3(0, 0.42, 0.26)
		root.get_node("Rig").add_child(bag)
		actors.add_child(root)
		_crew.append(root)
	for _g: Dictionary in replay.guards():
		var root := _actor("guard", ActorBuilder.HEIGHT["guard"])
		actors.add_child(root)
		_guards.append(root)


## A figure: its shadow, its feet on the ground, and its rig — the body and
## the arms that swing from its shoulders. A character model replaces the
## "Figure" under the rig.
func _actor(role: String, height: float) -> Node3D:
	var root := Node3D.new()
	root.add_child(_blob())
	var feet := Node3D.new()
	feet.name = "Feet"
	feet.scale = Vector3.ONE * height
	root.add_child(feet)
	var rig := Node3D.new()
	rig.name = "Rig"
	root.add_child(rig)
	# A character model, when one is given (`figure_maker`), plays its own
	# clips and stands on its own feet; else the stand-in figure.
	var model: Node3D = figure_maker.call(role, height) if figure_maker.is_valid() else null
	var figure := model if model != null else Node3D.new()
	figure.name = "Figure"
	rig.add_child(figure)
	if model != null:
		root.set_meta("model", true)
		feet.visible = false
		return root
	figure.scale = Vector3.ONE * height
	var body := _instance(ActorBuilder.mesh(role), material(_toon, true))
	body.name = "Body"
	figure.add_child(body)
	for side: float in [-1.0, 1.0]:
		var arm := _instance(ActorBuilder.arm(role), material(_toon, true))
		arm.name = "ArmL" if side < 0.0 else "ArmR"
		arm.position = Vector3(ActorBuilder.SHOULDER.x * side, ActorBuilder.SHOULDER.y, ActorBuilder.SHOULDER.z)
		figure.add_child(arm)
		var foot := _instance(ActorBuilder.foot(role), material(_toon))
		foot.name = "FootL" if side < 0.0 else "FootR"
		foot.position = Vector3(ActorBuilder.HIP.x * side, 0, ActorBuilder.HIP.z)
		feet.add_child(foot)
	return root


## A soft dark shadow on the ground under a figure, so it stands on the
## realm rather than floating over it.
static func _blob() -> MeshInstance3D:
	if not _cache.has("blob"):
		var g := Geo.new()
		g.ring(Geo.place(Vector3(0, 0.02, 0)), 0.0, 0.3, Palette.INK, 16)
		_cache["blob"] = g.mesh()
	var m := material(_clear)
	m.set_shader_parameter("opacity", 0.28)
	var mi := _instance(_cache["blob"], m, false)
	mi.name = "Blob"
	return mi


## The camera on §21.1's terms. Following crew in a heist, it shows about
## 12 tiles across (8 close up) round them; else it frames the zoom level's
## span of the island, as the realm screens show it. Between the levels a
## pinch moves smoothly.
func _frame_camera() -> void:
	if _size.x == 0:
		return
	var aspect := maxf(0.1, size.x / maxf(1.0, size.y))
	var z := clampf(_zoom_f, 0.0, 2.0)
	var whole: float = _whole_size(aspect, 0)
	var target := Vector3(0, -2.2, 0)
	var following := heist and not follow.is_empty() and replay != null and replay.has_landed()
	var cam_size := whole
	if following:
		var near := FOLLOW_TILES / aspect
		var close := CLOSE_TILES / aspect
		cam_size = lerpf(whole, near, z) if z <= 1.0 else lerpf(near, close, z - 1.0)
		cam_size = minf(cam_size, whole)
		var goal := _follow_point()
		# Drift to the crew as the camera closes in; the whole realm sits on
		# its rock.
		target = Vector3(0, -2.2, 0).lerp(goal, clampf(z, 0.0, 1.0))
	else:
		var lo: int = floori(z)
		var hi: int = mini(2, lo + 1)
		cam_size = lerpf(_whole_size(aspect, lo), _whole_size(aspect, hi), z - lo)
		target = Vector3(0, lerpf(-2.2, 0.3, clampf(z, 0.0, 1.0)), 0)
		if heist and landing_pick >= 0 and landing_pick < landing_marks.size():
			# The landing picker leans toward the spot on show, so an edge
			# spot is never off the side of a tall screen.
			var spot := world_at(Vector2(landing_marks[landing_pick]["at"]) + Vector2(0.5, 0.5))
			target = target.lerp(Vector3(spot.x, target.y, spot.z), 0.55)
	if _swoop > 0.0:
		# §21.1's swoop between realms: out and back in, in about a second.
		cam_size *= 1.0 + 0.9 * sin(_swoop * PI)
	camera.size = cam_size
	# The heist's camera (following the crew, or picking where to land) is
	# the designs' narrow perspective, so the diorama has depth; every other
	# view keeps §21.1's orthographic one. Either way `cam_size` metres fit
	# the screen's height at the point looked at.
	var perspective := heist and pitch == HEIST_PITCH and not (follow.is_empty() and landing_marks.is_empty())
	camera.projection = Camera3D.PROJECTION_PERSPECTIVE if perspective else Camera3D.PROJECTION_ORTHOGONAL
	camera.fov = HEIST_FOV
	var distance := cam_size / (2.0 * tan(deg_to_rad(HEIST_FOV) / 2.0)) if perspective else 40.0
	var yaw := deg_to_rad(45.0 + 90.0 * turns) + _twist * 0.35
	var p := deg_to_rad(pitch + (12.0 * sin(_swoop * PI) if _swoop > 0.0 else 0.0))
	if not _aimed or not following:
		_aim = target
		_aimed = following
	var back := Vector3(sin(yaw) * cos(p), sin(p), cos(yaw) * cos(p))
	camera.look_at_from_position(_aim + back * distance, _aim, Vector3.UP)
	# The HUD covers the top and the bottom of a heist: the crew is framed a
	# little above the middle, where the screen is clear.
	camera.v_offset = -cam_size * 0.05 if following else 0.0
	if heist and not landing_marks.is_empty():
		# While the landing picker's card covers the lower screen, the realm
		# sits above it.
		camera.v_offset = -cam_size * 0.24
	camera.h_offset = 0.0
	if _shake > 0.0 and not Settings.reduced_motion:
		# §21.8: "Screen shake never above 4 pixels".
		var px := Tokens.number("motion", "shake_px_most") * _shake
		var m := cam_size / maxf(1.0, size.y)
		camera.h_offset += sin(_clock * 71.0) * px * m
		camera.v_offset += cos(_clock * 53.0) * px * m


## The camera's size for zoom level `level` of the old fixed framing.
func _whole_size(aspect: float, level: int) -> float:
	var span: float = Vector2(_size).length() * ZOOM_SPAN[clampi(level, 0, 2)]
	return maxf(span * 0.9, span / aspect * 0.78)


## Where the followed crew stand: their middle, on the ground, kept on the
## grid.
func _follow_point() -> Vector3:
	var sum := Vector3.ZERO
	var n := 0
	for i: int in follow:
		if i >= 0 and i < _crew.size() and _crew[i].visible:
			sum += _crew[i].position
			n += 1
	if n == 0:
		return Vector3(0, 0.3, 0)
	var at := sum / n
	var half := Vector2(_size) * 0.5
	return Vector3(clampf(at.x, -half.x + 3.0, half.x - 3.0), 0.3, clampf(at.z, -half.y + 3.0, half.y - 3.0))


## A quarter turn of the camera, either way (§21.1).
func turn(by: int) -> void:
	turns = posmod(turns + by, 4)
	_frame_camera()


func set_zoom(level: int) -> void:
	if _intro != null:
		_intro.kill()
	zoom = clampi(level, 0, 2)
	_zoom_f = zoom
	_frame_camera()


## A gentle shake, 0 to 1 of §21.8's four pixels; none with reduced motion.
func shake(strength: float) -> void:
	if not Settings.reduced_motion:
		_shake = maxf(_shake, clampf(strength, 0.0, 1.0))


## Turn the camera a little off its quarter, by `radians` (a result's slow
## sway; a twist on its way to a quarter turn).
func sway(radians: float) -> void:
	_twist = radians / 0.35


## §21.1's one-second swoop between realms, with the rift's wipe at its
## middle; reduced motion cuts instead (§20.8).
func swoop() -> void:
	_aimed = false
	if Settings.reduced_motion:
		return
	_swoop = 1.0
	anchors.wipe = 1.0


## What changed since the last tick: where each actor is now, the Vault,
## pylons, wards and crystal walls, the sight overlay and the landing marks.
func sync() -> void:
	if replay == null or _size.x == 0 or _vault == null:
		return
	var tick := replay.tick()
	if tick != _tick:
		_from = _to.duplicate()
		_tick = tick
		_since = 0.0
	var crew := replay.crew()
	for i in mini(crew.size(), _crew.size()):
		var m: Dictionary = crew[i]
		var node := _crew[i]
		node.visible = replay.has_landed() and not (m["standing"] in ["Out", "Gone"])
		_to["c%d" % i] = world_at(m["at"])
		node.set_meta("down", m["standing"] != "Active")
		node.set_meta("gait", str(m["gait"]))
		var bag := node.get_node("Rig/Sack") as MeshInstance3D
		var share: float = float(m["carried"]) / maxf(1.0, float(m["carry"]))
		bag.visible = share > 0.0 and m["standing"] == "Active"
		bag.scale = Vector3.ONE * (0.6 + 0.8 * share)
	var guards := replay.guards()
	for i in mini(guards.size(), _guards.size()):
		var g: Dictionary = guards[i]
		_to["g%d" % i] = world_at(g["at"])
		var node := _guards[i]
		node.set_meta("down", g["down"])
		node.set_meta("state", str(g["state"]))
		# The simulation's facing is in the tile grid's frame: x right, y
		# down; the model faces −Z.
		var f: float = g["facing"]
		node.rotation.y = atan2(-cos(f), -sin(f))
	# Which of the crew stand where a guard on its feet can see, by the
	# simulation's own sight (`seen`): the HUD marks them with an eye.
	in_sight.clear()
	var sighted := {}
	for gi in guards.size():
		if not guards[gi]["down"]:
			for tile in replay.seen(gi):
				sighted[tile] = true
	for i in crew.size():
		var at: Vector2 = crew[i]["at"]
		if crew[i]["standing"] == "Active" and sighted.has(floori(at.y) * _size.x + floori(at.x)):
			in_sight[i] = true
	for k: String in _to:
		if not _from.has(k):
			_from[k] = _to[k]
	_place_actors(1.0 if _since <= 0.0 else clampf(_since * TPS, 0.0, 1.0))
	_face_crew(crew)
	_sync_pieces()
	FxGround.sight(self)
	_sync_marks()
	events.read(replay)
	var landed := replay.has_landed()
	if landed and not _landed and heist and not follow.is_empty() and not Settings.reduced_motion \
			and replay.tick() < 60:
		# The crew lands: the camera drops from the whole realm to them.
		_zoom_f = 0.0
		_intro = create_tween()
		_intro.tween_property(self, "_zoom_f", float(zoom), 1.2).set_trans(Tween.TRANS_CUBIC) \
			.set_ease(Tween.EASE_IN_OUT)
	_landed = landed
	if anchors != null:
		anchors.queue_redraw()


## Each crew member turned the way it last walked.
func _face_crew(crew: Array) -> void:
	for i in mini(crew.size(), _crew.size()):
		var a: Vector3 = _from.get("c%d" % i, Vector3.ZERO)
		var b: Vector3 = _to.get("c%d" % i, Vector3.ZERO)
		var d := Vector2(b.x - a.x, b.z - a.z)
		if d.length() > 0.001:
			_crew[i].rotation.y = atan2(-d.x, -d.y)


## Every actor between its last tick's place and this one's, `t` of the way.
func _place_actors(t: float) -> void:
	for i in _crew.size():
		var k := "c%d" % i
		if _to.has(k):
			_crew[i].position = (_from[k] as Vector3).lerp(_to[k], t)
	for i in _guards.size():
		var k := "g%d" % i
		if _to.has(k):
			_guards[i].position = (_from[k] as Vector3).lerp(_to[k], t)


## The skiff where the last Get out called it (§5.4): hovering off the
## island's edge beside the tile, bobbing, turned to the island.
func _sync_skiff(t: float) -> void:
	if _skiff == null:
		return
	var at := Vector2(-1, -1)
	var orders := replay.commands()
	for k in range(orders.size() - 1, -1, -1):
		var c: Dictionary = orders[k]
		if int(c["kind"]) == HeistController.Kind.SKIFF:
			at = Vector2(c["x"], c["y"]) / 256.0
			break
	_skiff.visible = at.x >= 0.0
	if not _skiff.visible:
		return
	var p := world_at(at)
	var out := Vector2(p.x, p.z).normalized()
	var bob := 0.0 if Settings.reduced_motion else sin(t * 1.6) * 0.08
	_skiff.position = Vector3(p.x + out.x * 2.6, maxf(0.0, p.y) + 0.9 + bob, p.z + out.y * 2.6)
	_skiff.rotation = Vector3(0, atan2(out.x, out.y) + PI / 2.0, sin(t * 1.1) * 0.05)


func _sync_pieces() -> void:
	var v := replay.vault()
	if _vault != null and v.has("at"):
		_vault.position = world_at(v["at"])
		var open: bool = v["open"]
		if _vault.get_meta("open", false) != open:
			_vault.mesh = PieceKit.vault(open)
			_vault.set_meta("open", open)
	var pylons := replay.pylons()
	for i in mini(pylons.size(), _pylons.size()):
		var up: bool = pylons[i]["standing"]
		if _pylons[i].get_meta("up", true) != up:
			_pylons[i].mesh = PieceKit.pylon() if up else PieceKit.broken_pylon()
			_pylons[i].set_meta("up", up)
	var wards := replay.wards()
	for i in mini(wards.size(), _wards.size()):
		var live: bool = wards[i]["live"]
		if _wards[i].get_meta("live", true) != live:
			_wards[i].mesh = PieceKit.ward(str(wards[i]["kind"])) if live else PieceKit.dead_ward()
			_wards[i].set_meta("live", live)
	var walls := replay.walls()
	var g := Geo.new()
	for w: Vector2i in walls:
		g.box(Geo.place(world_at(Vector2(w) + Vector2(0.5, 0.5)) + Vector3(0, 0.6, 0)), Vector3(0.86, 1.2, 0.86),
			Palette.TIME.lightened(0.3))
	_walls.mesh = g.mesh()


## The guard whose sight is drawn: the selected one; else, as the designs
## focus it, the most aware guard on its feet, the nearest to the chosen crew
## member breaking a tie (§21.12: "The selected guard's vision is drawn").
func shown_guard() -> int:
	var guards := replay.guards()
	if selected_guard >= 0 and selected_guard < guards.size() and not guards[selected_guard]["down"]:
		return selected_guard
	var near := Vector2(-1, -1)
	var crew := replay.crew()
	if chosen >= 0 and chosen < crew.size():
		near = crew[chosen]["at"]
	var best := -1
	var best_key := -INF
	for gi in guards.size():
		if guards[gi]["down"]:
			continue
		var key := float(AWARE.get(str(guards[gi]["state"]), 0)) * 1000.0
		if near.x >= 0.0:
			key -= (guards[gi]["at"] as Vector2).distance_to(near)
		else:
			key -= gi
		if key > best_key:
			best_key = key
			best = gi
	return best


## §5.4's landing marks: a ring where a landing is heard, a disc where it is
## covered, the one on show ringed twice — by shape, not colour (§20.8).
func _sync_marks() -> void:
	var g := Geo.new()
	for k in landing_marks.size():
		var m: Dictionary = landing_marks[k]
		var c := world_at(Vector2(m["at"]) + Vector2(0.5, 0.5)) + Vector3(0, 0.05, 0)
		if m.get("covered", false):
			g.ring(Geo.place(c), 0.0, 0.22, Palette.INK, 14)
		else:
			g.ring(Geo.place(c), 0.17, 0.26, Palette.INK, 14)
		if k == landing_pick:
			g.ring(Geo.place(c + Vector3(0, 0.01, 0)), 0.36, 0.46, Palette.MOTION, 18)
	marks_node.mesh = g.mesh()
	if marks_node.material_override == null:
		marks_node.material_override = material(_toon)


func _process(delta: float) -> void:
	if replay == null:
		return
	_since += delta
	_clock += delta
	_shake = maxf(0.0, _shake - delta * 2.5)
	_swoop = maxf(0.0, _swoop - delta)
	_place_actors(clampf(_since * TPS, 0.0, 1.0))
	var t := replay.tick() + clampf(_since * TPS, 0.0, 1.0)
	_animate(t)
	_sync_skiff(t / TPS)
	if heist and not follow.is_empty():
		var goal := _follow_point()
		if _aimed:
			_aim = _aim.lerp(goal, 1.0 - exp(-delta * 4.0)) if zoom > 0 or _zoom_f > 0.5 else _aim
	_frame_camera()
	FxGround.rings(self, _rings, t / TPS)
	laws.tick(delta, self)
	anchors.tick(delta)
	_read_hold()


## Gentle physical humour (§21.1): a figure on the move bobs and squashes
## with its steps — tiptoeing crouched, bounding at a run — and one standing
## still breathes; one that is down lies on its back. Its time is the
## heist's ticks, so a replay moves the same every time it is played. The
## laws running bend how everyone moves (§21.7's movement signatures).
func _animate(ticks: float) -> void:
	var t := ticks / TPS
	for i in _crew.size():
		_bounce(_crew[i], "c%d" % i, t + i * 0.37)
	for i in _guards.size():
		_bounce(_guards[i], "g%d" % i, t + i * 0.61)


func _bounce(node: Node3D, key: String, t: float) -> void:
	var rig := node.get_node_or_null("Rig") as Node3D
	if rig == null:
		return
	var feet := node.get_node_or_null("Feet") as Node3D
	if node.get_meta("model", false):
		_play_model(node, rig, key)
		return
	if node.get_meta("down", false):
		rig.rotation = Vector3(-PI / 2.0, 0, 0)
		rig.position = Vector3(0, 0.22, 0)
		rig.scale = Vector3.ONE
		if feet != null:
			feet.visible = false
		_limbs(rig, null, 0.0, 0.0, 0.0)
		return
	if feet != null:
		feet.visible = true
	var moving := _from.has(key) and _to.has(key) and (_from[key] as Vector3).distance_to(_to[key]) > 0.001
	var gait := str(node.get_meta("gait", "Walk"))
	var move := laws.movement(moving, gait, t)
	if moving:
		var rate: float = (2.2 if gait == "Walk" else (1.6 if gait == "Crouch" else 3.0)) * move["rate"]
		var step := absf(sin(t * TAU * rate))
		var lift: float = (0.07 if gait != "Crouch" else 0.03) * move["hop"]
		rig.position = Vector3(0, step * lift + move["float"], 0)
		var squat := 0.82 if gait == "Crouch" else 1.0
		rig.scale = Vector3(1.0 + 0.05 * (1.0 - step), (0.94 + 0.08 * step) * squat, 1.0 + 0.05 * (1.0 - step))
		rig.rotation = Vector3(-0.12 if gait == "Run" else (-0.05 if gait == "Crouch" else 0.0), 0,
			sin(t * TAU * rate * 0.5) * 0.06 + move["lean"])
		var swing := 1.0 if gait == "Run" else (0.35 if gait == "Crouch" else 0.7)
		_limbs(rig, feet, sin(t * TAU * rate * 0.5) * swing, 0.08 * swing, move["float"])
	else:
		rig.position = Vector3(0, move["float"], 0)
		rig.scale = Vector3(1.0, 1.0 + 0.02 * sin(t * TAU * 0.4), 1.0)
		rig.rotation = Vector3(0, 0, move["lean"] * 0.4)
		_limbs(rig, feet, sin(t * TAU * 0.4) * 0.08, 0.0, move["float"])


## A character model plays the clip for what its actor is doing; the rig
## only lays it down when it is down.
func _play_model(node: Node3D, rig: Node3D, key: String) -> void:
	var down: bool = node.get_meta("down", false)
	rig.rotation = Vector3.ZERO
	rig.position = Vector3.ZERO
	var moving := _from.has(key) and _to.has(key) and (_from[key] as Vector3).distance_to(_to[key]) > 0.001
	var gait := str(node.get_meta("gait", "Walk"))
	var clip: String = "ko" if down else ("idle" if not moving else {"Run": "run", "Crouch": "crouch"}.get(gait, "walk"))
	var figure := rig.get_node_or_null("Figure")
	if figure != null and figure.has_method("play") and node.get_meta("clip", "") != clip:
		node.set_meta("clip", clip)
		figure.call("play", clip)


## Arms swing against the steps and feet step out in turn: `phase` is the
## stride's swing (-1 to 1), `stride` how far a foot steps, `lift` how far
## the figure floats (feet rise with it).
func _limbs(rig: Node3D, feet: Node3D, phase: float, stride: float, lift: float) -> void:
	var figure := rig.get_node_or_null("Figure") as Node3D
	if figure != null:
		var l := figure.get_node_or_null("ArmL") as Node3D
		var r := figure.get_node_or_null("ArmR") as Node3D
		if l != null and r != null:
			l.rotation = Vector3(phase * 0.9, 0, -0.15)
			r.rotation = Vector3(-phase * 0.9, 0, 0.15)
	if feet == null:
		return
	feet.position.y = lift
	var fl := feet.get_node_or_null("FootL") as Node3D
	var fr := feet.get_node_or_null("FootR") as Node3D
	if fl != null and fr != null:
		fl.position.z = ActorBuilder.HIP.z - phase * stride / maxf(0.01, feet.scale.z)
		fr.position.z = ActorBuilder.HIP.z + phase * stride / maxf(0.01, feet.scale.z)
		fl.position.y = maxf(0.0, phase) * stride * 0.6
		fr.position.y = maxf(0.0, -phase) * stride * 0.6


## A screen describes the view after every tick: the words for a screen
## reader, and the world moved to match.
func describe() -> void:
	super.describe()
	sync()


## Taps, holds and gestures on the world (§21.1, §20.8). A press that moves
## less than `TAP_SLOP` and lifts before the hold time is a tap; a second tap
## soon after on the same spot steps the zoom; two fingers pinch to zoom and
## twist to turn, and neither is ever a tap. A mouse wheel zooms.
func _gui_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		var st := event as InputEventScreenTouch
		if st.pressed:
			_touches[st.index] = st.position
		else:
			_touches.erase(st.index)
		if _touches.size() > 1:
			_gesture = true
	elif event is InputEventScreenDrag:
		var sd := event as InputEventScreenDrag
		if _touches.size() == 2 and _touches.has(sd.index):
			var other: Vector2 = Vector2.ZERO
			for k: int in _touches:
				if k != sd.index:
					other = _touches[k]
			var before: Vector2 = (_touches[sd.index] as Vector2) - other
			var after := sd.position - other
			if before.length() > 4.0 and after.length() > 4.0:
				_zoom_by(log(after.length() / before.length()) * 1.6)
				_twist_by(before.angle_to(after))
		_touches[sd.index] = sd.position
	elif event is InputEventMagnifyGesture:
		_zoom_by(log((event as InputEventMagnifyGesture).factor) * 1.6)
		_gesture = true
	elif event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_WHEEL_UP and mb.pressed:
			_zoom_by(0.15)
		elif mb.button_index == MOUSE_BUTTON_WHEEL_DOWN and mb.pressed:
			_zoom_by(-0.15)
		elif mb.button_index == MOUSE_BUTTON_LEFT:
			if mb.pressed:
				_pressing = true
				_gesture = _touches.size() > 1
				_held_sent = false
				_press_at = mb.position
				_press_ms = Time.get_ticks_msec()
			elif _pressing:
				_pressing = false
				_release(mb.position)
	elif event is InputEventMouseMotion and _pressing:
		if (event as InputEventMouseMotion).position.distance_to(_press_at) > TAP_SLOP:
			_gesture = true


func _release(at: Vector2) -> void:
	if _gesture or _held_sent or at.distance_to(_press_at) > TAP_SLOP:
		_gesture = _touches.size() > 0 and _gesture
		_twist = 0.0
		return
	var now := Time.get_ticks_msec()
	if now - _last_tap_ms < 320 and at.distance_to(_last_tap_at) < TAP_SLOP * 2.0:
		# A double tap steps the zoom: realm, crew, close, and round again.
		set_zoom((zoom + 1) % 3 if zoom > 0 else 1)
		_last_tap_ms = -10000
	else:
		_last_tap_ms = now
		_last_tap_at = at
	if heist and replay != null:
		var t := tile_at(at)
		if t.x >= 0:
			events.ring(world_at(Vector2(t) + Vector2(0.5, 0.5)), Palette.PAPER, 0.9)
	tapped.emit(at)


## A press held still for §20.8's hold time is `held`, once.
func _read_hold() -> void:
	if _pressing and not _gesture and not _held_sent and Time.get_ticks_msec() - _press_ms >= Settings.hold_ms:
		_held_sent = true
		anchors.names_for = 2.5
		held.emit(_press_at)


func _zoom_by(amount: float) -> void:
	if _intro != null:
		_intro.kill()
	_zoom_f = clampf(_zoom_f + amount, 0.0, 2.0)
	zoom = roundi(_zoom_f)
	_gesture = true


func _twist_by(radians: float) -> void:
	_twist += radians
	_gesture = true
	if absf(_twist) > TWIST_RADIANS:
		turn(1 if _twist > 0.0 else -1)
		_twist = 0.0


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		_frame_camera()


## The flat view stays beneath as the fallback, drawn only where the 3D
## renderer is not there.
func _draw() -> void:
	if not rendering_3d():
		super._draw()


static func rendering_3d() -> bool:
	return DisplayServer.get_name() != "headless"


## The tile under a point on the screen: the camera's ray through it, met
## with the ground at each height from the top down, so a raised tile is
## picked where it is drawn; (-1, -1) off the realm.
func tile_at(at: Vector2) -> Vector2i:
	if _size.x == 0 or camera == null:
		return Vector2i(-1, -1)
	var origin := camera.project_ray_origin(at)
	var dir := camera.project_ray_normal(at)
	if absf(dir.y) < 0.0001:
		return Vector2i(-1, -1)
	for level in range(3, -1, -1):
		var y := level * IslandBuilder.LEVEL
		var hit := origin + dir * ((y - origin.y) / dir.y)
		var t := Vector2i(floori(hit.x + _size.x / 2.0), floori(hit.z + _size.y / 2.0))
		if t.x < 0 or t.y < 0 or t.x >= _size.x or t.y >= _size.y:
			continue
		var i := t.y * _size.x + t.x
		if (_heights[i] if i < _heights.size() else 0) == level:
			return t
	return Vector2i(-1, -1)


## The guard nearest a point on the screen, where the camera draws it, is the
## one whose sight is shown (§21.12).
func select_guard_near(at: Vector2) -> void:
	if replay == null or camera == null:
		return
	var best := -1
	var best_d := INF
	for gi in _guards.size():
		var d := camera.unproject_position(_guards[gi].position + Vector3(0, 0.6, 0)).distance_to(at)
		if d < best_d:
			best_d = d
			best = gi
	selected_guard = best
	describe()


## The point on the screen over a tile's centre: what `tile_at` inverts.
func screen_at(t: Vector2i) -> Vector2:
	return camera.unproject_position(world_at(Vector2(t) + Vector2(0.5, 0.5)))
