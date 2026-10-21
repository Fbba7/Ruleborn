class_name TrackScreen
extends Control
## The season track (§18.2, §18.8): stars in hand, the next tier and what it
## costs, a claim button, and all fifty tiers with what each track gives. It
## draws the store only; `ShopController` asks the server.
##
## Drawn as the design's Season (Screens v3, 17): the tier strip with its
## ring and the stars toward the next tier, then the pass as a road, the
## free lane and the Starpass lane either side of each tier's node.

var controller: ShopController
var body: VBoxContainer
var title_label: Label
var stars_label: Label
var next_label: Label
var status_label: Label
var claim_button: Button
var premium_button: Button
var _stars: PanelContainer
var _bar: ScreenMeter
var _tier: ScreenMeter


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
	var column := ScreenKit.frame(self)
	_stars = ScreenParts.pill("", "glass", "currencies", "seasonstars", 15.0)
	var head := ScreenNav.header("", _stars)
	title_label = head.find_child("Title", true, false) as Label
	column.add_child(head)
	stars_label = ScreenKit.text("", 13.0, "words", "card_lit", true, true)
	next_label = ScreenKit.text("", 17.0, "words", "card_lit", false, true)
	_bar = ScreenMeter.bar(0, 1, Color("#F2B43C"), 12.0)
	var strip := HBoxContainer.new()
	strip.add_theme_constant_override("separation", UI.px(10))
	_tier = ScreenMeter.ring(0, 1, Color("#F2B43C"), 56.0, "")
	strip.add_child(_tier)
	var words := VBoxContainer.new()
	words.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	words.add_theme_constant_override("separation", UI.px(4))
	words.alignment = BoxContainer.ALIGNMENT_CENTER
	words.add_child(next_label)
	words.add_child(_bar)
	words.add_child(stars_label)
	strip.add_child(words)
	column.add_child(ScreenKit.panel("card_lit", strip, 18.0, 12.0))
	status_label = UI.status("info", "")
	column.add_child(ScreenParts.status_plate(status_label))
	body = UI.scroll(column)
	claim_button = ScreenKit.button(Strings.t("TRACK_CLAIM"), controller.claim, "gold")
	premium_button = ScreenKit.button(Strings.t("TRACK_PREMIUM"), _buy_premium, "leather")
	column.add_child(ScreenNav.dock(&"home", [claim_button, premium_button]))


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
		ScreenParts.show_status(status_label)
		claim_button.disabled = true
		premium_button.visible = false
		return
	title_label.text = t["title"]
	stars_label.text = t["stars"]
	next_label.text = t["next"]
	ScreenParts.set_pill(_stars, ShopPresenter.grouped(int(t["stars_n"])))
	_tier.middle = str(int(t["claimed_n"]))
	_tier.most = maxf(float((t["rows"] as Array).size()), 1.0)
	_tier.set_value(int(t["claimed_n"]))
	_tier.accessibility_name = Strings.t("SCREEN_TIERS_CLAIMED", [int(t["claimed_n"]), (t["rows"] as Array).size()])
	_bar.visible = int(t["next_cost"]) > 0
	_bar.most = maxf(float(t["next_cost"]), 1.0)
	_bar.set_value(mini(int(t["stars_n"]), int(t["next_cost"])))
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
	ScreenParts.show_status(status_label)
	for c in body.get_children():
		c.queue_free()
	var lanes := HBoxContainer.new()
	lanes.add_theme_constant_override("separation", UI.px(8))
	for key: String in ["SCREEN_FREE_LANE", "", "SCREEN_STARPASS_LANE"]:
		var l := ScreenKit.text(Strings.t(key) if key != "" else "", 13.0, "words", "card", true)
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		l.size_flags_horizontal = Control.SIZE_EXPAND_FILL if key != "" else Control.SIZE_SHRINK_CENTER
		l.custom_minimum_size.x = 0 if key != "" else UI.px(44)
		lanes.add_child(l)
	body.add_child(lanes)
	for row: Dictionary in t["rows"]:
		body.add_child(_tier_row(row, bool(t["premium"])))


## One tier on the road: the free reward, the tier's node, and the
## Starpass reward, locked while the pass is not held; claimed tiers carry
## a tick, the next one is lit.
func _tier_row(row: Dictionary, premium: bool) -> Control:
	var state := str(row["state"])
	var r := HBoxContainer.new()
	r.add_theme_constant_override("separation", UI.px(8))
	var free := _reward(row["free"], row["free_mark"], state, false)
	r.add_child(free)
	var node := ScreenKit.text(str(int(row["tier"])), 17.0, "number", "gold" if state != "later" else "well")
	node.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var plate := ScreenKit.panel("gold" if state != "later" else "well", node, -1.0, 4.0)
	plate.custom_minimum_size = Vector2(UI.px(44), UI.px(44))
	plate.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	r.add_child(plate)
	r.add_child(_reward(row["paid"], row["paid_mark"], state, not premium and row["paid"] != ""))
	var words := ScreenKit.text(row["text"], 13.0, "body", "card", true, true)
	words.visible = false
	var box := VBoxContainer.new()
	box.add_child(r)
	box.add_child(words)
	if state == "claimed":
		box.modulate = Color(1, 1, 1, 0.92)
	return box


## A reward card: its mark and words, a tick once claimed, a lock while the
## Starpass is not held; an empty lane where the tier gives nothing there.
func _reward(words: String, mark: Array, state: String, locked: bool) -> Control:
	var col := HBoxContainer.new()
	col.add_theme_constant_override("separation", UI.px(6))
	if words == "":
		var empty := Control.new()
		empty.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		return empty
	var material := "card_lit" if state == "next" else ("cream" if state == "claimed" else "card")
	if mark.size() == 2:
		if mark[0] == "coin":
			col.add_child(ScreenCoin.make(str(mark[1]), 28.0))
		else:
			col.add_child(ScreenKit.icon(str(mark[0]), str(mark[1]), 30.0))
	var l := ScreenKit.text(words, 13.0, "words", material, false, true)
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	col.add_child(l)
	if state == "claimed":
		col.add_child(ScreenKit.icon("generalui", "confirm", 22.0))
	elif locked:
		col.add_child(ScreenKit.icon("generalui", "lock", 22.0))
	var p := ScreenKit.panel(material, col, 14.0, 8.0)
	p.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return p
