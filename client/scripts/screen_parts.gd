class_name ScreenParts
extends RefCounted
## The design's small repeated pieces (§21.8), built on ScreenKit's surfaces:
## pills and tags, filter chips, count badges, a segmented control, section
## headings, stat tiles and list rows. Information is shown as these, with
## icons and counts, never as a sentence listing data.


## A law's frame by its rank (§7.6, the design's oak, silver, gold and
## prismatic frames); the rank is always written too.
const RANK_FRAME := {"Common": "oak", "Uncommon": "silver", "Rare": "goldframe", "Deep": "prism"}


## A pill: an optional icon from the design's set, then its words.
static func pill(words: String, material := "glass", group := "", name := "", points := 13.0,
		role := "words", wraps := false) -> PanelContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", UI.px(4))
	if group != "" and ScreenKit.icon_key(group, name) != "":
		row.add_child(ScreenKit.icon(group, name, points + 5.0))
	var l := ScreenKit.text(words, points, role, material, false, wraps)
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	if wraps:
		l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(l)
	var p := ScreenKit.panel(material, row, 14.0 if wraps else -1.0, 4.0)
	var b := p.get_theme_stylebox("panel")
	b.content_margin_left = UI.px(9)
	b.content_margin_right = UI.px(10)
	b.content_margin_top = UI.px(2)
	b.content_margin_bottom = UI.px(2)
	p.size_flags_horizontal = Control.SIZE_FILL if wraps else Control.SIZE_SHRINK_BEGIN
	p.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	return p


## A filter chip (T9's): gold when chosen, glass when not, 48 points to
## tap. A `lead` control (a school's mark) or an icon goes before its words.
static func chip(words: String, on: bool, pressed: Callable, group := "", name := "", spoken := "",
		lead: Control = null) -> Button:
	var b := KitControls.chip(words if lead == null else "", on, pressed)
	b.accessibility_name = spoken if spoken != "" else words
	b.add_theme_font_override("font", ScreenKit.font("words"))
	var tex := ScreenKit.icon_texture(group, name) if group != "" else null
	if tex != null:
		b.icon = tex
		b.expand_icon = true
		b.add_theme_constant_override("icon_max_width", UI.px(22))
	b.set_meta("on", on)
	if lead != null:
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", UI.px(5))
		row.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.alignment = BoxContainer.ALIGNMENT_CENTER
		row.set_anchors_preset(Control.PRESET_FULL_RECT)
		lead.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		row.add_child(lead)
		var l := ScreenKit.text(words, 16.0, "words", "cream" if on else "glass")
		l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		row.add_child(l)
		b.add_child(row)
		b.custom_minimum_size.x = maxf(UI.CONTROL_POINTS * UI.PX_PER_POINT,
			row.get_combined_minimum_size().x + UI.px(28))
	else:
		UI.fit(b)
		if b.icon != null:
			b.custom_minimum_size.x += UI.px(26)
	return b


## A count on T9's red badge; the number is always the words.
static func badge(words: String) -> PanelContainer:
	return KitStatus.badge(words)


## A gold segmented control (T9's): options are {text, key, on}; `pressed`
## is called with the chosen option's key.
static func segmented(options: Array, pressed: Callable) -> PanelContainer:
	var words: Array = []
	var chosen := 0
	for i: int in options.size():
		words.append(str((options[i] as Dictionary)["text"]))
		if (options[i] as Dictionary).get("on", false):
			chosen = i
	return KitNav.segmented(words, chosen, func(i: int) -> void: pressed.call((options[i] as Dictionary)["key"]))


## A section's heading: a short kicker in capitals in gold, and an optional
## count or note at its right.
static func section(words: String, right := "") -> VBoxContainer:
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", UI.px(2))
	var row := HBoxContainer.new()
	var l := ScreenKit.text(words.to_upper(), 13.0, "words", "card", true, true)
	l.theme_type_variation = "Kicker"
	l.add_theme_color_override("font_color", Tokens.color("gold"))
	l.add_theme_constant_override("line_spacing", 0)
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(l)
	if right != "":
		var r := ScreenKit.text(right, 13.0, "words", "card", true)
		r.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		row.add_child(r)
	row.add_theme_constant_override("separation", UI.px(8))
	var inset := MarginContainer.new()
	inset.add_theme_constant_override("margin_right", UI.px(8))
	inset.add_child(row)
	box.add_child(inset)
	return box


## A stat tile: an icon, a big number in Lilita One, and what it counts.
static func stat(number: String, words: String, group := "", name := "", material := "card") -> PanelContainer:
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 0)
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	if group != "" and ScreenKit.icon_key(group, name) != "":
		var i := ScreenKit.icon(group, name, 26.0)
		i.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		box.add_child(i)
	var n := ScreenKit.text(number, 24.0, "number", material)
	n.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(n)
	var w := ScreenKit.text(words, 13.0, "words", material, true, true)
	w.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(w)
	var p := ScreenKit.panel(material, box, 14.0, 8.0)
	p.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return p


## A list row: an icon on a round plate, a title and a line under it, and
## whatever control sits at its right.
static func item(group: String, name: String, title: String, sub := "", right: Control = null,
		material := "card") -> PanelContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", UI.px(10))
	if group != "":
		var disc := ScreenKit.panel("well", ScreenKit.icon(group, name, 28.0), -1.0, 4.0)
		disc.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		row.add_child(disc)
	var words := VBoxContainer.new()
	words.add_theme_constant_override("separation", 0)
	words.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	words.alignment = BoxContainer.ALIGNMENT_CENTER
	words.add_child(ScreenKit.text(title, 15.0, "words", material, false, true))
	if sub != "":
		words.add_child(ScreenKit.text(sub, 13.0, "body", material, true, true))
	row.add_child(words)
	if right != null:
		right.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		row.add_child(right)
	return ScreenKit.panel(material, row, 16.0, 10.0)


## A horizontal row of pieces that wraps at large text.
static func flow(separation := 6.0) -> HFlowContainer:
	var r := HFlowContainer.new()
	r.add_theme_constant_override("h_separation", UI.px(separation))
	r.add_theme_constant_override("v_separation", UI.px(separation))
	return r


## A row that lays its children side by side, each given an equal share;
## stacked instead at large text, where side by side they would not fit.
static func columns(children: Array, separation := 8.0) -> BoxContainer:
	var r: BoxContainer = VBoxContainer.new()
	if Settings.text_scale <= 125:
		r = HBoxContainer.new()
	r.add_theme_constant_override("separation", UI.px(separation))
	for c: Control in children:
		c.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		r.add_child(c)
	return r


## A resource's amount on a glass pill, led by its mark.
static func resource(kind: String, amount: String, points := 15.0) -> PanelContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", UI.px(5))
	row.add_child(ScreenCoin.make(kind, points + 7.0))
	var l := ScreenKit.text(amount, points, "words", "well")
	l.name = "Amount"
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	row.add_child(l)
	var p := ScreenKit.panel("well", row, -1.0, 3.0)
	var b := p.get_theme_stylebox("panel")
	b.content_margin_left = UI.px(4)
	b.content_margin_right = UI.px(12)
	p.size_flags_horizontal = Control.SIZE_SHRINK_END
	p.visible = amount != ""
	return p


static func set_resource(p: PanelContainer, amount: String) -> void:
	var l := p.find_child("Amount", true, false) as Label
	if l != null:
		l.text = amount
	p.visible = amount != ""


## The plate a screen's status words sit on; hidden while they say nothing.
static func status_plate(words: Label) -> PanelContainer:
	words.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	# §21.8: an alarm or a success in words on parchment is bold.
	words.add_theme_font_override("font", ScreenKit.font("words"))
	words.set_meta("bold", true)
	var p := ScreenKit.panel("parchment", words, 14.0, 8.0)
	p.name = "Status"
	return p


## Shows a status's plate only while it has words.
static func show_status(words: Label) -> void:
	var p := words.get_parent() as Control
	if p != null:
		p.visible = words.text != ""


## Columns for a grid of tiles: `most` at normal text, fewer as §20.8's large
## text makes each tile's words wider.
static func grid_columns(most: int) -> int:
	if Settings.text_scale > 150:
		return maxi(1, most - 2)
	if Settings.text_scale > 110:
		return maxi(1, most - 1)
	return most


## Makes a whole panel one control: a flat button over it, named for a screen
## reader, with the keys a screen finds it by.
static func tap(panel: PanelContainer, pressed: Callable, spoken: String, key := "", id := "") -> Button:
	var b := UI.action("", pressed, "ghost", spoken)
	var box := RbBox.of(b)
	if box != null:
		box.visible = false
	b.custom_minimum_size = Vector2.ZERO
	b.set_meta("key", key)
	b.set_meta("item", id)
	panel.add_child(b)
	return b


## Gives every label under `node` the words of `material`.
static func recolour(node: Node, material: String) -> void:
	for l: Label in node.find_children("*", "Label", true, false):
		l.add_theme_color_override("font_color", ScreenKit.ink(material, false))


## New words on a pill made by `pill`.
static func set_pill(p: PanelContainer, words: String) -> void:
	for l: Label in p.find_children("*", "Label", true, false):
		l.text = words
	p.visible = words != ""


## Stops drawing `view` (a 3D preview the screen wants shown, meta
## "wanted") while less than `share` of it is in the list's view: a world
## drawn behind a sliver costs its full draw calls (§21.3's 150) and the
## phone's time for nothing.
static func cull(view: Control, list: Control, share := 0.5) -> void:
	var scroll := list.get_parent() as ScrollContainer
	if scroll == null:
		return
	var check := func(_v: float = 0.0) -> void:
		if not is_instance_valid(view) or not view.is_inside_tree() or view.get_parent() == null:
			return
		var host := view.get_parent() as Control
		var seen := host.get_global_rect().intersection(scroll.get_global_rect())
		var wanted := bool(view.get_meta("wanted", true))
		var shown := wanted and (host.size.y <= 0.0 or seen.size.y >= host.size.y * share)
		if view.visible != shown:
			# The frame keeps the preview's height while it is not drawn, so
			# the list does not jump, and so it can be seen to come back.
			host.custom_minimum_size.y = view.get_combined_minimum_size().y if not shown else 0.0
			view.visible = shown
	scroll.get_v_scroll_bar().value_changed.connect(check)
	# The list moves under the scroll as it scrolls, whether a finger or the
	# code moved it.
	list.item_rect_changed.connect(check)
	view.tree_entered.connect(check.call_deferred)
