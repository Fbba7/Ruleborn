class_name OverlayTiles
extends Node3D
## The defence and terrain overlay laid on a realm's tiles (the diorama's
## `DF`, realm-diorama.js ~:280–376): every open tile a soft rounded plate,
## tiles painted by what they mean (a guard's sight, where a piece may go),
## a cursor edged in gold where a tap would act or in red where the island
## refuses it, and a ghost of the piece before it is placed. The diorama
## turns a 9 × 9 grid of 3.9-unit cells 45° over its island; here the grid
## is the simulation's own (one tile, one metre), and the home camera's 45°
## yaw turns it the same way on screen.
##
## Each layer is one mesh, so the whole overlay is a handful of draw calls
## (§21.3).

## The plates' colours: the grid's, a guard's sight (§21.12's alarm red),
## where a piece may go, where it may not.
const GRID := Color(0.42, 0.32, 0.86, 0.2)
const SIGHT := Color("#FF6A7E", 0.5)
const OPEN := Color("#4DFF8E", 0.42)
const BAD := Color("#FF5C6E", 0.55)
const CURSOR := Color("#FFE38A")
const CURSOR_BAD := Color("#FF5C6E")
## A plate's share of its tile, and how far above the ground it floats.
const PLATE := 0.9
const LIFT := 0.035

static var _tile_texture: ImageTexture

var view: StageView
var grid_node: MeshInstance3D
var paint_node: MeshInstance3D
var cursor_node: MeshInstance3D
var ghost_node: MeshInstance3D
var _clock := 0.0


func _init(on: StageView) -> void:
	view = on
	name = "Tiles"
	grid_node = _layer(_plate_material(1.0))
	paint_node = _layer(_plate_material(1.0))
	cursor_node = _layer(_flat_material())
	ghost_node = MeshInstance3D.new()
	ghost_node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(ghost_node)
	on.layers.add_child(self)


func _layer(m: Material) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.material_override = m
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(mi)
	return mi


## The rounded plate the diorama draws on a canvas (`dTex().tile`): a soft
## fill and a white rim, made once.
static func tile_texture() -> ImageTexture:
	if _tile_texture != null:
		return _tile_texture
	var n := 64
	var img := Image.create(n, n, false, Image.FORMAT_RGBA8)
	var r := 12.0
	for y in n:
		for x in n:
			var p := Vector2(x + 0.5, y + 0.5)
			var q := Vector2(clampf(p.x, 3.0 + r, n - 3.0 - r), clampf(p.y, 3.0 + r, n - 3.0 - r))
			var d := p.distance_to(q) - r
			var a := 0.0
			if d <= 0.0:
				a = 0.5 if d < -4.0 else 1.0
			elif d < 1.0:
				a = 1.0 - d
			img.set_pixel(x, y, Color(1, 1, 1, a))
	_tile_texture = ImageTexture.create_from_image(img)
	return _tile_texture


static func _plate_material(alpha: float) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.vertex_color_use_as_albedo = true
	m.albedo_texture = tile_texture()
	m.albedo_color = Color(1, 1, 1, alpha)
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	m.no_depth_test = false
	m.render_priority = 1
	return m


static func _flat_material() -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.vertex_color_use_as_albedo = true
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	m.render_priority = 2
	return m


## A plate on each tile of `tiles` (all of the grid when empty), skipping
## `blocked`, in the grid's colour.
func show_grid(blocked := {}) -> void:
	var size := view.grid_size()
	var colours := {}
	for y in size.y:
		for x in size.x:
			var t := Vector2i(x, y)
			if not blocked.has(t):
				colours[t] = GRID
	grid_node.mesh = _plates(colours, PLATE)


func hide_grid() -> void:
	grid_node.mesh = null


## Tiles painted: `colours` maps a tile to its colour.
func paint(colours: Dictionary) -> void:
	paint_node.mesh = _plates(colours, PLATE * 1.02)


func _plates(colours: Dictionary, share: float) -> ArrayMesh:
	if colours.is_empty():
		return null
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var h := share / 2.0
	for t: Vector2i in colours:
		var c := view.tile_point(t, LIFT)
		var col: Color = colours[t]
		var corners := [Vector3(-h, 0, -h), Vector3(h, 0, -h), Vector3(h, 0, h), Vector3(-h, 0, h)]
		var uvs := [Vector2(0, 0), Vector2(1, 0), Vector2(1, 1), Vector2(0, 1)]
		for k: int in [0, 1, 2, 0, 2, 3]:
			st.set_color(col)
			st.set_uv(uvs[k])
			st.set_normal(Vector3.UP)
			st.add_vertex(c + (corners[k] as Vector3))
	return st.commit()


## The cursor on `t`: an edge of four bars, gold where a tap would act, red
## where the island refuses it; none when `t` is off the grid.
func cursor(t: Vector2i, ok := true) -> void:
	var size := view.grid_size()
	if t.x < 0 or t.y < 0 or t.x >= size.x or t.y >= size.y:
		cursor_node.mesh = null
		return
	var g := Geo.new()
	var c := view.tile_point(t, LIFT * 2.0)
	var col := CURSOR if ok else CURSOR_BAD
	var w := 0.09
	for side: Array in [[Vector3(0, 0, -0.5), Vector3(1.0 + w, 0.03, w)], [Vector3(0, 0, 0.5), Vector3(1.0 + w, 0.03, w)],
			[Vector3(-0.5, 0, 0), Vector3(w, 0.03, 1.0 + w)], [Vector3(0.5, 0, 0), Vector3(w, 0.03, 1.0 + w)]]:
		g.box(Geo.place(c + (side[0] as Vector3)), side[1], col)
	cursor_node.mesh = g.mesh()


## A ghost of `mesh` on tile `t`, turned `yaw`: see-through, tinted gold if
## it may stand there and red if not; none when `mesh` is null.
func ghost(mesh: Mesh, t: Vector2i, ok := true, yaw := 0.0) -> void:
	ghost_node.mesh = mesh
	if mesh == null:
		return
	ghost_node.position = view.tile_point(t)
	ghost_node.rotation = Vector3(0, yaw, 0)
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.albedo_color = Color(CURSOR if ok else CURSOR_BAD, 0.55)
	m.render_priority = 3
	ghost_node.material_override = m


func _process(delta: float) -> void:
	_clock += delta
	if Settings.reduced_motion:
		return
	# The ghost bobs and the painted plates pulse, as the diorama's do.
	ghost_node.position.y = _ground_y() + 0.06 + absf(sin(_clock * 3.0)) * 0.08
	var m := paint_node.material_override as StandardMaterial3D
	m.albedo_color.a = 0.8 + 0.2 * sin(_clock * 2.2)


func _ground_y() -> float:
	var at := ghost_node.position
	var size := view.grid_size()
	var t := Vector2i(floori(at.x + size.x / 2.0), floori(at.z + size.y / 2.0))
	return view.tile_point(t).y
