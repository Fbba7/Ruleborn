class_name LawFxCreature
extends RefCounted
## §21.7's movement signatures on T1's characters: the laws woven where a
## `CreatureModel` stands change how it moves — the clip it walks with and
## that clip's speed, a bounce, a lean, a sway, a crouch, a float — from
## `LawFx.gait` (LawFxGait's numbers, blended for several laws), the same
## numbers the law card's preview walks by (LawFxWalker).
##
## A character controller calls it once a frame, after placing the model:
##     LawFxCreature.apply(model, ["half_gravity", "haste"], seconds, moving)
## It never moves the model off the spot the simulation gives it: the
## offsets go on the model's own body inside it (the export's scene node),
## so `place` and `face` stay the caller's. `rest` puts the body back.

## The clips the design names (creature-kit.js), by what a gait asks for.
const SKATE_CLIP := &"slide"
const HOP_CLIP := &"leap"


## Pose `c` by the laws in `laws` at `seconds` (the heist's, so a replay moves
## the same), walking or standing; the gait's numbers, as applied.
static func apply(c: CreatureModel, laws: Array, seconds: float, moving: bool) -> Dictionary:
	var g := LawFxGait.blend(laws)
	var body := body_of(c)
	if body == null:
		return g
	if not body.has_meta("rest_scale"):
		body.set_meta("rest_scale", body.scale)
		body.set_meta("rest_position", body.position)
	var o := LawFxWalker.offsets(g, seconds, moving)
	var rest_scale: Vector3 = body.get_meta("rest_scale")
	var rest_position: Vector3 = body.get_meta("rest_position")
	# The gait's lifts are for a 1 m character; a 0.6 m one hops 0.6 as high.
	body.position = rest_position + Vector3(0, float(o["lift"]) * clampf(c.height(), 0.3, 1.6), 0)
	body.scale = rest_scale * (o["scale"] as Vector3)
	# The body is turned half round inside the model (the export faces +Z),
	# so its lean is the other way about its own x.
	body.rotation = Vector3(float(o["lean"]), body.rotation.y, -float(o["sway"]))
	if moving:
		var want := clip_for(g, c)
		if c.clip != want:
			c.play(want, float(o["rate"]))
		elif c.player() != null:
			c.player().speed_scale = float(o["rate"])
	g["applied"] = o
	return g


## The clip a gait walks with on `c`: a slide for a skate, a leap for a floaty
## hop, else the walk; whichever of them the kind has.
static func clip_for(g: Dictionary, c: CreatureModel) -> StringName:
	var names := c.clip_names()
	if float(g["skate"]) > 0.5 and names.has(String(SKATE_CLIP)):
		return SKATE_CLIP
	if float(g["float"]) > 0.5 and names.has(String(HOP_CLIP)):
		return HOP_CLIP
	return &"walk"


## Back to the body's rest pose (a law broken, the character out of its realm).
static func rest(c: CreatureModel) -> void:
	var body := body_of(c)
	if body == null or not body.has_meta("rest_scale"):
		return
	body.position = body.get_meta("rest_position")
	body.scale = body.get_meta("rest_scale")
	body.rotation = Vector3(0, body.rotation.y, 0)
	if c.player() != null:
		c.player().speed_scale = 1.0


## The model's body: its child that holds the skeleton (the exported scene).
static func body_of(c: CreatureModel) -> Node3D:
	var sk := c.skeleton()
	if sk == null:
		return null
	var n: Node = sk
	while n != null and n.get_parent() != c:
		n = n.get_parent()
	return n as Node3D
