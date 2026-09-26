class_name TrackRepository
extends RefCounted
## The season track (§18.2, §18.8; server/src/track.mjs): a season's track as
## the player sees it, and the next tier claimed.

var api: Api


func _init(a: Api) -> void:
	api = a


## A season's track: stars in hand, the tier price, how far it is claimed and
## every tier's rewards. `season` 0 is the current one.
func view(season := 0) -> Result:
	return await api.get_json("/v1/track" + ("?season=%d" % season if season > 0 else ""))


## §18.8: the next tier, this season's or an earlier one's, paid in this
## season's stars.
func claim(season: int) -> Result:
	return await api.post_json("/v1/track/claim", {"season": season})
