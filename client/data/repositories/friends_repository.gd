class_name FriendsRepository
extends RefCounted
## Friends, their week's feed and challenge links (§12.11, §17.6;
## server/src/friends.mjs).

var api: Api


func _init(a: Api) -> void:
	api = a


func friends() -> Result:
	return await api.get_json("/v1/friends")


## An invite to share; a friend accepts it by its code.
func invite() -> Result:
	return await api.post_json("/v1/friends/invites")


func accept(code: String) -> Result:
	return await api.post_json("/v1/friends/accept", {"invite": code})


func remove(account: String) -> Result:
	return await api.json(HTTPClient.METHOD_DELETE, "/v1/friends/" + account.uri_encode())


## §17.6: what the player's friends did in the last week.
func feed() -> Result:
	return await api.get_json("/v1/friends/feed")


## A challenge link to the player's own island in `realm`.
func challenge(realm := "heart") -> Result:
	return await api.post_json("/v1/challenges", {"realm": realm})


func open_challenge(code: String) -> Result:
	return await api.get_json("/v1/challenges/" + code.uri_encode())
