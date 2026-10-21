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
