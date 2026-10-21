class_name ScreenNav
extends RefCounted
## The app shell of the design (SCREENS.md, §21.8): a header with a round
## back button and the screen's title in Marcellus, the five tabs along the
## bottom (Islands, Laws, Heist, Crew, Friends) with the Heist in the
## centre, and the gold hub control under the header of the Laws and Crew
## hubs. Tabs sit inside the safe area, 54 points or more each, 48 tall.

## The five tabs: their route, icon and words, in the design's order.
const TABS := [
	{"key": "islands", "route": &"home", "icon": "universe", "words": "NAV_ISLANDS"},
	{"key": "laws", "route": &"codex", "icon": "lawcodex", "words": "NAV_LAWS"},
	{"key": "heist", "route": &"observatory", "icon": "heist", "words": "NAV_HEIST"},
	{"key": "crew", "route": &"roster", "icon": "roster", "words": "NAV_CREW"},
	{"key": "friends", "route": &"friends", "icon": "friendslist", "words": "NAV_FRIENDS"},
]
## How far the tab bar sits above the safe area: the corners' band is 8% of
## the frame's height (21.1's corners as the build checks them), 187 of 2340
## pixels, of which the safe area is 132.
const CORNER_LIFT_POINTS := 20.0
## The hubs: a tab that opens several screens, chosen by the gold control.
const HUBS := {
	"laws": [{"route": &"codex", "words": "HUB_ALL_LAWS"}, {"route": &"harmony", "words": "HUB_HARMONY"},
		{"route": &"lab", "words": "HUB_LAB"}],
	"crew": [{"route": &"roster", "words": "HUB_ROSTER"}, {"route": &"sages", "words": "HUB_SAGES"},
		{"route": &"forms", "words": "HUB_FORMS"}],
}


## The header: the screen's title in Marcellus and `right` (a pill, a count)
## at its end. It holds no control: §21.1 puts a sub-screen's back control in
## the lower band, in thumb reach, and the dock carries it.
static func header(title: String, right: Control = null) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", UI.px(8))
	var t := ScreenKit.text(title, 26.0, "name", "card")
	ScreenKit.inked(t, 1.0)
	t.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	t.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	t.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	t.accessibility_live = AccessibilityServer.LIVE_OFF
	t.name = "Title"
	row.add_child(t)
	if right != null:
		right.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		row.add_child(right)
	return row


## The lowest band of a sub-screen (§21.1): the round back button to `back`,
## then the screen's actions sharing the rest, clear of the corners.
static func dock(back: StringName, actions: Array = []) -> MarginContainer:
	var row := UI.row(8.0, true)
	row.add_child(back_button(back))
	for a: Control in actions:
		row.add_child(a)
	var m := UI.narrow(row)
	m.name = "Dock"
	return m


## A round leather back button, 48 points, going to `back`.
static func back_button(back: StringName) -> Button:
	var b := ScreenKit.button("", func() -> void: App.services.router.go(back), "leather",
		Strings.t("SCREEN_BACK"), -1.0)
	var path := ScreenKit.icon_path("generalui", "back")
	if path != "":
		b.icon = load(path)
		b.expand_icon = true
		b.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
		b.add_theme_constant_override("icon_max_width", UI.px(26))
	b.custom_minimum_size = Vector2.ONE * UI.CONTROL_POINTS * UI.PX_PER_POINT
	b.set_meta("back", true)
	b.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	return b


## The hub control for `hub` with `route` chosen.
static func hub(name: String, route: StringName) -> PanelContainer:
	var options: Array = []
	for h: Dictionary in HUBS[name]:
		options.append({"text": Strings.t(str(h["words"])), "key": h["route"], "on": h["route"] == route})
	var s := ScreenParts.segmented(options, func(r: StringName) -> void:
		if r != route:
			App.services.router.go(r))
	s.name = "Hub"
	return s


## The tab bar with `active` raised; `badges` maps a tab's key to a count.
static func bar(active: String, badges := {}) -> VBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", UI.px(3))
	for t: Dictionary in TABS:
		var on: bool = t["key"] == active
		row.add_child(_tab(t, on, int(badges.get(t["key"], 0))))
	var p := ScreenKit.panel("tab", row, 22.0, 4.0)
	var box := p.get_theme_stylebox("panel") as ScreenBox
	box.line_px = UI.px(1.4)
	box.rim = Color("#E9B65C55")
	box.rim_px = UI.px(1.0)
	box.drop_px = UI.px(3.0)
	box.drop = Color("#0A0408")
	p.name = "Tabs"
	# Lifted clear of the bottom corners (§21.1): the outer tabs reach the
	# sides, so the bar ends above the corners' band.
	var lift := VBoxContainer.new()
	lift.add_theme_constant_override("separation", 0)
	lift.add_child(p)
	var gap := Control.new()
	gap.custom_minimum_size.y = UI.px(CORNER_LIFT_POINTS)
	gap.mouse_filter = Control.MOUSE_FILTER_IGNORE
	lift.add_child(gap)
	lift.name = "TabBar"
	return lift


static func _tab(t: Dictionary, on: bool, count: int) -> Control:
	var words := Strings.t(str(t["words"]))
	var b := ScreenKit.button("", func() -> void:
		if not on:
			App.services.router.go(t["route"]), "active" if on else "tab", words, 16.0)
	if not on:
		var flat := ScreenKit.box("tab", 16.0, 2.0)
		flat.top = Color(0, 0, 0, 0)
		flat.bottom = Color(0, 0, 0, 0)
		b.add_theme_stylebox_override("normal", flat)
	b.custom_minimum_size = Vector2(UI.px(54), UI.px(58 if on else 54))
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b.size_flags_stretch_ratio = 1.6 if on else 1.0
	b.set_meta("tab", t["key"])
	b.set_meta("on", on)
	var col := VBoxContainer.new()
	col.set_anchors_preset(Control.PRESET_FULL_RECT)
	col.alignment = BoxContainer.ALIGNMENT_CENTER
	col.add_theme_constant_override("separation", 0)
	col.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var i := ScreenKit.icon("screens", str(t["icon"]), 34.0 if on else 28.0)
	i.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	col.add_child(i)
	var l := ScreenKit.text(words, 13.0, "words", "active" if on else "tab", not on)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	if on:
		ScreenKit.inked(l, 1.6)
	col.add_child(l)
	b.add_child(col)
	b.custom_minimum_size.y = maxf(b.custom_minimum_size.y, UI.px(34 if on else 28) + l.get_minimum_size().y)
	if count > 0:
		var badge := ScreenParts.badge(str(count))
		badge.set_anchors_preset(Control.PRESET_TOP_RIGHT)
		badge.position = Vector2(-UI.px(20), UI.px(2))
		b.add_child(badge)
	return b
