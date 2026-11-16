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
## `trailing` at its end, at least 64 points tall and as tall as its words
## at any text size. With `pressed` the whole card is one button over it,
## named by its title (KitLayout.tap); without, a card. `look` "seg" draws
## it flat, as a row inside a card.
static func row(icon: String, title: String, line := "", trailing: Control = null,
		pressed := Callable(), look := "card") -> Control:
	var host := UI.panel(look)
	host.name = "Row"
	host.custom_minimum_size = Vector2(UI.px(120), UI.px(64))
	host.size_flags_horizontal = Control.SIZE_EXPAND_FILL
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
		# At large text a wide control at the end would leave the title a
		# letter a line: it goes under the words instead.
		if Settings.text_scale > KitLayout.SIDE_BY_SIDE_UP_TO and trailing.get_combined_minimum_size().x > UI.px(64):
			trailing.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
			words.add_child(trailing)
		else:
			content.add_child(trailing)
	# The button under the words, so a control at the row's end keeps its
	# own taps.
	if pressed.is_valid():
		KitLayout.tap(host, pressed, title)
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
	# The baked grab handle once the sheet's skin is switched on (K16), in
	# the code-drawn grip's place.
	var grip: Control = KitSkin.mark("handle_parchment" if look == "sheet_parchment" else "handle")
	if grip == null:
		var bar := ColorRect.new()
		bar.color = Color(Tokens.color("text_on_night_2"), 0.35)
		bar.custom_minimum_size = Vector2(UI.px(40), UI.px(4))
		grip = bar
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
## `kind` "confirm" or "info" (K17) sets the title on a ribbon (K19) and
## marks one action primary: gold, with meta "primary", every other gold
## one turned leather. It is the action at `primary`, else a confirm's last
## and an info's first. An info with no actions gets a Dismiss that closes
## it. `kind` "dialog" is the plain card, as before.
static func dialog(host: Control, title: String, words: String, actions: Array, kind := "dialog",
		primary := -1) -> Control:
	var veil := Control.new()
	veil.name = "Dialog"
	veil.set_anchors_preset(Control.PRESET_FULL_RECT)
	veil.mouse_filter = Control.MOUSE_FILTER_STOP
	RbBox.dress(veil, "scrim", 0)
	var centre := CenterContainer.new()
	centre.set_anchors_preset(Control.PRESET_FULL_RECT)
	veil.add_child(centre)
	var card := UI.panel("card")
	# The popup's baked box once its skin is switched on (K17).
	RbBox.of(card).skin_shape = "popup/box"
	card.custom_minimum_size.x = UI.px(300)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", UI.px(12))
	if kind == "dialog":
		var t := UI.label(title, float(Tokens.type_role("heading")["points"]), true)
		t.theme_type_variation = "Heading"
		v.add_child(t)
		v.add_child(KitNav.rule())
	else:
		veil.name = kind.capitalize()
		v.add_child(ribbon(title))
		if kind == "info" and actions.is_empty():
			actions = [UI.action(Strings.t("COMMON_DISMISS"), veil.queue_free, "gold")]
		var chosen := primary if primary >= 0 else (actions.size() - 1 if kind == "confirm" else 0)
		for i: int in actions.size():
			var a := actions[i] as Control
			var look := "gold" if i == chosen else ("leather" if RbBox.of(a) != null and RbBox.of(a).look == "gold" else "")
			if look != "" and a is Button:
				UI.set_look(a as Button, look)
			elif look != "":
				UI.dress(a, look)
			if i == chosen:
				a.set_meta("primary", true)
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


## A ribbon title (K19): the words in Marcellus on the gold band the ribbon
## skin draws while it is on, centred (a popup's title, a section's).
static func ribbon(title: String) -> PanelContainer:
	var p := UI.panel("chapter")
	p.name = "Ribbon"
	# 24 points, as the chapter's band: Marcellus on the gold stands at
	# §21.8's large size.
	var t := UI.label(title, 24, true)
	t.theme_type_variation = "Heading"
	p.add_child(t)
	return p


## An info popover's frame (K30): a small popup box with `words`, and a
## pointer on its top edge toward what it explains (on its bottom edge when
## `below` is false, the popover then standing over that control).
static func popover(words: String, below := true) -> VBoxContainer:
	var v := VBoxContainer.new()
	v.name = "Popover"
	v.add_theme_constant_override("separation", 0)
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var card := UI.panel("card")
	RbBox.of(card).skin_shape = "popup/box"
	card.custom_minimum_size.x = UI.px(160)
	# A tap on the frame closes it too: it falls through to the layer.
	card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var l := UI.label(words, 14, true)
	l.custom_minimum_size.x = UI.px(200)
	card.add_child(l)
	# The pointer's strip, as wide as the frame: it is drawn at its meta "x"
	# (the middle of what it explains), else at its middle.
	var tip := Control.new()
	tip.name = "Pointer"
	tip.custom_minimum_size = Vector2(UI.px(18), UI.px(9))
	tip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var spec := Tokens.material("card")
	var fill := Tokens.gradient(str(spec["fill"])).sample(0.0 if below else 1.0)
	var edge: Color = (spec.get("line", spec.get("rim", [Color.TRANSPARENT])) as Array)[0]
	tip.draw.connect(func() -> void:
		var x := float(tip.get_meta("x")) if tip.has_meta("x") else tip.size.x * 0.5
		var w := UI.px(9)
		var h := tip.size.y
		var pts := PackedVector2Array([Vector2(x - w, h), Vector2(x, 0), Vector2(x + w, h)]) if below \
			else PackedVector2Array([Vector2(x - w, 0), Vector2(x, h), Vector2(x + w, 0)])
		tip.draw_colored_polygon(pts, fill)
		tip.draw_polyline(pts, edge, maxf(1.0, UI.px(1.5)), true))
	v.add_child(tip if below else card)
	v.add_child(card if below else tip)
	return v


## An info control (K30, in place of a tooltip, §21.8): the (i) as a round
## button of 48 points named `spoken`; a tap opens `words` in a popover by
## it, over the whole window, and a tap anywhere closes it. The open
## popover's layer is the button's meta "open" while it stands.
static func info(spoken: String, words: String) -> Button:
	var b := KitControls.icon_button("generalui/info", spoken, func() -> void: pass)
	b.name = "Info"
	b.pressed.connect(func() -> void: _toggle_info(b, words))
	return b


static func _toggle_info(b: Button, words: String) -> void:
	if b.has_meta("open") and is_instance_valid(b.get_meta("open")):
		(b.get_meta("open") as Node).queue_free()
		b.remove_meta("open")
		return
	var layer := Control.new()
	layer.name = "PopoverLayer"
	layer.set_anchors_preset(Control.PRESET_FULL_RECT)
	layer.mouse_filter = Control.MOUSE_FILTER_STOP
	layer.theme = RbTheme.of("dark")
	var view := b.get_viewport_rect().size
	var at := b.get_global_rect()
	var below := at.end.y + UI.px(160) < view.y
	var pop := popover(words, below)
	layer.add_child(pop)
	layer.gui_input.connect(func(e: InputEvent) -> void:
		if (e is InputEventMouseButton and (e as InputEventMouseButton).pressed) \
				or (e is InputEventScreenTouch and (e as InputEventScreenTouch).pressed):
			layer.accept_event()
			layer.queue_free()
			if is_instance_valid(b):
				b.remove_meta("open"))
	b.get_viewport().add_child(layer)
	b.set_meta("open", layer)
	pop.reset_size()
	var w := pop.get_combined_minimum_size().x
	var h := pop.get_combined_minimum_size().y
	var side := UI.px(8)
	pop.position = Vector2(clampf(at.get_center().x - w * 0.5, side, maxf(side, view.x - w - side)),
		at.end.y if below else at.position.y - h)
	# The pointer stays on the (i) when the frame is held inside the window.
	var tip := pop.get_node("Pointer") as Control
	tip.set_meta("x", clampf(at.get_center().x - pop.position.x, UI.px(20), maxf(UI.px(20), w - UI.px(20))))
	tip.queue_redraw()
	Motion.pop(pop)


## An empty state (K35): a list with nothing in it says so with its icon,
## its words, and one gold action (`action` names it; none when ""), on a
## card in the kit's materials. The action is the card's meta "action".
static func empty(icon: String, words: String, action := "", acted := Callable()) -> PanelContainer:
	var p := UI.panel("card")
	p.name = "Empty"
	p.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var v := VBoxContainer.new()
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	v.add_theme_constant_override("separation", UI.px(12))
	if icon != "":
		var i := Icons.view(icon, 96)
		i.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		i.modulate.a = 0.8
		v.add_child(i)
	var l := UI.label(words, 16, true)
	l.theme_type_variation = "Secondary"
	v.add_child(l)
	if action != "":
		var go := UI.action(action, acted, "gold")
		go.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		p.set_meta("action", go)
		v.add_child(go)
	p.add_child(v)
	return p


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


## A chapter's band (the Codex's school albums): in its school's colours,
## the school's mark in a disc, the title in Marcellus over a kicker, both
## stroked in ink, and a count on a dark pill at its end.
static func chapter(school: String, title: String, kicker: String, count: String) -> PanelContainer:
	var p := UI.panel("chapter_" + school)
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
	# 24 points: Marcellus is not bold, and on the gold's deep stop no ink
	# reaches APCA Lc 75, so the title stands at §21.8's large size (Lc 60).
	var t := UI.label(title, 24, true)
	t.theme_type_variation = "Heading"
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	words.add_child(t)
	var k := UI.label(kicker, 13, true)
	k.theme_type_variation = "Kicker"
	k.uppercase = true
	k.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	k.set_meta("bold", true)
	words.add_child(k)
	band.add_child(words)
	var c := KitStatus.pill(count, "", "track")
	c.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	band.add_child(c)
	p.add_child(band)
	return p


## A chapter's album (the Codex, 13-law-codex.png): the school's band
## sitting square on a cream panel that holds `body` (its law cards), one
## piece edged in ink. The band is `chapter`'s; `body` is the screen's.
static func album(school: String, title: String, kicker: String, count: String, body: Control) -> PanelContainer:
	var p := PanelContainer.new()
	p.name = "Album"
	p.add_theme_stylebox_override("panel", UI.clear_box(0, 0))
	UI.dress(p, "album")
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 0)
	var band := chapter(school, title, kicker, count)
	# Square at its foot, on the cream, without its own drop.
	var box := RbBox.of(band)
	box.foot_points = 0.0
	v.add_child(band)
	var inner := MarginContainer.new()
	inner.name = "Pages"
	for side: String in ["margin_left", "margin_right", "margin_top", "margin_bottom"]:
		inner.add_theme_constant_override(side, UI.px(10))
	inner.add_child(body)
	v.add_child(inner)
	p.add_child(v)
	return p


## A quest (17 Season's quests): its mark on a dark tile, its title, a bar
## with "2 / 3" written inside it, and at its end the reward on a dark pill
## with a small SWAP under it (`swap_words`, `swap`), or, once done, a green
## CLAIM with the reward under its word (`claim_words`, `claim`), the card
## ringed in green. The count is
## written, so done never rests on the green (§20.8).
static func quest(icon: String, title: String, done: int, of: int, reward: String, reward_icon: String,
		claim_words: String, claim: Callable, swap_words := "", swap := Callable()) -> PanelContainer:
	var finished := done >= of
	var p := UI.panel("parchment_done" if finished else "parchment")
	p.name = "Quest"
	var strip := HBoxContainer.new()
	strip.add_theme_constant_override("separation", UI.px(10))
	var tile := PanelContainer.new()
	tile.add_theme_stylebox_override("panel", UI.clear_box(6, 6))
	UI.dress(tile, "plate_dark", 10)
	tile.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	tile.add_child(Icons.view(icon, 28))
	strip.add_child(tile)
	var mid := VBoxContainer.new()
	mid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	mid.alignment = BoxContainer.ALIGNMENT_CENTER
	mid.add_theme_constant_override("separation", UI.px(4))
	var t := UI.label(title, 15, true)
	t.theme_type_variation = "BodyBold"
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	t.set_meta("bold", true)
	mid.add_child(t)
	# Tall enough for its count at the player's text size.
	var tall := maxf(18.0, UI.text_px(13) / UI.PX_PER_POINT * 1.3)
	var bar := KitBar.make(float(done) / maxf(of, 1), Tokens.color("success") if finished else Color(), tall)
	# A light track on parchment.
	RbBox.dress(bar, "bar_track_light")
	var count := UI.label("%d / %d" % [done, of], 13)
	count.theme_type_variation = "Number"
	count.set_meta("bold", true)
	count.set_anchors_preset(Control.PRESET_FULL_RECT)
	count.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	# Where the count's middle sits on the fill: cream stroked in ink (read
	# against its stroke, §21.8); on the light track: the parchment's ink.
	if float(done) / maxf(of, 1) >= 0.5:
		count.add_theme_color_override("font_color", Tokens.color("cream"))
		count.add_theme_color_override("font_outline_color", Tokens.color("ink_line"))
		count.add_theme_constant_override("outline_size", maxi(UI.px(2.5), ceili(UI.text_px(13) * 0.2)))
	else:
		count.add_theme_color_override("font_color", Tokens.color("parchment_ink"))
		count.add_theme_constant_override("outline_size", 0)
	bar.add_child(count)
	mid.add_child(bar)
	strip.add_child(mid)
	var end := VBoxContainer.new()
	end.alignment = BoxContainer.ALIGNMENT_CENTER
	end.add_theme_constant_override("separation", UI.px(4))
	if finished:
		end.add_child(KitControls.action2(claim_words, reward, claim, "green", ""))
	else:
		end.add_child(KitStatus.pill(reward, reward_icon, "plate_dark"))
		if swap.is_valid():
			# A small key, drawn inside its 48-point hit area (§21.1).
			var s := UI.action(swap_words.to_upper(), swap, "chip_light", "%s: %s" % [swap_words, title])
			s.add_theme_font_size_override("font_size", UI.text_px(13))
			s.custom_minimum_size = Vector2(UI.px(UI.CONTROL_POINTS), UI.px(UI.CONTROL_POINTS))
			# The chip is the words' height, inside the 48-point hit area.
			var chip := RbBox.of(s)
			chip.inset_top = UI.px(7)
			chip.bleed = -UI.px(7)
			for state: String in ["normal", "hover", "pressed", "focus", "disabled"]:
				s.add_theme_stylebox_override(state, UI.clear_box(12, 0))
			s.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
			end.add_child(s)
	# At large text the end goes under the words.
	if Settings.text_scale > KitLayout.SIDE_BY_SIDE_UP_TO:
		end.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
		mid.add_child(end)
	else:
		strip.add_child(end)
	p.add_child(strip)
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
