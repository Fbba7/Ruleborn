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
## The Echo form's ghosts trail by this much each (Featherkin_Rig.html: 0.3 s),
## and how strongly each is drawn (11.10: "faint ghost outlines that trail a
## step behind").
const ECHO_DELAY := 0.3
const ECHO_GHOSTS := [0.8, 0.45]
## The Hush form's ink: a deep violet, finer (11.10: "soft, silent edges").
const HUSH_INK := Color("#2E2457")
## Clips that play once and hold or hand back (`ko` holds, `hit` returns).
const ONCE := [&"hit", &"ko"]
const FORMS := [&"base", &"hush", &"spark", &"echo"]
const MANIFEST := "res://art/creatures/manifest.json"
## The guard form's rim (CreatureGear.SASH, lifted).
const GUARD_RIM := Color("#FF6F5E")
## Each kind's own form pattern (§21.6: forms change "pattern, glow and one
## accessory"; creature_look.gdshaderinc): [shape, cells over the body's
## height]. Shapes: 0 spots, 1 bands, 2 chevrons, 3 rings, 4 scales, 5 swirl,
## 6 zigzag. Read from each kind's look: a feather's chevrons, a shell's
## bands, a storm's zigzag, a clock's swirl. Kinds not listed take spots.
const FORM_PATTERN := {
	"featherkin": [2, 7.0], "skyskipper": [1, 6.0], "rambler": [0, 5.0], "glassgolem": [4, 6.0],
	"quarryback": [1, 9.0], "prismmite": [4, 10.0], "tidewalker": [3, 6.0], "hourkeeper": [5, 4.0],
	"stillwatch": [2, 10.0], "emberling": [6, 6.0], "stormhound": [6, 9.0], "sparkwright": [0, 9.0],
	"mossbear": [0, 4.0], "bloomling": [3, 8.0], "rootrunner": [1, 5.0], "echoplate": [4, 5.0],
	"lanternwisp": [5, 6.0], "soulmender": [3, 5.0],
}
## Corrections toward the design's portraits (art/design/stills/portraits),
## where the hero pages' sheen and glass carry a kind's paint further than
## the shared tone does: the tone (light paint toward white), and a tint on
## the paint. Judged side by side with each portrait.
const LOOK := {
	"featherkin": {"tone": 0.5, "tint": Vector3(1.0, 1.05, 0.62)},
	"glassgolem": {"tone": 0.45, "tint": Vector3(1.4, 1.22, 0.98)},
}
## The heights the ruleborn band (0.5–1.4 m) is drawn at in a heist.
const READABLE := Vector2(0.95, 1.4)

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
var _echoes: Array[CreatureModel] = []
# Where the body has been (time, transform), for the Echo ghosts to follow.
var _trail: Array = []
var _clock := 0.0
var _outline: ShaderMaterial
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
	for g: CreatureModel in _echoes:
		g.play(name_ok, speed)


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
	for g: CreatureModel in _echoes:
		g.set_expression(expression_name)


## §21.6's forms (11.10), each changing pattern, glow and one accessory in
## its note's colour: base; hush (midnight paint with star freckles, soft
## violet edges and a moonlit rim, a crescent charm); spark (lit from within,
## ember flecks and arcs crackling at the edges, embers rising, a star charm);
## echo (rings running up the body, faint ghost outlines a step behind where
## the body was, a ring charm).
func set_form(form_name: StringName) -> void:
	form = form_name if FORMS.has(form_name) else &"base"
	# The body and its fur shells alike. Midnight does not pale toward the day's sheen.
	_body_param("hush", 1.0 if form == &"hush" else 0.0)
	_body_param("lift", _lift * (0.25 if form == &"hush" else 1.0))
	_body_param("spark", 1.0 if form == &"spark" else 0.0)
	_body_param("echo_form", 1.0 if form == &"echo" else 0.0)
	if _glass != null:
		_glass.set_shader_parameter("hush", 1.0 if form == &"hush" else 0.0)
		_glass.set_shader_parameter("spark", 1.0 if form == &"spark" else 0.0)
	if _outline != null:
		_outline.set_shader_parameter("ink", HUSH_INK if form == &"hush" else CreatureGear.INK)
		_outline.set_shader_parameter("width_px", OUTLINE_PX * (0.7 if form == &"hush" else 1.0))
	for key: StringName in [&"hush", &"spark", &"echo"]:
		_drop_gear(key)
	if form != &"base":
		_gear[form] = CreatureGear.form_charm(self, form)
	if form == &"spark":
		_drop_gear(&"embers")
		_gear[&"embers"] = CreatureGear.embers(self)
	else:
		_drop_gear(&"embers")
	if form == &"echo" and _echoes.is_empty():
		_trail.clear()
		for i in ECHO_GHOSTS.size():
			var g := CreatureModel.make(kind)
			g.name = "echo" if i == 0 else "echo%d" % (i + 1)
			g._ghost(float(ECHO_GHOSTS[i]))
			add_child(g)
			g.top_level = true
			g.global_transform = global_transform if is_inside_tree() else transform
			g.play(clip)
			_echoes.append(g)
	elif form != &"echo" and not _echoes.is_empty():
		for g: CreatureModel in _echoes:
			g.queue_free()
		_echoes.clear()


## As a guard (§21.6: "ruleborn add a sash and a small lantern"): a sash across
## the chest and a lantern at the hand, on the kind's own bones.
func set_guard(on: bool) -> void:
	guard = on
	_drop_gear(&"guard")
	if on:
		_gear[&"guard"] = CreatureGear.guard_kit(self)
	# A guard's rim is the sash's warm red, so at the heist's size a guard
	# is told from the crew by its edge as well as its kit.
	_material.set_shader_parameter("rim_colour", GUARD_RIM if on else Color(str(info.get("rim", "#9FD4FF"))))


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


## The heist's readability scale (§21.6's heights, read at 40 px): the
## ruleborn band 0.5–1.4 m drawn as `READABLE` (0.95–1.4 m), so the smallest
## kinds grow most, the largest not at all, and the order of heights holds.
## Anything over the band keeps its true size. Hand it to `set_display_scale`
## or scale the node by it.
func readable_scale() -> float:
	var tall := maxf(0.1, height())
	var t := clampf((tall - 0.5) / 0.9, 0.0, 1.0)
	return maxf(1.0, lerpf(READABLE.x, READABLE.y, t) / tall)


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
	_lift = (0.2 + 0.2 * float(surface.get("gloss", 0.0))) * (1.0 - metal)
	_material.set_shader_parameter("lift", _lift)
	_material.set_shader_parameter("rim_colour", Color(str(info.get("rim", "#9FD4FF"))))
	_material.set_shader_parameter("glow_vc", float(info.get("glow", 0.0)))
	_material.set_shader_parameter("unit_height", height() / maxf(0.0001, float(info.get("scale", 1.0))))
	var look: Dictionary = LOOK.get(String(kind), {})
	if look.has("tone"):
		_material.set_shader_parameter("tone", float(look["tone"]))
	if look.has("tint"):
		_material.set_shader_parameter("paint_tint", look["tint"])
	var pattern: Array = FORM_PATTERN.get(String(kind), [0, 6.0])
	_material.set_shader_parameter("form_pattern", float(pattern[0]))
	_material.set_shader_parameter("form_scale", float(pattern[1]))
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
		# The body's own sheen: the shader's default lift pales fleece to pink-white.
		m.set_shader_parameter("lift", _lift)
		for p: StringName in [&"form_pattern", &"form_scale", &"unit_height", &"hush", &"spark", &"echo_form", &"tone",
				&"paint_tint"]:
			m.set_shader_parameter(p, _material.get_shader_parameter(p))
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
		_outline = o
	else:
		last.next_pass = null


# A uniform on the body's material and every fur shell after it.
func _body_param(param: StringName, value: Variant) -> void:
	var m: Material = _material
	while m != null and m != _outline:
		(m as ShaderMaterial).set_shader_parameter(param, value)
		m = m.next_pass


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


# An Echo ghost: every surface in the glass material's echo colour, drawn
# mostly at its edges, at `strength` of full.
func _ghost(strength: float) -> void:
	var g := ShaderMaterial.new()
	g.shader = _glass_shader
	g.set_shader_parameter("atlas", _material.get_shader_parameter("atlas"))
	g.set_shader_parameter("echo", strength)
	g.set_shader_parameter("unit_height", _material.get_shader_parameter("unit_height"))
	for i in _mesh.mesh.get_surface_count():
		_mesh.set_surface_override_material(i, g)
	_material = g
	_outline = null
	for c in get_children():
		if c is MeshInstance3D and c != _model:
			c.queue_free()
	_player.speed_scale = 1.0


func _process(delta: float) -> void:
	if _echoes.is_empty():
		return
	# Remember where the body has been; each ghost stands where it stood a
	# step ago, on the same clip that much earlier.
	_clock += delta
	_trail.append([_clock, global_transform])
	var keep := ECHO_DELAY * float(ECHO_GHOSTS.size()) + 0.1
	while _trail.size() > 2 and float(_trail[1][0]) < _clock - keep:
		_trail.pop_front()
	var a := _player.current_animation
	for i in _echoes.size():
		var g := _echoes[i]
		var lag := ECHO_DELAY * float(i + 1)
		var then := _trail_at(_clock - lag)
		# Standing still, a ghost still shows: a little behind and aside.
		var back := global_transform.basis * (Vector3(0.1, 0.0, 0.16) * float(i + 1) * height())
		var still := clampf(1.0 - then.origin.distance_to(global_position) / maxf(0.05, 0.2 * height()), 0.0, 1.0)
		g.global_transform = Transform3D(then.basis, then.origin + back * still)
		if a == "":
			continue
		if g._player.current_animation != a:
			g._player.play(a, 0.0)
		var length := _player.get_animation(a).length
		var t := _player.current_animation_position - lag
		if t < 0.0:
			t = fposmod(t, length) if _player.get_animation(a).loop_mode != Animation.LOOP_NONE else 0.0
		g._player.seek(t, true)


func _trail_at(time: float) -> Transform3D:
	var best: Transform3D = global_transform
	for e: Array in _trail:
		if float(e[0]) <= time:
			best = e[1]
		else:
			break
	return best
