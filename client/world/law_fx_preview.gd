class_name LawFxPreview
extends Control
## A live 3D preview of laws on screen, for the law card, Weaving and the
## Harmony view (§21.7: the law card's "looping four-second preview of its
## movement signature"; Weaving's "the harmonies and clashes a law would
## cause before it's woven"): a small realm drawn by the world view, the
## laws woven on it with LawFx's signatures, crowns and links, and a figure
## walking its loop in the first law's gait. It is a picture: it takes no
## taps and says nothing a screen reader must read, since the card's words
## say it all.

## The preview realm: one of each thing a signature dresses.
const PUT := {"hedge": [[1, 1], [2, 1]], "ruin_wall": [[7, 2]], "tree": [[1, 7]], "pond": [[7, 6], [7, 7]],
	"lantern_post": [[4, 1]], "static_stone": [[8, 1]], "tall_grass": [[1, 4]], "bush": [[5, 8]]}
## Where the laws are woven, in order.
const SPOTS: Array[Vector2i] = [Vector2i(4, 5), Vector2i(2, 3), Vector2i(6, 4)]

var view: WorldView
var fx: LawFx
var walker: LawFxWalker
var laws: Array = []
var realm_type := "heart"
var seconds := 0.0


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	custom_minimum_size = Vector2(0, UI.px(200))
	clip_contents = true


## Show `which` laws woven in a realm of `type`, the first walked; nothing
## changes if they are the laws already shown.
func show_laws(which: Array, type := "heart") -> void:
	if which == laws and type == realm_type and view != null:
		return
	laws = which.duplicate()
	realm_type = type
	if view != null:
		view.queue_free()
	view = WorldView.new()
	view.heist = false
	view.realm_type = type
	view.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	view.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(view)
	var replay := RulebornReplay.new()
	replay.start("5", 4500, 3, island(laws))
	# A card is a picture of the law in daylight, whatever the hour.
	view.set_sky_hour(12)
	view.show_replay(replay)
	view.set_zoom(2)
	fx = LawFx.attach(view, replay)
	# The preview runs on its own clock, not the replay's.
	fx.source = null
	var law := str(laws[0]) if not laws.is_empty() else ""
	walker = LawFxWalker.new(law, ActorBuilder.mesh("Scout"), WorldView.material(_toon(), true))
	walker.reach = 1.6
	walker.scale = Vector3.ONE * 1.4
	fx.add_child(walker)
	_tick(0.0)


## The laws a realm of the server's Weaving or Harmony view holds: its
## slots' laws (Weaving) or its laws (Harmony), and its type in the
## world's words ("Heart" is "heart").
static func realm_laws(r: Dictionary) -> Array:
	var out: Array = []
	for s: Dictionary in r.get("slots", []):
		if s.get("law") is String:
			out.append(s["law"])
	for l: Dictionary in r.get("laws", []):
		out.append(str(l["law"]))
	return out


static func realm_type_of(r: Dictionary) -> String:
	return str(r["type"]).to_lower() if r.get("type") is String else "heart"


static func _toon() -> Shader:
	return load("res://world/toon.gdshader")


## The preview's realm with `which` laws woven on it.
static func island(which: Array) -> PackedByteArray:
	var i := RulebornIsland.new()
	i.reset(1)
	for id: String in PUT:
		for xy: Array in PUT[id]:
			i.set_ground(xy[0], xy[1], id)
	for k in mini(which.size(), SPOTS.size()):
		i.weave(str(which[k]), SPOTS[k].x, SPOTS[k].y)
	return i.bytes()


func _process(delta: float) -> void:
	if fx == null or not is_visible_in_tree():
		return
	_tick(delta)


func _tick(delta: float) -> void:
	seconds += delta
	fx.sync(seconds * LawFx.TPS)
	walker.walk(seconds)
	walker.position.y = 0.0
