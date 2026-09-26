class_name ShopController
extends RefCounted
## The track, the shop and the wallet, with no screen: each asks its
## repository and dispatches what came back, so a screen only draws the store
## and a test drives the flows headless against a FakeTransport or the real
## server.

var services: Services


func _init(s: Services) -> void:
	services = s


func _store() -> Store:
	return services.store


func load_track(season := 0) -> void:
	_store().dispatch(&"track_asked")
	var r := await services.track.view(season)
	if r.ok:
		_store().dispatch(&"track_loaded", {"view": r.value})
	else:
		_store().dispatch(&"track_failed", {"code": r.code})


## §18.2: claim the next tier of the season on show, then show the track again.
func claim() -> void:
	var view: Dictionary = _store().get_slice(ShopState.TRACK)["view"]
	if view.is_empty():
		return
	_store().dispatch(&"track_asked")
	var r := await services.track.claim(int(view["season"]))
	if not r.ok:
		_store().dispatch(&"track_failed", {"code": r.code})
		return
	_store().dispatch(&"tier_claimed", {"claim": r.value})
	await load_track(int(view["season"]))
	await load_wallet()


func load_shop() -> void:
	_store().dispatch(&"shop_asked")
	var r := await services.shop.catalogue()
	if not r.ok:
		_store().dispatch(&"shop_failed", {"code": r.code})
		return
	_store().dispatch(&"shop_loaded", {"catalogue": r.value})
	var s := await services.shop.summary()
	if s.ok:
		_store().dispatch(&"summary_loaded", {"summary": s.value})
	var f := await services.friends.friends()
	if f.ok:
		_store().dispatch(&"gift_friends", {"friends": f.value})


func load_wallet() -> void:
	var r := await services.account.balance()
	if r.ok:
		_store().dispatch(&"wallet_loaded", {"balance": r.value})
	else:
		_store().dispatch(&"wallet_failed", {"code": r.code})


## F41's purchase: the server's intent first (§20.2's cap is kept before the
## store takes any money), then the platform store, then its receipt through
## the outbox. `for_friend` makes it a gift, "gift." before the product.
func buy(product: String, for_friend := "") -> void:
	var id := ("gift." + product) if for_friend != "" and not product.begins_with("gift.") else product
	_store().dispatch(&"purchase_started", {"product": id})
	var i := await services.shop.intent(id, for_friend)
	if not i.ok:
		_store().dispatch(&"purchase_failed", {"code": i.code})
		return
	var paid := await services.purchases.buy(id, str(i.value["intent"]))
	if not paid.ok:
		_store().dispatch(&"purchase_failed", {"code": paid.code})
		return
	var r := await services.shop.redeem(str(paid.value["store"]), str(paid.value["transaction"]),
		str(paid.value["receipt"]))
	if not r.ok:
		_store().dispatch(&"purchase_failed", {"code": r.code})
		return
	_store().dispatch(&"purchase_finished", {"result": r.value})
	if not r.value.get("pending", false):
		await load_shop()
		if id.trim_prefix("gift.").begins_with("premium."):
			await load_track()


## Wear an owned cosmetic in its slot, or empty the slot with `item` null.
func wear(kind: String, item: Variant, target: Variant = null) -> void:
	var r := await services.shop.equip(kind, item, target)
	if r.ok:
		_store().dispatch(&"worn", {"equipped": r.value})
	else:
		_store().dispatch(&"shop_failed", {"code": r.code})
