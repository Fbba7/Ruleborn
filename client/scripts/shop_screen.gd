class_name ShopScreen
extends Control
## The shop (§19.12, §20.2, §22.1, F41): the wallet, every cosmetic for sale
## at its money price with Buy and Give, everything the player owns — bought
## or earned — with Wear and Take off, the month's spending and a minor's
## cap. There is no currency: each item is a store product. It draws the
## store only; the purchase runs in Services' shop flow, so leaving the screen
## mid-purchase loses nothing.

## The crew roles an outfit is worn by (content/roles.json's ids, G28).
const ROLES := ["scout", "breaker", "carrier", "warden", "mender"]

var controller: ShopController
var body: VBoxContainer
var wallet_label: Label
var status_label: Label
## The friend a gift goes to, by index into the player's friends.
var friend_index := 0
## Where each owned item would be worn, for the slots worn by a role or a
## law: its index into those.
var target_index := {}


func _ready() -> void:
	App.ready(self)
	controller = App.services.shop_flow
	_build()
	App.services.store.changed.connect(_on_changed)
	_refresh()
	await controller.load_wallet()
	await controller.load_shop()


func _on_changed(slice: StringName) -> void:
	if slice in [ShopState.SHOP, ShopState.WALLET] and is_inside_tree():
		_refresh()


func _build() -> void:
	var column := UI.frame(self)
	column.add_child(UI.title(Strings.t("SHOP_TITLE")))
	var head := UI.panel()
	wallet_label = UI.label("", UI.TEXT_POINTS, true)
	head.add_child(wallet_label)
	column.add_child(head)
	status_label = UI.status("info", "")
	column.add_child(UI.plate(status_label))
	body = UI.scroll(column)
	var actions := UI.row(-1.0, true)
	actions.add_child(UI.button(Strings.t("SHOP_TRACK"), func() -> void: App.services.router.go(&"track"), true))
	actions.add_child(UI.button(Strings.t("COMMON_HOME"), func() -> void: App.services.router.go(&"home")))
	column.add_child(UI.narrow(actions))


## The places a slot is worn in: the crew roles for an outfit, the launch laws
## for a law visual.
static func targets(kind: String) -> Array:
	if ShopPresenter.TARGETED.get(kind, "") == "role":
		return ROLES
	if ShopPresenter.TARGETED.get(kind, "") == "law":
		return RulebornIsland.palette()["laws"]
	return []


func _refresh() -> void:
	var s := ShopPresenter.shop(App.services.store.get_slice(ShopState.SHOP), App.services.purchases)
	var w := ShopPresenter.wallet(App.services.store.get_slice(ShopState.WALLET))
	wallet_label.text = w["text"]
	if s["error"] != "":
		UI.set_status(status_label, "alarm", Errors.message("SHOP_FAILED", s["error"]))
	elif s["buying"] != "":
		UI.set_status(status_label, "confirming", Strings.t("SHOP_BUYING"))
	elif s["bought"] != "":
		UI.set_status(status_label, "success", s["bought"])
	elif not s["loaded"]:
		UI.set_status(status_label, "info", Strings.t("COMMON_LOADING"))
	else:
		UI.set_status(status_label, "info", "")
	for c in body.get_children():
		c.queue_free()
	if s["empty"]:
		body.add_child(UI.plate(UI.label(Strings.t("SHOP_EMPTY"), UI.TEXT_POINTS, true)))
	var friends: Array = s["friends"]
	var friend: Dictionary = friends[friend_index % friends.size()] if not friends.is_empty() else {}
	if not s["items"].is_empty() and not friend.is_empty():
		var pick := UI.row()
		pick.add_child(UI.plate(UI.label(Strings.t("SHOP_GIFT_TO", friend["name"]))))
		pick.add_child(UI.button(Strings.t("SHOP_OTHER_FRIEND"), func() -> void:
			friend_index += 1
			_refresh()))
		body.add_child(pick)
	for item: Dictionary in s["items"]:
		body.add_child(_for_sale(item, s["buying"] != "", friend))
	for item: Dictionary in s["owned"]:
		body.add_child(_owned(item))
	# §20.2's summary, and a minor's cap, after what is on sale.
	var lines: Array[String] = s["months"].duplicate()
	if s["left"] != "":
		lines.append(s["left"])
	if not lines.is_empty():
		body.add_child(UI.plate(UI.label("\n".join(lines), UI.TEXT_POINTS, true)))


func _for_sale(item: Dictionary, busy: bool, friend: Dictionary) -> Control:
	var box := VBoxContainer.new()
	box.add_child(UI.label(Strings.t("SHOP_ITEM", [item["name"], item["price"]]), UI.TEXT_POINTS, true))
	var r := UI.row()
	var buy := UI.button(Strings.t("SHOP_BUY"), controller.buy.bind(item["id"]), true, Color(),
		Strings.t("SHOP_BUY_NAMED", [item["name"], item["price"]]))
	buy.disabled = busy
	r.add_child(buy)
	if not friend.is_empty():
		var give := UI.button(Strings.t("SHOP_GIVE"), controller.buy.bind(item["id"], friend["account"]), false,
			Color(), Strings.t("SHOP_GIVE_NAMED", [item["name"], friend["name"]]))
		give.disabled = busy
		r.add_child(give)
	box.add_child(r)
	return UI.plate(box)


func _owned(item: Dictionary) -> Control:
	var box := VBoxContainer.new()
	var worn: Array = item["worn_in"]
	box.add_child(UI.label(Strings.t("SHOP_OWNED_WORN" if not worn.is_empty() else "SHOP_OWNED", item["name"]),
		UI.TEXT_POINTS, true))
	if not item["wearable"]:
		return UI.plate(box)
	var r := UI.row()
	var places := targets(item["kind"])
	var target: Variant = null
	if not places.is_empty():
		target = places[int(target_index.get(item["id"], 0)) % places.size()]
		var place := Strings.term("ROLE" if item["target"] == "role" else "LAW", str(target))
		r.add_child(UI.button(Strings.t("SHOP_WORN_BY", place), func() -> void:
			target_index[item["id"]] = int(target_index.get(item["id"], 0)) + 1
			_refresh(), false, Color(), Strings.t("SHOP_WORN_BY_NEXT", place)))
	var slot := str(item["kind"]) if target == null else "%s:%s" % [item["kind"], target]
	var on := slot in worn
	r.add_child(UI.button(Strings.t("SHOP_TAKE_OFF" if on else "SHOP_WEAR"),
		controller.wear.bind(item["kind"], null if on else item["id"], target), false, Color(),
		Strings.t("SHOP_TAKE_OFF_NAMED" if on else "SHOP_WEAR_NAMED", item["name"])))
	box.add_child(r)
	return UI.plate(box)
