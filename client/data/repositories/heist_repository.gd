class_name HeistRepository
extends RefCounted
## §24.12's lease, play, queue and validate, from the client's side: targets
## from §24.8's lists, a lease on one, and the replay sent through the outbox
## so a submission survives no network.

var api: Api
var outbox: Outbox
## Leases kept for a heist with no network (G41).
var stock: LeaseStock


func _init(a: Api, o: Outbox, s: LeaseStock = null) -> void:
	api = a
	outbox = o
	stock = s if s != null else LeaseStock.new()


## §24.8: the current target list for each band, by hash.
func target_index() -> Result:
	return await api.get_json("/v1/targets")


## A bundle or a target list, by the hash it is stored under.
func fetch(key: String) -> Result:
	return await api.raw(HTTPClient.METHOD_GET, "/v1/bundles/" + key)


## The first island in the target lists that is not the player's own: the
## list file is fetched by hash, as §24.8 intends. §12.22's ordering runs on
## the server (GET /v1/offer); this is the fallback on a list alone, and like
## §12.22 it reaches for the game's generated islands only when no player's
## island is there.
func first_target(account: String, skip: Array[String] = []) -> Result:
	var index := await target_index()
	if not index.ok:
		return index
	var generated: Dictionary = {}
	for band: String in index.value:
		var file := await fetch(str(index.value[band]))
		if not file.ok:
			continue
		var list: Variant = JSON.parse_string((file.value as PackedByteArray).get_string_from_utf8())
		if list is Dictionary:
			for candidate: Dictionary in list.get("candidates", []):
				if candidate.get("owner") == account or str(candidate.get("bundle")) in skip:
					continue
				if candidate.get("origin") != "generated":
					return Result.success(candidate)
				if generated.is_empty():
					generated = candidate
	if not generated.is_empty():
		return Result.success(generated)
	return Result.failure("no_target")


## G41: while online, keep LeaseStock.SIZE leases with their islands, each on
## an island not already held, so a heist can start with no network. Returns
## how many were added; stops at the first failure, which the next refill
## tries again.
func fill_stock(account: String) -> int:
	var added := 0
	while stock.count() < LeaseStock.SIZE:
		var target := await first_target(account, stock.bundles())
		if not target.ok:
			break
		var bundle := await fetch(str(target.value["bundle"]))
		if not bundle.ok:
			break
		var leased := await lease(str(target.value["bundle"]), str(target.value.get("owner", "")))
		if not leased.ok:
			break
		stock.add(str(target.value["bundle"]), leased.value, bundle.value)
		added += 1
	return added


## §24.12: "a target snapshot, a seed, a single-use token and an expiry".
## The owner names whose island it is: two players can publish the same one.
func lease(bundle: String, owner := "", trace := false) -> Result:
	var body := {"bundle": bundle}
	if owner != "":
		body["owner"] = owner
	# §12.3's Trace: the raider's island, once, with no fee.
	if trace:
		body["trace"] = true
	return await api.post_json("/v1/leases", body)


## §24.12's queue, validate and grant: the replay is kept in the outbox under
## its lease token, then sent. The answer is the server's decision; if the
## network is not there, `pending` is true and the outbox sends it later.
func submit(lease_token: String, replay_bytes: PackedByteArray) -> Result:
	# The server hands back a raider's open lease on the same island, so the
	# token played may be one the stock holds: once played, it leaves it.
	stock.drop(lease_token)
	return await outbox.send(api, lease_token, "/v1/heists/" + lease_token, replay_bytes)


func replay(heist_token: String) -> Result:
	return await api.raw(HTTPClient.METHOD_GET, "/v1/heists/%s/replay" % heist_token)
