class_name FxMotion
extends RefCounted
## How `WorldView`'s figures move between the simulation's ticks: the
## stand-ins' bobs, squashes, leans and swinging limbs, and a character
## model's clips, each from what the simulation says its actor is doing.

## The simulation's water surface (`RulebornReplay.surfaces`).
const WATER := 2


## Gentle physical humour (§21.1): a figure on the move bobs and squashes
## with its steps — tiptoeing crouched, bounding at a run — and one standing
## still breathes; one that is down lies on its back. Its time is the
## heist's ticks, so a replay moves the same every time it is played. The
## laws running bend how everyone moves (§21.7's movement signatures).
static func animate(view: WorldView, ticks: float) -> void:
	var t := ticks / WorldView.TPS
	for i in view._crew.size():
		bounce(view, view._crew[i], "c%d" % i, t + i * 0.37)
	for i in view._guards.size():
		bounce(view, view._guards[i], "g%d" % i, t + i * 0.61)


static func bounce(view: WorldView, node: Node3D, key: String, t: float) -> void:
	var rig := node.get_node_or_null("Rig") as Node3D
	if rig == null:
		return
	var feet := node.get_node_or_null("Feet") as Node3D
	if node.get_meta("model", false):
		play_model(view, node, rig, key, t)
		return
	if node.get_meta("down", false):
		rig.rotation = Vector3(-PI / 2.0, 0, 0)
		rig.position = Vector3(0, 0.22, 0)
		rig.scale = Vector3.ONE
		if feet != null:
			feet.visible = false
		limbs(rig, null, 0.0, 0.0, 0.0)
		return
	if feet != null:
		feet.visible = true
	var moving := _moving(view, key)
	var gait := str(node.get_meta("gait", "Walk"))
	var move := movement(view.gait, moving, t)
	if moving:
		var rate: float = (2.2 if gait == "Walk" else (1.6 if gait == "Crouch" else 3.0)) * move["rate"]
		var step := absf(sin(t * TAU * rate))
		var lift: float = (0.07 if gait != "Crouch" else 0.03) * move["hop"]
		rig.position = Vector3(0, step * lift + move["float"], 0)
		var squat := 0.82 if gait == "Crouch" else 1.0
		rig.scale = Vector3(1.0 + 0.05 * (1.0 - step), (0.94 + 0.08 * step) * squat, 1.0 + 0.05 * (1.0 - step))
		rig.rotation = Vector3(-0.12 if gait == "Run" else (-0.05 if gait == "Crouch" else 0.0), 0,
			sin(t * TAU * rate * 0.5) * 0.06 + move["lean"])
		var swing := 1.0 if gait == "Run" else (0.35 if gait == "Crouch" else 0.7)
		limbs(rig, feet, sin(t * TAU * rate * 0.5) * swing, 0.08 * swing, move["float"])
	else:
		rig.position = Vector3(0, move["float"], 0)
		rig.scale = Vector3(1.0, 1.0 + 0.02 * sin(t * TAU * 0.4), 1.0)
		rig.rotation = Vector3(0, 0, move["lean"] * 0.4)
		limbs(rig, feet, sin(t * TAU * 0.4) * 0.08, 0.0, move["float"])


## A character model plays the clip for what its actor is doing; the rig
## only lays it down when it is down.
static func play_model(view: WorldView, node: Node3D, rig: Node3D, key: String, t := 0.0) -> void:
	var down: bool = node.get_meta("down", false)
	var moving := _moving(view, key)
	var move := movement(view.gait, moving, t)
	# Knocked out, a model lies on its back whatever its kind's "ko" pose, so
	# who is out reads from above at a glance; else the laws bend its walk
	# too: it leans, sways and floats as they say.
	rig.rotation = Vector3(-PI / 2.0, 0, 0) if down else Vector3(0, 0, float(move["lean"]))
	rig.position = Vector3(0, 0.25, 0) if down else Vector3(0, float(move["float"]), 0)
	var gait := str(node.get_meta("gait", "Walk"))
	var clip := model_clip(down, moving, gait, node.get_meta("carrying", false), int(node.get_meta("hit", 0)) > 0)
	# Where it walks, by the simulation's grid: wading through water, climbing
	# between height levels.
	if moving and not down:
		var ground := terrain(view, key)
		if ground != "":
			clip = ground
	if int(node.get_meta("cheer", 0)) > 0:
		node.set_meta("cheer", int(node.get_meta("cheer", 0)) - 1)
		if not down and not moving:
			clip = "celebrate"
	# A screen may hold a pose (the result's celebration) while it stands.
	if not down and not moving and str(node.get_meta("pose", "")) != "":
		clip = str(node.get_meta("pose", ""))
	if int(node.get_meta("hit", 0)) > 0:
		node.set_meta("hit", int(node.get_meta("hit", 0)) - 1)
	# Crouching is a slow walk; a run is quick.
	var speed: float = ({"Crouch": 0.6, "Run": 1.2}.get(gait, 1.0) if moving else 1.0) * float(view.gait["tempo"])
	var figure := rig.get_node_or_null("Figure")
	if figure != null and figure.has_method("play") and node.get_meta("clip", "") != clip:
		node.set_meta("clip", clip)
		figure.call("play", StringName(clip), speed)


## The design's clip for what the simulation says an actor is doing: "ko"
## when down, "hit" as a blow lands, "carry" moving with loot, "run" at a run,
## "walk" walking or crouched, else "idle".
static func model_clip(down: bool, moving: bool, gait: String, carrying: bool, struck: bool) -> String:
	if down:
		return "ko"
	if struck:
		return "hit"
	if not moving:
		return "idle"
	if carrying:
		return "carry"
	return "run" if gait == "Run" else "walk"


## Arms swing against the steps and feet step out in turn: `phase` is the
## stride's swing (-1 to 1), `stride` how far a foot steps, `lift` how far
## the figure floats (feet rise with it).
static func limbs(rig: Node3D, feet: Node3D, phase: float, stride: float, lift: float) -> void:
	var figure := rig.get_node_or_null("Figure") as Node3D
	if figure != null:
		var l := figure.get_node_or_null("ArmL") as Node3D
		var r := figure.get_node_or_null("ArmR") as Node3D
		if l != null and r != null:
			l.rotation = Vector3(phase * 0.9, 0, -0.15)
			r.rotation = Vector3(-phase * 0.9, 0, 0.15)
	if feet == null:
		return
	feet.position.y = lift
	var fl := feet.get_node_or_null("FootL") as Node3D
	var fr := feet.get_node_or_null("FootR") as Node3D
	if fl != null and fr != null:
		fl.position.z = ActorBuilder.HIP.z - phase * stride / maxf(0.01, feet.scale.z)
		fr.position.z = ActorBuilder.HIP.z + phase * stride / maxf(0.01, feet.scale.z)
		fl.position.y = maxf(0.0, phase) * stride * 0.6
		fr.position.y = maxf(0.0, -phase) * stride * 0.6


## Whether the actor `key` moved between its last two ticks.
static func _moving(view: WorldView, key: String) -> bool:
	return view._from.has(key) and view._to.has(key) \
		and (view._from[key] as Vector3).distance_to(view._to[key]) > 0.001


## The laws' gait (`LawFxGait`) as the stand-in's step: the `rate` of its
## steps, its `hop` against the plain walk's, how far it `float`s and its
## `lean`, swaying where a law sways. Reduced motion keeps the steps plain.
static func movement(g: Dictionary, moving: bool, t: float) -> Dictionary:
	var neutral: Dictionary = LawFxGait.NEUTRAL
	var out := {"rate": float(g["tempo"]), "hop": float(g["bounce"]) / float(neutral["bounce"]),
		"float": float(g["float"]) * 0.15 * (0.6 + 0.4 * sin(t * 2.0)),
		"lean": (float(g["lean"]) if moving else 0.0) + float(g["sway"]) * sin(t * 3.0)}
	if Settings.reduced_motion:
		out["hop"] = minf(float(out["hop"]), 1.0)
		out["lean"] = 0.0
	return out


## "wade" for an actor walking on a water tile, "climb" for one going between
## height levels this tick, else "": read from the grid the simulation gives.
static func terrain(view: WorldView, key: String) -> String:
	if not view._to.has(key) or not view._from.has(key):
		return ""
	var a: Vector3 = view._from[key]
	var b: Vector3 = view._to[key]
	if absf(b.y - a.y) > 0.01:
		return "climb"
	var tile := Vector2i(floori(b.x + view._size.x / 2.0), floori(b.z + view._size.y / 2.0))
	var i := tile.y * view._size.x + tile.x
	if i >= 0 and i < view._surfaces.size() and view._surfaces[i] == WATER:
		return "wade"
	return ""
