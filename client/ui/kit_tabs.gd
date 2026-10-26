class_name KitTabs
extends MarginContainer
## §21.8's five tabs: Islands, Laws, the Heist in the centre, Crew and
## Friends, as the designs draw them (10-roster.png): a full-width violet
## bar with a gold edge along its top, flush to the screen's foot; each tab
## an icon over its name in stroked capitals, parted by hairlines; the
## chosen tab a tall periwinkle tile with a gold rim that rises above the
## bar, half as wide again, its icon larger and bobbing; the Heist glowing
## gold when not chosen. The bar runs under the home bar, but every tab
## stays inside §21.1's safe area and clear of the corners, and each is a
## 48-point hit area at least. A badge writes its count (§20.8).

signal picked(id: String)

## [id, icon, label key], in the bar's order.
const TABS := [
	["islands", "screens/universe", "KIT_TAB_ISLANDS"],
	["laws", "screens/lawcodex", "KIT_TAB_LAWS"],
	["heist", "screens/heist", "KIT_TAB_HEIST"],
	["crew", "screens/roster", "KIT_TAB_CREW"],
	["friends", "screens/friendslist", "KIT_TAB_FRIENDS"],
]
## How far the chosen tab rises above the bar, in points.
const RISE := 18.0
## The largest text size, in percent, at which every tab shows its word.
const LABELS_UP_TO := 125

var active := ""
var buttons: Dictionary = {}
var _icons: Dictionary = {}
var _labels: Dictionary = {}
var _bobs: Dictionary = {}
var _glows: Dictionary = {}


## The bar with `chosen` chosen and a badge on each tab named in `badges`
## ({"heist": 4}). It sits last in a UI.frame column.
static func make(chosen: String, badges := {}) -> KitTabs:
	var t := KitTabs.new()
	t.name = "Tabs"
	# Out to the screen's edges and foot, past the column's safe margins.
	var side := UI.px(Tokens.number("size", "safe_side_points"))
	t.add_theme_constant_override("margin_left", -side)
	t.add_theme_constant_override("margin_right", -side)
	t.add_theme_constant_override("margin_bottom", -UI.px(Tokens.number("size", "safe_top_points")))
	var bar := PanelContainer.new()
	bar.name = "Bar"
	var pad := UI.clear_box(Tokens.number("size", "safe_side_points") + 4, 0)
	pad.content_margin_top = 0
	# Above the home bar and the bottom corners (§21.1: 8% of the frame).
	pad.content_margin_bottom = UI.px(Tokens.number("size", "safe_top_points") + Tokens.number("size",
		"tab_bar_lift"))
	bar.add_theme_stylebox_override("panel", pad)
	var box := UI.dress(bar, "tab_bar", 24)
	box.inset_top = UI.px(RISE)
	t.add_child(bar)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 0)
	bar.add_child(row)
	for i: int in TABS.size():
		if i > 0:
			row.add_child(t._divider())
		var tab: Array = TABS[i]
		row.add_child(t._tab(tab, int(badges.get(tab[0], 0))))
	t.choose(chosen, false)
	return t


func _divider() -> Control:
	var d := ColorRect.new()
	d.color = Color(Tokens.color("text_on_night_2"), 0.12)
	d.custom_minimum_size = Vector2(maxf(1.0, UI.px(0.5)), UI.px(36))
	d.size_flags_vertical = Control.SIZE_SHRINK_END
	d.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return d


func _tab(tab: Array, badge: int) -> Button:
	var id: String = tab[0]
	var words := Strings.t(tab[2])
	var b := UI.action("", func() -> void: _pick(id), "tab", words if badge == 0 else Strings.t(
		"KIT_TAB_BADGE", [words, badge]))
	b.name = "Tab_" + id
	b.custom_minimum_size = Vector2(UI.px(54), UI.px(Tokens.number("size", "tab_height")))
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b.size_flags_vertical = Control.SIZE_SHRINK_END
	b.set_meta("tab", id)
	var content := VBoxContainer.new()
	content.set_anchors_preset(Control.PRESET_FULL_RECT)
	content.alignment = BoxContainer.ALIGNMENT_END
	content.add_theme_constant_override("separation", 0)
	content.offset_bottom = -UI.px(4)
	content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var icon := Icons.view(str(tab[1]), 32)
	icon.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.add_child(icon)
	var l := UI.label(words, 13)
	l.theme_type_variation = "Tab"
	l.uppercase = true
	l.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	l.clip_text = true
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	l.add_theme_color_override("font_outline_color", Tokens.color("ink_deep"))
	l.set_meta("bold", true)
	content.add_child(l)
	b.add_child(content)
	if badge > 0:
		var tag := KitStatus.badge(str(badge))
		tag.set_anchors_preset(Control.PRESET_TOP_RIGHT)
		tag.position = Vector2(-UI.px(6), -UI.px(2))
		tag.grow_horizontal = Control.GROW_DIRECTION_BEGIN
		b.add_child(tag)
	buttons[id] = b
	_icons[id] = icon
	_labels[id] = l
	return b


func _pick(id: String) -> void:
	choose(id)
	picked.emit(id)


## Chooses a tab: it rises, widens and lights; the others settle.
func choose(id: String, animate := true) -> void:
	active = id
	for k: String in buttons:
		var b: Button = buttons[k]
		var on := k == id
		UI.set_look(b, "tab_active" if on else ("tab_heist" if k == "heist" else "tab"))
		b.size_flags_stretch_ratio = Tokens.number("size", "tab_active_grow") if on else 1.0
		b.custom_minimum_size.y = UI.px(Tokens.number("size", "tab_height") + (RISE if on else 0.0))
		var label: Label = _labels[k]
		label.add_theme_font_size_override("font_size", UI.text_px(15 if on else 13))
		label.set_meta("points", 15.0 if on else 13.0)
		# Five words at large text do not fit 360 points: the tabs not chosen
		# keep their icon and their spoken name, the chosen one its word too.
		label.visible = on or Settings.text_scale <= LABELS_UP_TO
		# Stroked in ink as the design draws it, wide enough (§21.8: 12% of
		# the size) that the words are read against their outline, which the
		# pale chosen tile alone (4.49:1) is not.
		label.add_theme_constant_override("outline_size", UI.px(2.0 if on else 1.5))
		if on:
			label.add_theme_color_override("font_color", Tokens.color("tab_label"))
		else:
			label.remove_theme_color_override("font_color")
		var icon: TextureRect = _icons[k]
		icon.custom_minimum_size = Vector2.ONE * UI.px(46 if on else 30)
		if _bobs.has(k):
			(_bobs[k] as Tween).kill()
			_bobs.erase(k)
		if on and animate:
			Motion.pop(icon)
		if on and is_inside_tree():
			var bob := Motion.bob(icon, 2.0)
			if bob != null:
				_bobs[k] = bob
		var box := RbBox.of(b)
		if _glows.has(k):
			(_glows[k] as Tween).kill()
			_glows.erase(k)
			box.self_modulate = Color.WHITE
		if k == "heist" and not on and is_inside_tree():
			var pulse := Motion.glow(box)
			if pulse != null:
				_glows[k] = pulse


func _ready() -> void:
	choose(active, false)
