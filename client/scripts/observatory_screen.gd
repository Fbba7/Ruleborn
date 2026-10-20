class_name ObservatoryScreen
extends Control
## The Observatory (§12.3, §23.2, "Choose a target"): a Trace first and
## apart, then the offered universes as their free target cards, each with
## its fee and why it was offered, and the paid refresh. A card opens its
## scout report. Each card leads with a picture of its universe — the Heart
## at its realm level and the other realms around it, bare — drawn by one
## shared offscreen world (`StageThumbs`), never a 3D view per card.

var controller: ObservatoryController
var body: VBoxContainer
var header_label: Label
var status_label: Label
var thumbs: StageThumbs
## Each card's picture, by its key, while it waits to be drawn.
var _pictures := {}


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
	header_label = UI.label("", UI.TEXT_POINTS, true)
	column.add_child(OverlaySheet.ribbon(UI.title(Strings.t("OBS_TITLE")), header_label))
	status_label = UI.status("info", "")
	column.add_child(UI.plate(status_label))
	body = UI.scroll(column)
	var actions := UI.row(-1.0, true)
	actions.add_child(UI.button(Strings.t("COMMON_HOME"), func() -> void: App.services.router.go(&"home"), true))
	column.add_child(UI.narrow(OverlaySheet.dock(actions)))
	OverlaySheet.dress(self)


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
	header_label.text = o.get("header", "")
	for child in body.get_children():
		body.remove_child(child)
		child.queue_free()
	if not o["ready"]:
		return
	var busy: bool = o["busy"] != ""
	if not (o["trace"] as Dictionary).is_empty():
		body.add_child(_card(o["trace"], busy))
	for note: String in ["wanderer", "fallback"]:
		if o.get(note, "") != "":
			body.add_child(UI.plate(UI.label(o[note], UI.TEXT_POINTS, true)))
	for c: Dictionary in o["cards"]:
		body.add_child(_card(c, busy))
	if o.has("empty"):
		body.add_child(UI.plate(UI.label(o["empty"], UI.TEXT_POINTS, true)))
	body.add_child(UI.plate(RosterScreen.offer(o["refresh"], busy, controller.refresh)))
	OverlaySheet.dress(body)
	OverlaySheet.unsqueeze(body)


func _card(c: Dictionary, busy: bool) -> Control:
	var box := VBoxContainer.new()
	box.add_child(_picture(c["card"]))
	var title := UI.label(c["title"], UI.TEXT_POINTS, true)
	title.set_meta("kind", c["kind"])
	box.add_child(title)
	for line: String in c["lines"]:
		box.add_child(UI.label(line, UI.TEXT_POINTS, true))
	box.add_child(RosterScreen.offer(c, busy, controller.choose.bind(str(c["bundle"]))))
	return UI.plate(box)


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
	rect.custom_minimum_size = Vector2(0, UI.px(130))
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
