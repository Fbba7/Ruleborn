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
## The realm still to open was tapped (its pin): where it is bought.
signal next_chosen

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
## The Heart's citadel from T3's kit (its Keeper's Spire), or the map's own
## port of the design's castle (`UniverseCitadel`).
const CITADEL_FROM_KIT := true
## How far back the camera stands from what it looks at: enough that the
## whole column is in front of it, near enough that the sun's shadow reaches.
const BACK := 140.0
## The camera's size over a whole universe, at which the sky is drawn at its
## own scale (`universe_galaxy.gdshader`'s `sky_scale`).
const SKY_SIZE := 90.0
## A fault, in the alarm's red (§21.8 keeps red for alarms).
const FAULT := Color("#FF5A7A")

static var _toon: Shader = load("res://world/universe_toon.gdshader")
static var _outline: Shader = load("res://world/outline.gdshader")
static var _glow: Shader = load("res://world/universe_glow.gdshader")
static var _veil: Shader = load("res://world/universe_veil.gdshader")
static var _shade: Shader = load("res://world/universe_shade.gdshader")
static var _dome: Shader = load("res://world/universe_dome.gdshader")

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
## Each link as drawn: its kind and its middle, where its pin stands.
var links: Array[Dictionary] = []
## Pixels at the top and bottom that a screen's own controls cover: the
## camera frames the universe into what is left (`set_inset`).
var inset := Vector2.ZERO
## The screen's own controls over the world (home's side buttons), in the
## view's pixels, which pins keep clear of.
var keep_clear: Array[Rect2] = []

var _view := {}
var _extras := {}
## A realm asked for before it was drawn: [id, zoom], shown once it is.
var _wanted := []
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
var _wipe: UniverseWipe
var _wipe_amount := 0.0
var _tilt := Vector2.ZERO
var _time := 0.0
var _touches := {}
var _gesture := {}
var _press_at := Vector2.ZERO
var _press_ms := 0
var _spinners: Array[Dictionary] = []
var _streams: Array[Dictionary] = []
var _flight: UniverseFlight
var _crowd: UniverseCrowd
var _lods := {}
var _rocks := {}
var _close := {}


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
	_wipe = UniverseWipe.new()
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
	environment.ambient_light_energy = 0.5
	environment.tonemap_mode = Environment.TONE_MAPPER_LINEAR
	var env_node := WorldEnvironment.new()
	env_node.environment = environment
	world.add_child(env_node)
	sun = DirectionalLight3D.new()
	sun.light_color = Color("#FFE6C8")
	sun.light_energy = 0.95
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
	camera.far = 600.0
	world.add_child(camera)
	statics = Node3D.new()
	world.add_child(statics)
	movers = Node3D.new()
	world.add_child(movers)
	var people := Node3D.new()
	people.name = "Characters"
	world.add_child(people)
	_crowd = UniverseCrowd.new(people)


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
		if not _wanted.is_empty() and islands.has(str(_wanted[0])):
			focus_realm(str(_wanted[0]), int(_wanted[1]))
			_aim(true)
	pins.show_pins(view, extras)


## Every island, link, skiff and the sky, from the view.
func _build() -> void:
	for c in statics.get_children():
		c.queue_free()
	for c in movers.get_children():
		c.queue_free()
	islands.clear()
	_lods.clear()
	_rocks.clear()
	_close.clear()
	_crowd.show("", null, [])
	_spinners.clear()
	_streams.clear()
	triangles = 0
	var realms: Array = _view.get("realms", [])
	var ghosts := 1 if _view.get("open") is Dictionary else 0
	places = UniverseLayout.places(realms, ghosts)
	var glows := UniversePaint.new()
	var light := UniversePaint.new()
	var flow := UniversePaint.new()
	for r: Dictionary in realms:
		var id := str(r.get("realm", ""))
		if not places.has(id):
			continue
		var island := UniverseIsland.new(r, places[id])
		island.spire = int(_view.get("spire", 1))
		_rock(id, island, glows, light, flow, r.get("buildings", []))
		islands[id] = island
	if ghosts > 0 and places.has("next:0"):
		var types: Array = (_view["open"] as Dictionary).get("types", [])
		var ghost := UniverseIsland.new({"realm": "next:0", "type": str(types[0]) if not types.is_empty() else "Heart",
			"ghost": true}, places["next:0"])
		_rock("next:0", ghost, glows, light, flow, [])
		islands["next:0"] = ghost
	_build_scatter()
	_build_lods()
	_build_links(glows, light, flow)
	_build_faults(light, glows)
	# Framed to the islands' rims, so the whole universe fills the screen's
	# width as the designs' home does.
	_bounds = UniverseLayout.bounds(places, UniverseLayout.radius(UniverseLayout.OUTER_GRID))
	triangles += glows.count + light.count + flow.count
	_add(glows.mesh(), _glow_material(0.3, 0.35), false)
	_add(light.mesh(), _veil_material(0.0, 0.0), false)
	_add(flow.mesh(), _veil_material(1.6, 3.0), false)
	_build_citadel()
	_build_heart_rings()
	var centre := _bounds.get_center()
	StarSky.new(hash(str(realms.size()))).build(statics, Vector3(centre.x, 0, centre.z),
		maxf(60.0, _bounds.size.z * 0.6))
	_flight = UniverseFlight.new(movers, islands, _view, _bounds, _streams)
	triangles += _flight.triangles


## An island's own rock, ground and dressing on a node of its own, so a
## close-up draws only the islands on the screen; the realm seen close swaps
## it for T2's island (`_show_close`).
func _rock(id: String, island: UniverseIsland, glows: UniversePaint, light: UniversePaint,
		flow: UniversePaint, buildings: Array) -> void:
	var body := Geo.new()
	var hero := Geo.new()
	island.build(body, hero, glows, light, flow, buildings)
	var node := Node3D.new()
	node.name = "Rock"
	statics.add_child(node)
	var shade := ShaderMaterial.new()
	shade.shader = _shade
	for part: Array in [[body.mesh(), _material()], [hero.mesh(), _material(true)], [island.shades.mesh(), shade]]:
		if part[0] == null:
			continue
		var mi := MeshInstance3D.new()
		mi.mesh = part[0]
		mi.material_override = part[1]
		node.add_child(mi)
	triangles += body.triangles + hero.triangles + island.shades.count
	_rocks[id] = node


## The realm seen close (zoom 2) drawn as T2 draws a realm's island, built
## the first time it is seen close and kept; every other island its rock.
func _show_close() -> void:
	var shown := focus_id if zoom == 2 and islands.has(focus_id) and not focus_id.begins_with("next:") else ""
	if shown != "" and not _close.has(shown):
		_make_close(shown)
	for id: String in _rocks:
		(_rocks[id] as Node3D).visible = id != shown
	for id: String in _close:
		(_close[id] as Node3D).visible = id == shown


func _make_close(id: String) -> Node3D:
	var close := UniverseClose.build(islands[id], UniverseLayout.grid({"realm": id}))
	statics.add_child(close)
	_close[id] = close
	return close


## The triangles inside the camera's view now (`UniverseBudget.drawn`).
func drawn_triangles() -> int:
	return UniverseBudget.drawn(world, camera)


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


## Each realm's buildings at two levels of detail on a node of their own; the
## close ones are shown only on the realm the camera is on (`_show_lods`).
func _build_lods() -> void:
	_lods.clear()
	for id: String in islands:
		var isl: UniverseIsland = islands[id]
		var node := Node3D.new()
		node.name = "Buildings"
		statics.add_child(node)
		var near := Node3D.new()
		node.add_child(near)
		var far := MeshInstance3D.new()
		far.mesh = isl.far.mesh()
		far.material_override = _material(true)
		far.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		node.add_child(far)
		triangles += isl.far.triangles
		_lods[id] = [near, far]
	_show_lods()


## The realm's buildings drawn close, made the first time they are shown.
func _near_of(id: String) -> Node3D:
	var near := _lods[id][0] as Node3D
	if near.get_child_count() > 0 or not islands.has(id):
		return near
	var isl: UniverseIsland = islands[id]
	isl.build_near()
	for part: Array in [[isl.near, _material(true), "Kit"], [isl.near_fine, _material(), "Fine"]]:
		var mesh: ArrayMesh = (part[0] as Geo).mesh()
		if mesh != null:
			var mi := MeshInstance3D.new()
			mi.mesh = mesh
			mi.material_override = part[1]
			mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			mi.name = part[2]
			near.add_child(mi)
	return near


func _show_lods() -> void:
	for id: String in _lods:
		var close := zoom > 0 and id == focus_id
		if close:
			_near_of(id)
		(_lods[id][0] as Node3D).visible = close
		(_lods[id][1] as Node3D).visible = not close
		# The kit's fine parts (windows, frames, flags) only in a close-up,
		# where they can be seen, and not on the Heart, whose island takes
		# their room in §21.3's budget.
		var fine := (_lods[id][0] as Node3D).get_node_or_null("Fine") as Node3D
		if fine != null:
			fine.visible = zoom == 2 and id != "heart"
	_show_close()
	# The citadel larger over the whole universe, so the Heart reads first
	# from afar as the designs' home draws it; life-sized for the realm zooms.
	var citadel := statics.get_node_or_null("Citadel") as Node3D
	if citadel != null:
		citadel.scale = Vector3.ONE * (UniverseCitadel.FAR_SCALE if zoom == 0 else UniverseCitadel.MAP_SCALE)
	# The realm's own characters, in a close-up only.
	var shown := focus_id if zoom == 2 and islands.has(focus_id) else ""
	if _crowd != null:
		_crowd.show(shown, islands.get(shown), _extras.get("characters", []))


## Every island's meadow: tufts of grass and flowers, two layers of
## instances for the whole universe (§21.3: MultiMesh scatter).
func _build_scatter() -> void:
	var tufts: Array = []
	var flowers: Array = []
	var petals: Array = []
	for id: String in islands:
		(islands[id] as UniverseIsland).scatter(tufts, flowers, petals)
	# Three blades a tuft, a stem and a head a flower: a few triangles each.
	var tuft := Geo.new()
	for b in 3:
		var a := b * 2.1
		var root := Vector3(cos(a) * 0.07, 0, sin(a) * 0.07)
		var side := Vector3(-sin(a), 0, cos(a)) * 0.07
		var tip := root * 2.5 + Vector3(0, 0.42 - 0.06 * b, 0)
		tuft.tri(root - side, tip, root + side, Color.WHITE)
	var bloom := Geo.new()
	bloom.tri(Vector3(-0.02, 0, 0), Vector3(0, 0.26, 0), Vector3(0.02, 0, 0), Color("#5A9A48"))
	for k in 3:
		var a0 := TAU * k / 3.0
		var a1 := TAU * (k + 1) / 3.0
		bloom.tri(Vector3(0, 0.34, 0), Vector3(cos(a1) * 0.1, 0.24, sin(a1) * 0.1),
			Vector3(cos(a0) * 0.1, 0.24, sin(a0) * 0.1), Color.WHITE)
	var petal := Geo.new()
	petal.quad(Vector3(-0.12, 0, 0), Vector3(0, 0, -0.07), Vector3(0.12, 0, 0), Vector3(0, 0, 0.07), Color.WHITE)
	for layer: Array in [[tufts, tuft.mesh()], [flowers, bloom.mesh()], [petals, petal.mesh()]]:
		var items: Array = layer[0]
		if items.is_empty():
			continue
		var mm := MultiMesh.new()
		mm.transform_format = MultiMesh.TRANSFORM_3D
		mm.use_colors = true
		mm.mesh = layer[1]
		mm.instance_count = items.size()
		for i in items.size():
			mm.set_instance_transform(i, items[i][0])
			mm.set_instance_color(i, items[i][1])
		var mmi := MultiMeshInstance3D.new()
		mmi.multimesh = mm
		mmi.material_override = _material()
		mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		statics.add_child(mmi)
		triangles += items.size() * ((layer[1] as ArrayMesh).surface_get_array_len(0) / 3)


## §5.3's links, each built to its gap; a rope bridge on its own node, so it
## sways.
func _build_links(glows: UniversePaint, light: UniversePaint, flow: UniversePaint) -> void:
	links.clear()
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
		links.append({"kind": link.kind, "mid": (ends[0] + ends[1]) / 2.0 + Vector3(0, link.length * 0.06 + 1.2, 0)})
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
			# Each link its own mesh, so one off the screen is not drawn.
			var own := Geo.new()
			link.build(own, glows, flow, light)
			triangles += own.triangles
			var mi := MeshInstance3D.new()
			mi.mesh = own.mesh()
			mi.material_override = _material(true)
			mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			statics.add_child(mi)
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


## The Heart's citadel on a node of its own, drawn larger than the realm's
## buildings so the Heart reads from across the universe.
func _build_citadel() -> void:
	if not islands.has("heart"):
		return
	var heart: UniverseIsland = islands["heart"]
	var solid := Geo.new()
	var fine := Geo.new()
	var lights := UniversePaint.new()
	if CITADEL_FROM_KIT:
		# T3's citadel (the kit's Keeper's Spire on a five-tile footprint),
		# with the orb's light and the gate's braziers the map adds.
		BuildingKit.build(solid, "keeper_s_spire", Vector3(0, UniverseIsland.dome(0.0) - 0.05, 0), 5, heart.spire,
			heart.palette, fine)
		lights.glow(Vector3(0, 9.6, 0), 2.4, Color(heart.palette["accent"], 0.8))
		lights.glow(Vector3(0, 9.6, 0), 0.8, Color(Color.WHITE, 0.9))
	else:
		UniverseCitadel.build(solid, lights, Vector3(0, UniverseIsland.dome(0.0) - 0.05, 0), heart.palette,
			heart.spire)
	var node := Node3D.new()
	node.position = heart.at
	node.scale = Vector3.ONE * (UniverseCitadel.FAR_SCALE if zoom == 0 else UniverseCitadel.MAP_SCALE)
	node.name = "Citadel"
	statics.add_child(node)
	for part: Array in [[solid.mesh(), _material(true), true], [fine.mesh(), _material(), false],
			[lights.mesh(), _glow_material(0.3, 0.35), false]]:
		if part[0] == null:
			continue
		var mi := MeshInstance3D.new()
		mi.mesh = part[0]
		mi.material_override = part[1]
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON if part[2] \
			else GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		mi.extra_cull_margin = 10.0
		node.add_child(mi)
	triangles += solid.triangles + fine.triangles + lights.count


## The Heart's rings, turning (the design's three tori, :1166), in the strain
## band's colour: calm white, then gold, ember and the alarm's red.
func _build_heart_rings() -> void:
	if not islands.has("heart"):
		return
	var heart: UniverseIsland = islands["heart"]
	# The winds' dome over the Heart (§5.4), faint, seen at its edge.
	var dome := MeshInstance3D.new()
	var shell := SphereMesh.new()
	shell.radius = heart.radius * 1.15
	shell.height = heart.radius * 1.15 * 1.6
	shell.is_hemisphere = true
	shell.radial_segments = 32
	shell.rings = 8
	dome.mesh = shell
	var dm := ShaderMaterial.new()
	dm.shader = _dome
	dome.material_override = dm
	dome.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	dome.position = heart.at
	statics.add_child(dome)
	triangles += 32 * 8 * 2
	var band := int(_extras.get("band", 0))
	var colours: Array[Color] = [Color("#E6F4FF"), Color("#FFD27A"), Color("#FF9A5A"), FAULT]
	var tint: Color = colours[clampi(band, 0, colours.size() - 1)]
	for i in 3:
		var paint := UniversePaint.new()
		var r := heart.radius * (1.22 + 0.17 * i)
		var inner := PackedVector3Array()
		var outer := PackedVector3Array()
		for k in 49:
			var a := PI * (1.2 + 0.2 * i) * k / 48.0
			inner.append(Vector3(cos(a) * r, 0, sin(a) * r))
			outer.append(Vector3(cos(a) * (r + 0.24), 0, sin(a) * (r + 0.24)))
		paint.strip(inner, outer, Color(tint, 1.0), 1.0, true)
		var mi := MeshInstance3D.new()
		mi.mesh = paint.mesh()
		mi.material_override = _veil_material(0.0, 0.0)
		(mi.material_override as ShaderMaterial).set_shader_parameter("strength", 0.55)
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		mi.position = heart.at + Vector3(0, 0.6 + i * 0.9, 0)
		mi.rotation = Vector3(0.06 * (i - 1), i * 2.0, 0.05 * (1 - i))
		statics.add_child(mi)
		_spinners.append({"node": mi, "axis": Vector3.UP, "turn": (0.35 + i * 0.12) * (-1.0 if i % 2 else 1.0)})


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
	# Resting on a realm, its island as seen close is made ready, so the
	# swoop in does not wait for it.
	if zoom == 1 and _swoop >= 1.0 and focus_id != "heart" and islands.has(focus_id) \
			and not focus_id.begins_with("next:") and not _close.has(focus_id):
		_make_close(focus_id).visible = false
	if _flight != null:
		_flight.fly(_time)
		_flight.drift(_time)
	_crowd.step(_time)
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


## The camera where the swoop has it, tilted by the phone.
func _place_camera() -> void:
	var yaw := _yaw + deg_to_rad(_tilt.x * TILT_DEGREES.x)
	var p := deg_to_rad(PITCH + _tilt.y * TILT_DEGREES.y)
	var back := Vector3(sin(yaw) * cos(p), sin(p), cos(yaw) * cos(p))
	camera.size = maxf(_size, 1.0)
	# The sun's shadow reaches as far as the camera sees, and no further.
	sun.directional_shadow_max_distance = BACK + clampf(_size * 0.9, 30.0, 160.0)
	camera.v_offset = -(inset.y - inset.x) / 2.0 * _size / maxf(1.0, size.y)
	_set_origin(back)
	if not camera.is_inside_tree():
		camera.position = _target + back * BACK
		return
	camera.look_at_from_position(_target + back * BACK, _target, Vector3.UP)


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
	m.set_shader_parameter("sky_scale", maxf(1.0, SKY_SIZE / maxf(1.0, camera.size)))


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
	_show_lods()
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
		_wipe.set_amount(_wipe_amount)
		return
	_target = (_from[0] as Vector3).lerp(_to[0], e)
	_size = lerpf(_from[1], _to[1], e)
	_yaw = lerp_angle(_from[2], _to[2], e)


## The camera on realm `id` at zoom `level` (1 or 2), swooping there; from
## one realm to another, through cloud.
func focus_realm(id: String, level := 1) -> void:
	if id.begins_with("next:"):
		return
	if not islands.has(id):
		_wanted = [id, level]
		return
	_wanted = []
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


## A quarter turn of the camera, either way (§21.1). Over the whole
## universe a turn is a half turn, so its column stays upright on a portrait
## screen rather than lying across it.
func turn(by: int) -> void:
	turns = posmod(turns + by * (2 if zoom == 0 else 1), 4)
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


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED and not islands.is_empty():
		_aim(true)


## Draw calls the map makes (§21.3: "under 150"), its own meshes counted with
## their outline passes, before the shadow pass.
func draw_calls() -> int:
	var n := 0
	for node in world.find_children("*", "GeometryInstance3D", true, false):
		var g := node as GeometryInstance3D
		if not g.is_visible_in_tree():
			continue
		n += 1
		var m := g.material_override as ShaderMaterial
		if m != null and m.next_pass != null:
			n += 1
	return n
