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
	var g := Geo.new()
	var colours := RealmPalette.of(view.realm_type)
	var heart_r := Vector2(view.grid_size()).length() * 0.62
	for i in outer:
		# The outer realms around the Heart: a ring behind it, each a little
		# lower, linked to it by a plank bridge.
		var a := PI * 1.25 if outer == 1 else lerpf(PI * 0.8, PI * 1.7, float(i) / (outer - 1))
		var d := heart_r + 5.5
		var at := Vector3(cos(a) * d, -2.2 - 0.9 * (i % 2), sin(a) * d)
		var holder := Node3D.new()
		holder.position = at
		holder.scale = Vector3.ONE * 0.5
		view.layers.add_child(holder)
		view.look.island(holder, Vector2i(10, 10), hash(str(card.get("bundle", ""))) + i * 977, colours)
		var from := Vector3(cos(a) * heart_r * 0.95, -0.1, sin(a) * heart_r * 0.95)
		var to := at + Vector3(-cos(a), 0, -sin(a)) * 3.2
		_bridge(g, from, to, colours)
	view.fill = 1.1 if outer == 0 else 1.6
	view.look_up = 0.0 if outer == 0 else heart_r * 0.12
	if outer > 0:
		var mi := WorldView._instance(g.mesh(), WorldView.material(load("res://world/toon.gdshader") as Shader, true))
		view.layers.add_child(mi)


## A plank bridge from `a` to `b`, sagging in the middle.
static func _bridge(g: Geo, a: Vector3, b: Vector3, colours: Dictionary) -> void:
	var n := 9
	var yaw := atan2(-(b - a).x, -(b - a).z)
	for k in n:
		var t := (k + 0.5) / n
		var p := a.lerp(b, t) + Vector3(0, -sin(t * PI) * 0.6, 0)
		g.box(Geo.place(p, yaw), Vector3(1.1, 0.12, 0.42), Palette.WOOD.darkened(0.1 * (k % 2)))
	for side: float in [-0.45, 0.45]:
		for k in n + 1:
			var t := float(k) / n
			var p := a.lerp(b, t) + Vector3(0, -sin(t * PI) * 0.6, 0) + Vector3(cos(yaw), 0, -sin(yaw)) * side
			g.box(Geo.place(p + Vector3(0, 0.25, 0), yaw), Vector3(0.06, 0.5, 0.06), colours["soil"])
