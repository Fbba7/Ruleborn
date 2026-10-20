class_name StageThumbs
extends Control
## Each Observatory card's universe as a picture (the design's `obs` stills:
## a target's islands hanging in its sky), from one shared offscreen world:
## a single `StageView` draws each card's universe in turn and its frame is
## copied to a texture, so a list of six cards costs one 3D viewport, never
## six (§21.3). What is drawn is only what a card says (§12.3: "the free
## scouting facts"): the Heart at its realm level, bare, and the card's
## other realms as smaller islands around it, linked; nothing placed.

signal drawn(key: String, texture: Texture2D)

## The picture's size in pixels.
const SIZE := Vector2i(780, 330)
## The hour the pictures are lit at: the Observatory looks out at dusk.
const DUSK := 19

var view: StageView
var _queue: Array[Dictionary] = []
var _busy := false
var _done := {}


func _init() -> void:
	name = "Thumbs"
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	# Offscreen: drawn every frame while there is work, never shown.
	position = Vector2(-SIZE.x * 4, 0)
	size = Vector2(SIZE)
	view = StageView.new()
	view.size = Vector2(SIZE)
	view.pitch = 42.0
	view.fill = 2.1
	add_child(view)
	# Seen through the Observatory's glass, a universe hangs in its dusk.
	view.set_sky_hour(DUSK)
	# The view's world drawn by its own viewport, out of its container, so
	# it draws while nothing on screen shows it.
	view.container.stretch = false
	view.container.remove_child(view.viewport)
	add_child(view.viewport)
	view.viewport.size = SIZE
	view.viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	view.visible = false


## The picture of `card`'s universe, from the cache, or null while it is
## being drawn; `drawn` is emitted when it is.
func picture(card: Dictionary) -> Texture2D:
	var key := key_of(card)
	if _done.has(key):
		return _done[key]
	if not _queue.any(func(q: Dictionary) -> bool: return key_of(q) == key):
		_queue.append(card)
	if not _busy:
		_busy = true
		_next.call_deferred()
	return null


static func key_of(card: Dictionary) -> String:
	return "%s|%d" % [card.get("bundle", ""), hash(card.get("realm", {}))]


func _next() -> void:
	if _queue.is_empty() or not is_inside_tree():
		_busy = false
		return
	_busy = true
	var card: Dictionary = _queue.pop_front()
	stage(card)
	for i in 3:
		await get_tree().process_frame
	if not is_inside_tree():
		return
	var image := view.viewport.get_texture().get_image() if WorldView.rendering_3d() else null
	var texture: Texture2D = ImageTexture.create_from_image(image) if image != null and not image.is_empty() \
		else null
	_done[key_of(card)] = texture
	drawn.emit(key_of(card), texture)
	_next()


## Draws `card`'s universe on the shared view.
func stage(card: Dictionary) -> void:
	var realm: Dictionary = card.get("realm", {})
	var replay := StageRealm.replay_of(StageRealm.blank(int(realm.get("realm_level", 1))))
	if replay == null:
		return
	view.realm_type = StageRealm.realm_type(str(realm.get("type", "Heart")))
	view.show_replay(replay)
	view.show_vault(false)
	for c: Node in view.layers.get_children():
		c.queue_free()
	var outer := maxi(0, int(card.get("realms", 1)) - 1)
	var heart_r := Vector2(view.grid_size()).length() * 0.62
	StagePlan.outer(view.layers, view, outer, str(card.get("bundle", "")))
	view.fill = 1.1 if outer == 0 else 1.6
	view.look_up = 0.0 if outer == 0 else heart_r * 0.12
