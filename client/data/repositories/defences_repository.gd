class_name DefencesRepository
extends RefCounted
## The defence log (§13.2, §23.2; server/src/defences.mjs): the raids on the
## player this season, each with its report, and the raid badge.

var api: Api


func _init(a: Api) -> void:
	api = a


## The log, read: its raids are no longer new.
func view() -> Result:
	return await api.get_json("/v1/defences")


## How many raids are new since the log was last read.
func badge() -> Result:
	return await api.get_json("/v1/defences/badge")
