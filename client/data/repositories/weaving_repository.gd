class_name WeavingRepository
extends RefCounted
## What is woven (§5.1, §5.5, §5.6; server/src/weaving.mjs): each realm's
## slots and the crown's, what every restored law would come to woven in
## each, priced by the simulation's one function (TD.14), the laws
## recommended for each, and the universe's stability.

var api: Api


func _init(a: Api) -> void:
	api = a


func view() -> Result:
	return await api.get_json("/v1/weaving")


## §5.6: a restored law woven into slot `slot` of `realm` ("crown" for the
## crown's). A retry of one already woven there is answered as woven.
func weave(realm: String, slot: int, law: String) -> Result:
	return await api.post_json("/v1/weaving", {"realm": realm, "slot": slot, "law": law})


## §5.6: the law in slot `slot` of `realm` taken out; the slot rests an hour.
func unweave(realm: String, slot: int) -> Result:
	return await api.json(HTTPClient.METHOD_DELETE, "/v1/weaving/%s/%d" % [realm.uri_encode(), slot])
