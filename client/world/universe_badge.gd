class_name UniverseBadge
extends Button
## Home's top left (§21.8's home layout): the Keeper's emblem in a ring whose
## gold arc is the way to the next Keeper level (§14.2), the level on a gold
## disc, "Keeper 14" in Marcellus, and Renown on a glass chip beneath. It
## opens the menu of every screen, as the designs' portrait does. What it
## shows is said in words to a screen reader (§20.8).

var level := 0
## The share of the way to the next level, 0 to 1.
var share := 0.0
var title := ""
## Renown's number, or "" before the league has answered.
var renown := ""
var _face: Texture2D = UniverseHud.icon("realm_heart")
var _gem: Texture2D = UniverseHud.icon("res_renown")


func _init() -> void:
	flat = true
	focus_mode = Control.FOCUS_ALL
	mouse_filter = Control.MOUSE_FILTER_STOP
	for state: String in ["normal", "hover", "pressed", "focus", "disabled", "hover_pressed"]:
		add_theme_stylebox_override(state, StyleBoxEmpty.new())
	resized.connect(queue_redraw)
	accessibility_name = Strings.t("HOME_MENU")


## What the Keeper bar says (KeeperPresenter.bar), and Renown if known.
func show_keeper(bar: Dictionary, xp_share: float, renown_text: String) -> void:
	level = int(bar.get("level", 0))
	share = clampf(xp_share, 0.0, 1.0)
	title = str(bar.get("title", ""))
	renown = renown_text
	accessibility_name = str(bar.get("spoken", title))
	custom_minimum_size = Vector2(_width(), _ring() + UI.px(10))
	queue_redraw()


func _ring() -> float:
	return maxf(UI.CONTROL_POINTS * UI.PX_PER_POINT, UI.px(54))


func _name_px() -> int:
	return UI.text_px(17.0)


func _chip_px() -> int:
	return UI.text_px(13.0)


func _width() -> float:
	var name_w := UniverseHud.names_font().get_string_size(title, HORIZONTAL_ALIGNMENT_LEFT, -1, _name_px()).x
	var chip_w := UniverseHud.words_font().get_string_size(renown, HORIZONTAL_ALIGNMENT_LEFT, -1, _chip_px()).x \
		+ UI.px(34)
	return _ring() + UI.px(10) + maxf(name_w, chip_w if renown != "" else 0.0) + UI.px(6)


func _draw() -> void:
	if title == "":
		return
	var r := _ring() * 0.5
	var c := Vector2(r + UI.px(2), r + UI.px(2))
	var pressed := is_pressed()
	if pressed:
		c.y += UI.px(1.5)
	UniverseHud.drop(self, c, r)
	# The ring: night inside, the way to the next level as a gold arc.
	draw_circle(c, r, UniverseHud.CARD[1], true, -1.0, true)
	draw_arc(c, r - UI.px(3.5), 0.0, TAU, 64, Color(UniverseHud.DEEP_INK, 0.9), UI.px(5), true)
	if share > 0.0:
		draw_arc(c, r - UI.px(3.5), -PI * 0.5, -PI * 0.5 + TAU * share, 64, UniverseHud.GOLD[1], UI.px(5), true)
	UniverseHud.ball(self, c, r - UI.px(7.5), [Color("#B9A6F2"), Color("#6A52C8"), Color("#2E1F6E")], Color(), false)
	var face := _face
	if face != null:
		var s := (r - UI.px(8)) * 1.35
		draw_texture_rect(face, Rect2(c - Vector2(s, s) * 0.5, Vector2(s, s)), false)
	draw_arc(c, r, 0.0, TAU, 64, UniverseHud.INK_LINE, UniverseHud.outline_px(), true)
	# The level on a gold disc at the ring's foot.
	var lc := c + Vector2(r * 0.72, r * 0.72)
	var lr := maxf(UI.px(11.5), UI.text_px(13.0) * 0.75)
	UniverseHud.ball(self, lc, lr, UniverseHud.GOLD, UniverseHud.GOLD_RIM)
	var nf := UniverseHud.numbers_font()
	var npx := UI.text_px(14.0)
	var digits := str(level)
	UniverseHud.inked(self, nf, Vector2(lc.x - lr * 2.0, lc.y + nf.get_ascent(npx) * 0.42), digits, npx,
		Color.WHITE, lr * 4.0, HORIZONTAL_ALIGNMENT_CENTER)
	# The name, and Renown beneath it.
	var x := c.x + r + UI.px(9)
	var names := UniverseHud.names_font()
	var top: float = c.y - UI.px(4) if renown != "" else c.y + names.get_ascent(_name_px()) * 0.35
	UniverseHud.inked(self, names, Vector2(x, top), title, _name_px(), UniverseHud.WORDS)
	if renown != "":
		var words := UniverseHud.words_font()
		var w := words.get_string_size(renown, HORIZONTAL_ALIGNMENT_LEFT, -1, _chip_px()).x
		var h := _chip_px() * 1.5
		var chip := Rect2(Vector2(x + UI.px(8), top + UI.px(7)), Vector2(w + UI.px(26), h))
		UniverseHud.glass(h * 0.5).draw(get_canvas_item(), chip)
		var gem := _gem
		var g := h * 1.15
		if gem != null:
			draw_texture_rect(gem, Rect2(Vector2(chip.position.x - g * 0.45, chip.position.y + (h - g) * 0.5),
				Vector2(g, g)), false)
		draw_string(words, Vector2(chip.position.x + UI.px(16), chip.position.y + h * 0.5
			+ words.get_ascent(_chip_px()) * 0.36), renown, HORIZONTAL_ALIGNMENT_LEFT, -1, _chip_px(),
			UniverseHud.WORDS)
	if has_focus():
		draw_arc(c, r + UI.px(3), 0.0, TAU, 64, UniverseHud.WORDS, UI.px(2), true)
