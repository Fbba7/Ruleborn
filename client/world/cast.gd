class_name Cast
extends RefCounted
## Who stands in the realm: each actor's character model (§21.6), handed to
## `WorldView.figure_maker`. A heist's crew are named by role only until
## crews carry their members' kinds, so each role has one kind of its school
## spread, and a guard is a Warden in the guard form (§21.6: "ruleborn add a
## sash and a small lantern").

## A role's kind, one per role (§21.6's table: each role's first kind).
const KIND := {"Scout": &"featherkin", "Breaker": &"rambler", "Carrier": &"skyskipper", "Warden": &"mossbear",
	"Mender": &"hourkeeper", "guard": &"glassgolem"}


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
