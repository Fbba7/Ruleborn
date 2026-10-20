class_name WorldLook
extends RefCounted
## How a realm looks around its grid (§21.1: "Picture-book dioramas floating in
## a violet sky"; §21.2's skies; §21.4's realms): the light, the sky by the
## realm and the hour, the fog that sinks the rock into the sky, the
## vignette, and the floating island the grid stands on with its scatter,
## roots, waterfalls and clouds. `WorldView` asks for these and draws the
## simulation's pieces on top.

static var _sky: Shader = load("res://world/sky.gdshader")
static var _toon: Shader = load("res://world/toon.gdshader")
static var _ground: Shader = load("res://world/look_ground.gdshader")
static var _fall: Shader = load("res://world/look_fall.gdshader")
static var _mist: Shader = load("res://world/look_mist.gdshader")
static var _cloud: Shader = load("res://world/look_cloud.gdshader")
static var _vignette: Shader = load("res://world/look_vignette.gdshader")

var environment: Environment
var sun: DirectionalLight3D
## The realm type the look is drawn for (§21.4), and the hour (§21.2).
var realm := "heart"
var hour := 12
var vignette: ColorRect
## The sky's gradient (sky.gdshader), drawn behind the world.
var sky_material: ShaderMaterial
var _mists: Array[ShaderMaterial] = []
var _clouds: ShaderMaterial


## One warm sun with its shadow, a sky by the hour, ambient light from the
## sky so shade is violet, not black, fog and a vignette; added to `world`.
func _init(world: Node3D) -> void:
	environment = Environment.new()
	# The sky is a gradient over the whole screen, at the far plane.
	environment.background_mode = Environment.BG_COLOR
	sky_material = ShaderMaterial.new()
	sky_material.shader = _sky
	var sky_quad := MeshInstance3D.new()
	sky_quad.mesh = _quad()
	sky_quad.material_override = sky_material
	sky_quad.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	sky_quad.custom_aabb = AABB(Vector3(-1e5, -1e5, -1e5), Vector3(2e5, 2e5, 2e5))
	world.add_child(sky_quad)
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.tonemap_mode = Environment.TONE_MAPPER_LINEAR
	# The rock sinks into the sky below the island (the diorama's `Fog`, :490).
	environment.fog_enabled = true
	environment.fog_mode = Environment.FOG_MODE_EXPONENTIAL
	environment.fog_density = 0.0
	environment.fog_height = -2.5
	environment.fog_height_density = 0.06
	environment.fog_sky_affect = 0.0
	var env_node := WorldEnvironment.new()
	env_node.environment = environment
	world.add_child(env_node)
	sun = DirectionalLight3D.new()
	sun.shadow_enabled = true
	sun.directional_shadow_mode = DirectionalLight3D.SHADOW_ORTHOGONAL
	# Shadows fitted to one island under the orthographic camera, soft
	# enough that pieces sit on the ground (§21.1's "toy-like").
	sun.directional_shadow_max_distance = 48.0
	sun.shadow_blur = 1.6
	sun.shadow_bias = 0.04
	sun.shadow_normal_bias = 1.2
	world.add_child(sun)
	var layer := CanvasLayer.new()
	layer.layer = -1
	vignette = ColorRect.new()
	vignette.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	vignette.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var vm := ShaderMaterial.new()
	vm.shader = _vignette
	vignette.material = vm
	layer.add_child(vignette)
	world.add_child(layer)
	set_hour(Time.get_datetime_dict_from_system()["hour"])


## §21.2: the sky follows the player's local time, and the light with it: a
## warm sun by day, a low amber one at dusk, a cool moon at night, when
## lanterns and glows carry the realm. The realm's own sky and light
## (§21.4) are crossed with the hour's.
func set_hour(new_hour: int) -> void:
	hour = new_hour
	var sky := RealmPalette.realm_sky_at(hour, realm)
	var m := sky_material
	m.set_shader_parameter("top", sky[0])
	m.set_shader_parameter("middle", sky[1])
	m.set_shader_parameter("bottom", sky[2])
	var glow := sky[3]
	glow.a = 0.4
	m.set_shader_parameter("glow", glow)
	var dark := sky[0].get_luminance() < 0.2
	m.set_shader_parameter("stars", 0.9 if dark or realm == "crystalline" else 0.0)
	var light: Array = RealmPalette.light_at(hour, realm)
	sun.light_color = light[0]
	sun.light_energy = light[1]
	environment.ambient_light_color = light[2]
	environment.ambient_light_energy = light[3]
	var at := RealmPalette.sun_from(hour, realm)
	sun.basis = Basis.looking_at(-at, Vector3.UP if absf(at.y) < 0.99 else Vector3.FORWARD)
	# The fog takes the sky's middle, lifted toward its horizon.
	environment.fog_light_color = sky[1].lerp(sky[2], 0.45)
	environment.fog_light_energy = 1.0
	for mist: ShaderMaterial in _mists:
		mist.set_shader_parameter("colour", sky[2].lerp(Color.WHITE, 0.55))
	if _clouds != null:
		var lit: Color = light[0]
		_clouds.set_shader_parameter("top", Color.WHITE.lerp(lit, 0.25).lerp(sky[2], 0.12))
		_clouds.set_shader_parameter("under", sky[1].lerp(sky[2], 0.55).lerp(Color.WHITE, 0.3))
	var vm := vignette.material as ShaderMaterial
	var edge := sky[0].darkened(0.55)
	edge.a = 0.42
	vm.set_shader_parameter("edge", edge)


## The floating rock round a grid of `grid` tiles, its scatter and the sky's
## dressing, added to `statics`. `type` is §21.4's realm; without it the
## palette names it.
func island(statics: Node3D, grid: Vector2i, seed_from: int, colours: Dictionary, type := "") -> void:
	var builder := IslandBuilder.new(grid, seed_from, colours, type)
	realm = builder.kind
	_mists.clear()
	var paint_scale := 4.2
	statics.add_child(_piece(builder.meadow(), _painted(LookPaint.grass(), paint_scale), false))
	statics.add_child(_piece(builder.cliffs(), _painted(LookPaint.rock(), 0.0), true))
	var roots := builder.roots()
	statics.add_child(_piece(roots[0], _painted(LookPaint.rock(), 0.0, 0.5), true))
	var vines := _painted(null, 0.0)
	vines.set_shader_parameter("sway", 0.18)
	vines.set_shader_parameter("sway_by_uv", true)
	statics.add_child(_piece(roots[1], vines, false))
	for part: Array in builder.scatter():
		statics.add_child(_scatter(part[0], part[1], part[2], part[3], part[4]))
	var falls := builder.waterfalls()
	if falls[0] != null:
		var fm := ShaderMaterial.new()
		fm.shader = _fall
		statics.add_child(_piece(falls[0], fm, false))
		var pm := ShaderMaterial.new()
		pm.shader = load("res://world/water.gdshader")
		statics.add_child(_piece(falls[1], pm, false))
		for foot: Vector3 in falls[2]:
			for j in 3:
				statics.add_child(_mist_at(foot + Vector3((j - 1) * 0.5, j * 0.3, 0), 2.4 + j, 0.35))
	var dressing := builder.sky_dressing()
	statics.add_child(_piece(dressing[0], _painted(LookPaint.rock(), 0.0, 0.6), true))
	var cloud := ShaderMaterial.new()
	cloud.shader = _cloud
	_clouds = cloud
	statics.add_child(_piece(dressing[1], cloud, false))
	# The cloud sea under the island: soft, wide and slow.
	var r := builder.radius()
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_from
	for i in 6:
		var a := rng.randf() * TAU
		var d := r * (0.5 + rng.randf() * 0.7)
		var mist := _mist_at(Vector3(cos(a) * d, -6.5 - rng.randf() * 3.0, sin(a) * d), 9.0 + rng.randf() * 5.0, 0.24)
		mist.scale.y *= 0.5
		statics.add_child(mist)
	set_hour(hour)


static func _piece(mesh: Mesh, mat: Material, shadows: bool) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = mat
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON if shadows \
		else GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return mi


## The painted ground material: `paint` laid at `scale` metres a tile, or by
## the mesh's UV when `scale` is 0; no paint when null.
static func _painted(paint: Texture2D, scale: float, strength := 1.0) -> ShaderMaterial:
	var m := ShaderMaterial.new()
	m.shader = _ground
	if paint != null:
		m.set_shader_parameter("paint", paint)
		m.set_shader_parameter("paint_strength", strength)
	else:
		m.set_shader_parameter("paint_strength", 0.0)
	m.set_shader_parameter("world_scale", scale)
	return m


## One kind of scatter as a MultiMesh: one draw call however many there are.
static func _scatter(mesh: Mesh, at: Array[Transform3D], colours: Array[Color], sway: float,
		drift: float) -> MultiMeshInstance3D:
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = true
	mm.mesh = mesh
	mm.instance_count = at.size()
	for i in at.size():
		mm.set_instance_transform(i, at[i])
		mm.set_instance_color(i, colours[i])
	var mi := MultiMeshInstance3D.new()
	mi.multimesh = mm
	var m := _painted(null, 0.0)
	m.set_shader_parameter("sway", sway)
	m.set_shader_parameter("drift", drift)
	mi.material_override = m
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return mi


## A soft puff of mist facing the camera, `width` across.
func _mist_at(at: Vector3, width: float, opacity: float) -> MeshInstance3D:
	var m := ShaderMaterial.new()
	m.shader = _mist
	m.set_shader_parameter("opacity", opacity)
	m.set_shader_parameter("drift", 0.8)
	_mists.append(m)
	var mi := _piece(_quad(), m, false)
	mi.position = at
	mi.scale = Vector3(width, width * 0.6, 1.0)
	return mi


## A unit quad facing +Z, centred, with its UV: the sky's and the mists'.
static func _quad() -> ArrayMesh:
	var m := LookMesh.new()
	var a := Vector3(-0.5, -0.5, 0)
	var b := Vector3(0.5, -0.5, 0)
	var c := Vector3(0.5, 0.5, 0)
	var d := Vector3(-0.5, 0.5, 0)
	m.tri(a, b, c, Color.WHITE, Vector3.BACK, Vector2(0, 1), Vector2(1, 1), Vector2(1, 0))
	m.tri(a, c, d, Color.WHITE, Vector3.BACK, Vector2(0, 1), Vector2(1, 0), Vector2(0, 0))
	return m.mesh()
