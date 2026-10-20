class_name StarSky
extends RefCounted
## The night the universe hangs in (§21.1: "dioramas floating in a violet
## sky"; §21.2: menus "stand on a night backdrop"): the galaxy plane far
## below, three layers of stars at different depths, so a tilt of the phone
## moves them apart, and drifting nebula light between them (the design's
## galaxy sky, realm_diorama.js :1074–1134). Comets and shooting stars are
## moved by the map each frame (`UniverseView`).

## How far below the islands the galaxy lies.
const DEPTH := -60.0

static var _galaxy: Shader = load("res://world/universe_galaxy.gdshader")
static var _glow: Shader = load("res://world/universe_glow.gdshader")

var _seed := 7


func _init(sky_seed := 7) -> void:
	_seed = sky_seed


func _noise(i: int) -> float:
	var h := (_seed * 73856093) ^ (i * 19349663)
	h = (h ^ (h >> 13)) * 1274126177
	return float(posmod(h ^ (h >> 16), 100000)) / 100000.0


## The sky round `centre`, reaching `reach` metres along the column, added
## to `parent`. Three draw calls: the galaxy, the stars, the nebula light.
func build(parent: Node3D, centre: Vector3, reach: float) -> void:
	var plane := MeshInstance3D.new()
	var quad := PlaneMesh.new()
	quad.size = Vector2(reach * 9.0, reach * 9.0)
	plane.mesh = quad
	var m := ShaderMaterial.new()
	m.shader = _galaxy
	# Placed from the point under the middle of the screen (`origin`, which
	# the map moves): the galaxy low in the frame, nebulae round it.
	m.set_shader_parameter("galaxy_at", Vector2(reach * 0.15, reach * 0.55))
	m.set_shader_parameter("galaxy_radius", reach * 1.05)
	m.set_shader_parameter("nebula_a", Vector4(-reach * 0.6, -reach * 0.7, reach * 0.7, 0))
	m.set_shader_parameter("nebula_b", Vector4(reach * 0.7, reach * 0.1, reach * 0.6, 0))
	m.set_shader_parameter("nebula_c", Vector4(-reach * 0.3, reach * 0.9, reach * 0.7, 0))
	m.set_shader_parameter("nebula_d", Vector4(reach * 0.4, -reach * 1.2, reach * 0.6, 0))
	# Drawn first, behind everything: all light is added over it.
	m.render_priority = -100
	plane.material_override = m
	plane.position = centre + Vector3(0, DEPTH, 0)
	plane.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	plane.name = "Galaxy"
	parent.add_child(plane)
	var stars := UniversePaint.new()
	var span := Vector3(reach * 2.6, 0, reach * 3.6)
	# Far dust, the warm stars, and a few bright ones near the islands.
	for i in 260:
		var p := centre + Vector3((_noise(i) - 0.5) * span.x, -reach * (0.25 + 0.5 * _noise(i + 900)),
			(_noise(i + 1800) - 0.5) * span.z)
		stars.glow(p, 0.3 + 0.3 * _noise(i + 2700), Color(Color("#FFFFFF"), 0.18 + 0.3 * _noise(i + 3600)))
	for i in 90:
		var p := centre + Vector3((_noise(i + 5000) - 0.5) * span.x, -reach * (0.15 + 0.3 * _noise(i + 5500)),
			(_noise(i + 6000) - 0.5) * span.z)
		stars.glow(p, 0.6 + 0.5 * _noise(i + 6500), Color(Color("#FFE7A8"), 0.4))
	for i in 40:
		var p := centre + Vector3((_noise(i + 7000) - 0.5) * span.x * 0.9, -6.0 + 18.0 * _noise(i + 7500),
			(_noise(i + 8000) - 0.5) * span.z * 0.9)
		var tint := Color("#E8DCFF") if i % 3 else Color("#BFF3F8")
		stars.glow(p, 0.9 + 1.2 * _noise(i + 8500), Color(tint, 0.9))
	parent.add_child(_layer(stars.mesh(), 0.75, 0.5, "Stars"))
	var haze := UniversePaint.new()
	for i in 26:
		var p := centre + Vector3((_noise(i + 9000) - 0.5) * span.x * 0.8, -reach * (0.12 + 0.18 * _noise(i + 9100)),
			(_noise(i + 9200) - 0.5) * span.z * 0.85)
		var tint := Color("#8A7AD8") if i % 3 else Color("#C86FB0")
		if i % 7 == 0:
			tint = Color("#3CC6D8")
		haze.glow(p, reach * (0.22 + 0.2 * _noise(i + 9300)), Color(tint, 0.14 + 0.08 * _noise(i + 9400)))
	parent.add_child(_layer(haze.mesh(), 0.08, 0.0, "Haze"))


static func _layer(mesh: ArrayMesh, twinkle: float, core: float, name: String) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	var m := ShaderMaterial.new()
	m.shader = _glow
	m.set_shader_parameter("twinkle", twinkle)
	m.set_shader_parameter("core", core)
	mi.material_override = m
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mi.name = name
	# A glow layer is spread over the sky: never culled for its box.
	mi.extra_cull_margin = 400.0
	return mi
