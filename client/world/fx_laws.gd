class_name FxLaws
extends Node3D
## §21.7's laws on screen: each law woven in the realm has a world signature
## ("how its realm looks") and a movement signature ("how characters move"),
## both always on while its pylon stands, so a player reads the island
## without opening a menu. Drawn as §21.3 allows on the phone: particles
## (`MultiMesh` motes moved on the CPU), marks on the ground and vertex
## animation of the figures (`movement`), never a full-screen pass. Each law
## takes at most two draw calls, and every effect is kept low, thin or
## see-through, so nothing a player must read is hidden.
##
## The launch laws (sim/src/laws_table.rs's `launch: true`) each have one;
## the designs' `lawFX` drew nine (stillness, slow rivers, half gravity,
## current, glass, day and night, frictionless, bloom, glowing dark), whose
## numbers these follow.

## Each law's look: its motes (`shape`, `motion`, `count`, `colour`, whether
## they glow) and a mark on the ground (`ground`), and how it bends movement
## (`rate` of steps, `hop` height, `float` above the ground, `lean`).
const LOOK := {
	"bounce": {"shape": "ball", "motion": "bounce", "count": 14, "colour": "#F7A6DA", "glow": false,
		"hop": 1.9, "rate": 1.1},
	"half_gravity": {"shape": "rock", "motion": "hover", "count": 16, "colour": "#B9AE9F", "glow": false,
		"ground": "shadows", "hop": 2.6, "rate": 0.6, "float": 0.1},
	"frictionless": {"shape": "glint", "motion": "glint", "count": 10, "colour": "#E6FCFF", "glow": true,
		"ground": "ice", "hop": 0.2, "rate": 0.8, "lean": 0.12},
	"inward_pull": {"shape": "streak", "motion": "spiral", "count": 22, "colour": "#F2B43C", "glow": true,
		"ground": "spiral", "rate": 0.9},
	"brittle_stone": {"shape": "crumb", "motion": "fall", "count": 18, "colour": "#8A7A6A", "glow": false,
		"ground": "cracks", "hop": 0.4, "rate": 0.8},
	"glass": {"shape": "glint", "motion": "glint", "count": 16, "colour": "#E6E0FF", "glow": true,
		"ground": "panes"},
	"density": {"shape": "ball", "motion": "hover", "count": 12, "colour": "#A98CF0", "glow": false,
		"rate": 0.7, "hop": 1.3},
	"honeycomb": {"shape": "hex", "motion": "rise", "count": 12, "colour": "#F2C14A", "glow": true,
		"ground": "hexes", "rate": 0.85, "hop": 0.6},
	"slow_rivers": {"shape": "drop", "motion": "hang", "count": 22, "colour": "#9BEAF3", "glow": true,
		"rate": 0.6},
	"stillness": {"shape": "drop", "motion": "hang", "count": 26, "colour": "#9BEAF3", "glow": true,
		"ground": "rings"},
	"delay": {"shape": "ball", "motion": "hang", "count": 10, "colour": "#3CC6D8", "glow": true,
		"ground": "ripples"},
	"haste": {"shape": "streak", "motion": "stream", "count": 26, "colour": "#FFFFFF", "glow": false,
		"rate": 1.5, "hop": 1.2},
	"glowing_dark": {"shape": "mote", "motion": "drift", "count": 30, "colour": "#9DF2B0", "glow": true,
		"dark": 0.5, "rate": 0.85, "hop": 0.5},
	"aurora": {"shape": "mote", "motion": "drift", "count": 14, "colour": "#9BF0D8", "glow": true,
		"ground": "bands"},
	"chain_lightning": {"shape": "spark", "motion": "spark", "count": 12, "colour": "#BFE8FF", "glow": true,
		"ground": "arcs"},
	"static": {"shape": "spark", "motion": "spark", "count": 26, "colour": "#FFE27A", "glow": true,
		"lean": 0.04},
	"bloom": {"shape": "flower", "motion": "sprout", "count": 18, "colour": "#F7A6DA", "glow": false},
	"kinship": {"shape": "leaf", "motion": "drift", "count": 10, "colour": "#5CC46A", "glow": false,
		"ground": "threads"},
	"thorns": {"shape": "thorn", "motion": "sprout", "count": 20, "colour": "#4E7A3A", "glow": false,
		"hop": 1.3},
	"regrowth": {"shape": "leaf", "motion": "rise", "count": 18, "colour": "#7FD86A", "glow": true},
	"whispers": {"shape": "wisp", "motion": "drift", "count": 12, "colour": "#F2A6E8", "glow": true},
	"echoes": {"shape": "wisp", "motion": "orbit", "count": 10, "colour": "#E05CB4", "glow": true,
		"ground": "rings"},
	"sleepwalk": {"shape": "z", "motion": "rise", "count": 12, "colour": "#C9B8FF", "glow": true,
		"rate": 0.75, "lean": 0.08},
	"soul_swap": {"shape": "wisp", "motion": "orbit", "count": 14, "colour": "#F7A6DA", "glow": true},
}

static var _clear: Shader = load("res://world/toon_clear.gdshader")
static var _toon: Shader = load("res://world/toon.gdshader")

## The laws drawn, in the order their pylons stand.
var woven: Array[String] = []
var _grid := Vector2i.ZERO
var _motes: Array[Dictionary] = []
var _threads: MeshInstance3D
var _clock := 0.0
var _dark := 0.0
var _sun_energy := -1.0
var _ambient := -1.0


## Draw the laws `ids` over a realm of `grid` tiles. Laws with no look of
## their own (not launched yet) draw nothing.
func build(ids: Array[String], grid: Vector2i, view: WorldView) -> void:
	for c in get_children():
		c.queue_free()
	woven.clear()
	_motes.clear()
	_threads = null
	_grid = grid
	_dark = 0.0
	if _sun_energy >= 0.0 and view.sun != null:
		view.sun.light_energy = _sun_energy
		view.environment.ambient_light_energy = _ambient
	_sun_energy = -1.0
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(grid) ^ ids.size()
	for id in ids:
		if not LOOK.has(id) or id in woven:
			continue
		woven.append(id)
		var look: Dictionary = LOOK[id]
		_dark = maxf(_dark, float(look.get("dark", 0.0)))
		_add_motes(id, look, rng)
		if look.has("ground"):
			_add_ground(str(look["ground"]), Color(str(look["colour"])), rng)
	if _dark > 0.0 and view.sun != null:
		# Glowing dark: the sun and the sky's light dimmed, so what glows
		# carries the realm (§21.7: "a black realm lit by glowing mushrooms").
		_sun_energy = view.sun.light_energy
		_ambient = view.environment.ambient_light_energy
		view.sun.light_energy *= 1.0 - _dark * 0.7
		view.environment.ambient_light_energy *= 1.0 - _dark * 0.5


## How the laws running bend a figure's steps: `rate` of its steps, `hop`
## height, how far it `float`s, and its `lean`.
func movement(moving: bool, _gait: String, t: float) -> Dictionary:
	var out := {"rate": 1.0, "hop": 1.0, "float": 0.0, "lean": 0.0}
	for id in woven:
		var look: Dictionary = LOOK[id]
		out["rate"] = float(out["rate"]) * float(look.get("rate", 1.0))
		out["hop"] = float(out["hop"]) * float(look.get("hop", 1.0))
		out["float"] = float(out["float"]) + float(look.get("float", 0.0)) * (0.6 + 0.4 * sin(t * 2.0))
		var lean := float(look.get("lean", 0.0))
		if id == "static":
			lean *= sin(t * 37.0)
		elif id == "frictionless":
			lean *= sin(t * 1.7) if moving else 0.0
		elif id == "sleepwalk":
			lean *= sin(t * 0.9)
		out["lean"] = float(out["lean"]) + lean
	if Settings.reduced_motion:
		out["hop"] = minf(float(out["hop"]), 1.0)
		out["lean"] = 0.0
	return out


## A mote's place at time `t`: its law's motion.
func tick(delta: float, view: WorldView) -> void:
	if woven.is_empty():
		return
	_clock += delta * (0.25 if Settings.reduced_motion else 1.0)
	for m in _motes:
		_move(m, _clock)
	if _threads != null:
		_link_crew(view)


func _add_motes(id: String, look: Dictionary, rng: RandomNumberGenerator) -> void:
	var count := int(look["count"])
	var colour := Color(str(look["colour"]))
	var glow: bool = look["glow"]
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = true
	mm.mesh = _shape(str(look["shape"]), colour, glow)
	mm.instance_count = count
	var half := Vector2(_grid) * 0.5 + Vector2(1.5, 1.5)
	var seeds: Array[Vector4] = []
	for i in count:
		seeds.append(Vector4(rng.randf_range(-half.x, half.x), rng.randf_range(-half.y, half.y), rng.randf(),
			rng.randf_range(0.6, 1.4)))
		mm.set_instance_color(i, Color(1, 1, 1, 1))
	var mi := MultiMeshInstance3D.new()
	mi.multimesh = mm
	var mat := ShaderMaterial.new()
	mat.shader = _toon if not glow else _clear
	if glow:
		mat.set_shader_parameter("opacity", 0.85)
	else:
		mat.set_shader_parameter("glow_from_alpha", 1.0)
	mi.material_override = mat
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mi.name = "Law_" + id
	add_child(mi)
	var m := {"mm": mm, "seeds": seeds, "motion": str(look["motion"]), "half": half, "glow": glow}
	_motes.append(m)
	_move(m, 0.0)


## Each motion: where seed `s` (x, z on the grid, a phase, a size) is at `t`.
func _move(m: Dictionary, t: float) -> void:
	var mm: MultiMesh = m["mm"]
	var seeds: Array[Vector4] = m["seeds"]
	var half: Vector2 = m["half"]
	for i in seeds.size():
		var s := seeds[i]
		var ph := s.z * TAU
		var pos := Vector3(s.x, 0.4, s.y)
		var sz := s.w
		var spin := ph
		var alpha := 1.0
		match str(m["motion"]):
			"hover":
				pos.y = 0.35 + s.z * 1.2 + sin(t * 0.8 + ph) * 0.12
				spin = t * 0.2 + ph
			"bounce":
				var k := absf(sin(t * 2.4 + ph))
				pos.y = 0.08 + k * 0.7
				sz *= 0.9 + 0.2 * (1.0 - k)
			"glint":
				alpha = maxf(0.0, sin(t * 1.6 + ph * 3.0))
				pos.y = 0.15 + s.z * 0.6
				sz *= 0.4 + alpha
			"spiral":
				var u := fmod(t * 0.12 + s.z, 1.0)
				var r := lerpf(half.length() * 0.7, 0.6, u)
				var a := ph + u * 5.0
				pos = Vector3(cos(a) * r, 0.12, sin(a) * r)
				spin = -a
				alpha = sin(u * PI)
			"fall":
				var u := fmod(t * 0.35 + s.z, 1.0)
				pos.y = 2.0 * (1.0 - u)
				alpha = 1.0 - u * u
				spin = t * 3.0 + ph
			"rise":
				var u := fmod(t * 0.18 + s.z, 1.0)
				pos.y = 0.2 + u * 2.6
				pos.x += sin(t + ph) * 0.2
				alpha = sin(u * PI)
				spin = t * 0.8 + ph
			"hang":
				pos.y = 0.8 + s.z * 2.0 + sin(t * 0.25 + ph) * 0.03
			"stream":
				var u := fmod(t * 0.5 + s.z, 1.0)
				pos.x = lerpf(-half.x - 3.0, half.x + 3.0, u)
				pos.y = 0.6 + s.w * 1.4
				alpha = sin(u * PI)
				spin = 0.0
			"drift":
				pos.x += sin(t * 0.21 + ph) * 1.2
				pos.z += cos(t * 0.17 + ph * 1.3) * 1.2
				pos.y = 0.5 + s.z * 2.2 + sin(t * 0.9 + ph) * 0.25
				alpha = 0.55 + 0.45 * sin(t * 1.3 + ph)
			"spark":
				var on := fmod(t * 2.0 + s.z * 7.0, 1.0)
				alpha = 1.0 if on < 0.25 else 0.0
				pos.y = 0.15 + s.z * 0.4
				spin = t * 9.0 + ph
				sz *= 0.6 + on
			"sprout":
				var g := 0.5 + 0.5 * sin(t * 0.5 + ph)
				pos.y = 0.02
				sz *= maxf(0.05, g)
			"orbit":
				var a := t * 0.5 + ph
				var r := 1.0 + s.w * 3.0
				pos = Vector3(cos(a) * r, 0.6 + sin(t + ph) * 0.3, sin(a) * r)
				alpha = 0.6 + 0.4 * sin(t * 2.0 + ph)
		var turned := Basis(Vector3.UP, spin).scaled(Vector3.ONE * maxf(0.001, sz * (0.3 + 0.7 * alpha)))
		mm.set_instance_transform(i, Transform3D(turned, pos))
		mm.set_instance_color(i, Color(1, 1, 1, alpha if m["glow"] else 1.0))


## The mote meshes: small, chunky, each a silhouette of its own.
func _shape(shape: String, colour: Color, glow: bool) -> ArrayMesh:
	var g := Geo.new()
	var c := Color(colour, 0.6 if glow else 1.0)
	match shape:
		"rock":
			g.prism(Geo.place(Vector3(0, -0.25, 0)), 6, 0.0, 0.28, 0.3, colour.darkened(0.15))
			g.prism(Geo.place(Vector3(0, 0.05, 0)), 6, 0.3, 0.26, 0.07, Color("#7DBA5B"))
		"glint":
			for a: float in [0.0, PI / 2.0]:
				g.box(Geo.place(Vector3.ZERO, a), Vector3(0.36, 0.05, 0.05), c)
		"streak":
			g.box(Geo.place(Vector3.ZERO), Vector3(1.2, 0.04, 0.06), c)
		"crumb", "spark":
			g.box(Geo.place(Vector3.ZERO, 0.4), Vector3(0.1, 0.1, 0.1), c)
		"hex":
			g.prism(Geo.place(Vector3.ZERO), 6, 0.16, 0.16, 0.03, c)
		"drop":
			g.ball(Geo.place(Vector3.ZERO, 0.0, Vector3(1.0, 1.4, 1.0)), 0.08, c, 3, 6)
		"mote":
			g.ball(Geo.place(Vector3.ZERO), 0.06, c, 2, 5)
		"flower":
			for k in 5:
				var a := TAU * k / 5.0
				g.ball(Geo.place(Vector3(cos(a) * 0.08, 0.22, sin(a) * 0.08)), 0.06, c, 2, 5)
			g.ball(Geo.place(Vector3(0, 0.22, 0)), 0.05, Color("#FFE27A"), 2, 5)
			g.prism(Geo.place(Vector3.ZERO), 4, 0.02, 0.02, 0.2, Color("#4E9A44"))
		"leaf":
			g.box(Geo.place(Vector3.ZERO, 0.6), Vector3(0.16, 0.03, 0.08), c)
		"thorn":
			for k in 3:
				var a := TAU * k / 3.0
				g.prism(Transform3D(Basis(Vector3(cos(a), 0, sin(a)), 0.5), Vector3(cos(a) * 0.08, 0, sin(a) * 0.08)),
					4, 0.05, 0.0, 0.32, colour)
		"wisp":
			g.ball(Geo.place(Vector3.ZERO, 0.0, Vector3(1.0, 1.6, 1.0)), 0.1, c, 3, 6)
			g.ball(Geo.place(Vector3(0, -0.12, 0)), 0.05, c, 2, 5)
		"z":
			g.box(Geo.place(Vector3(0, 0.1, 0)), Vector3(0.22, 0.04, 0.04), c)
			g.box(Transform3D(Basis(Vector3.FORWARD, 0.9), Vector3.ZERO), Vector3(0.28, 0.04, 0.04), c)
			g.box(Geo.place(Vector3(0, -0.1, 0)), Vector3(0.22, 0.04, 0.04), c)
		_:
			g.ball(Geo.place(Vector3.ZERO), 0.1, c, 3, 6)
	return g.mesh()


## A law's mark on the ground: flat, thin and see-through, so it is read as
## ground (§21.12: "drawn as ground, not as effects").
func _add_ground(kind: String, colour: Color, rng: RandomNumberGenerator) -> void:
	var g := Geo.new()
	var half := Vector2(_grid) * 0.5
	var y := 0.035
	match kind:
		"cracks":
			for k in 26:
				var p := Vector3(rng.randf_range(-half.x, half.x), y, rng.randf_range(-half.y, half.y))
				var a := rng.randf() * TAU
				for j in 3:
					var d := Vector3(cos(a), 0, sin(a)) * rng.randf_range(0.25, 0.5)
					_line(g, p, p + d, 0.025, Color("#3A2A2A"))
					p += d
					a += rng.randf_range(-1.0, 1.0)
		"hexes":
			var r := 0.5
			for qx in range(-int(half.x) - 1, int(half.x) + 2):
				for qz in range(-int(half.y) - 1, int(half.y) + 2):
					var c := Vector3(qx * r * 1.5, y, (qz + (0.5 if qx % 2 != 0 else 0.0)) * r * 1.732)
					if absf(c.x) > half.x or absf(c.z) > half.y:
						continue
					for k in 6:
						var a0 := TAU * k / 6.0
						var a1 := TAU * (k + 1) / 6.0
						_line(g, c + Vector3(cos(a0), 0, sin(a0)) * r, c + Vector3(cos(a1), 0, sin(a1)) * r, 0.02, colour)
		"ice":
			for k in 7:
				var c := Vector3(rng.randf_range(-half.x + 1, half.x - 1), y, rng.randf_range(-half.y + 1, half.y - 1))
				g.ring(Geo.place(c), 0.0, rng.randf_range(0.6, 1.2), Color("#BFEFFF"), 16)
				_line(g, c + Vector3(-0.3, 0.005, -0.2), c + Vector3(0.25, 0.005, 0.15), 0.04, Color.WHITE)
		"spiral":
			for arm in 3:
				var prev := Vector3.ZERO
				for k in 40:
					var u := k / 40.0
					var a := arm * TAU / 3.0 + u * 7.0
					var r := 0.6 + u * half.length() * 0.8
					var p := Vector3(cos(a) * r, y, sin(a) * r)
					if k > 0:
						_line(g, prev, p, 0.03, colour)
					prev = p
		"panes":
			for k in 8:
				var c := Vector3(rng.randf_range(-half.x, half.x), 0.6, rng.randf_range(-half.y, half.y))
				g.box(Geo.place(c, rng.randf() * PI), Vector3(0.7, 1.0, 0.03), Color(colour, 1.0))
		"bands":
			for k in 3:
				var z := lerpf(-half.y, half.y, (k + 0.5) / 3.0)
				g.box(Geo.place(Vector3(0, y, z), 0.3), Vector3(half.x * 2.4, 0.01, 0.7),
					[Color("#9BF0D8"), Color("#B89CFF"), Color("#F7A6DA")][k])
		"arcs":
			for k in 6:
				var a3 := Vector3(rng.randf_range(-half.x, half.x), 0.4, rng.randf_range(-half.y, half.y))
				var b3 := a3 + Vector3(rng.randf_range(-2, 2), 0.0, rng.randf_range(-2, 2))
				var p := a3
				for j in 5:
					var q := a3.lerp(b3, (j + 1) / 5.0) + Vector3(0, rng.randf_range(-0.15, 0.25), 0)
					_line(g, p, q, 0.03, colour)
					p = q
		"rings", "ripples":
			for k in (3 if kind == "rings" else 6):
				var c := Vector3.ZERO if kind == "rings" else Vector3(rng.randf_range(-half.x, half.x), y,
					rng.randf_range(-half.y, half.y))
				var r0 := 1.4 + k * 1.3 if kind == "rings" else 0.4
				for j in (1 if kind == "rings" else 3):
					var r := r0 + j * 0.35
					g.ring(Geo.place(c + Vector3(0, y, 0)), r, r + 0.05, colour, 40)
		"shadows":
			for k in 10:
				var c := Vector3(rng.randf_range(-half.x, half.x), y, rng.randf_range(-half.y, half.y))
				g.ring(Geo.place(c), 0.0, 0.3, Color("#2A1E40"), 12)
		"threads":
			_threads = MeshInstance3D.new()
			_threads.material_override = WorldView.clear_material(0.9)
			_threads.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			_threads.name = "Threads"
			add_child(_threads)
			return
	var mi := MeshInstance3D.new()
	mi.mesh = g.mesh()
	mi.material_override = WorldView.clear_material(0.45 if kind != "panes" else 0.16)
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mi.name = "Ground_" + kind
	add_child(mi)


static func _line(g: Geo, a: Vector3, b: Vector3, w: float, colour: Color) -> void:
	var d := b - a
	if d.length() < 0.0001:
		return
	var side := Vector3(-d.z, 0, d.x).normalized() * w
	if absf(d.y) > absf(d.x) + absf(d.z):
		side = Vector3(w, 0, 0)
	g.quad(a - side, b - side, b + side, a + side, colour)


## Kinship's green thread between crew members who stand near each other.
func _link_crew(view: WorldView) -> void:
	var g := Geo.new()
	var crew := view._crew
	for i in crew.size():
		for j in range(i + 1, crew.size()):
			if not crew[i].visible or not crew[j].visible:
				continue
			var a := crew[i].position + Vector3(0, 0.45, 0)
			var b := crew[j].position + Vector3(0, 0.45, 0)
			if a.distance_to(b) > 3.0:
				continue
			var prev := a
			for k in 8:
				var u := (k + 1) / 8.0
				var p := a.lerp(b, u) + Vector3(0, sin(u * PI) * 0.25 + sin(_clock * 3.0 + u * 9.0) * 0.04, 0)
				_line(g, prev, p, 0.03, Color("#5CC46A"))
				prev = p
	_threads.mesh = g.mesh()
