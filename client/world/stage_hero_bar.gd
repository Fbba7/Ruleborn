class_name StageHeroBar
extends Control
## A bar as the design draws one (§21.8): a dark well, a glossy fill in
## `colour` to `fraction`, and words over it in light ink with an ink edge,
## so they read on the fill and on the well alike. `mirrored` fills from the
## right, for the left half of a comparison.

var fraction := 0.0
var colour := Color("#5CC46A")
var words := ""
var mirrored := false
var _label: Label


static func make(at: float, fill: Color, text := "", points := 22.0, flip := false) -> StageHeroBar:
	var b := StageHeroBar.new()
	b.fraction = clampf(at, 0.0, 1.0)
	b.colour = fill
	b.words = text
	b.mirrored = flip
	b.custom_minimum_size = Vector2(UI.px(40), UI.px(points))
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if text != "":
		b._label = StageHeroKit.words(text, 13.0, Color("#FFF6DC"), true)
		b._label.set_anchors_preset(Control.PRESET_FULL_RECT)
		b._label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		b._label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		b.add_child(b._label)
		b.set_meta("behind", [Color("#1A1238"), fill] as Array[Color])
	b.accessibility_name = text
	return b


func _draw() -> void:
	var h := size.y
	var corner := h / UI.PX_PER_POINT / 2.0
	draw_style_box(StageHeroMaterial.box("well", corner, 0.0), Rect2(Vector2.ZERO, size))
	if fraction <= 0.0:
		return
	var inset := float(UI.px(2))
	var wide := maxf(h - inset * 2.0, (size.x - inset * 2.0) * fraction)
	var at := Vector2(size.x - inset - wide if mirrored else inset, inset)
	draw_style_box(StageHeroMaterial.box("#" + colour.to_html(false), (h - inset * 2.0) / UI.PX_PER_POINT / 2.0, 0.0),
		Rect2(at, Vector2(wide, h - inset * 2.0)))
