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
	row.add_theme_constant_override("separation", UI.px(2))
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	for i: int in of:
		var bell := Control.new()
		bell.custom_minimum_size = Vector2(UI.px(9), UI.px(12))
		bell.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var lit := Tokens.color("warn") if i < of / 2 else Tokens.color("alarm")
		row.add_child(bell)
		RbBox.dress(bell, "bar_track", 3)
		if i < level:
			RbBox.of(bell).tint(lit.lightened(0.3), lit)
	v.add_child(row)
	var l := UI.label(words, 13)
	l.theme_type_variation = "Caption"
	l.set_meta("bold", true)
	l.add_theme_font_override("font", UI.bold_font())
	v.add_child(l)
	return v


## The clock: tabular figures on parchment, the alarm's red plate under
## thirty seconds (`warning`), its words staying readable on either.
static func clock(text: String, warning := false) -> PanelContainer:
	var p := PanelContainer.new()
	p.name = "Clock"
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
	ring.custom_minimum_size = Vector2.ONE * UI.px(points)
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
	v.add_child(u)
	ring.add_child(v)
	return ring


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
static func crew(picture: Texture2D, name: String, health: float, uses: int, pressed: Callable,
		school := "") -> VBoxContainer:
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
	var bar := KitBar.make(health, Tokens.color("success"), 8)
	bar.custom_minimum_size.x = UI.px(54)
	bar.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	v.add_child(bar)
	var n := UI.label(name, 14)
	n.add_theme_font_override("font", UI.bold_font())
	n.add_theme_color_override("font_color", Tokens.color("text_on_night"))
	n.add_theme_color_override("font_outline_color", Tokens.color("ink_line"))
	n.add_theme_constant_override("outline_size", UI.px(2))
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
	var bar := KitBar.make(carried, Color(), 8.0)
	bar.name = "Load"
	var tick := ColorRect.new()
	tick.name = "Aim"
	tick.color = Tokens.color("cream")
	tick.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tick.anchor_left = clampf(mark, 0.0, 1.0)
	tick.anchor_right = tick.anchor_left
	tick.anchor_bottom = 1.0
	tick.offset_left = -UI.px(1.5)
	tick.offset_right = UI.px(1.5)
	tick.offset_top = -UI.px(2)
	tick.offset_bottom = UI.px(2)
	bar.add_child(tick)
	v.add_child(bar)
	if words != "":
		var l := UI.label(words, 14)
		l.theme_type_variation = "Secondary"
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		l.set_meta("bold", true)
		l.add_theme_font_override("font", UI.bold_font())
		v.add_child(l)
	return p


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
