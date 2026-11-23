class_name ShopPresenter
extends RefCounted
## What the track, shop and wallet screens show, from the store's slices:
## plain data, no nodes, so each is tested headless. Every word is the
## catalogue's; every number is formatted for the player's language.


## The premium track's kinds, in the server's order (track.mjs PREMIUM_KINDS).
const PREMIUM_KINDS := ["realm_skin", "sky_theme", "bridge_style", "outfit", "sage_robe", "law_visual"]
## Slots worn one per crew role or per law (G28): what each is worn by.
const TARGETED := {"outfit": "role", "law_visual": "law"}


## Cents as money in the player's language (§19.12: "Every cosmetic shows its
## real-money price"): the store's own price when it gave one, else the
## server's euros.
static func money(cents: int, store_price := "") -> String:
	if store_price != "":
		return store_price
	var whole := cents / 100
	var part := cents % 100
	return Strings.t("MONEY_EUR", "%s%s%02d" % [grouped(whole), Strings.t("NUMBER_DECIMAL"), part])


## A whole number with the language's thousands separator: 11,250 or 11.250.
static func grouped(n: int) -> String:
	var digits := str(absi(n))
	var out := ""
	while digits.length() > 3:
		out = Strings.t("NUMBER_GROUP") + digits.right(3) + out
		digits = digits.left(digits.length() - 3)
	return ("-" if n < 0 else "") + digits + out


## A reward in words: "500 Essence", "5 pages", "a stray", or a cosmetic by
## its kind.
static func reward(r: Variant) -> String:
	if not (r is Dictionary) or (r as Dictionary).is_empty():
		return ""
	var d: Dictionary = r
	if d.has("essence"):
		return Strings.t("TRACK_ESSENCE", grouped(int(d["essence"])))
	if d.has("pages"):
		return Strings.t("TRACK_PAGES", int(d["pages"]))
	if d.has("strayOffer"):
		return Strings.t("TRACK_STRAY")
	if d.has("cosmetic"):
		return Strings.t("TRACK_COSMETIC", Strings.term("KIND", str(d.get("kind", ""))))
	return ""


## The track screen: the season, stars in hand, the next tier and its price,
## and every tier with what each track gives and whether it is claimed.
static func track(t: Dictionary) -> Dictionary:
	var v: Dictionary = t.get("view", {})
	if v.is_empty():
		return {"ready": false, "error": str(t.get("error", "")), "busy": bool(t.get("busy", false))}
	var claimed := int(v.get("claimed", 0))
	var next: Variant = v.get("next")
	var stars := int(v.get("stars", 0))
	var rows: Array[Dictionary] = []
	for tier: Dictionary in v.get("tiers", []):
		var n := int(tier["tier"])
		var state := "claimed" if n <= claimed else ("next" if next is Dictionary and n == int(next["tier"]) else "later")
		var premium := reward(tier.get("premium"))
		rows.append({"tier": n, "state": state,
			"text": Strings.t("TRACK_TIER", [n, reward(tier.get("free")),
				(Strings.t("TRACK_AND_PREMIUM", premium) if premium != "" else "")]),
			"premium_held": premium != "" and not bool(v.get("premium", false)),
			"free": reward(tier.get("free")), "free_mark": mark(tier.get("free")), "paid": premium,
			"paid_mark": mark(tier.get("premium"))})
	var can := next is Dictionary and stars >= int(next["cost"])
	return {
		"ready": true, "busy": bool(t.get("busy", false)), "error": str(t.get("error", "")),
		"title": Strings.t("TRACK_TITLE", int(v["season"])),
		"stars": Strings.t("TRACK_STARS", grouped(stars)),
		"next": (Strings.t("TRACK_NEXT", [int(next["tier"]), int(next["cost"])]) if next is Dictionary
			else Strings.t("TRACK_COMPLETE")),
		"can_claim": can,
		"premium": bool(v.get("premium", false)),
		"premium_product": str(v.get("premiumProduct", "")),
		"premium_price": int(v.get("premiumPrice", 0)),
		"season": int(v["season"]),
		"rows": rows,
		"claimed": _claimed_text(t.get("claimed", {})),
		"stars_n": stars, "next_tier": int(next["tier"]) if next is Dictionary else 0,
		"next_cost": int(next["cost"]) if next is Dictionary else 0, "claimed_n": claimed,
	}


## A reward's mark: [group, icon] from the design's set, or a resource.
static func mark(r: Variant) -> Array:
	if not (r is Dictionary) or (r as Dictionary).is_empty():
		return []
	var d: Dictionary = r
	if d.has("essence"):
		return ["coin", "essence"]
	if d.has("pages"):
		return ["currencies", "pages"]
	if d.has("strayOffer"):
		return ["season", "tierreward"]
	if d.has("cosmetic"):
		return ["shopcosmetics", str(d.get("kind", "")).replace("_", "")]
	return []


static func _claimed_text(c: Variant) -> String:
	if not (c is Dictionary) or (c as Dictionary).is_empty():
		return ""
	var d: Dictionary = c
	var got := reward(d.get("free"))
	var premium := reward(d.get("premium"))
	return Strings.t("TRACK_CLAIMED", [int(d["tier"]), got + (Strings.t("TRACK_AND_PREMIUM", premium)
		if premium != "" else "")])


## A cosmetic's kind: the catalogue's, or read from an earned one's id as
## the server reads it (shop.mjs kindOf): a track tier's is its tier's kind,
## a league's season-end cosmetic is a realm skin, the first hatch's free
## outfit (§19.20) is an outfit (RB-20).
static func kind_of(id: String, catalogue: Array) -> String:
	for i: Dictionary in catalogue:
		if str(i["id"]) == id:
			return str(i.get("kind", ""))
	var tier := RegEx.create_from_string("^track-\\d+-(\\d+)$").search(id)
	if tier != null:
		return PREMIUM_KINDS[(int(tier.get_string(1)) / 5 - 1) % PREMIUM_KINDS.size()]
	if RegEx.create_from_string("^season-\\d+-[a-z]+$").search(id) != null:
		return "realm_skin"
	if id == "hatch-outfit":
		return "outfit"
	return ""


## A cosmetic's name for its card's title: its catalogue words, else the
## name its id ends in ("robe-aurora" is Aurora), as its kind is shown beside.
static func cosmetic_title(id: String) -> String:
	var key := "COSMETIC_" + id.to_upper().replace("-", "_")
	if Strings.rows().has(key):
		return Strings.t(key)
	var tail := id.get_slice("-", 1) if id.contains("-") else id
	return Strings.t("SCREEN_COSMETIC_TITLE", tail.replace("_", " ").capitalize())


## A cosmetic's name: its catalogue words if it has them, else its kind and id.
static func cosmetic_name(id: String, kind: String) -> String:
	var key := "COSMETIC_" + id.to_upper().replace("-", "_")
	return Strings.t(key) if Strings.rows().has(key) else Strings.t("SHOP_OWNED_NAME",
		[Strings.term("KIND", kind), id])


## The shop screen: each item for sale with its money price; what the player
## owns, bought or earned, with where it is worn (§22.1: an outfit by a crew
## role, a law visual by a law, an emote used rather than worn); the friends a
## gift can go to; the month's spending (§20.2) and, for a minor, what is left
## of the month's cap. `loaded` tells an empty shop from one still loading.
static func shop(s: Dictionary, purchases: StorePurchases) -> Dictionary:
	var owned: Array = s.get("owned", [])
	var equipped: Dictionary = s.get("equipped", {})
	var catalogue: Array = s.get("items", [])
	var items: Array[Dictionary] = []
	for i: Dictionary in catalogue:
		var id := str(i["id"])
		if id in owned:
			continue
		items.append({"id": id, "kind": str(i.get("kind", "")), "name": cosmetic_name(id, str(i.get("kind", ""))),
			"title": cosmetic_title(id), "price": money(int(i.get("price", 0)), purchases.price(id)),
			"product": str(i.get("product", id)), "gift": str(i.get("gift", "gift." + id))})
	var mine: Array[Dictionary] = []
	for id: Variant in owned:
		var kind := kind_of(str(id), catalogue)
		var slots: Array[String] = []
		for slot: String in equipped:
			if str(equipped[slot]) == str(id):
				slots.append(slot)
		mine.append({"id": str(id), "kind": kind, "name": cosmetic_name(str(id), kind),
			"wearable": kind != "" and kind != "emote", "target": TARGETED.get(kind, ""),
			"worn_in": slots})
	var friends: Array[Dictionary] = []
	for f: Dictionary in s.get("friends", []):
		friends.append({"account": str(f["account"]), "name": SocialPresenter.who(str(f["account"]), "")})
	var summary: Dictionary = s.get("summary", {})
	var months: Array[String] = []
	for m: Dictionary in summary.get("months", []):
		months.append(Strings.t("SHOP_MONTH", [str(m["month"]), money(int(m["cents"])), money(int(m["refunded"]))]))
	var left: Variant = summary.get("left")
	var loaded := bool(s.get("loaded", false))
	return {
		"items": items, "owned": mine, "friends": friends,
		"loaded": loaded, "empty": loaded and items.is_empty() and mine.is_empty(),
		"buying": str(s.get("buying", "")), "error": str(s.get("error", "")),
		"bought": _bought_text(s.get("bought", {})),
		"months": months,
		"left": Strings.t("SHOP_LEFT", money(int(left))) if left != null and not summary.is_empty() else "",
	}


static func _bought_text(b: Variant) -> String:
	if not (b is Dictionary) or (b as Dictionary).is_empty():
		return ""
	var d: Dictionary = b
	if d.get("pending", false):
		return Strings.t("SHOP_PENDING")
	return Strings.t("SHOP_BOUGHT")


## The wallet: §9.1's two resources, in the player's numbers.
static func wallet(w: Dictionary) -> Dictionary:
	if not w.get("known", false):
		var code := str(w.get("error", ""))
		return {"text": Errors.message("WALLET_FAILED", code) if code != "" else Strings.t("COMMON_LOADING"),
			"error": code}
	return {"text": Strings.t("WALLET", [grouped(int(w["starlight"])), grouped(int(w["essence"]))]),
		"error": str(w.get("error", ""))}
