class_name LawFx
extends Node3D
## §21.7's laws on screen: "Each law has a world signature (how its realm
## looks) and a movement signature (how characters move). Both are always on
## while the law is woven, so an observant player can read an island without
## opening a menu."
##
## `attach` builds every woven law's world signature over a heist's realm,
## read from the simulation (`RulebornReplay.pylons()`: each pylon's law and
## school; the grid from `size()`, `features()`, `heights()`), crowns each
## pylon with its school's shape (§21.2), and draws §21.7's harmony threads,
## dissonance lines and chord triangles between the pylons. `sync(tick)`
## moves all of it from the heist's ticks, so a replay looks the same every
## time it is played. `gait(law)` gives a character controller each law's
## movement signature as numbers (LawFxGait).
##
## Every signature is made of §21.3's cheap pieces: motes (one mesh of
## camera-facing quads per layer, moved in law_fx_mote), ground marks
## (law_fx_decal), solid pieces moved in the vertex stage (law_fx_solid,
## law_fx_glass), the realm's own light, and a screen-space tint on one quad
## before the camera — never full-screen post-processing. Nothing is drawn
## over what a player must read: ground marks sit under the guard's sight
## overlay, and motes are small and see-through.

## Ticks a second (sim::TICKS_PER_SECOND).
const TPS := 30.0
## §7.10's 24 laws that ship at launch, in content/laws.json's order.
const LAUNCH: Array[String] = ["bounce", "half_gravity", "frictionless", "inward_pull", "brittle_stone", "glass",
	"density", "honeycomb", "slow_rivers", "stillness", "delay", "haste", "glowing_dark", "aurora",
	"chain_lightning", "static", "bloom", "kinship", "thorns", "regrowth", "whispers", "echoes", "sleepwalk",
	"soul_swap"]
## §7.5's paradoxes.
const PARADOXES: Array[String] = ["reversal", "twin_suns", "unmaking"]
## Where an effect sits among the see-through things: ground marks under the
## sight overlay (render priority 0), motes and clear pieces over it.
const UNDER := -2
const OVER := 1

static var _shaders := {}

## The realm the signatures stand on.
var site: LawFxSite
## The view it is attached to, whose light and camera Day and night, Glowing
## dark and the tint use; null in a preview with its own camera.
var view: WorldView
var camera: Camera3D
var sun: DirectionalLight3D
var environment: Environment
## Each law's signature, by law id; the links and crowns apart.
var signatures := {}
var crowns: Node3D
var links: Node3D
## The paradox woven in the universe, if any (§7.5): its overlay.
var paradox := ""
## The heist's seconds at the last sync.
var seconds := 0.0

var _clocked: Array[ShaderMaterial] = []
var _hooks: Array[Callable] = []
var _watchers: Array[Callable] = []
var _followers: Array[Dictionary] = []
var _tint: MeshInstance3D
var _light := {}


## Every woven law of `replay`'s realm drawn over `v`'s world: under T5's
## `effects` node when the view has one, else under its world.
static func attach(v: WorldView, replay: RulebornReplay) -> LawFx:
	var fx := LawFx.new()
	fx.view = v
	fx.camera = v.camera
	fx.sun = v.sun
	fx.environment = v.environment
	var hook: Variant = v.get("effects")
	var parent: Node3D = hook if hook is Node3D else v.world
	parent.add_child(fx)
	fx.build(LawFxSite.from_replay(replay))
	return fx


static func _shader(name: String) -> Shader:
	if not _shaders.has(name):
		_shaders[name] = load("res://world/law_fx_%s.gdshader" % name)
	return _shaders[name]


## Build every signature over `s`: one per woven law, the crowns, the links.
func build(s: LawFxSite) -> void:
	for c in get_children():
		remove_child(c)
		c.queue_free()
	_clocked.clear()
	_hooks.clear()
	_watchers.clear()
	_followers.clear()
	signatures.clear()
	_restore_light()
	site = s
	crowns = Node3D.new()
	crowns.name = "Crowns"
	add_child(crowns)
	for p: Dictionary in site.pylons:
		var law: String = p["law"]
		if not signatures.has(law):
			var sig := Node3D.new()
			sig.name = law
			add_child(sig)
			signatures[law] = sig
			LawFxSigns.build(self, sig, law)
		var mat := solid_material(4, 0.6)
		mat.set_shader_parameter("pulse", 0.6)
		var cap := LawFxBatch.new(LawFxBatch.Kind.SOLIDS)
		var top: Vector3 = p["at"] + Vector3(0, LawFxCrown.HEIGHT, 0)
		cap.solid(LawFxCrown.mesh(str(p["school"])), Transform3D(Basis.IDENTITY.scaled(Vector3.ONE * 1.5), top), top,
			RealmKit.jitter(p["tile"], 9))
		layer(crowns, cap, mat, true)
	links = Node3D.new()
	links.name = "Links"
	add_child(links)
	LawFxLinks.build(self, links)
	if paradox != "":
		LawFxLinks.paradox(self, paradox)
	sync(seconds * TPS)


## A law's signature on its own (the law card's and Weaving's preview).
func build_one(s: LawFxSite, law: String) -> void:
	build(s)
	for k: String in signatures.keys():
		(signatures[k] as Node3D).visible = k == law


## §7.5: the universe's paradox, over every realm (Reversal, Twin suns,
## Unmaking), or "" for none.
func set_paradox(id: String) -> void:
	paradox = id
	if site != null:
		build(site)


## Move everything to the heist's tick `tick` (fractions draw between ticks).
func sync(tick: float) -> void:
	seconds = tick / TPS
	for m: ShaderMaterial in _clocked:
		m.set_shader_parameter("t", seconds)
	for h: Callable in _hooks:
		h.call(seconds)


## What the heist shows this tick: each pylon standing or broken (§7.1:
## "breaking the pylon ends the law": its signature fades away), and every
## piece that follows a character (Soul swap's wisps, Kinship's threads)
## moved to where the simulation puts it.
func sync_world(replay: RulebornReplay) -> void:
	var up := {}
	for p: Dictionary in replay.pylons():
		up[str(p["law"])] = bool(up.get(str(p["law"]), false)) or bool(p["standing"])
	for law: String in signatures:
		var on: bool = up.get(law, true)
		for mi: MeshInstance3D in (signatures[law] as Node3D).find_children("*", "MeshInstance3D", true, false):
			var m := mi.material_override as ShaderMaterial
			while m != null:
				m.set_shader_parameter("strength", 1.0 if on else 0.0)
				m = m.next_pass as ShaderMaterial
	var crew: Array = []
	for c: Dictionary in replay.crew():
		if replay.has_landed() and str(c["standing"]) == "Active":
			crew.append(site.world_at(c["at"]))
	var guards: Array = []
	for g: Dictionary in replay.guards():
		if not g["down"]:
			guards.append(site.world_at(g["at"]))
	for f: Dictionary in _followers:
		var at: Array = crew if f["who"] == "crew" else (guards if f["who"] == "guards" else crew + guards)
		var nodes: Array = f["nodes"]
		while nodes.size() < at.size():
			var mi := MeshInstance3D.new()
			mi.mesh = f["mesh"]
			mi.material_override = f["material"]
			mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			mi.extra_cull_margin = 4.0
			(f["sig"] as Node3D).add_child(mi)
			nodes.append(mi)
		for k in nodes.size():
			var n := nodes[k] as MeshInstance3D
			n.visible = k < at.size()
			if n.visible:
				n.position = at[k]
	for w: Callable in _watchers:
		w.call(crew, guards)


## Something that redraws from the characters' places each tick: called
## with the crew's and the guards' world positions.
func watch(hook: Callable) -> void:
	_watchers.append(hook)


## `batch` (built round the origin) drawn on every character `who` names
## ("crew", "guards" or "all"), moved with them by `sync_world`.
func follow(sig: Node3D, batch: LawFxBatch, mat: ShaderMaterial, who: String) -> void:
	_clocked.append(mat)
	_followers.append({"sig": sig, "mesh": batch.mesh(), "material": mat, "who": who, "nodes": [],
		"triangles": batch.triangles})


## A layer of `sig`: `batch`'s mesh drawn in `mat`, moved by the clock.
func layer(sig: Node3D, batch: LawFxBatch, mat: ShaderMaterial, outlined := false) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = batch.mesh()
	mi.material_override = mat
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mi.set_meta("triangles", batch.triangles)
	# Motes and moving pieces leave their mesh's bounds, so the bounds are
	# the realm's, with the sky above it.
	var h := site.half() if site != null else Vector2(8, 8)
	mi.custom_aabb = AABB(Vector3(-h.x - 4, -4, -h.y - 4), Vector3(h.x * 2 + 8, 14, h.y * 2 + 8))
	if outlined:
		var ink := ShaderMaterial.new()
		ink.shader = _shader("ink")
		_copy_motion(mat, ink)
		mat.next_pass = ink
		_clocked.append(ink)
	sig.add_child(mi)
	_clocked.append(mat)
	return mi


## Something a signature moves itself each sync, from the heist's seconds.
func every(hook: Callable) -> void:
	_hooks.append(hook)


func mote_material(glow := 0.35, pace := 1.0) -> ShaderMaterial:
	var m := ShaderMaterial.new()
	m.shader = _shader("mote")
	m.set_shader_parameter("glow", glow)
	m.set_shader_parameter("pace", pace * _pace())
	m.render_priority = OVER
	return m


func decal_material(pattern: int, a: Color, b := Color("#1A0C14"), pace := 1.0) -> ShaderMaterial:
	var m := ShaderMaterial.new()
	m.shader = _shader("decal")
	m.set_shader_parameter("pattern", pattern)
	m.set_shader_parameter("colour_a", a)
	m.set_shader_parameter("colour_b", b)
	m.set_shader_parameter("pace", pace * _pace())
	m.set_shader_parameter("focus", Vector2(site.heart.x, site.heart.z) if site != null else Vector2.ZERO)
	m.render_priority = UNDER
	return m


func solid_material(motion: int, amount := 1.0, pace := 1.0) -> ShaderMaterial:
	var m := ShaderMaterial.new()
	m.shader = _shader("solid")
	m.set_shader_parameter("motion", motion)
	m.set_shader_parameter("amount", amount)
	m.set_shader_parameter("pace", pace * _pace())
	return m


func glass_material(edge: Color, motion := 0, amount := 1.0, fill := 0.12) -> ShaderMaterial:
	var m := ShaderMaterial.new()
	m.shader = _shader("glass")
	m.set_shader_parameter("edge", edge)
	m.set_shader_parameter("motion", motion)
	m.set_shader_parameter("amount", amount)
	m.set_shader_parameter("fill", fill)
	m.set_shader_parameter("pace", _pace())
	m.render_priority = OVER
	return m


## A screen-space tint (§21.3): one quad just before the camera, darkening
## the screen's edges toward `colour` by `edge` and washing all of it by
## `wash`. Nothing of the world is re-rendered for it.
func thread_material(width := 0.045) -> ShaderMaterial:
	var m := ShaderMaterial.new()
	m.shader = _shader("thread")
	m.set_shader_parameter("width", width)
	m.set_shader_parameter("pace", _pace())
	m.render_priority = OVER
	return m


func tint(colour: Color, edge: float, wash := 0.0) -> ShaderMaterial:
	if camera == null:
		return null
	if _tint == null:
		_tint = MeshInstance3D.new()
		var q := QuadMesh.new()
		q.size = Vector2(2, 2)
		_tint.mesh = q
		_tint.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		_tint.extra_cull_margin = 1000.0
		var m := ShaderMaterial.new()
		m.shader = _shader("tint")
		m.render_priority = 100
		_tint.material_override = m
		camera.add_child(_tint)
		_clocked.append(m)
		tree_exiting.connect(_tint.queue_free)
	var mat := _tint.material_override as ShaderMaterial
	mat.set_shader_parameter("colour", colour)
	mat.set_shader_parameter("edge", edge)
	mat.set_shader_parameter("wash", wash)
	return mat


## The realm's light, dimmed or turned by a law (Glowing dark, Day and
## night): the sun's and the ambient's strength as built, kept to restore.
func light() -> Dictionary:
	if _light.is_empty() and sun != null and environment != null:
		_light = {"sun": sun.light_energy, "sun_colour": sun.light_color, "ambient": environment.ambient_light_energy,
			"ambient_colour": environment.ambient_light_color}
	return _light


func _restore_light() -> void:
	if _light.is_empty() or sun == null or environment == null:
		return
	sun.light_energy = _light["sun"]
	sun.light_color = _light["sun_colour"]
	environment.ambient_light_energy = _light["ambient"]
	environment.ambient_light_color = _light["ambient_colour"]
	_light = {}


func _exit_tree() -> void:
	_restore_light()


## Haste quickens every signature's clock and Stillness all but stops it
## (§21.7: "Clouds race overhead; plants sway quickly", "not a leaf moves").
func _pace() -> float:
	if site == null:
		return 1.0
	var p := 1.0
	for d: Dictionary in site.pylons:
		if d["law"] == "haste":
			p *= 1.6
		elif d["law"] == "stillness":
			p *= 0.35
	return p


func _copy_motion(from: ShaderMaterial, to: ShaderMaterial) -> void:
	for k: String in ["motion", "amount", "pace"]:
		to.set_shader_parameter(k, from.get_shader_parameter(k))


## A signature's cost (§21.3's budgets): its triangles and draw calls, every
## layer counted, outlines as a second pass.
func budget(law: String) -> Dictionary:
	var tris := 0
	var draws := 0
	var sig: Node3D = signatures.get(law)
	if sig == null:
		return {"triangles": 0, "draws": 0}
	for mi: MeshInstance3D in sig.find_children("*", "MeshInstance3D", true, false):
		if mi.mesh == null:
			continue
		var n := int(mi.get_meta("triangles", 0))
		var passes := 2 if mi.material_override != null and mi.material_override.next_pass != null else 1
		tris += n * passes
		draws += passes
	return {"triangles": tris, "draws": draws}


## §21.7's movement signature of `law` as numbers a character controller
## applies (LawFxGait documents each).
static func gait(law: String) -> Dictionary:
	return LawFxGait.of(law)


## A pylon's crown: its school's shape (§21.2), glowing; for PieceKit.
static func crown(school: String) -> ArrayMesh:
	return LawFxCrown.mesh(school)
