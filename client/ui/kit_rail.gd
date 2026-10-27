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
	var m := KitTris.new()
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
	m.draw_on(get_canvas_item())
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
