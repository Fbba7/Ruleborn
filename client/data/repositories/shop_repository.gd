class_name ShopRepository
extends RefCounted
## Purchases, gifts and cosmetics (§20.2, §22.1, F41; server/src/shop.mjs).
## A purchase is three steps: an intent the server holds under a minor's
## monthly cap, the platform store's purchase, and the store's receipt, which
## goes through §24.12's outbox so a purchase is never lost to a dropped
## network — the player has paid by then.

var api: Api
var outbox: Outbox


func _init(a: Api, o: Outbox) -> void:
	api = a
	outbox = o


## The catalogue with each item's products and price, what is owned and what
## is worn.
func catalogue() -> Result:
	return await api.get_json("/v1/cosmetics")


func equip(kind: String, item: Variant, target: Variant = null) -> Result:
	var body := {"kind": kind, "item": item}
	if target != null:
		body["target"] = target
	return await api.post_json("/v1/cosmetics/equip", body)


## Step one: ask to buy `product` for oneself, or as a gift `for_friend`.
func intent(product: String, for_friend := "") -> Result:
	var body := {"product": product}
	if for_friend != "":
		body["for"] = for_friend
	return await api.post_json("/v1/shop/intents", body)


## Step three: the store's receipt, kept in the outbox under its store
## transaction until the server has decided it. Answered `pending` when the
## network could not carry it; the outbox sends it on the next flush.
func redeem(store: String, transaction: String, receipt: String) -> Result:
	var key := "%s:%s" % [store, transaction]
	outbox.put(key, "/v1/shop/receipts", JSON.stringify({"store": store, "receipt": receipt}).to_utf8_buffer(), true)
	var answered := {"result": null}
	var on_settled := func(k: String, r: Result) -> void:
		if k == key:
			answered["result"] = r
	outbox.settled.connect(on_settled)
	await outbox.flush(api)
	outbox.settled.disconnect(on_settled)
	if answered["result"] == null:
		return Result.success({"pending": true})
	return answered["result"]


## §20.2's monthly spending summary, and what a minor may still spend.
func summary() -> Result:
	return await api.get_json("/v1/shop/summary")
