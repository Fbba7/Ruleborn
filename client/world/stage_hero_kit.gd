class_name StageHeroKit
extends RefCounted
## The design's small pieces for the character screens (§21.8), on
## StageHeroMaterial's materials: kickers, chips, tabs, cards with a kicker,
## stat rows and the round arrow. Information is shown as the design shows
## it — a word on a chip, a number on a bar — never as a sentence listing it.

## A kicker's tracking, as the design spaces its small capitals.
static var _tracked: FontVariation = null


## Words in the client's bold face, in `colour`, edged in ink when `edged`
## so they hold on any fill.
static func words(text: String, points: float, colour: Color, edged := false) -> Label:
	var l := UI.label(text, points)
	l.add_theme_font_override("font", UI.bold_font())
	l.add_theme_color_override("font_color", colour)
	l.set_meta("own_ink", true)
	l.set_meta("bold", true)
	if edged:
		l.add_theme_color_override("font_outline_color", Color("#120C2A"))
		l.add_theme_constant_override("outline_size", UI.px(2))
	return l


## `l` wraps onto more lines when its column is narrow, but never below its
## own width up to `cap_points`, so a short word is never broken inside.
static func wrapped(l: Label, cap_points := 120.0) -> Label:
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.custom_minimum_size.x = UI.px(minf(cap_points, 60.0))
	# Measured as drawn, once the label has its theme: unwrapped, on its
	# longest word and on the whole.
	l.ready.connect(func() -> void:
		var said := l.text
		l.autowrap_mode = TextServer.AUTOWRAP_OFF
		l.custom_minimum_size.x = 0
		var longest := 0.0
		for word: String in said.split(" "):
			l.text = word
			longest = maxf(longest, l.get_minimum_size().x)
		l.text = said
		var whole := l.get_minimum_size().x
		# Between words only: a word is never split.
		l.autowrap_mode = TextServer.AUTOWRAP_WORD
		l.custom_minimum_size.x = maxf(longest + UI.px(2), minf(whole + UI.px(2), UI.px(cap_points))))
	return l


## A kicker: a card's small capital heading, tracked wide, in gold.
static func kicker(text: String, colour := Color("#E9B65C")) -> Label:
	if _tracked == null:
		_tracked = FontVariation.new()
		_tracked.base_font = ThemeDB.fallback_font
		_tracked.variation_embolden = 0.8
		_tracked.spacing_glyph = 2
	var l := UI.label(text.to_upper(), 13.0)
	l.add_theme_font_override("font", _tracked)
	l.add_theme_color_override("font_color", colour)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	# A kicker wraps: tracked wide in capitals, a long language's runs past
	# the phone (French's every-fifth-level heading). A short one keeps its
	# own width, so it never breaks inside a word.
	wrapped(l, 100.0)
	l.set_meta("own_ink", true)
	l.set_meta("bold", true)
	return l


## A chip: a glyph or an icon and a word on a pill of `kind` (a material
## or a colour);
## its words wrap when `wraps`, for a chip that may hold a phrase.
static func chip(text: String, kind := "glass", glyph := "", wraps := false) -> PanelContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", UI.px(4))
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	var ink := StageHeroMaterial.ink(kind)
	# A glyph, or one of the design's icons by its name ("traits/swift").
	if glyph.contains("/"):
		if Icons.has(glyph):
			row.add_child(Icons.view(glyph, 20.0))
	elif glyph != "":
		row.add_child(words(glyph, 14.0, ink))
	var said := words(text, 14.0, ink)
	# At §20.8's larger text every chip may wrap, so none outgrows the phone.
	wraps = wraps or Settings.text_scale > 100
	if wraps:
		wrapped(said, 160.0)
		said.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(said)
	var p := StageHeroMaterial.panel(kind, row, 999.0, 10.0)
	p.add_theme_stylebox_override("panel", UI.clear_box(10, 4))
	p.size_flags_horizontal = Control.SIZE_FILL if wraps else Control.SIZE_SHRINK_BEGIN
	p.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return p


## A card on the night: a kicker and what it heads, in a dark violet card
## with a gold rim (§21.8).
static func card(heading: String, body: Control, kind := "card") -> PanelContainer:
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", UI.px(4))
	if heading != "":
		v.add_child(kicker(heading))
	v.add_child(body)
	var p := StageHeroMaterial.panel(kind, v, 16.0, 12.0)
	p.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return p


## A paragraph on a card, left-aligned and wrapping.
static func para(words_shown: String, points := 16.0, colour := Color("#F3EEFF")) -> Label:
	var l := UI.label(words_shown, points, true)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	l.add_theme_color_override("font_color", colour)
	l.set_meta("own_ink", true)
	l.custom_minimum_size.x = UI.px(60)
	return l


## A segmented control: one button a name, each with its icon when given,
## the chosen one on the kit's gold chip, the rest on its glass chips, as
## the design's hub and tabs. `pick` takes the index.
static func tabs(names: Array, chosen: int, pick: Callable, icons: Array = []) -> PanelContainer:
	# One row; rows that wrap when the words are long (§20.8's larger text, or
	# a language's longer words).
	var row: Container = HBoxContainer.new()
	row.add_theme_constant_override("separation", UI.px(4))
	if Settings.text_scale > 100 or "".join(names).length() > (16 if not icons.is_empty() else 22):
		row = HFlowContainer.new()
		row.add_theme_constant_override("h_separation", UI.px(4))
		row.add_theme_constant_override("v_separation", UI.px(4))
	for i: int in names.size():
		# The kit's segmented control, as the design's: the chosen segment a
		# gold tab inside the track, the rest words on the track.
		var b := UI.action(str(names[i]), pick.bind(i), "seg_on" if i == chosen else "seg")
		b.add_theme_font_size_override("font_size", UI.text_px(15))
		b.set_meta("points", 15.0)
		for state: String in ["normal", "hover", "pressed", "focus", "disabled"]:
			b.add_theme_stylebox_override(state, UI.clear_box(6, 4))
		if i < icons.size() and Icons.has(str(icons[i])):
			b.icon = Icons.texture(str(icons[i]))
			b.add_theme_constant_override("icon_max_width", UI.px(20))
			b.add_theme_constant_override("h_separation", UI.px(4))
			UI.fit(b)
			b.custom_minimum_size.x += UI.px(22)
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.set_meta("item", "tab:%d" % i)
		b.set_meta("chosen", i == chosen)
		b.accessibility_name = Strings.t("WORKSHOP_TAB_SHOWN" if i == chosen else "WORKSHOP_TAB_SHOW", str(names[i]))
		row.add_child(b)
	var p := StageHeroMaterial.panel("well", row, 14.0, 4.0)
	UI.dress(p, "seg_track", 14.0)
	p.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return p


## Two columns of cards that fall to one at large text (§20.8).
static func grid(cells: Array, screen: Control) -> GridContainer:
	var g := GridContainer.new()
	g.columns = 1 if StageHeroSkin.columns(screen, 150.0) < 2 else 2
	g.add_theme_constant_override("h_separation", UI.px(8))
	g.add_theme_constant_override("v_separation", UI.px(8))
	g.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	for c: Control in cells:
		c.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		g.add_child(c)
	return g


## The design's round arrow on a stage: the kit's leather disc with its
## arrow icon, named for a screen reader.
static func arrow(back: bool, spoken: String, go: Callable) -> Button:
	return KitControls.icon_button("hud/prev" if back else "hud/next", spoken, go, "leather", 48.0)


## A character's name plate: the name in Marcellus, light, edged in ink; and
## under it its school on a chip in the school's colour with its shape
## (§21.2), and `sub` (its kind and role).
static func name_plate(name: Label, school: String, sub: String) -> Control:
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", UI.px(4))
	StageHeroSkin.named(name)
	name.add_theme_font_size_override("font_size", UI.text_px(32))
	name.set_meta("points", 32.0)
	name.add_theme_color_override("font_color", StageHeroSkin.LIGHT)
	name.add_theme_color_override("font_outline_color", Color("#120C2A"))
	name.add_theme_constant_override("outline_size", UI.px(2))
	name.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	name.set_meta("own_ink", true)
	v.add_child(name)
	var line := HFlowContainer.new()
	line.add_theme_constant_override("h_separation", UI.px(8))
	var colour: Color = Palette.SCHOOL.get(school, Palette.MOTION)
	line.add_child(chip(Strings.t("SCHOOL_" + school.to_upper()).to_upper(),
		"#" + colour.darkened(0.55).to_html(false), "schools/" + school))
	var under := wrapped(words(sub, 16.0, StageHeroSkin.LIGHT_SOFT), 100.0)
	under.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	line.add_child(under)
	v.add_child(line)
	return v


## The level on a gold hexagon, a bar of the levels its home allows, and its
## health on a chip (none when `health` is negative).
static func level_row(level: int, top: int, health := -1) -> Control:
	var row := HFlowContainer.new()
	row.add_theme_constant_override("h_separation", UI.px(10))
	row.add_theme_constant_override("v_separation", UI.px(6))
	top = maxi(1, top)
	row.add_child(StageHeroHex.make(str(level), Strings.t("CHARACTER_LEVEL_SHORT"), 58.0))
	var v := VBoxContainer.new()
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	v.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	# Wide enough at large text for its words on one line; the health chip
	# then flows under it.
	v.custom_minimum_size.x = UI.px(110 if Settings.text_scale <= 125 else 190)
	v.add_theme_constant_override("separation", UI.px(4))
	# The design's segmented bar: a green segment for each level reached on
	# a dark track, the words inside it edged in ink.
	var track := PanelContainer.new()
	var well := StyleBoxFlat.new()
	well.bg_color = Color("#120C2A")
	well.border_color = Color("#0A0618")
	well.set_border_width_all(UI.px(2))
	well.set_corner_radius_all(UI.px(10))
	well.set_content_margin_all(UI.px(3))
	track.add_theme_stylebox_override("panel", well)
	var stack := MarginContainer.new()
	var steps := HBoxContainer.new()
	steps.add_theme_constant_override("separation", UI.px(2))
	for i: int in mini(top, 20):
		var step := Panel.new()
		var fill := StyleBoxFlat.new()
		var lit := i < roundi(float(level) / float(top) * mini(top, 20))
		fill.bg_color = Color("#4FC384") if lit else Color("#2A2050")
		fill.border_color = Color("#A8F0B8") if lit else Color("#2A2050")
		fill.border_width_top = UI.px(2) if lit else 0
		fill.set_corner_radius_all(UI.px(6))
		step.add_theme_stylebox_override("panel", fill)
		step.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		step.custom_minimum_size = Vector2(UI.px(4), UI.px(22))
		step.mouse_filter = Control.MOUSE_FILTER_IGNORE
		steps.add_child(step)
	stack.add_child(steps)
	var said := words(Strings.t("CHARACTER_LEVEL_OF", [level, top]), 14.0, StageHeroSkin.LIGHT, true)
	said.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	said.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	said.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	said.custom_minimum_size.x = UI.px(60)
	track.add_child(stack)
	track.set_meta("behind", [well.bg_color] as Array[Color])
	v.add_child(track)
	# At large text the words go under the bar, where they have the width;
	# inside it they would break a line between every word.
	if Settings.text_scale > 125:
		v.add_child(said)
	else:
		stack.add_child(said)
	row.add_child(v)
	if health >= 0:
		var heart := chip("%d" % health, "card", "♥")
		heart.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		heart.accessibility_name = Strings.t("CHARACTER_STAT_SPOKEN", [Strings.t("CHARACTER_STAT_HEALTH"), str(health)])
		row.add_child(heart)
	return row


## The crew's hub, as the design heads the Roster, the Sage hall and the
## Forms album: one segment each with its icon, the open one in gold; a tap
## on another goes there.
static func hub(open: int) -> PanelContainer:
	var routes: Array[StringName] = [&"roster", &"sages", &"forms"]
	var p := tabs([Strings.t("CREW_HUB_ROSTER"), Strings.t("CREW_HUB_SAGES"), Strings.t("CREW_HUB_FORMS")], open,
		func(i: int) -> void:
			if i != open:
				App.services.router.go(routes[i]),
		["screens/roster", "screens/sagehall", "screens/formsalbum"])
	p.name = "Hub"
	return p


## The design's five tabs at the foot of a crew screen, Crew chosen; a tab
## goes where the app's bar sends it (Islands home, Laws the Codex, Heist
## the Observatory, Friends the friends list).
static func tab_bar() -> KitTabs:
	var routes := {"islands": &"home", "laws": &"codex", "heist": &"observatory", "crew": &"roster",
		"friends": &"friends"}
	var t := KitNav.tabs("crew")
	# The chosen tab's 15-point word on the kit's 1.5-point outline reads
	# 4.49:1 on its tile; at 2 points (past §21.8's 12%) it stands on the ink.
	for l: Label in (t.buttons["crew"] as Button).find_children("*", "Label", true, false):
		l.add_theme_constant_override("outline_size", UI.px(2))
	t.picked.connect(func(to: String) -> void:
		if to != "crew":
			App.services.router.go(routes[to]))
	# Five words do not fit at large text: the tabs not chosen keep their
	# icon and spoken name.
	if Settings.text_scale > 125:
		for key: String in t.buttons:
			if key != "crew":
				for l: Label in (t.buttons[key] as Button).find_children("*", "Label", true, false):
					l.visible = false
	return t
