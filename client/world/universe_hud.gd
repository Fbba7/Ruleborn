class_name UniverseHud
extends RefCounted
## The look home's interface is drawn in (§21.8's two families of surface, as
## the designs draw them): dark glass for pills over the world, leather for
## round buttons, gold for the main action, all outlined in ink; light words
## on the dark. Shared by the Keeper badge, the strain pill, the resource
## bars, the side buttons, the goal and the tabs, so each is drawn the same.

const INK_LINE := Color("#1A0C14")
const DEEP_INK := Color("#120C2A")
## §21.8: "dark glass at 78% for pills over the world (#140A16)".
const GLASS := Color(0.078, 0.039, 0.086, 0.78)
const GLASS_RIM := Color(0.949, 0.769, 0.361, 0.45)
const WORDS := Color("#F3EEFF")
## §21.8: secondary words on dark are no darker than #B8A8D8.
const SOFT_WORDS := Color("#B8A8D8")
const CREAM := Color("#FFF3CC")
const LEATHER := [Color("#6A3E52"), Color("#3A2030"), Color("#1E1018")]
const LEATHER_RIM := Color("#B8741E")
const GOLD := [Color("#FFF3CC"), Color("#F2C45C"), Color("#B8741E")]
const GOLD_RIM := Color("#6B4420")
const GOLD_DROP := Color("#4A2A10")
const HARD_DROP := Color("#0A0408")
## The active tab's periwinkle, as the designs draw it.
const ACTIVE := [Color("#8FA2FF"), Color("#6A5AF0"), Color("#4532B8")]
const CARD := [Color("#261A4C"), Color("#1A1134")]
## §21.8: red for alarms as a fill, and the deeper red words sit on.
const ALARM := Color("#E2536B")
const ALARM_FILL := Color("#B3203A")
const SUCCESS := Color("#3FBF7F")
## Each resource's colour and icon (the designs' `RBIcons.res`).
const RESOURCES := {"starlight": Color("#F2B43C"), "aether": Color("#3CC6D8"), "essence": Color("#5CC46A")}
## Each strain band's colour (§5.5's seven bands, as the designs colour them);
## the band's name is always written beside it (§20.8).
const BANDS := [Color("#7A6E86"), Color("#5CC46A"), Color("#3CC6D8"), Color("#E9B65C"), Color("#F07A3C"),
	Color("#E2536B"), Color("#9C2A4A")]

## Baked balls, by size and look.
static var _balls := {}


## An icon of the design's set. Load it before drawing, never inside `_draw`:
## a texture first loaded there draws white under the Compatibility renderer.
static func icon(file: String) -> Texture2D:
	var path := "res://world/universe_icons/%s.svg" % file
	return load(path) as Texture2D if ResourceLoader.exists(path) else null


## Manrope at 800: the HUD's words and changing numbers.
static func words_font() -> Font:
	return FxSkin.words()


## Lilita One: large numbers that do not change, and short titles.
static func numbers_font() -> Font:
	return FxSkin.numbers()


## Marcellus: names and titles.
static func names_font() -> Font:
	return StageHeroSkin.names_font()


static func outline_px() -> float:
	return UI.px(3.0 if Settings.high_contrast else 2.0)


## The glass pill: dark glass with a faint gold rim and a soft shadow; opaque
## with a full ink outline in high contrast (§21.8: "no glass").
static func glass(radius: float) -> StyleBoxFlat:
	var b := StyleBoxFlat.new()
	b.bg_color = Color(GLASS, 1.0) if Settings.high_contrast else GLASS
	b.border_color = INK_LINE if Settings.high_contrast else GLASS_RIM
	b.set_border_width_all(UI.px(3.0) if Settings.high_contrast else maxi(2, UI.px(1.5)))
	b.set_corner_radius_all(int(radius))
	b.shadow_color = Color(0, 0, 0, 0.35)
	b.shadow_size = UI.px(4)
	b.shadow_offset = Vector2(0, UI.px(2))
	b.anti_aliasing = true
	return b


## A rounded plate in `fill`, outlined in ink, with a hard drop under it.
static func plate(fill: Color, radius: float, under := HARD_DROP) -> StyleBoxFlat:
	var b := StyleBoxFlat.new()
	b.bg_color = fill
	b.border_color = INK_LINE
	b.set_border_width_all(int(outline_px()))
	b.set_corner_radius_all(int(radius))
	b.shadow_color = under
	b.shadow_size = 0
	b.shadow_offset = Vector2(0, UI.px(2.5))
	b.anti_aliasing = true
	return b


## A ball shaded from `ramp` (light, middle, dark), lit from the upper left:
## the designs' radial gradients. Baked once per size and look into a texture
## and drawn as one quad, so a ball costs the frame one draw call (§21.3),
## not the dozens its rings and anti-aliased edges would.
## With `dropped`, its hard drop is baked in beneath it, the same one call.
static func ball(ci: CanvasItem, centre: Vector2, radius: float, ramp: Array, rim := Color(), ink := true,
		dropped := false) -> void:
	var tex := ball_texture(radius, ramp, rim, ink, dropped)
	var half := tex.get_width() * 0.5
	ci.draw_texture_rect(tex, Rect2(centre - Vector2(half, half), Vector2(tex.get_width(), tex.get_height())), false)


## The baked ball `ball` draws: a disc of `radius` pixels in a texture one
## pixel wider all round, its edges anti-aliased by coverage.
static func ball_texture(radius: float, ramp: Array, rim := Color(), ink := true, dropped := false) -> ImageTexture:
	var r := roundf(radius)
	var line := outline_px() if ink else 0.0
	var under := UI.px(3.5) if dropped else 0
	var key := "%d:%s:%s:%s:%s:%d" % [r, ramp, rim, line, Settings.high_contrast, under]
	if _balls.has(key):
		return _balls[key]
	var side := int(r) * 2 + 2
	var img := Image.create_empty(side, side + under, false, Image.FORMAT_RGBA8)
	var c := Vector2(side, side) * 0.5
	var light := c + Vector2(0.0, -r * 0.44)
	for y in side + under:
		for x in side:
			var p := Vector2(x + 0.5, y + 0.5)
			var d := p.distance_to(c)
			var cover := clampf(r - d + 0.5, 0.0, 1.0)
			if cover <= 0.0:
				img.set_pixel(x, y, Color(HARD_DROP, clampf(r - p.distance_to(c + Vector2(0, under)) + 0.5, 0.0, 1.0))
					if under > 0 else Color(0, 0, 0, 0))
				continue
			# Light at the highlight, the middle tone half way, dark at the rim.
			var t := clampf(p.distance_to(light) / (r * 1.38), 0.0, 1.0)
			var col: Color = (ramp[0] as Color).lerp(ramp[1], t / 0.45) if t < 0.45 \
				else (ramp[1] as Color).lerp(ramp[2], (t - 0.45) / 0.55)
			if rim != Color():
				var ring := clampf(1.0 - absf(d - (r - line - UI.px(1.5))) / maxf(1.0, UI.px(1.0)), 0.0, 1.0)
				col = col.lerp(rim, ring)
			if line > 0.0:
				col = col.lerp(INK_LINE, clampf(d - (r - line) + 0.5, 0.0, 1.0))
			img.set_pixel(x, y, Color(col, col.a * cover))
	var tex := ImageTexture.create_from_image(img)
	_balls[key] = tex
	return tex


## A soft shadow under a round shape, on the world.
static func drop(ci: CanvasItem, centre: Vector2, radius: float, colour := HARD_DROP) -> void:
	ball(ci, centre + Vector2(0.0, UI.px(3.5)), radius, [colour, colour, colour], Color(), false)


## A gold pill `tall` pixels high as the designs' main pills (Collect): lit
## from above with a cream crown, a deeper foot, a cream inner rim, outlined
## in ink on a hard drop and a soft warm glow. Baked once per height into a
## nine-slice box whose middle stretches, so any width is one draw call.
static func gold_pill(tall: float) -> StyleBoxTexture:
	var h := int(roundf(tall))
	var key := "pill:%d:%s" % [h, Settings.high_contrast]
	if _balls.has(key):
		return _balls[key]
	var glow := 0 if Settings.high_contrast else UI.px(7)
	var under := UI.px(3)
	var r := h * 0.5
	var w := h + 2 + glow * 2
	var img := Image.create_empty(w, h + glow * 2 + under, false, Image.FORMAT_RGBA8)
	var line := outline_px()
	var mid := w * 0.5
	for y in img.get_height():
		for x in w:
			var p := Vector2(x + 0.5, y + 0.5) - Vector2(0.0, glow)
			var axis := Vector2(clampf(p.x, mid - 1.0, mid + 1.0), r)
			var d := p.distance_to(axis)
			var dd := (p - Vector2(0.0, under)).distance_to(Vector2(clampf(p.x, mid - 1.0, mid + 1.0), r))
			var col := Color(GOLD[1], clampf(1.0 - (d - r) / maxf(1.0, glow), 0.0, 1.0) * 0.35) if glow > 0 \
				else Color(0, 0, 0, 0)
			col = _over(col, Color(GOLD_DROP, clampf(r - dd + 0.5, 0.0, 1.0)))
			var cover := clampf(r - d + 0.5, 0.0, 1.0)
			if cover > 0.0:
				var v := clampf(p.y / h, 0.0, 1.0)
				var body: Color = (GOLD[0] as Color).lerp(GOLD[1], v / 0.5) if v < 0.5 \
					else (GOLD[1] as Color).lerp(Color("#C27E22"), (v - 0.5) / 0.5)
				body = body.lerp(Color(GOLD[0]), clampf(1.0 - absf(d - (r - line - UI.px(1.5))) / UI.px(1.0), 0.0, 1.0)
					* 0.8)
				body = body.lerp(INK_LINE, clampf(d - (r - line) + 0.5, 0.0, 1.0))
				col = _over(col, Color(body, cover))
			img.set_pixel(x, y, col)
	var box := StyleBoxTexture.new()
	box.texture = ImageTexture.create_from_image(img)
	box.texture_margin_left = r + glow
	box.texture_margin_right = r + glow
	box.expand_margin_left = glow
	box.expand_margin_right = glow
	box.expand_margin_top = glow
	box.expand_margin_bottom = glow + under
	_balls[key] = box
	return box


## `plate`'s look baked into a nine-slice box (a rounded plate in `fill`,
## outlined in ink, on its hard drop), so any size of it is one draw call.
static func baked_plate(fill: Color, radius: float) -> StyleBoxTexture:
	return baked_box(fill, INK_LINE, outline_px(), radius, HARD_DROP, UI.px(2.5))


## A rounded box in `fill`, edged `line` pixels in `edge`, on a drop `under`
## pixels down in `shade`, baked once into a nine-slice box: one draw call
## at any size, where a flat box with a shadow and smoothed edges is several.
static func baked_box(fill: Color, edge: Color, line: float, radius: float, shade: Color,
		under: int) -> StyleBoxTexture:
	var r := maxi(2, int(roundf(radius)))
	var key := "box:%s:%s:%s:%d:%s:%d" % [fill, edge, line, r, shade, under]
	if _balls.has(key):
		return _balls[key]
	var side := r * 2 + 2
	var img := Image.create_empty(side, side + under, false, Image.FORMAT_RGBA8)
	var corner := func(p: Vector2, lift: float) -> float:
		var q := Vector2(clampf(p.x, r, side - r), clampf(p.y, r + lift, side - r + lift))
		return p.distance_to(q) - r
	for y in side + under:
		for x in side:
			var p := Vector2(x + 0.5, y + 0.5)
			var d: float = corner.call(p, 0.0)
			var col := Color(shade, shade.a * clampf(0.5 - float(corner.call(p, under)), 0.0, 1.0)) if under > 0 \
				else Color(0, 0, 0, 0)
			var cover := clampf(0.5 - d, 0.0, 1.0)
			if cover > 0.0:
				var body := fill.lerp(edge, clampf(d + line + 0.5, 0.0, 1.0)) if line > 0.0 else fill
				col = _over(col, Color(body, body.a * cover))
			img.set_pixel(x, y, col)
	var box := StyleBoxTexture.new()
	box.texture = ImageTexture.create_from_image(img)
	box.set_texture_margin_all(r)
	box.texture_margin_bottom = r + under
	box.expand_margin_bottom = under
	_balls[key] = box
	return box


## `top` laid over `under`.
static func _over(under: Color, top: Color) -> Color:
	var a := top.a + under.a * (1.0 - top.a)
	if a <= 0.0:
		return Color(0, 0, 0, 0)
	return Color((Color(top.r, top.g, top.b) * top.a + Color(under.r, under.g, under.b) * under.a * (1.0 - top.a)) / a,
		a)


## Words with an ink outline all round (§21.8 measures them against it).
static func inked(ci: CanvasItem, font: Font, at: Vector2, text: String, size_px: int, colour: Color,
		width := -1.0, align := HORIZONTAL_ALIGNMENT_LEFT, outline := -1.0) -> void:
	var o := int(outline if outline >= 0.0 else maxf(UI.px(1.5), size_px * 0.14))
	ci.draw_string_outline(font, at, text, align, width, size_px, o, INK_LINE)
	ci.draw_string(font, at, text, align, width, size_px, colour)


## A count badge: a red disc with its number in paper (or a glyph), outlined
## in ink, so it never rests on colour alone (§20.8).
static func badge(ci: CanvasItem, centre: Vector2, text: String) -> void:
	badge_words(ci, badge_box(ci, centre, text), text)


## A count badge's disc, drawn; returns where its words go.
static func badge_box(ci: CanvasItem, centre: Vector2, text: String) -> Rect2:
	var font := words_font()
	var size_px := UI.text_px(13.0)
	var w := font.get_string_size(text, HORIZONTAL_ALIGNMENT_CENTER, -1, size_px).x
	var r := maxf(UI.px(11), size_px * 0.62)
	var half := maxf(0.0, w * 0.5 - r * 0.55)
	var box := Rect2(centre - Vector2(r + half, r), Vector2((r + half) * 2.0, r * 2.0))
	baked_plate(ALARM_FILL, r).draw(ci.get_canvas_item(), box)
	return box


## A count badge's words on its disc (`badge_box`).
static func badge_words(ci: CanvasItem, box: Rect2, text: String) -> void:
	var font := words_font()
	var size_px := UI.text_px(13.0)
	var base := box.get_center().y + font.get_ascent(size_px) * 0.5 - font.get_descent(size_px) * 0.35
	ci.draw_string(font, Vector2(box.position.x, base), text, HORIZONTAL_ALIGNMENT_CENTER, box.size.x, size_px,
		Color.WHITE)


## A number in the language's grouping: 12,650.
static func grouped(n: int) -> String:
	return ShopPresenter.grouped(n)


## An amount as the designs' resource row shows it: in full below 10,000, then
## in thousands or millions to one decimal, cut down, never rounded up, so it
## never shows more than is held ("142.0k"). Collect shortens from `from` on,
## as the design's "COLLECT 3.4k" does.
static func compact(n: int, from := 10000) -> String:
	if absi(n) < from:
		return grouped(n)
	var big := absi(n) >= 1000000
	var tenths := absi(n) / (100000 if big else 100)
	var text := "%s%s%s%d" % ["-" if n < 0 else "", grouped(tenths / 10), Strings.t("NUMBER_DECIMAL"), tenths % 10]
	return Strings.t("HOME_AMOUNT_MILLIONS" if big else "HOME_AMOUNT_THOUSANDS", text)

