class_name UniverseCrowd
extends RefCounted
## The player's own characters on the realm the map is closed in on (§23.2:
## the home "alive"; §14.1's work): each a T1 sculpt (`CreatureModel`), at
## the building it works, asleep where it rests, or strolling the plaza
## when it has nothing to do — as the home view (`RosterState`) says. Only a
## close-up shows them, and only a few, as each is a whole character's
## triangles (§21.3).

## How many characters a close-up shows.
const MOST := 2
## The map draws its figures larger than life, as the design's diorama does
## (its characters at 1.9 to 2.3 times, realm_diorama.js :611), so they read
## beside buildings drawn three tiles across.
const MAP_SCALE := 2.1
## What each of §14.1's states plays.
const CLIP := {"working": &"work", "guarding": &"idle2", "resting": &"nap", "idle": &"walk"}

var parent: Node3D
var _shown := ""
var _walkers: Array[Dictionary] = []


func _init(into: Node3D) -> void:
	parent = into


## The characters of `characters` (the home view's) who are in realm `id`
## on island `isl`; none when `id` is "". Built again only when the realm
## changes.
func show(id: String, isl: UniverseIsland, characters: Array) -> void:
	if id == _shown:
		return
	_shown = id
	for c in parent.get_children():
		c.queue_free()
	_walkers.clear()
	if id == "" or isl == null:
		return
	var n := 0
	for ch: Dictionary in characters:
		if n >= MOST:
			break
		if realm_of(ch) != id:
			continue
		var model := CreatureModel.make(StringName(str(ch.get("kind", ""))))
		if model == null:
			continue
		parent.add_child(model)
		model.scale = Vector3.ONE * MAP_SCALE
		var state := str(ch.get("state", "idle"))
		var at := _spot(isl, ch, n)
		model.place(at, isl.at - at)
		model.play(CLIP.get(state, &"idle"))
		if state == "idle":
			_walkers.append({"model": model, "centre": isl.at, "r": Vector2(at.x - isl.at.x, at.z - isl.at.z).length(),
				"a": atan2(at.z - isl.at.z, at.x - isl.at.x), "y": at.y})
		n += 1


## Where a character is: the realm it works in, else its home ("spire", the
## Spire's rooms, is the Heart).
static func realm_of(ch: Dictionary) -> String:
	var work: Variant = ch.get("work")
	if work is Dictionary and str(ch.get("state", "")) in ["working", "guarding", "resting"]:
		return str((work as Dictionary).get("realm", ""))
	var home := str(ch.get("home", ""))
	return "heart" if home == "spire" else home


## In front of the building it works (on its outer side), else on the
## plaza's edge.
func _spot(isl: UniverseIsland, ch: Dictionary, n: int) -> Vector3:
	var work: Variant = ch.get("work")
	if work is Dictionary:
		var key := "%s:%d" % [str((work as Dictionary).get("kind", "")), int((work as Dictionary).get("n", 1))]
		if isl.places.has(key):
			var top: Vector3 = isl.places[key]
			var out := Vector3(top.x - isl.at.x, 0, top.z - isl.at.z).normalized()
			var p := top + out * 2.0
			var f := Vector2(p.x - isl.at.x, p.z - isl.at.z).length() / isl.radius
			return Vector3(p.x, isl.at.y + UniverseIsland.dome(f), p.z)
	var r := (8.4 if isl.key == "heart" else 3.0)
	var a := PI / 2.0 - 0.5 + n * 0.9
	return isl.at + Vector3(cos(a) * r, UniverseIsland.dome(r / isl.radius), sin(a) * r)


## The strollers a step round the plaza at `now` seconds.
func step(now: float) -> void:
	for w: Dictionary in _walkers:
		var model: CreatureModel = w["model"]
		if not is_instance_valid(model):
			continue
		var a := float(w["a"]) + now * 0.9 / maxf(1.0, float(w["r"]))
		var c: Vector3 = w["centre"]
		var p := c + Vector3(cos(a) * float(w["r"]), 0, sin(a) * float(w["r"]))
		p.y = float(w["y"])
		model.place(p, Vector3(-sin(a), 0, cos(a)))
