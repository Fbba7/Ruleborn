class_name ProfileRepository
extends RefCounted
## The Profile (§23.2; server/src/profile.mjs): the player's record, and its
## visibility switch, which §20.2 keeps off for 13 to 15.

var api: Api


func _init(a: Api) -> void:
	api = a


func view() -> Result:
	return await api.get_json("/v1/profile")


## The profile shown to others, or hidden. Answers the profile.
func share(on: bool) -> Result:
	return await api.json(HTTPClient.METHOD_PUT, "/v1/profile", {"public": on})
