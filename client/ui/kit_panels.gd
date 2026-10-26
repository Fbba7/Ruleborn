class_name KitPanels
## The kit's larger surfaces: section headings, list rows (a card with an
## icon, a title, a line under it and something at its end), bottom sheets
## and dialogs over a dimmed screen.


## A section's heading in Marcellus, set to the left of its list.
static func section(title: String) -> Label:
	var l := UI.label(title, float(Tokens.type_role("heading")["points"]), true)
	l.theme_type_variation = "Heading"
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	l.name = "Section"
	return l


## A list row: an icon (if named), a bold title and a secondary line, and
## `trailing` at its end. With `pressed` it is one 64-point button, named
## by its title; without, a card. `look` "seg" draws it flat, as a row
## inside a card.
static func row(icon: String, title: String, line := "", trailing: Control = null,
		pressed := Callable(), look := "card") -> Control:
	var host: Control
	if pressed.is_valid():
		var b := UI.action("", pressed, look, title)
		b.name = "Row"
		b.custom_minimum_size = Vector2(UI.px(120), UI.px(64))
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		host = b
	else:
		var p := UI.panel(look)
		p.name = "Row"
		p.custom_minimum_size.y = UI.px(64)
		host = p
	var content := HBoxContainer.new()
	content.add_theme_constant_override("separation", UI.px(10))
	content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if icon != "":
		content.add_child(Icons.view(icon, 36))
	var words := VBoxContainer.new()
	words.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	words.alignment = BoxContainer.ALIGNMENT_CENTER
	words.add_theme_constant_override("separation", 0)
	words.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var t := UI.label(title, 16, true)
	t.theme_type_variation = "BodyBold"
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	t.set_meta("bold", true)
	words.add_child(t)
	if line != "":
		var s := UI.label(line, 13, true)
		s.theme_type_variation = "Secondary"
		s.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		words.add_child(s)
	content.add_child(words)
	if trailing != null:
		trailing.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		content.add_child(trailing)
	if host is Button:
		var m := MarginContainer.new()
		m.set_anchors_preset(Control.PRESET_FULL_RECT)
		m.mouse_filter = Control.MOUSE_FILTER_IGNORE
		for side: String in ["margin_left", "margin_right"]:
			m.add_theme_constant_override(side, UI.px(12))
		m.add_child(content)
		host.add_child(m)
	else:
		host.add_child(content)
	return host


## A bottom sheet with a title: the designs' tray, sliding up over the
## screen, dark, or parchment as the designs' menu sheet. Its body is the
## VBox under meta "body".
static func sheet(title: String, look := "sheet") -> PanelContainer:
	var p := PanelContainer.new()
	p.name = "Sheet"
	p.add_theme_stylebox_override("panel", UI.clear_box(16, 10))
	UI.dress(p, look, 26)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", UI.px(8))
	var grip := ColorRect.new()
	grip.color = Color(Tokens.color("text_on_night_2"), 0.35)
	grip.custom_minimum_size = Vector2(UI.px(40), UI.px(4))
	grip.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	grip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_child(grip)
	var t := UI.label(title, float(Tokens.type_role("heading")["points"]), true)
	t.theme_type_variation = "Heading"
	v.add_child(t)
	var body := VBoxContainer.new()
	body.add_theme_constant_override("separation", UI.px(8))
	v.add_child(body)
	p.add_child(v)
	p.set_meta("body", body)
	p.ready.connect(func() -> void: Motion.sheet_in(p))
	return p


## A dialog over `host`: the screen dimmed behind, a card with a title,
## words and `actions` in the thumb's reach; it pops in. Closing it is the
## caller's (queue_free on what this returns).
static func dialog(host: Control, title: String, words: String, actions: Array) -> Control:
	var veil := Control.new()
	veil.name = "Dialog"
	veil.set_anchors_preset(Control.PRESET_FULL_RECT)
	veil.mouse_filter = Control.MOUSE_FILTER_STOP
	RbBox.dress(veil, "scrim", 0)
	var centre := CenterContainer.new()
	centre.set_anchors_preset(Control.PRESET_FULL_RECT)
	veil.add_child(centre)
	var card := UI.panel("card")
	card.custom_minimum_size.x = UI.px(300)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", UI.px(12))
	var t := UI.label(title, float(Tokens.type_role("heading")["points"]), true)
	t.theme_type_variation = "Heading"
	v.add_child(t)
	v.add_child(KitNav.rule())
	if words != "":
		v.add_child(UI.label(words, 16, true))
	var r := UI.row()
	for a: Control in actions:
		r.add_child(a)
	v.add_child(r)
	card.add_child(v)
	centre.add_child(card)
	host.add_child(veil)
	veil.theme = RbTheme.of("dark")
	card.ready.connect(func() -> void: Motion.pop(card))
	return veil


## A row that goes somewhere (Profile and stats, Privacy policy): a list
## row with the designs' chevron at its end.
static func link(icon: String, title: String, line: String, pressed: Callable) -> Control:
	return row(icon, title, line, Icons.view("hud/next", 20), pressed)


## A value the player's age band fixes (§20.2, §23.5 "shown locked"): not a
## control but words, a lock beside the value and why it is fixed, read as
## one sentence.
static func locked(icon: String, title: String, value: String, why: String) -> Control:
	var tag := HBoxContainer.new()
	tag.add_theme_constant_override("separation", UI.px(4))
	tag.add_child(Icons.view("generalui/lock", 18))
	var v := UI.label(value, 14)
	v.theme_type_variation = "LabelText"
	v.set_meta("bold", true)
	tag.add_child(v)
	var r := row(icon, title, why, tag)
	r.accessibility_name = "%s: %s. %s" % [title, value, why]
	return r


## A chapter's band (the Codex's school albums): gold, the school's mark in
## a dark disc, the title in Marcellus over a kicker, and a count on a pill
## at its end.
static func chapter(school: String, title: String, kicker: String, count: String) -> PanelContainer:
	var p := UI.panel("chapter")
	p.name = "Chapter"
	var band := HBoxContainer.new()
	band.add_theme_constant_override("separation", UI.px(10))
	var disc := PanelContainer.new()
	disc.add_theme_stylebox_override("panel", UI.clear_box(4, 4))
	UI.dress(disc, "ring_" + school, 999)
	disc.add_child(Icons.view("schools/" + school, 26))
	disc.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	band.add_child(disc)
	var words := VBoxContainer.new()
	words.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	words.add_theme_constant_override("separation", 0)
	var t := UI.label(title, 22)
	t.theme_type_variation = "Heading"
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	words.add_child(t)
	var k := UI.label(kicker, 13)
	k.theme_type_variation = "Kicker"
	k.uppercase = true
	k.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	k.set_meta("bold", true)
	words.add_child(k)
	band.add_child(words)
	var c := KitStatus.pill(count, "", "parchment")
	c.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	band.add_child(c)
	p.add_child(band)
	return p


## A notice with something to do about it (the designs' raid banner): its
## icon on a disc, a bold title over a secondary line, a gold action, and a
## close cross. It is a banner, so it stays until dismissed when the player
## keeps banners (§20.8, §21.8); `kind` is "alarm", "success" or "info", and
## its glyph leads the title so the kind never rests on the edge's colour.
static func notice(kind: String, icon: String, title: String, line: String, action: String,
		acted: Callable) -> PanelContainer:
	var p := UI.banner(kind, title)
	var r := p.get_child(0) as Container
	var words := r.get_child(0) as Label
	words.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	words.theme_type_variation = "Status" + kind.capitalize()
	var stack := VBoxContainer.new()
	stack.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	stack.add_theme_constant_override("separation", 0)
	r.remove_child(words)
	stack.add_child(words)
	if line != "":
		var s := UI.label(line, 13, true)
		s.theme_type_variation = "Secondary"
		s.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		stack.add_child(s)
	r.add_child(stack)
	r.move_child(stack, 0)
	if icon != "":
		var disc := PanelContainer.new()
		disc.add_theme_stylebox_override("panel", UI.clear_box(4, 4))
		UI.dress(disc, "badge" if kind == "alarm" else "icon_disc")
		disc.add_child(Icons.view(icon, 26))
		disc.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		r.add_child(disc)
		r.move_child(disc, 0)
	if action != "":
		var go := UI.action(action, acted, "gold")
		go.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		r.add_child(go)
		r.move_child(go, r.get_child_count() - 2)
	return p
