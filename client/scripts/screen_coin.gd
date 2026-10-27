class_name ScreenCoin
extends Control
## A resource's mark, drawn as the design draws its resource discs: a round
## gem in the resource's colour (§21.2's Starlight gold, Aether cyan, Essence
## green), light at the top, with an ink edge and a white mark of its own (a
## star, a diamond, a drop), so a resource reads by shape as well as colour.

const KINDS := {"starlight": Color("#F2B43C"), "aether": Color("#3CC6D8"), "essence": Color("#5CC46A"),
	"renown": Color("#E05CB4")}

var kind := "starlight"


static func make(k: String, points := 20.0) -> ScreenCoin:
	var c := ScreenCoin.new()
	c.kind = k
	c.custom_minimum_size = Vector2.ONE * UI.px(points)
	c.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return c


func _draw() -> void:
	var school := kind.trim_prefix("school:") if kind.begins_with("school:") else ""
	var colour: Color = Palette.SCHOOL.get(school, Color.WHITE) if school != "" else KINDS.get(kind, Color.WHITE)
	var c := size / 2.0
	var r := minf(size.x, size.y) / 2.0 - 1.0
	var d := ScreenDraw.new()
	d.circle(c + Vector2(0, r * 0.12), r, Color("#0A0408"))
	d.circle(c, r, Color("#1A0C14"))
	d.circle(c, r * 0.84, colour.darkened(0.25))
	d.circle(c - Vector2(0, r * 0.1), r * 0.72, colour)
	d.circle(c - Vector2(r * 0.25, r * 0.38), r * 0.22, Color(1, 1, 1, 0.55), 12)
	var mark := PackedVector2Array()
	if school != "":
		mark = RealmView.shape_points(Tokens.shape(school), c, r * 0.5)
	match "school" if school != "" else kind:
		"starlight":
			for i: int in 10:
				var a := -PI / 2.0 + i * PI / 5.0
				mark.append(c + Vector2(cos(a), sin(a)) * r * (0.5 if i % 2 == 0 else 0.22))
		"aether":
			mark = PackedVector2Array([c + Vector2(0, -r * 0.5), c + Vector2(r * 0.34, 0), c + Vector2(0, r * 0.5),
				c + Vector2(-r * 0.34, 0)])
		"renown":
			mark = PackedVector2Array([c + Vector2(-r * 0.45, r * 0.3), c + Vector2(-r * 0.45, -r * 0.2),
				c + Vector2(-r * 0.2, r * 0.02), c + Vector2(0, -r * 0.4), c + Vector2(r * 0.2, r * 0.02),
				c + Vector2(r * 0.45, -r * 0.2), c + Vector2(r * 0.45, r * 0.3)])
		"school":
			pass
		_:
			for i: int in 12:
				var a2 := PI / 2.0 + i * TAU / 12.0
				var kk := 0.42 if i != 6 else 0.62
				mark.append(c + Vector2(cos(a2) * r * 0.36, sin(a2) * r * kk + r * 0.08))
	d.outline(mark, Color("#1A0C14"), maxf(1.5, r * 0.14))
	d.polygon(mark, Color(1, 1, 1, 0.95))
	d.flush(get_canvas_item())
