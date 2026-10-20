class_name FxEvents
extends RefCounted
## What happened between two ticks, read from the simulation's state and
## drawn: a grab's loot rising as a number and coins, a hit, a crew member
## going down and being revived, a guard knocked out or alerted, the alarm
## going up, a pylon or a ward breaking, the Vault opening, and a crossing to
## another realm. Nothing here decides anything: each effect is a difference
## between two `RulebornReplay` readings, so a replay shows the same effects
## every time it is played (§24.1).
##
## Bursts are one-shot `CPUParticles3D` in the toon look's colours, each one
## draw call while it lives; numbers and marks go to `FxAnchors`; the camera
## shakes gently, never past §21.8's 4 pixels, and not at all with reduced
## motion (§20.8).

const BURST_SECONDS := 1.2

## Loot comes a little every tick while a crew member loads; it is shown
## gathered, at most every this many ticks a member.
const LOOT_TICKS := 12

static var _mesh_cache := {}

var view: WorldView
var _last := {}
var _first := true
## Loot gathered since each member's last pop-up, and that pop-up's tick.
var _gain := {}
var _gain_tick := {}


func _init(world_view: WorldView) -> void:
	view = world_view


## Forget the last reading: a new heist, or a replay opened afresh.
func reset() -> void:
	_last.clear()
	_first = true
	_gain.clear()
	_gain_tick.clear()


## Compare this tick's reading with the last, and show what changed. A
## reading taken after a jump back in time (a replay restarted) is a fresh
## start, not a burst of events.
func read(r: RulebornReplay) -> void:
	var now := _reading(r)
	if _first or int(now["tick"]) < int(_last.get("tick", 0)):
		_first = false
		_gain.clear()
		_gain_tick.clear()
		_last = now
		return
	if int(now["realm"]) != int(_last["realm"]) and int(_last["realm"]) >= 0:
		view.swoop()
		_last = now
		return
	_crew(r, now)
	_guards(r, now)
	_pieces(r, now)
	if int(now["alarm"]) > int(_last["alarm"]):
		view.anchors.flash = 1.0
		view.shake(0.8)
		Haptics.play("warning")
	view.anchors.alarm_share = clampf(float(now["alarm"]) / 6.0, 0.0, 1.0)
	_last = now


func _reading(r: RulebornReplay) -> Dictionary:
	var crew: Array[Array] = []
	for m: Dictionary in r.crew():
		crew.append([int(m["carried"]), int(m["health"]), str(m["standing"])])
	var guards: Array[Array] = []
	for g: Dictionary in r.guards():
		guards.append([bool(g["down"]), str(g["state"])])
	var pylons: Array[bool] = []
	for p: Dictionary in r.pylons():
		pylons.append(bool(p["standing"]))
	var wards: Array[bool] = []
	for w: Dictionary in r.wards():
		wards.append(bool(w["live"]))
	var v := r.vault()
	return {"tick": r.tick(), "realm": r.realm_code(), "alarm": r.alarm(), "crew": crew, "guards": guards,
		"pylons": pylons, "wards": wards, "open": bool(v.get("open", false)), "health": int(v.get("health", 0))}


func _crew(r: RulebornReplay, now: Dictionary) -> void:
	var was: Array = _last["crew"]
	var crew := r.crew()
	for i in mini(was.size(), (now["crew"] as Array).size()):
		var a: Array = was[i]
		var b: Array = now["crew"][i]
		# Pop-ups rise from above the head and a little to one side, so a
		# number never sits on the figure it is about.
		var head := float(view._crew[i].get_meta("head", 1.0)) if i < view._crew.size() else 1.0
		var ground := view.world_at(crew[i]["at"])
		var at := ground + Vector3(0.35, head + 0.45, 0)
		if int(b[0]) > int(a[0]):
			_gain[i] = int(_gain.get(i, 0)) + int(b[0]) - int(a[0])
		var gained := int(_gain.get(i, 0))
		if gained > 0 and (int(now["tick"]) - int(_gain_tick.get(i, -999)) >= LOOT_TICKS or int(b[0]) <= int(a[0])):
			_gain[i] = 0
			_gain_tick[i] = int(now["tick"])
			view.anchors.pop(at, "+%d" % gained, FxSkin.GOLD, "coin")
			view.looted.emit(view.get_global_transform() * view.camera.unproject_position(at), gained)
			burst(ground + Vector3(0, head * 0.7, 0), Color("#F2B43C"), 6, 2.2, "coin")
		if int(b[1]) < int(a[1]):
			view.anchors.pop(at, "-%d" % (int(a[1]) - int(b[1])), FxSkin.ALARM_ON_DARK)
			burst(ground + Vector3(0, head * 0.6, 0), Color("#FFFFFF"), 5, 1.6)
			view.shake(0.3)
		if str(a[2]) == "Active" and str(b[2]) != "Active" and str(b[2]) not in ["Out", "Gone"]:
			burst(ground + Vector3(0, 0.5, 0), Color("#FFE27A"), 12, 2.6, "star")
			view.shake(0.7)
		elif str(a[2]) != "Active" and str(b[2]) == "Active":
			view.anchors.pop(at, "♥", FxSkin.SUCCESS)
			burst(ground + Vector3(0, 0.4, 0), FxSkin.SUCCESS, 14, 2.0)
			ring(ground + Vector3(0, 0.05, 0), FxSkin.SUCCESS, 1.4)


func _guards(r: RulebornReplay, now: Dictionary) -> void:
	var was: Array = _last["guards"]
	var guards := r.guards()
	for i in mini(was.size(), (now["guards"] as Array).size()):
		var a: Array = was[i]
		var b: Array = now["guards"][i]
		var ghead := float(view._guards[i].get_meta("head", 1.2)) if i < view._guards.size() else 1.2
		var at := view.world_at(guards[i]["at"]) + Vector3(0, ghead * 0.7, 0)
		if not bool(a[0]) and bool(b[0]):
			burst(at, Color("#FFE27A"), 16, 3.0, "star")
			view.anchors.pop(at + Vector3(0, 0.5, 0), "KO", Color("#FFE27A"), "star")
			view.shake(0.9)
		if str(b[1]) == "Alerted" and str(a[1]) != "Alerted":
			view.anchors.flash = maxf(view.anchors.flash, 0.7)
			ring(view.world_at(guards[i]["at"]) + Vector3(0, 0.05, 0), FxSkin.ALARM, 1.8)


func _pieces(r: RulebornReplay, now: Dictionary) -> void:
	var pylons := r.pylons()
	var was: Array = _last["pylons"]
	for i in mini(was.size(), (now["pylons"] as Array).size()):
		if bool(was[i]) and not bool(now["pylons"][i]):
			var at := view.world_at(pylons[i]["at"]) + Vector3(0, 0.8, 0)
			var colour: Color = Palette.SCHOOL.get(str(pylons[i].get("school", "")), Palette.STONE)
			burst(at, colour, 22, 4.0, "shard")
			ring(at - Vector3(0, 0.75, 0), colour, 2.6)
			view.shake(1.0)
	var wards := r.wards()
	var live: Array = _last["wards"]
	for i in mini(live.size(), (now["wards"] as Array).size()):
		if bool(live[i]) and not bool(now["wards"][i]):
			var at := view.world_at(wards[i]["at"]) + Vector3(0, 0.5, 0)
			burst(at, Color("#BFEFFF"), 12, 2.4, "shard")
			view.shake(0.4)
	var v := r.vault()
	if v.has("at"):
		var at := view.world_at(v["at"]) + Vector3(0, 0.9, 0)
		if bool(now["open"]) and not bool(_last["open"]):
			burst(at, Color("#F2B43C"), 30, 4.5, "coin")
			ring(at - Vector3(0, 0.85, 0), Color("#FFE27A"), 3.0)
			view.shake(1.0)
			# The crew beside it cheer for a moment (the design's celebrate).
			for c: Node3D in view._crew:
				if c.position.distance_to(at) < 3.0:
					c.set_meta("cheer", 90)
		elif int(now["health"]) < int(_last["health"]) and int(now["tick"]) % 6 == 0:
			burst(at, Color("#D9D2FF"), 4, 1.6, "shard")


## A one-shot spray of `count` bits from `at`: coins, stars or shards.
func burst(at: Vector3, colour: Color, count: int, speed: float, kind := "") -> void:
	if not WorldView.rendering_3d():
		return
	var p := CPUParticles3D.new()
	p.one_shot = true
	p.emitting = false
	p.amount = maxi(1, count if not Settings.reduced_motion else count / 3)
	p.lifetime = BURST_SECONDS * 0.8
	p.explosiveness = 0.95
	p.direction = Vector3.UP
	p.spread = 70.0
	p.initial_velocity_min = speed * 0.5
	p.initial_velocity_max = speed
	p.gravity = Vector3(0, -9.0, 0)
	p.angular_velocity_min = -360.0
	p.angular_velocity_max = 360.0
	p.scale_amount_min = 0.7
	p.scale_amount_max = 1.2
	var fade := Gradient.new()
	fade.set_color(0, Color(colour, 1.0))
	fade.set_color(1, Color(colour, 0.0))
	fade.add_point(0.75, Color(colour, 1.0))
	p.color_ramp = fade
	p.mesh = _bit(kind)
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.vertex_color_use_as_albedo = true
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	p.material_override = mat
	p.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	p.position = at
	view.world.add_child(p)
	p.emitting = true
	view.get_tree().create_timer(BURST_SECONDS + 0.4).timeout.connect(p.queue_free)


## A flat ring that spreads on the ground and fades: a shock, a revive.
func ring(at: Vector3, colour: Color, reach: float) -> void:
	if not WorldView.rendering_3d():
		return
	var g := Geo.new()
	g.ring(Geo.place(Vector3.ZERO), 0.82, 1.0, colour, 40)
	var mi := MeshInstance3D.new()
	mi.mesh = g.mesh()
	var mat := WorldView.clear_material(0.8)
	mi.material_override = mat
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mi.position = at + Vector3(0, 0.06, 0)
	mi.scale = Vector3.ONE * 0.2
	view.world.add_child(mi)
	var tw := view.create_tween()
	tw.set_parallel(true)
	tw.tween_property(mi, "scale", Vector3.ONE * reach, 0.7).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tw.tween_method(func(a: float) -> void: mat.set_shader_parameter("opacity", a), 0.8, 0.0, 0.7)
	tw.chain().tween_callback(mi.queue_free)


static func _bit(kind: String) -> Mesh:
	if _mesh_cache.has(kind):
		return _mesh_cache[kind]
	var m: Mesh
	match kind:
		"coin":
			var c := CylinderMesh.new()
			c.top_radius = 0.09
			c.bottom_radius = 0.09
			c.height = 0.03
			c.radial_segments = 8
			c.rings = 1
			m = c
		"star":
			var s := PrismMesh.new()
			s.size = Vector3(0.16, 0.16, 0.05)
			m = s
		"shard":
			var b := PrismMesh.new()
			b.size = Vector3(0.2, 0.22, 0.12)
			m = b
		_:
			var q := SphereMesh.new()
			q.radius = 0.06
			q.height = 0.12
			q.radial_segments = 6
			q.rings = 3
			m = q
	_mesh_cache[kind] = m
	return m
