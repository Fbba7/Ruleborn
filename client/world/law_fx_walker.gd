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
var body: MeshInstance3D
## The loop it walks, round the origin, in metres.
var reach := 1.4
var _shadow: MeshInstance3D


func _init(law := "", mesh: ArrayMesh = null, mat: Material = null) -> void:
	gait = LawFxGait.of(law)
	body = MeshInstance3D.new()
	body.mesh = mesh
	body.material_override = mat
	add_child(body)


## Where the preview's figure is `t` seconds in: round a soft square, pausing
## at one corner (for Stillness's statue pose and a dart's wait).
func walk(t: float) -> void:
	var u := fmod(t, LOOP) / LOOP
	var moving := u < 0.8
	var a := clampf(u / 0.8, 0.0, 1.0) * TAU
	position = Vector3(cos(a) * reach, position.y, sin(a) * reach * 0.6)
	rotation.y = atan2(sin(a), -cos(a) * 0.6) if moving else rotation.y
	pose(body, gait, t, moving)


## A figure's body posed by `g` at `t` seconds, walking or standing.
static func pose(node: Node3D, g: Dictionary, t: float, moving: bool) -> void:
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
	node.position = Vector3(0, y, 0)
	node.scale = Vector3(1.0 + squash * 0.6, 1.0 - squash - crouch, 1.0 + squash * 0.6)
	var lean := float(g["lean"]) + skate * 0.1 * sin(t * 1.3)
	var sway := float(g["sway"]) * sin(phase * PI * 0.5) + skate * 0.12 * sin(t * 2.0)
	if float(g["shimmer"]) > 0.5 and not moving:
		sway = 0.0
	node.rotation = Vector3(-lean if moving else 0.0, 0.0, sway)
