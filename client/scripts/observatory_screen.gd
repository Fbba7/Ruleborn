class_name ObservatoryScreen
extends Control
## The Observatory (§12.3, §23.2, "Choose a target"): a Trace first and
## apart, then the offered universes as their free target cards, each with
## its fee and why it was offered, and the paid refresh. A card opens its
## scout report. Each card leads with a picture of its universe — the Heart
## at its realm level and the other realms around it, bare — drawn by one
## shared offscreen world (`StageThumbs`), never a 3D view per card.

## A card's width: the next one peeks in at the phone's edge.
const CARD_POINTS := 300.0
const PICTURE_POINTS := 150.0

var controller: ObservatoryController
var body: VBoxContainer
var header_label: Label
var status_label: Label
var thumbs: StageThumbs
## Each card's picture, by its key, while it waits to be drawn.
var _pictures := {}
var _row: HBoxContainer
var _notes: VBoxContainer
var _dock: HFlowContainer


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
	var heading := OverlayHud.heading("", Strings.t("OBS_TITLE"))
	header_label = heading.find_child("Kicker", true, false) as Label
	(heading.find_child("Title", true, false) as Label).add_theme_font_size_override("font_size", UI.text_px(26))
	column.add_child(heading)
	status_label = UI.status("info", "")
	status_label.add_theme_font_size_override("font_size", UI.text_px(13))
	status_label.set_meta("points", 13.0)
	column.add_child(UI.plate(status_label, "glass"))
	# The deck: the cards side by side, swiped across, as the design's.
	var deck := ScrollContainer.new()
	deck.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	deck.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body = VBoxContainer.new()
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_row = HBoxContainer.new()
	_row.add_theme_constant_override("separation", UI.px(12))
	_row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_child(_row)
	deck.add_child(body)
	column.add_child(deck)
	_notes = VBoxContainer.new()
	column.add_child(_notes)
	_dock = HFlowContainer.new()
	_dock.alignment = FlowContainer.ALIGNMENT_CENTER
	_dock.add_theme_constant_override("h_separation", UI.px(12))
	column.add_child(_dock)


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
	for holder: Node in [_row, _notes, _dock]:
		for child: Node in holder.get_children():
			holder.remove_child(child)
			child.queue_free()
	_dock.add_child(OverlayHud.back_key(func() -> void: App.services.router.go(&"home")))
	if not o["ready"]:
		return
	var busy: bool = o["busy"] != ""
	if not (o["trace"] as Dictionary).is_empty():
		_row.add_child(_card(o["trace"], busy))
	for c: Dictionary in o["cards"]:
		_row.add_child(_card(c, busy))
	for note: String in ["wanderer", "fallback", "empty"]:
		if o.get(note, "") != "":
			var p := OverlayHud.pill("generalui/info", o[note], o[note], "glass")
			var words := p.find_child("Words", true, false) as Label
			words.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			words.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			words.add_theme_font_size_override("font_size", UI.text_px(13))
			_notes.add_child(p)
	var r: Dictionary = o["refresh"]
	var b := UI.action(r["action"], controller.refresh, "leather", r["spoken"])
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
	panel.custom_minimum_size.x = UI.px(CARD_POINTS)
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
	var tiles := HBoxContainer.new()
	tiles.add_theme_constant_override("separation", UI.px(6))
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
		var why := UI.label((c["lines"] as Array)[-1], 13.0, true)
		why.theme_type_variation = "Secondary"
		box.add_child(why)
	var fee := UI.label(ObservatoryPresenter.fee(raw), 13.0, true)
	fee.theme_type_variation = "Secondary"
	box.add_child(fee)
	var b := UI.action(c["action"], controller.choose.bind(str(c["bundle"])), "gold", c["spoken"])
	b.disabled = busy or not c["can"]
	b.set_meta("key", c["key"])
	b.set_meta("item", c["item"])
	b.icon = Icons.texture("planningactions/scout")
	b.add_theme_constant_override("icon_max_width", UI.px(22))
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.add_child(b)
	return panel


## A tile on the card: a small name over a value in the number face.
func _tile(name: String, value: String) -> Control:
	var tile := UI.panel("parchment")
	tile.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var words := VBoxContainer.new()
	words.add_theme_constant_override("separation", 0)
	var n := UI.label(name, 13.0)
	n.theme_type_variation = "Secondary"
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
	var looks := {"trace": ["OBS_RIBBON_TRACE", "gold"], "echo": ["OBS_RIBBON_ECHO", "tab_active"],
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
