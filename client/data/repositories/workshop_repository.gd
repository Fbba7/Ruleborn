class_name WorkshopRepository
extends RefCounted
## The Island Workshop (§18.6, §18.7, §20.7; server/src/workshop.mjs):
## browsing, the player's own islands, publishing a cleared island, playing
## one, rating, reporting, remixing and withdrawing, and a creator's ladder.

var api: Api
var outbox: Outbox


func _init(a: Api, o: Outbox) -> void:
	api = a
	outbox = o


## "top", "new" or "featured" (§20.7: a 13-to-15 sees only "featured").
func browse(list: String, limit := 20) -> Result:
	return await api.get_json("/v1/workshop?list=%s&limit=%d" % [list.uri_encode(), limit])


func mine() -> Result:
	return await api.get_json("/v1/workshop/mine")


## §18.6: publish an island the creator has cleared, with the replay that
## cleared it, named from the word lists (SocialRepository.words); `remix_of`
## names its original.
func publish(bundle: PackedByteArray, replay: PackedByteArray, adjective: int, noun: int,
		remix_of := "") -> Result:
	var body := {"bundle": Marshalls.raw_to_base64(bundle), "replay": Marshalls.raw_to_base64(replay),
		"adjective": adjective, "noun": noun}
	if remix_of != "":
		body["remixOf"] = remix_of
	return await api.post_json("/v1/workshop", body)


## A seed and a clock to play an island on: `{token, bundle, seed, ticks}`.
func play(id: String) -> Result:
	return await api.post_json("/v1/workshop/%s/play" % id.uri_encode())


## A play's replay, kept in the outbox under its token until the server has
## it (§24.12), as a raid's is.
func submit(token: String, replay: PackedByteArray) -> Result:
	return await outbox.send(api, token, "/v1/workshop/plays/" + token, replay)


## §18.7: fun, cleverness and fairness, 1 to 5 each.
func rate(id: String, fun: int, cleverness: int, fairness: int) -> Result:
	return await api.post_json("/v1/workshop/%s/rating" % id.uri_encode(),
		{"fun": fun, "cleverness": cleverness, "fairness": fairness})


## §20.4: a report, with its reason.
func report(id: String, reason: String) -> Result:
	return await api.post_json("/v1/workshop/%s/report" % id.uri_encode(), {"reason": reason})


## §18.6: the island's bundle, to build on; its remix names the original.
func remix(id: String) -> Result:
	return await api.raw(HTTPClient.METHOD_POST, "/v1/workshop/%s/remix" % id.uri_encode())


func withdraw(id: String) -> Result:
	return await api.post_json("/v1/workshop/%s/withdraw" % id.uri_encode())


## §18.7's ladder for a creator.
func ladder(account: String) -> Result:
	return await api.get_json("/v1/creators/" + account.uri_encode())

