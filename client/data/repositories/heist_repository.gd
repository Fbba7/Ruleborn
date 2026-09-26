class_name HeistRepository
extends RefCounted
## §24.12's lease, play, queue and validate, from the client's side: targets
## from §24.8's lists, a lease on one, and the replay sent through the outbox
## so a submission survives no network.

var api: Api
var outbox: Outbox


func _init(a: Api, o: Outbox) -> void:
	api = a
	outbox = o


## §24.8: the current target list for each band, by hash.
func target_index() -> Result:
	return await api.get_json("/v1/targets")


## A bundle or a target list, by the hash it is stored under.
func fetch(key: String) -> Result:
	return await api.raw(HTTPClient.METHOD_GET, "/v1/bundles/" + key)


## The first island in the target lists that is not the player's own: the
## list file is fetched by hash, as §24.8 intends. §12.22's ordering runs on
## the server (GET /v1/offer); this is the fallback on a list alone.
func first_target(account: String) -> Result:
	var index := await target_index()
	if not index.ok:
		return index
	for band: String in index.value:
		var file := await fetch(str(index.value[band]))
		if not file.ok:
			continue
		var list: Variant = JSON.parse_string((file.value as PackedByteArray).get_string_from_utf8())
		if list is Dictionary:
			for candidate: Dictionary in list.get("candidates", []):
				if candidate.get("owner") != account:
					return Result.success(candidate)
	return Result.failure("no_target")


## §24.12: "a target snapshot, a seed, a single-use token and an expiry".
## The owner names whose island it is: two players can publish the same one.
func lease(bundle: String, owner := "") -> Result:
	var body := {"bundle": bundle}
	if owner != "":
		body["owner"] = owner
	return await api.post_json("/v1/leases", body)


## §24.12's queue, validate and grant: the replay is kept in the outbox under
## its lease token, then sent. The answer is the server's decision; if the
## network is not there, `pending` is true and the outbox sends it later.
func submit(lease_token: String, replay_bytes: PackedByteArray) -> Result:
	var route := "/v1/heists/" + lease_token
	outbox.put(lease_token, route, replay_bytes)
	var answered := {"result": null}
	var on_settled := func(key: String, r: Result) -> void:
		if key == lease_token:
			answered["result"] = r
	outbox.settled.connect(on_settled)
	await outbox.flush(api)
	outbox.settled.disconnect(on_settled)
	if answered["result"] == null:
		return Result.success({"pending": true})
	return answered["result"]


func replay(heist_token: String) -> Result:
	return await api.raw(HTTPClient.METHOD_GET, "/v1/heists/%s/replay" % heist_token)
