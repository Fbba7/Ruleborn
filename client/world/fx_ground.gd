class_name FxGround
extends RefCounted
## What `WorldView` draws flat on the ground, each frame or each tick: the
## shown guard's sight and the other guards' cones (§21.12), the rings under
## the crew and the guards, and the chosen crew member's route to its last
## order. All of it is read from `RulebornReplay`; none of it decides
## anything.


## §21.12: "Sharp edges, no gradients. A tile is inside or outside": each
## tile the shown guard's cone reaches, as the simulation decides it, filled
## flat in the alarm's red just above the ground, and an ink-red line round
## the shape it makes. Every other guard on its feet shows a quiet outline of
## its cone, so its facing reads without a second shape to read (§21.12:
## "the others show only their facing").
static func sight(view: WorldView) -> void:
	var g := Geo.new()
	var edge := Geo.new()
	var shown := view.shown_guard()
	if shown >= 0:
		var seen := {}
		for tile in view.replay.seen(shown):
			seen[tile] = true
		for tile: int in seen:
			var p := Vector2(tile % view._size.x, tile / view._size.x)
			var c := view.world_at(p + Vector2(0.5, 0.5))
			g.box(Geo.place(c + Vector3(0, 0.03, 0)), Vector3(0.98, 0.02, 0.98), Palette.ALARM)
			for side: Vector2i in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
				var q := Vector2i(p) + side
				var size := view._size
				var inside := q.x >= 0 and q.y >= 0 and q.x < size.x and q.y < size.y and seen.has(q.y * size.x + q.x)
				if not inside:
					var mid := c + Vector3(side.x * 0.47, 0.045, side.y * 0.47)
					var along := Vector3(absf(side.y), 0, absf(side.x))
					edge.box(Geo.place(mid), along * 1.0 + Vector3(absf(side.x), 0, absf(side.y)) * 0.07 \
						+ Vector3(0, 0.02, 0), Palette.ALARM.darkened(0.35))
	var guards := view.replay.guards()
	for i in guards.size():
		var gd: Dictionary = guards[i]
		if i == shown or gd["down"] or i >= view._guards.size():
			continue
		cone_outline(edge, view._guards[i].position + Vector3(0, 0.05, 0), float(gd["facing"]), float(gd["cone"]),
			float(gd["far"]))
	view.overlay.mesh = g.mesh()
	view.sight_edge.mesh = edge.mesh()
	if view.overlay.material_override == null:
		view.overlay.material_override = WorldView.clear_material(0.42)


## A thin dashed outline of a cone on the ground: two edges and the far arc,
## a hint of where a guard looks rather than a second shape to read.
static func cone_outline(g: Geo, at: Vector3, facing: float, cone: float, far: float) -> void:
	var half := cone * 0.5
	var steps := 10
	var colour := Color("#F3EEFF", 0.55)
	var w := 0.04
	var pts: Array[Vector3] = [at]
	for k in steps + 1:
		var a := facing - half + cone * k / steps
		pts.append(at + Vector3(cos(a), 0, sin(a)) * far)
	pts.append(at)
	var dash := 0.28
	var gap := 0.18
	for k in pts.size() - 1:
		var a3: Vector3 = pts[k]
		var b3: Vector3 = pts[k + 1]
		var d := b3 - a3
		var length := d.length()
		if length < 0.001:
			continue
		var along := d / length
		var side := Vector3(-d.z, 0, d.x).normalized() * w
		var u := 0.0
		while u < length:
			var p0 := a3 + along * u
			var p1 := a3 + along * minf(length, u + dash)
			g.quad(p0 - side, p1 - side, p1 + side, p0 + side, colour)
			u += dash + gap


## The rings on the ground: each crew member's in its role's colour, as the
## designs ring their crew, the chosen one's gold and pulsing; each guard's in
## its awareness colour, so its state reads from above too, the shown one's
## doubled.
static func rings(view: WorldView, into: MeshInstance3D, t: float) -> void:
	var g := Geo.new()
	var crew := view.replay.crew()
	for i in mini(crew.size(), view._crew.size()):
		if not view._crew[i].visible or i == view.chosen:
			continue
		var c: Color = Palette.ROLE.get(str(crew[i]["role"]), Palette.PAPER)
		# A bold ring in the role's colour on an ink rim, so a crew member
		# stands out from painted grass as the designs' rings do.
		g.ring(Geo.place(view._crew[i].position + Vector3(0, 0.05, 0)), 0.36, 0.5, c, 24)
		g.ring(Geo.place(view._crew[i].position + Vector3(0, 0.051, 0)), 0.5, 0.55, Palette.INK, 24)
	var chosen := view.chosen
	if chosen >= 0 and chosen < view._crew.size() and view._crew[chosen].visible:
		var pulse := 0.0 if Settings.reduced_motion else 0.04 * sin(t * TAU * 1.2)
		var at := view._crew[chosen].position
		g.ring(Geo.place(at + Vector3(0, 0.05, 0)), 0.4 + pulse, 0.54 + pulse, Palette.MOTION, 28)
		g.ring(Geo.place(at + Vector3(0, 0.051, 0)), 0.54 + pulse, 0.57 + pulse, Palette.INK, 28)
	var shown := view.shown_guard()
	var night := view.hour >= 19 or view.hour < 6 or view.woven.has("glowing_dark")
	for i in view._guards.size():
		var node := view._guards[i]
		if node.get_meta("down", false):
			continue
		if night:
			# By night a guard's lantern lights a warm pool round it
			# (§21.2: "lanterns and glows carry the realm").
			var pool := node.position + node.basis * Vector3(-0.3, 0.0, -0.4)
			g.ring(Geo.place(Vector3(pool.x, node.position.y + 0.035, pool.z)), 0.0, 1.1, Color("#FFC36A", 0.5), 24)
		var c: Color = Palette.GUARD_STATE.get(str(node.get_meta("state", "Unaware")), Palette.PAPER)
		g.ring(Geo.place(node.position + Vector3(0, 0.05, 0)), 0.42, 0.5, c, 24)
		if i == shown:
			# The guard whose sight is drawn: an ink-red ring round its own,
			# so whose cone it is reads at a glance (§21.12).
			g.ring(Geo.place(node.position + Vector3(0, 0.052, 0)), 0.52, 0.62, Palette.ALARM.darkened(0.3), 28)
	route(view, g, t)
	into.mesh = g.mesh()


## The chosen crew member's last order, drawn as the designs' route preview:
## ink dots on the ground from where it stands to where it was sent, white
## where they cross the shown guard's red sight, and a ring at the end. It draws the
## order the player gave, not a path the client works out (§12.18).
static func route(view: WorldView, g: Geo, t: float) -> void:
	var chosen := view.chosen
	if not view.heist or chosen < 0 or chosen >= view._crew.size() or not view._crew[chosen].visible:
		return
	var goal := order_goal(view, view.chosen)
	if goal.x < 0.0:
		return
	var from := view._crew[view.chosen].position
	var to := view.world_at(goal)
	var flat := Vector2(to.x - from.x, to.z - from.z)
	if flat.length() < 0.6:
		return
	var seen := {}
	var shown := view.shown_guard()
	if shown >= 0:
		for tile in view.replay.seen(shown):
			seen[tile] = true
	var steps := int(flat.length() / 0.36)
	var drift := 0.0 if Settings.reduced_motion else fmod(t * 1.2, 1.0)
	for k in range(1, steps):
		var u := (k + drift) / float(steps)
		var p := from.lerp(to, u)
		var tile := Vector2i(floori(p.x + view._size.x / 2.0), floori(p.z + view._size.y / 2.0))
		var lit := seen.has(tile.y * view._size.x + tile.x)
		g.ring(Geo.place(Vector3(p.x, view.world_at(Vector2(tile) + Vector2(0.5, 0.5)).y + 0.06, p.z)), 0.0, 0.09,
			Palette.PAPER if lit else Color(Palette.INK, 0.8), 8)
	var pulse := 0.0 if Settings.reduced_motion else 0.05 * sin(t * TAU)
	g.ring(Geo.place(to + Vector3(0, 0.06, 0)), 0.24 + pulse, 0.33 + pulse, Palette.INK, 20)
	g.ring(Geo.place(to + Vector3(0, 0.061, 0)), 0.0, 0.1, Palette.MOTION, 10)


## Where crew member `i` was last sent, in tiles, or (-1, -1) when its last
## order sends it nowhere (a halt, a gait, nothing yet).
static func order_goal(view: WorldView, i: int) -> Vector2:
	var orders := view.replay.commands()
	for k in range(orders.size() - 1, -1, -1):
		var c: Dictionary = orders[k]
		if int(c["actor"]) != i:
			continue
		match int(c["kind"]):
			HeistController.Kind.MOVE_TO, HeistController.Kind.BREAK, HeistController.Kind.DISARM:
				return Vector2(c["x"], c["y"]) / 256.0
			HeistController.Kind.CRACK, HeistController.Kind.LOAD:
				var v := view.replay.vault()
				return (v["at"] as Vector2) if v.has("at") else Vector2(-1, -1)
			HeistController.Kind.ATTACK, HeistController.Kind.DRAG:
				var guards := view.replay.guards()
				var gi := int(c["x"])
				return (guards[gi]["at"] as Vector2) if gi >= 0 and gi < guards.size() else Vector2(-1, -1)
			HeistController.Kind.GAIT:
				continue
			_:
				return Vector2(-1, -1)
	return Vector2(-1, -1)


## The pylons, each standing or broken, and the wards, each live or down, as
## one mesh, built again only when one of them changes.
static func pieces(view: WorldView) -> void:
	if view._pieces == null:
		return
	var pylons := view.replay.pylons()
	var wards := view.replay.wards()
	var key := ",".join(pylons.map(func(p: Dictionary) -> String: return str(p["standing"]))) + "|" \
		+ ",".join(wards.map(func(w: Dictionary) -> String: return str(w["live"])))
	if key == view._piece_key:
		return
	view._piece_key = key
	var st := SurfaceTool.new()
	var any := false
	for p: Dictionary in pylons:
		var mesh := PieceKit.pylon(str(p.get("school", "matter"))) if p["standing"] else PieceKit.broken_pylon()
		any = _append(st, mesh, view.world_at(p["at"])) or any
	for w: Dictionary in wards:
		var mesh := PieceKit.ward(str(w["kind"])) if w["live"] else PieceKit.dead_ward()
		any = _append(st, mesh, view.world_at(w["at"])) or any
	view._pieces.mesh = st.commit() if any else null


static func _append(st: SurfaceTool, mesh: ArrayMesh, at: Vector3) -> bool:
	if mesh == null:
		return false
	for k in mesh.get_surface_count():
		st.append_from(mesh, k, Transform3D(Basis.IDENTITY, at))
	return mesh.get_surface_count() > 0
