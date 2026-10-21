class_name Icons
## The design's interface icons (tools/ui/export_icons.mjs wrote them from
## art/design/diorama/): §21.8's rounded shapes on a 24-point grid with a
## 2-point outline, the designs' three-stop volume, gloss and soft drop.
## Named "group/name" ("hud/starlight", "schools/matter", "laws/bounce"), or
## by the name alone where only one group has it. A name with no icon is a
## defect and fails loudly.

const MANIFEST := "res://ui/icons/manifest.json"

static var _paths: Dictionary = {}
static var _bare: Dictionary = {}


static func _load() -> void:
	if not _paths.is_empty():
		return
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(MANIFEST))
	assert(parsed is Dictionary, "%s is not a JSON object" % MANIFEST)
	_paths = (parsed as Dictionary).get("icons", {})
	var seen := {}
	for key: String in _paths:
		var bare := key.get_slice("/", 1)
		seen[bare] = int(seen.get(bare, 0)) + 1
		_bare[bare] = key
	for bare: String in seen:
		if int(seen[bare]) > 1:
			_bare.erase(bare)


## Whether an icon of that name exists.
static func has(name: String) -> bool:
	_load()
	return _paths.has(name) or _bare.has(name)


## The icon's texture. (Not `get`: every Object has a `get` already.)
static func texture(name: String) -> Texture2D:
	_load()
	var key: String = name if _paths.has(name) else str(_bare.get(name, ""))
	assert(key != "", "no icon %s" % name)
	if key == "":
		push_error("no icon %s" % name)
		return null
	return load(str(_paths[key]))


## Every icon's full name.
static func names() -> Array[String]:
	_load()
	var out: Array[String] = []
	out.assign(_paths.keys())
	return out


## An icon as a control `points` across, for a row or a button: scaled to
## fit, never stretched, and ignored by touch so its button gets the tap.
static func view(name: String, points := 24.0) -> TextureRect:
	var t := TextureRect.new()
	t.texture = texture(name)
	t.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	t.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	t.custom_minimum_size = Vector2.ONE * UI.px(points)
	t.mouse_filter = Control.MOUSE_FILTER_IGNORE
	t.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	t.name = "Icon"
	return t
