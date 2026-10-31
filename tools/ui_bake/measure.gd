extends RefCounted
## What guard.sh reads off a screen's last frame (report.md section 10.1):
## draw calls, the interface's texture memory (the textures its canvas items
## hold, at 4 bytes a pixel, as report.md counts an atlas; the fonts' glyph
## caches beside it), and the contrast of its words
## over the pixels drawn behind them. budget_shots.py wraps each screen's shot
## script in a few lines that call `snap` on every process_frame, connected
## before the shot's own awaits, so the last snapshot is the frame the shot
## saves, and `report` from `_finalize`, once the shot has quit. The shot
## itself is unchanged. One line on stdout, `guard-measure: {json}`.

## §21.8's floor for words, WCAG 2's ratio (ColourCheck.MIN_RATIO).
const FLOOR := 4.5
## The share of the pixels round a word's box that may sit below the floor:
## the box's edge crosses outlines, icons and anti-aliasing, so the word is
## judged at its tenth percentile, not at its single darkest pixel.
const PERCENTILE := 0.1

var _calls := 0
var _renderer_bytes := 0
var _words: Array[Dictionary] = []
var _images := {}
var _textures := {}
var _fonts := {}


## The state of this frame. Kept by reference: the textures, fonts and the
## frame's images outlive the tree, which is freed before `_finalize`.
func snap(tree: SceneTree) -> void:
	_calls = RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_DRAW_CALLS_IN_FRAME)
	_renderer_bytes = int(Performance.get_monitor(Performance.RENDER_TEXTURE_MEM_USED))
	_words = []
	_images = {}
	_textures = {}
	_fonts = {}
	var vps := {}
	for node: Node in _canvas(tree.root):
		_collect(node)
		var c := node as Control
		if c == null or not c.is_visible_in_tree():
			continue
		var text := ""
		if c is Label:
			text = (c as Label).text
		elif c is Button and not (c as Button).disabled:
			text = (c as Button).text
		if text.strip_edges() == "":
			continue
		_fonts[c.get_theme_font("font")] = true
		var word := _word(c)
		if word.is_empty():
			continue
		var vp := c.get_viewport()
		vps[vp.get_instance_id()] = vp
		word["vp"] = vp.get_instance_id()
		word["text"] = text.substr(0, 24)
		word["path"] = str(tree.root.get_path_to(c))
		_words.append(word)
	for id: int in vps:
		_images[id] = (vps[id] as Viewport).get_texture().get_image()


func report() -> void:
	var below := []
	var worst := 21.0
	var judged := 0
	for w: Dictionary in _words:
		var ratio := _ratio(w)
		if ratio < 0.0:
			continue
		judged += 1
		worst = minf(worst, ratio)
		if ratio < FLOOR:
			below.append("%s %.2f %s" % [w["path"], ratio, w["text"]])
	var bytes := 0
	var font_bytes := 0
	var sizes := []
	for t: Texture2D in _textures:
		bytes += t.get_width() * t.get_height() * 4
		sizes.append([t.get_width() * t.get_height() * 4, "%s %dx%d %s" % [t.get_class(), t.get_width(), t.get_height(), t.resource_path]])
	var files := {}
	for f: Font in _fonts:
		var file := _file(f)
		if file != null:
			files[file] = true
	for file: FontFile in files:
		var b := _font_bytes(file)
		font_bytes += b
		sizes.append([b, "glyph cache %s" % file.get_font_name()])
	sizes.sort_custom(func(a: Array, b: Array) -> bool: return a[0] > b[0])
	print("guard-measure: " + JSON.stringify({
		"draw_calls": _calls,
		"texture_bytes": bytes,
		"textures": _textures.size(),
		"font_cache_bytes": font_bytes,
		"renderer_texture_bytes": _renderer_bytes,
		"words": judged,
		"words_below": below.size(),
		"worst_ratio": snappedf(worst, 0.01),
		"below": below,
		"largest": sizes.slice(0, 6).map(func(e: Array) -> String: return "%.1f MiB %s" % [e[0] / 1048576.0, e[1]]),
	}))


## The canvas items of the tree; a 3D world's own nodes are not the interface.
static func _canvas(n: Node) -> Array[Node]:
	var out: Array[Node] = []
	if n is CanvasItem or n is Viewport or n is CanvasLayer:
		out.append(n)
	for child: Node in n.get_children():
		if child is Node3D:
			continue
		out.append_array(_canvas(child))
	return out


## Every texture a canvas item holds: its own properties, the boxes and the
## material's parameters among them.
func _collect(n: Node) -> void:
	if not n is CanvasItem:
		return
	for p: Dictionary in n.get_property_list():
		if p["type"] != TYPE_OBJECT:
			continue
		var v: Variant = n.get(p["name"])
		_hold(v)


func _hold(v: Variant) -> void:
	if v is Texture2D:
		_textures[v] = true
	elif v is StyleBoxTexture:
		_hold((v as StyleBoxTexture).texture)
	elif v is ShaderMaterial:
		var m := v as ShaderMaterial
		if m.shader != null:
			for u: Dictionary in m.shader.get_shader_uniform_list():
				_hold(m.get_shader_parameter(u["name"]))
	elif v is Font:
		_fonts[v] = true


## The font file under a variation, whose glyph caches it shares.
static func _file(f: Font) -> FontFile:
	while f is FontVariation:
		f = (f as FontVariation).base_font
	return f as FontFile


## A font file's glyph caches, as the textures the renderer keeps (in their
## own formats; Godot's are two bytes a pixel). They are the type's, not the
## art's, so they are reported beside the interface's textures, not in them.
static func _font_bytes(file: FontFile) -> int:
	var bytes := 0
	for cache: int in file.get_cache_count():
		for size: Vector2i in file.get_size_cache_list(cache):
			for i: int in file.get_texture_count(cache, size):
				var image := file.get_texture_image(cache, size, i)
				if image != null:
					bytes += image.get_data_size()
	return bytes


## One word, as it is drawn: against its ink outline where §21.8 lets the
## outline count (at least 1.5 points or 12% of its size wide), else against
## the pixels just inside the edge of its box, read from the frame later.
static func _word(c: Control) -> Dictionary:
	var ink := c.get_theme_color("font_color") * _modulate(c)
	if ink.a < 0.5:
		return {}
	var size := c.get_theme_font_size("font_size")
	var outline := c.get_theme_constant("outline_size")
	if outline > 0 and outline >= minf(UI.px(1.5), 0.12 * size):
		var o := c.get_theme_color("font_outline_color")
		if o.a >= 0.9:
			return {"ink": ink, "outline": o}
	var xf := c.get_global_transform_with_canvas()
	return {"ink": ink, "rect": Rect2(xf.origin, c.size * xf.get_scale())}


func _ratio(w: Dictionary) -> float:
	if w.has("outline"):
		return ColourCheck.ratio(w["ink"], w["outline"])
	var image: Image = _images.get(w["vp"])
	if image == null:
		return -1.0
	var r: Rect2 = (w["rect"] as Rect2).intersection(Rect2(Vector2.ZERO, image.get_size()))
	if r.size.x < 4 or r.size.y < 4:
		return -1.0
	var ink: Color = w["ink"]
	var ratios: Array[float] = []
	var x0 := int(r.position.x) + 1
	var y0 := int(r.position.y) + 1
	var x1 := int(r.end.x) - 2
	var y1 := int(r.end.y) - 2
	for x: int in range(x0, x1 + 1, 2):
		ratios.append(ColourCheck.ratio(ink, image.get_pixel(x, y0)))
		ratios.append(ColourCheck.ratio(ink, image.get_pixel(x, y1)))
	for y: int in range(y0, y1 + 1, 2):
		ratios.append(ColourCheck.ratio(ink, image.get_pixel(x0, y)))
		ratios.append(ColourCheck.ratio(ink, image.get_pixel(x1, y)))
	ratios.sort()
	return snappedf(ratios[int(ratios.size() * PERCENTILE)], 0.01)


## What a node and every canvas item above it multiply its colours by.
static func _modulate(c: CanvasItem) -> Color:
	var m := c.self_modulate
	var n: Node = c
	while n is CanvasItem:
		m *= (n as CanvasItem).modulate
		n = n.get_parent()
	return m
