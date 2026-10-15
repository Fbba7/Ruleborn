class_name FirstRepository
extends RefCounted
## What the first launch asks the server (TD.26): §20.2's protections and the
## name word lists, both before any account exists (§25.2), and the Keeper's
## name once one does (G58).

var api: Api


func _init(a: Api) -> void:
	api = a


func protections() -> Result:
	return await api.public_json("/v1/protections")


func words() -> Result:
	return await api.public_json("/v1/words")


## The name kept on the phone, as word-list indexes.
func send_name(name: Dictionary) -> Result:
	return await api.json(HTTPClient.METHOD_PUT, "/v1/keeper/name", name)
