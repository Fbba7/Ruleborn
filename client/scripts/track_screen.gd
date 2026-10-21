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
var _strip: HBoxContainer
var _pass: HBoxContainer
var _pass_card: PanelContainer


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
	status_label = UI.status("info", "")
	column.add_child(ScreenParts.status_plate(status_label))
	body = UI.scroll(column)
	stars_label = ScreenKit.text("", 13.0, "words", "card_lit", true, true)
	next_label = ScreenKit.text("", 17.0, "words", "card_lit", false, true)
	_bar = ScreenMeter.bar(0, 1, Color("#F2B43C"), 12.0)
	_tier = ScreenMeter.ring(0, 1, Color("#F2B43C"), 56.0, "")
	_strip = HBoxContainer.new()
	_strip.add_theme_constant_override("separation", UI.px(10))
	_strip.add_child(_tier)
	var words := VBoxContainer.new()
	words.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	words.add_theme_constant_override("separation", UI.px(4))
	words.alignment = BoxContainer.ALIGNMENT_CENTER
	words.add_child(next_label)
	words.add_child(_bar)
	words.add_child(stars_label)
	_strip.add_child(words)
	_pass = HBoxContainer.new()
	_pass.add_theme_constant_override("separation", UI.px(10))
	_pass.add_child(ScreenKit.icon("season", "premiumtrack", 40.0))
	var pass_words := VBoxContainer.new()
	pass_words.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	pass_words.alignment = BoxContainer.ALIGNMENT_CENTER
	pass_words.add_child(ScreenKit.text(Strings.t("SCREEN_STARPASS_LANE"), 17.0, "number", "card_lit"))
	pass_words.add_child(ScreenKit.text(Strings.t("SCREEN_STARPASS_LINE"), 13.0, "words", "card_lit", true, true))
	_pass.add_child(pass_words)
	premium_button = ScreenKit.button(Strings.t("TRACK_PREMIUM"), _buy_premium, "gold", "", 14.0)
	premium_button.size_flags_horizontal = Control.SIZE_SHRINK_END
	premium_button.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	premium_button.tooltip_text = Strings.t("TRACK_PREMIUM")
	_pass.add_child(premium_button)
	_pass_card = ScreenKit.panel("card_lit", _pass, 18.0, 10.0)
	column.add_child(_pass_card)
	claim_button = ScreenKit.button(Strings.t("TRACK_CLAIM"), controller.claim, "green")
	column.add_child(ScreenNav.dock(&"home", [claim_button]))


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
	# The price on the gold button, as the design's Starpass bar; the button
	# is named in full for a screen reader.
	var price := ShopPresenter.money(t["premium_price"], App.services.purchases.price(t["premium_product"]))
	UI.relabel(premium_button, price)
	premium_button.accessibility_name = Strings.t("TRACK_PREMIUM_PRICE", price)
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
	_pass_card.visible = premium_button.visible
	if _strip.get_parent() != null:
		_strip.get_parent().remove_child(_strip)
	for c in body.get_children():
		c.queue_free()
	body.add_child(ScreenParts.segmented([{"text": Strings.t("SCREEN_PASS"), "key": "pass", "on": true},
		{"text": Strings.t("SCREEN_LEAGUE"), "key": "league", "on": false}], func(key: String) -> void:
			if key == "league":
				App.services.router.go(&"social")))
	body.add_child(ScreenKit.panel("card_lit", _strip, 18.0, 12.0))
	body.add_child(_road(t["rows"], bool(t["premium"])))


## The design's track: one column a tier, the Starpass reward over the
## tier's node on the road and the free reward under it, scrolled sideways,
## the next tier lit; the lanes named at their start.
func _road(rows: Array, premium: bool) -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", UI.px(8))
	var lanes := VBoxContainer.new()
	lanes.add_theme_constant_override("separation", UI.px(8))
	for key: String in ["SCREEN_STARPASS_LANE", "", "SCREEN_FREE_LANE"]:
		var tag: Control
		if key == "":
			tag = Control.new()
			tag.custom_minimum_size = Vector2(UI.px(20), UI.px(44))
		else:
			var l := ScreenKit.text(Strings.t(key), 13.0, "words", "active" if key != "SCREEN_FREE_LANE" else "card")
			tag = ScreenKit.panel("tab_active" if key != "SCREEN_FREE_LANE" else "card", l, 10.0, 4.0)
			tag.size_flags_vertical = Control.SIZE_EXPAND_FILL
		lanes.add_child(tag)
	row.add_child(lanes)
	for r: Dictionary in rows:
		row.add_child(_tier_row(r, premium))
	var strip := ScrollContainer.new()
	strip.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	strip.custom_minimum_size.y = row.get_combined_minimum_size().y + UI.px(10)
	strip.add_child(row)
	# Open at the next tier, as the design does.
	strip.ready.connect(func() -> void:
		var at := 0
		for r: Dictionary in rows:
			if r["state"] == "next":
				at = int(r["tier"])
		strip.set_deferred("scroll_horizontal", maxi(0, (at - 2) * UI.px(112))))
	return strip


## One tier on the road: the Starpass reward, locked while the pass is not
## held; the tier's node; the free reward. Claimed tiers carry a tick, the
## next one is lit.
func _tier_row(row: Dictionary, premium: bool) -> Control:
	var state := str(row["state"])
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", UI.px(8))
	col.custom_minimum_size.x = UI.px(104)
	col.add_child(_reward(row["paid"], row["paid_mark"], state, not premium and row["paid"] != ""))
	var node := ScreenKit.text(str(int(row["tier"])), 17.0, "number", "gold" if state != "later" else "well")
	node.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	node.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	var plate := ScreenKit.panel("gold" if state != "later" else "well", node, -1.0, 2.0)
	plate.custom_minimum_size = Vector2(UI.px(44), UI.px(44))
	plate.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	if state == "next":
		RbBox.of(plate).set_chosen(true)
	col.add_child(plate)
	col.add_child(_reward(row["free"], row["free_mark"], state, false))
	col.tooltip_text = row["text"]
	return col


## A reward card: its mark over its words, a tick once claimed, a lock
## while the Starpass is not held; an empty slot where the tier gives
## nothing in that lane.
func _reward(words: String, mark: Array, state: String, locked: bool) -> Control:
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", UI.px(4))
	col.alignment = BoxContainer.ALIGNMENT_CENTER
	var material := "card_selected" if state == "next" else ("parchment" if state == "claimed" else "card")
	if words == "":
		var empty := ScreenKit.panel("track", null, 14.0, 4.0)
		empty.custom_minimum_size.y = UI.px(112)
		return empty
	var top := HBoxContainer.new()
	top.alignment = BoxContainer.ALIGNMENT_CENTER
	if mark.size() == 2:
		if mark[0] == "coin":
			top.add_child(ScreenCoin.make(str(mark[1]), 40.0))
		else:
			top.add_child(ScreenKit.icon(str(mark[0]), str(mark[1]), 44.0))
	col.add_child(top)
	var l := ScreenKit.text(words, 13.0, "words", material, false, true)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(l)
	if state == "claimed":
		var tick := ScreenKit.icon("generalui", "confirm", 22.0)
		tick.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		col.add_child(tick)
	elif locked:
		var lock := ScreenKit.icon("generalui", "lock", 22.0)
		lock.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		col.add_child(lock)
	var p := ScreenKit.panel(material, col, 14.0, 6.0)
	p.custom_minimum_size.y = UI.px(112)
	return p
