class_name SocialRepository
extends RefCounted
## Leagues, constellations and crews (§12.9, §17, §18.1; server/src/social.mjs,
## seasons.mjs). Friends are FriendsRepository's.

var api: Api


func _init(a: Api) -> void:
	api = a


# -- the league (§18.1) ---------------------------------------------------------

func league() -> Result:
	return await api.get_json("/v1/league")


## A closed season's result for the player; `null` in the answer if they
## played none of it.
func result(season: int) -> Result:
	return await api.get_json("/v1/seasons/%d/result" % season)


## §17.5's constellation league for a closed season.
func constellation_table(season: int) -> Result:
	return await api.get_json("/v1/seasons/%d/constellations" % season)


# -- constellations (§17.1) ------------------------------------------------------

## The player's constellation, `{"constellation": null}` for none.
func my_constellation() -> Result:
	return await api.get_json("/v1/constellations/mine")


func constellation(id: String) -> Result:
	return await api.get_json("/v1/constellations/" + id.uri_encode())


## Named from the Workshop's word lists, by index (D63).
func found(adjective: int, noun: int) -> Result:
	return await api.post_json("/v1/constellations", {"adjective": adjective, "noun": noun})


func join(id: String) -> Result:
	return await api.post_json("/v1/constellations/%s/join" % id.uri_encode())


func leave() -> Result:
	return await api.post_json("/v1/constellations/leave")


## The founder names an elder, or makes one a member again.
func appoint(id: String, account: String, role: String) -> Result:
	return await api.post_json("/v1/constellations/%s/roles" % id.uri_encode(), {"account": account, "role": role})


## The name word lists, as the Workshop's (GET /v1/workshop/words).
func words() -> Result:
	return await api.get_json("/v1/workshop/words")


# -- crews (§17.7) ----------------------------------------------------------------

## The player's crew, `{"crew": null}` for none.
func my_crew() -> Result:
	return await api.get_json("/v1/crews/mine")


func start_crew() -> Result:
	return await api.post_json("/v1/crews")


func join_crew(code: String) -> Result:
	return await api.post_json("/v1/crews/join", {"invite": code})


func leave_crew() -> Result:
	return await api.post_json("/v1/crews/leave")
