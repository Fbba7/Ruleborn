class_name RbBox
extends Control
## A material from ui/tokens.json drawn behind a control by ui/rb_box.gdshader:
## the kit's panels, buttons, pills and plates are all one of these. It is an
## internal child of the control it dresses, drawn behind it and grown past
## its edges by the drop, shadow and glow, so the control keeps its own size,
## children and theme. A control another script has since dressed in a fill
## of its own (a StyleBoxFlat with colour) keeps that look: the box steps
## aside.

const SHADER := preload("res://ui/rb_box.gdshader")

static var _textures: Dictionary = {}

## The material's name (tokens.json `material`).
var look := ""
## The material's resolved values (Tokens.material).
var spec: Dictionary = {}
## A corner radius in points instead of the material's.
var radius_points := -1.0
## Pixels of the host's top left undrawn, so something in it can rise above
## the box (the chosen tab over the bar).
var inset_top := 0.0:
	set(v):
		inset_top = v
		_shade()
## Not drawn while every word in the host is empty (a plate whose label has
## nothing to say yet), so no empty card stands on the screen.
var hide_empty := false
## Drawn as the chosen one of a set: a gold edge and glow, so the choice
## never rests on colour or fading alone (§20.8).
var chosen := false
## The control this box dresses.
var host: Control = null
## How far the body has sunk onto its drop: 0 at rest, 1 pressed.
var press := 0.0:
	set(v):
		press = v
		_shade()

var _reach := 0.0
var _shader := ShaderMaterial.new()


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
		host.draw.connect(queue_redraw)
	item_rect_changed.connect(queue_redraw)
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
	if chosen:
		u.set_shader_parameter("line_color", Tokens.color("card_selected_rim"))
		u.set_shader_parameter("line_w", p.call(Tokens.number("size", "line_heavy") + 0.5))
		u.set_shader_parameter("glow_color", Color(Tokens.color("card_selected_rim"), 0.45))
		u.set_shader_parameter("glow_r", p.call(10.0))
		_reach = maxf(_reach, ceilf(p.call(10.0) + 2.0))
	u.set_shader_parameter("soft_color", soft[0])
	u.set_shader_parameter("soft_y", p.call(soft[1]))
	u.set_shader_parameter("soft_blur", maxf(p.call(soft[2]), 1.0))
	u.set_shader_parameter("gloss", float(spec.get("gloss", 0.0)))
	var grain: Array = spec.get("grain", [Color(0, 0, 0, 0), 0.0])
	u.set_shader_parameter("grain_color", Color(grain[0], grain[1]))
	u.set_shader_parameter("stars", 1.0 if material_name.begins_with("night") and not Tokens.high_contrast else 0.0)
	u.set_shader_parameter("star_color", Tokens.color("night_star"))
	var rays: Array = spec.get("rays", [Color(0, 0, 0, 0), 18.0])
	u.set_shader_parameter("rays_color", rays[0])
	u.set_shader_parameter("rays_count", rays[1])
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


## Marks or unmarks the box as the chosen one of a set.
func set_chosen(on: bool) -> void:
	chosen = on
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
	var at := (-position if host != null else Vector2.ZERO) + Vector2(0, inset_top)
	var inner := (host.size if host != null else size) - Vector2(0, inset_top)
	return Rect2(at - Vector2.ONE * _reach, inner + Vector2.ONE * 2.0 * _reach)


func _shade() -> void:
	var travel: float = (spec.get("drop", [Color(), 0.0]) as Array)[1] * UI.PX_PER_POINT
	_shader.set_shader_parameter("box_size", quad().size - Vector2.ONE * 2.0 * _reach)
	_shader.set_shader_parameter("reach", _reach)
	_shader.set_shader_parameter("radius", radius_px())
	_shader.set_shader_parameter("body_y", press * travel * 0.75)
	queue_redraw()


func _draw() -> void:
	# Another script's own fill on this control wins: its look is drawn, not
	# both.
	var flat := _flat()
	if flat != null and flat.bg_color.a > 0.01:
		return
	if hide_empty and _empty():
		return
	# A disabled control is faded, box and words (its words by the theme).
	var faded := host is BaseButton and (host as BaseButton).disabled
	draw_rect(quad(), Color(1, 1, 1, 0.5 if faded else 1.0))


func _empty() -> bool:
	for c: Node in host.find_children("*", "Label", true, false):
		if (c as Label).text != "" and (c as Label).is_visible_in_tree():
			return false
	return host.find_children("*", "Button", true, false).is_empty()
