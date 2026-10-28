class_name UniversePurse
extends HFlowContainer
## Home's full-width row of resources (§21.8's home layout), as the designs
## draw it: Starlight, Aether and Essence, each a slim dark pill with a faint
## gold rim, its icon on a dark disc at the left, the amount held at the right
## (past 10,000 in thousands, "142.0k"; said in full), and a line along its
## foot in the resource's colour that fills as that resource's producers fill
## (§9.3's twelve hours), marked Full in gold words once they are nearly full,
## so a player sees what is waiting to be collected. An amount the server has
## not given is a dash, never a guess. Where the three will not sit on one line
## with Full in words (a long amount, large text), the word gives way first
## (the line still shows full, and it is still said); past that the row wraps
## rather than run off the screen.
##
## The three pills are drawn by the row itself, each kind of mark in one run
## across all three (pills, lines, discs, icons, words), so the row costs the
## frame a handful of draw calls (§21.3); each pill is an empty cell the row
## lays out and the Collect reward flies to.

const ORDER := ["starlight", "aether", "essence"]
## The share at which producers are said to be full.
const FULL := 0.9
## The pill's height, in points (the design's 30), more where text needs it.
const PILL_POINTS := 30.0
## The rim, as the design's inset gold line.
const RIM := Color(0.914, 0.714, 0.361, 0.45)

## Per resource: {"amount": int or -1, "ready": int, "holds": int}.
var rows := {}
## Each resource's cell, which the row draws its pill over.
var pills := {}
## The resources whose producers are full, which say so in words when there is
## room.
var _full := {}
var _words := {}
var _share := {}
var _say_full := {}
var _icons := {}


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_theme_constant_override("h_separation", UI.px(6))
	add_theme_constant_override("v_separation", UI.px(6))
	for k: String in ORDER:
		var cell := Control.new()
		cell.name = "Resource"
		cell.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		cell.mouse_filter = Control.MOUSE_FILTER_IGNORE
		cell.item_rect_changed.connect(queue_redraw)
		pills[k] = cell
		_words[k] = "–"
		_share[k] = 0.0
		_icons[k] = Icons.texture("resources/" + k)
		add_child(cell)
	_size_cells()


## What the store holds (UniverseStore.purse).
func show_purse(purse: Dictionary) -> void:
	rows = purse
	var said := PackedStringArray()
	for k: String in ORDER:
		var r: Dictionary = rows.get(k, {})
		var amount := int(r.get("amount", -1))
		var holds := int(r.get("holds", 0))
		var share := clampf(float(r.get("ready", 0)) / holds, 0.0, 1.0) if holds > 0 else 0.0
		_words[k] = UniverseHud.compact(amount) if amount >= 0 else "–"
		_full[k] = share >= FULL
		_fill(k, share)
		said.append(Strings.t("HOME_PURSE_SPOKEN", [Strings.t("HOME_RES_" + k.to_upper()),
			UniverseHud.grouped(amount) if amount >= 0 else Strings.t("HOME_UNKNOWN"),
			UniverseHud.grouped(int(r.get("ready", 0)))]))
	accessibility_name = Strings.t("HOME_PURSE")
	accessibility_description = "\n".join(said)
	_size_cells()
	queue_redraw()


## A line easing to its new share (§21.8: easing out, within 250 ms; at once
## under reduced motion).
func _fill(k: String, share: float) -> void:
	var ms := UI.motion_ms(250.0)
	if ms <= 0.0 or not is_inside_tree():
		_share[k] = share
		return
	var t := create_tween()
	t.tween_method(func(v: float) -> void:
		_share[k] = v
		queue_redraw(), float(_share[k]), share, ms / 1000.0).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)


func _notification(what: int) -> void:
	if what == NOTIFICATION_PRE_SORT_CHILDREN:
		_fit()


func _amount_px() -> int:
	return UI.text_px(15.0)


func _full_px() -> int:
	return UI.text_px(13.0)


func _tall() -> float:
	return maxf(UI.px(PILL_POINTS), _amount_px() * 1.75)


## Each cell as wide as its pill needs: the disc, Full where it is said, the
## amount and a little room.
func _size_cells() -> void:
	for k: String in ORDER:
		(pills[k] as Control).custom_minimum_size = Vector2(_need(k, bool(_say_full.get(k, false))), _tall())


func _need(k: String, with_full: bool) -> float:
	var font := UniverseHud.words_font()
	var w := _tall() * 1.4 + UI.px(6) + font.get_string_size(str(_words[k]), HORIZONTAL_ALIGNMENT_LEFT, -1,
		_amount_px()).x
	if with_full:
		w += font.get_string_size(Strings.t("KIT_FULL").to_upper(), HORIZONTAL_ALIGNMENT_LEFT, -1, _full_px()).x \
			+ UI.px(6)
	return w


## Full in words only while all three pills still sit on one line with it.
func _fit() -> void:
	var need := float(get_theme_constant("h_separation")) * (ORDER.size() - 1)
	var words := need
	for k: String in ORDER:
		need += _need(k, false)
		words += _need(k, _full.get(k, false))
	var room := words <= size.x
	var changed := false
	for k: String in ORDER:
		var want: bool = room and _full.get(k, false)
		if _say_full.get(k, false) != want:
			_say_full[k] = want
			changed = true
	if changed:
		_size_cells()


func _draw() -> void:
	var ci := get_canvas_item()
	var h := _tall()
	var hc := Settings.high_contrast
	var rects := {}
	for k: String in ORDER:
		var cell: Control = pills[k]
		var r := Rect2(cell.position + Vector2(0.0, (cell.size.y - h) * 0.5), Vector2(cell.size.x, h))
		# A cell popped by the Collect reward grows from its centre.
		rects[k] = Rect2(r.get_center() - r.size * cell.scale * 0.5, r.size * cell.scale)
	var pill := UniverseHud.baked_box(Color("#1C0F21") if not hc else Color("#140A16"), UniverseHud.INK_LINE if hc
		else RIM, float(UI.px(3.0)) if hc else maxf(2.0, UI.px(1.5)), h * 0.5, Color(0, 0, 0, 0.35), UI.px(2))
	for k: String in ORDER:
		pill.draw(ci, rects[k])
	# The line along each foot, inside the rim.
	for k: String in ORDER:
		var r: Rect2 = rects[k]
		var inset := h * 0.5
		var line := Rect2(Vector2(r.position.x + inset * 0.6, r.end.y - UI.px(4.5)), Vector2(r.size.x - inset * 1.2,
			UI.px(2.5)))
		draw_rect(line, Color(0, 0, 0, 0.45))
		draw_rect(Rect2(line.position, Vector2(line.size.x * float(_share[k]), line.size.y)),
			UniverseHud.RESOURCES[k])
	var disc := Color("#1E1546")
	for k: String in ORDER:
		var r: Rect2 = rects[k]
		UniverseHud.ball(self, Vector2(r.position.x + h * 0.5, r.get_center().y), h * 0.5 - UI.px(3),
			[Color("#2E2268"), disc, Color("#120C30")], Color(), false)
	for k: String in ORDER:
		var r: Rect2 = rects[k]
		var s := h * 0.55
		draw_texture_rect(_icons[k], Rect2(Vector2(r.position.x + h * 0.5, r.get_center().y) - Vector2(s, s) * 0.5,
			Vector2(s, s)), false)
	var font := UniverseHud.words_font()
	for k: String in ORDER:
		var r: Rect2 = rects[k]
		var px := _amount_px()
		var base := r.get_center().y + font.get_ascent(px) * 0.36 - UI.px(1)
		var x := r.position.x + h + UI.px(2)
		var right := r.end.x - h * 0.4
		draw_string(font, Vector2(x, base), str(_words[k]), HORIZONTAL_ALIGNMENT_RIGHT, right - x, px,
			UniverseHud.WORDS)
		# Full in gold just before the amount, as the design's "FULL 61.0k".
		if _say_full.get(k, false):
			var full := Strings.t("KIT_FULL").to_upper()
			var at := right - font.get_string_size(str(_words[k]), HORIZONTAL_ALIGNMENT_LEFT, -1, px).x - UI.px(6) \
				- font.get_string_size(full, HORIZONTAL_ALIGNMENT_LEFT, -1, _full_px()).x
			draw_string(font, Vector2(at, base), full, HORIZONTAL_ALIGNMENT_LEFT, -1, _full_px(),
				UniverseHud.GOLD[0] if hc else UniverseHud.GOLD[1])
