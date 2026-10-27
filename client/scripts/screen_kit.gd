class_name ScreenKit
extends RefCounted
## T10's screens on T9's kit (client/ui): the night backdrop, the materials
## drawn by RbBox, the three faces and the design's icons, reached by the
## names the screens use. A screen asks for a surface by its part in the
## design (a card, a lit card, a well, a cream chip) and this names T9's
## material for it; every surface marks the colours its words sit on
## (`text_bg`), so the contrast check measures the words where they stand.

## The screens' names for T9's materials (ui/tokens.json `material`).
const LOOKS := {"card": "card", "card_lit": "card_selected", "well": "track", "glass": "glass",
	"parchment": "parchment", "leather": "leather", "gold": "gold", "cream": "chip_on", "red": "red", "green": "green",
	"active": "tab_active", "tab": "tab", "oak": "frame_oak", "silver": "frame_silver", "goldframe": "frame_gold",
	"prism": "frame_prismatic", "ghost": "ghost", "plate": "plate"}
## The ink words are outlined in (§21.8).
const INK := Color("#120C2A")
## An ink outline round words over a fill, in points: what §21.8 measures
## outlined words against (1.5 points or 12% of their size).
const OUTLINE_POINTS := 1.5


## The night backdrop and a column inside the safe areas (UI.frame).
static func frame(screen: Control) -> VBoxContainer:
	return UI.frame(screen)


## T9's material for a screen's surface name.
static func look(material: String) -> String:
	return LOOKS.get(material, material)


## A content box `pad` points inside a dressed control: the box a
## PanelContainer or Button keeps while its RbBox draws the material.
static func box(pad := 12.0) -> StyleBoxFlat:
	return UI.clear_box(pad, pad)


## Dresses `c` in `material` with corners of `radius` points (negative: a
## pill), its words in the material's family.
static func restyle(c: Control, material: String, radius := 16.0) -> RbBox:
	return UI.dress(c, look(material), 999.0 if radius < 0.0 else radius)


## A panel of `material` round `child`, `pad` points inside it.
static func panel(material: String, child: Control = null, radius := 16.0, pad := 12.0) -> PanelContainer:
	UI.root_theme()
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", box(pad))
	restyle(p, material, radius)
	p.set_meta("material", material)
	if child != null:
		p.add_child(child)
	return p


## The words colour of `material`: its primary or its secondary ink.
static func ink(material: String, soft := false) -> Color:
	var spec := Tokens.material(look(material))
	if soft and not Settings.high_contrast and spec.has("text_2"):
		return spec["text_2"]
	return spec["text"]


## Words: `role` is "words" (Manrope 800), "body" (Manrope 600), "number"
## (Lilita One) or "name" (Marcellus); on `material`, soft or not.
static func text(words: String, points: float, role := "words", material := "card", soft := false,
		wraps := false) -> Label:
	var l := UI.label(words, points, wraps)
	l.add_theme_font_override("font", font(role))
	l.add_theme_color_override("font_color", ink(material, soft))
	# Words on a bright fill wear the material's ink outline, as T9 draws them.
	var spec := Tokens.material(look(material))
	if spec.has("text_outline"):
		l.add_theme_color_override("font_outline_color", spec["text_outline"][0])
		l.add_theme_constant_override("outline_size", UI.px(spec["text_outline"][1]))
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	l.set_meta("bold", role in ["words", "number"])
	l.set_meta("own_ink", true)
	return l


## Words with an ink outline all round (§21.8), for a number or a title over
## a fill: at 1.5 points or more they are measured against the outline.
static func inked(l: Label, points := OUTLINE_POINTS) -> Label:
	l.add_theme_color_override("font_outline_color", INK)
	l.add_theme_constant_override("outline_size", UI.px(points * 2.0))
	return l


## §21.8's faces: Manrope 800 with tabular figures for words and numbers
## that change, Manrope 600 for body text, Lilita One for large numbers that
## do not, Marcellus for titles and names.
static func font(role: String) -> Font:
	match role:
		"body":
			return Tokens.font("ui", 600, true)
		"number":
			return Tokens.font("display")
		"name":
			return Tokens.font("title")
	return Tokens.font("ui", 800, true)


## A button in `material` ("gold" for the main action, "leather" otherwise,
## or any material), squashing and sinking onto its drop when pressed.
static func button(words: String, pressed: Callable, material := "leather", spoken := "",
		radius := 16.0) -> Button:
	var b := UI.action(words, pressed, look(material), spoken)
	dress(b, material, radius)
	return b


## Gives an existing button `material`'s look and corners.
static func dress(b: Button, material: String, radius := 16.0) -> Button:
	UI.set_look(b, look(material))
	restyle(b, material, radius)
	b.add_theme_font_override("font", font("words"))
	b.set_meta("material", material)
	UI.fit(b)
	return b


## An icon from the design's set (T9's Icons), `points` square; an empty
## square when the set has no such icon.
static func icon(group: String, name: String, points := 24.0) -> TextureRect:
	var key := icon_key(group, name)
	if key != "":
		return Icons.view(key, points)
	var t := TextureRect.new()
	t.custom_minimum_size = Vector2.ONE * UI.px(points)
	t.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return t


## An icon's texture, or null.
static func icon_texture(group: String, name: String) -> Texture2D:
	var key := icon_key(group, name)
	return Icons.texture(key) if key != "" else null


## The set's name for an icon (`group/name`), or "" when it has none.
static func icon_key(group: String, name: String) -> String:
	var key := "%s/%s" % [group, name.to_lower().replace("_", "").replace(" ", "").replace("-", "")]
	return key if Icons.has(key) else ""
