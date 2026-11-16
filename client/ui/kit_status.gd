class_name KitStatus
## What a screen reports at a glance: count badges, pills (glass over the
## world, as the designs' strain pill), resource pills with their storage
## line and the FULL tag, level plates and progress bars. Every one writes
## its number or word; colour is never the only sign (§20.8).


## A count badge: white words with an ink outline on the designs' red,
## measured against the outline (§21.8). In another round material (a
## building's level on "gold_round", a post's number on "leather") its
## words take that material's ink, in the display face, `points` large.
static func badge(text: String, look := "badge", points := 13.0) -> PanelContainer:
	var p := PanelContainer.new()
	p.name = "Badge"
	p.add_theme_stylebox_override("panel", UI.clear_box(5, 0))
	var box := UI.dress(p, look, 99.0 if look != "badge" else -1.0)
	var side := float(UI.px(Tokens.number("size", "badge_points")))
	if look != "badge":
		side = maxf(side, UI.px(points + 10.0))
	p.custom_minimum_size = Vector2(side, side)
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	p.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	p.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	var l := UI.label(text, points)
	l.name = "Words"
	l.add_theme_font_override("font", UI.bold_font() if look == "badge" else Tokens.font("display"))
	l.add_theme_color_override("font_color", Tokens.color("on_alarm") if look == "badge" else box.spec["text"])
	if look == "badge" or box.spec["family"] == "dark":
		l.add_theme_color_override("font_outline_color", Tokens.color("ink_line"))
		l.add_theme_constant_override("outline_size", UI.px(2))
	l.set_meta("bold", true)
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	p.add_child(l)
	return p


## The attention dot (a tab or a row with something new, no count): the
## kit's dot while its skin is on, else a dot in the alarm's red. It is a
## mark beside words that say the same, never the only sign (§20.8).
static func attention(points := 12.0) -> Control:
	var d: Control = KitSkin.mark("dot", points)
	if d == null:
		var ring := KitRing.new()
		ring.dot = true
		ring.fraction = 1.0
		ring.tint = Tokens.color("alarm")
		ring.custom_minimum_size = Vector2.ONE * UI.px(points)
		ring.mouse_filter = Control.MOUSE_FILTER_IGNORE
		d = ring
	d.name = "Dot"
	d.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	d.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	return d


## A pill of words, with an icon before them if named: glass over the world
## unless another material is given. Words wider than `widest` points (by
## default the phone less its margins) end in an ellipsis; the label keeps
## them all, and a screen reader says them all.
static func pill(text: String, icon := "", look := "glass", widest := 300.0) -> PanelContainer:
	var p := PanelContainer.new()
	p.name = "Pill"
	p.add_theme_stylebox_override("panel", UI.clear_box(10, 4))
	UI.dress(p, look, 999)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", UI.px(6))
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	if icon != "":
		row.add_child(Icons.view(icon, 22))
	var l := UI.label(text, 14)
	l.theme_type_variation = "LabelText"
	l.set_meta("bold", true)
	l.name = "Words"
	l.set_meta("widest", widest)
	row.add_child(l)
	p.add_child(row)
	set_pill(p, text)
	return p


## A hint over the world (02-heist.png's "Tap crew, then ground · hold
## ground to sneak or run"): dark glass, its words whole and centred,
## wrapping onto a second line rather than ending in an ellipsis.
static func hint(text: String) -> PanelContainer:
	var p := PanelContainer.new()
	p.name = "Hint"
	p.add_theme_stylebox_override("panel", UI.clear_box(14, 5))
	UI.dress(p, "glass", 14)
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	p.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var l := UI.label(text, 15, true)
	l.name = "Words"
	l.theme_type_variation = "LabelText"
	l.set_meta("bold", true)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	p.add_child(l)
	return p


## A pill's new words, ellipsised past its widest.
static func set_pill(p: PanelContainer, text: String) -> void:
	var l := p.find_child("Words", true, false) as Label
	l.text = text
	var font := RbTheme.role_font("label")
	var natural := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1,
		l.get_theme_font_size("font_size") if l.is_inside_tree() else UI.text_px(14)).x + 2.0
	var cap := float(UI.px(float(l.get_meta("widest", 300.0))))
	# A label that may trim asks for no width at all, so it trims only
	# when the words pass the cap, and then holds the cap.
	l.clip_text = natural > cap
	l.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS if natural > cap else TextServer.OVERRUN_NO_TRIMMING
	l.custom_minimum_size.x = cap if natural > cap else 0.0


## A resource with its storage (§21.8's home layout: "resources with storage
## bars"): its icon in a dark disc, the amount in tabular figures at the
## pill's end, FULL written in gold before it when the store is nine-tenths
## full or more, and the share of storage as a line glowing along the
## pill's foot.
static func resource(icon: String, amount: String, fraction: float, tone: Color) -> PanelContainer:
	var p := PanelContainer.new()
	p.name = "Resource"
	var pad := UI.clear_box(3, 2)
	# 6 points at the end (T4's measure): "FULL 142.0k" fits a third of the
	# phone at 100% text, as the design's "FULL 61.0k" does.
	pad.content_margin_right = UI.px(6)
	pad.content_margin_bottom = UI.px(1)
	p.add_theme_stylebox_override("panel", pad)
	UI.dress(p, "track", 999)
	p.custom_minimum_size.y = UI.px(Tokens.number("size", "pill_points"))
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 0)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", UI.px(3))
	row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var disc := PanelContainer.new()
	disc.add_theme_stylebox_override("panel", UI.clear_box(2, 2))
	UI.dress(disc, "icon_disc")
	disc.add_child(Icons.view(icon, 22))
	disc.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(disc)
	var full := UI.label(Strings.t("KIT_FULL"), 13)
	full.theme_type_variation = "Kicker"
	full.uppercase = true
	full.add_theme_color_override("font_color", Tokens.color("gold_top"))
	full.set_meta("bold", true)
	full.name = "Full"
	var room := Control.new()
	room.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	room.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(room)
	row.add_child(full)
	var l := UI.label(amount, 16)
	l.theme_type_variation = "Number"
	l.set_meta("bold", true)
	l.name = "Amount"
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	row.add_child(l)
	v.add_child(row)
	var bar := KitBar.make(fraction, tone, 4)
	bar.name = "Storage"
	bar.inset_points = 0.0
	RbBox.dress(bar, "icon_disc")
	RbBox.dress(bar.fill, "bar_line")
	bar.colour(tone.lightened(0.15))
	var inset := MarginContainer.new()
	inset.add_theme_constant_override("margin_left", UI.px(14))
	inset.add_theme_constant_override("margin_right", UI.px(4))
	inset.add_child(bar)
	v.add_child(inset)
	p.add_child(v)
	set_resource(p, amount, fraction)
	return p


## A resource pill's new amount and share of storage.
static func set_resource(p: PanelContainer, amount: String, fraction: float) -> void:
	(p.find_child("Amount", true, false) as Label).text = amount
	Motion.fill(p.find_child("Storage", true, false) as KitBar, clampf(fraction, 0.0, 1.0))
	(p.find_child("Full", true, false) as Control).visible = fraction >= 0.9


## A small plate for a level or a count on a portrait ("LV 5"): parchment
## with ink figures.
static func plate(text: String) -> PanelContainer:
	var p := PanelContainer.new()
	p.name = "Plate"
	p.add_theme_stylebox_override("panel", UI.clear_box(6, 1))
	UI.dress(p, "plate")
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var l := UI.label(text, 13)
	l.theme_type_variation = "Number"
	l.set_meta("bold", true)
	p.add_child(l)
	return p


## A progress bar with its number written beside it ("3 / 5"), in `colour`
## (gold if none).
static func progress(done: float, of: float, words: String, tone := Color()) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.name = "Progress"
	row.add_theme_constant_override("separation", UI.px(8))
	var bar := KitBar.make(0.0 if of <= 0.0 else done / of, tone)
	bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(bar)
	var l := UI.label(words, 14)
	l.theme_type_variation = "Number"
	l.set_meta("bold", true)
	row.add_child(l)
	return row


## The universe's stability (§5.5) on a glass pill: a dot in its band's
## colour and the share and band in words ("82% · Humming"), so the band
## never rests on its colour.
static func strain(words: String, band: String) -> PanelContainer:
	var p := pill(words)
	p.name = "Strain"
	var dot := KitRing.new()
	dot.dot = true
	dot.fraction = 1.0
	dot.tint = Tokens.color("band_" + band)
	dot.custom_minimum_size = Vector2.ONE * UI.px(14)
	dot.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var row := p.get_child(0) as HBoxContainer
	row.add_child(dot)
	row.move_child(dot, 0)
	return p


## An island's label over the map: a cream pill with the realm's icon, its
## name in Marcellus and its level on a dark disc.
static func island_label(icon: String, name: String, level: int) -> PanelContainer:
	var p := PanelContainer.new()
	p.name = "IslandLabel"
	p.add_theme_stylebox_override("panel", UI.clear_box(5, 2))
	UI.dress(p, "island_label")
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", UI.px(5))
	if icon != "":
		row.add_child(Icons.view(icon, 22))
	var n := UI.label(name, 16)
	n.theme_type_variation = "Heading"
	n.add_theme_font_size_override("font_size", UI.text_px(16))
	row.add_child(n)
	var disc := PanelContainer.new()
	disc.add_theme_stylebox_override("panel", UI.clear_box(4, 0))
	UI.dress(disc, "level_disc")
	disc.custom_minimum_size = Vector2.ONE * UI.px(22)
	var l := UI.label(str(level), 13)
	l.theme_type_variation = "Number"
	l.set_meta("bold", true)
	disc.add_child(l)
	disc.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(disc)
	p.add_child(row)
	return p


## A ribbon tag on a card's corner (FEATURED SET, EMOTE): small capitals on
## gold, or on a dark plate.
static func tag(text: String, dark := false) -> PanelContainer:
	var p := PanelContainer.new()
	p.name = "Tag"
	p.add_theme_stylebox_override("panel", UI.clear_box(7, 1))
	UI.dress(p, "tag_dark" if dark else "tag")
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	p.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	var l := UI.label(text, 13)
	l.theme_type_variation = "Kicker"
	l.uppercase = true
	l.set_meta("bold", true)
	p.add_child(l)
	return p


## Experience toward the next level (the Character screen): a green bar
## cut into segments with its figures written inside it ("588 / 600 XP").
static func xp(done: float, of: float, words: String, segments := 8) -> Control:
	var bar := KitBar.make(0.0 if of <= 0.0 else done / of, Tokens.color("green_bar"), 22)
	bar.name = "Experience"
	var ticks := KitTicks.new()
	ticks.count = segments
	ticks.set_anchors_preset(Control.PRESET_FULL_RECT)
	ticks.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bar.add_child(ticks)
	var l := UI.label(words, 13)
	l.theme_type_variation = "Number"
	l.set_anchors_preset(Control.PRESET_FULL_RECT)
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	l.add_theme_color_override("font_color", Tokens.color("text_on_night"))
	l.add_theme_color_override("font_outline_color", Tokens.color("ink_line"))
	l.add_theme_constant_override("outline_size", UI.px(2))
	l.set_meta("bold", true)
	bar.add_child(l)
	return bar


## A stat tile (the designs' profile and result tiles): an icon if named,
## a big number in Lilita One, and what it counts beneath, wrapping.
static func stat(number: String, words: String, icon := "", look := "card") -> PanelContainer:
	var p := UI.panel(look)
	p.name = "Stat"
	p.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 0)
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	if icon != "":
		var i := Icons.view(icon, 26)
		i.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		v.add_child(i)
	var n := UI.label(number, 24)
	n.theme_type_variation = "DisplayS"
	n.add_theme_font_size_override("font_size", UI.text_px(24))
	n.set_meta("points", 24.0)
	n.name = "Number"
	v.add_child(n)
	var w := UI.label(words, 13, true)
	w.theme_type_variation = "Secondary"
	w.add_theme_font_override("font", UI.bold_font())
	w.set_meta("bold", true)
	v.add_child(w)
	p.add_child(v)
	return p


## A sash across a card's top right corner (08-observatory.png's "TRACE ·
## 24 h"): bold capitals on a gold band at 45 degrees, cut by the card's
## edge. Add it to the card last (inside a container it fills the card); it
## lets taps through.
static func sash(text: String, points := 72.0) -> Control:
	var corner := Control.new()
	corner.name = "Sash"
	corner.set_anchors_preset(Control.PRESET_FULL_RECT)
	corner.clip_contents = true
	corner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var band := PanelContainer.new()
	band.add_theme_stylebox_override("panel", UI.clear_box(0, 2))
	UI.dress(band, "plate_gold", 0)
	band.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var l := UI.label(text, 13)
	l.uppercase = true
	l.theme_type_variation = "Kicker"
	l.set_meta("bold", true)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	band.add_child(l)
	corner.add_child(band)
	# Long enough to cross the corner at 45 degrees, centred on its diagonal,
	# wherever the card's right edge lands.
	var place := func() -> void:
		# The corner the band crosses is as large as its words need: across
		# it the band shows 0.85 of `side`.
		var side := maxf(UI.px(points), (l.get_combined_minimum_size().x + UI.px(16)) / 0.85)
		band.size = Vector2(side * 1.5, band.get_combined_minimum_size().y)
		band.pivot_offset = band.size * 0.5
		band.rotation = PI * 0.25
		band.position = Vector2(corner.size.x - side * 0.3, side * 0.3) - band.size * 0.5
	corner.resized.connect(place)
	band.minimum_size_changed.connect(place)
	return corner



## K34, the spinner: the atlas's ring (the timer's icon while its skin is
## off) `points` tall, turned once every `KitSkin.SPIN_SECONDS` from when it
## enters the tree. Under reduced motion the mark holds still and, with
## `words`, "Loading" follows it (§20.8). Said aloud as loading either way.
static func spinner(points := 24.0, words := true) -> HBoxContainer:
	var h := HBoxContainer.new()
	h.name = "Spinner"
	h.mouse_filter = Control.MOUSE_FILTER_IGNORE
	h.add_theme_constant_override("separation", UI.px(6))
	h.accessibility_name = Strings.t("COMMON_LOADING")
	# The mark turns inside a holder of its size, so a container that lays
	# out the spinner never moves the turn's pivot.
	var holder := Control.new()
	holder.name = "Holder"
	holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	holder.custom_minimum_size = Vector2.ONE * UI.px(points)
	holder.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var mark: Control = KitSkin.mark("spinner", points)
	if mark == null:
		mark = Icons.view("generalui/timer", points)
		mark.size = mark.custom_minimum_size
	mark.name = "Mark"
	# A piece's baked shape may not be square: centred in the holder.
	mark.position = (holder.custom_minimum_size - mark.size) * 0.5
	mark.pivot_offset = mark.size * 0.5
	holder.add_child(mark)
	h.add_child(holder)
	if Settings.reduced_motion:
		if words:
			var l := UI.label(Strings.t("COMMON_LOADING"), maxf(13.0, points * 0.6))
			l.name = "Words"
			h.add_child(l)
		return h
	mark.ready.connect(func() -> void:
		var turn := mark.create_tween().set_loops()
		turn.tween_property(mark, "rotation", TAU, KitSkin.SPIN_SECONDS).from(0.0), CONNECT_ONE_SHOT)
	return h


## The Ld state (kit-spec.md section 3) on `c`, a button (K01), a round
## action (K02), a text field (K11) or a quest card (K43), or off again with
## `on` false. The control it applies to is `c` when `c` is a button or a
## field, else the first one inside it (a round action's disc, a quest card's
## claim): its face is held, its words and icon hidden and a still or
## turning spinner (`spinner`) the words' size laid over them, out of any
## layout, so nothing moves. Taps and focus stop while it loads, and a screen
## reader says it is loading.
static func loading(c: Control, on := true) -> void:
	var host := _acted_on(c)
	var held: Dictionary = host.get_meta("kit_loading") if host.has_meta("kit_loading") else {}
	if on != held.is_empty():
		return
	if not on:
		for row: Array in held["hidden"]:
			if is_instance_valid(row[0]):
				(row[0] as CanvasItem).self_modulate.a = row[1]
		if is_instance_valid(held["over"]):
			(held["over"] as Node).queue_free()
		host.focus_mode = held["focus"]
		host.accessibility_description = held["said"]
		host.remove_meta("kit_loading")
		return
	var words := 0.0
	var hidden := []
	for n: Node in [host] + host.find_children("*", "", true, false):
		if n == host or n is Label or (n is TextureRect and host is BaseButton):
			var item := n as CanvasItem
			if item.self_modulate.a == 0.0 and n != host:
				continue
			hidden.append([item, item.self_modulate.a])
			item.self_modulate.a = 0.0
			if n is Label and (n as Label).text != "":
				words = maxf(words, (n as Control).get_theme_font_size("font_size"))
			elif n is TextureRect:
				words = maxf(words, (n as Control).custom_minimum_size.y * 0.8)
	if (host is Button and (host as Button).text != "") or (host is LineEdit and (host as LineEdit).text != ""):
		words = maxf(words, host.get_theme_font_size("font_size"))
	if words <= 0.0:
		words = UI.text_px(UI.TEXT_POINTS)
	# The spinner as tall as the words' line, never taller than the control.
	var side := words * 1.2
	if host.size.y > 0.0:
		side = minf(side, host.size.y * 0.8)
	var over := CenterContainer.new()
	over.name = "Loading"
	over.set_anchors_preset(Control.PRESET_FULL_RECT)
	# It takes the taps the control would.
	over.mouse_filter = Control.MOUSE_FILTER_STOP
	over.z_index = UI.WORDS_Z
	over.add_child(spinner(side / UI.PX_PER_POINT, false))
	# An internal child: no container lays it out.
	host.add_child(over, false, Node.INTERNAL_MODE_BACK)
	host.set_meta("kit_loading", {"hidden": hidden, "over": over, "focus": host.focus_mode,
		"said": host.accessibility_description})
	if host.has_focus():
		host.release_focus()
	host.focus_mode = Control.FOCUS_NONE
	host.accessibility_description = Strings.t("COMMON_LOADING")


## Whether `c` (or the control inside it that `loading` applies to) loads.
static func is_loading(c: Control) -> bool:
	return _acted_on(c).has_meta("kit_loading")


## The L overlay (kit-spec.md section 3) on `c`, any control (a button, a
## card), or off with `on` false: the locked material on its kit box (with
## `face`) and the lock mark at its top left, over its words, out of any
## layout; a tap anywhere on it opens a popover of `why` (how it unlocks)
## instead of acting. Returns the mark, or null when turned off.
static func locked(c: Control, why := "", on := true, face := true) -> Control:
	var host := c
	var old := host.get_node_or_null("Lock")
	if old != null:
		host.remove_child(old)
		old.queue_free()
		var was: Variant = host.get_meta("kit_unlocked_look", null)
		if was != null and RbBox.of(host) != null:
			RbBox.of(host).set_look(str(was))
		host.remove_meta("kit_unlocked_look")
	if not on:
		return null
	if face and RbBox.of(host) != null:
		host.set_meta("kit_unlocked_look", RbBox.of(host).look)
		RbBox.of(host).set_look("locked")
	# A clear key over the whole control: the control's own action never runs.
	var cover := Button.new()
	cover.name = "Lock"
	cover.flat = true
	cover.focus_mode = Control.FOCUS_ALL if why != "" else Control.FOCUS_NONE
	for state: String in ["normal", "hover", "pressed", "focus", "disabled"]:
		cover.add_theme_stylebox_override(state, StyleBoxEmpty.new())
	cover.set_anchors_preset(Control.PRESET_FULL_RECT)
	cover.z_index = UI.WORDS_Z
	cover.accessibility_name = why if why != "" else Strings.t("SCREEN_SLOT_LOCKED")
	if why != "":
		cover.pressed.connect(func() -> void: KitPanels._toggle_info(cover, why))
	var mark: Control = KitSkin.mark("lock", 22.0)
	if mark == null:
		mark = Icons.view("generalui/lock", 22.0)
		mark.size = mark.custom_minimum_size
	mark.name = "Mark"
	mark.mouse_filter = Control.MOUSE_FILTER_IGNORE
	mark.position = Vector2.ONE * -UI.px(4)
	cover.add_child(mark)
	host.add_child(cover, false, Node.INTERNAL_MODE_BACK)
	return mark


## The A overlay (kit-spec.md section 3) on `c`, any control, or off with
## `on` false: a count badge of `count`, or the attention dot with no count,
## at its top right inside its hit area, over its words, out of any layout.
## It replaces any mark this call put there before, so a control carries one
## at most, and pulses once on arrival (reduced motion: no pulse). Returns
## the mark, or null when turned off.
static func notice(c: Control, count := "", on := true) -> Control:
	var host := c
	var old := host.get_node_or_null("Notice")
	if old != null:
		host.remove_child(old)
		old.queue_free()
	if not on:
		return null
	var mark: Control = badge(count) if count != "" else attention()
	mark.name = "Notice"
	mark.mouse_filter = Control.MOUSE_FILTER_IGNORE
	mark.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	mark.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	var side := mark.get_combined_minimum_size()
	mark.offset_left = -side.x
	mark.offset_right = 0.0
	mark.offset_top = 0.0
	mark.offset_bottom = side.y
	mark.z_index = UI.WORDS_Z
	host.add_child(mark, false, Node.INTERNAL_MODE_BACK)
	if not Settings.reduced_motion:
		var pulse := func() -> void:
			mark.pivot_offset = mark.size * 0.5
			var t := mark.create_tween()
			var half := Tokens.number("motion", "pop_ms") / 1000.0
			t.tween_property(mark, "scale", Vector2.ONE * 1.15, half).set_trans(Tween.TRANS_SINE)
			t.tween_property(mark, "scale", Vector2.ONE, half).set_trans(Tween.TRANS_SINE)
		if mark.is_inside_tree():
			pulse.call()
		else:
			mark.ready.connect(pulse, CONNECT_ONE_SHOT)
	return mark


## The control a state applies to: `c` when it is a button or a field, else
## the first visible one inside it, else `c`.
static func _acted_on(c: Control) -> Control:
	if c is BaseButton or c is LineEdit:
		return c
	for n: Node in c.find_children("*", "", true, false):
		if (n is BaseButton or n is LineEdit) and (n as Control).is_visible_in_tree() == c.is_visible_in_tree():
			return n
	return c
