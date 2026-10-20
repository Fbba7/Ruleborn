class_name StageTown
extends Node3D
## A realm's buildings at their levels and the workers at its producers
## (§23.2's realm view: "buildings, workers, pylons"): each building from the
## kit's §21.5 look for its level on the island's footprint, all of them one
## inked mesh (§21.3), and each worker a figure at its producer's door,
## working — a hop and a lean, each on its own beat (§21.1: "gentle physical
## humour"). Where a building stands is the island's; its level is the
## universe view's; who works there is the home's.

static var _toon: Shader = load("res://world/toon.gdshader")

var view: StageView
var houses: MeshInstance3D
## Each building as drawn: {kind, at, side, level, mid}, for taps and pins.
var placed: Array[Dictionary] = []
var _workers: Array[Node3D] = []
var _clock := 0.0


func _init(on: StageView) -> void:
	view = on
	name = "Town"
	houses = MeshInstance3D.new()
	houses.material_override = WorldView.material(_toon, true)
	add_child(houses)
	on.layers.add_child(self)


## Draws `buildings` ({kind, at, side, level}, as `StageRealm.buildings`
## gives them) and, for each `producers` entry {kind, workers}, a figure per
## worker by its building, in `roles` order (a worker's role, by id).
func build(buildings: Array[Dictionary], colours: Dictionary, producers: Array, roles: Dictionary) -> void:
	for w: Node3D in _workers:
		w.queue_free()
	_workers.clear()
	placed.clear()
	var g := Geo.new()
	for b: Dictionary in buildings:
		var at: Vector2i = b["at"]
		var side: int = b["side"]
		var corner := view.tile_point(at)
		var mid := corner + Vector3((side - 1) / 2.0, 0, (side - 1) / 2.0)
		BuildingKit.build(g, str(b["kind"]), mid, side, int(b["level"]), colours)
		# A doorstep of flagstones, so a building sits on the realm.
		g.box(Geo.place(mid + Vector3(0, 0.02, side * 0.5)), Vector3(0.5, 0.04, 0.3), colours["stone"])
		var shown := b.duplicate()
		shown["mid"] = mid
		placed.append(shown)
	houses.mesh = g.mesh()
	for p: Dictionary in producers:
		var home := _find(str(p["kind"]))
		if home.is_empty():
			continue
		var ids: Array = p.get("workers", [])
		for k in ids.size():
			_worker(home, k, ids.size(), str(roles.get(int(ids[k]), "")))


func _find(kind: String) -> Dictionary:
	for b: Dictionary in placed:
		if str(b["kind"]) == kind:
			return b
	return {}


## The building on tile `t`, or {}.
func at_tile(t: Vector2i) -> Dictionary:
	for b: Dictionary in placed:
		var a: Vector2i = b["at"]
		var s: int = b["side"]
		if t.x >= a.x and t.y >= a.y and t.x < a.x + s and t.y < a.y + s:
			return b
	return {}


## Worker `k` of `n` before the building's door, facing it.
func _worker(home: Dictionary, k: int, n: int, role: String) -> void:
	var side: int = home["side"]
	var mid: Vector3 = home["mid"]
	var along := (k - (n - 1) / 2.0) * 0.55
	var root := Node3D.new()
	root.position = mid + Vector3(along, 0, side * 0.5 + 0.45)
	root.rotation.y = PI - 0.45 + 0.3 * k
	var body := WorldView._instance(ActorBuilder.mesh(role if role != "" else "Carrier"),
		WorldView.material(_toon, true))
	body.name = "Body"
	body.scale = Vector3.ONE * 0.9
	root.add_child(body)
	root.set_meta("beat", float(k) * 0.9 + mid.x * 0.37)
	add_child(root)
	_workers.append(root)


func worker_count() -> int:
	return _workers.size()


func _process(delta: float) -> void:
	_clock += delta
	if Settings.reduced_motion:
		return
	for w: Node3D in _workers:
		var t: float = _clock * 2.4 + float(w.get_meta("beat"))
		var body := w.get_node("Body") as Node3D
		# A worker's hop and lean into the work, then a breath.
		var hop := maxf(0.0, sin(t * 2.0))
		body.position.y = hop * 0.08
		body.rotation.x = -0.18 * maxf(0.0, sin(t * 2.0 + 0.6))
		body.scale = Vector3.ONE * 0.9 * Vector3(1.0 + 0.04 * (1.0 - hop), 0.95 + 0.07 * hop, 1.0)
