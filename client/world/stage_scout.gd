class_name StageScout
extends Node3D
## What a scout knows of a realm, on its island (§12.4: "laws, guards by
## role, wards by kind"; "nothing placed"): the island at its realm's size
## and type under the scout's mist, every tile veiled, since where anything
## stands is what the raid finds out; the guards it counted lined up on the
## rim by role, the wards it counted standing beside them by kind, and its
## laws flown as banners at its near corner. Nothing is drawn on a tile.

## The mist's veil over every tile.
const VEIL := Color(0.78, 0.74, 0.96, 0.55)

static var _toon: Shader = load("res://world/toon.gdshader")
static var _mist: Shader = load("res://world/stage_mist.gdshader")

var view: StageView
var tiles: OverlayTiles
var mist: MeshInstance3D
var figures: Node3D
var banners: MeshInstance3D


func _init(on: StageView) -> void:
	view = on
	name = "Scout"
	tiles = OverlayTiles.new(on)
	mist = MeshInstance3D.new()
	mist.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	# Every vertex of a card sits at its centre: the box is given.
	mist.custom_aabb = AABB(Vector3(-12, -1, -12), Vector3(24, 6, 24))
	var m := ShaderMaterial.new()
	m.shader = _mist
	m.render_priority = 2
	m.set_shader_parameter("drift", 0.0 if Settings.reduced_motion else 1.0)
	mist.material_override = m
	add_child(mist)
	figures = Node3D.new()
	add_child(figures)
	banners = WorldView._instance(null, WorldView.material(_toon, true))
	add_child(banners)
	on.layers.add_child(self)


## Draws the card's realm ({realm_level, laws, guards, wards}, the server's
## counts) on the view, which shows its bare island.
func build(realm: Dictionary) -> void:
	for c: Node in figures.get_children():
		c.queue_free()
	var size := view.grid_size()
	var veil := {}
	for y in size.y:
		for x in size.x:
			veil[Vector2i(x, y)] = VEIL
	tiles.paint(veil)
	mist.mesh = _clouds(size)
	var pins := StageScreen.pins_of(view)
	pins.clear()
	# The guards by role along the near south rim, the wards by kind along
	# the near east rim, each kind with its count pinned over it.
	var guards: Dictionary = realm.get("guards", {})
	var wards: Dictionary = realm.get("wards", {})
	_line(guards, false, size)
	_line(wards, true, size)
	# The laws fly at the realm's near corner, a banner each, the line-ups
	# either side of them; the sheet below names them.
	var laws: Array = realm.get("laws", [])
	var g := Geo.new()
	for i in laws.size():
		var across := (i - (laws.size() - 1) / 2.0) * 1.1
		var at := Vector3(size.x * 0.5 + 1.0 + across * 0.7071, 0.0, size.y * 0.5 + 1.0 - across * 0.7071)
		g.prism(Geo.place(at), 6, 0.07, 0.05, 2.6, Palette.WOOD.darkened(0.25))
		g.ball(Geo.place(at + Vector3(0, 2.65, 0)), 0.11, Palette.MOTION, 3, 6)
		var cloth := Palette.MATTER.lightened(0.15 * (i % 2))
		g.box(Geo.place(at + Vector3(0.36, 2.15, 0.36), PI / 4.0), Vector3(0.9, 0.62, 0.05), cloth)
	banners.mesh = g.mesh()


## One rim's line-up: `counts` by kind, guards along the south rim or wards
## along the east, from the near corner outward.
func _line(counts: Dictionary, wards: bool, size: Vector2i) -> void:
	var pins := StageScreen.pins_of(view)
	var kinds := counts.keys()
	kinds.sort()
	var step := 0.95
	var along := 2.4
	for k: String in kinds:
		var first := along
		for i in int(counts[k]):
			var at := Vector2(size.x + 0.85, size.y - along) if wards else Vector2(size.x - along, size.y + 0.85)
			var model: CreatureModel = null if wards else guard_model(k)
			if model != null:
				model.position = _ground(at)
				model.rotation.y = PI
				figures.add_child(model)
			else:
				_figure(PieceKit.ward(k.to_pascal_case()) if wards else ActorBuilder.mesh("guard"), at,
					1.7 if wards else 1.6)
			along += step
		var mid := (first + along - step) / 2.0
		var top := Vector2(size.x + 0.85, size.y - mid) if wards else Vector2(size.x - mid, size.y + 0.85)
		var fill := Color("#FFC2CC")
		if wards:
			var school := str(Palette.WARD_SCHOOL.get(k.to_pascal_case(), "matter"))
			fill = (Palette.SCHOOL.get(school, Palette.MATTER) as Color).lightened(0.55)
		pins.pin(OverlaySheet.chip(str(int(counts[k])), fill), _ground(top) + Vector3(0, 1.75, 0))
		along += step * 0.5


## A guard of `role` as the scout counted it: its role's kind (`Cast`) in
## the guard form (§21.6: "ruleborn add a sash and a small lantern"), or
## null where the model is not exported.
static func guard_model(role: String) -> CreatureModel:
	var kind: StringName = Cast.KIND.get(role, &"")
	if kind == &"" or not CreatureModel.manifest().has(String(kind)):
		return null
	var model := CreatureModel.make(kind)
	if model != null:
		model.set_guard(true)
	return model


func _ground(at: Vector2) -> Vector3:
	var size := view.grid_size()
	return Vector3(at.x - size.x / 2.0, 0.0, at.y - size.y / 2.0)


func _figure(mesh: Mesh, at: Vector2, scale_by: float) -> void:
	var mi := WorldView._instance(mesh, WorldView.material(_toon, true))
	mi.position = _ground(at)
	mi.scale = Vector3.ONE * scale_by
	# Facing out of the realm, toward whoever is looking at it.
	mi.rotation.y = PI
	figures.add_child(mi)


## The mist over the grid, seeded by its size: soft cards in two layers
## (`stage_mist.gdshader`), one mesh.
func _clouds(size: Vector2i) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var n := size.x * size.y / 3
	for i in n:
		var u := RealmKit.jitter(Vector2i(i, size.x), 1)
		var v := RealmKit.jitter(Vector2i(size.y, i), 2)
		var lift := 0.35 + 0.9 * RealmKit.jitter(Vector2i(i, i), 3)
		var at := Vector3((u - 0.5) * size.x * 1.02, lift, (v - 0.5) * size.y * 1.02)
		var colour := Color(RealmKit.jitter(Vector2i(i, 7), 4), 0.42 + 0.3 * RealmKit.jitter(Vector2i(7, i), 5), 0.0)
		var uvs := [Vector2(0, 0), Vector2(1, 0), Vector2(1, 1), Vector2(0, 1)]
		for k: int in [0, 1, 2, 0, 2, 3]:
			st.set_color(colour)
			st.set_uv(uvs[k])
			st.add_vertex(at)
	return st.commit()

