class_name StageHeroMaterial
extends RefCounted
## The design's materials for the character screens' 2D (§21.8), as
## nine-patch textures drawn here once and cached: a vertical gradient fill,
## an ink outline, an inner rim, a top highlight and a hard lip beneath —
## what a flat style box cannot draw. One texture a material and size, so a
## card costs one nine-patch.

## Each material: its gradient (top, middle, bottom), its inner rim and that
## rim's width in points, its outline, the hard lip beneath in points and its
## colour, the highlight along the top edge, and the ink its words take.
const KINDS := {
	"card": {"fill": ["#2E2158", "#241A4A", "#1A1236"], "rim": "#E9B65C59", "rim_w": 1.0, "line": "#0A0618",
		"lip": 2.0, "lip_c": "#0A0618", "gloss": "#FFFFFF14", "ink": "#F3EEFF"},
	"well": {"fill": ["#150D2E", "#1A1238", "#1E1540"], "rim": "#00000000", "rim_w": 0.0, "line": "#0A0618",
		"lip": 0.0, "lip_c": "#00000000", "gloss": "#FFFFFF00", "ink": "#F3EEFF"},
	"parchment": {"fill": ["#FFFBF0", "#F8EDD6", "#F1E3C4"], "rim": "#FFFFFF80", "rim_w": 1.0, "line": "#1A0C14",
		"lip": 2.0, "lip_c": "#4A2A10", "gloss": "#FFFFFF00", "ink": "#2A1A10"},
	"leather": {"fill": ["#6A3E52", "#4A2A3C", "#2E1824"], "rim": "#B8741E", "rim_w": 1.5, "line": "#1A0C14",
		"lip": 3.0, "lip_c": "#0A0408", "gloss": "#FFDCB440", "ink": "#F6E6C8"},
	"gold": {"fill": ["#FBE6B0", "#F2C870", "#E0A850"], "rim": "#6B4420", "rim_w": 1.0, "line": "#1A0C14",
		"lip": 3.0, "lip_c": "#4A2A10", "gloss": "#FFFFFF8C", "ink": "#1B1430"},
	"green": {"fill": ["#A8F0B8", "#7EDDA0", "#4FC384"], "rim": "#1F6E46", "rim_w": 1.0, "line": "#1A0C14",
		"lip": 3.0, "lip_c": "#0E3A20", "gloss": "#FFFFFF80", "ink": "#0A3A20"},
	"tab": {"fill": ["#6470E8", "#4A3CCB", "#3226A0"], "rim": "#F2C45C", "rim_w": 1.5, "line": "#120C2A",
		"lip": 0.0, "lip_c": "#00000000", "gloss": "#FFFFFF4D", "ink": "#FFF6DC"},
	"glass": {"fill": ["#1A0E22D9", "#140A1CD0", "#100816C8"], "rim": "#E9B65C73", "rim_w": 1.0,
		"line": "#00000000", "lip": 0.0, "lip_c": "#00000000", "gloss": "#FFFFFF10", "ink": "#F3EEFF"},
}

static var _cache := {}


## A style box of `kind` with corners of `corner_points`, its words held
## `pad_points` in from its edge (more beneath, over the lip).
static func box(kind: String, corner_points := 14.0, pad_points := 10.0) -> StyleBoxTexture:
	var k := of(kind)
	# A pill's round ends: a nine-patch's corners can be no larger than half
	# the smallest control, so "round" is 20 points.
	var r := UI.px(minf(corner_points, 20.0))
	var line := StageHeroSkin.edge_px() if Color(str(k["line"])).a > 0.0 else 0
	var lip := UI.px(float(k["lip"]))
	var key := "%s:%d:%d:%d" % [kind, r, line, lip]
	var tex: Texture2D = _cache.get(key)
	if tex == null:
		tex = _draw(k, r, line, lip)
		_cache[key] = tex
	var s := StyleBoxTexture.new()
	s.texture = tex
	var m := r + line + 2
	s.texture_margin_left = m
	s.texture_margin_right = m
	s.texture_margin_top = m
	s.texture_margin_bottom = m + lip
	s.content_margin_left = UI.px(pad_points)
	s.content_margin_right = UI.px(pad_points)
	s.content_margin_top = UI.px(pad_points * 0.8)
	s.content_margin_bottom = UI.px(pad_points * 0.8) + lip
	return s


## The ink words take on `kind`.
static func ink(kind: String) -> Color:
	return Color(str(of(kind)["ink"]))


## What words on `kind` sit on: its fill through the middle, where words
## are set, for the accessibility checks a gradient's style box cannot tell.
static func behind(kind: String) -> Array[Color]:
	var fill: Array = of(kind)["fill"]
	var mid := Color(str(fill[1]))
	return [Color(str(fill[0])).lerp(mid, 0.5), mid, mid.lerp(Color(str(fill[2])), 0.5)]


## A material by name, or, for a colour ("#5CC46A"), that colour as a glossy
## fill: lighter above, deeper below, rimmed in its own shadow.
static func of(kind: String) -> Dictionary:
	if KINDS.has(kind):
		return KINDS[kind]
	var c := Color(kind)
	var dark := c.get_luminance() < 0.55
	return {"fill": ["#" + c.lightened(0.22).to_html(), "#" + c.to_html(), "#" + c.darkened(0.22).to_html()],
		"rim": "#" + Color(c.lightened(0.55), 0.5).to_html(), "rim_w": 1.0, "line": "#1A0C14", "lip": 2.0,
		"lip_c": "#" + c.darkened(0.6).to_html(), "gloss": "#FFFFFF66", "ink": "#FFF6DC" if dark else "#1B1430"}


## A panel of `kind` holding `child`, its labels in the material's ink.
static func panel(kind: String, child: Control, corner_points := 14.0, pad_points := 10.0) -> PanelContainer:
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", box(kind, corner_points, pad_points))
	p.set_meta("behind", behind(kind))
	p.add_child(child)
	for l: Label in child.find_children("*", "Label", true, false) + ([child] if child is Label else []):
		if not l.has_meta("own_ink"):
			l.add_theme_color_override("font_color", ink(kind))
	return p


## Dresses a button in `kind`: pressed, a shade brighter and squashed;
## focused, a light ring; disabled, dimmed.
static func button(b: Button, kind: String, corner_points := 14.0) -> Button:
	var normal := box(kind, corner_points, 8.0)
	b.add_theme_stylebox_override("normal", normal)
	b.add_theme_stylebox_override("hover", normal)
	var pressed := box(kind, corner_points, 8.0)
	pressed.modulate_color = Color(1.06, 1.06, 1.06)
	b.add_theme_stylebox_override("pressed", pressed)
	var dim := box(kind, corner_points, 8.0)
	dim.modulate_color = Color(0.62, 0.6, 0.7, 0.8)
	b.add_theme_stylebox_override("disabled", dim)
	var focus := StyleBoxFlat.new()
	focus.draw_center = false
	focus.bg_color = Color(0, 0, 0, 0)
	focus.border_color = Color("#FFF3CC")
	focus.set_border_width_all(UI.px(1.5))
	focus.set_corner_radius_all(UI.px(corner_points + 2.0))
	focus.set_expand_margin_all(UI.px(2))
	b.add_theme_stylebox_override("focus", focus)
	b.set_meta("behind", behind(kind))
	var words := ink(kind)
	for c: String in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color",
			"font_hover_pressed_color"]:
		b.add_theme_color_override(c, words)
	b.add_theme_color_override("font_disabled_color", Color(words, 0.7))
	if not b.has_meta("squashes"):
		b.set_meta("squashes", true)
		b.button_down.connect(func() -> void: _squash(b, 0.95))
		b.button_up.connect(func() -> void: _squash(b, 1.0))
	return b


## §21.8: "buttons squash slightly when pressed"; not under reduced motion.
static func _squash(b: Button, to: float) -> void:
	if not b.is_inside_tree() or Settings.reduced_motion:
		return
	b.pivot_offset = b.size / 2.0
	var t := b.create_tween()
	t.set_ease(Tween.EASE_OUT)
	t.set_trans(Tween.TRANS_QUAD)
	t.tween_property(b, "scale", Vector2(to, to), 0.12)


## The texture: an outline, the gradient inside it, the rim inside that,
## a highlight along the top, and the lip beneath, at 2× and filtered down
## for soft edges.
static func _draw(k: Dictionary, r: int, line: int, lip: int) -> ImageTexture:
	var side := (r + line + 2) * 2 + 4
	var w := side
	var h := side + lip
	var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
	var fill: Array = k["fill"]
	var top := Color(str(fill[0]))
	var mid := Color(str(fill[1]))
	var bottom := Color(str(fill[2]))
	var outline := Color(str(k["line"]))
	var rim := Color(str(k["rim"]))
	var rim_w := float(UI.px(float(k["rim_w"])))
	var lip_c := Color(str(k["lip_c"]))
	var gloss := Color(str(k["gloss"]))
	var face_h := float(h - lip)
	for y: int in h:
		for x: int in w:
			var p := Vector2(x + 0.5, y + 0.5)
			var d_face := _rounded(p, Vector2(w, face_h), float(r + line))
			var d_lip := _rounded(p - Vector2(0, lip), Vector2(w, face_h), float(r + line))
			var c := Color(0, 0, 0, 0)
			if lip > 0:
				c = _over(c, lip_c, clampf(0.5 - d_lip, 0.0, 1.0))
			var t := clampf(p.y / face_h, 0.0, 1.0)
			var body := top.lerp(mid, t * 2.0) if t < 0.5 else mid.lerp(bottom, t * 2.0 - 1.0)
			var inside := -d_face
			var shade := body
			if line > 0:
				shade = outline.lerp(body, clampf(inside - float(line) + 0.5, 0.0, 1.0))
			if rim_w > 0.0:
				var band := clampf(inside - float(line) + 0.5, 0.0, 1.0) * clampf(float(line) + rim_w - inside + 0.5, 0.0, 1.0)
				shade = shade.lerp(Color(rim, 1.0), band * rim.a)
			if gloss.a > 0.0:
				var g := clampf(1.0 - (p.y - float(line) - rim_w) / maxf(2.0, float(UI.px(2))), 0.0, 1.0)
				g *= clampf(inside - float(line) - rim_w + 0.5, 0.0, 1.0)
				shade = shade.lerp(Color(gloss, 1.0), g * gloss.a)
			var a := clampf(0.5 - d_face, 0.0, 1.0)
			c = _over(c, Color(shade, body.a if line == 0 else 1.0), a)
			img.set_pixel(x, y, c)
	return ImageTexture.create_from_image(img)


## Signed distance from `p` to a rectangle of `size` at the origin with
## corners of `radius`: negative inside.
static func _rounded(p: Vector2, size: Vector2, radius: float) -> float:
	var q := (p - size / 2.0).abs() - size / 2.0 + Vector2(radius, radius)
	return Vector2(maxf(q.x, 0.0), maxf(q.y, 0.0)).length() + minf(maxf(q.x, q.y), 0.0) - radius


## `top` laid over `under` at `amount`.
static func _over(under: Color, top: Color, amount: float) -> Color:
	var a := top.a * amount
	var out_a := a + under.a * (1.0 - a)
	if out_a <= 0.0:
		return Color(0, 0, 0, 0)
	var rgb := (Color(top.r, top.g, top.b) * a + Color(under.r, under.g, under.b) * under.a * (1.0 - a)) / out_a
	return Color(rgb.r, rgb.g, rgb.b, out_a)
