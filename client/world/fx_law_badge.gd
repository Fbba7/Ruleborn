class_name FxLawBadge
extends Control
## A law's icon as the heist's "Laws here" banner shows it: a rendered badge
## rather than a bare glyph. The frame is the law's school's shape (§21.8,
## §21.2: a leaf for Life, a bolt for Energy), in the school's colour with an
## ink edge and a hard drop; on it a cream disc, lit from the top, holds the
## law's own icon at its painted size, so a dark ink icon reads as well as a
## coloured one.

## The icon drawn on the badge.
var icon := ""
## The law's school, lower case ("life", "energy").
var school := ""


static func make(icon_name: String, school_name: String, points := 30.0) -> FxLawBadge:
	var b := FxLawBadge.new()
	b.icon = icon_name
	b.school = school_name
	b.custom_minimum_size = Vector2.ONE * UI.px(points)
	b.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	b.mouse_filter = Control.MOUSE_FILTER_IGNORE
	# The icon at its painted size on the disc (0.7 of the radius, the icon
	# 1.3 of that): the set's own view, a child so it draws over the disc.
	if icon_name != "" and Icons.has(icon_name):
		var view := Icons.view(icon_name, points * 0.455)
		view.mouse_filter = Control.MOUSE_FILTER_IGNORE
		b.add_child(view)
		view.set_anchors_and_offsets_preset(Control.PRESET_CENTER, Control.PRESET_MODE_MINSIZE)
	return b


func _draw() -> void:
	var colour: Color = Palette.SCHOOL.get(school, FxSkin.GOLD)
	var c := size / 2.0
	var r := minf(size.x, size.y) / 2.0
	var ink := FxSkin.INK_LINE
	var d := ScreenDraw.new()
	# The school's shape behind the disc, reaching past it (the frame).
	var shape := Tokens.shape(school) if school != "" else ""
	if shape != "":
		var frame := RealmView.shape_points(shape, c, r * 0.98)
		var drop := PackedVector2Array()
		for p: Vector2 in frame:
			drop.append(p + Vector2(0, maxf(1.0, r * 0.1)))
		d.polygon(drop, ink)
		d.outline(frame, ink, maxf(2.0, r * 0.16))
		d.polygon(frame, colour)
	# The disc: an ink edge, a ring in the school's deeper colour, the cream
	# face, and its top light.
	var disc := r * 0.7
	d.circle(c + Vector2(0, disc * 0.12), disc, ink)
	d.circle(c, disc, ink)
	d.circle(c, disc * 0.88, colour.darkened(0.3))
	d.circle(c - Vector2(0, disc * 0.04), disc * 0.74, Color("#FFF4DC"))
	d.circle(c - Vector2(disc * 0.28, disc * 0.4), disc * 0.2, Color(1, 1, 1, 0.6), 12)
	d.flush(get_canvas_item())
