class_name UniverseFlight
extends RefCounted
## What moves over the universe map: the skiffs flying the links with their
## glowing wakes (the design's `makeSkiff` and `skiffs`, realm_diorama.js
## :1196–1223), the light running through each rift, two comets crossing the
## deep sky, and the debris drifting round every island (:1157). Built once
## a universe (`UniverseView` keeps one) and moved each frame by the time
## the map has run.

## The skiffs flying the links, and the glows in each one's wake.
const SKIFFS := 4
const WAKE := 12

## Triangles of what flies, for the map's budget.
var triangles := 0
var time := 0.0

var parent: Node3D
var islands := {}
var view_data := {}
var bounds := AABB()
var _skiffs: Array[Dictionary] = []
var _streams: Array[Dictionary] = []
var _sparks: MultiMeshInstance3D
var _comets: Array[Dictionary] = []
var _debris: MultiMeshInstance3D
var _orbits: Array[Dictionary] = []


## Everything that flies over `realms` (id → UniverseIsland), added to
## `into`; `streams` are the open rifts' paths and colours.
func _init(into: Node3D, realms: Dictionary, universe: Dictionary, box: AABB, streams: Array[Dictionary]) -> void:
	parent = into
	islands = realms
	view_data = universe
	bounds = box
	_streams = streams
	_skiffs_build()
	_sparks_build()
	_debris_build()


## The skiffs: one over each of the first links, back and forth; with no
## links, circling the universe.
func _skiffs_build() -> void:
	var named: Array = view_data.get("links", [])
	for i in SKIFFS:
		var route := {}
		if i < named.size():
			var l: Dictionary = named[i]
			if islands.has(str(l["a"])) and islands.has(str(l["b"])):
				var ia: UniverseIsland = islands[str(l["a"])]
				var ib: UniverseIsland = islands[str(l["b"])]
				route = {"a": ia.at, "b": ib.at, "school": ib.school}
		if route.is_empty() and i >= 2:
			continue
		var school: Color = route.get("school", Palette.SPIRIT)
		var mi := MeshInstance3D.new()
		mi.mesh = SkiffBuilder.mesh(school)
		mi.material_override = UniverseView._material(true)
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		mi.scale = Vector3.ONE * 1.1
		parent.add_child(mi)
		triangles += (mi.mesh as ArrayMesh).surface_get_array_len(0) / 3 if mi.mesh != null else 0
		_skiffs.append({"node": mi, "route": route, "phase": i * 0.37, "speed": 0.06 + 0.015 * i,
			"wake": [] as Array[Vector3], "colour": school})


## Rocks drifting round each island, a few with a tree on top (the design's
## debris, :1157), one layer of instances for the universe, moved each frame.
func _debris_build() -> void:
	_orbits.clear()
	var g := Geo.new()
	g.prism(Transform3D(Basis(Vector3.RIGHT, PI), Vector3.ZERO), 6, 1.0, 0.0, 1.8, Color("#7E6E9A"))
	g.prism(Geo.place(Vector3(0, -0.02, 0)), 6, 1.05, 1.0, 0.3, Color("#6E9A55"))
	g.prism(Geo.place(Vector3(0.2, 0.28, 0.1)), 5, 0.38, 0.0, 0.9, Color("#3E8A45"))
	for id: String in islands:
		var isl: UniverseIsland = islands[id]
		if isl.ghost:
			continue
		for k in 2:
			_orbits.append({"centre": isl.at, "r": isl.radius * (1.18 + 0.25 * isl.noise(900 + k)),
				"y": -2.0 - 5.0 * isl.noise(910 + k), "a": isl.noise(920 + k) * TAU,
				"speed": (0.05 + 0.06 * isl.noise(930 + k)) * (1.0 if k % 2 else -1.0),
				"size": 0.55 + 0.7 * isl.noise(940 + k), "tint": Color.WHITE if isl.key != "emberreach"
					else Color("#8A6A70")})
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = true
	mm.mesh = g.mesh()
	mm.instance_count = _orbits.size()
	for i in _orbits.size():
		mm.set_instance_color(i, _orbits[i]["tint"])
	_debris = MultiMeshInstance3D.new()
	_debris.multimesh = mm
	_debris.material_override = UniverseView._material()
	_debris.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_debris.extra_cull_margin = 400.0
	parent.add_child(_debris)
	triangles += _orbits.size() * g.triangles
	drift(time)


## Rocks round their islands at `now` seconds.
func drift(now: float) -> void:
	time = 0.0 if Settings.reduced_motion else now
	if _debris == null:
		return
	var mm := _debris.multimesh
	for i in _orbits.size():
		var o: Dictionary = _orbits[i]
		var a := float(o["a"]) + time * float(o["speed"])
		var c: Vector3 = o["centre"]
		var p := c + Vector3(cos(a) * float(o["r"]), float(o["y"]) + sin(time * 0.7 + a) * 0.5, sin(a) * float(o["r"]))
		mm.set_instance_transform(i, Transform3D(Basis(Vector3.UP, a * 2.0).scaled(Vector3.ONE * float(o["size"])), p))


## One layer of moving lights — skiffs' wakes, rifts' streams, comets — as
## one draw call, placed each frame.
func _sparks_build() -> void:
	var quad := UniversePaint.new()
	quad.glow(Vector3.ZERO, 1.0, Color.WHITE)
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = true
	mm.mesh = quad.mesh()
	var n := _skiffs.size() * WAKE + 2 * 14 + 3
	for st: Dictionary in _streams:
		n += int(st.get("lights", 10))
	mm.instance_count = n
	_sparks = MultiMeshInstance3D.new()
	_sparks.multimesh = mm
	_sparks.material_override = UniverseView._glow_material(0.0, 0.4)
	_sparks.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_sparks.extra_cull_margin = 400.0
	parent.add_child(_sparks)
	for c in 2:
		_comets.append({"period": 22.0 + c * 9.0, "offset": c * 11.0, "side": -1.0 if c else 1.0,
			"trail": [] as Array[Vector3]})


## Skiffs along their links, the wake behind each, the rifts' streams and
## the comets.
## Under reduced motion (§20.8) each keeps a still form: the skiffs moored
## part way along their links with no wake, the links' lights standing where
## they are, the comets gone.
func fly(now: float) -> void:
	var still := Settings.reduced_motion
	time = 0.0 if still else now
	if _sparks == null:
		return
	var mm := _sparks.multimesh
	var i := 0
	for s: Dictionary in _skiffs:
		var node: MeshInstance3D = s["node"]
		var t := 0.3 + float(s["phase"]) if still else time * float(s["speed"]) + float(s["phase"])
		var p := _skiff_at(s, t)
		var ahead := _skiff_at(s, t + 0.01)
		node.position = p
		var d := ahead - p
		if d.length() > 0.0001:
			node.rotation = Vector3(sin(time * 1.3 + float(s["phase"]) * 9.0) * 0.06, atan2(-d.z, d.x), d.y * 0.4)
		var wake: Array[Vector3] = s["wake"]
		if still:
			wake.clear()
			for k in WAKE:
				mm.set_instance_transform(i, Transform3D(Basis().scaled(Vector3.ZERO), p))
				i += 1
			continue
		wake.push_front(p + Vector3(0, 0.5, 0))
		if wake.size() > WAKE * 2:
			wake.pop_back()
		for k in WAKE:
			var w: Vector3 = wake[mini(k * 2, wake.size() - 1)]
			var c: Color = s["colour"]
			mm.set_instance_transform(i, Transform3D(Basis().scaled(Vector3.ONE * (0.9 - k * 0.06)), w))
			mm.set_instance_color(i, Color(c.lightened(0.4 if k % 2 else 0.1), 0.75 - k * 0.055))
			i += 1
	for st: Dictionary in _streams:
		var path: Array[Vector3] = st["path"]
		var lights := int(st.get("lights", 10))
		# A rift's stream runs and weaves; a link's few lights walk its deck.
		var walk := lights < 10
		for k in lights:
			var u := fmod(time * (0.08 if walk else 0.45) + (k + 0.5) / lights, 1.0)
			var f := u * (path.size() - 1)
			var j := mini(int(f), path.size() - 2)
			var at := path[j].lerp(path[j + 1], f - j)
			var c: Color = st["colour"] if k % 2 or walk else Color.WHITE
			var weave := 0.0 if walk else sin(u * PI * 4.0 + time * 3.0) * 0.6
			mm.set_instance_transform(i, Transform3D(Basis().scaled(Vector3.ONE * (1.1 if walk else 0.8)), at
				+ Vector3(0, 0, weave)))
			mm.set_instance_color(i, Color(c, sin(u * PI) * (0.85 if walk else 0.9)))
			i += 1
	if not still:
		i = _fly_comets(mm, i)
	while i < mm.instance_count:
		mm.set_instance_transform(i, Transform3D(Basis().scaled(Vector3.ZERO), Vector3.ZERO))
		i += 1


## Two comets crossing the deep sky, each with a tail of fading lights.
func _fly_comets(mm: MultiMesh, start: int) -> int:
	var i := start
	var c0 := bounds.get_center()
	var reach := maxf(40.0, bounds.size.z * 0.6)
	for c: Dictionary in _comets:
		var u := fmod(time + float(c["offset"]), float(c["period"])) / float(c["period"])
		var side: float = c["side"]
		var head := c0 + Vector3(-reach + u * reach * 2.0, -12.0 - side * 4.0 + sin(u * 3.0) * 2.0,
			side * (-reach * 0.9 + u * reach * 1.8))
		var trail: Array[Vector3] = c["trail"]
		trail.push_front(head)
		if trail.size() > 40:
			trail.pop_back()
		for k in 14:
			var at := trail[mini(k * 3, trail.size() - 1)]
			mm.set_instance_transform(i, Transform3D(Basis().scaled(Vector3.ONE * (1.6 - k * 0.09)), at))
			var tint := Color("#E8F6FF") if k == 0 else (Color("#9BEAF3") if side < 0 else Color("#FFD8F0"))
			mm.set_instance_color(i, Color(tint, 0.9 - k * 0.06))
			i += 1
	return i


## A skiff `t` along its route: over its link and back, riding high in the
## middle; with no link, round the universe.
func _skiff_at(s: Dictionary, t: float) -> Vector3:
	var route: Dictionary = s["route"]
	if route.is_empty():
		var c := bounds.get_center()
		var r := Vector2(bounds.size.x * 0.62, bounds.size.z * 0.45)
		var q := t * TAU * 0.5 * (1.0 if float(s["phase"]) < 0.5 else -1.0)
		return Vector3(c.x + cos(q) * r.x, 3.5 + sin(t * 9.0) * 0.4, c.z + sin(q) * r.y)
	var u := pingpong(t, 1.0)
	u = u * u * (3.0 - 2.0 * u)
	var a: Vector3 = route["a"]
	var b: Vector3 = route["b"]
	return a.lerp(b, u) + Vector3(0, 4.0 + sin(u * PI) * 3.0 + sin(time * 1.7 + float(s["phase"])) * 0.3, 0)
