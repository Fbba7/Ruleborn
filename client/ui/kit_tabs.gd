class_name KitTabs
extends MarginContainer
## §21.8's five tabs: Islands, Laws, the Heist in the centre, Crew and
## Friends, as the designs draw them (10-roster.png): a full-width violet
## bar with a gold edge along its top, flush to the screen's foot; each tab
## an icon over its name in stroked capitals, parted by hairlines; the
## chosen tab a tall periwinkle tile with a gold rim that rises above the
## bar, half as wide again, its icon larger and bobbing; the Heist glowing
## gold when not chosen. Each name sits under its tile, on the bar, never
## across the tile's gold rim (10-roster.png, board 3's dock). The bar runs
## under the home bar, but every tab
## stays inside §21.1's safe area and clear of the corners, and each is a
## 48-point hit area at least. A badge writes its count (§20.8).

signal picked(id: String)

## [id, icon, label key], in the bar's order: the design's own tab icons
## (tools/ui/export_icons.mjs takes them from its tab bar).
const TABS := [
	["islands", "tabs/islands", "KIT_TAB_ISLANDS"],
	["laws", "tabs/codex", "KIT_TAB_LAWS"],
	["heist", "tabs/heist", "KIT_TAB_HEIST"],
	["crew", "tabs/crew", "KIT_TAB_CREW"],
	["friends", "tabs/friends", "KIT_TAB_FRIENDS"],
]
## How far the chosen tab rises above the bar, in points.
const RISE := 18.0
## The clear space between a tile's gold rim and the name under it, in points.
const RIM := 2.0
## How wide the chosen tile and the Heist's stand, in points, inside their
## tab's share of the bar.
const TILE := 62.0
const HEIST_TILE := 46.0
## How large the chosen tab's own icon stands, inside its tile, in points.
const ICON := 54.0
## How large a face given to the chosen tab stands, in points.
const FACE := 62.0
## The widest the chosen tab may grow, against a tab not chosen, to show its
## whole word at large text; the others keep §21.1's 48 points.
const MOST_GROW := 3.0

var active := ""
var buttons: Dictionary = {}
var _icons: Dictionary = {}
var _labels: Dictionary = {}
var _bobs: Dictionary = {}
var _faces: Dictionary = {}
var _plain: Dictionary = {}
var _glows: Dictionary = {}
var _tiles: Dictionary = {}


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
	# Its sides and foot run off the screen: only the gold top edge shows.
	box.bleed = UI.px(32)
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
	# §21.1's 48 points: the share past it goes to the chosen tab's word at large text.
	b.custom_minimum_size = Vector2(UI.px(UI.CONTROL_POINTS), UI.px(Tokens.number("size", "tab_height")))
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b.size_flags_vertical = Control.SIZE_SHRINK_END
	b.set_meta("tab", id)
	var content := VBoxContainer.new()
	content.name = "Content"
	content.set_anchors_preset(Control.PRESET_FULL_RECT)
	content.alignment = BoxContainer.ALIGNMENT_END
	content.add_theme_constant_override("separation", UI.px(RIM))
	content.offset_bottom = -UI.px(4)
	content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	# The tile: the chosen tab's periwinkle plate or the Heist's gold ring,
	# over its name, the icon standing in it. It takes the tab's height the
	# name leaves, so the name is always under its rim, never across it.
	var tile := Control.new()
	tile.name = "Tile"
	tile.size_flags_vertical = Control.SIZE_EXPAND_FILL
	tile.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	tile.mouse_filter = Control.MOUSE_FILTER_IGNORE
	UI.dress(tile, "tab", 16)
	content.add_child(tile)
	var icon := Icons.view(str(tab[1]), 36)
	# On the tile's foot, inside its rim; a larger picture stands up out of it.
	icon.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	icon.grow_horizontal = Control.GROW_DIRECTION_BOTH
	icon.grow_vertical = Control.GROW_DIRECTION_BEGIN
	tile.add_child(icon)
	var l := UI.label(words, 13)
	l.theme_type_variation = "Tab"
	l.uppercase = true
	# Never cut: a word that does not fit is hidden (`_fit`), not shown in
	# pieces ("ISLA", "GESET").
	l.clip_text = true
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	l.add_theme_color_override("font_outline_color", Tokens.color("ink_deep"))
	l.set_meta("bold", true)
	content.add_child(l)
	b.add_child(content)
	if badge > 0:
		var tag := KitStatus.badge(str(badge))
		tag.set_anchors_preset(Control.PRESET_TOP_RIGHT)
		# Raised by however much large text has grown it, so it sits over the
		# tab's top edge, not over its icon.
		tag.position = Vector2(-UI.px(6), -UI.px(2) - (UI.text_px(13) - UI.px(13)))
		tag.grow_horizontal = Control.GROW_DIRECTION_BEGIN
		b.add_child(tag)
	buttons[id] = b
	b.resized.connect(_fit, CONNECT_DEFERRED)
	_icons[id] = icon
	_tiles[id] = tile
	_plain[id] = icon.texture
	_labels[id] = l
	return b


func _pick(id: String) -> void:
	choose(id)
	picked.emit(id)


## Gives tab `id` a face to show when chosen in place of its icon (the
## screen's own character or object, larger, its head above the tile):
## null takes it back. The tab keeps its spoken name.
func face(id: String, picture: Texture2D) -> void:
	if picture == null:
		_faces.erase(id)
	else:
		_faces[id] = picture
	if buttons.has(id):
		choose(active, false)


## Chooses a tab: it rises, widens and lights; the others settle.
func choose(id: String, animate := true) -> void:
	active = id
	if is_inside_tree():
		_fit.call_deferred()
	for k: String in buttons:
		var b: Button = buttons[k]
		var on := k == id
		# The tab itself stays on the bar's look: its name is read on the bar.
		UI.set_look(b, "tab")
		var tile: Control = _tiles[k]
		var box := RbBox.of(tile)
		var look := "tab_active" if on else ("tab_heist" if k == "heist" else "")
		box.visible = look != ""
		if look != "":
			box.set_look(look)
		# The bar's look is clear: where the tile draws, the tab draws no
		# empty box of its own under it.
		RbBox.of(b).visible = look == ""
		tile.custom_minimum_size.x = _tile_width(k)
		b.size_flags_stretch_ratio = Tokens.number("size", "tab_active_grow") if on else 1.0
		b.custom_minimum_size.y = UI.px(Tokens.number("size", "tab_height") + (RISE if on else 0.0))
		var label: Label = _labels[k]
		label.add_theme_font_size_override("font_size", UI.text_px(15 if on else 13))
		label.set_meta("points", 15.0 if on else 13.0)
		# Five words at large text do not fit 360 points: the tabs not chosen
		# keep their icon and their spoken name, the chosen one its word too.
		# Stroked in ink as the design draws it, wide enough (§21.8: 12% of
		# the size) that the words are read against their outline.
		# 12% of the size as drawn, at any text size, rounded up.
		var stroke := float(UI.px(2.0 if on else 1.5))
		if on:
			stroke = maxf(stroke, ceilf(UI.text_px(15) * 0.13))
		label.add_theme_constant_override("outline_size", int(stroke))
		if on:
			label.add_theme_color_override("font_color", Tokens.color("tab_label"))
		else:
			label.remove_theme_color_override("font_color")
		var icon: TextureRect = _icons[k]
		# The chosen tab's picture stands large in its tile, its top above the
		# rim, as every design still draws it: its face if the screen gave one
		# (larger still), else its own icon.
		var faced := on and _faces.has(k)
		icon.texture = (_faces[k] if faced else _plain[k]) as Texture2D
		icon.custom_minimum_size = Vector2.ONE * UI.px(FACE if faced else (ICON if on else 36.0))
		icon.offset_bottom = -float(UI.px(5.0 if on else 3.0))
		if _bobs.has(k):
			(_bobs[k] as Tween).kill()
			_bobs.erase(k)
		if on and animate:
			Motion.pop(icon)
		if on and is_inside_tree():
			var bob := Motion.bob(icon, 2.0)
			if bob != null:
				_bobs[k] = bob
		if _glows.has(k):
			(_glows[k] as Tween).kill()
			_glows.erase(k)
			box.self_modulate = Color.WHITE
		if k == "heist" and not on and is_inside_tree():
			var pulse := Motion.glow(box)
			if pulse != null:
				_glows[k] = pulse


## Tab `k`'s tile width in pixels: the chosen tile's or the Heist's, inside
## its tab's share of the bar once laid out; none for a plain tab's.
func _tile_width(k: String) -> float:
	var points := TILE if k == active else (HEIST_TILE if k == "heist" else 36.0)
	var w := float(UI.px(points))
	var b: Button = buttons[k]
	if b.size.x > 0.0:
		w = minf(w, b.size.x - UI.px(RIM * 2.0))
	return w


func _ready() -> void:
	choose(active, false)
	resized.connect(_fit, CONNECT_DEFERRED)
	_fit.call_deferred()


## Every tab shows its whole word or none, under its tile: the chosen tab
## widens, up to MOST_GROW and while the others keep their least width, to
## keep its own word whole, and gives back its grow, down to the others'
## width, where that keeps every other word whole too (100% in Portuguese).
## Where large text or a long language would still cut a word not chosen,
## they all show their icons alone (each still named aloud, §20.8); the
## chosen word shrinks to the largest size that fits, never under its own
## at 100%, else shows its icon alone too.
func _fit() -> void:
	if not is_inside_tree() or not _labels.has(active) or size.x <= 0.0:
		return
	var chosen: Button = buttons[active]
	var row := chosen.get_parent() as Control
	var dividers := (row.get_child_count() - buttons.size()) * maxf(1.0, UI.px(0.5))
	var width := row.size.x - dividers
	var others := float(buttons.size() - 1)
	var grow := Tokens.number("size", "tab_active_grow")
	# Measured at its full size, whatever an earlier pass shrank it to.
	var label: Label = _labels[active]
	var full := UI.text_px(15)
	label.add_theme_font_size_override("font_size", full)
	var need := _need(label)
	# The least share that holds the chosen word whole.
	var holds := others * need / (width - need) if need < width else INF
	grow = maxf(grow, holds)
	# The others keep their own least width (§21.1's 48 points).
	var least := 0.0
	var widest := 0.0
	for k: String in buttons:
		if k != active:
			least = maxf(least, (buttons[k] as Button).get_combined_minimum_size().x)
			widest = maxf(widest, _need(_labels[k]))
	var most := minf(MOST_GROW, width / maxf(least, 1.0) - others)
	var ratio := minf(grow, most)
	# The share at which every other word fits: taken where it leaves the
	# chosen tab at least as wide as the others and its word whole.
	var gives := width / maxf(widest, 1.0) - others
	if gives < ratio and gives >= maxf(1.0, holds):
		ratio = gives
	chosen.size_flags_stretch_ratio = ratio
	# Where even the widest tab cannot hold the word at the chosen text size
	# (200% in English), it takes the largest size that fits, never under
	# its own at 100%; the screen's title says the name at full size.
	var room := width * ratio / (others + ratio)
	# The tab as laid out, once it has been (the bar gives minimums first).
	if chosen.size.x > 0.0:
		room = minf(room, chosen.size.x)
	var stroke := label.get_theme_constant("outline_size")
	var word := need - stroke
	if need > room:
		var at := floori(full * (room - stroke) / maxf(word, 1.0))
		label.add_theme_font_size_override("font_size", clampi(at, UI.px(15), full))
	label.visible = _need(label) <= room + 0.5
	# The others' width once the chosen one has grown.
	var each := width / (others + ratio)
	for k: String in _labels:
		if k != active:
			(_labels[k] as Label).visible = widest <= each + 0.5
	for k: String in _tiles:
		(_tiles[k] as Control).custom_minimum_size.x = _tile_width(k)


## The width a tab needs to show `l`'s whole word in capitals, its stroke
## included.
func _need(l: Label) -> float:
	var px := l.get_theme_font_size("font_size")
	var words := l.text.to_upper()
	return l.get_theme_font("font").get_string_size(words, HORIZONTAL_ALIGNMENT_LEFT, -1, px).x + \
		l.get_theme_constant("outline_size")
