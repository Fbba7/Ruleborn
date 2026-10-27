class_name KitRail
extends Control
## The season's tier rail (17-season.png): numbered tiers on a rail, the
## rail gold up to the tier reached and violet past it, the tiers passed on
## small gold discs, the tier reached on a large gold disc in a glowing
## ring, the tiers to come on dark discs. One control, drawn; a screen
## reader hears "Tier 12, 340 of 500 to the next" (its spoken name).

## The first tier shown, and how many.
var first := 1
var count := 3
## The tier reached, and how far along to the next (0 to 1).
var reached := 1
var along := 0.0


## A rail of `count` tiers from `first`, `reached` reached and `along` of
## the way to the next; `spoken` is what a screen reader says for it.
static func make(first_tier: int, tiers: int, at: int, share: float, spoken: String) -> KitRail:
	var r := KitRail.new()
	r.name = "TierRail"
	r.first = first_tier
	r.count = tiers
	r.reached = at
	r.along = clampf(share, 0.0, 1.0)
	r.accessibility_name = spoken
	r.custom_minimum_size = Vector2(UI.px(240), UI.px(64))
	r.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return r


func _draw() -> void:
	# Every rail and disc is one array of triangles, drawn at once, its edges feathered a
	# pixel for smoothness; the numbers follow in one run of text. (Drawn
	# circle by circle it was 26 draw calls; now it is two or three.)
	var m := _Mesh.new()
	var y := size.y * 0.5
	var step := size.x / float(count)
	var ink := Tokens.color("ink_line")
	var rail := float(UI.px(10))
	# The rail: ink under, violet all along, gold up to where the player is.
	var at := clampf(step * (reached - first + 0.5) + step * along, 0.0, size.x)
	m.bar(Vector2(0, y), size.x, rail + UI.px(3), ink)
	m.bar(Vector2(0, y), size.x, rail, Tokens.paint("#3A2878"))
	m.bar(Vector2(0, y), at, rail, Tokens.color("gold"))
	m.bar(Vector2(0, y - rail * 0.25), at, rail * 0.25, Color(Tokens.color("cream"), 0.55))
	if along > 0.0 and at < size.x:
		m.disc(Vector2(at, y), rail * 0.7, Color(Tokens.color("cream"), 0.9))
	for i: int in count:
		var tier := first + i
		var c := Vector2(step * (i + 0.5), y)
		var r := float(UI.px(27) if tier == reached else UI.px(17))
		if tier == reached:
			m.disc(c, r + UI.px(9), Color(Tokens.color("gold"), 0.18))
			m.disc(c, r + UI.px(4), Color(Tokens.color("gold"), 0.35))
		m.disc(c, r, ink)
		var passed := tier <= reached
		m.disc(c, r - UI.px(2), Tokens.color("gold") if passed else Tokens.paint("#2A1C5A"))
		if passed:
			m.disc(c + Vector2(0, -r * 0.25), r * 0.62, Color(Tokens.color("gold_top"), 0.7))
	RenderingServer.canvas_item_add_triangle_array(get_canvas_item(), m.order, m.points, m.colours)
	var face := Tokens.font("display")
	for i: int in count:
		var tier := first + i
		var c := Vector2(step * (i + 0.5), y)
		var now := tier == reached
		var words := str(tier)
		var px := UI.text_px(22.0 if now else 15.0)
		var w := face.get_string_size(words, HORIZONTAL_ALIGNMENT_LEFT, -1, px)
		var at_text := c + Vector2(-w.x * 0.5, face.get_ascent(px) * 0.5 - UI.px(1))
		draw_string(face, at_text, words, HORIZONTAL_ALIGNMENT_LEFT, -1, px,
			Tokens.color("parchment_ink") if tier <= reached else Tokens.color("cream"))


## Triangles with a colour at each corner, gathered to be drawn at once.
class _Mesh:
	var points := PackedVector2Array()
	var colours := PackedColorArray()
	var order := PackedInt32Array()

	## A filled circle whose edge fades over one pixel.
	func disc(c: Vector2, r: float, colour: Color) -> void:
		var n := clampi(int(r * 0.6), 16, 48)
		var base := points.size()
		points.append(c)
		colours.append(colour)
		var clear := Color(colour, 0.0)
		for k: int in n:
			var d := Vector2.from_angle(TAU * k / n)
			points.append(c + d * (r - 0.5))
			colours.append(colour)
			points.append(c + d * (r + 0.5))
			colours.append(clear)
		for k: int in n:
			var a := base + 1 + 2 * k
			var b := base + 1 + 2 * ((k + 1) % n)
			order.append_array([base, a, b, a, a + 1, b + 1, a, b + 1, b])

	## A bar from `from` to the right, `long` long and `thick` thick, about
	## its middle, its long edges fading over one pixel.
	func bar(from: Vector2, long: float, thick: float, colour: Color) -> void:
		if long <= 0.0:
			return
		var base := points.size()
		var clear := Color(colour, 0.0)
		var h := thick * 0.5
		for edge: Array in [[-h - 0.5, clear], [-h + 0.5, colour], [h - 0.5, colour], [h + 0.5, clear]]:
			for x: float in [from.x, from.x + long]:
				points.append(Vector2(x, from.y + float(edge[0])))
				colours.append(edge[1])
		for row: int in 3:
			var a := base + 2 * row
			order.append_array([a, a + 1, a + 3, a, a + 3, a + 2])
