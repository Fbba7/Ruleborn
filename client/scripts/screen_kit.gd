class_name ScreenKit
extends RefCounted
## The design's menu screens' surfaces (§21.8), for T10's screens until T9's
## kit carries them: the night backdrop, the dark violet card, glass pills,
## parchment, leather and gold, each outlined in ink with its rim, gloss and
## hard drop; Manrope for words and numbers that change, Lilita One for large
## numbers that do not, Marcellus for titles and names. Every surface names
## the colours behind its words (meta "behind"), so the contrast check
## measures words against what they really sit on.

## Each material: its fill stops, outline, rims, gloss, hard drop and words.
const MATERIALS := {
	"card": {"top": "#2A1E56", "bottom": "#1A1134", "line": 0.0, "rim": "#E9B65C66", "rim_px": 1.5,
		"gloss": "#FFFFFF1A", "drop": "#0A0618", "drop_px": 3.0, "words": "#F3EEFF", "soft": "#E0D8F7"},
	"card_lit": {"top": "#3A2A6A", "bottom": "#22164A", "line": 0.0, "rim": "#F2C45CCC", "rim_px": 2.0,
		"gloss": "#FFFFFF24", "drop": "#0A0618", "drop_px": 3.0, "words": "#F3EEFF", "soft": "#E0D8F7",
		"glow": "#B49CFF55"},
	"well": {"top": "#120A26", "bottom": "#1A1134", "line": 0.0, "rim": "#00000055", "rim_px": 1.5,
		"words": "#F3EEFF", "soft": "#E0D8F7"},
	"glass": {"top": "#140A16C7", "bottom": "#140A16C7", "line": 0.0, "rim": "#E9B65C73", "rim_px": 1.5,
		"shadow": "#00000059", "words": "#F3EEFF", "soft": "#E0D8F7"},
	"parchment": {"top": "#FFFBF0", "bottom": "#F1E3C4", "line": 2.0, "drop": "#4A2A10", "drop_px": 3.0,
		"words": "#2A1A10", "soft": "#4A3226"},
	"leather": {"top": "#6A3E52", "mid": "#3A2030", "bottom": "#2A1622", "line": 2.0, "rim": "#B8741E",
		"rim_px": 2.0, "gloss": "#FFDCB433", "drop": "#0A0408", "drop_px": 4.0, "words": "#F6E6C8",
		"soft": "#E8D2B0"},
	"gold": {"top": "#F9DE9C", "mid": "#EDBE68", "bottom": "#E2A84E", "line": 2.0, "rim": "#FFEEC4AA",
		"rim_px": 1.0, "gloss": "#FFFFFF8C", "drop": "#4A2A10", "drop_px": 4.0, "words": "#1B1430",
		"soft": "#3A2410", "glow": "#E9B65C4D"},
	"cream": {"top": "#FFF6DA", "bottom": "#F2D58E", "line": 2.0, "drop": "#4A2A10", "drop_px": 2.0,
		"words": "#2A1A10", "soft": "#4A3020"},
	"red": {"top": "#C23150", "bottom": "#B3203A", "line": 2.0, "rim": "#FF8A9A88", "rim_px": 1.0,
		"drop": "#0A0408", "drop_px": 4.0, "words": "#FFFBF0", "soft": "#FFE6EA"},
	"green": {"top": "#A8F0B8", "bottom": "#6CD494", "line": 2.0, "drop": "#0A3A20", "drop_px": 3.0,
		"words": "#062814", "soft": "#062814"},
	"active": {"top": "#8FA2FF", "mid": "#6A5AF0", "bottom": "#4532B8", "line": 2.0, "rim": "#F2C45C",
		"rim_px": 3.0, "rim2": "#8A5A1C", "rim2_px": 1.5, "gloss": "#FFFFFF4D", "glow": "#AA96FF8C",
		"words": "#FFF6DC", "soft": "#FFF6DC"},
	"oak": {"top": "#C89058", "mid": "#8A5630", "bottom": "#6A3E1E", "line": 2.0, "rim": "#E8B888", "rim_px": 1.5,
		"gloss": "#FFFFFF33", "words": "#FFF3E0", "soft": "#FFF3E0"},
	"silver": {"top": "#FAFCFF", "mid": "#B4BECE", "bottom": "#86919F", "line": 2.0, "rim": "#FFFFFFAA",
		"rim_px": 1.5, "gloss": "#FFFFFF66", "words": "#1A0C14", "soft": "#1A0C14"},
	"goldframe": {"top": "#FFF6CF", "mid": "#E9B65C", "bottom": "#AE6E16", "line": 2.0, "rim": "#FFE8A0",
		"rim_px": 1.5, "gloss": "#FFFFFF66", "words": "#1A0C14", "soft": "#1A0C14"},
	"prism": {"top": "#FF8AD0", "mid": "#8AF0C8", "bottom": "#C29AFF", "line": 2.0, "rim": "#FFFFFFAA",
		"rim_px": 1.5, "gloss": "#FFFFFF66", "words": "#1A0C14", "soft": "#1A0C14"},
	"tab": {"top": "#2A1E52", "bottom": "#160E30", "line": 0.0, "words": "#E2D8FF", "soft": "#E0D8F7"},
}
## The night backdrop of the menu screens (§21.2, §21.8): a violet glow
## falling to near black, and its two ends for the contrast check.
const NIGHT := [Color("#2E1F5E"), Color("#140C30"), Color("#0A0620")]
## The ink words are outlined in (§21.8).
const INK := Color("#120C2A")
## A third of an ink outline for words over a fill, in points (§21.8).
const OUTLINE_POINTS := 1.5
## The families of §21.8, by role.
const FONT_FILES := {"words": "res://world/fx_fonts/manrope_800.woff2",
	"body": "res://world/fx_fonts/manrope_600.woff2",
	"number": "res://world/fx_fonts/lilita_one.woff2", "name": "res://world/stage_hero_names.woff2"}
## Corner radii by the design's five-step scale, in points.
const RADIUS := {"tag": 8.0, "pill": 12.0, "card": 16.0, "stage": 22.0}

static var _fonts := {}


## The night backdrop and a column inside the safe areas, as UI.frame lays it
## out; the screen says which sky its words are measured over.
static func frame(screen: Control) -> VBoxContainer:
	var column := UI.frame(screen)
	var sky := screen.get_node("Sky") as TextureRect
	sky.texture = backdrop_texture()
	sky.stretch_mode = TextureRect.STRETCH_SCALE
	var stars := ScreenStars.new()
	stars.set_anchors_preset(Control.PRESET_FULL_RECT)
	stars.mouse_filter = Control.MOUSE_FILTER_IGNORE
	screen.add_child(stars)
	screen.move_child(stars, 1)
	screen.set_meta("sky", [NIGHT[0], NIGHT[2]])
	return column


static func backdrop_texture() -> GradientTexture2D:
	var g := Gradient.new()
	g.offsets = PackedFloat32Array([0.0, 0.55, 1.0])
	g.colors = PackedColorArray(NIGHT)
	var t := GradientTexture2D.new()
	t.gradient = g
	t.fill = GradientTexture2D.FILL_RADIAL
	t.fill_from = Vector2(0.5, 0.18)
	t.fill_to = Vector2(1.25, 1.0)
	t.width = 128
	t.height = 256
	return t


## A material's style box, `pad` points inside it, its corner `radius` points
## (negative: a pill).
static func box(material: String, radius := 16.0, pad := 12.0) -> ScreenBox:
	var m: Dictionary = MATERIALS[material]
	var b := ScreenBox.new()
	b.top = Color(str(m["top"]))
	b.bottom = Color(str(m["bottom"]))
	b.mid = Color(str(m["mid"])) if m.has("mid") else Color(0, 0, 0, 0)
	b.radius = radius if radius < 0.0 else float(UI.px(radius))
	var hc := Settings.high_contrast
	b.line_px = UI.px(3.0) if hc else UI.px(float(m.get("line", 0.0)) / 1.5)
	if m.has("rim"):
		b.rim = Color(str(m["rim"]))
		b.rim_px = UI.px(float(m["rim_px"]) / 1.5)
	if m.has("rim2"):
		b.rim2 = Color(str(m["rim2"]))
		b.rim2_px = UI.px(float(m["rim2_px"]) / 1.5)
	if m.has("gloss") and not hc:
		b.gloss = Color(str(m["gloss"]))
		b.gloss_px = UI.px(2.0)
	if m.has("drop"):
		b.drop = Color(str(m["drop"]))
		b.drop_px = UI.px(float(m["drop_px"]) / 1.5)
	if m.has("shadow"):
		b.shadow = Color(str(m["shadow"]))
		b.shadow_px = UI.px(4.0)
		b.shadow_y = UI.px(2.0)
	elif m.has("glow"):
		b.shadow = Color(str(m["glow"]))
		b.shadow_px = UI.px(6.0)
	if hc:
		b.top = Color(b.top, 1.0)
		b.bottom = Color(b.bottom, 1.0)
	b.set_content_margin_all(UI.px(pad))
	return b


## The colours words on `material` sit on, at its worst points: its stops,
## laid over the night where the material lets the night through.
static func behind(material: String) -> Array[Color]:
	var m: Dictionary = MATERIALS[material]
	var out: Array[Color] = []
	for k: String in ["top", "mid", "bottom"]:
		if m.has(k):
			var c := Color(str(m[k]))
			if Settings.high_contrast:
				c.a = 1.0
			for night: Color in [NIGHT[0], NIGHT[2]]:
				out.append(ColourCheck.over(c, night))
	return out


## A panel of `material` round `child`; its labels take the material's words.
static func panel(material: String, child: Control = null, radius := 16.0, pad := 12.0) -> PanelContainer:
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", box(material, radius, pad))
	p.set_meta("behind", behind(material))
	p.set_meta("material", material)
	if child != null:
		p.add_child(child)
	return p


## The words colour of `material`: "words" or "soft".
static func ink(material: String, soft := false) -> Color:
	var m: Dictionary = MATERIALS[material]
	if soft and not Settings.high_contrast:
		return Color(str(m["soft"]))
	return Color(str(m["words"]))


## Words: `role` is "words" (Manrope 800), "body" (Manrope 600), "number"
## (Lilita One) or "name" (Marcellus); on `material`, soft or not.
static func text(words: String, points: float, role := "words", material := "card", soft := false,
		wraps := false) -> Label:
	var l := UI.label(words, points, wraps)
	l.add_theme_font_override("font", font(role))
	l.add_theme_color_override("font_color", ink(material, soft))
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	l.set_meta("bold", role in ["words", "number"])
	l.set_meta("own_ink", true)
	return l


## Words with an ink outline all round (§21.8), for a number or a title over
## a fill or the world. An outline at least 1.5 points or 12% of the words'
## size is what the words are measured against.
static func inked(l: Label, points := OUTLINE_POINTS) -> Label:
	l.add_theme_color_override("font_outline_color", INK)
	l.add_theme_constant_override("outline_size", UI.px(points * 2.0))
	if points >= maxf(OUTLINE_POINTS, float(l.get_meta("points", UI.TEXT_POINTS)) * 0.12):
		l.set_meta("behind", [INK])
	return l


static func font(role: String) -> Font:
	if _fonts.has(role):
		return _fonts[role]
	var file: String = FONT_FILES.get(role, "")
	var f: Font = ThemeDB.fallback_font
	if file != "" and ResourceLoader.exists(file):
		var loaded := load(file) as FontFile
		loaded.fallbacks = [ThemeDB.fallback_font]
		if role in ["words", "body"]:
			var v := FontVariation.new()
			v.base_font = loaded
			v.opentype_features = {"tnum": 1}
			f = v
		else:
			f = loaded
	_fonts[role] = f
	return f


## A button in `material` ("gold" for the main action, "leather" otherwise,
## or any material), with the design's press: it sinks onto its drop and
## squashes slightly (§21.8). Keeps UI.button's size, haptics and name.
static func button(words: String, pressed: Callable, material := "leather", spoken := "",
		radius := 16.0) -> Button:
	var b := UI.button(words, pressed, material == "gold", Color(), spoken)
	dress(b, material, radius)
	return b


## Gives an existing button `material`'s look in every state.
static func dress(b: Button, material: String, radius := 16.0) -> Button:
	for state: String in ["normal", "hover", "pressed", "disabled"]:
		var s := box(material, radius, 8.0)
		s.content_margin_left = UI.px(14)
		s.content_margin_right = UI.px(14)
		match state:
			"hover":
				s.top = s.top.lightened(0.05)
			"pressed":
				s.sink_px = s.drop_px
			"disabled":
				s.top = s.top.darkened(0.45)
				s.mid = s.mid.darkened(0.45) if s.mid.a > 0.0 else s.mid
				s.bottom = s.bottom.darkened(0.45)
				s.rim = Color(s.rim, s.rim.a * 0.4)
				s.gloss = Color(0, 0, 0, 0)
				s.shadow = Color(0, 0, 0, 0)
		b.add_theme_stylebox_override(state, s)
	var focus := ScreenBox.new()
	focus.top = Color(0, 0, 0, 0)
	focus.bottom = Color(0, 0, 0, 0)
	focus.radius = radius if radius < 0.0 else float(UI.px(radius))
	focus.rim = Color("#FFF3CC")
	focus.rim_px = UI.px(2.0)
	b.add_theme_stylebox_override("focus", focus)
	var words := ink(material)
	for c: String in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color",
			"font_hover_pressed_color"]:
		b.add_theme_color_override(c, words)
	b.add_theme_color_override("font_disabled_color", Color(words, 0.6))
	b.add_theme_font_override("font", font("words"))
	b.set_meta("behind", behind(material))
	b.set_meta("material", material)
	if not b.button_down.is_connected(_squash.bind(b, 0.96)):
		b.button_down.connect(_squash.bind(b, 0.96))
		b.button_up.connect(_squash.bind(b, 1.0))
	UI.fit(b)
	return b


## An icon from the design's set (art/design/diorama/icons.js, exported by
## tools/screen_icons), `points` square; empty when the set has no such icon.
static func icon(group: String, name: String, points := 24.0) -> TextureRect:
	var t := TextureRect.new()
	var path := icon_path(group, name)
	if path != "":
		t.texture = load(path)
	t.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	t.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	t.custom_minimum_size = Vector2.ONE * UI.px(points)
	t.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return t


static func icon_path(group: String, name: String) -> String:
	var key := name.to_lower().replace("_", "").replace(" ", "").replace("-", "")
	var path := "res://art/screen_icons/%s_%s.svg" % [group, key]
	return path if ResourceLoader.exists(path) else ""


static func _squash(b: Button, to: float) -> void:
	if not b.is_inside_tree() or Settings.reduced_motion:
		return
	b.pivot_offset = b.size / 2.0
	var t := b.create_tween()
	t.set_ease(Tween.EASE_OUT)
	t.set_trans(Tween.TRANS_QUAD)
	t.tween_property(b, "scale", Vector2(to, to), 0.12)
