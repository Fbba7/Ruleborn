class_name Tokens
## ui/tokens.json, read once: the one place the client's look is defined.
## A token missing from the file is a defect, and fails loudly.

const FILE := "res://ui/tokens.json"

## §20.8's high-contrast mode: `color` reads `color_high_contrast` first.
## Settings.apply sets it.
static var high_contrast := false

static var _data: Dictionary = {}


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
