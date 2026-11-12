class_name KitHud
## The HUD pieces §21.8's layouts name, for the screens that hold them:
## the Keeper's badge (portrait, XP ring, level plate, name, Renown), the
## nearest goal above the tabs, an ability's uses as pips with their number,
## the alarm meter with its count written, and the clock. Each writes its
## number; colour is never the only sign (§20.8).


## The Keeper's badge at the home screen's top left: the portrait in a ring
## that fills with experience, the level on a plate, the name in Marcellus
## and the Renown on a pill.
static func keeper(portrait: Texture2D, name: String, level: int, xp: float, renown: String) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.name = "Keeper"
	row.add_theme_constant_override("separation", UI.px(8))
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var ring := KitRing.new()
	ring.name = "Portrait"
	ring.fraction = clampf(xp, 0.0, 1.0)
	ring.picture = portrait
	ring.custom_minimum_size = Vector2.ONE * UI.px(52)
	var plate := KitStatus.plate(str(level))
	UI.dress(plate, "plate_gold")
	plate.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	plate.grow_horizontal = Control.GROW_DIRECTION_BOTH
	plate.grow_vertical = Control.GROW_DIRECTION_BEGIN
	plate.position.y = UI.px(6)
	ring.add_child(plate)
	row.add_child(ring)
	var words := VBoxContainer.new()
	words.add_theme_constant_override("separation", UI.px(2))
	words.alignment = BoxContainer.ALIGNMENT_CENTER
	var n := UI.label(name, 18)
	n.theme_type_variation = "Heading"
	n.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	words.add_child(n)
	var r := KitStatus.pill(renown, "resources/renown")
	r.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	words.add_child(r)
	row.add_child(words)
	return row


## The nearest goal (§14.8) on a card above the tabs: its icon, its words
## and how far along it is, the count written beside the bar.
static func goal(icon: String, words: String, done: float, of: float, count: String) -> PanelContainer:
	var p := UI.panel("card")
	p.name = "Goal"
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", UI.px(10))
	if icon != "":
		row.add_child(Icons.view(icon, 32))
	var v := VBoxContainer.new()
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	v.add_theme_constant_override("separation", UI.px(4))
	var l := UI.label(words, 14, true)
	l.theme_type_variation = "BodyBold"
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	l.set_meta("bold", true)
	v.add_child(l)
	v.add_child(KitStatus.progress(done, of, count, Tokens.color("gold")))
	row.add_child(v)
	p.add_child(row)
	return p


## An ability's uses (§21.8): `of` pips, the spent ones hollow, with the
## number left written beside them.
static func pips(left: int, of: int) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.name = "Pips"
	row.add_theme_constant_override("separation", UI.px(3))
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for i: int in of:
		var pip := KitRing.new()
		pip.dot = true
		pip.fraction = 1.0 if i < left else 0.0
		pip.custom_minimum_size = Vector2.ONE * UI.px(12)
		pip.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		row.add_child(pip)
	var n := UI.label(str(left), 13)
	n.theme_type_variation = "Number"
	n.set_meta("bold", true)
	row.add_child(n)
	return row


## The alarm meter: `of` bells, the first half amber and the rest red as
## they fill, with "Alarm 2 / 6" (`words`) written under them.
static func meter(level: int, of: int, words: String) -> VBoxContainer:
	var v := VBoxContainer.new()
	v.name = "Meter"
	v.add_theme_constant_override("separation", UI.px(2))
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var row := HBoxContainer.new()
	row.name = "Bells"
	row.add_theme_constant_override("separation", UI.px(2))
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	for i: int in of:
		_bell(row, i, level, of)
	v.add_child(row)
	var l := UI.label(words, 13)
	l.theme_type_variation = "Caption"
	l.set_meta("bold", true)
	l.add_theme_font_override("font", UI.bold_font())
	v.add_child(l)
	return v


## Bell `i` of `of` in `row`: lit (marked "lit") below `level`, amber in the
## first half and red after.
static func _bell(row: HBoxContainer, i: int, level: int, of: int) -> void:
	var bell := Control.new()
	bell.custom_minimum_size = Vector2(UI.px(9), UI.px(12))
	bell.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var lit := Tokens.color("warn") if i < of / 2 else Tokens.color("alarm")
	row.add_child(bell)
	RbBox.dress(bell, "bar_track", 3)
	if i < level:
		RbBox.of(bell).tint(lit.lightened(0.3), lit)
		bell.set_meta("lit", true)


## The clock: tabular figures on parchment, the alarm's red plate under
## thirty seconds (`warning`), its words staying readable on either.
static func clock(text: String, warning := false) -> PanelContainer:
	var p := PanelContainer.new()
	p.name = "Clock"
	p.set_meta("alarmed", warning)
	p.add_theme_stylebox_override("panel", UI.clear_box(12, 2))
	UI.dress(p, "red" if warning else "parchment", 999)
	var l := UI.label(text, 22)
	l.theme_type_variation = "NumberM"
	l.set_meta("bold", true)
	if warning:
		l.add_theme_color_override("font_color", Tokens.color("on_alarm"))
		l.add_theme_color_override("font_outline_color", Tokens.color("ink_line"))
		l.add_theme_constant_override("outline_size", UI.px(3))
	l.name = "Time"
	p.add_child(l)
	return p


## A big ring around a number (the play-time ring, the Codex's count): the
## number in Lilita One with its unit under it, the ring filled to
## `fraction` in gold.
static func dial(number: String, unit: String, fraction: float, points := 112.0) -> KitRing:
	var ring := KitRing.new()
	ring.name = "Dial"
	ring.heavy = true
	ring.fraction = clampf(fraction, 0.0, 1.0)
	# Larger with the text, up to a third again, so its words stay inside.
	var side := points * clampf(Settings.text_scale / 100.0, 1.0, 1.35)
	ring.custom_minimum_size = Vector2.ONE * UI.px(side)
	ring.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var v := VBoxContainer.new()
	v.set_anchors_preset(Control.PRESET_FULL_RECT)
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	v.add_theme_constant_override("separation", -UI.px(4))
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var n := UI.label(number, 30)
	n.theme_type_variation = "Display"
	v.add_child(n)
	var u := UI.label(unit, 13)
	u.theme_type_variation = "Kicker"
	u.add_theme_font_override("font", Tokens.font("ui", 800))
	u.uppercase = true
	u.set_meta("bold", true)
	u.autowrap_mode = TextServer.AUTOWRAP_WORD
	u.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	u.custom_minimum_size.x = UI.px(side * 0.62)
	u.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	v.add_child(u)
	ring.add_child(v)
	return ring


## A weekly streak (17 Season's quests): a tile a day, kept days gold with a
## tick, today cream ringed in gold with its letter, days to come pale with
## theirs, and the week's reward last on a violet tile with its amount.
## `kept` days are done of `letters`; `today` is the index of today. Each
## tile says its day and state aloud (`spoken`: [kept, today, later] words).
static func streak(letters: Array, kept: int, today: int, reward_icon: String, reward: String,
		spoken: Array) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.name = "Streak"
	row.add_theme_constant_override("separation", UI.px(5))
	for i: int in letters.size():
		var look := "day_done" if i < kept else ("day_today" if i == today else "day_later")
		var tile := PanelContainer.new()
		tile.add_theme_stylebox_override("panel", UI.clear_box(2, 2))
		UI.dress(tile, look, 12)
		tile.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		tile.custom_minimum_size = Vector2(UI.px(36), UI.px(44))
		tile.mouse_filter = Control.MOUSE_FILTER_IGNORE
		tile.accessibility_name = "%s, %s" % [letters[i], spoken[0 if i < kept else (1 if i == today else 2)]]
		var l := UI.label("✓" if i < kept else str(letters[i]), 16)
		l.add_theme_font_override("font", UI.bold_font())
		l.set_meta("bold", true)
		l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		tile.add_child(l)
		row.add_child(tile)
	var prize := PanelContainer.new()
	prize.add_theme_stylebox_override("panel", UI.clear_box(2, 2))
	UI.dress(prize, "round_violet", 12)
	prize.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	prize.custom_minimum_size = Vector2(UI.px(40), UI.px(44))
	prize.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var v := VBoxContainer.new()
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	v.add_theme_constant_override("separation", -UI.px(2))
	var art := Icons.view(reward_icon, 22)
	art.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	v.add_child(art)
	var amount := UI.label(reward, 13)
	amount.add_theme_font_override("font", UI.bold_font())
	amount.set_meta("bold", true)
	v.add_child(amount)
	prize.add_child(v)
	row.add_child(prize)
	return row


## A week's bars (the play-time card): one bar a day, its height its share
## of the most, today's in gold and the rest violet, each day's letter
## under it and its minutes in its spoken name (§20.8: the numbers are read).
static func week(minutes: Array, letters: Array, today: int) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.name = "Week"
	row.add_theme_constant_override("separation", UI.px(10))
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	var most := 1.0
	for m: Variant in minutes:
		most = maxf(most, float(m))
	for i: int in minutes.size():
		var day := VBoxContainer.new()
		day.add_theme_constant_override("separation", UI.px(4))
		day.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var well := Control.new()
		well.custom_minimum_size = Vector2(UI.px(18), UI.px(56))
		well.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var bar := Control.new()
		bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var share := float(minutes[i]) / most
		# At most 24 points wide, as the design's, centred in its day.
		bar.anchor_left = 0.5
		bar.anchor_right = 0.5
		bar.offset_left = -UI.px(12)
		bar.offset_right = UI.px(12)
		bar.anchor_top = 1.0 - maxf(share, 0.12)
		bar.anchor_bottom = 1.0
		well.add_child(bar)
		RbBox.dress(bar, "week_today" if i == today else "week_day", 6)
		well.accessibility_name = "%s %s" % [letters[i], minutes[i]]
		day.add_child(well)
		var l := UI.label(str(letters[i]), 13)
		l.theme_type_variation = "Kicker"
		l.set_meta("bold", true)
		l.add_theme_color_override("font_color", Tokens.color("gold_top") if i == today else Tokens.color(
			"text_on_night_2"))
		day.add_child(l)
		row.add_child(day)
	return row


## A crew member's key (02-heist.png): their portrait on their school's
## ground in a leather ring, their ability's uses as diamonds on a dark tag
## at its shoulder (filled and hollow: told apart by shape), their health
## as a green bar and their name beneath. `school` "" keeps the violet.
## `inked` (the heist over the world): a thicker bar and a heavier ink
## outline round the name, so both read on any ground.
static func crew(picture: Texture2D, name: String, health: float, uses: int, pressed: Callable,
		school := "", inked := false) -> VBoxContainer:
	var v := VBoxContainer.new()
	v.name = "Crew"
	v.add_theme_constant_override("separation", UI.px(3))
	v.alignment = BoxContainer.ALIGNMENT_END
	var b := UI.action("", pressed, "seg", name)
	b.custom_minimum_size = Vector2.ONE * UI.px(58)
	b.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	# The ring is the whole key: the segment's box stays undrawn behind it.
	RbBox.of(b).visible = false
	var ring := KitRing.new()
	ring.picture = picture
	ring.band = Tokens.color("leather_dark")
	ring.ground = Tokens.color(school) if school != "" else Color()
	ring.zoom = 1.3
	ring.focus = Vector2(0.5, 0.42)
	ring.set_anchors_preset(Control.PRESET_FULL_RECT)
	ring.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.add_child(ring)
	if uses >= 0:
		var tag := _uses(uses, 2)
		# On the disc's shoulder, its right edge a little past the disc's.
		tag.set_anchors_preset(Control.PRESET_TOP_RIGHT)
		tag.grow_horizontal = Control.GROW_DIRECTION_BEGIN
		tag.offset_left = UI.px(6)
		tag.offset_right = UI.px(6)
		tag.offset_top = -UI.px(8)
		tag.offset_bottom = -UI.px(8)
		b.add_child(tag)
	v.add_child(b)
	var bar := KitBar.make(health, Tokens.color("success"), 11 if inked else 8)
	bar.custom_minimum_size.x = UI.px(54)
	bar.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	v.add_child(bar)
	var n := UI.label(name, 14)
	n.add_theme_font_override("font", UI.bold_font())
	n.add_theme_color_override("font_color", Tokens.color("text_on_night"))
	n.add_theme_color_override("font_outline_color", Tokens.color("ink_line"))
	n.add_theme_constant_override("outline_size", _ink(14) if inked else UI.px(2))
	n.set_meta("bold", true)
	v.add_child(n)
	return v


## An ability's uses on a dark tag: `of` diamonds, those left filled in
## cream, those spent hollow.
static func _uses(left: int, of: int) -> PanelContainer:
	var p := PanelContainer.new()
	p.name = "Uses"
	p.add_theme_stylebox_override("panel", UI.clear_box(4, 2))
	UI.dress(p, "tag_dark", 999)
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", UI.px(1))
	for i: int in of:
		var d := _Diamond.new()
		d.full = i < left
		d.custom_minimum_size = Vector2.ONE * UI.px(12)
		d.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.add_child(d)
	p.add_child(row)
	return p


## The alarm meter in its own panel (02-heist.png): "Alarm" and its count
## in the header, the bells beneath.
static func alarm(level: int, of: int, title: String) -> PanelContainer:
	var p := UI.panel("leather")
	p.name = "Alarm"
	p.set_meta("of", of)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", UI.px(4))
	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", UI.px(8))
	var t := UI.label(title, 14)
	t.add_theme_font_override("font", UI.bold_font())
	t.set_meta("bold", true)
	t.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	head.add_child(t)
	var n := UI.label("%d / %d" % [level, of], 14)
	n.name = "Count"
	n.theme_type_variation = "Number"
	n.set_meta("bold", true)
	head.add_child(n)
	v.add_child(head)
	var bells := meter(level, of, "")
	bells.get_child(1).queue_free()
	v.add_child(bells)
	p.add_child(v)
	return p


## Numbers in rows on a card (the heist's loot: "Room 1,840", "Left
## 2,600"), each word on the left and its number in gold tabular figures on
## the right.
static func figures(rows: Array, look := "card") -> PanelContainer:
	var p := UI.panel(look)
	p.name = "Figures"
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", UI.px(2))
	for r: Array in rows:
		var h := HBoxContainer.new()
		h.add_theme_constant_override("separation", UI.px(8))
		var w := UI.label(str(r[0]), 14)
		w.theme_type_variation = "Secondary"
		w.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		w.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		w.set_meta("bold", true)
		w.add_theme_font_override("font", UI.bold_font())
		h.add_child(w)
		var n := UI.label(str(r[1]), 16)
		n.theme_type_variation = "Number"
		n.add_theme_color_override("font_color", Tokens.color("gold_top"))
		n.set_meta("bold", true)
		h.add_child(n)
		v.add_child(h)
	p.add_child(v)
	return p


## The heist's loot panel (02-heist.png): "Room" and "Left" with their
## numbers, the load as a bar with a cream tick at the share the player aims
## for (`mark`, 0 to 1), and that aim in words beneath ("Load to 80%").
## `carried` is how full the crew is (0 to 1); the numbers say it too (§20.8).
static func loot(rows: Array, carried: float, mark: float, words: String) -> PanelContainer:
	var p := figures(rows, "leather")
	p.name = "Loot"
	var v := p.get_child(0) as VBoxContainer
	var said: Array[Label] = []
	var counts: Array[Label] = []
	for h: Node in v.get_children():
		said.append(h.get_child(0) as Label)
		counts.append(h.get_child(1) as Label)
	p.set_meta("words", said)
	p.set_meta("numbers", counts)
	var bar := KitBar.make(carried, Color(), 8.0)
	bar.name = "Load"
	bar.aim(mark)
	v.add_child(bar)
	if words != "":
		var l := UI.label(words, 14)
		l.name = "Caption"
		l.theme_type_variation = "Secondary"
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		l.set_meta("bold", true)
		l.add_theme_font_override("font", UI.bold_font())
		v.add_child(l)
	return p


## The clock as the key frame 02-heist.png draws it: Lilita One figures in
## tabular widths, cream with an ink outline and a drop, on parchment
## rounded 14 points with its gold edge; the alarm's red plate when
## `alarmed`. Larger than `clock`, and kept modest beside the crew.
static func clock_large(text: String, alarmed := false) -> PanelContainer:
	var p := PanelContainer.new()
	p.name = "Clock"
	p.set_meta("large", true)
	p.set_meta("alarmed", alarmed)
	var pad := UI.clear_box(14, 4)
	pad.content_margin_bottom = UI.px(6)
	p.add_theme_stylebox_override("panel", pad)
	UI.dress(p, "red" if alarmed else "parchment", 14)
	var l := UI.label(text, 26)
	l.name = "Time"
	l.add_theme_font_override("font", Tokens.font("display", 400, true))
	l.add_theme_color_override("font_color", Tokens.color("on_alarm" if alarmed else "cream"))
	l.add_theme_color_override("font_outline_color", Tokens.color("ink_line"))
	l.add_theme_constant_override("outline_size", _ink(26))
	l.add_theme_color_override("font_shadow_color", Tokens.color("drop"))
	l.add_theme_constant_override("shadow_offset_x", 0)
	l.add_theme_constant_override("shadow_offset_y", UI.px(1.5))
	l.set_meta("bold", true)
	p.add_child(l)
	return p


## A clock's new time, and its plate red or parchment as `alarmed` says,
## without building it again (`clock` or `clock_large`).
static func set_clock(p: PanelContainer, text: String, alarmed := false) -> void:
	var l := p.get_node("Time") as Label
	l.text = text
	if bool(p.get_meta("alarmed", false)) == alarmed:
		return
	p.set_meta("alarmed", alarmed)
	var large := bool(p.get_meta("large", false))
	UI.dress(p, "red" if alarmed else "parchment", 14 if large else 999)
	if large:
		l.add_theme_color_override("font_color", Tokens.color("on_alarm" if alarmed else "cream"))
	elif alarmed:
		l.add_theme_color_override("font_color", Tokens.color("on_alarm"))
		l.add_theme_color_override("font_outline_color", Tokens.color("ink_line"))
		l.add_theme_constant_override("outline_size", UI.px(3))
	else:
		l.remove_theme_color_override("font_color")
		l.remove_theme_color_override("font_outline_color")
		l.remove_theme_constant_override("outline_size")


## The alarm panel for a narrow column at any text size: with §20.8's large
## text the count stands under the word rather than run off the phone, and
## from past half the bells it is written in the alarm's red, as the bells
## are (the number says the level either way, §20.8). Named for a screen
## reader as "Alarm 4 / 6".
static func alarm_fit(level: int, of: int, title: String) -> PanelContainer:
	var p := alarm(level, of, title)
	p.set_meta("fit", true)
	var n := p.find_child("Count", true, false) as Label
	if Settings.text_scale > 130:
		var head := n.get_parent()
		head.remove_child(n)
		head.add_sibling(n)
		n.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	_raise(p, n, level, of)
	return p


## An alarm panel's new level (`alarm` or `alarm_fit`): its bells and its
## count, without building it again.
static func set_alarm(p: PanelContainer, level: int) -> void:
	var of := int(p.get_meta("of", 0))
	var row := p.find_child("Bells", true, false) as HBoxContainer
	for c: Node in row.get_children():
		row.remove_child(c)
		c.queue_free()
	for i: int in of:
		_bell(row, i, level, of)
	var n := p.find_child("Count", true, false) as Label
	n.text = "%d / %d" % [level, of]
	if bool(p.get_meta("fit", false)):
		_raise(p, n, level, of)


static func _raise(p: PanelContainer, n: Label, level: int, of: int) -> void:
	if level >= of / 2 + 1:
		n.add_theme_color_override("font_color", Tokens.color("alarm_text_on_night"))
	else:
		n.remove_theme_color_override("font_color")
	p.accessibility_name = Strings.t("HUD_ALARM", n.text)


## The loot panel for a narrow column, `width` points wide (2.3 times that
## with §20.8's large text, where the column is wider), in any language:
## the rows as two columns (words, then numbers: a face drawn in one call)
## while they fit, else a long row's number closer to its word and then
## under it; the caption wrapping between words; the aim's tick left out
## when `aim` is below 0 (a replay has no target); a thicker load bar.
## `vault` [word, number, fraction] adds the Vault's cracking: a third row,
## or with large text a thin bar beside its icon, lower than a row. Named
## for a screen reader with every number.
static func loot_fit(rows: Array, carried: float, aim: float, words: String, vault := [],
		width := 90.0) -> PanelContainer:
	var large := Settings.text_scale > 130
	var all := rows.duplicate()
	if not vault.is_empty() and not large:
		all.append([vault[0], vault[1]])
	var p := loot(all, carried, maxf(aim, 0.0), words)
	p.set_meta("fit", true)
	p.set_meta("vault", vault.duplicate())
	var v := p.get_child(0) as VBoxContainer
	var bar := v.get_node("Load") as KitBar
	bar.custom_minimum_size.y = UI.px(10)
	(bar.get_node("Aim") as Control).visible = aim >= 0.0
	_columns(v, all, UI.px(width) * (2.3 if large else 1.0))
	var caption := v.get_node_or_null("Caption") as Label
	if caption != null:
		caption.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		caption.custom_minimum_size.x = minf(_wide(words, 14), UI.px(width - 2.0))
	if not vault.is_empty() and large:
		var row := HBoxContainer.new()
		row.name = "Vault"
		row.add_theme_constant_override("separation", UI.px(4))
		var icon := Icons.view("heiststatus/vaultprogress", 16.0)
		icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		row.add_child(icon)
		var crack := KitBar.make(float(vault[2]), Color(), 5.0)
		crack.name = "Cracked"
		crack.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		row.add_child(crack)
		bar.add_sibling(row)
	_speak(p, all, words)
	return p


## A loot panel's new numbers (`loot` or `loot_fit`), without building it
## again: `rows` in the order it was built with (a row it was not built
## with is left out), the load easing to `fraction`, the aim's tick at `aim`
## (hidden below 0), the caption's words and, on `loot_fit`, the Vault's
## [word, number, fraction]. A change of language or text size builds it
## again.
static func set_loot(p: PanelContainer, rows: Array, fraction: float, aim: float, caption: String,
		vault := []) -> void:
	var all := rows.duplicate()
	var cracked := p.find_child("Cracked", true, false) as KitBar
	if not vault.is_empty():
		p.set_meta("vault", vault.duplicate())
		if cracked != null:
			Motion.fill(cracked, clampf(float(vault[2]), 0.0, 1.0))
		else:
			all.append([vault[0], vault[1]])
	var said: Array = p.get_meta("words", [])
	var counts: Array = p.get_meta("numbers", [])
	for i: int in mini(all.size(), said.size()):
		(said[i] as Label).text = str(all[i][0])
		(counts[i] as Label).text = str(all[i][1])
	var bar := p.find_child("Load", true, false) as KitBar
	Motion.fill(bar, clampf(fraction, 0.0, 1.0))
	var tick := bar.get_node_or_null("Aim") as Control
	if tick != null:
		tick.visible = aim >= 0.0
		tick.anchor_left = clampf(aim, 0.0, 1.0)
		tick.anchor_right = tick.anchor_left
	var l := p.find_child("Caption", true, false) as Label
	if l != null:
		l.text = caption
	if bool(p.get_meta("fit", false)):
		_speak(p, all.slice(0, said.size()), caption)


static func _speak(p: PanelContainer, rows: Array, words: String) -> void:
	var spoken := PackedStringArray()
	for r: Array in rows:
		spoken.append("%s %s" % [r[0], r[1]])
	var vault: Array = p.get_meta("vault", [])
	if not vault.is_empty() and p.find_child("Cracked", true, false) != null:
		spoken.append("%s %s" % [vault[0], vault[1]])
	if words != "":
		spoken.append(words)
	p.accessibility_name = ", ".join(spoken)


## Sets a loot panel's rows (in `v`) as two columns, words and numbers,
## where they fit in `room` pixels; else each long row stands its number
## closer to its word, and under it where even that is too wide.
static func _columns(v: VBoxContainer, rows: Array, room: float) -> void:
	var word := 0.0
	var number := 0.0
	for r: Array in rows:
		word = maxf(word, _wide(str(r[0]), 14))
		number = maxf(number, _wide(str(r[1]), 16))
	var lines: Array[Node] = []
	for c: Node in v.get_children():
		if c is HBoxContainer:
			lines.append(c)
	if word + number + UI.px(8) > room:
		for line: Node in lines:
			var n := line.get_child(1) as Label
			var wide := _wide((line.get_child(0) as Label).text, 14) + _wide(n.text, 16)
			if wide + UI.px(8) <= room:
				continue
			(line as HBoxContainer).add_theme_constant_override("separation", UI.px(2))
			if wide + UI.px(2) > room:
				line.remove_child(n)
				line.add_sibling(n)
				n.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		return
	var both := HBoxContainer.new()
	both.name = "Columns"
	both.add_theme_constant_override("separation", UI.px(8))
	var sides: Array[VBoxContainer] = [VBoxContainer.new(), VBoxContainer.new()]
	sides[0].size_flags_horizontal = Control.SIZE_EXPAND_FILL
	for side: VBoxContainer in sides:
		side.add_theme_constant_override("separation", UI.px(2))
		both.add_child(side)
	for line: Node in lines:
		for k: int in 2:
			var l := line.get_child(0) as Label
			line.remove_child(l)
			# One height for a word and its number, so the columns keep the rows.
			l.custom_minimum_size.y = ceilf(UI.text_px(16) * 1.4)
			l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			if k == 1:
				l.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
			sides[k].add_child(l)
		v.remove_child(line)
		line.queue_free()
	v.add_child(both)
	v.move_child(both, 0)


## A tip over the world for the heist (02-heist.png's "Tap crew, then
## ground"): leather rounded 14 points, its words bold in cream with an ink
## outline all round, whole and centred, wrapping rather than ending in an
## ellipsis. Reads at any text size where the glass `KitStatus.hint` thins.
static func tip(text: String) -> PanelContainer:
	var p := PanelContainer.new()
	p.name = "Tip"
	p.add_theme_stylebox_override("panel", UI.clear_box(14, 6))
	UI.dress(p, "leather", 14)
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	p.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var l := UI.label(text, 15, true)
	l.name = "Words"
	l.add_theme_font_override("font", UI.bold_font())
	l.add_theme_color_override("font_color", Tokens.color("cream"))
	l.add_theme_color_override("font_outline_color", Tokens.color("ink_line"))
	l.add_theme_constant_override("outline_size", _ink(15))
	l.set_meta("bold", true)
	p.add_child(l)
	return p


## An ink outline, in pixels, wide enough to count all round for words
## `points` tall (§21.8: 1.5 points or 12% of their size).
static func _ink(points: float) -> int:
	return UI.px(maxf(1.5, 0.12 * points) + 0.5)


## How wide words stand in the kit's bold face (measured before the piece
## is in the tree, where no theme reaches).
static func _wide(text: String, points: float) -> float:
	return ceilf(UI.bold_font().get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, UI.text_px(points)).x)


## The Sage beside the crew (02-heist.png): their portrait round in a gold
## ring, and Cast beneath it, a leather key with the wand over its word;
## `pressed` casts. The portrait is a picture, the key says what it does.
static func sage(picture: Texture2D, name: String, words: String, pressed: Callable) -> VBoxContainer:
	var v := VBoxContainer.new()
	v.name = "Sage"
	v.add_theme_constant_override("separation", UI.px(6))
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var face := PanelContainer.new()
	face.name = "Face"
	face.add_theme_stylebox_override("panel", UI.clear_box(0, 0))
	face.custom_minimum_size = Vector2.ONE * UI.px(60)
	face.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	face.mouse_filter = Control.MOUSE_FILTER_IGNORE
	face.accessibility_name = name
	var ring := KitRing.new()
	ring.picture = picture
	ring.band = Tokens.color("gold")
	ring.ground = Tokens.paint("#4A3A9A")
	ring.zoom = 1.3
	ring.focus = Vector2(0.5, 0.42)
	ring.mouse_filter = Control.MOUSE_FILTER_IGNORE
	face.add_child(ring)
	v.add_child(face)
	var cast := KitControls.big_action("heistcontrols/cast", words, pressed, "leather")
	cast.name = "Cast"
	v.add_child(cast)
	return v


## A diamond, filled or hollow (an ability's use).
class _Diamond:
	extends Control
	var full := true

	func _draw() -> void:
		var c := size * 0.5
		var r := minf(size.x, size.y) * 0.5
		var points := PackedVector2Array([c + Vector2(0, -r), c + Vector2(r, 0), c + Vector2(0, r), c + Vector2(-r, 0)])
		var cream := Tokens.color("cream")
		if full:
			draw_colored_polygon(points, cream)
		else:
			points.append(points[0])
			draw_polyline(points, cream, maxf(1.0, UI.px(0.8)), true)
