class_name KitNumerals
extends RefCounted
## The kit's baked numerals (kit-spec.md sections 3 and 6.1: T3, pieces
## `num_<finish>_<glyph>`): a number drawn from the atlas glyph by glyph, each
## in a cell of its fixed advance, so a count that changes never moves its
## neighbours. The words are the client's own formatting, never the art's
## (`report.md` section 10.4): the grouping and decimal marks of the
## language shown (`NUMBER_GROUP`, `NUMBER_DECIMAL`), so English "1,234" and
## Brazilian Portuguese "1.234" draw from the same pieces. While the numerals'
## skin is off, or any glyph's piece is missing, the number is live text in
## its type role instead, so a number is never blank.

## Each character the numerals draw, as its glyph's name.
const GLYPHS := {
	"0": "0", "1": "1", "2": "2", "3": "3", "4": "4", "5": "5", "6": "6", "7": "7", "8": "8", "9": "9",
	",": "comma", ".": "period", ":": "colon", "/": "slash", "+": "plus", "-": "minus", "−": "minus",
	"%": "percent", "×": "x", "?": "question", " ": "space", "\u00a0": "space", "\u202f": "space",
}
## The finishes the kit bakes (kit-spec.md section 3, T3).
const FINISHES := ["num_gold", "num_white", "num_timer", "num_timer_red"]


## Count `n`, grouped as the language shown groups it, in `finish`, sized to
## type role `role`'s slot.
static func number(n: int, finish := "num_gold", role := "display") -> Control:
	return make(ShopPresenter.grouped(n), finish, role, str(n))


## `text` (digits and the marks `GLYPHS` names) in `finish`, sized to type
## role `role`'s slot at the player's text size: baked when every glyph's
## piece is there, else live text in the role. A screen reader says `spoken`
## (the text when empty).
static func make(text: String, finish := "num_gold", role := "display", spoken := "") -> Control:
	var points := float(Tokens.type_role(role)["points"])
	var cells: Array[Dictionary] = []
	for ch: String in text:
		var p := KitSkin.numeral("%s_%s" % [finish, GLYPHS.get(ch, "")]) if GLYPHS.has(ch) else {}
		if p.is_empty():
			cells.clear()
			break
		cells.append(p)
	var said := spoken if spoken != "" else text
	if cells.is_empty():
		var l := UI.label(text, points)
		l.theme_type_variation = RbTheme.variation(role)
		l.accessibility_name = said
		l.set_meta("spoken", said)
		return l
	var row := Row.new()
	row.cells = cells
	row.height = RbTheme.role_font(role).get_height(UI.text_px(points))
	row.accessibility_name = said
	row.set_meta("spoken", said)
	row.set_meta("numerals", text)
	row.set_meta("points", points)
	return row


## A baked number: every glyph drawn in one canvas item, in the art's layer
## so it batches with the atlas (kit-spec.md section 7), each in its fixed
## advance with the glyph's overhang (its stroke and drop) centred on it.
class Row:
	extends Control

	## The glyphs' pieces, in order.
	var cells: Array[Dictionary] = []
	## The slot's height in pixels: the role's line, as its live text takes.
	var height := 0.0

	func _init() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		size_flags_vertical = Control.SIZE_SHRINK_CENTER
		# The glyphs are baked 210 px tall and drawn a tenth of that: averaged
		# from the page's mipmaps, their stroke, drop and gradient survive.
		texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS

	## Pixels on screen per pixel of a glyph: the tallest glyph fills the slot.
	func glyph_scale() -> float:
		var tallest := 1.0
		for p: Dictionary in cells:
			tallest = maxf(tallest, float(p["h"]))
		return height / tallest

	## Each glyph's fixed advance on screen, in order.
	func advances() -> Array[float]:
		var s := glyph_scale()
		var out: Array[float] = []
		for p: Dictionary in cells:
			out.append(float(p.get("advance", p["w"])) * s)
		return out

	func _get_minimum_size() -> Vector2:
		var w := 0.0
		for a: float in advances():
			w += a
		return Vector2(ceilf(w), ceilf(height))

	func _draw() -> void:
		var s := glyph_scale()
		var x := (size.x - get_minimum_size().x) * 0.5
		var bottom := (size.y + height) * 0.5
		for p: Dictionary in cells:
			var w := float(p["w"]) * s
			var h := float(p["h"]) * s
			var advance := float(p.get("advance", p["w"])) * s
			var at := Rect2(x + (advance - w) * 0.5, bottom - h, w, h)
			draw_texture_rect_region(KitSkin.texture(p), at, Rect2(p["x"], p["y"], p["w"], p["h"]))
			x += advance
