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
## steps, with three zoom levels.

## §21.1's pitches: the heist's follow camera, and the home diorama's.
const HEIST_PITCH := 50.0
const HOME_PITCH := 35.0
## How much of the island a zoom level shows: the whole rock, the realm's
## grid (§21.1: "about 12 tiles across"), and a close-up.
const ZOOM_SPAN := [1.25, 1.0, 0.6]
## Ticks a second, for drawing between them.
const TPS := 30.0

static var _toon: Shader = load("res://world/toon.gdshader")
static var _clear: Shader = load("res://world/toon_clear.gdshader")
static var _outline: Shader = load("res://world/outline.gdshader")
static var _water: Shader = load("res://world/water.gdshader")
static var _cache := {}

## §21.4's realm type, which picks the palette; and whether this is a heist.
var realm_type := "heart"
var heist := true
## The buildings standing ([kind, x, y, side], `RulebornIsland.buildings()`),
## when the screen knows them, so each footprint is drawn as its kind.
var buildings: Array = []
var pitch := HEIST_PITCH
## The camera's quarter turns (§21.1: "rotatable in 90° steps") and zoom.
var turns := 0
var zoom := 1

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

var _static_key := ""
var _vault: MeshInstance3D
var _pylons: Array[MeshInstance3D] = []
var _wards: Array[MeshInstance3D] = []
var _walls: MeshInstance3D
var _crew: Array[Node3D] = []
var _guards: Array[Node3D] = []
var _guard_marks: Array[Label3D] = []
## Each actor's place a tick ago and now, for drawing between ticks.
var _from: Dictionary = {}
var _to: Dictionary = {}
var _tick := -1
var _since := 0.0



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
	set_sky_hour(Time.get_datetime_dict_from_system()["hour"])


## §21.2: the sky follows the player's local time, and the light with it.
func set_sky_hour(hour: int) -> void:
	look.set_hour(hour)


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
	kit.buildings = buildings
	kit.build()
	# The kit's layers with its own materials (T3: they carry its idle motion).
	for mi: MeshInstance3D in kit.instances():
		statics.add_child(mi)
	# The Vault, the pylons and the wards change as the heist goes, so each
	# is its own piece.
	_vault = _instance(PieceKit.vault(false), RealmKit.material("toon", true))
	statics.add_child(_vault)
	for p: Dictionary in replay.pylons():
		var mi := _instance(PieceKit.pylon(), RealmKit.material("toon", true))
		mi.position = world_at(p["at"])
		statics.add_child(mi)
		_pylons.append(mi)
	for w: Dictionary in replay.wards():
		var mi := _instance(PieceKit.ward(str(w["kind"])), RealmKit.material("toon", true))
		mi.position = world_at(w["at"])
		statics.add_child(mi)
		_wards.append(mi)
	_walls = _instance(null, material(_clear), false)
	statics.add_child(_walls)
	_build_actors()


func _water_material(lava: bool) -> ShaderMaterial:
	var m := material(_water)
	if lava:
		m.set_shader_parameter("deep", Color("#C8401E"))
		m.set_shader_parameter("foam", Color("#FFC24A"))
		m.set_shader_parameter("glowing", 0.8)
	return m


## The crew and the guards, made once a heist and moved every tick.
func _build_actors() -> void:
	for c in actors.get_children():
		c.queue_free()
	_crew.clear()
	_guards.clear()
	_guard_marks.clear()
	for m: Dictionary in replay.crew():
		var root := Node3D.new()
		root.add_child(_blob())
		var body := _instance(ActorBuilder.mesh(str(m["role"])), material(_toon, true))
		body.name = "Body"
		root.add_child(body)
		var bag := _instance(ActorBuilder.sack(), material(_toon, true))
		bag.name = "Sack"
		bag.position = Vector3(0, 0.38, 0.3)
		root.add_child(bag)
		actors.add_child(root)
		_crew.append(root)
	for g: Dictionary in replay.guards():
		var root := Node3D.new()
		root.add_child(_blob())
		var body := _instance(ActorBuilder.mesh("guard"), material(_toon, true))
		body.name = "Body"
		body.scale = Vector3.ONE * 1.25
		root.set_meta("base", body.scale)
		root.add_child(body)
		var mark := Label3D.new()
		mark.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		mark.no_depth_test = true
		mark.font_size = 96
		mark.pixel_size = 0.006
		mark.outline_size = 18
		mark.modulate = Palette.INK
		mark.outline_modulate = Palette.PAPER
		mark.position = Vector3(0, 1.35, 0)
		root.add_child(mark)
		actors.add_child(root)
		_guards.append(root)
		_guard_marks.append(mark)


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


## The camera on §21.1's terms, framing the zoom level's span of the island.
func _frame_camera() -> void:
	if _size.x == 0:
		return
	var span: float = Vector2(_size).length() * ZOOM_SPAN[clampi(zoom, 0, 2)]
	var aspect := maxf(0.1, size.x / maxf(1.0, size.y))
	camera.size = maxf(span * 0.9, span / aspect * 0.78)
	var yaw := deg_to_rad(45.0 + 90.0 * turns)
	var p := deg_to_rad(pitch)
	# The whole island is framed with its rock beneath; a realm, on its grid.
	var target := Vector3(0, -2.2 if zoom == 0 else 0.3, 0)
	var back := Vector3(sin(yaw) * cos(p), sin(p), cos(yaw) * cos(p))
	camera.look_at_from_position(target + back * 40.0, target, Vector3.UP)


## A quarter turn of the camera, either way (§21.1).
func turn(by: int) -> void:
	turns = posmod(turns + by, 4)
	_frame_camera()


func set_zoom(level: int) -> void:
	zoom = clampi(level, 0, 2)
	_frame_camera()


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
		var body := node.get_node("Body") as MeshInstance3D
		var down: bool = m["standing"] != "Active"
		body.rotation = Vector3(-PI / 2.0 if down else 0.0, 0, 0)
		body.position = Vector3(0, 0.2 if down else 0.0, 0)
		var bag := node.get_node("Sack") as MeshInstance3D
		var share: float = float(m["carried"]) / maxf(1.0, float(m["carry"]))
		bag.visible = share > 0.0 and not down
		bag.scale = Vector3.ONE * (0.6 + 0.8 * share)
	var guards := replay.guards()
	for i in mini(guards.size(), _guards.size()):
		var g: Dictionary = guards[i]
		_to["g%d" % i] = world_at(g["at"])
		var node := _guards[i]
		var body := node.get_node("Body") as MeshInstance3D
		body.rotation = Vector3(-PI / 2.0 if g["down"] else 0.0, 0, 0)
		# The simulation's facing is in the tile grid's frame: x right, y
		# down; the model faces −Z.
		var f: float = g["facing"]
		node.rotation.y = atan2(-cos(f), -sin(f))
		_guard_marks[i].text = "" if g["down"] else str(GUARD_MARK.get(g["state"], ""))
		_guard_marks[i].modulate = mark_colour(str(g["state"]))
	for k: String in _to:
		if not _from.has(k):
			_from[k] = _to[k]
	_place_actors(1.0 if _since <= 0.0 else clampf(_since * TPS, 0.0, 1.0))
	_face_crew(crew)
	_sync_pieces()
	_sync_overlay()
	_sync_marks()


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


## The guard whose sight is drawn: the selected one, else the first on its
## feet (§21.12: "The selected guard's vision is drawn").
func shown_guard() -> int:
	var guards := replay.guards()
	if selected_guard >= 0 and selected_guard < guards.size() and not guards[selected_guard]["down"]:
		return selected_guard
	for gi in guards.size():
		if not guards[gi]["down"]:
			return gi
	return -1


## §21.12: "Sharp edges, no gradients. A tile is inside or outside": each
## tile the shown guard's cone reaches, as the simulation decides it, filled
## flat in the alarm's red just above the ground.
func _sync_overlay() -> void:
	var g := Geo.new()
	var shown := shown_guard()
	if shown >= 0:
		for tile in replay.seen(shown):
			var p := Vector2(tile % _size.x, tile / _size.x)
			var c := world_at(p + Vector2(0.5, 0.5))
			g.box(Geo.place(c + Vector3(0, 0.03, 0)), Vector3(0.96, 0.02, 0.96), Palette.ALARM)
	overlay.mesh = g.mesh()
	if overlay.material_override == null:
		var m := material(_clear)
		m.set_shader_parameter("opacity", 0.42)
		overlay.material_override = m


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
	_place_actors(clampf(_since * TPS, 0.0, 1.0))
	_animate(replay.tick() + clampf(_since * TPS, 0.0, 1.0))


## Gentle physical humour (§21.1): a figure on the move bobs and squashes
## with its steps, one standing still breathes. Its time is the heist's
## ticks, so a replay moves the same every time it is played.
func _animate(ticks: float) -> void:
	var t := ticks / TPS
	for i in _crew.size():
		_bounce(_crew[i], "c%d" % i, t + i * 0.37)
	for i in _guards.size():
		_bounce(_guards[i], "g%d" % i, t + i * 0.61)


func _bounce(node: Node3D, key: String, t: float) -> void:
	var body := node.get_node_or_null("Body") as MeshInstance3D
	if body == null or absf(body.rotation.x) > 0.1:
		return
	var moving := _from.has(key) and _to.has(key) and (_from[key] as Vector3).distance_to(_to[key]) > 0.001
	if moving:
		var step := absf(sin(t * TAU * 2.2))
		body.position.y = step * 0.07
		body.scale = node.get_meta("base", Vector3.ONE) * Vector3(1.0 + 0.05 * (1.0 - step), 0.94 + 0.08 * step,
			1.0 + 0.05 * (1.0 - step))
	else:
		body.position.y = 0.0
		body.scale = node.get_meta("base", Vector3.ONE) * Vector3(1.0, 1.0 + 0.02 * sin(t * TAU * 0.4), 1.0)


## A screen describes the view after every tick: the words for a screen
## reader, and the world moved to match.
func describe() -> void:
	super.describe()
	sync()


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


## The point on the screen over a tile's centre: what `tile_at` inverts.
func screen_at(t: Vector2i) -> Vector2:
	return camera.unproject_position(world_at(Vector2(t) + Vector2(0.5, 0.5)))
