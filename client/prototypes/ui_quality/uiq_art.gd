class_name UiqArt
extends RefCounted
## T14's proof (docs/art/ui-quality/report.md): the heist HUD's authored art,
## baked offline by tools/ui_research/bake_hud.js into one atlas. Frames are
## 9-slices, icons and buttons sprites, numerals one picture a glyph in four
## finishes; words stay live text, set in Lilita One with an ink outline and
## a hard drop. One texture, so the HUD batches. A prototype only: no screen
## of the game uses it.

const DIR := "res://prototypes/ui_quality/art/"
const INK := Color("#1A0C14")
const GOLD := Color("#FFD866")
const TEXT_Z := 2
const GLYPH := {":": "colon", ",": "comma", "/": "slash", "~": "tilde", "%": "percent", "+": "plus"}

static var _manifest: Dictionary = {}
static var _atlas: Texture2D
static var _pieces: Dictionary = {}
static var _font: Font


## A piece's place in the atlas.
static func region(name: String) -> Rect2:
	if _manifest.is_empty():
		_manifest = JSON.parse_string(FileAccess.get_file_as_string(DIR + "manifest.json"))
		_atlas = load(DIR + "atlas.webp") as Texture2D
	var p: Dictionary = _manifest.get(name, {})
	return Rect2(float(p.get("x", 0)), float(p.get("y", 0)), float(p.get("w", 1)), float(p.get("h", 1)))


static func tex(name: String) -> Texture2D:
	if not _pieces.has(name):
		var t := AtlasTexture.new()
		t.region = region(name)
		t.atlas = _atlas
		_pieces[name] = t
	return _pieces[name]


## A frame as a 9-slice, its margins from the bake's manifest.
static func nine(name: String) -> NinePatchRect:
	var n := NinePatchRect.new()
	n.region_rect = region(name)
	n.texture = _atlas
	n.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var s: Variant = (_manifest.get(name, {}) as Dictionary).get("slice")
	if s is Dictionary:
		n.patch_margin_left = int(s["l"])
		n.patch_margin_top = int(s["t"])
		n.patch_margin_right = int(s["r"])
		n.patch_margin_bottom = int(s["b"])
	return n


## A sprite at a size, centred on `at` (in its parent's pixels).
static func sprite(name: String, at: Vector2, side: Vector2) -> TextureRect:
	var t := TextureRect.new()
	t.texture = tex(name)
	t.mouse_filter = Control.MOUSE_FILTER_IGNORE
	t.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	t.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	t.position = at - side / 2.0
	t.size = side
	return t


## A number in baked glyphs: `style` is timer, timer_red, gold or white;
## `h` the glyphs' height. Glyphs overlap by their strokes, as set type does.
static func digits(text: String, style: String, h: float) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_theme_constant_override("separation", int(-h * 0.1))
	for ch in text:
		if ch == " ":
			continue
		var t := TextureRect.new()
		t.texture = tex("num_%s_%s" % [style, GLYPH.get(ch, ch)])
		t.mouse_filter = Control.MOUSE_FILTER_IGNORE
		t.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		t.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT
		t.custom_minimum_size = Vector2(h * t.texture.get_width() / t.texture.get_height(), h)
		row.add_child(t)
	return row


## Live words as the HUD sets them: Lilita One in an ink outline.
static func words(text: String, px: float, colour := Color.WHITE) -> Label:
	if _font == null:
		# One multichannel distance field for every size and outline, so all
		# the HUD's words share one glyph texture (and one batch).
		var f := FontFile.new()
		f.multichannel_signed_distance_field = true
		f.msdf_pixel_range = 40
		f.msdf_size = 64
		f.load_dynamic_font("res://ui/fonts/lilita_one/LilitaOne-Regular.ttf")
		_font = f
	var l := Label.new()
	l.text = text
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	# Over every piece of art, so the art batches in one texture and the
	# words in another rather than taking turns.
	l.z_index = TEXT_Z
	var s := LabelSettings.new()
	s.font = _font
	s.font_size = int(px)
	s.font_color = colour
	# A thick outline and no separate drop: a label's drop is a whole extra
	# pass a label (about 26 draw calls over this HUD, past §21.3's 150); the
	# baked numerals keep theirs.
	s.outline_size = int(px * 0.3)
	s.outline_color = INK
	l.label_settings = s
	return l
