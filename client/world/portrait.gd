class_name Portrait
extends RefCounted
## Portraits rendered from the characters' models (§21.3: "their portraits
## are rendered from the imported models in this look"): head and
## shoulders, in the hero stage's toon light, on a clear background, so a
## card puts its own school-coloured ground behind. Each is drawn once, in
## one shared offscreen viewport, and kept; a card gets its texture at once
## and the picture fills in a frame or two later.

## The pixel size portraits are drawn at, square.
const SIZE := PortraitStudio.SIZE

static var _cache := {}
## The studio, untyped so the two scripts' statics never load each other.
static var _studio: Node = null


## The portrait of a kind in a look ("" its own, a note for a form, "guard",
## or "shadow" for its silhouette, as a locked card shows it).
static func of(kind: String, look := "") -> Texture2D:
	var key := StageHeroFigure.key(kind) + "/" + look
	if _cache.has(key):
		return _cache[key]
	var image := Image.create_empty(SIZE, SIZE, false, Image.FORMAT_RGBA8)
	var texture := ImageTexture.create_from_image(image)
	_cache[key] = texture
	if _can_draw():
		_ensure_studio()
		_studio.call("ask", StageHeroFigure.key(kind), look, texture)
	return texture


## Whether every portrait asked for has been drawn.
static func settled() -> bool:
	return _studio == null or not is_instance_valid(_studio) or bool(_studio.call("idle"))


## Forgets every portrait, as a change of contrast mode needs.
static func clear() -> void:
	_cache.clear()


static func _can_draw() -> bool:
	return DisplayServer.get_name() != "headless" and Engine.get_main_loop() is SceneTree


static func _ensure_studio() -> void:
	if _studio != null and is_instance_valid(_studio):
		return
	_studio = load("res://world/portrait_studio.gd").new()
	(Engine.get_main_loop() as SceneTree).root.add_child.call_deferred(_studio)
