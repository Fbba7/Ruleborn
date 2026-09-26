class_name ShopState
extends RefCounted
## The season track, the shop and the wallet, as the store holds them
## (§18.2, §20.2, §22.1). Each reducer is a static function of (slice,
## payload) returning the new slice, so the tests call them directly.

## The season track as the server last showed it, and what went wrong last.
const TRACK := &"track"
## The catalogue, what is owned and worn, the month's spending, and the
## purchase in progress: "" or the product being bought.
const SHOP := &"shop"
## Starlight and Essence (§9.1), as the server's ledger holds them.
const WALLET := &"wallet"


static func register(store: Store) -> void:
	store.register(TRACK, {"view": {}, "error": "", "busy": false, "claimed": {}}, {
		&"track_asked": asked,
		&"track_loaded": track_loaded,
		&"track_failed": failed,
		&"tier_claimed": tier_claimed,
	})
	store.register(SHOP, {"items": [], "owned": [], "equipped": {}, "summary": {}, "error": "", "buying": "",
			"bought": {}, "busy": false, "loaded": false, "friends": []}, {
		&"shop_asked": asked,
		&"shop_loaded": shop_loaded,
		&"summary_loaded": summary_loaded,
		&"shop_failed": failed,
		&"purchase_started": purchase_started,
		&"purchase_finished": purchase_finished,
		&"purchase_failed": purchase_failed,
		&"worn": worn,
		&"gift_friends": gift_friends,
	})
	store.register(WALLET, {"starlight": 0, "essence": 0, "known": false, "error": ""}, {
		&"wallet_loaded": wallet_loaded,
		&"wallet_failed": failed,
	})


## A call to the server is on its way: the slice says so and forgets the
## last failure.
static func asked(s: Dictionary, _p: Dictionary) -> Dictionary:
	var next := s.duplicate()
	next["busy"] = true
	next["error"] = ""
	return next


## A call failed: the slice keeps what it had, and the failure's code.
static func failed(s: Dictionary, p: Dictionary) -> Dictionary:
	var next := s.duplicate()
	next["busy"] = false
	next["error"] = str(p["code"])
	return next


static func track_loaded(s: Dictionary, p: Dictionary) -> Dictionary:
	var next := s.duplicate()
	next["view"] = p["view"]
	next["busy"] = false
	next["error"] = ""
	return next


## What the tier just claimed gave: kept to show, until the next claim.
static func tier_claimed(s: Dictionary, p: Dictionary) -> Dictionary:
	var next := s.duplicate()
	next["claimed"] = p["claim"]
	next["busy"] = false
	next["error"] = ""
	return next


static func shop_loaded(s: Dictionary, p: Dictionary) -> Dictionary:
	var next := s.duplicate()
	var c: Dictionary = p["catalogue"]
	next["items"] = c.get("items", [])
	next["owned"] = c.get("owned", [])
	next["equipped"] = c.get("equipped", {})
	next["busy"] = false
	next["error"] = ""
	next["loaded"] = true
	return next


static func summary_loaded(s: Dictionary, p: Dictionary) -> Dictionary:
	var next := s.duplicate()
	next["summary"] = p["summary"]
	return next


static func purchase_started(s: Dictionary, p: Dictionary) -> Dictionary:
	var next := s.duplicate()
	next["buying"] = str(p["product"])
	next["failed"] = ""
	next["bought"] = {}
	next["error"] = ""
	return next


## The server granted it, or holds its receipt until the network is back
## (`pending`, §24.12).
static func purchase_finished(s: Dictionary, p: Dictionary) -> Dictionary:
	var next := s.duplicate()
	next["buying"] = ""
	next["bought"] = p["result"]
	return next


## What failed is kept with why, so only the screen that bought it says so.
static func purchase_failed(s: Dictionary, p: Dictionary) -> Dictionary:
	var next := s.duplicate()
	next["failed"] = s.get("buying", "")
	next["buying"] = ""
	next["error"] = str(p["code"])
	return next


## The player's friends, whom a gift can go to (F41).
static func gift_friends(s: Dictionary, p: Dictionary) -> Dictionary:
	var next := s.duplicate()
	next["friends"] = p["friends"]
	return next


static func worn(s: Dictionary, p: Dictionary) -> Dictionary:
	var next := s.duplicate()
	next["equipped"] = p["equipped"]
	return next


static func wallet_loaded(_s: Dictionary, p: Dictionary) -> Dictionary:
	return {"starlight": int(p["balance"].get("starlight", 0)), "essence": int(p["balance"].get("essence", 0)),
		"known": true, "error": ""}
