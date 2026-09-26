class_name ShopTests
extends RefCounted
## The season track, the shop and the wallet (§18.2, §20.2, §22.1, F41,
## G32): reducers and presenters headless, the purchase flow against a
## FakeTransport and a fake store, and the whole of it against the real
## server when run.gd names one. `check(name, passed, detail)` is run.gd's.

var tree: SceneTree
var check: Callable
var server_url := ""


func _init(t: SceneTree, c: Callable, url: String) -> void:
	tree = t
	check = c
	server_url = url


func run() -> void:
	_reducers()
	_track_words()
	_money()
	_owned()
	await _session()
	await _unblocked()
	await _purchase()
	await _capped()
	await _kept()
	await _against_server()


func _fake() -> Array:
	var transport := FakeTransport.new()
	var s := Services.build(tree.root, "https://edge.example", transport, "user://outbox-shop-test.json")
	s.router.change = func(_path: String) -> void: pass
	var store := FakeStorePurchases.new()
	s.purchases = store
	DirAccess.remove_absolute("user://outbox-shop-test.json")
	s.outbox = Outbox.new("user://outbox-shop-test.json")
	s.shop.outbox = s.outbox
	# Signed in already: the flows under test make no session call of their own.
	s.api.token = "t"
	return [s, transport, store]


func _reducers() -> void:
	var store := Store.new()
	ShopState.register(store)
	var seen: Array[StringName] = []
	store.changed.connect(func(slice: StringName) -> void: seen.append(slice))
	store.dispatch(&"track_loaded", {"view": {"season": 1, "claimed": 0}})
	store.dispatch(&"track_failed", {"code": "not_enough_stars"})
	var track: Dictionary = store.get_slice(ShopState.TRACK)
	store.dispatch(&"purchase_started", {"product": "premium.1"})
	var buying: String = store.get_slice(ShopState.SHOP)["buying"]
	store.dispatch(&"purchase_failed", {"code": "monthly_cap"})
	store.dispatch(&"wallet_loaded", {"balance": {"starlight": 11250, "essence": 500}})
	var shop: Dictionary = store.get_slice(ShopState.SHOP)
	var wallet: Dictionary = store.get_slice(ShopState.WALLET)
	check.call("the track, shop and wallet reducers change only their own slice, keep what they had when a call "
			+ "fails, and name the failure",
		track["view"] == {"season": 1, "claimed": 0} and track["error"] == "not_enough_stars"
			and buying == "premium.1" and shop["buying"] == "" and shop["error"] == "monthly_cap"
			and wallet == {"starlight": 11250, "essence": 500, "known": true, "error": ""}
			and seen == [ShopState.TRACK, ShopState.TRACK, ShopState.SHOP, ShopState.SHOP, ShopState.WALLET],
		"%s %s %s %s" % [track, shop, wallet, seen])


func _view() -> Dictionary:
	var tiers := []
	for n in range(1, 11):
		var free := {"essence": 500} if n % 5 != 0 else {"pages": 5}
		var premium: Variant = null
		if n % 5 == 0:
			premium = {"cosmetic": "track-1-%d" % n, "kind": "realm_skin"}
		tiers.append({"tier": n, "free": free, "premium": premium})
	return {"season": 1, "current": 1, "stars": 30, "tierStars": 20, "claimed": 4, "premium": false,
		"premiumProduct": "premium.1", "premiumPrice": 600, "next": {"tier": 5, "cost": 20}, "tiers": tiers}


func _track_words() -> void:
	var out := {}
	for locale: String in Strings.LOCALES:
		Strings.set_locale(locale)
		out[locale] = ShopPresenter.track({"view": _view(), "error": "", "busy": false, "claimed": {}})
	Strings.set_locale("en")
	var en: Dictionary = out["en"]
	var rows: Array = en["rows"]
	var five: Dictionary = rows[4]
	var pt_rows: Array = out["pt_BR"]["rows"]
	check.call("the track shows the season, the stars in hand, the next tier and its price, and each tier's "
			+ "rewards from both tracks, claimed or not, in both languages (§18.2)",
		en["title"].contains("1") and en["stars"].contains("30") and en["next"].contains("5")
			and en["next"].contains("20") and en["can_claim"] and rows.size() == 10
			and rows[0]["state"] == "claimed" and five["state"] == "next" and five["premium_held"]
			and rows[0]["text"] == "Tier 1: 500 Essence"
			and five["text"] == "Tier 5: 5 pages, and with the premium track a realm skin"
			and pt_rows[0]["text"] == "Nível 1: 500 de Essência"
			and pt_rows[4]["text"] == "Nível 5: 5 páginas, e com a trilha premium um item: visual de reino"
			and rows[5]["state"] == "later" and out["pt_BR"]["stars"] != en["stars"],
		"%s / %s" % [[rows[0]["text"], five["text"]], [pt_rows[0]["text"], pt_rows[4]["text"]]])


func _money() -> void:
	var got := {}
	for locale: String in Strings.LOCALES:
		Strings.set_locale(locale)
		got[locale] = [ShopPresenter.money(600), ShopPresenter.grouped(11250), ShopPresenter.money(123456)]
	Strings.set_locale("en")
	var store_first := ShopPresenter.money(600, "R$ 34,90") == "R$ 34,90"
	check.call("money and numbers are written the player's way: €6.00 and 11,250 in English, €6,00 and 11.250 "
			+ "in Portuguese, and the store's own price before the server's (§19.12)",
		got["en"] == ["€6.00", "11,250", "€1,234.56"] and got["pt_BR"] == ["€ 6,00", "11.250", "€ 1.234,56"]
			and store_first, str(got))


func _owned() -> void:
	var shown := ShopPresenter.shop({"items": [{"id": "robe", "kind": "sage_robe", "price": 500},
			{"id": "wave", "kind": "emote", "price": 100}],
		"owned": ["wave", "track-1-20"], "equipped": {"outfit:scout": "track-1-20"}, "loaded": true,
		"friends": [{"account": "ffee0011", "since": 1}]}, StorePurchases.new())
	var mine: Array = shown["owned"]
	var earned: Dictionary = mine[1]
	check.call("the shop lists what is for sale, and everything owned, bought or earned, to wear where it is "
			+ "worn: an earned outfit by a crew role, an emote used rather than worn; gifts go to a friend "
			+ "(§22.1, F41, G28)",
		shown["items"].size() == 1 and shown["items"][0]["id"] == "robe" and mine.size() == 2
			and not mine[0]["wearable"] and earned["kind"] == "outfit" and earned["target"] == "role"
			and earned["worn_in"] == ["outfit:scout"] and shown["friends"][0]["name"] == Strings.t("SOCIAL_KEEPER",
				"FFEE") and ShopScreen.targets("outfit").size() == 5 and not ShopScreen.targets("law_visual").is_empty(),
		str(shown))


func _session() -> void:
	var transport := FakeTransport.new()
	var s := Services.build(tree.root, "https://edge.example", transport, "user://outbox-session-test.json")
	transport.on("POST /v1/session", {"account": "me", "token": "k"})
	transport.then("GET /v1/balance", [[{"error": "session_refused"}, 401]])
	transport.on("GET /v1/balance", {"starlight": 1, "essence": 2})
	await s.shop_flow.load_wallet()
	var routes := transport.calls.map(func(k: Dictionary) -> String: return k["route"])
	var wallet: Dictionary = s.store.get_slice(ShopState.WALLET)
	check.call("a screen's first call signs in by itself, and a call refused for an expired session signs in "
			+ "again and is made again, once (§24.8)",
		routes == ["POST /v1/session", "GET /v1/balance", "POST /v1/session", "GET /v1/balance"]
			and wallet["known"] and s.store.get_slice(AppState.SESSION)["account"] == "me",
		"%s %s" % [routes, wallet])
	s.close()


func _unblocked() -> void:
	var f := _fake()
	var s: Services = f[0]
	var transport: FakeTransport = f[1]
	s.outbox.put("a", "/v1/heists/a", PackedByteArray([1]))
	s.outbox.put("b", "/v1/shop/receipts", JSON.stringify({"store": "app-store", "receipt": "r"}).to_utf8_buffer(),
		true)
	transport.on("POST /v1/heists/a", {"error": "internal"}, 500)
	transport.on("POST /v1/shop/receipts", {"product": "wave", "to": "me", "granted": {}}, 201)
	var sent := await s.outbox.flush(s.api)
	check.call("one result the server cannot decide now waits, and the rest are still sent: a receipt is never "
			+ "held up behind a heist (§24.12)",
		sent == 1 and s.outbox.pending() == 1 and s.outbox.has("a") and not s.outbox.has("b"),
		"sent %d, pending %d" % [sent, s.outbox.pending()])
	s.close()


func _purchase() -> void:
	var f := _fake()
	var s: Services = f[0]
	var transport: FakeTransport = f[1]
	var store: FakeStorePurchases = f[2]
	transport.on("POST /v1/shop/intents", {"intent": "i-1", "product": "gift.robe-aurora", "price": 500}, 201)
	transport.on("POST /v1/shop/receipts", {"product": "gift.robe-aurora", "to": "friend-1",
		"granted": {"cosmetic": "robe-aurora"}}, 201)
	transport.on("GET /v1/cosmetics", {"items": [{"id": "robe-aurora", "kind": "sage_robe", "price": 500}],
		"owned": [], "equipped": {}})
	transport.on("GET /v1/shop/summary", {"currency": "EUR", "months": [{"month": "2026-09", "cents": 500,
		"refunded": 0}], "left": null})
	var c := ShopController.new(s)
	await c.buy("robe-aurora", "friend-1")
	var routes := transport.calls.map(func(k: Dictionary) -> String: return k["route"])
	var intent: Dictionary = JSON.parse_string((transport.calls[0]["body"] as PackedByteArray).get_string_from_utf8())
	var receipt: Dictionary = JSON.parse_string((transport.calls[1]["body"] as PackedByteArray).get_string_from_utf8())
	var shown := ShopPresenter.shop(s.store.get_slice(ShopState.SHOP), s.purchases)
	check.call("a purchase asks the server first, then the store with the server's intent, then sends the "
			+ "store's receipt through the outbox; a gift names its friend (F41, §20.2, §24.12)",
		routes.slice(0, 2) == ["POST /v1/shop/intents", "POST /v1/shop/receipts"]
			and intent == {"product": "gift.robe-aurora", "for": "friend-1"}
			and store.bought == [{"product": "gift.robe-aurora", "intent": "i-1"}]
			and str(receipt["receipt"]).ends_with(":i-1") and s.outbox.pending() == 0
			and shown["bought"] != "" and shown["months"].size() == 1,
		"%s %s %s %s" % [routes, intent, store.bought, shown])
	s.close()


func _capped() -> void:
	var f := _fake()
	var s: Services = f[0]
	var transport: FakeTransport = f[1]
	var store: FakeStorePurchases = f[2]
	transport.on("POST /v1/shop/intents", {"error": "monthly_cap", "left": 100, "cap": 2500}, 403)
	await ShopController.new(s).buy("premium.1")
	var shown := ShopPresenter.shop(s.store.get_slice(ShopState.SHOP), s.purchases)
	check.call("a purchase over a minor's monthly cap never reaches the store, and the player is told why (§20.2)",
		store.bought.is_empty() and shown["error"] == "monthly_cap"
			and Errors.text("monthly_cap") != Strings.t("ERR_UNKNOWN", "monthly_cap"), str(shown))
	s.close()


func _kept() -> void:
	var f := _fake()
	var s: Services = f[0]
	var transport: FakeTransport = f[1]
	transport.on("POST /v1/shop/intents", {"intent": "i-2"}, 201)
	# The store took the money; the server's call to Play fails for now.
	transport.on("POST /v1/shop/receipts", {"error": "receipt_refused", "why": "store_unavailable"}, 503)
	var c := ShopController.new(s)
	await c.buy("premium.1")
	var bought: Dictionary = s.store.get_slice(ShopState.SHOP)["bought"]
	var outage: bool = s.outbox.pending() == 1 and bool(bought.get("pending", false))
	transport.on("POST /v1/shop/receipts", {"product": "premium.1", "to": "me", "granted": {}}, 201)
	transport.offline = true
	transport.on("POST /v1/shop/intents", {"intent": "i-3"}, 201)
	await s.outbox.flush(s.api)
	var still := s.outbox.pending() == 1
	transport.offline = false
	var sent := await s.outbox.flush(s.api)
	check.call("a receipt the network cannot carry, or that the server cannot check with the store yet, waits "
			+ "in the outbox and is sent later, never lost (§24.12, D67)",
		outage and still and sent == 1 and s.outbox.pending() == 0,
		"outage %s, still %s, sent %d" % [outage, still, sent])
	s.close()


func _against_server() -> void:
	var name := "against the server: the track shows this season, its first tier is claimed free and pays its "
	name += "Essence into the wallet, and the premium track is offered at its price; the store's receipt is "
	name += "checked by the server (§18.2, §22.1)"
	if server_url == "":
		check.call(name, false, "no server: run through client/status.py, which starts one")
		return
	var s := Services.build(tree.root, server_url, null, "user://outbox-shop-online.json")
	s.router.change = func(_path: String) -> void: pass
	DirAccess.remove_absolute("user://outbox-shop-online.json")
	s.outbox = Outbox.new("user://outbox-shop-online.json")
	s.shop.outbox = s.outbox
	var store := FakeStorePurchases.new()
	s.purchases = store
	var me := await s.account.sign_in("test:shop")
	var c := ShopController.new(s)
	await c.load_track()
	var before := ShopPresenter.track(s.store.get_slice(ShopState.TRACK))
	await c.claim()
	var after := ShopPresenter.track(s.store.get_slice(ShopState.TRACK))
	var wallet: Dictionary = s.store.get_slice(ShopState.WALLET)
	await c.load_shop()
	# This server checks no store (its StoreKit roots are not configured), so
	# the fake store's receipt is refused: the refusal is the server's own.
	await c.buy(str(before.get("premium_product", "")))
	var shop: Dictionary = s.store.get_slice(ShopState.SHOP)
	check.call(name,
		me.ok and before.get("ready", false) and before["can_claim"]
			and before["premium_product"] == "premium.%d" % int(before["season"])
			and int(before["premium_price"]) == 600 and after["rows"][0]["state"] == "claimed"
			and int(wallet["essence"]) >= 500 and store.bought.size() == 1 and shop["error"] == "receipt_refused",
		"%s | %s | %s | %s" % [before.get("next"), after.get("claimed"), wallet, shop])
	s.close()
