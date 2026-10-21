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
## the designs' radial gradients, drawn as rings closing on the highlight.
static func ball(ci: CanvasItem, centre: Vector2, radius: float, ramp: Array, rim := Color(), ink := true) -> void:
	var light := centre + Vector2(0.0, -radius * 0.44)
	var steps := 14
	for i: int in steps:
		var t := float(i) / float(steps - 1)
		var c: Color = (ramp[2] as Color).lerp(ramp[1], minf(1.0, t / 0.55)) if t < 0.55 \
			else (ramp[1] as Color).lerp(ramp[0], (t - 0.55) / 0.45)
		var r := radius * (1.0 - t * 0.78)
		ci.draw_circle(centre.lerp(light, t * 0.85), r, c, true, -1.0, true)
	if rim != Color():
		ci.draw_arc(centre, radius - UI.px(1.5), 0.0, TAU, 48, rim, UI.px(2.0), true)
	if ink:
		ci.draw_arc(centre, radius, 0.0, TAU, 56, INK_LINE, outline_px(), true)


## A soft shadow under a round shape, on the world.
static func drop(ci: CanvasItem, centre: Vector2, radius: float, colour := HARD_DROP) -> void:
	ci.draw_circle(centre + Vector2(0.0, UI.px(3.5)), radius, colour, true, -1.0, true)


## Words with an ink outline all round (§21.8 measures them against it).
static func inked(ci: CanvasItem, font: Font, at: Vector2, text: String, size_px: int, colour: Color,
		width := -1.0, align := HORIZONTAL_ALIGNMENT_LEFT, outline := -1.0) -> void:
	var o := int(outline if outline >= 0.0 else maxf(UI.px(1.5), size_px * 0.14))
	ci.draw_string_outline(font, at, text, align, width, size_px, o, INK_LINE)
	ci.draw_string(font, at, text, align, width, size_px, colour)


## A count badge: a red disc with its number in paper (or a glyph), outlined
## in ink, so it never rests on colour alone (§20.8).
static func badge(ci: CanvasItem, centre: Vector2, text: String) -> void:
	var font := words_font()
	var size_px := UI.text_px(13.0)
	var w := font.get_string_size(text, HORIZONTAL_ALIGNMENT_CENTER, -1, size_px).x
	var r := maxf(UI.px(11), size_px * 0.62)
	var half := maxf(0.0, w * 0.5 - r * 0.55)
	var box := Rect2(centre - Vector2(r + half, r), Vector2((r + half) * 2.0, r * 2.0))
	plate(ALARM_FILL, r).draw(ci.get_canvas_item(), box)
	var base := centre.y + font.get_ascent(size_px) * 0.5 - font.get_descent(size_px) * 0.35
	ci.draw_string(font, Vector2(box.position.x, base), text, HORIZONTAL_ALIGNMENT_CENTER, box.size.x, size_px,
		Color.WHITE)


## A number in the language's grouping: 12,650.
static func grouped(n: int) -> String:
	return ShopPresenter.grouped(n)

