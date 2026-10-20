class_name UniverseView
extends Control
## The player's universe in 3D (§21.1; §23.2: "Home. See every realm and
## link at once"): every realm's island hanging in a vertical column over a
## galaxy, the Heart in the middle, each island in its type's look with its
## buildings at their levels; §5.3's links between them as stone bridges,
## rope bridges, chutes and rifts; skiffs flying them; and over it all, pins
## that follow the islands — each realm's name, what its producers have
## ready, the alerts, and the faults (§5.4). It draws what the store holds
## (`show_universe`) and decides nothing.
##
## The camera is §21.1's home camera: orthographic, at a 35° pitch, turned in
## quarter turns, at three zooms — the whole universe, one realm, a close-up.
## A pinch zooms, a twist turns, a drag pans, and a tap on a realm swoops to
## it in about a second, through a wipe of cloud between two realms (the
## design's `cloudWipe`, realm_diorama.js :1011). A tilt of the phone, or a
## slow drift where there is no tilt, moves the near and far sky apart.

## A tap on a realm (its id), after the swoop to it has begun.
signal realm_chosen(id: String)
## The zoom level changed: 0 the whole universe, 1 a realm, 2 a close-up.
signal zoomed(level: int)

const PITCH := 35.0
## A swoop between realms, in milliseconds (§21.1: "a one-second swoop").
const SWOOP_MS := 1000.0
## How much of the frame a realm fills at zooms 1 and 2, in island radii.
const REALM_SPAN := [0.0, 2.7, 1.45]
## The tilt parallax's reach, in degrees of yaw and pitch.
const TILT_DEGREES := Vector2(4.0, 2.5)
## A tap: moved less than this many pixels, held less than this long.
const TAP_PX := 14.0
const TAP_MS := 400
## The skiffs flying the links, and the glows in each one's wake.
const SKIFFS := 4
const WAKE := 12
## A fault, in the alarm's red (§21.8 keeps red for alarms).
const FAULT := Color("#FF5A7A")

static var _toon: Shader = load("res://world/universe_toon.gdshader")
static var _outline: Shader = load("res://world/outline.gdshader")
static var _glow: Shader = load("res://world/universe_glow.gdshader")
static var _veil: Shader = load("res://world/universe_veil.gdshader")

var viewport: SubViewport
var container: SubViewportContainer
var world: Node3D
var camera: Camera3D
var sun: DirectionalLight3D
var environment: Environment
var statics: Node3D
var movers: Node3D
var pins: UniversePins
## The realms as drawn: id → UniverseIsland, and where each hangs.
var islands := {}
var places := {}
## The realm the camera is on ("" for the whole universe), its zoom and turn.
var focus_id := ""
var zoom := 0
var turns := 0
## Triangles drawn by the map's own meshes, for §21.3's budget.
var triangles := 0
## Pixels at the top and bottom that a screen's own controls cover: the
## camera frames the universe into what is left (`set_inset`).
var inset := Vector2.ZERO

var _view := {}
var _extras := {}
var _key := ""
var _bounds := AABB()
## The camera now, and where a swoop takes it: target, size, yaw.
var _target := Vector3.ZERO
var _size := 100.0
var _yaw := 0.0
var _from := [Vector3.ZERO, 100.0, 0.0]
var _to := [Vector3.ZERO, 100.0, 0.0]
var _swoop := 1.0
var _wiping := false
var _wipe: Control
var _wipe_amount := 0.0
var _tilt := Vector2.ZERO
var _time := 0.0
var _touches := {}
var _gesture := {}
var _press_at := Vector2.ZERO
var _press_ms := 0
var _spinners: Array[Dictionary] = []
var _skiffs: Array[Dictionary] = []
var _streams: Array[Dictionary] = []
var _sparks: MultiMeshInstance3D
var _comets: Array[Dictionary] = []


func _init() -> void:
	clip_contents = true
	mouse_filter = Control.MOUSE_FILTER_STOP
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
	pins = UniversePins.new(self)
	pins.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(pins)
	_wipe = Control.new()
	_wipe.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_wipe.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_wipe.draw.connect(_draw_wipe)
	add_child(_wipe)
	_build_stage()


## The night's light: a warm key light from above, a violet fill from the
## sky, and the camera.
func _build_stage() -> void:
	environment = Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color("#120A38")
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color("#8A78D8")
	environment.ambient_light_energy = 0.42
	environment.tonemap_mode = Environment.TONE_MAPPER_LINEAR
	var env_node := WorldEnvironment.new()
	env_node.environment = environment
	world.add_child(env_node)
	sun = DirectionalLight3D.new()
	sun.light_color = Color("#FFE6C8")
	sun.light_energy = 0.9
	sun.shadow_enabled = true
	sun.directional_shadow_mode = DirectionalLight3D.SHADOW_ORTHOGONAL
	sun.directional_shadow_max_distance = 160.0
	sun.rotation_degrees = Vector3(-55, 28, 0)
	world.add_child(sun)
	var rim := DirectionalLight3D.new()
	rim.light_color = Color("#FF9ED8")
	rim.light_energy = 0.3
	rim.rotation_degrees = Vector3(-20, 200, 0)
	world.add_child(rim)
	camera = Camera3D.new()
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.near = 1.0
	camera.far = 900.0
	world.add_child(camera)
	statics = Node3D.new()
	world.add_child(statics)
	movers = Node3D.new()
	world.add_child(movers)


## The universe as the store holds it: `view` is the server's universe
## (GET /v1/universe: realms with their buildings and levels, links, faults,
## the next realm to open), and `extras` what other screens' slices add —
## "producers" (the home's, with what each has ready), "raids" unseen, and
## "band" the strain band (0 calm). Built again only when what it draws has
## changed; the pins follow every call.
func show_universe(view: Dictionary, extras := {}) -> void:
	_view = view
	_extras = extras
	var key := str(hash([view.get("realms", []), view.get("links", []), view.get("faults", []),
		view.get("open", null) != null, extras.get("band", 0)]))
	if key != _key:
		_key = key
		_build()
		if focus_id != "" and not places.has(focus_id):
			focus_id = ""
			zoom = 0
		_aim(true)
	pins.show_pins(view, extras)


## Every island, link, skiff and the sky, from the view.
func _build() -> void:
	for c in statics.get_children():
		c.queue_free()
	for c in movers.get_children():
		c.queue_free()
	islands.clear()
	_spinners.clear()
	_skiffs.clear()
	_streams.clear()
	_comets.clear()
	triangles = 0
	var realms: Array = _view.get("realms", [])
	var ghosts := 1 if _view.get("open") is Dictionary else 0
	places = UniverseLayout.places(realms, ghosts)
	var body := Geo.new()
	var hero := Geo.new()
	var glows := UniversePaint.new()
	var light := UniversePaint.new()
	var flow := UniversePaint.new()
	for r: Dictionary in realms:
		var id := str(r.get("realm", ""))
		if not places.has(id):
			continue
		var island := UniverseIsland.new(r, places[id])
		island.spire = int(_view.get("spire", 1))
		island.build(body, hero, glows, light, flow, r.get("buildings", []))
		islands[id] = island
	if ghosts > 0 and places.has("next:0"):
		var types: Array = (_view["open"] as Dictionary).get("types", [])
		var ghost := UniverseIsland.new({"realm": "next:0", "type": str(types[0]) if not types.is_empty() else "Heart",
			"ghost": true}, places["next:0"])
		ghost.build(body, hero, glows, light, flow, [])
		islands["next:0"] = ghost
	_build_links(hero, glows, light, flow)
	_build_faults(light, glows)
	_bounds = UniverseLayout.bounds(places, UniverseLayout.radius(UniverseLayout.OUTER_GRID) + 2.0)
	triangles = body.triangles + hero.triangles + (glows.count + light.count + flow.count)
	_add(body.mesh(), _material(), true)
	_add(hero.mesh(), _material(true), true)
	_add(glows.mesh(), _glow_material(0.3, 0.35), false)
	_add(light.mesh(), _veil_material(0.0, 0.0), false)
	_add(flow.mesh(), _veil_material(1.6, 3.0), false)
	_build_heart_rings()
	var centre := _bounds.get_center()
	StarSky.new(hash(str(realms.size()))).build(statics, Vector3(centre.x, 0, centre.z),
		maxf(60.0, _bounds.size.z * 0.6))
	_build_skiffs()
	_build_sparks()


func _add(mesh: ArrayMesh, mat: Material, shadows: bool) -> MeshInstance3D:
	if mesh == null:
		return null
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = mat
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON if shadows \
		else GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mi.extra_cull_margin = 40.0
	statics.add_child(mi)
	return mi


static func _material(outlined := false) -> ShaderMaterial:
	var m := ShaderMaterial.new()
	m.shader = _toon
	if outlined:
		var o := ShaderMaterial.new()
		o.shader = _outline
		m.next_pass = o
	return m


static func _glow_material(twinkle: float, core: float) -> ShaderMaterial:
	var m := ShaderMaterial.new()
	m.shader = _glow
	m.set_shader_parameter("twinkle", twinkle)
	m.set_shader_parameter("core", core)
	return m


static func _veil_material(flow: float, streaks: float) -> ShaderMaterial:
	var m := ShaderMaterial.new()
	m.shader = _veil
	m.set_shader_parameter("flow", flow)
	m.set_shader_parameter("streaks", streaks)
	return m


## §5.3's links, each built to its gap; a rope bridge on its own node, so it
## sways.
func _build_links(hero: Geo, glows: UniversePaint, light: UniversePaint, flow: UniversePaint) -> void:
	for l: Dictionary in _view.get("links", []):
		var a := str(l.get("a", ""))
		var b := str(l.get("b", ""))
		if not islands.has(a) or not islands.has(b):
			continue
		var ia: UniverseIsland = islands[a]
		var ib: UniverseIsland = islands[b]
		var ends := UniverseLayout.link_ends(ia.at, ia.edge(0.0), ib.at, ib.edge(0.0))
		var link := LinkBuilder.new(str(l.get("kind", "stone_bridge")), ends[0], ends[1], ib.school,
			bool(l.get("open", true)))
		if link.kind == "rope_bridge":
			var own := Geo.new()
			var start := link.xf
			link.xf = Transform3D.IDENTITY
			link.build(own, glows, flow, light)
			triangles += own.triangles
			var mi := MeshInstance3D.new()
			mi.mesh = own.mesh()
			mi.material_override = _material(true)
			mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			var pivot := Node3D.new()
			pivot.transform = start
			pivot.add_child(mi)
			statics.add_child(pivot)
			_spinners.append({"node": mi, "axis": Vector3.RIGHT, "sway": 0.025, "speed": 1.1,
				"phase": float(int(l.get("n", 0)))})
		else:
			link.build(hero, glows, flow, light)
		if link.kind == "rift" and link.open:
			_streams.append({"path": link.stream(), "colour": ib.school})


## §5.4's faults: a crack of light across each faulted outer realm, and a
## broken streak from it to the Heart, which the crew may jump once.
func _build_faults(light: UniversePaint, glows: UniversePaint) -> void:
	if not islands.has("heart"):
		return
	var heart: UniverseIsland = islands["heart"]
	for f: Variant in _view.get("faults", []):
		var id := str(f)
		if not islands.has(id):
			continue
		var isl: UniverseIsland = islands[id]
		var a := isl.noise(301) * TAU
		var left := PackedVector3Array()
		var right := PackedVector3Array()
		for k in 9:
			var u := k / 8.0
			var p := isl.at.lerp(isl.point(a, 0.95, 0.0), u) + Vector3(0, UniverseIsland.dome(u) + 0.06, 0)
			var side := Vector3(-sin(a), 0, cos(a)) * (0.5 if k % 2 == 0 else -0.5) * (1.0 - u * 0.5)
			left.append(p + side - Vector3(0.12, 0, 0.12))
			right.append(p + side + Vector3(0.12, 0, 0.12))
		light.strip(left, right, Color(FAULT, 1.0), 1.0, true)
		for k in 16:
			var u := k / 15.0
			var p := isl.at.lerp(heart.at, u) + Vector3(sin(u * 37.0) * 1.2, 2.0 + sin(u * PI) * 6.0, cos(u * 23.0))
			glows.glow(p, 0.9 + 0.4 * (k % 2), Color(FAULT, 0.7))


## The Heart's rings, turning (the design's three tori, :1166), in the strain
## band's colour: calm white, then gold, ember and the alarm's red.
func _build_heart_rings() -> void:
	if not islands.has("heart"):
		return
	var heart: UniverseIsland = islands["heart"]
	var band := int(_extras.get("band", 0))
	var colours: Array[Color] = [Color("#E6F4FF"), Color("#FFD27A"), Color("#FF9A5A"), FAULT]
	var tint: Color = colours[clampi(band, 0, colours.size() - 1)]
	for i in 3:
		var paint := UniversePaint.new()
		var r := heart.radius + 1.6 + i * 1.3
		var inner := PackedVector3Array()
		var outer := PackedVector3Array()
		for k in 41:
			var a := PI * 1.25 * k / 40.0
			inner.append(Vector3(cos(a) * r, 0, sin(a) * r))
			outer.append(Vector3(cos(a) * (r + 0.45), 0, sin(a) * (r + 0.45)))
		paint.strip(inner, outer, Color(tint, 0.85), 1.0, true)
		var mi := MeshInstance3D.new()
		mi.mesh = paint.mesh()
		mi.material_override = _veil_material(0.0, 0.0)
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		mi.position = heart.at + Vector3(0, 0.8 + i * 0.6, 0)
		mi.rotation.y = i * 2.0
		statics.add_child(mi)
		_spinners.append({"node": mi, "axis": Vector3.UP, "turn": (0.35 + i * 0.12) * (-1.0 if i % 2 else 1.0)})


## The skiffs: one over each of the first links, back and forth; with no
## links, circling the universe.
func _build_skiffs() -> void:
	var links: Array = _view.get("links", [])
	for i in SKIFFS:
		var route := {}
		if i < links.size():
			var l: Dictionary = links[i]
			if islands.has(str(l["a"])) and islands.has(str(l["b"])):
				var ia: UniverseIsland = islands[str(l["a"])]
				var ib: UniverseIsland = islands[str(l["b"])]
				route = {"a": ia.at, "b": ib.at, "school": ib.school}
		if route.is_empty() and i >= 2:
			continue
		var school: Color = route.get("school", Palette.SPIRIT)
		var mi := MeshInstance3D.new()
		mi.mesh = SkiffBuilder.mesh(school)
		mi.material_override = _material(true)
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		mi.scale = Vector3.ONE * 0.8
		movers.add_child(mi)
		triangles += (mi.mesh as ArrayMesh).surface_get_array_len(0) / 3 if mi.mesh != null else 0
		_skiffs.append({"node": mi, "route": route, "phase": i * 0.37, "speed": 0.06 + 0.015 * i,
			"wake": [] as Array[Vector3], "colour": school})


## One layer of moving lights — skiffs' wakes, rifts' streams, comets — as
## one draw call, placed each frame.
func _build_sparks() -> void:
	var quad := UniversePaint.new()
	quad.glow(Vector3.ZERO, 1.0, Color.WHITE)
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = true
	mm.mesh = quad.mesh()
	var n := _skiffs.size() * WAKE + _streams.size() * 10 + 2 * 14 + 3
	mm.instance_count = n
	_sparks = MultiMeshInstance3D.new()
	_sparks.multimesh = mm
	_sparks.material_override = _glow_material(0.0, 0.4)
	_sparks.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_sparks.extra_cull_margin = 400.0
	movers.add_child(_sparks)
	for c in 2:
		_comets.append({"period": 22.0 + c * 9.0, "offset": c * 11.0, "side": -1.0 if c else 1.0,
			"trail": [] as Array[Vector3]})


func _process(delta: float) -> void:
	_time += delta
	_read_tilt(delta)
	if _swoop < 1.0:
		_swoop = minf(1.0, _swoop + delta * 1000.0 / maxf(1.0, UI.motion_ms(SWOOP_MS)))
		_step_swoop()
	_place_camera()
	for s: Dictionary in _spinners:
		var node: Node3D = s["node"]
		if s.has("turn"):
			node.rotation.y += float(s["turn"]) * delta * 0.3
		else:
			node.rotation.x = sin(_time * float(s["speed"]) + float(s["phase"])) * float(s["sway"])
	_fly(delta)
	pins.follow()


## A tilt of the phone where there is one; a slow drift where there is not.
func _read_tilt(delta: float) -> void:
	var g := Input.get_accelerometer()
	var want := Vector2(sin(_time * 0.11) * 0.6, sin(_time * 0.07 + 1.0) * 0.5)
	if g.length() > 0.5:
		want = Vector2(clampf(g.x / 4.0, -1.0, 1.0), clampf((g.y + 6.0) / 4.0, -1.0, 1.0))
	if Settings.reduced_motion:
		want = Vector2.ZERO
	_tilt = _tilt.lerp(want, clampf(delta * 2.0, 0.0, 1.0))


## Skiffs along their links, the wake behind each, the rifts' streams and
## the comets.
func _fly(delta: float) -> void:
	if _sparks == null:
		return
	var mm := _sparks.multimesh
	var i := 0
	for s: Dictionary in _skiffs:
		var node: MeshInstance3D = s["node"]
		var t := _time * float(s["speed"]) + float(s["phase"])
		var p := _skiff_at(s, t)
		var ahead := _skiff_at(s, t + 0.01)
		node.position = p
		var d := ahead - p
		if d.length() > 0.0001:
			node.rotation = Vector3(sin(_time * 1.3 + float(s["phase"]) * 9.0) * 0.06, atan2(-d.z, d.x), d.y * 0.4)
		var wake: Array[Vector3] = s["wake"]
		wake.push_front(p + Vector3(0, 0.5, 0))
		if wake.size() > WAKE * 2:
			wake.pop_back()
		for k in WAKE:
			var w: Vector3 = wake[mini(k * 2, wake.size() - 1)]
			var c: Color = s["colour"]
			mm.set_instance_transform(i, Transform3D(Basis().scaled(Vector3.ONE * (0.9 - k * 0.06)), w))
			mm.set_instance_color(i, Color(c.lightened(0.4 if k % 2 else 0.1), 0.75 - k * 0.055))
			i += 1
	for st: Dictionary in _streams:
		var path: Array[Vector3] = st["path"]
		for k in 10:
			var u := fmod(_time * 0.45 + k / 10.0, 1.0)
			var at := path[mini(int(u * (path.size() - 1)), path.size() - 1)]
			var c: Color = st["colour"] if k % 2 else Color.WHITE
			mm.set_instance_transform(i, Transform3D(Basis().scaled(Vector3.ONE * 0.8), at
				+ Vector3(0, 0, sin(u * PI * 4.0 + _time * 3.0) * 0.6)))
			mm.set_instance_color(i, Color(c, sin(u * PI) * 0.9))
			i += 1
	i = _fly_comets(mm, i, delta)
	while i < mm.instance_count:
		mm.set_instance_transform(i, Transform3D(Basis().scaled(Vector3.ZERO), Vector3.ZERO))
		i += 1


## Two comets crossing the deep sky, each with a tail of fading lights.
func _fly_comets(mm: MultiMesh, start: int, _delta: float) -> int:
	var i := start
	var c0 := _bounds.get_center()
	var reach := maxf(40.0, _bounds.size.z * 0.6)
	for c: Dictionary in _comets:
		var u := fmod(_time + float(c["offset"]), float(c["period"])) / float(c["period"])
		var side: float = c["side"]
		var head := c0 + Vector3(-reach + u * reach * 2.0, -12.0 - side * 4.0 + sin(u * 3.0) * 2.0,
			side * (-reach * 0.9 + u * reach * 1.8))
		var trail: Array[Vector3] = c["trail"]
		trail.push_front(head)
		if trail.size() > 40:
			trail.pop_back()
		for k in 14:
			var at := trail[mini(k * 3, trail.size() - 1)]
			mm.set_instance_transform(i, Transform3D(Basis().scaled(Vector3.ONE * (1.6 - k * 0.09)), at))
			var tint := Color("#E8F6FF") if k == 0 else (Color("#9BEAF3") if side < 0 else Color("#FFD8F0"))
			mm.set_instance_color(i, Color(tint, 0.9 - k * 0.06))
			i += 1
	return i


## A skiff `t` along its route: over its link and back, riding high in the
## middle; with no link, round the universe.
func _skiff_at(s: Dictionary, t: float) -> Vector3:
	var route: Dictionary = s["route"]
	if route.is_empty():
		var c := _bounds.get_center()
		var r := Vector2(_bounds.size.x * 0.62, _bounds.size.z * 0.45)
		var q := t * TAU * 0.5 * (1.0 if float(s["phase"]) < 0.5 else -1.0)
		return Vector3(c.x + cos(q) * r.x, 3.5 + sin(t * 9.0) * 0.4, c.z + sin(q) * r.y)
	var u := pingpong(t, 1.0)
	u = u * u * (3.0 - 2.0 * u)
	var a: Vector3 = route["a"]
	var b: Vector3 = route["b"]
	return a.lerp(b, u) + Vector3(0, 4.0 + sin(u * PI) * 3.0 + sin(_time * 1.7 + float(s["phase"])) * 0.3, 0)


## The camera where the swoop has it, tilted by the phone.
func _place_camera() -> void:
	var yaw := _yaw + deg_to_rad(_tilt.x * TILT_DEGREES.x)
	var p := deg_to_rad(PITCH + _tilt.y * TILT_DEGREES.y)
	var back := Vector3(sin(yaw) * cos(p), sin(p), cos(yaw) * cos(p))
	camera.size = _size
	camera.v_offset = -(inset.y - inset.x) / 2.0 * _size / maxf(1.0, size.y)
	_set_origin(back)
	if not camera.is_inside_tree():
		camera.position = _target + back * 300.0
		return
	camera.look_at_from_position(_target + back * 300.0, _target, Vector3.UP)


## The galaxy follows the screen most of the way, so it reads as far off.
func _set_origin(back: Vector3) -> void:
	var galaxy := statics.get_node_or_null("Galaxy") as MeshInstance3D
	if galaxy == null:
		return
	var depth := _target.y - galaxy.position.y
	var under := _target - back * (depth / maxf(0.1, back.y))
	var m := galaxy.material_override as ShaderMaterial
	var fixed := Vector2(galaxy.position.x, galaxy.position.z)
	m.set_shader_parameter("origin", Vector2(under.x, under.z) * 0.85 + fixed * 0.15)


## Where the camera should be for the focus, zoom and turn: the whole
## universe framed, or one realm.
func _aim(now := false) -> void:
	var yaw := deg_to_rad(90.0 * turns)
	var target := Vector3.ZERO
	var size := 100.0
	var seen := maxf(1.0, self.size.y - inset.x - inset.y)
	var aspect := maxf(0.1, self.size.x / seen)
	if zoom == 0 or focus_id == "" or not islands.has(focus_id):
		target = _bounds.get_center()
		size = _fit(_bounds, target, yaw, aspect) * 1.04
	else:
		var isl: UniverseIsland = islands[focus_id]
		target = isl.at + Vector3(0, -1.2 if zoom == 1 else 0.6, 0)
		var span: float = isl.radius * REALM_SPAN[zoom]
		size = maxf(span / aspect, span * 0.8)
	# The camera's height covers the whole control; the frame, what is seen.
	size *= maxf(1.0, self.size.y) / seen
	_from = [_target, _size, _yaw]
	_to = [target, size, yaw]
	if now or UI.motion_ms(SWOOP_MS) == 0.0:
		_swoop = 1.0
		_target = target
		_size = size
		_yaw = yaw
		_place_camera()
	else:
		_swoop = 0.0


## The height an orthographic camera at `yaw` needs to frame `box`.
func _fit(box: AABB, target: Vector3, yaw: float, aspect: float) -> float:
	var p := deg_to_rad(PITCH)
	var back := Vector3(sin(yaw) * cos(p), sin(p), cos(yaw) * cos(p))
	var right := Vector3.UP.cross(back).normalized()
	var up := back.cross(right).normalized()
	var w := 0.0
	var h := 0.0
	for k in 8:
		var c := box.get_endpoint(k) - target
		w = maxf(w, absf(c.dot(right)))
		h = maxf(h, absf(c.dot(up)))
	return maxf(h * 2.0, w * 2.0 / aspect)


## A swoop's step: eased, through a wipe of cloud when it goes from one
## realm to another.
func _step_swoop() -> void:
	var e := _swoop * _swoop * (3.0 - 2.0 * _swoop)
	if _wiping:
		_wipe_amount = sin(_swoop * PI)
		var jump := 1.0 if _swoop >= 0.5 else 0.0
		_target = (_from[0] as Vector3).lerp(_to[0], jump)
		_size = lerpf(_from[1], _to[1], jump)
		_yaw = lerp_angle(_from[2], _to[2], jump)
		if _swoop >= 1.0:
			_wiping = false
			_wipe_amount = 0.0
		_wipe.queue_redraw()
		return
	_target = (_from[0] as Vector3).lerp(_to[0], e)
	_size = lerpf(_from[1], _to[1], e)
	_yaw = lerp_angle(_from[2], _to[2], e)


## The camera on realm `id` at zoom `level` (1 or 2), swooping there; from
## one realm to another, through cloud.
func focus_realm(id: String, level := 1) -> void:
	if not islands.has(id) or id.begins_with("next:"):
		return
	var between := zoom > 0 and focus_id != "" and focus_id != id
	focus_id = id
	var was := zoom
	zoom = clampi(level, 1, 2)
	_aim()
	_wiping = between and UI.motion_ms(SWOOP_MS) > 0.0
	if was != zoom:
		zoomed.emit(zoom)


## The universe behind a screen built on `UI.frame`: drawn under the frame's
## column, which lets taps through wherever it has nothing of its own.
static func behind(screen: Control, column: VBoxContainer) -> UniverseView:
	var view := UniverseView.new()
	view.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	view.name = "Universe"
	screen.add_child(view)
	screen.move_child(view, 1)
	(column.get_parent() as Control).mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return view


## The universe framed into the room between `top`'s bottom edge and
## `bottom`'s top edge, once the screen has laid them out.
func fit_between(top: Control, bottom: Control) -> void:
	if top == null or bottom == null or not is_inside_tree():
		return
	var above := top.get_global_rect().end.y - global_position.y
	var below := size.y - (bottom.get_global_rect().position.y - global_position.y)
	set_inset.call_deferred(maxf(0.0, above), maxf(0.0, below))


## The pixels a screen's controls cover at the top and the bottom.
func set_inset(top: float, bottom: float) -> void:
	if inset.is_equal_approx(Vector2(top, bottom)):
		return
	inset = Vector2(top, bottom)
	if not islands.is_empty():
		_aim(true)


## The whole universe again.
func show_whole() -> void:
	set_zoom(0)


func set_zoom(level: int) -> void:
	var was := zoom
	zoom = clampi(level, 0, 2)
	if zoom > 0 and (focus_id == "" or not islands.has(focus_id)):
		focus_id = _nearest_to_centre()
	_aim()
	if was != zoom:
		zoomed.emit(zoom)


## A quarter turn of the camera, either way (§21.1).
func turn(by: int) -> void:
	turns = posmod(turns + by, 4)
	_aim()


## The realm nearest the middle of the screen: the one a pinch zooms into.
func _nearest_to_centre() -> String:
	var best := "heart" if islands.has("heart") else ""
	var best_d := INF
	for id: String in islands:
		if id.begins_with("next:"):
			continue
		var d := camera.unproject_position((islands[id] as UniverseIsland).at).distance_to(size / 2.0)
		if d < best_d:
			best_d = d
			best = id
	return best


## The realm under a point on the screen, by its island's rim; "" for sky.
func realm_at(point: Vector2) -> String:
	if camera == null:
		return ""
	var origin := camera.project_ray_origin(point)
	var dir := camera.project_ray_normal(point)
	if absf(dir.y) < 0.0001:
		return ""
	var reach := UniverseLayout.radius(UniverseLayout.OUTER_GRID)
	for depth: float in [0.0, -3.0]:
		var hit := origin + dir * ((depth - origin.y) / dir.y)
		var id := UniverseLayout.realm_near(places, hit, reach)
		if id != "" and not id.begins_with("next:"):
			return id
	return ""


## Along the ground toward the viewer: where a realm's near rim is.
func toward() -> Vector3:
	return Vector3(sin(_yaw), 0, cos(_yaw))


## Where a point of the world is on this control (the viewport is stretched
## to it, so the camera's pixels are the control's).
func screen_at(p: Vector3) -> Vector2:
	return camera.unproject_position(p)


## A tap, pinch, twist or drag.
func _gui_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		var t := event as InputEventScreenTouch
		if t.pressed:
			_touches[t.index] = t.position
			if _touches.size() == 1:
				_press_at = t.position
				_press_ms = Time.get_ticks_msec()
			_gesture = {}
		else:
			_touches.erase(t.index)
			if _touches.is_empty():
				_release(t.position)
		accept_event()
	elif event is InputEventScreenDrag:
		var d := event as InputEventScreenDrag
		_touches[d.index] = d.position
		if _touches.size() >= 2:
			_pinch()
		else:
			_pan(d.relative)
		accept_event()
	elif event is InputEventMouseButton:
		var m := event as InputEventMouseButton
		if m.button_index == MOUSE_BUTTON_WHEEL_UP and m.pressed:
			set_zoom(zoom + 1)
		elif m.button_index == MOUSE_BUTTON_WHEEL_DOWN and m.pressed:
			set_zoom(zoom - 1)
		elif m.button_index == MOUSE_BUTTON_LEFT:
			if m.pressed:
				_press_at = m.position
				_press_ms = Time.get_ticks_msec()
			else:
				_release(m.position)
	elif event is InputEventMouseMotion and (event as InputEventMouseMotion).button_mask & MOUSE_BUTTON_MASK_LEFT:
		_pan((event as InputEventMouseMotion).relative)
	elif event is InputEventMagnifyGesture:
		var g := event as InputEventMagnifyGesture
		if g.factor > 1.15:
			set_zoom(zoom + 1)
		elif g.factor < 0.87:
			set_zoom(zoom - 1)


## A tap on a realm swoops to it; a second tap on the realm on show closes
## in.
func _release(at: Vector2) -> void:
	if at.distance_to(_press_at) > TAP_PX or Time.get_ticks_msec() - _press_ms > TAP_MS:
		return
	var id := realm_at(at)
	if id == "":
		return
	choose(id)


## Realm `id` chosen, by a tap on it or on its pin.
func choose(id: String) -> void:
	focus_realm(id, 2 if id == focus_id and zoom == 1 else 1)
	realm_chosen.emit(id)


## Two fingers: apart or together zooms a level, a twist of 40° turns.
func _pinch() -> void:
	var keys := _touches.keys()
	var a: Vector2 = _touches[keys[0]]
	var b: Vector2 = _touches[keys[1]]
	var dist := a.distance_to(b)
	var angle := (b - a).angle()
	if _gesture.is_empty():
		_gesture = {"dist": dist, "angle": angle}
		return
	if dist > float(_gesture["dist"]) * 1.3:
		set_zoom(zoom + 1)
		_gesture = {"dist": dist, "angle": angle}
	elif dist < float(_gesture["dist"]) * 0.75:
		set_zoom(zoom - 1)
		_gesture = {"dist": dist, "angle": angle}
	var twist := wrapf(angle - float(_gesture["angle"]), -PI, PI)
	if absf(twist) > deg_to_rad(40.0):
		turn(1 if twist > 0.0 else -1)
		_gesture = {"dist": dist, "angle": angle}


## A drag moves the camera over the map, never off it.
func _pan(by: Vector2) -> void:
	if _swoop < 1.0:
		return
	var per_px := _size / maxf(1.0, size.y)
	var right := camera.global_basis.x
	var ahead := Vector3(-sin(_yaw), 0, -cos(_yaw))
	var move := (-right * by.x + ahead * by.y / sin(deg_to_rad(PITCH))) * per_px
	move.y = 0.0
	var lo := _bounds.position
	var hi := _bounds.end
	_target = Vector3(clampf(_target.x + move.x, lo.x, hi.x), _target.y, clampf(_target.z + move.z, lo.z, hi.z))


## The cloud wipe: soft puffs that close over the screen and open again.
func _draw_wipe() -> void:
	if _wipe_amount <= 0.01:
		return
	var s := _wipe.size
	var n := 18
	for k in n:
		var fx := fmod(k * 0.618, 1.0)
		var fy := fmod(k * 0.381 + 0.13, 1.0)
		var r := (0.25 + 0.2 * fmod(k * 0.77, 1.0)) * s.length() * _wipe_amount
		var tint := Color("#F4EEFF").lerp(Color("#C9B6FF"), fmod(k * 0.53, 1.0) * 0.5)
		_wipe.draw_circle(Vector2(fx * s.x, fy * s.y), r, Color(tint, minf(1.0, _wipe_amount * 1.4)))


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED and not islands.is_empty():
		_aim(true)


## Draw calls the map makes (§21.3: "under 150"), its own meshes counted with
## their outline passes, before the shadow pass.
func draw_calls() -> int:
	var n := 0
	for node in world.find_children("*", "GeometryInstance3D", true, false):
		var g := node as GeometryInstance3D
		if not g.visible:
			continue
		n += 1
		var m := g.material_override as ShaderMaterial
		if m != null and m.next_pass != null:
			n += 1
	return n
