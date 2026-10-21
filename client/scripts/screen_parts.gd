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
	if group != "" and ScreenKit.icon_path(group, name) != "":
		var i := ScreenKit.icon(group, name, points + 5.0)
		row.add_child(i)
	var l := ScreenKit.text(words, points, role, material, false, wraps)
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	if wraps:
		l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(l)
	var p := ScreenKit.panel(material, row, 14.0 if wraps else -1.0, 4.0)
	var b := p.get_theme_stylebox("panel") as ScreenBox
	b.content_margin_left = UI.px(9)
	b.content_margin_right = UI.px(10)
	b.content_margin_top = UI.px(2)
	b.content_margin_bottom = UI.px(2)
	p.size_flags_horizontal = Control.SIZE_FILL if wraps else Control.SIZE_SHRINK_BEGIN
	p.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	return p


## A filter chip: cream when chosen, glass when not, 48 points to tap. A
## `lead` control (a school's mark) goes before its words.
static func chip(words: String, on: bool, pressed: Callable, group := "", name := "", spoken := "",
		lead: Control = null) -> Button:
	var material := "cream" if on else "card"
	var b := ScreenKit.button(words if lead == null else "", pressed, material, spoken if spoken != "" else words,
		-1.0)
	if group != "":
		var path := ScreenKit.icon_path(group, name)
		if path != "":
			b.icon = load(path)
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
		var l := ScreenKit.text(words, 16.0, "words", material)
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


## A count on a small round plate: red for what needs the player, violet or
## green otherwise; the number is always the words.
static func badge(words: String, material := "red", points := 13.0) -> PanelContainer:
	var l := ScreenKit.text(words, points, "words", material)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var p := ScreenKit.panel(material, l, -1.0, 1.0)
	var b := p.get_theme_stylebox("panel") as ScreenBox
	b.content_margin_left = UI.px(6)
	b.content_margin_right = UI.px(6)
	b.drop_px = UI.px(1.0)
	p.custom_minimum_size = Vector2(UI.px(20), UI.px(20))
	p.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	p.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	return p


## A gold segmented control: one button per option, the chosen one gold and
## the rest flat in a dark well. Options are {text, key, on, spoken?}.
static func segmented(options: Array, pressed: Callable) -> PanelContainer:
	# At large text the segments' words may not fit side by side: they wrap
	# onto a second line rather than widen the screen.
	var row: Container = HFlowContainer.new()
	if Settings.text_scale <= 125:
		row = HBoxContainer.new()
	row.add_theme_constant_override("separation", UI.px(4))
	row.add_theme_constant_override("h_separation", UI.px(4))
	row.add_theme_constant_override("v_separation", UI.px(4))
	for o: Dictionary in options:
		var on := bool(o.get("on", false))
		var b := ScreenKit.button(str(o["text"]), pressed.bind(o["key"]), "gold" if on else "tab",
			str(o.get("spoken", "")), 12.0)
		if not on:
			var flat := ScreenKit.box("tab", 12.0, 8.0)
			flat.top = Color(0, 0, 0, 0)
			flat.bottom = Color(0, 0, 0, 0)
			b.add_theme_stylebox_override("normal", flat)
			b.set_meta("behind", ScreenKit.behind("well"))
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.set_meta("key", o["key"])
		b.set_meta("on", on)
		if on:
			b.accessibility_description = Strings.t("SCREEN_CHOSEN")
		row.add_child(b)
	var p := ScreenKit.panel("well", row, 16.0, 4.0)
	return p


## A section's heading: a short kicker in capitals, an optional count or
## note at its right, and an ink rule under it.
static func section(words: String, right := "") -> VBoxContainer:
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", UI.px(2))
	var row := HBoxContainer.new()
	var l := ScreenKit.text(words.to_upper(), 13.0, "words", "card", true, true)
	l.add_theme_constant_override("line_spacing", 0)
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(l)
	if right != "":
		var r := ScreenKit.text(right, 13.0, "words", "card", true)
		r.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		row.add_child(r)
	box.add_child(row)
	var rule := ColorRect.new()
	rule.color = Color("#E9B65C40")
	rule.custom_minimum_size = Vector2(0, maxf(1.0, UI.px(0.7)))
	rule.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(rule)
	return box


## A stat tile: an icon, a big number in Lilita One, and what it counts.
static func stat(number: String, words: String, group := "", name := "", material := "card") -> PanelContainer:
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 0)
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	if group != "" and ScreenKit.icon_path(group, name) != "":
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
	var l := ScreenKit.text(amount, points, "words", "glass")
	l.name = "Amount"
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	row.add_child(l)
	var p := ScreenKit.panel("glass", row, -1.0, 3.0)
	var b := p.get_theme_stylebox("panel") as ScreenBox
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
	var b := UI.button("", pressed, false, Color(), spoken)
	for state: String in ["normal", "hover", "pressed", "disabled"]:
		b.add_theme_stylebox_override(state, StyleBoxEmpty.new())
	var focus := ScreenBox.new()
	focus.top = Color(0, 0, 0, 0)
	focus.bottom = Color(0, 0, 0, 0)
	focus.rim = Color("#FFF3CC")
	focus.rim_px = UI.px(2.0)
	focus.radius = UI.px(12.0)
	b.add_theme_stylebox_override("focus", focus)
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
