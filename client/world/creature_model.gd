class_name CreatureModel
extends Node3D
## One character as the design sculpted it (§21.6, §21.9): the kind's model
## exported from `art/design/creatures/` by `tools/art/export.mjs`, with its
## skeleton, the design's clips by their names, its expressions, sockets, and
## its forms, in §21.3's toon look.
##
## Three calls put one in a scene:
##     var c := CreatureModel.make(&"featherkin")
##     c.place(Vector3(2.5, 0, 4.5), Vector3.FORWARD)
##     c.play(&"walk")
## Forward is −Z and one unit is one metre; the model stands on y = 0 at the
## height §21.6 gives it.

## §21.3 asks for character outlines; the design's handoff says the owner had
## them removed. One switch, on by default (docs/art/tracks/t1-characters.md).
const OUTLINE := true
const OUTLINE_PX := 1.5
## The design's cross-fade between clips (creature-kit.js `play`: 280 ms).
const BLEND := 0.28
## The Echo twin trails by this much (Featherkin_Rig.html: 0.3 s).
const ECHO_DELAY := 0.3
## Clips that play once and hold or hand back (`ko` holds, `hit` returns).
const ONCE := [&"hit", &"ko"]
const FORMS := [&"base", &"hush", &"spark", &"echo"]
const MANIFEST := "res://art/creatures/manifest.json"

static var _manifest: Dictionary = {}
static var _shader: Shader = load("res://world/creature.gdshader")
static var _glass_shader: Shader = load("res://world/creature_glass.gdshader")
static var _outline_shader: Shader = load("res://world/creature_outline.gdshader")
static var _fur_shader: Shader = load("res://world/creature_fur.gdshader")

## The kind (a key of the manifest), its manifest entry, and its state.
var kind: StringName = &""
var info: Dictionary = {}
var form: StringName = &"base"
var guard := false
var clip: StringName = &""
var expression: StringName = &""

var _model: Node3D
var _skeleton: Skeleton3D
var _mesh: MeshInstance3D
var _player: AnimationPlayer
var _material: ShaderMaterial
var _glass: ShaderMaterial
var _sockets: Dictionary = {}
var _loop_clip: StringName = &"idle"
var _echo: CreatureModel
var _gear: Dictionary = {}
var _fur := 0
var _lift := 0.5


## A new model of `kind_name`, playing its idle; null for an unknown kind.
static func make(kind_name: StringName, fur_shells := 0) -> CreatureModel:
	var entry: Dictionary = manifest().get(String(kind_name), {})
	if entry.is_empty():
		push_warning("CreatureModel: no kind %s" % kind_name)
		return null
	var c := CreatureModel.new()
	c.name = String(kind_name)
	c._build(kind_name, entry, fur_shells)
	return c


## The export's manifest: every kind with its triangles, clips, sockets, scale.
static func manifest() -> Dictionary:
	if _manifest.is_empty():
		# Loaded as Godot's JSON resource, so an exported pack carries it.
		var res := load(MANIFEST) as JSON
		if res != null and res.data is Dictionary:
			_manifest = (res.data as Dictionary).get("kinds", {})
	return _manifest


## Every exported kind, in §21.9's order (ruleborn, Sages, visitors, ...).
static func kinds(group := "") -> PackedStringArray:
	var out := PackedStringArray()
	for k: String in manifest():
		if group == "" or str((manifest()[k] as Dictionary).get("group", "")) == group:
			out.append(k)
	return out


## Stand at `at` (metres, on the ground) facing `facing` (any horizontal direction).
func place(at: Vector3, facing := Vector3.FORWARD) -> void:
	position = at
	face(facing)


## Turn to face a horizontal direction; the model's front is −Z.
func face(direction: Vector3) -> void:
	var d := Vector3(direction.x, 0.0, direction.z)
	if d.length_squared() < 0.000001:
		return
	rotation.y = atan2(-d.x, -d.z)


## Play one of the design's clips: idle, idle2, walk, run, carry, climb, leap,
## slide, wade, hit, ko, celebrate, nap, work, ability (and any the kind adds).
## `speed` scales it (a walk matched to the ground speed). An unknown clip
## falls back to idle.
func play(clip_name: StringName, speed := 1.0) -> void:
	var name_ok := clip_name if _player.has_animation(clip_name) else &"idle"
	clip = name_ok
	expression = &""
	if not ONCE.has(name_ok):
		_loop_clip = name_ok
	_player.play(name_ok, BLEND, speed)
	if _echo != null:
		_echo.play(name_ok, speed)


## Hold one of the design's expressions (curious, focus, startled, caught) over
## a breathing stand; an empty name goes back to the last clip.
func set_expression(expression_name: StringName) -> void:
	var anim := StringName("expr_" + String(expression_name))
	if expression_name == &"" or not _player.has_animation(anim):
		expression = &""
		play(_loop_clip)
		return
	expression = expression_name
	_player.play(anim, BLEND)
	if _echo != null:
		_echo.set_expression(expression_name)


## §21.6's forms: base, hush (midnight, with a crescent charm), spark (lit from
## within, embers at the design's ember sockets) or echo (a translucent twin a
## moment behind).
func set_form(form_name: StringName) -> void:
	form = form_name if FORMS.has(form_name) else &"base"
	_material.set_shader_parameter("hush", 1.0 if form == &"hush" else 0.0)
	# Midnight does not pale toward the day's sheen.
	_material.set_shader_parameter("lift", _lift * (0.25 if form == &"hush" else 1.0))
	_material.set_shader_parameter("spark", 1.0 if form == &"spark" else 0.0)
	if _glass != null:
		_glass.set_shader_parameter("hush", 1.0 if form == &"hush" else 0.0)
		_glass.set_shader_parameter("spark", 1.0 if form == &"spark" else 0.0)
	_drop_gear(&"hush")
	_drop_gear(&"spark")
	if form == &"hush":
		_gear[&"hush"] = CreatureGear.hush_charm(self)
	elif form == &"spark":
		_gear[&"spark"] = CreatureGear.embers(self)
	if form == &"echo" and _echo == null:
		_echo = CreatureModel.make(kind)
		_echo.name = "echo"
		_echo._ghost()
		add_child(_echo)
		_echo.position = Vector3(0.12, 0.0, 0.18) * height()
		_echo.play(clip)
	elif form != &"echo" and _echo != null:
		_echo.queue_free()
		_echo = null


## As a guard (§21.6: "ruleborn add a sash and a small lantern"): a sash across
## the chest and a lantern at the hand, on the kind's own bones.
func set_guard(on: bool) -> void:
	guard = on
	_drop_gear(&"guard")
	if on:
		_gear[&"guard"] = CreatureGear.guard_kit(self)


## A socket by name (a node that follows its bone): the design's glow points
## (`socket_<n>`), ember points (`ember_<n>`), and the standard ones every kind
## has: `head_top`, `hand_R`, `hand_L`, `chest`, `back`, `feet`.
func socket(socket_name: StringName) -> Node3D:
	return _sockets.get(socket_name, null)


## Height in metres as drawn (§21.6's table, from the manifest).
func height() -> float:
	return float(info.get("height", 1.0))


## The kind's clip names.
func clip_names() -> PackedStringArray:
	var out := PackedStringArray()
	for a: StringName in _player.get_animation_list():
		if not String(a).begins_with("expr_"):
			out.append(String(a))
	return out


## Fur shells over the body: the manifest's count is the design's; the phone's
## world keeps 0 and the Character screen asks for more.
func set_fur(shells: int) -> void:
	_fur = clampi(shells, 0, int((info.get("fur", {}) as Dictionary).get("shells", 0)))
	_chain_passes()


## A light readability scale on top of §21.6's height (1 is true size): the
## heist's camera shows a character 30–60 px tall, and a caller there may draw
## it a little larger without changing what the simulation measures.
func set_display_scale(factor: float) -> void:
	_model.scale = Vector3.ONE * float(info.get("scale", 1.0)) * clampf(factor, 0.5, 2.0)


## The animation player, for callers that sync or seek clips.
func player() -> AnimationPlayer:
	return _player


## The skeleton, for attachments a caller adds itself.
func skeleton() -> Skeleton3D:
	return _skeleton


## The body's material (forms, flashes and tints are its parameters).
func material() -> ShaderMaterial:
	return _material


func _build(kind_name: StringName, entry: Dictionary, fur_shells: int) -> void:
	kind = kind_name
	info = entry
	var scene := load("res://art/creatures/" + str(entry["file"])) as PackedScene
	_model = scene.instantiate() as Node3D
	# The export faces +Z (glTF's front); this node's front is −Z.
	_model.rotation.y = PI
	_model.scale = Vector3.ONE * float(entry.get("scale", 1.0))
	add_child(_model)
	_skeleton = _model.find_children("*", "Skeleton3D", true, false)[0] as Skeleton3D
	_mesh = _skeleton.find_children("*", "MeshInstance3D", true, false)[0] as MeshInstance3D
	_player = _model.find_children("*", "AnimationPlayer", true, false)[0] as AnimationPlayer
	_mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_materials()
	_set_loops()
	_make_sockets()
	_player.animation_finished.connect(_on_finished)
	_fur = clampi(fur_shells, 0, int((entry.get("fur", {}) as Dictionary).get("shells", 0)))
	_chain_passes()
	add_child(CreatureGear.blob(self))
	play(&"idle")


func _materials() -> void:
	var mesh := _mesh.mesh
	var atlas: Texture2D = null
	var normals: Texture2D = null
	for i in mesh.get_surface_count():
		var src := mesh.surface_get_material(i) as BaseMaterial3D
		if src != null and src.albedo_texture != null:
			atlas = src.albedo_texture
			normals = src.normal_texture
	_material = ShaderMaterial.new()
	_material.shader = _shader
	_material.set_shader_parameter("atlas", atlas)
	_material.set_shader_parameter("normals", normals)
	_material.set_shader_parameter("relief", float(info.get("relief", 1.0)))
	var surface: Dictionary = info.get("surface", {})
	var metal := float(surface.get("metal", 0.0))
	_material.set_shader_parameter("body_metal", metal)
	_material.set_shader_parameter("body_gloss", clampf(float(surface.get("gloss", 0.0)) * 0.8, 0.0, 1.0))
	_material.set_shader_parameter("body_iris", float(surface.get("iris", 0.0)))
	var emit: Array = surface.get("emit", [0.0, 0.0, 0.0])
	_material.set_shader_parameter("body_emit", Vector3(float(emit[0]), float(emit[1]), float(emit[2])))
	# Metal keeps its greys; only paint pales toward the design's sheen.
	_lift = (0.5 + 0.25 * float(surface.get("gloss", 0.0))) * (1.0 - metal)
	_material.set_shader_parameter("lift", _lift)
	_material.set_shader_parameter("rim_colour", Color(str(info.get("rim", "#9FD4FF"))))
	_material.set_shader_parameter("glow_vc", float(info.get("glow", 0.0)))
	for i in mesh.get_surface_count():
		var src := mesh.surface_get_material(i)
		if src != null and src.resource_name == "creature_glass":
			_glass = ShaderMaterial.new()
			_glass.shader = _glass_shader
			_glass.set_shader_parameter("atlas", atlas)
			_glass.set_shader_parameter("rim_colour", Color(str(info.get("rim", "#9FD4FF"))))
			_mesh.set_surface_override_material(i, _glass)
		else:
			_mesh.set_surface_override_material(i, _material)


# The body's extra passes: fur shells (each one more draw), then the ink outline.
func _chain_passes() -> void:
	var last: Material = _material
	var fur: Dictionary = info.get("fur", {})
	var cells := 512.0 * 900.0 / maxf(1.0, float(info.get("texels_per_unit", 300.0)))
	for s in _fur:
		var m := ShaderMaterial.new()
		m.shader = _fur_shader
		m.set_shader_parameter("atlas", _material.get_shader_parameter("atlas"))
		m.set_shader_parameter("rim_colour", _material.get_shader_parameter("rim_colour"))
		m.set_shader_parameter("layer", float(s + 1) / float(_fur + 1))
		m.set_shader_parameter("fur_len", float(fur.get("len", 0.0045)) * 2.2)
		m.set_shader_parameter("strand_cells", cells)
		last.next_pass = m
		last = m
	if OUTLINE:
		var o := ShaderMaterial.new()
		o.shader = _outline_shader
		o.set_shader_parameter("width_px", OUTLINE_PX)
		last.next_pass = o
	else:
		last.next_pass = null


func _set_loops() -> void:
	for a: StringName in _player.get_animation_list():
		var anim := _player.get_animation(a)
		anim.loop_mode = Animation.LOOP_NONE if ONCE.has(a) else Animation.LOOP_LINEAR


func _make_sockets() -> void:
	for s: Dictionary in info.get("sockets", []):
		var bone := str(s.get("bone", ""))
		var idx := _skeleton.find_bone(bone)
		if idx < 0:
			continue
		var att := BoneAttachment3D.new()
		att.name = "socket_" + str(s.get("name", bone))
		att.bone_name = bone
		_skeleton.add_child(att)
		var mark := Marker3D.new()
		mark.name = str(s.get("name", bone))
		var off: Array = s.get("offset", [0.0, 0.0, 0.0])
		mark.position = Vector3(float(off[0]), float(off[1]), float(off[2]))
		att.add_child(mark)
		_sockets[StringName(str(s.get("name", bone)))] = mark


func _on_finished(anim: StringName) -> void:
	if anim == &"hit":
		play(_loop_clip)


func _drop_gear(key: StringName) -> void:
	if _gear.has(key):
		var holder := _gear[key] as Node
		for part: Node in holder.get_meta("parts", []):
			if is_instance_valid(part):
				part.queue_free()
		holder.queue_free()
		_gear.erase(key)


# The Echo twin: every surface in the glass material's echo colour.
func _ghost() -> void:
	var g := ShaderMaterial.new()
	g.shader = _glass_shader
	g.set_shader_parameter("atlas", _material.get_shader_parameter("atlas"))
	g.set_shader_parameter("echo", 1.0)
	for i in _mesh.mesh.get_surface_count():
		_mesh.set_surface_override_material(i, g)
	_material = g
	for c in get_children():
		if c is MeshInstance3D and c != _model:
			c.queue_free()
	_player.speed_scale = 1.0
	set_process(true)


func _process(_delta: float) -> void:
	if _echo == null:
		return
	# Keep the twin a fixed moment behind on the same clip.
	var a := _player.current_animation
	if a == "":
		return
	if _echo._player.current_animation != a:
		_echo._player.play(a, 0.0)
	var length := _player.get_animation(a).length
	var t := _player.current_animation_position - ECHO_DELAY
	if t < 0.0:
		t = fposmod(t, length) if _player.get_animation(a).loop_mode != Animation.LOOP_NONE else 0.0
	_echo._player.seek(t, true)
