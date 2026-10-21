class_name KitTabs
extends MarginContainer
## §21.8's five tabs: Islands, Laws, the Heist in the centre, Crew and
## Friends, on a dark bar inside the safe area and clear of the corners
## (§21.1: five 54-point tabs fit in 390 points; each is a 48-point hit
## area at least). The chosen tab grows, takes the designs' periwinkle with
## its gold rim, and its icon rises and bobs; the Heist glows gold when not
## chosen. A badge carries a count in words as well as its red (§20.8).

signal picked(id: String)

## [id, icon, label key], in the bar's order.
const TABS := [
	["islands", "screens/universe", "KIT_TAB_ISLANDS"],
	["laws", "screens/lawcodex", "KIT_TAB_LAWS"],
	["heist", "screens/heist", "KIT_TAB_HEIST"],
	["crew", "screens/roster", "KIT_TAB_CREW"],
	["friends", "screens/friendslist", "KIT_TAB_FRIENDS"],
]

var active := ""
var buttons: Dictionary = {}
var _icons: Dictionary = {}
var _bobs: Dictionary = {}
var _glows: Dictionary = {}


## The bar with `chosen` chosen and a badge on each tab named in `badges`
## ({"heist": 4}).
static func make(chosen: String, badges := {}) -> KitTabs:
	var t := KitTabs.new()
	t.name = "Tabs"
	t.add_theme_constant_override("margin_bottom", UI.px(Tokens.number("size", "tab_bar_lift")))
	var bar := PanelContainer.new()
	bar.add_theme_stylebox_override("panel", UI.clear_box(6, 6))
	UI.dress(bar, "card", 24)
	t.add_child(bar)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", UI.px(4))
	bar.add_child(row)
	for tab: Array in TABS:
		var b := t._tab(tab, int(badges.get(tab[0], 0)))
		row.add_child(b)
	t.choose(chosen, false)
	return t


func _tab(tab: Array, badge: int) -> Button:
	var id: String = tab[0]
	var words := Strings.t(tab[2])
	var b := UI.action("", func() -> void: _pick(id), "tab", words if badge == 0 else Strings.t(
		"KIT_TAB_BADGE", [words, badge]))
	b.name = "Tab_" + id
	b.custom_minimum_size = Vector2(UI.px(54), UI.px(Tokens.number("size", "tab_height")))
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b.set_meta("tab", id)
	var content := VBoxContainer.new()
	content.set_anchors_preset(Control.PRESET_FULL_RECT)
	content.alignment = BoxContainer.ALIGNMENT_CENTER
	content.add_theme_constant_override("separation", 0)
	content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var icon := Icons.view(str(tab[1]), 30)
	icon.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.add_child(icon)
	var l := UI.label(words, 13)
	l.theme_type_variation = "Tab"
	l.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	l.clip_text = true
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.add_child(l)
	b.add_child(content)
	if badge > 0:
		var tag := KitStatus.badge(str(badge))
		tag.set_anchors_preset(Control.PRESET_TOP_RIGHT)
		tag.position = Vector2(-UI.px(4), -UI.px(6))
		tag.grow_horizontal = Control.GROW_DIRECTION_BEGIN
		b.add_child(tag)
	buttons[id] = b
	_icons[id] = icon
	return b


func _pick(id: String) -> void:
	choose(id)
	picked.emit(id)


## Chooses a tab: it grows and lights; the others settle.
func choose(id: String, animate := true) -> void:
	active = id
	for k: String in buttons:
		var b: Button = buttons[k]
		var on := k == id
		UI.set_look(b, "tab_active" if on else ("tab_heist" if k == "heist" else "tab"))
		b.size_flags_stretch_ratio = Tokens.number("size", "tab_active_grow") if on else 1.0
		var label := b.find_children("*", "Label", true, false)[0] as Label
		label.theme_type_variation = "Tab"
		if on:
			label.add_theme_color_override("font_color", Tokens.color("tab_label"))
			label.add_theme_color_override("font_outline_color", Tokens.color("ink_deep"))
			label.add_theme_constant_override("outline_size", UI.px(1.5))
		else:
			label.remove_theme_color_override("font_color")
			label.remove_theme_constant_override("outline_size")
		var icon: TextureRect = _icons[k]
		icon.custom_minimum_size = Vector2.ONE * UI.px(38 if on else 28)
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
