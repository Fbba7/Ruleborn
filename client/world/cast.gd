class_name Cast
extends RefCounted
## Who stands in the realm: each actor's character model (§21.6), handed to
## `WorldView.figure_maker`. A heist's crew are named by role only until
## crews carry their members' kinds, so each role has one kind of its school
## spread, and a guard is a Warden in the guard form (§21.6: "ruleborn add a
## sash and a small lantern").

## A role's kind, one per role, from §21.6's table: 02-heist.png's own crew
## where it shows one (Skyskipper, Mossbear, Emberling), and a kind of
## another school for the rest, so no two of a crew share a colour and each
## reads apart on the grass at a glance. The Mender is Bloomling, one surface
## to Hourkeeper's two, so the eleven figures of a long crew's result keep
## §21.3's draw calls (149).
const KIND := {"Scout": &"lanternwisp", "Breaker": &"emberling", "Carrier": &"skyskipper", "Warden": &"mossbear",
	"Mender": &"bloomling", "guard": &"glassgolem"}


## The model for an actor of `role` ("guard" for a guard), or null to draw
## the stand-in figure (an unknown role, or a build without the models).
static func figure(role: String, _height: float) -> Node3D:
	var kind: StringName = KIND.get(role, &"")
	if kind == &"" or not CreatureModel.manifest().has(String(kind)):
		return null
	var model := CreatureModel.make(kind)
	if model != null and role == "guard":
		model.set_guard(true)
	return model
