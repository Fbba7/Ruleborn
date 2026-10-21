class_name UniverseTabs
extends Control
## Home's foot (§21.8's home layout): five tabs with the Heist in the centre,
## on a dark bar that runs under the home indicator, the tabs themselves
## inside the safe area and clear of the corners (§21.1). The tab the player is
## on is raised on a periwinkle disc and its name grows, so it is told by
## size and place as well as colour (§20.8); the Heist is a larger gold ball.
## A count badge says what waits behind a tab in numbers.
##
## Until the app's own tab bar lands (the app shell's), home draws this one.

signal chosen(key: String)

## Each tab: its key, its icon and the words under it.
const TABS := [["islands", "universe", "HOME_TAB_ISLANDS"], ["laws", "codex", "HOME_TAB_LAWS"],
	["heist", "heist", "HOME_TAB_HEIST"], ["crew", "roster", "HOME_TAB_CREW"],
	["friends", "friends", "HOME_TAB_FRIENDS"]]

var active := "islands"
var buttons := {}


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 0)
	row.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(row)
	for t: Array in TABS:
		var b := UniverseTab.new()
		b.key = t[0]
		b.icon_name = t[1]
		b.tex = UniverseHud.icon(t[1])
		b.words = Strings.t(t[2])
		b.accessibility_name = b.words
		b.pressed.connect(func() -> void: Haptics.play("tap"))
		b.pressed.connect(func() -> void: chosen.emit(b.key))
		buttons[t[0]] = b
		row.add_child(b)
	resized.connect(_lay_out)
	_lay_out()


## The badge over a tab: a number or a glyph, "" for none.
func set_badge(key: String, text: String) -> void:
	var b: UniverseTab = buttons.get(key)
	if b != null:
		b.count = text
		b.accessibility_name = b.words if text == "" else Strings.t("HOME_BADGE_SPOKEN", [b.words, text])
		b.queue_redraw()


func _lay_out() -> void:
	# Each tab as wide as the bar allows between the corners (§21.1: past 15%
	# of the screen's width either side of the lowest row), never under 48
	# points.
	var room := 360.0 * UI.PX_PER_POINT * 0.68
	var w := maxf(UI.CONTROL_POINTS * UI.PX_PER_POINT, room / TABS.size())
	for k: String in buttons:
		var b: UniverseTab = buttons[k]
		b.active = k == active
		b.custom_minimum_size = Vector2(w, _height())
	custom_minimum_size.y = _height()
	queue_redraw()


func _height() -> float:
	return UI.px(52) + UI.text_px(13.0) * 1.3


func _draw() -> void:
	# The bar, from edge to edge and down under the home indicator.
	var side := UI.px(Tokens.number("size", "safe_side_points")) + UI.px(2)
	var below := UI.px(Tokens.number("size", "safe_top_points")) + UI.px(2)
	var top := UI.px(14)
	var bar := Rect2(Vector2(-side, top), Vector2(size.x + side * 2.0, size.y - top + below))
	var box := StyleBoxFlat.new()
	box.bg_color = UniverseHud.CARD[1]
	box.border_color = UniverseHud.INK_LINE
	box.border_width_top = int(UniverseHud.outline_px())
	box.corner_radius_top_left = UI.px(22)
	box.corner_radius_top_right = UI.px(22)
	box.shadow_color = Color(0, 0, 0, 0.45)
	box.shadow_size = UI.px(8)
	box.anti_aliasing = true
	box.draw(get_canvas_item(), bar)
	draw_rect(Rect2(bar.position + Vector2(UI.px(20), UI.px(2.5)), Vector2(bar.size.x - UI.px(40), UI.px(2))),
		Color(UniverseHud.GOLD[1], 0.35))
