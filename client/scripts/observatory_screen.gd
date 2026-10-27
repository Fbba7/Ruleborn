class_name ObservatoryScreen
extends Control
## The Observatory (§12.3, §23.2, "Choose a target"): a Trace first and
## apart, then the offered universes as their free target cards, each with
## its fee and why it was offered, and the paid refresh. A card opens its
## scout report. Each card leads with a picture of its universe — the Heart
## at its realm level and the other realms around it, bare — drawn by one
## shared offscreen world (`StageThumbs`), never a 3D view per card.

## How far a swipe goes before it turns the deck a card.
const SWIPE_POINTS := 40.0
## The sliver of the next card that peeks in at the deck's edge.
const PEEK_POINTS := 10.0
const PICTURE_POINTS := 150.0

var controller: ObservatoryController
var body: VBoxContainer
var header_label: Label
var status_label: Label
var thumbs: StageThumbs
## Each card's picture, by its key, while it waits to be drawn.
var _pictures := {}
var _row: HBoxContainer
var _peek: Control
var _notes: VBoxContainer
var _dock: HFlowContainer
var _pager: HBoxContainer
## The card on show, and the deck's cards, one shown at a time.
var _page := 0
var _cards: Array[Control] = []
var _swipe := 0.0
var _turned := false


func _ready() -> void:
	App.ready(self)
	controller = App.services.observatory_flow
	_build()
	App.services.store.changed.connect(_on_changed)
	_refresh()
	await controller.load_observatory()


func _on_changed(slice: StringName) -> void:
	if slice == ObservatoryState.OBSERVATORY and is_inside_tree():
		_refresh()


func _build() -> void:
	var column := UI.frame(self)
	StageScreen.night_sky(self)
	thumbs = StageThumbs.new()
	add_child(thumbs)
	thumbs.drawn.connect(_on_drawn)
	var heading := OverlayTop.bar(func() -> void: App.services.router.go(&"home"), "", Strings.t("OBS_TITLE"))
	header_label = heading.find_child("Kicker", true, false) as Label
	(heading.find_child("Title", true, false) as Label).add_theme_font_size_override("font_size", UI.text_px(26))
	# New targets on the heading's right, as the design's refresh chip: not
	# a key the player reaches for often.
	_dock = HFlowContainer.new()
	_dock.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	heading.add_child(_dock)
	column.add_child(heading)
	status_label = UI.status("info", "")
	status_label.add_theme_font_size_override("font_size", UI.text_px(13))
	status_label.set_meta("points", 13.0)
	column.add_child(UI.plate(status_label, "glass"))
	# The deck, as the design's: one card on show with the next peeking in,
	# swiped across or turned by the keys under it in the thumb's reach. One
	# card at a time, so the deck is never wider than the phone.
	# A tall card (large text) scrolls up and down within the deck.
	var deck := ScrollContainer.new()
	deck.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	deck.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body = VBoxContainer.new()
	body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.mouse_filter = Control.MOUSE_FILTER_PASS
	body.gui_input.connect(_on_deck_input)
	_row = HBoxContainer.new()
	_row.add_theme_constant_override("separation", UI.px(6))
	body.add_child(_row)
	deck.add_child(body)
	column.add_child(deck)
	# The notes under the cards, scrolled with them.
	_notes = VBoxContainer.new()
	body.add_child(_notes)
	_pager = HBoxContainer.new()
	_pager.alignment = BoxContainer.ALIGNMENT_CENTER
	_pager.add_theme_constant_override("separation", UI.px(14))
	column.add_child(_pager)
	StageScreen.corner_gap(column)


func _refresh() -> void:
	if not is_inside_tree():
		return
	var o := ObservatoryPresenter.screen(App.services.store.get_slice(ObservatoryState.OBSERVATORY))
	if o["error"] != "":
		UI.set_status(status_label, "alarm", o["error"])
	elif o["busy"] != "" or not o["ready"]:
		UI.set_status(status_label, "info", Strings.t("COMMON_LOADING"))
	else:
		UI.set_status(status_label, "info", o.get("protected", ""))
	(status_label.get_parent() as Control).visible = status_label.text != ""
	header_label.text = str(o.get("header", "")).to_upper()
	for holder: Node in [_row, _notes, _dock, _pager]:
		for child: Node in holder.get_children():
			holder.remove_child(child)
			child.queue_free()
	_cards.clear()
	if not o["ready"]:
		return
	var busy: bool = o["busy"] != ""
	if not (o["trace"] as Dictionary).is_empty():
		_cards.append(_card(o["trace"], busy))
	for c: Dictionary in o["cards"]:
		_cards.append(_card(c, busy))
	for card: Control in _cards:
		_row.add_child(card)
	_peek = UI.panel("parchment")
	_peek.custom_minimum_size.x = UI.px(PEEK_POINTS)
	_peek.size_flags_vertical = Control.SIZE_FILL
	_peek.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_row.add_child(_peek)
	_build_pager()
	_show_page(_page)
	for note: String in ["wanderer", "fallback", "empty"]:
		if o.get(note, "") != "":
			var p := OverlayHud.pill("generalui/info", o[note], o[note], "glass")
			var words := p.find_child("Words", true, false) as Label
			words.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			words.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			words.add_theme_font_size_override("font_size", UI.text_px(13))
			_notes.add_child(p)
	var r: Dictionary = o["refresh"]
	var view: Dictionary = App.services.store.get_slice(ObservatoryState.OBSERVATORY).get("view", {})
	var cost := ShopPresenter.grouped(int((view.get("refresh", {}) as Dictionary).get("aether", 0)))
	# The chip says its price beside the refresh mark; its words are spoken.
	var b := UI.action("↻ " + cost, controller.refresh, "leather", r["spoken"])
	b.set_meta("frequent", false)
	b.disabled = busy or not r["can"]
	b.set_meta("key", r["key"])
	b.set_meta("item", r["item"])
	b.icon = Icons.texture("resources/aether")
	b.add_theme_constant_override("icon_max_width", UI.px(20))
	b.tooltip_text = r["why"]
	b.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_dock.add_child(b)


## A target card, as the design's: its universe's picture under a ribbon
## that says a Trace or an echo, the Keeper's level on a badge by its name,
## its size and Renown, the rough loot and depth on two tiles, why it was
## offered, its realm's counts, the fee, and the gold Scout key. The card's
## lines are what a screen reader says for it.
func _card(c: Dictionary, busy: bool) -> Control:
	var raw: Dictionary = c["card"]
	var panel := UI.panel("parchment")
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	panel.accessibility_description = "\n".join(c["lines"])
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", UI.px(6))
	panel.add_child(box)
	# The picture, with the ribbon over its corner: a plain holder, so the
	# ribbon keeps its own size.
	var holder := Control.new()
	holder.custom_minimum_size = Vector2(0, UI.px(PICTURE_POINTS))
	holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var picture := _picture(raw)
	picture.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	holder.add_child(picture)
	var ribbon := _ribbon(str(c["kind"]))
	if ribbon != null:
		holder.add_child(ribbon)
	box.add_child(holder)
	var who := HBoxContainer.new()
	who.add_theme_constant_override("separation", UI.px(8))
	who.add_child(OverlayHud.medallion("screens/universe",
		int(raw["keeper_level"]) if raw.get("keeper_level") != null else -1, 46.0))
	var title := UI.label(c["title"], 17.0, true)
	title.theme_type_variation = "Heading"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.set_meta("kind", c["kind"])
	who.add_child(title)
	box.add_child(who)
	# A flow, so at §20.8's large text the tiles stack rather than widen.
	var tiles := HFlowContainer.new()
	tiles.add_theme_constant_override("h_separation", UI.px(6))
	tiles.add_theme_constant_override("v_separation", UI.px(6))
	tiles.add_child(_tile(Strings.t("OBS_TILE_LOOT"), "~" + ShopPresenter.grouped(int(raw.get("loot", 0)))))
	var depth := int(raw.get("depth", 0))
	tiles.add_child(_tile(Strings.t("OBS_TILE_DEPTH"), Strings.t("OBS_TILE_DEPTH_N", depth) if depth > 0
		else UniversePresenter.realm_name("Heart")))
	box.add_child(tiles)
	var facts: Array[Control] = OverlayFacts.universe(raw, c["lines"], false)
	var realm: Dictionary = raw.get("realm", {})
	facts.append(OverlayHud.pill("hud/strain", str((realm.get("laws", []) as Array).size()), "", "card"))
	facts.append(OverlayHud.pill("crewroles/warden", str(ObservatoryPresenter.total(realm.get("guards", {}))), "",
		"card"))
	facts.append(OverlayHud.pill("hud/shield", str(ObservatoryPresenter.total(realm.get("wards", {}))), "", "card"))
	box.add_child(OverlayHud.row_of(facts))
	if str(c["kind"]) != "trace":
		box.add_child(UI.label((c["lines"] as Array)[-1], 13.0, true))
	box.add_child(UI.label(ObservatoryPresenter.fee(raw), 13.0, true))
	var b := UI.action(c["action"], controller.choose.bind(str(c["bundle"])), "gold", c["spoken"])
	b.disabled = busy or not c["can"]
	b.set_meta("key", c["key"])
	b.set_meta("item", c["item"])
	b.icon = Icons.texture("planningactions/scout")
	b.add_theme_constant_override("icon_max_width", UI.px(22))
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.add_child(b)
	return panel


## The keys that turn the deck, with a dot for each card between them.
func _build_pager() -> void:
	if _cards.size() < 2:
		return
	_pager.add_child(_turn_key(-1))
	var dots := HBoxContainer.new()
	dots.add_theme_constant_override("separation", UI.px(6))
	dots.alignment = BoxContainer.ALIGNMENT_CENTER
	dots.name = "Dots"
	for i: int in _cards.size():
		var dot := PanelContainer.new()
		dot.add_theme_stylebox_override("panel", UI.clear_box(0, 0))
		dot.mouse_filter = Control.MOUSE_FILTER_IGNORE
		dot.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		dots.add_child(dot)
	_pager.add_child(dots)
	_pager.add_child(_turn_key(1))


func _turn_key(step: int) -> Button:
	var b := UI.action("", func() -> void: _show_page(_page + step), "leather",
		Strings.t("OBS_NEXT_CARD" if step > 0 else "OBS_PREV_CARD"))
	b.custom_minimum_size = Vector2.ONE * UI.px(48)
	UI.dress(b, "leather", 24.0)
	var middle := CenterContainer.new()
	middle.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	middle.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var mark := Icons.view("generalui/back", 24.0)
	mark.flip_h = step > 0
	middle.add_child(mark)
	b.add_child(middle)
	b.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	b.set_meta("step", step)
	return b


## Show the card at `page`, kept within the deck: the dots say which, the
## keys at either end of the deck go grey.
func _show_page(page: int) -> void:
	_page = clampi(page, 0, maxi(0, _cards.size() - 1))
	for i: int in _cards.size():
		_cards[i].visible = i == _page
	if _peek != null:
		_peek.visible = _page < _cards.size() - 1
	var dots := _pager.find_child("Dots", false, false)
	if dots != null:
		for i: int in dots.get_child_count():
			var dot := dots.get_child(i) as PanelContainer
			var on := i == _page
			dot.custom_minimum_size = Vector2(UI.px(22 if on else 9), UI.px(9))
			UI.dress(dot, "gold" if on else "glass", 99.0)
		(dots as Control).accessibility_name = Strings.t("OBS_PAGE", [_page + 1, _cards.size()])
	for b: Node in _pager.get_children():
		if b is Button:
			var step := int(b.get_meta("step", 0))
			(b as Button).disabled = _page + step < 0 or _page + step >= _cards.size()


## A sideways swipe on the deck turns it, the design's carousel.
func _on_deck_input(event: InputEvent) -> void:
	var dx := 0.0
	if event is InputEventScreenDrag:
		dx = (event as InputEventScreenDrag).relative.x
	elif event is InputEventMouseMotion and (event as InputEventMouseMotion).button_mask & MOUSE_BUTTON_MASK_LEFT:
		dx = (event as InputEventMouseMotion).relative.x
	elif (event is InputEventScreenTouch or event is InputEventMouseButton) and not event.is_pressed():
		_swipe = 0.0
		_turned = false
		return
	_swipe += dx
	# One card per swipe, however long the drag.
	if not _turned and absf(_swipe) >= UI.px(SWIPE_POINTS):
		_show_page(_page + (1 if _swipe < 0 else -1))
		_turned = true


## A tile on the card: a small name over a value in the number face.
func _tile(name: String, value: String) -> Control:
	var tile := UI.panel("parchment")
	tile.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var words := VBoxContainer.new()
	words.add_theme_constant_override("separation", 0)
	var n := UI.label(name, 13.0, true)
	n.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	words.add_child(n)
	var v := UI.label(value, 18.0, true)
	v.add_theme_font_override("font", Tokens.font("display"))
	v.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	words.add_child(v)
	tile.add_child(words)
	return tile


## The corner ribbon: a Trace in gold, an echo in violet, the game's own
## island on leather; a player's card has none.
func _ribbon(kind: String) -> Control:
	var looks := {"trace": ["OBS_RIBBON_TRACE", "gold"], "echo": ["OBS_RIBBON_ECHO", "round_violet"],
		"generated": ["OBS_RIBBON_GENERATED", "leather"]}
	if not looks.has(kind):
		return null
	var tag := OverlayHud.pill("", Strings.t(looks[kind][0]).to_upper(), "", looks[kind][1])
	tag.anchor_left = 1.0
	tag.anchor_right = 1.0
	tag.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	tag.offset_right = -UI.px(8)
	tag.offset_top = UI.px(8)
	tag.rotation_degrees = 0.0
	return tag


## The card's universe in a frame, filled in when the shared world has drawn
## it.
func _picture(card: Dictionary) -> Control:
	var frame := PanelContainer.new()
	var box := OverlaySheet.night(OverlaySheet.CONTROL_CORNER)
	box.set_content_margin_all(UI.px(1))
	frame.add_theme_stylebox_override("panel", box)
	frame.set_meta("dressed", true)
	frame.clip_contents = true
	var stars := TextureRect.new()
	stars.texture = StageScreen.night_texture()
	stars.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	stars.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	stars.mouse_filter = Control.MOUSE_FILTER_IGNORE
	frame.add_child(stars)
	var rect := TextureRect.new()
	rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	rect.custom_minimum_size = Vector2(0, UI.px(PICTURE_POINTS))
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	frame.add_child(rect)
	var key := StageThumbs.key_of(card)
	_pictures[key] = rect
	rect.texture = thumbs.picture(card)
	return frame


func _on_drawn(key: String, texture: Texture2D) -> void:
	var rect := _pictures.get(key) as TextureRect
	if rect != null and is_instance_valid(rect):
		rect.texture = texture
