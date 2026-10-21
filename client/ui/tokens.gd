class_name Tokens
## ui/tokens.json, read once: the one place the client's look is defined.
## A token missing from the file is a defect, and fails loudly.

const FILE := "res://ui/tokens.json"

## §20.8's high-contrast mode: `color` reads `color_high_contrast` first.
## Settings.apply sets it.
static var high_contrast := false

static var _data: Dictionary = {}
static var _gradients: Dictionary = {}
static var _fonts: Dictionary = {}


static func _all() -> Dictionary:
	if _data.is_empty():
		var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(FILE))
		assert(parsed is Dictionary, "%s is not a JSON object" % FILE)
		_data = parsed
	return _data


static func _value(group: String, name: String) -> Variant:
	var g: Dictionary = _all().get(group, {})
	assert(g.has(name), "no token %s.%s" % [group, name])
	if not g.has(name):
		push_error("no token %s.%s" % [group, name])
		return null
	return g[name]["value"]


static func color(name: String) -> Color:
	if high_contrast and (_all().get("color_high_contrast", {}) as Dictionary).has(name):
		return Color(str(_value("color_high_contrast", name)))
	return Color(str(_value("color", name)))


static func number(group: String, name: String) -> float:
	return float(_value(group, name))


static func list(group: String, name: String) -> Array:
	return _value(group, name)


## A school's shape (§21.2): "chevron", "cube", "hourglass", "bolt", "leaf" or
## "eye".
static func shape(school: String) -> String:
	var shapes: Dictionary = _all().get("shape", {})
	assert(shapes.has(school), "no shape for school %s" % school)
	return str(shapes.get(school, ""))


## The schools, in §21.2's order.
static func schools() -> Array[String]:
	var out: Array[String] = []
	for k: String in _all().get("shape", {}):
		if not k.begins_with("_"):
			out.append(k)
	return out


## A colour named by a token or written as hex ("#RRGGBBAA"), as gradients
## and materials name their colours.
static func paint(name: String) -> Color:
	return Color(name) if name.begins_with("#") else color(name)


## A gradient's stops as a Gradient, in the current contrast mode.
static func gradient(name: String) -> Gradient:
	var key := "%s:%s" % [name, high_contrast]
	if _gradients.has(key):
		return _gradients[key]
	var g := Gradient.new()
	var stops: Array = _value("gradient", name)
	var offsets := PackedFloat32Array()
	var colours := PackedColorArray()
	for stop: Array in stops:
		offsets.append(float(stop[0]))
		colours.append(paint(str(stop[1])))
	g.offsets = offsets
	g.colors = colours
	_gradients[key] = g
	return g


## How a gradient lies: "radial" [centre x, centre y, radius x, radius y] as
## fractions of the box (radii 0 for the farthest corner), "angle" in
## degrees, or "conic_from" in degrees; an empty dictionary is top to bottom.
static func gradient_shape(name: String) -> Dictionary:
	var g: Dictionary = (_all().get("gradient", {}) as Dictionary).get(name, {})
	var out := {}
	for k: String in ["radial", "angle", "conic_from"]:
		if g.has(k):
			out[k] = g[k]
	return out


## A material (tokens.json `material`) with its colours resolved: each of
## line, rim, rim_2, highlight, shade, drop, soft, glow and grain is
## [Color, points...] or absent; gloss is a strength, 0 to 1; text, text_2 and text_outline are colours;
## text_bg is the colours its words sit on. In high contrast an outline is
## 21.8's 3 points and glass is opaque.
static func material(name: String) -> Dictionary:
	var m: Dictionary = (_all().get("material", {}) as Dictionary).get(name, {})
	assert(not m.is_empty(), "no material %s" % name)
	var out := {"name": name, "fill": str(m.get("fill", "card")), "radius": float(m.get("radius", 16)),
		"gloss": float(m.get("gloss", 0.0)) if not high_contrast else 0.0,
		"family": str(m.get("family", "dark")), "over_world": bool(m.get("over_world", false))}
	for part: String in ["line", "rim", "rim_2", "highlight", "shade", "drop", "soft", "glow", "grain", "text_outline",
			"rays"]:
		var v: Variant = m.get(part)
		if v is Array:
			var a: Array = (v as Array).duplicate()
			a[0] = paint(str(a[0]))
			for i: int in range(1, a.size()):
				a[i] = float(a[i])
			out[part] = a
	if high_contrast and not name.begins_with("night") and name != "scrim":
		var line: Array = out.get("line", [paint("ink_line"), 0.0])
		out["line"] = [Color(line[0], 1.0) if line[1] > 0.0 else paint("ink_line"), number("size", "line_hc")]
		out.erase("glow")
		out.erase("rays")
	for part: String in ["text", "text_2"]:
		out[part] = paint(str(m.get(part, "text_on_night")))
	var bg: Array[Color] = []
	for c: Variant in m.get("text_bg", []):
		bg.append(paint(str(c)))
	out["text_bg"] = bg
	return out


## The materials, by name.
static func materials() -> Array[String]:
	var out: Array[String] = []
	for k: String in _all().get("material", {}):
		if not k.begins_with("_"):
			out.append(k)
	return out


## A type role (tokens.json `type`): family, weight, points, tracking,
## upper, tnum, drop and outline.
static func type_role(name: String) -> Dictionary:
	var t: Dictionary = (_all().get("type", {}) as Dictionary).get(name, {})
	assert(not t.is_empty(), "no type role %s" % name)
	return t


## The type roles, by name.
static func type_roles() -> Array[String]:
	var out: Array[String] = []
	for k: String in _all().get("type", {}):
		if not k.begins_with("_"):
			out.append(k)
	return out


## A family's font at a weight, with tabular figures if asked: Manrope's
## variable axis for "ui" (21.8: 900 is drawn at 800), the file as it is for
## the others, `spacing` pixels between letters (the designs' tracking),
## each falling back to the engine's font for anything it lacks.
static func font(family: String, weight := 400, tnum := false, spacing := 0) -> Font:
	var heaviest := int(number("font", "heaviest"))
	var key := "%s:%d:%s:%d" % [family, mini(weight, heaviest), tnum, spacing]
	if _fonts.has(key):
		return _fonts[key]
	var path := str(_value("font", family))
	var base: Font = load(path) if ResourceLoader.exists(path) else ThemeDB.fallback_font
	if base is FontFile:
		(base as FontFile).fallbacks = [ThemeDB.fallback_font]
	var f := FontVariation.new()
	f.base_font = base
	var ts := TextServerManager.get_primary_interface()
	if family == "ui":
		f.variation_opentype = {ts.name_to_tag("wght"): mini(weight, heaviest)}
	if tnum:
		f.opentype_features = {ts.name_to_tag("tnum"): 1}
	f.spacing_glyph = spacing
	_fonts[key] = f
	return f
