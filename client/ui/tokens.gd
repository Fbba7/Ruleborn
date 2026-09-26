class_name Tokens
## ui/tokens.json, read once: the one place the client's look is defined.
## A token missing from the file is a defect, and fails loudly.

const FILE := "res://ui/tokens.json"

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
	return Color(str(_value("color", name)))


static func number(group: String, name: String) -> float:
	return float(_value(group, name))
