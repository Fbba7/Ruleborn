class_name ScreenNav
extends RefCounted
## The app shell of the design (SCREENS.md, §21.8) on T9's pieces: a header
## with the screen's title, the bottom dock with the round back button and
## the screen's actions, the hub's gold control and the five tabs. Where
## each tab and hub segment goes is the router's (Router.TABS, Router.HUBS).
## §21.1 keeps every frequently used control in the lower two-thirds: the
## header holds no control, the hub sits above the tabs, and a sub-screen's
## back control is the first of its dock.

## How far the dock stands above the safe area: the corners' band is 8% of
## the frame's height as the build checks it (187 of 2340 pixels), of which
## the safe area is 132.
const CORNER_LIFT_POINTS := 20.0
## The largest text size, in percent, at which every tab shows its word.
const LABELS_UP_TO := 125


## The header: the title (T9's, with its gold rule) and `right` (a pill, a
## count) at its end.
static func header(title: String, right: Control = null) -> BoxContainer:
	# At large text the title and its pill stack, rather than widen the screen.
	var row: BoxContainer = VBoxContainer.new()
	if Settings.text_scale <= 125:
		row = HBoxContainer.new()
	row.add_theme_constant_override("separation", UI.px(8))
	var h := KitNav.header(title)
	h.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(h)
	var t := h.find_children("*", "Label", true, false)[0] as Label
	t.name = "Title"
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	t.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	t.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	if right != null:
		right.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		right.size_flags_horizontal = Control.SIZE_SHRINK_END if row is HBoxContainer else Control.SIZE_SHRINK_BEGIN
		row.add_child(right)
	return row


## The lowest band of a sub-screen (§21.1): the back button to `back`, then
## the screen's actions. It stands above the corners' band, as the tab bar
## does, so it may use the frame's width; it wraps at large text.
static func dock(back: StringName, actions: Array = []) -> MarginContainer:
	var back_b := back_button(back)
	# One line, the actions sharing the width after the back button, when
	# they fit it; else a row that wraps.
	var wide := back_b.get_combined_minimum_size().x
	for a: Control in actions:
		wide += a.get_combined_minimum_size().x + UI.px(8)
	var room := UI.px(360.0 - 2.0 * Tokens.number("size", "safe_side_points"))
	var row: Container = UI.row(8.0, true)
	if wide <= room:
		var line := HBoxContainer.new()
		line.add_theme_constant_override("separation", UI.px(8))
		line.alignment = BoxContainer.ALIGNMENT_CENTER
		if Settings.left_handed:
			line.layout_direction = Control.LAYOUT_DIRECTION_RTL
		line.set_meta("thumb", true)
		row = line
	row.add_child(back_b)
	for a: Control in actions:
		row.add_child(a)
	var m := MarginContainer.new()
	m.add_theme_constant_override("margin_bottom", UI.px(CORNER_LIFT_POINTS))
	m.add_child(row)
	m.name = "Dock"
	return m


## T9's round back button, going to `back`.
static func back_button(back: StringName) -> Button:
	var b := KitNav.back(func() -> void: App.services.router.go(back))
	b.set_meta("back", true)
	b.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	return b


## The hub control for `name` with `route` chosen.
static func hub(name: String, route: StringName) -> PanelContainer:
	var options: Array = []
	var routes: Array = []
	var chosen := 0
	for h: Dictionary in Router.HUBS[name]:
		if h["route"] == route:
			chosen = routes.size()
		options.append(Strings.t(str(h["words"])))
		routes.append(h["route"])
	# At large text three words do not fit one strip: chips that wrap, so no
	# word is broken.
	if Settings.text_scale > 125:
		var row := ScreenParts.flow(6.0)
		row.alignment = FlowContainer.ALIGNMENT_CENTER
		for i: int in options.size():
			var to: StringName = routes[i]
			row.add_child(ScreenParts.chip(str(options[i]), i == chosen, func() -> void:
				if to != route:
					App.services.router.go(to)))
		var p := ScreenKit.panel("well", row, 18.0, 6.0)
		p.name = "Hub"
		return p
	var s := KitNav.segmented(options, chosen, func(i: int) -> void:
		if routes[i] != route:
			App.services.router.go(routes[i]))
	for b: Button in s.find_children("*", "Button", true, false):
		b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		b.custom_minimum_size.x = UI.CONTROL_POINTS * UI.PX_PER_POINT
	s.name = "Hub"
	return s


## The five tabs with `active` chosen; a tab goes to its route.
static func bar(active: String, badges := {}) -> KitTabs:
	var t := KitNav.tabs(active, badges)
	t.picked.connect(func(id: String) -> void:
		if id != active:
			App.services.router.go(Router.TABS[id]))
	# The chosen tab's word in the design's thick ink stroke (10-roster.png),
	# wide enough that §21.8 measures it against the stroke.
	if t.buttons.has(active):
		for l: Label in (t.buttons[active] as Button).find_children("*", "Label", true, false):
			l.add_theme_constant_override("outline_size", UI.px(maxf(2.0, 0.12 * float(l.get_meta("points", 15.0)))))
	# Five words at large text do not fit 360 points: the tabs not chosen keep
	# their icon and their spoken name, the chosen one its word too.
	if Settings.text_scale > LABELS_UP_TO:
		for id: String in t.buttons:
			if id != active:
				for l: Label in (t.buttons[id] as Button).find_children("*", "Label", true, false):
					l.visible = false
	return t

