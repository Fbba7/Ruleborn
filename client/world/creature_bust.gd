class_name CreatureBust
extends RefCounted
## Head-and-shoulders busts of the characters for the heist's crew row and
## its Sage disc (02-heist.png: each face fills its disc), rendered from the
## models in the hero light and cut round, so a caller draws one straight on
## its disc. Each is drawn once, in one offscreen viewport, and kept; the
## texture comes at once and the picture fills in a frame or two later.

## The pixel size busts are drawn at, square.
const SIZE := 192
## The looks a bust takes: its own, a form, or the guard form.
const LOOKS := ["", "hush", "spark", "echo", "guard"]

static var _cache := {}
## The studio, untyped so the two scripts' statics never load each other.
static var _studio: Node = null


## The bust of `kind` ("glass_golem" or "glassgolem") in `form` ("" its own,
## "hush", "spark", "echo" or "guard"): a round picture, clear outside its
## circle; on a lit disc of `ground` (the role's or school's colour, lighter
## at the middle as 02-heist.png's are) when one is given, else clear behind.
## Blank where nothing can draw (a headless run) or for a kind the export
## lacks.
static func of(kind: String, form := "", ground := Color(0, 0, 0, 0)) -> Texture2D:
	var exported := StageHeroFigure.key(kind).replace("_", "")
	var look := form if form in LOOKS else ""
	var key := "%s/%s/%s" % [exported, look, ground.to_html()]
	if _cache.has(key):
		return _cache[key]
	var texture := ImageTexture.create_from_image(Image.create_empty(SIZE, SIZE, false, Image.FORMAT_RGBA8))
	_cache[key] = texture
	if _can_draw() and CreatureModel.manifest().has(exported):
		_ensure_studio()
		_studio.call("ask", exported, look, ground, texture)
	return texture


## Whether a bust's picture has been drawn into its texture yet.
static func drawn(texture: Texture2D) -> bool:
	return texture != null and texture.get_image() != null and not texture.get_image().is_invisible()


## Whether every bust asked for has been drawn.
static func settled() -> bool:
	return _studio == null or not is_instance_valid(_studio) or bool(_studio.call("idle"))


## Forgets every bust, as a change of contrast mode needs.
static func clear() -> void:
	_cache.clear()


static func _can_draw() -> bool:
	return DisplayServer.get_name() != "headless" and Engine.get_main_loop() is SceneTree


static func _ensure_studio() -> void:
	if _studio != null and is_instance_valid(_studio):
		return
	_studio = load("res://world/creature_bust_studio.gd").new()
	(Engine.get_main_loop() as SceneTree).root.add_child.call_deferred(_studio)
