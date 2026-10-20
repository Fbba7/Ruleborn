class_name StagePlan
extends Node3D
## A target's universe as the planner reads it (§12.5, §23.2: "Entry (any
## edge tile, or a fault), route"; the diorama's `plan` mode): the target's
## realm, bare as the scout knows it, every edge tile marked as a place the
## crew may land; across a universe, its outer realms hung around it on their
## bridges, each numbered as the words below name it, the faults marked in
## the alarm's colour, and the route drawn as chevrons along the crossings to
## the Heart. Only what the card says is drawn: counts, never a tile.

## The outer realms' size and how far out they hang.
const OUTER_SCALE := 0.5
const OUTER_GAP := 5.5

static var _toon: Shader = load("res://world/toon.gdshader")

var view: StageView
var marks: MeshInstance3D
var _clock := 0.0


func _init(on: StageView) -> void:
	view = on
	name = "Plan"
	marks = MeshInstance3D.new()
	marks.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	marks.material_override = WorldView.material(_toon)
	add_child(marks)
	on.layers.add_child(self)


## Draws `card`'s plan on the view, which shows its realm bare.
func build(card: Dictionary) -> void:
	for c: Node in get_children():
		if c != marks:
			c.queue_free()
	var pins := StageScreen.pins_of(view)
	pins.clear()
	var g := Geo.new()
	var size := view.grid_size()
	var faults: Array = card.get("fault_realms", [])
	if not card.get("across", false):
		# Every edge tile a landing mark: a gold ring on the ground.
		for y in size.y:
			for x in size.x:
				if x == 0 or y == 0 or x == size.x - 1 or y == size.y - 1:
					g.ring(Geo.place(view.tile_point(Vector2i(x, y), 0.05)), 0.2, 0.3, Palette.MOTION, 12)
	else:
		# Across a universe the crew lands on an outer realm's edge, or at
		# a fault, and crosses realm by realm to the Heart.
		var depth := maxi(1, int(card.get("depth", 1)))
		var spots := outer(self, view, maxi(depth, int(card.get("realms", 1)) - 1), str(card.get("bundle", "")),
			true)
		var to := Vector3.ZERO
		for i in spots.size():
			var at: Vector3 = spots[i]
			var faulted := ("outer-%d" % (i + 1)) in faults
			pins.pin(OverlaySheet.chip(str(i + 1), Palette.ALARM.lightened(0.45) if faulted else Color()),
				at + Vector3(0, 1.8, 0))
			for k in 16:
				var a := TAU * k / 16.0
				g.ring(Geo.place(at + Vector3(cos(a) * 3.0, 0.08, sin(a) * 3.0)), 0.12, 0.2, Palette.MOTION, 10)
			if faulted:
				_fault(g, at)
			_route(g, at, to)
			to = at
	pins.pin(OverlaySheet.chip(UniversePresenter.realm_name("Heart"), Palette.MOTION),
		Vector3(0, 2.4, 0))
	marks.mesh = g.mesh()


## `count` outer realms hung around the Heart behind it, each a small island
## added to `holder` with a plank bridge to the Heart; their centres.
## `tall` hangs them in a column behind the Heart, chained, for a portrait
## screen; otherwise they spread either side, for a wide picture.
static func outer(holder: Node3D, on: StageView, count: int, seed_from: String, tall := false) -> Array[Vector3]:
	var out: Array[Vector3] = []
	var g := Geo.new()
	var colours := RealmPalette.of(on.realm_type)
	var heart_r := Vector2(on.grid_size()).length() * 0.62
	var last := Vector3.ZERO
	var last_r := heart_r
	for i in count:
		var a := PI * 1.25 if count == 1 else lerpf(PI * 0.8, PI * 1.7, float(i) / (count - 1))
		var d := heart_r + OUTER_GAP
		if tall:
			a = PI * 1.25 + (0.32 if i % 2 == 0 else -0.32)
			d = heart_r + OUTER_GAP + i * (OUTER_GAP + 7.0)
		var at := Vector3(cos(a) * d, -2.2 - 0.9 * (i % 2), sin(a) * d)
		var isle := Node3D.new()
		isle.position = at
		isle.scale = Vector3.ONE * OUTER_SCALE
		holder.add_child(isle)
		on.look.island(isle, Vector2i(10, 10), hash(seed_from) + i * 977, colours)
		var toward := (last - at).normalized()
		var from := last + (at - last).normalized() * last_r * 0.95 + Vector3(0, -0.1 if i == 0 else 0.0, 0)
		if not tall:
			from = Vector3(cos(a) * heart_r * 0.95, -0.1, sin(a) * heart_r * 0.95)
			toward = Vector3(-cos(a), 0, -sin(a))
		bridge(g, from, at + toward * 3.2, colours)
		out.append(at)
		if tall:
			last = at
			last_r = 3.6
	var mi := WorldView._instance(g.mesh(), WorldView.material(_toon, true))
	if mi.mesh != null:
		holder.add_child(mi)
	return out


## A plank bridge from `a` to `b`, sagging in the middle, with posts.
static func bridge(g: Geo, a: Vector3, b: Vector3, colours: Dictionary) -> void:
	var n := 9
	var yaw := atan2(-(b - a).x, -(b - a).z)
	for k in n:
		var t := (k + 0.5) / n
		var p := a.lerp(b, t) + Vector3(0, -sin(t * PI) * 0.6, 0)
		g.box(Geo.place(p, yaw), Vector3(1.1, 0.12, 0.42), Palette.WOOD.darkened(0.1 * (k % 2)))
	for side: float in [-0.5, 0.5]:
		for k in n + 1:
			var t := float(k) / n
			var p := a.lerp(b, t) + Vector3(0, -sin(t * PI) * 0.6, 0) + Vector3(cos(yaw), 0, -sin(yaw)) * side
			g.box(Geo.place(p + Vector3(0, 0.25, 0), yaw), Vector3(0.07, 0.5, 0.07), colours["soil"])


## A fault on an outer realm: a jagged rift of light across it (§5.4).
static func _fault(g: Geo, at: Vector3) -> void:
	var glow := Color(Palette.ALARM.lightened(0.2), 0.0)
	for k in 5:
		var p := at + Vector3(-1.2 + 0.6 * k, 0.15, 0.35 * ((k % 2) * 2 - 1))
		g.box(Geo.place(p, 0.6 * ((k % 2) * 2 - 1)), Vector3(0.7, 0.1, 0.16), glow)


## The route from an outer realm to the Heart: chevrons along the crossing.
static func _route(g: Geo, from: Vector3, to: Vector3) -> void:
	var d := to - from
	var yaw := atan2(-d.x, -d.z)
	for k in 4:
		var t := 0.3 + 0.12 * k
		var p := from.lerp(to, t) + Vector3(0, 0.5 - sin(t * PI) * 0.2, 0)
		for s: float in [-1.0, 1.0]:
			var arm := Transform3D(Basis(Vector3.UP, yaw + s * 0.6), p + Vector3(cos(yaw), 0, -sin(yaw)) * s * 0.18)
			g.box(arm, Vector3(0.12, 0.08, 0.5), Color(Palette.MOTION, 0.0))


func _process(delta: float) -> void:
	_clock += delta
	if Settings.reduced_motion:
		return
	# The landing marks breathe, so the edge reads as "land here".
	marks.position.y = absf(sin(_clock * 2.0)) * 0.04
