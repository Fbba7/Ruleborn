class_name RbBox
extends Control
## A material from ui/tokens.json drawn behind a control by ui/rb_box.gdshader:
## the kit's panels, buttons, pills and plates are all one of these. It is an
## internal child of the control it dresses, drawn behind it and grown past
## its edges by the drop, shadow and glow, so the control keeps its own size,
## children and theme. A control another script has since dressed in a fill
## of its own (a StyleBoxFlat with colour) keeps that look: the box steps
## aside. A material whose skin is switched on in ui/kit_families.json is
## drawn from the kit's atlas instead (KitSkin), by a face of its own inside
## the box, and the shader draws only where the atlas lacks the piece.

const SHADER := preload("res://ui/rb_box.gdshader")

static var _textures: Dictionary = {}

## The material's name (tokens.json `material`).
var look := ""
## The material's resolved values (Tokens.material).
var spec: Dictionary = {}
## A corner radius in points instead of the material's.
var radius_points := -1.0
## The two lower corners' radius in points, when not negative: a band that
## sits square on the panel under it (the Codex's chapter over its album).
var foot_points := -1.0:
	set(v):
		foot_points = v
		_shade()
## Pixels of the host's top left undrawn, so something in it can rise above
## the box (the chosen tab over the bar).
var inset_top := 0.0:
	set(v):
		inset_top = v
		_shade()
## Pixels the box runs past the host's left, right and foot: a bar flush
## to the screen's edges shows only its top edge, its corners off the screen.
var bleed := 0.0:
	set(v):
		bleed = v
		_shade()
## Pixels the box is drawn inside the host on every side: a disc smaller
## than its 48-point hit area (§21.1), the hit area unchanged.
var inset := 0.0:
	set(v):
		inset = v
		_shade()
## Not drawn while every word in the host is empty (a plate whose label has
## nothing to say yet), so no empty card stands on the screen.
var hide_empty := false
## Drawn as the chosen one of a set: a gold edge and glow, so the choice
## never rests on colour or fading alone (§20.8).
var chosen := false
## The control this box dresses.
var host: Control = null
## The skin's shape drawn in place of the material's own when the atlas
## draws the box (a bar's `alarm` fill); "" for the material's.
var skin_shape := "":
	set(v):
		skin_shape = v
		_redraw()
## Whether only a press held down is the host's pressed state: a switch says
## that it is on by its shape (`toggle/track_on`), not by its pressed face.
var held_only := false
## How far the body has sunk onto its drop: 0 at rest, 1 pressed.
var press := 0.0:
	set(v):
		press = v
		_shade()

var _reach := 0.0
var _line_px := 0.0
var _shader := ShaderMaterial.new()
var _face: Control = null
var _faces: Dictionary = {}
## The colour a neutral piece is tinted by when the use has refilled the box
## (`tint`), else null: the material's own fill tints it.
var _tint: Variant = null


## Dresses `control` in `look`, behind its own drawing and children, and
## marks it with the colours its words sit on (`text_bg`) for the contrast
## checks. A second call changes the material.
static func dress(control: Control, material_name: String, radius := -1.0) -> RbBox:
	var box := of(control)
	if box == null:
		box = RbBox.new()
		box.name = "RbBox"
		box.host = control
		control.add_child(box, false, Node.INTERNAL_MODE_FRONT)
	box.radius_points = radius
	box.set_look(material_name)
	return box


## The box dressing `control`, or null.
static func of(control: Control) -> RbBox:
	for c: Node in control.get_children(true):
		if c is RbBox:
			return c
	return null


## A gradient token as a texture the shader samples, made once per contrast
## mode.
static func texture(gradient: String) -> GradientTexture1D:
	var key := "%s:%s" % [gradient, Tokens.high_contrast]
	if not _textures.has(key):
		var t := GradientTexture1D.new()
		t.gradient = Tokens.gradient(gradient)
		t.width = 256
		_textures[key] = t
	return _textures[key]


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	show_behind_parent = true
	focus_mode = Control.FOCUS_NONE
	material = _shader
	_shader.shader = SHADER


func _ready() -> void:
	# A container lays its internal children out too, so the box draws from
	# its host's rect, wherever the container has put the box itself.
	if host != null:
		host.resized.connect(_shade)
		# The host redraws when its state changes (pressed, disabled), and
		# the box follows it.
		host.draw.connect(_redraw)
	item_rect_changed.connect(_redraw)
	_shade()


func _get_minimum_size() -> Vector2:
	return Vector2.ZERO


## Switches the material, as a chip turns on or a card is chosen.
func set_look(material_name: String) -> void:
	look = material_name
	spec = Tokens.material(material_name)
	if host != null:
		host.set_meta("rb_material", material_name)
		host.set_meta("text_bg", spec["text_bg"])
		host.set_meta("rb_family", spec["family"])
	var p := func(points: float) -> float: return points * UI.PX_PER_POINT
	var drop: Array = spec.get("drop", [Color(0, 0, 0, 0), 0.0])
	var soft: Array = spec.get("soft", [Color(0, 0, 0, 0), 0.0, 0.0])
	var glow: Array = spec.get("glow", [Color(0, 0, 0, 0), 0.0])
	_reach = ceilf(maxf(p.call(drop[1]) + absf(p.call(soft[1])) + p.call(soft[2]), p.call(glow[1])) + 2.0)
	var shape := Tokens.gradient_shape(str(spec["fill"]))
	var u := _shader
	u.set_shader_parameter("fill_tex", texture(str(spec["fill"])))
	u.set_shader_parameter("fill_mode", 1 if shape.has("radial") else (2 if shape.has("conic_from") else 0))
	u.set_shader_parameter("fill_angle", float(shape.get("angle", shape.get("conic_from", 180.0))))
	var radial: Array = shape.get("radial", [0.5, 0.5, 0.0, 0.0])
	u.set_shader_parameter("fill_geo", Vector4(radial[0], radial[1], radial[2], radial[3]))
	for part: Array in [["line", "line_color", "line_w"], ["rim", "rim_color", "rim_w"],
			["rim_2", "rim2_color", "rim2_w"], ["highlight", "hi_color", "hi_w"], ["shade", "shade_color", "shade_w"],
			["drop", "drop_color", "drop_y"], ["glow", "glow_color", "glow_r"]]:
		var v: Array = spec.get(part[0], [Color(0, 0, 0, 0), 0.0])
		u.set_shader_parameter(part[1], v[0])
		u.set_shader_parameter(part[2], maxf(p.call(v[1]), 0.0 if part[0] != "glow" else 1.0))
	if chosen and KitSkin.part("rim").is_empty():
		u.set_shader_parameter("line_color", Tokens.color("card_selected_rim"))
		u.set_shader_parameter("line_w", p.call(Tokens.number("size", "line_heavy") + 0.5))
		u.set_shader_parameter("glow_color", Color(Tokens.color("card_selected_rim"), 0.45))
		u.set_shader_parameter("glow_r", p.call(10.0))
		_reach = maxf(_reach, ceilf(p.call(10.0) + 2.0))
	_line_px = float(u.get_shader_parameter("line_w"))
	u.set_shader_parameter("soft_color", soft[0])
	u.set_shader_parameter("soft_y", p.call(soft[1]))
	u.set_shader_parameter("soft_blur", maxf(p.call(soft[2]), 1.0))
	u.set_shader_parameter("gloss", float(spec.get("gloss", 0.0)))
	var grain: Array = spec.get("grain", [Color(0, 0, 0, 0), 0.0])
	u.set_shader_parameter("grain_color", Color(grain[0], grain[1]))
	u.set_shader_parameter("stars", 1.0 if material_name.begins_with("night") and not Tokens.high_contrast else 0.0)
	u.set_shader_parameter("star_color", Tokens.color("night_star"))
	var stripes: Array = spec.get("stripes", [Color(0, 0, 0, 0)])
	u.set_shader_parameter("stripes_color", stripes[0])
	var rays: Array = spec.get("rays", [Color(0, 0, 0, 0), 18.0])
	u.set_shader_parameter("rays_color", rays[0])
	u.set_shader_parameter("rays_count", rays[1])
	if KitSkin.is_on(KitSkin.skin(material_name)) or _rimmed(material_name):
		_make_face()
	_shade()


## Refills the box top to bottom from `top` to `bottom` (a bar in a
## resource's colour), keeping the rest of its material.
func tint(top: Color, bottom: Color) -> void:
	var key := "tint:%s:%s" % [top.to_html(), bottom.to_html()]
	if not _textures.has(key):
		var g := Gradient.new()
		g.set_color(0, top)
		g.set_color(1, bottom)
		var t := GradientTexture1D.new()
		t.gradient = g
		t.width = 64
		_textures[key] = t
	_shader.set_shader_parameter("fill_tex", _textures[key])
	_shader.set_shader_parameter("fill_mode", 0)
	_shader.set_shader_parameter("fill_angle", 180.0)
	_tint = top.lerp(bottom, 0.5)
	_redraw()


## Whether the selected rim is drawn over this box in `material_name`.
func _rimmed(material_name: String) -> bool:
	return (chosen or material_name == "card_selected") and KitSkin.is_on("selected")


## The face from the atlas, in front of the box and behind the host's own
## children; made once, when a skin or the rim first draws on it.
func _make_face() -> void:
	if _face != null:
		return
	_face = Control.new()
	_face.name = "KitFace"
	_face.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_face.focus_mode = Control.FOCUS_NONE
	_face.draw.connect(_draw_face)
	add_child(_face, false, Node.INTERNAL_MODE_FRONT)


## Marks or unmarks the box as the chosen one of a set.
func set_chosen(on: bool) -> void:
	chosen = on
	if _rimmed(look):
		_make_face()
	set_look(look)


## The material's corner, in pixels: the control's own flat box's radius
## when a script has rounded it, else the material's.
func radius_px() -> float:
	var points := radius_points if radius_points >= 0.0 else float(spec.get("radius", 16.0))
	var flat := _flat()
	if flat != null and flat.corner_radius_top_left > 0:
		return float(flat.corner_radius_top_left)
	return points * UI.PX_PER_POINT


func _flat() -> StyleBoxFlat:
	if host is PanelContainer:
		return host.get_theme_stylebox("panel") as StyleBoxFlat
	if host is Button:
		var b := host as Button
		var state := "disabled" if b.disabled else ("pressed" if b.button_pressed or press > 0.5 else "normal")
		return b.get_theme_stylebox(state) as StyleBoxFlat
	return null


## The host's rect in the box's own space, grown by the reach.
func quad() -> Rect2:
	var at := (-position if host != null else Vector2.ZERO) + Vector2(-bleed + inset, inset_top + inset)
	var inner := (host.size if host != null else size) - Vector2(-2.0 * bleed + 2.0 * inset,
		inset_top - bleed + 2.0 * inset)
	return Rect2(at - Vector2.ONE * _reach, inner + Vector2.ONE * 2.0 * _reach)


func _shade() -> void:
	var travel: float = (spec.get("drop", [Color(), 0.0]) as Array)[1] * UI.PX_PER_POINT
	var box := quad().size - Vector2.ONE * 2.0 * _reach
	_shader.set_shader_parameter("box_size", box)
	# An outline is never more than a fifth of the box's smaller side, so
	# high contrast's 3 points still leave a thin bar its fill.
	if box.x > 0.0 and box.y > 0.0:
		_shader.set_shader_parameter("line_w", minf(_line_px, maxf(1.0, minf(box.x, box.y) * 0.2)))
	_shader.set_shader_parameter("reach", _reach)
	_shader.set_shader_parameter("radius", radius_px())
	_shader.set_shader_parameter("radius_foot", foot_points * UI.PX_PER_POINT if foot_points >= 0.0 else -1.0)
	_shader.set_shader_parameter("body_y", press * travel * 0.75)
	_redraw()


## The atlas piece the box is drawn from in the host's state and on the
## ground under it, or empty while the code-drawn box draws it (its skin
## off, or the piece missing). A box refilled by its use (`tint`) draws only
## a piece baked to be tinted: an untinted one would lose the use's colour,
## which its words are set against, so the code-drawn box keeps it. A shape
## the use itself names (`skin_shape`, a bar's alarm fill) is the use's
## colour already, and is drawn.
func piece() -> Dictionary:
	if _face == null:
		return {}
	var ground := KitSkin.ground_of(host)
	var p := KitSkin.piece(look, _state(), ground, skin_shape)
	if _tint is Color and not bool(p.get("tint", false)):
		if skin_shape == "" or p == KitSkin.piece(look, _state(), ground):
			return {}
	return p


## The selected rim drawn over the box from the atlas (kit-spec.md section
## 5's overlay), while the box is the chosen one of a set or its material is
## the selected card's; empty while the `selected` skin is off, and the
## chosen one's edge is then the code-drawn box's.
func rim() -> Dictionary:
	if _face == null or not (chosen or look == "card_selected"):
		return {}
	return KitSkin.part("rim")


func _state() -> String:
	if host is Button:
		var b := host as Button
		var down := press > 0.5 or (b.button_pressed and not held_only)
		return "disabled" if b.disabled else ("pressed" if down else "normal")
	return "normal"


func _redraw() -> void:
	queue_redraw()
	if _face != null:
		_face.queue_redraw()


## Whether the box draws at all: another script's own fill on this control
## wins, and a box hidden while empty is not drawn.
func _shown() -> bool:
	var flat := _flat()
	if flat != null and flat.bg_color.a > 0.01:
		return false
	return not (hide_empty and _empty())


## The face from the atlas: a 9-slice stretched over the host, or a sprite,
## drawn at the kit's scale. A neutral piece is tinted by the use's colour
## (`tint`) or its material's fill, under its skin's untinted frame at the
## same rect; the selected rim is drawn over them.
func _draw_face() -> void:
	if not _shown():
		return
	var p := piece()
	if not p.is_empty():
		var hue := Color.WHITE
		if bool(p.get("tint", false)):
			hue = _tint if _tint is Color else Tokens.gradient(str(spec["fill"])).sample(0.5)
			_draw_piece(p, hue)
			var frame := KitSkin.frame(look, _state())
			if not frame.is_empty():
				_draw_piece(frame, Color.WHITE)
		else:
			_draw_piece(p, hue)
	for over: Dictionary in [KitSkin.frame_ring(look), rim()]:
		if not over.is_empty():
			_draw_piece(over, Color.WHITE)


## Draws piece `p` so that its face covers the host. A piece carries its
## ink line's margin (`KitSkin.MARGIN_POINTS`) around its face and its lip
## below it (kit-spec.md section 6.4), and those fall outside the host, as
## the code-drawn box's outline and drop do; a skin with a wider margin
## names it (`KitSkin.margins`). A 9-slice whose margins are
## larger than the host is drawn smaller, whole; a sprite keeps its shape,
## as wide as the host, from its top.
func _draw_piece(p: Dictionary, hue: Color) -> void:
	var tex := KitSkin.texture(p)
	var s := KitSkin.scale()
	var r := quad().grow(-_reach)
	var region := KitSkin.region(p)
	var edge := KitSkin.MARGIN_POINTS * float(KitSkin.px_per_point())
	var slice: Variant = p.get("slice")
	if slice is Dictionary:
		var out := KitSkin.margins(p)
		var beside := float(out[0]) + float(out[2])
		var above := float(out[1]) + float(out[3])
		var across := float(slice["l"]) + float(slice["r"])
		var down := float(slice["t"]) + float(slice["b"])
		var fit := minf(1.0, minf((r.size.x / s + beside) / across, (r.size.y / s + above) / down))
		s *= fit
		var at := Rect2(-Vector2(float(out[0]), float(out[1])), r.size / s + Vector2(beside, above))
		_face.draw_set_transform(r.position, 0.0, Vector2(s, s))
		var key := "%s:%s:%s" % [region, tex.get_instance_id(), hue.to_html()]
		if not _faces.has(key):
			var sb := StyleBoxTexture.new()
			sb.texture = tex
			sb.region_rect = region
			sb.modulate_color = hue
			sb.texture_margin_left = float(slice["l"])
			sb.texture_margin_top = float(slice["t"])
			sb.texture_margin_right = float(slice["r"])
			sb.texture_margin_bottom = float(slice["b"])
			_faces[key] = sb
		_face.draw_style_box(_faces[key], at)
	else:
		var k := r.size.x / maxf(1.0, region.size.x - 2.0 * edge)
		_face.draw_set_transform(r.position - Vector2.ONE * edge * k, 0.0, Vector2(k, k))
		_face.draw_texture_rect_region(tex, Rect2(Vector2.ZERO, region.size), region, hue)
	_face.draw_set_transform(Vector2.ZERO)


func _draw() -> void:
	# Another script's own fill on this control wins: its look is drawn, not
	# both; and a face from the atlas is drawn by the face.
	if not _shown() or not piece().is_empty():
		return
	# A disabled control is faded, box and words (its words by the theme).
	var faded := host is BaseButton and (host as BaseButton).disabled
	draw_rect(quad(), Color(1, 1, 1, 0.5 if faded else 1.0))


func _empty() -> bool:
	for c: Node in host.find_children("*", "Label", true, false):
		if (c as Label).text != "" and (c as Label).is_visible_in_tree():
			return false
	return host.find_children("*", "Button", true, false).is_empty()
