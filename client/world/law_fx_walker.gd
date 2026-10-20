class_name LawFxWalker
extends Node3D
## A law's movement signature played on a figure (§21.7: "a looping
## four-second preview of its movement signature" on the law card): the
## numbers of `LawFx.gait` turned into a walk. `pose` is the whole of it and
## static, so a character controller (T1's CreatureModel) can call it on its
## own body node with its own clock: it bobs, squashes, leans, sways, glides
## or hangs in the air as the gait says, never moving the figure off the
## spot the simulation gives it.

## The walk's steps a second at tempo 1 (WorldView's walk, 2.2).
const STEPS := 2.2
## How long the preview's loop takes, in seconds.
const LOOP := 4.0

var gait := LawFxGait.of("")
var law := ""
var body: MeshInstance3D
## T1's character walking the loop instead of the stand-in body, moved by
## LawFxCreature; null where no character is exported.
var figure: CreatureModel
## The loop it walks, round `centre`, in metres.
var reach := 1.4
var centre := Vector3.ZERO
var _shadow: MeshInstance3D


func _init(law_id := "", mesh: ArrayMesh = null, mat: Material = null) -> void:
	gait = LawFxGait.of(law_id)
	law = law_id
	body = MeshInstance3D.new()
	body.mesh = mesh
	body.material_override = mat
	add_child(body)
	# A soft shadow that stays on the ground, so a hop or a float reads.
	var g := Geo.new()
	g.ring(Geo.place(Vector3(0, 0.02, 0)), 0.0, 0.3, Palette.INK, 16)
	_shadow = MeshInstance3D.new()
	_shadow.mesh = g.mesh()
	var m := ShaderMaterial.new()
	m.shader = load("res://world/toon_clear.gdshader")
	m.set_shader_parameter("opacity", 0.3)
	_shadow.material_override = m
	_shadow.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(_shadow)


## Where the preview's figure is `t` seconds in: round a soft square, pausing
## at one corner (for Stillness's statue pose and a dart's wait).
func walk(t: float) -> void:
	var u := fmod(t, LOOP) / LOOP
	var moving := u < 0.8
	var a := clampf(u / 0.8, 0.0, 1.0) * TAU
	position = centre + Vector3(cos(a) * reach, position.y - centre.y, sin(a) * reach * 0.6)
	rotation.y = atan2(sin(a), -cos(a) * 0.6) if moving else rotation.y
	var lift := 0.0
	if figure != null:
		LawFxCreature.apply(figure, [] if law == "" else [law], t, moving)
		if not moving and figure.clip != &"idle":
			figure.play(&"idle")
		var fbody := LawFxCreature.body_of(figure)
		lift = fbody.position.y if fbody != null else 0.0
	else:
		pose(body, gait, t, moving)
		lift = body.position.y
	var k := clampf(1.0 - lift * 1.5, 0.45, 1.0)
	_shadow.scale = Vector3(k, 1.0, k)


## Walk T1's character of `kind` instead of the stand-in body.
func use_figure(kind: StringName) -> void:
	var c := CreatureModel.make(kind)
	if c == null:
		return
	figure = c
	body.visible = false
	add_child(c)


## A figure's body posed by `g` at `t` seconds, walking or standing.
static func pose(node: Node3D, g: Dictionary, t: float, moving: bool) -> void:
	var o := offsets(g, t, moving)
	node.position = Vector3(0, float(o["lift"]), 0)
	node.scale = o["scale"]
	node.rotation = Vector3(-float(o["lean"]), 0.0, float(o["sway"]))


## What a gait does to a body at `t` seconds, walking or standing, as numbers
## to add to its rest pose: "lift" (metres up), "scale" (squash and crouch),
## "lean" (radians forward), "sway" (radians sideways) and "rate" (its walk
## clip's speed, times the clip's own).
static func offsets(g: Dictionary, t: float, moving: bool) -> Dictionary:
	var tempo := float(g["tempo"]) / maxf(0.3, float(g["stride"]))
	var phase := t * STEPS * tempo
	var step := absf(sin(phase * PI))
	var lift := float(g["bounce"])
	var hang := float(g["float"])
	var skate := float(g["skate"])
	if str(g["rhythm"]) == "step-step-hop" and int(phase) % 3 == 2:
		lift *= 3.0
	if not moving:
		lift = 0.0
		step = 0.0
	# A floaty hop hangs at the top: the curve flattens as `float` grows.
	var y := lift * pow(step, 1.0 - hang * 0.7) * (1.0 - skate) + hang * 0.06
	var squash := float(g["squash"]) * (1.0 - step) * (1.0 - skate) if moving else 0.0
	var crouch := float(g["crouch"]) * 0.25 + float(g["tiptoe"]) * -0.04
	var lean := float(g["lean"]) + skate * 0.1 * sin(t * 1.3)
	var sway := float(g["sway"]) * sin(phase * PI * 0.5) + skate * 0.12 * sin(t * 2.0)
	if float(g["shimmer"]) > 0.5 and not moving:
		sway = 0.0
	return {"lift": y, "scale": Vector3(1.0 + squash * 0.6, 1.0 - squash - crouch, 1.0 + squash * 0.6),
		"lean": lean if moving else 0.0, "sway": sway, "rate": float(g["tempo"]) * (1.0 - skate * 0.7)}
