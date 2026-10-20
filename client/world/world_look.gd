class_name WorldLook
extends RefCounted
## How a realm looks around its grid (§21.1: "Picture-book dioramas floating in
## a violet sky"; §21.2's skies): the light, the sky by the hour, and the
## floating rock the grid stands on. `WorldView` asks for these and draws the
## simulation's pieces on top.

static var _sky: Shader = load("res://world/sky.gdshader")
static var _toon: Shader = load("res://world/toon.gdshader")

var environment: Environment
var sun: DirectionalLight3D


## One warm sun with its shadow, a sky by the hour, ambient light from the
## sky so shade is violet, not black; added to `world`.
func _init(world: Node3D) -> void:
	environment = Environment.new()
	environment.background_mode = Environment.BG_SKY
	var sky := Sky.new()
	var sky_material := ShaderMaterial.new()
	sky_material.shader = _sky
	sky.sky_material = sky_material
	environment.sky = sky
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color("#8E86C8")
	environment.ambient_light_energy = 0.42
	environment.tonemap_mode = Environment.TONE_MAPPER_LINEAR
	var env_node := WorldEnvironment.new()
	env_node.environment = environment
	world.add_child(env_node)
	sun = DirectionalLight3D.new()
	sun.light_color = Color("#FFF1DA")
	sun.light_energy = 0.82
	sun.shadow_enabled = true
	sun.directional_shadow_mode = DirectionalLight3D.SHADOW_ORTHOGONAL
	sun.directional_shadow_max_distance = 60.0
	sun.rotation_degrees = Vector3(-58, 35, 0)
	world.add_child(sun)
	set_hour(Time.get_datetime_dict_from_system()["hour"])


## §21.2: the sky follows the player's local time, and the light with it: a
## warm sun by day, a low amber one at dusk, a cool moon at night, when
## lanterns and glows carry the realm.
func set_hour(hour: int) -> void:
	var pair := RealmPalette.sky_at(hour)
	var m := environment.sky.sky_material as ShaderMaterial
	m.set_shader_parameter("top", pair[0])
	m.set_shader_parameter("bottom", pair[1])
	var light: Array = RealmPalette.light_at(hour)
	sun.light_color = light[0]
	sun.light_energy = light[1]
	environment.ambient_light_color = light[2]
	environment.ambient_light_energy = light[3]


## The floating rock round a grid of `grid` tiles, its scatter and the sky's
## dressing, added to `statics`.
func island(statics: Node3D, grid: Vector2i, seed_from: int, colours: Dictionary) -> void:
	var builder := IslandBuilder.new(grid, seed_from, colours)
	for part: Array in [[builder.rock(), true], [builder.scatter(), false], [builder.sky_dressing(), false]]:
		if part[0] == null:
			continue
		var m := ShaderMaterial.new()
		m.shader = _toon
		m.set_shader_parameter("glow_from_alpha", 1.0)
		var mi := MeshInstance3D.new()
		mi.mesh = part[0]
		mi.material_override = m
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON if part[1] \
			else GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		statics.add_child(mi)
