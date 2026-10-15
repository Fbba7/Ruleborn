class_name CurationRepository
extends RefCounted
## §13.3's curation (server/src/curation.mjs): a realm's island, its origin
## and name, the generator's layouts and what a swap of each woven law
## costs; a layout laid, a swap woven (G54), the curated island published
## and named.

var api: Api


func _init(a: Api) -> void:
	api = a


## The curation view of `realm`, its layouts from page `page`.
func view(realm: String, page := 0) -> Result:
	return await api.get_json("/v1/curation/%s?page=%d" % [realm, page])


## "Pick a different generated layout": the one from `layout_seed` laid on the
## realm and published, generated. Answers the view after it.
func layout(realm: String, layout_seed: String) -> Result:
	return await api.post_json("/v1/curation/%s/layout" % realm, {"seed": layout_seed})


## G54: `law` woven in slot `slot` of `realm` in place of what is there, at
## §5.6's price and time.
func swap(realm: String, slot: int, law: String) -> Result:
	return await api.post_json("/v1/weaving", {"realm": realm, "slot": slot, "law": law, "swap": true})


## The curated island published: it stays generated while its terrain is
## the layout's (§13.3).
func publish(realm: String, island: PackedByteArray) -> Result:
	return await api.raw(HTTPClient.METHOD_PUT, "/v1/islands/%s" % realm, island)


## "Name it", from the word lists' indexes. Answers the view after it.
func name_island(realm: String, adjective: int, noun: int) -> Result:
	return await api.json(HTTPClient.METHOD_PUT, "/v1/curation/%s/name" % realm,
		{"adjective": adjective, "noun": noun})
