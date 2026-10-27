class_name UniverseMenu
extends Control
## Every screen from home, on a sheet over a night backdrop (§21.8: "Menus
## stand on a night backdrop"), opened from the Keeper badge as the designs'
## portrait opens theirs: a dark card of tiles, each the screen's icon over its
## name, which scrolls when §20.8's large text makes it long, and a close
## control in the thumb's reach (§21.1).

signal picked(route: StringName)

const TILE := Color("#24164F")
const TILE_EDGE := Color("#F2B43C")
const TILE_POINTS := 13.0

## Every tile's button, by route.
var tiles := {}
var close_button: Button


## A sheet of `places`, each named by its catalogue key in `words`.
static func make(places: Array, words: Dictionary) -> UniverseMenu:
	var m := UniverseMenu.new()
	m._build(places, words)
	return m


func _build(places: Array, words: Dictionary) -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	visible = false
	mouse_filter = Control.MOUSE_FILTER_STOP
	accessibility_name = Strings.t("HOME_MENU")
	var dim := ColorRect.new()
	dim.color = Color(UniverseHud.DEEP_INK, 0.86)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(dim)
	var column := UI.frame(self)
	# The night backdrop stands in for the frame's day sky.
	(get_node("Sky") as CanvasItem).visible = false
	var title := Label.new()
	title.text = Strings.t("HOME_MENU")
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_override("font", UniverseHud.names_font())
	title.add_theme_font_size_override("font_size", UI.text_px(22.0))
	title.add_theme_color_override("font_color", UniverseHud.WORDS)
	title.add_theme_color_override("font_outline_color", UniverseHud.INK_LINE)
	title.add_theme_constant_override("outline_size", UI.px(3))
	title.set_meta("points", 22.0)
	column.add_child(title)
	var card := PanelContainer.new()
	var box := UniverseHud.plate(UniverseHud.CARD[0], UI.px(18))
	box.set_content_margin_all(UI.px(10))
	card.add_theme_stylebox_override("panel", box)
	card.size_flags_vertical = Control.SIZE_EXPAND_FILL
	column.add_child(card)
	var scroller := ScrollContainer.new()
	scroller.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	card.add_child(scroller)
	var grid := GridContainer.new()
	grid.add_theme_constant_override("h_separation", UI.px(8))
	grid.add_theme_constant_override("v_separation", UI.px(8))
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var widest := 0.0
	for route: StringName in places:
		var b := _tile(Strings.t(words[route]), route)
		tiles[route] = b
		grid.add_child(b)
		widest = maxf(widest, _longest_word(b))
	var room := 360.0 * UI.PX_PER_POINT - UI.px(Tokens.number("size", "safe_side_points")) * 2.0 - UI.px(40)
	grid.columns = clampi(floori(room / (maxf(widest, UI.CONTROL_POINTS * UI.PX_PER_POINT) + UI.px(14))), 1, 3)
	scroller.add_child(grid)
	var row := UI.row(-1.0, true)
	close_button = UI.button(Strings.t("HOME_MENU_CLOSE"), close, true)
	row.add_child(close_button)
	column.add_child(UI.narrow(row))


func open() -> void:
	visible = true
	if not tiles.is_empty():
		(tiles.values()[0] as Control).grab_focus.call_deferred()


func close() -> void:
	visible = false


func _tile(text: String, route: StringName) -> Button:
	var b := UI.button(text, func() -> void: picked.emit(route))
	b.icon = load("res://world/universe_icons/%s.svg" % route) if ResourceLoader.exists(
		"res://world/universe_icons/%s.svg" % route) else UniverseHud.icon("heist")
	b.expand_icon = true
	b.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	b.vertical_icon_alignment = VERTICAL_ALIGNMENT_TOP
	b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b.custom_minimum_size = Vector2(UI.CONTROL_POINTS * UI.PX_PER_POINT, _tile_height())
	b.add_theme_constant_override("icon_max_width", UI.px(44))
	b.add_theme_font_override("font", UniverseHud.words_font())
	for state: String in ["normal", "hover", "pressed", "focus", "disabled"]:
		var box := StyleBoxFlat.new()
		box.bg_color = TILE.lightened(0.12) if state == "pressed" else TILE
		box.border_color = Color(TILE_EDGE, 0.7) if state != "focus" else UniverseHud.WORDS
		box.set_border_width_all(UI.px(1.5) if state != "focus" else UI.px(3))
		box.set_corner_radius_all(UI.px(12))
		box.set_content_margin_all(UI.px(5))
		box.shadow_color = UniverseHud.HARD_DROP
		box.shadow_offset = Vector2(0, UI.px(2))
		box.anti_aliasing = true
		b.add_theme_stylebox_override(state, box)
	for colour: String in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color",
			"font_disabled_color"]:
		b.add_theme_color_override(colour, UniverseHud.WORDS)
	b.add_theme_font_size_override("font_size", UI.text_px(TILE_POINTS))
	b.set_meta("points", TILE_POINTS)
	return b


## The widest word on a tile, which it cannot wrap inside.
static func _longest_word(b: Button) -> float:
	var font := b.get_theme_font("font")
	var widest := 0.0
	for word: String in b.text.split(" "):
		widest = maxf(widest, font.get_string_size(word, HORIZONTAL_ALIGNMENT_LEFT, -1,
			b.get_theme_font_size("font_size")).x)
	return widest + UI.px(10)


static func _tile_height() -> float:
	return maxf(UI.CONTROL_POINTS * UI.PX_PER_POINT, UI.px(56) + UI.text_px(TILE_POINTS) * 2.5)
