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
var _starlight: PanelContainer
## The kind the list is filtered to, or "" for all.
var _kind := ""
var _essence: PanelContainer


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
	var column := ScreenKit.frame(self)
	var purse := HBoxContainer.new()
	purse.add_theme_constant_override("separation", UI.px(4))
	_starlight = ScreenParts.resource("starlight", "")
	_essence = ScreenParts.resource("essence", "")
	purse.add_child(_starlight)
	purse.add_child(_essence)
	column.add_child(ScreenNav.header(Strings.t("SHOP_TITLE"), purse))
	wallet_label = ScreenKit.text("", 13.0, "words", "card", true, true)
	wallet_label.visible = false
	column.add_child(wallet_label)
	status_label = UI.status("info", "")
	column.add_child(ScreenParts.status_plate(status_label))
	body = UI.scroll(column)
	var track := ScreenKit.button(Strings.t("SHOP_TRACK"), func() -> void: App.services.router.go(&"track"), "gold")
	column.add_child(ScreenNav.dock(&"home", [track]))


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
	var balance: Dictionary = App.services.store.get_slice(ShopState.WALLET)
	ScreenParts.set_resource(_starlight, ShopPresenter.grouped(int(balance["starlight"]))
		if balance.has("starlight") else "")
	ScreenParts.set_resource(_essence, ShopPresenter.grouped(int(balance["essence"])) if balance.has("essence") else "")
	wallet_label.visible = not balance.has("starlight")
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
	ScreenParts.show_status(status_label)
	for c in body.get_children():
		c.queue_free()
	if s["empty"]:
		body.add_child(ScreenParts.item("shopcosmetics", "bundle", Strings.t("SHOP_EMPTY")))
	var friends: Array = s["friends"]
	var friend: Dictionary = friends[friend_index % friends.size()] if not friends.is_empty() else {}
	if not s["items"].is_empty():
		body.add_child(ScreenParts.section(Strings.t("SCREEN_SHOP_FOR_SALE"), str((s["items"] as Array).size())))
	if not s["items"].is_empty() and not friend.is_empty():
		var other := ScreenKit.button(Strings.t("SHOP_OTHER_FRIEND"), func() -> void:
			friend_index += 1
			_refresh(), "leather", "", 14.0)
		body.add_child(ScreenParts.item("social", "gift", Strings.t("SHOP_GIFT_TO", friend["name"]), "", other))
	var kinds: Array[String] = []
	for item: Dictionary in s["items"]:
		if not kinds.has(str(item["kind"])):
			kinds.append(str(item["kind"]))
	if kinds.size() > 1:
		var chips := ScreenParts.flow(6.0)
		chips.add_child(ScreenParts.chip(Strings.t("SCREEN_ALL"), _kind == "", func() -> void:
			_kind = ""
			_refresh()))
		for k: String in kinds:
			chips.add_child(ScreenParts.chip(Strings.term("KIND", k), _kind == k, func() -> void:
				_kind = k
				_refresh(), "shopcosmetics", k.replace("_", "")))
		body.add_child(chips)
		body.move_child(chips, 0)
	var shown: Array = (s["items"] as Array).filter(func(i: Dictionary) -> bool:
		return _kind == "" or str(i["kind"]) == _kind)
	if not shown.is_empty():
		body.add_child(_featured(shown[0], s["buying"] != "", friend))
	if shown.size() > 1:
		var grid := GridContainer.new()
		grid.columns = 2 if Settings.text_scale <= 125 else 1
		grid.add_theme_constant_override("h_separation", UI.px(8))
		grid.add_theme_constant_override("v_separation", UI.px(8))
		for item: Dictionary in shown.slice(1):
			grid.add_child(_for_sale(item, s["buying"] != "", friend))
		body.add_child(grid)
	if not (s["owned"] as Array).is_empty():
		body.add_child(ScreenParts.section(Strings.t("SCREEN_SHOP_OWNED"), str((s["owned"] as Array).size())))
	for item: Dictionary in s["owned"]:
		body.add_child(_owned(item))
	# §20.2's summary, and a minor's cap, after what is on sale.
	var lines: Array[String] = s["months"].duplicate()
	if s["left"] != "":
		lines.append(s["left"])
	if not lines.is_empty():
		body.add_child(ScreenParts.item("shopcosmetics", "spendingcap", Strings.t("SCREEN_SHOP_SPENT"),
			"\n".join(lines)))


## The first cosmetic on show as the design's featured card: its art large
## on a lit stage, its name in Marcellus, its kind, and its price on gold.
func _featured(item: Dictionary, busy: bool, friend: Dictionary) -> Control:
	var top: BoxContainer = VBoxContainer.new()
	if Settings.text_scale <= 125:
		top = HBoxContainer.new()
	top.add_theme_constant_override("separation", UI.px(10))
	var words := VBoxContainer.new()
	words.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	words.add_theme_constant_override("separation", UI.px(4))
	var kicker := ScreenKit.text(Strings.t("SCREEN_FEATURED").to_upper(), 13.0, "words", "card")
	kicker.add_theme_color_override("font_color", Tokens.color("gold"))
	words.add_child(kicker)
	var name := ScreenKit.text(item.get("title", item["name"]), 26.0, "name", "card", false, true)
	name.tooltip_text = Strings.t("SHOP_ITEM", [item["name"], item["price"]])
	words.add_child(name)
	words.add_child(ScreenParts.pill(Strings.term("KIND", str(item["kind"])), "well", "shopcosmetics",
		str(item["kind"]).replace("_", "")))
	top.add_child(words)
	var art := ScreenKit.icon("shopcosmetics", str(item["kind"]).replace("_", ""), 104.0)
	top.add_child(art)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", UI.px(10))
	box.add_child(top)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", UI.px(8))
	var buy := ScreenKit.button(item["price"], controller.buy.bind(item["id"]), "gold",
		Strings.t("SHOP_BUY_NAMED", [item["name"], item["price"]]), 14.0)
	buy.disabled = busy
	buy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(buy)
	if not friend.is_empty():
		var give := ScreenKit.button(Strings.t("SHOP_GIVE"), controller.buy.bind(item["id"], friend["account"]),
			"leather", Strings.t("SHOP_GIVE_NAMED", [item["name"], friend["name"]]), 14.0)
		give.disabled = busy
		row.add_child(give)
	box.add_child(row)
	return ScreenKit.panel("frame_gold", ScreenKit.panel("card", box, 18.0, 12.0), 22.0, 5.0)


## A cosmetic for sale as the design's card: its kind's art on a lit stage,
## its name and kind, the price on its Buy button, and Give for a friend.
func _for_sale(item: Dictionary, busy: bool, friend: Dictionary) -> Control:
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", UI.px(6))
	var art := ScreenKit.icon("shopcosmetics", str(item["kind"]).replace("_", ""), 84.0)
	art.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	var stage := ScreenKit.panel("well", art, 14.0, 10.0)
	box.add_child(stage)
	var name := ScreenKit.text(item.get("title", item["name"]), 15.0, "words", "card_lit", false, true)
	name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name.tooltip_text = Strings.t("SHOP_ITEM", [item["name"], item["price"]])
	box.add_child(name)
	var kind := ScreenParts.pill(Strings.term("KIND", str(item["kind"])), "well")
	kind.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	box.add_child(kind)
	var buy := ScreenKit.button(item["price"], controller.buy.bind(item["id"]), "gold",
		Strings.t("SHOP_BUY_NAMED", [item["name"], item["price"]]), 14.0)
	buy.disabled = busy
	buy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	buy.tooltip_text = Strings.t("SHOP_BUY")
	box.add_child(buy)
	if not friend.is_empty():
		var give := ScreenKit.button(Strings.t("SHOP_GIVE"), controller.buy.bind(item["id"], friend["account"]),
			"leather", Strings.t("SHOP_GIVE_NAMED", [item["name"], friend["name"]]), 14.0)
		give.disabled = busy
		give.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		box.add_child(give)
	var p := ScreenKit.panel("card_lit", box, 18.0, 10.0)
	p.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return p


## A cosmetic owned: its art and name, where it is worn, and the controls
## that choose where and put it on or take it off.
func _owned(item: Dictionary) -> Control:
	var worn: Array = item["worn_in"]
	var words := Strings.t("SHOP_OWNED_WORN" if not worn.is_empty() else "SHOP_OWNED", item["name"])
	var controls := ScreenParts.flow(6.0)
	controls.alignment = FlowContainer.ALIGNMENT_END
	if item["wearable"]:
		var places := targets(item["kind"])
		var target: Variant = null
		if not places.is_empty():
			target = places[int(target_index.get(item["id"], 0)) % places.size()]
			var place := Strings.term("ROLE" if item["target"] == "role" else "LAW", str(target))
			controls.add_child(ScreenKit.button(Strings.t("SHOP_WORN_BY", place), func() -> void:
				target_index[item["id"]] = int(target_index.get(item["id"], 0)) + 1
				_refresh(), "card", Strings.t("SHOP_WORN_BY_NEXT", place), 14.0))
		var slot := str(item["kind"]) if target == null else "%s:%s" % [item["kind"], target]
		var on := slot in worn
		controls.add_child(ScreenKit.button(Strings.t("SHOP_TAKE_OFF" if on else "SHOP_WEAR"),
			controller.wear.bind(item["kind"], null if on else item["id"], target), "leather" if on else "gold",
			Strings.t("SHOP_TAKE_OFF_NAMED" if on else "SHOP_WEAR_NAMED", item["name"]), 14.0))
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", UI.px(6))
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", UI.px(8))
	row.add_child(ScreenKit.icon("shopcosmetics", str(item["kind"]).replace("_", ""), 40.0))
	var l := ScreenKit.text(words, 15.0, "words", "card", false, true)
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	row.add_child(l)
	if not worn.is_empty():
		row.add_child(ScreenKit.icon("generalui", "confirm", 24.0))
	box.add_child(row)
	if controls.get_child_count() > 0:
		box.add_child(controls)
	return ScreenKit.panel("card", box, 16.0, 10.0)
