class_name TrackScreen
extends Control
## The season track (§18.2, §18.8): stars in hand, the next tier and what it
## costs, a claim button, and all fifty tiers with what each track gives. It
## draws the store only; `ShopController` asks the server.

var controller: ShopController
var body: VBoxContainer
var title_label: Label
var stars_label: Label
var next_label: Label
var status_label: Label
var claim_button: Button
var premium_button: Button


func _ready() -> void:
	App.ready(self)
	controller = App.services.shop_flow
	_build()
	App.services.store.changed.connect(_on_changed)
	_refresh()
	await controller.load_track()
	await controller.load_wallet()


func _on_changed(slice: StringName) -> void:
	if slice in [ShopState.TRACK, ShopState.WALLET, ShopState.SHOP] and is_inside_tree():
		_refresh()


func _build() -> void:
	var column := UI.frame(self)
	title_label = UI.title("")
	column.add_child(title_label)
	var head := UI.panel()
	var head_box := VBoxContainer.new()
	head.add_child(head_box)
	stars_label = UI.label("", UI.TEXT_POINTS, true)
	next_label = UI.label("", UI.TEXT_POINTS, true)
	head_box.add_child(stars_label)
	head_box.add_child(next_label)
	column.add_child(head)
	status_label = UI.status("info", "")
	column.add_child(UI.plate(status_label))
	body = UI.scroll(column, true)
	var actions := UI.row(-1.0, true)
	claim_button = UI.button(Strings.t("TRACK_CLAIM"), controller.claim, true)
	actions.add_child(claim_button)
	premium_button = UI.button(Strings.t("TRACK_PREMIUM"), _buy_premium)
	actions.add_child(premium_button)
	actions.add_child(UI.button(Strings.t("COMMON_HOME"), func() -> void: App.services.router.go(&"home")))
	column.add_child(UI.narrow(actions))


func _buy_premium() -> void:
	var t := ShopPresenter.track(App.services.store.get_slice(ShopState.TRACK))
	if t.get("premium_product", "") != "":
		await controller.buy(str(t["premium_product"]))


func _refresh() -> void:
	var t := ShopPresenter.track(App.services.store.get_slice(ShopState.TRACK))
	var shop: Dictionary = App.services.store.get_slice(ShopState.SHOP)
	if not t["ready"]:
		title_label.text = Strings.t("TRACK_TITLE_LOADING")
		UI.set_status(status_label, "alarm" if t["error"] != "" else "info",
			Errors.message("TRACK_FAILED", t["error"]) if t["error"] != "" else Strings.t("COMMON_LOADING"))
		claim_button.disabled = true
		premium_button.visible = false
		return
	title_label.text = t["title"]
	stars_label.text = t["stars"]
	next_label.text = t["next"]
	claim_button.disabled = not t["can_claim"] or t["busy"]
	premium_button.visible = not t["premium"] and t["premium_product"] != ""
	UI.relabel(premium_button, Strings.t("TRACK_PREMIUM_PRICE", ShopPresenter.money(t["premium_price"],
		App.services.purchases.price(t["premium_product"]))))
	premium_button.disabled = str(shop.get("buying", "")) != ""
	# A purchase's failure is this screen's only if it was the premium track.
	var premium_failed := str(shop.get("failed", "")).trim_prefix("gift.").begins_with("premium.")
	if t["error"] != "":
		UI.set_status(status_label, "alarm", Errors.message("TRACK_FAILED", t["error"]))
	elif premium_failed and str(shop.get("error", "")) != "":
		UI.set_status(status_label, "alarm", Errors.message("TRACK_PREMIUM_FAILED", str(shop["error"])))
	elif t["claimed"] != "":
		UI.set_status(status_label, "success", t["claimed"])
	else:
		UI.set_status(status_label, "info", "")
	for c in body.get_children():
		c.queue_free()
	for row: Dictionary in t["rows"]:
		var kind := "success" if row["state"] == "claimed" else ("info" if row["state"] == "next" else "")
		var l := UI.status(kind, row["text"]) if kind != "" else UI.label(row["text"], UI.TEXT_POINTS, true)
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		body.add_child(l)
