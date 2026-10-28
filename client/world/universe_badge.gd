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
	custom_minimum_size = Vector2(_width(), maxf(_ring() + UI.px(10), _ring() + _tag().y * 0.5 + UI.px(1)))
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
	return _text_x() + maxf(name_w, chip_w if renown != "" else 0.0) + UI.px(6)


## The level's gold pill: the design's 28 by 18 points, grown with the text.
func _tag() -> Vector2:
	var w := UniverseHud.words_font().get_string_size(str(level), HORIZONTAL_ALIGNMENT_LEFT, -1, UI.text_px(13.0)).x
	var h := maxf(UI.px(18), UI.text_px(13.0) * 1.4)
	return Vector2(maxf(UI.px(28), w + h * 0.8), h)


## Where the name starts: past the ring.
func _text_x() -> float:
	return _ring() + UI.px(11)


func _draw() -> void:
	if title == "":
		return
	var r := _ring() * 0.5
	var c := Vector2(r + UI.px(2), r + UI.px(2))
	var pressed := is_pressed()
	if pressed:
		c.y += UI.px(1.5)
	# The ring: night inside, outlined in ink on its drop (one baked ball),
	# the way to the next level as a gold arc on a dark track.
	var night: Color = UniverseHud.CARD[1]
	UniverseHud.ball(self, c, r, [night, night, night], Color(), true, true)
	draw_arc(c, r - UI.px(3.5), 0.0, TAU, 64, Color(UniverseHud.DEEP_INK, 0.9), UI.px(5))
	if share > 0.0:
		draw_arc(c, r - UI.px(3.5), -PI * 0.5, -PI * 0.5 + TAU * share, 64, UniverseHud.GOLD[1], UI.px(5))
	UniverseHud.ball(self, c, r - UI.px(7.5), [Color("#B9A6F2"), Color("#6A52C8"), Color("#2E1F6E")], Color(), false)
	var face := _face
	if face != null:
		var s := (r - UI.px(8)) * 1.35
		draw_texture_rect(face, Rect2(c - Vector2(s, s) * 0.5, Vector2(s, s)), false)
	# The level on a gold pill across the ring's foot, as the design's.
	var digits := str(level)
	var tag := _tag()
	var lc := Vector2(c.x, c.y + r - UI.px(3))
	var plate := Rect2(lc - tag * 0.5, tag)
	UniverseHud.gold_pill(tag.y).draw(get_canvas_item(), plate)
	# Every shape first, then the words font by font, so the words batch.
	var x := _text_x() + (c.x - r - UI.px(2))
	var names := UniverseHud.names_font()
	var top: float = c.y - UI.px(4) if renown != "" else c.y + names.get_ascent(_name_px()) * 0.35
	if renown != "":
		var words := UniverseHud.words_font()
		var w := words.get_string_size(renown, HORIZONTAL_ALIGNMENT_LEFT, -1, _chip_px()).x
		var h := _chip_px() * 1.5
		var chip := Rect2(Vector2(x + UI.px(8), top + UI.px(7)), Vector2(w + UI.px(26), h))
		# The design's chip: deep night, edged in the gem's rose.
		var hc := Settings.high_contrast
		UniverseHud.baked_box(Color("#0C0820") if hc else Color(0.047, 0.031, 0.125, 0.8), UniverseHud.INK_LINE if hc
			else Color(0.878, 0.361, 0.706, 0.45), float(UI.px(3.0)) if hc else maxf(2.0, UI.px(1.0)), h * 0.5,
			Color(0, 0, 0, 0.35), UI.px(2)).draw(get_canvas_item(), chip)
		var gem := _gem
		var g := h * 1.15
		if gem != null:
			draw_texture_rect(gem, Rect2(Vector2(chip.position.x - g * 0.45, chip.position.y + (h - g) * 0.5),
				Vector2(g, g)), false)
		draw_string(words, Vector2(chip.position.x + UI.px(16), chip.position.y + h * 0.5
			+ words.get_ascent(_chip_px()) * 0.36), renown, HORIZONTAL_ALIGNMENT_LEFT, -1, _chip_px(),
			UniverseHud.WORDS)
	var nf := UniverseHud.words_font()
	var npx := UI.text_px(13.0)
	draw_string(nf, Vector2(plate.position.x, lc.y + nf.get_ascent(npx) * 0.36), digits, HORIZONTAL_ALIGNMENT_CENTER,
		plate.size.x, npx, Color("#1B1430"))
	UniverseHud.inked(self, names, Vector2(x, top), title, _name_px(), UniverseHud.WORDS)
	if has_focus():
		draw_arc(c, r + UI.px(3), 0.0, TAU, 64, UniverseHud.WORDS, UI.px(2), true)
