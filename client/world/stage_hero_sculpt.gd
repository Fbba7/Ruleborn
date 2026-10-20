class_name StageHeroSculpt
extends RefCounted
## A stand-in for each character until the design's sculpts are exported
## (§21.6): the kind's body and size, its colours, its school's shape as a
## marking, and §21.6's cuteness rules — a big head, eyes set low and wide,
## short limbs and rounded tips. A form ("hush", "spark", "echo") changes
## its pattern, glow and one accessory in its note's colour; the guard form
## adds the sash and the small lantern. Built one unit tall, facing +Z, as
## one vertex-coloured mesh inside §21.3's 3,000 to 6,000 triangles.

## The launch notes' colours, by name, as the design's character sheets
## set them (Featherkin_dc.html `NOTE`).
const NOTE := {"hush": Color("#8C6CF0"), "spark": Color("#F07A3C"), "echo": Color("#E05CB4")}
const SKIN := Color("#F2C9A8")
const WHITE := Color("#FFFDF6")
const INK := Color("#1A0C14")
## A glowing white: alpha 0 lights it fully in its own colour.
const GLINT := Color(1.0, 1.0, 1.0, 0.0)

static var _cache := {}

var g := Geo.new()
var kind := ""
var look := ""
var mark_school := "motion"
## The colour a form takes its pattern and accessory in, or none.
var note := Color(0, 0, 0, 0)


## The stand-in mesh for a kind in a look, made once and shared.
static func of(for_kind: String, for_look := "") -> ArrayMesh:
	var cache_key := for_kind + "/" + for_look
	if not _cache.has(cache_key):
		var s := StageHeroSculpt.new(for_kind, for_look)
		_cache[cache_key] = s.build()
	return _cache[cache_key]


func _init(for_kind: String, for_look: String) -> void:
	kind = for_kind
	look = for_look
	mark_school = StageHeroFigure.school(kind)
	note = NOTE.get(look, Color(0, 0, 0, 0))


func build() -> ArrayMesh:
	match kind:
		"featherkin":
			_owl(Color("#F4D77E"), Color("#FFF3D2"), Color("#E8A23A"), true)
		"hourkeeper":
			_owl(Color("#6FB2DA"), Color("#F4F8FF"), Color("#D9A548"), false)
		"skyskipper":
			_skyskipper()
		"rambler":
			_rambler()
		"glass_golem":
			_golem()
		"quarryback":
			_quarryback()
		"prism_mite":
			_mite()
		"tidewalker":
			_otter()
		"stillwatch":
			_heron()
		"emberling":
			_emberling()
		"stormhound":
			_hound()
		"sparkwright":
			_panda()
		"mossbear":
			_bear()
		"bloomling":
			_bloomling()
		"rootrunner":
			_rootrunner()
		"echoplate":
			_armour()
		"lantern_wisp":
			_wisp()
		"soulmender":
			_moth()
		"egg":
			_egg()
		"shell":
			_shell()
		"archivist", "tinkerer", "gardener", "wanderer", "chronicler", "lamplighter":
			_sage()
		_:
			_chibi(Palette.SCHOOL.get(mark_school, Palette.MOTION), WHITE)
	if look == "guard":
		_guard()
	return g.mesh()


# --- The kinds ------------------------------------------------------------


func _owl(body: Color, face: Color, beak: Color, cape: bool) -> void:
	var c := Vector3(0, 0.44, 0)
	_ball(c, 0.36, body, Vector3(1.0, 1.12, 0.95))
	_ball(Vector3(0, 0.25, 0.2), 0.2, _tint(face), Vector3(1.0, 1.1, 0.6))
	for s: float in [-1.0, 1.0]:
		var dir := Vector3(s * sin(0.36), 0, cos(0.36))
		g.ball(Transform3D(Basis.looking_at(-dir, Vector3.UP) * Basis.from_scale(Vector3(1.0, 1.05, 0.35)),
			Vector3(0, 0.55, 0.0) + dir * 0.31), 0.15, face, 8, 14)
	_eyes(Vector3(0, 0.55, 0.0), 0.37, 0.36, 0.0, 0.1, Color("#E8962A"))
	_cone(Vector3(0, 0.49, 0.32), Vector3(0, 0.42, 0.4), 0.035, beak)
	for s: float in [-1.0, 1.0]:
		_cone(Vector3(s * 0.17, 0.78, 0.02), Vector3(s * 0.27, 0.95, 0.0), 0.06, body.darkened(0.08))
		_ball(Vector3(s * 0.34, 0.4, -0.04), 0.2, body.darkened(0.12), Vector3(0.32, 1.0, 0.8), Vector3(0, 0, s * 0.25))
		_ball(Vector3(s * 0.1, 0.05, 0.12), 0.06, beak, Vector3(1.0, 0.6, 1.4))
	if cape:
		_ball(Vector3(0, 0.42, -0.2), 0.3, _tint(body.darkened(0.15)), Vector3(1.2, 1.05, 0.45))
		_strap(Vector3(0.2, 0.62, 0.22), Vector3(-0.22, 0.26, 0.25), Color("#8A5A32"))
		_ball(Vector3(-0.3, 0.22, 0.12), 0.09, Color("#B07A4F"), Vector3(1.0, 0.9, 0.6))
		_mark(Vector3(0, 0.76, 0.27), 0.05)
	else:
		# The hourglass belly.
		_cone(Vector3(0, 0.12, 0.33), Vector3(0, 0.27, 0.33), 0.08, Color("#D9A548"), false)
		_cone(Vector3(0, 0.42, 0.33), Vector3(0, 0.27, 0.33), 0.08, Color("#D9A548"), false)
		_ball(Vector3(0, 0.2, 0.36), 0.045, Color(1.0, 0.85, 0.5, 0.4))
		_mark(Vector3(0, 0.76, 0.27), 0.05)
		_lantern(Vector3(0.36, 0.2, 0.12), 0.06)


func _skyskipper() -> void:
	var gold := Color("#F6D774")
	var head := Vector3(0, 0.56, 0.02)
	_ball(Vector3(0, 0.26, 0), 0.18, gold, Vector3(1.0, 1.15, 0.9))
	_ball(Vector3(0, 0.24, 0.1), 0.12, _tint(WHITE), Vector3(1.0, 1.2, 0.6))
	_ball(head, 0.21, gold, Vector3(1.05, 0.95, 0.95))
	_ball(head + Vector3(0, -0.07, 0.16), 0.08, WHITE, Vector3(1.4, 0.8, 0.7))
	_ball(head + Vector3(0, -0.03, 0.22), 0.022, Color("#E88AA0"))
	_eyes(head, 0.21, 0.4, 0.1, 0.075, Color("#6A4A2A"))
	for s: float in [-1.0, 1.0]:
		_ball(head + Vector3(s * 0.08, 0.3, -0.03), 0.065, gold, Vector3(0.8, 3.0, 0.6), Vector3(0, 0, -s * 0.18))
		_ball(head + Vector3(s * 0.085, 0.3, 0.0), 0.04, Color("#F2A8B8"), Vector3(0.6, 2.6, 0.3), Vector3(0, 0, -s * 0.18))
		_ball(Vector3(s * 0.09, 0.04, 0.05), 0.06, gold.darkened(0.06), Vector3(0.8, 0.55, 1.7))
		_ball(Vector3(s * 0.16, 0.27, 0.06), 0.05, gold, Vector3(0.8, 1.3, 0.8))
	_ball(Vector3(0, 0.2, -0.18), 0.07, WHITE)
	_strap(Vector3(-0.14, 0.42, 0.12), Vector3(0.2, 0.2, 0.08), Color("#3A7FC0"))
	_ball(Vector3(0.21, 0.18, 0.06), 0.1, _tint(Color("#6FB8F0")), Vector3(0.9, 0.8, 0.7))
	_mark(Vector3(0.21, 0.2, 0.14), 0.04)


func _rambler() -> void:
	var wool := Color("#EBC67E")
	var c := Vector3(0, 0.44, 0)
	_ball(c, 0.38, wool)
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	for k in 16:
		var yaw := rng.randf_range(-PI, PI)
		var pitch := rng.randf_range(-0.6, 1.2)
		if absf(yaw) < 0.6 and pitch < 0.5:
			continue
		_ball(_on(c, 0.36, yaw, pitch), 0.11, _tint(wool.lightened(0.05)), Vector3.ONE, Vector3.ZERO, 1)
	var face := Vector3(0, 0.46, 0.28)
	_ball(face, 0.2, Color("#7E5232"), Vector3(1.05, 1.0, 0.6))
	_ball(face + Vector3(0, -0.09, 0.07), 0.1, Color("#A87850"), Vector3(1.2, 0.8, 0.7))
	_eyes(face + Vector3(0, 0.0, -0.08), 0.2, 0.42, 0.0, 0.07, Color("#3A2414"))
	for s: float in [-1.0, 1.0]:
		var at := Vector3(s * 0.2, 0.62, 0.18)
		var r := 0.075
		for k in 6:
			_ball(at, r, Color("#C99A5A").darkened(0.04 * k), Vector3.ONE, Vector3.ZERO, 1)
			var a := k * 0.9
			at += Vector3(s * 0.07 * cos(a), -0.06 * sin(a) + 0.03, -0.06 * cos(a * 0.7))
			r *= 0.86
		_ball(Vector3(s * 0.18, 0.06, 0.08), 0.08, Color("#6A4428"), Vector3(1.0, 0.8, 1.2))
	_mark(face + Vector3(0, 0.14, 0.08), 0.05)


func _golem() -> void:
	var glass := Color("#9C82F5", 0.82)
	var deep := Color("#6A50D0", 0.85)
	_facet(Vector3(0, 0.52, 0), 0.27, glass, Vector3(1.25, 1.15, 0.9))
	_facet(Vector3(0, 0.84, 0.02), 0.15, glass, Vector3(1.1, 1.0, 1.0))
	for s: float in [-1.0, 1.0]:
		_facet(Vector3(s * 0.3, 0.68, 0), 0.12, deep)
		_cone(Vector3(s * 0.3, 0.74, -0.02), Vector3(s * 0.42, 0.98, -0.06), 0.06, glass)
		_facet(Vector3(s * 0.38, 0.42, 0.04), 0.1, deep, Vector3(0.9, 1.4, 0.9))
		_facet(Vector3(s * 0.4, 0.26, 0.08), 0.12, glass)
		_facet(Vector3(s * 0.12, 0.12, 0.02), 0.11, deep, Vector3(1.0, 1.2, 1.0))
		_ball(Vector3(s * 0.055, 0.86, 0.15), 0.03, GLINT, Vector3(1.4, 0.8, 0.5))
	_cone(Vector3(0, 0.95, 0), Vector3(0, 1.04, 0), 0.06, glass)
	_ball(Vector3(0, 0.56, 0.2), 0.07, Color(1.0, 0.95, 1.0, 0.2))
	_mark(Vector3(0, 0.56, 0.25), 0.06)


func _quarryback() -> void:
	var shell := Color("#A99CC8")
	var hide := Color("#D8CDE6")
	for k in 5:
		var z := -0.24 + k * 0.12
		_ball(Vector3(0, 0.38, z), 0.31 - absf(k - 2) * 0.03, shell.darkened(0.06 * (k % 2)), Vector3(1.0, 0.95, 0.42))
	var head := Vector3(0, 0.36, 0.34)
	_ball(head, 0.15, hide, Vector3(0.95, 0.95, 1.1))
	_ball(head + Vector3(0, -0.04, 0.13), 0.04, Color("#E89AB0"))
	_eyes(head, 0.15, 0.45, 0.0, 0.06, Color("#3A2A4A"))
	for s: float in [-1.0, 1.0]:
		_ball(head + Vector3(s * 0.11, 0.12, -0.04), 0.05, hide.darkened(0.1), Vector3(0.7, 1.3, 0.5))
		_ball(Vector3(s * 0.18, 0.08, 0.14), 0.07, hide.darkened(0.08), Vector3(1.0, 1.2, 1.0))
		_ball(Vector3(s * 0.18, 0.08, -0.16), 0.07, hide.darkened(0.08), Vector3(1.0, 1.2, 1.0))
	_limb(Vector3(0, 0.3, -0.36), Vector3(0, 0.46, -0.6), 0.04, hide.darkened(0.1))
	_cone(Vector3(0, 0.5, -0.62), Vector3(0.14, 0.44, -0.64), 0.05, Color("#8A8098"))
	_cone(Vector3(0, 0.5, -0.62), Vector3(-0.14, 0.44, -0.64), 0.05, Color("#8A8098"))
	_mark(Vector3(0, 0.7, 0.0), 0.06)


func _mite() -> void:
	var lilac := Color("#B79CF5")
	var head := Vector3(0, 0.58, 0.02)
	_ball(Vector3(0, 0.24, 0), 0.17, lilac.darkened(0.05), Vector3(1.0, 1.1, 0.95))
	_ball(head, 0.27, lilac)
	_eyes(head, 0.27, 0.38, 0.05, 0.1, Color("#4A2A8A"))
	for s: float in [-1.0, 1.0]:
		_limb(head + Vector3(s * 0.1, 0.22, 0), head + Vector3(s * 0.2, 0.42, 0.04), 0.014, lilac.darkened(0.2))
		var tip := Color("#FF9ADF") if s < 0 else Color("#8AE8FF")
		_ball(head + Vector3(s * 0.2, 0.44, 0.04), 0.04, Color(tip, 0.4))
		_ball(Vector3(s * 0.12, 0.05, 0.06), 0.05, lilac.darkened(0.15))
		_ball(Vector3(s * 0.17, 0.24, 0.04), 0.045, lilac, Vector3(0.8, 1.3, 0.8))
	_cone(Vector3(0, 0.12, -0.15), Vector3(0, 0.5, -0.2), 0.11, Color(Color("#D8C8FF"), 0.6), false)
	_ball(Vector3(0, 0.24, -0.14), 0.06, Color(Color("#FFE08A"), 0.5))
	_mark(Vector3(0, 0.26, 0.17), 0.045)


func _otter() -> void:
	var sand := Color("#D9AE78")
	var cream := Color("#F6E6C8")
	var head := Vector3(0, 0.68, 0.04)
	_ball(Vector3(0, 0.36, 0), 0.2, sand, Vector3(1.0, 1.5, 0.9))
	_ball(Vector3(0, 0.34, 0.1), 0.14, _tint(cream), Vector3(1.0, 1.6, 0.6))
	_ball(head, 0.17, sand, Vector3(1.1, 0.95, 1.0))
	_ball(head + Vector3(0, -0.05, 0.13), 0.08, cream, Vector3(1.4, 0.85, 0.8))
	_ball(head + Vector3(0, -0.02, 0.2), 0.025, Color("#3A2418"))
	_eyes(head, 0.17, 0.42, 0.05, 0.062, Color("#2A1A10"))
	for s: float in [-1.0, 1.0]:
		_ball(head + Vector3(s * 0.15, 0.08, -0.02), 0.04, sand.darkened(0.15))
		_ball(Vector3(s * 0.16, 0.42, 0.1), 0.045, sand.darkened(0.08), Vector3(0.8, 1.4, 0.8))
		_ball(Vector3(s * 0.09, 0.04, 0.06), 0.06, sand.darkened(0.2), Vector3(0.9, 0.55, 1.4))
	_ball(Vector3(0, 0.1, -0.24), 0.07, sand.darkened(0.12), Vector3(0.9, 0.5, 2.2), Vector3(-0.4, 0, 0))
	var shell := _tint(Color("#5FD0DE"))
	_ball(Vector3(0, 0.46, -0.2), 0.15, shell, Vector3(1.0, 1.0, 0.7))
	_ball(Vector3(0.04, 0.5, -0.29), 0.08, shell.lightened(0.2), Vector3(1.0, 1.0, 0.6))
	_ball(Vector3(0.06, 0.52, -0.33), 0.04, WHITE)
	_strap(Vector3(-0.15, 0.56, 0.12), Vector3(0.15, 0.3, 0.12), Color("#7A5232"))
	_mark(Vector3(0, 0.5, -0.36), 0.05, Vector3(0, PI, 0))


func _heron() -> void:
	var slate := Color("#D2E2EC")
	var wing := Color("#8AA6B8")
	_ball(Vector3(0, 0.46, -0.04), 0.2, slate, Vector3(1.0, 1.05, 1.5))
	for s: float in [-1.0, 1.0]:
		_ball(Vector3(s * 0.15, 0.48, -0.08), 0.16, wing, Vector3(0.35, 0.9, 1.4))
		_limb(Vector3(s * 0.06, 0.3, 0), Vector3(s * 0.07, 0.03, 0.02), 0.018, Color("#5A6A78"))
		_ball(Vector3(s * 0.07, 0.02, 0.06), 0.035, Color("#5A6A78"), Vector3(1.0, 0.4, 1.8))
	var neck := [Vector3(0, 0.6, 0.12), Vector3(0, 0.7, 0.13), Vector3(0, 0.79, 0.1)]
	for p: Vector3 in neck:
		_ball(p, 0.07, slate)
	var head := Vector3(0, 0.88, 0.08)
	_ball(head, 0.11, WHITE)
	_eyes(head, 0.11, 0.6, 0.0, 0.045, Color("#D9A548"))
	_cone(head + Vector3(0, -0.02, 0.08), head + Vector3(0, -0.05, 0.3), 0.03, Color("#F2B43C"))
	_cone(head + Vector3(0, 0.06, -0.06), head + Vector3(0, 0.1, -0.24), 0.025, _tint(Color("#3CC6D8")))
	_ball(Vector3(0, 0.5, -0.3), 0.08, wing.darkened(0.1), Vector3(0.8, 0.5, 1.4))
	_mark(Vector3(0, 0.5, 0.26), 0.04)


func _emberling() -> void:
	var coal := Color("#4E3E44")
	var head := Vector3(0, 0.56, 0.02)
	_ball(Vector3(0, 0.25, 0), 0.18, coal, Vector3(1.0, 1.1, 0.95))
	_ball(head, 0.23, Color("#6A4E4A"))
	_eyes(head, 0.23, 0.38, 0.05, 0.085, Color("#F0802A"))
	var flame := [Color("#FFD24A", 0.2), Color("#F07A3C", 0.35), Color("#FF9A3C", 0.25)]
	for k in 5:
		var a := (k - 2) * 0.42
		var base := head + Vector3(sin(a) * 0.14, 0.15, cos(a) * 0.02 - 0.02)
		_cone(base, base + Vector3(sin(a) * 0.08, 0.2 - absf(k - 2) * 0.04, 0), 0.07, flame[k % 3])
	for k in 4:
		_ball(Vector3(0.08 * (k - 1.5), 0.2 + 0.05 * (k % 2), 0.16), 0.02, Color("#FF8A3C", 0.2))
	for s: float in [-1.0, 1.0]:
		_ball(Vector3(s * 0.17, 0.27, 0.05), 0.05, coal.lightened(0.08), Vector3(0.8, 1.3, 0.8))
		_ball(Vector3(s * 0.09, 0.04, 0.06), 0.06, coal.darkened(0.1), Vector3(1.0, 0.6, 1.3))
	_limb(Vector3(0, 0.16, -0.14), Vector3(0, 0.3, -0.32), 0.025, coal)
	_ball(Vector3(0, 0.33, -0.34), 0.05, Color("#FFB04A", 0.2))
	_mark(Vector3(0, 0.26, 0.18), 0.045)


func _hound() -> void:
	var fox := Color("#F0843C")
	var bolt := Color(Color("#5AC8FF"), 0.35)
	_ball(Vector3(0, 0.34, -0.06), 0.19, fox, Vector3(0.95, 1.0, 1.35))
	_ball(Vector3(0, 0.38, 0.12), 0.12, _tint(WHITE), Vector3(1.0, 1.2, 0.6))
	var head := Vector3(0, 0.62, 0.12)
	_ball(head, 0.17, fox)
	_ball(head + Vector3(0, -0.06, 0.13), 0.08, WHITE, Vector3(1.0, 0.8, 1.3))
	_ball(head + Vector3(0, -0.04, 0.24), 0.025, INK)
	_eyes(head, 0.17, 0.45, 0.05, 0.062, Color("#3A7FC0"))
	for s: float in [-1.0, 1.0]:
		_cone(head + Vector3(s * 0.1, 0.1, -0.02), head + Vector3(s * 0.17, 0.3, -0.04), 0.07, fox.darkened(0.06))
		_ball(head + Vector3(s * 0.165, 0.29, -0.04), 0.032, INK.lightened(0.2))
		_limb(Vector3(s * 0.1, 0.24, 0.1), Vector3(s * 0.1, 0.03, 0.12), 0.035, fox.darkened(0.1))
		_limb(Vector3(s * 0.1, 0.24, -0.2), Vector3(s * 0.1, 0.03, -0.2), 0.035, fox.darkened(0.1))
	for k in 3:
		var p := head + Vector3(0, 0.12 - k * 0.12, -0.12 - k * 0.07)
		_cone(p, p + Vector3(0.05 * (1 - 2 * (k % 2)), 0.1, -0.06), 0.04, bolt)
	_ball(Vector3(0, 0.46, -0.36), 0.11, fox, Vector3(0.9, 0.9, 1.6), Vector3(0.6, 0, 0))
	_ball(Vector3(0, 0.56, -0.48), 0.07, WHITE)
	_mark(head + Vector3(0, 0.1, 0.13), 0.04)


func _panda() -> void:
	var red := Color("#E0703A")
	var dark := Color("#5A3024")
	var head := Vector3(0, 0.6, 0.02)
	_ball(Vector3(0, 0.27, 0), 0.19, red, Vector3(1.0, 1.1, 0.95))
	_ball(Vector3(0, 0.25, 0.1), 0.13, dark, Vector3(1.0, 1.1, 0.6))
	_ball(head, 0.23, red, Vector3(1.1, 0.95, 1.0))
	_ball(head + Vector3(0, -0.08, 0.15), 0.1, WHITE, Vector3(1.3, 0.75, 0.7))
	_ball(head + Vector3(0, -0.05, 0.23), 0.025, INK)
	_eyes(head, 0.23, 0.38, 0.0, 0.07, Color("#3A2418"))
	for s: float in [-1.0, 1.0]:
		var eye := _on(head, 0.23, s * 0.38, 0.0) + Vector3(0, 0, 0.02)
		_ring_flat(eye, 0.085, 0.022, Color("#C98A3A"))
		_ball(head + Vector3(s * 0.18, 0.17, -0.02), 0.07, red, Vector3(1.0, 1.0, 0.6))
		_ball(head + Vector3(s * 0.18, 0.17, 0.01), 0.04, WHITE, Vector3(1.0, 1.0, 0.4))
		_ball(Vector3(s * 0.17, 0.28, 0.05), 0.05, dark, Vector3(0.8, 1.3, 0.8))
		_ball(Vector3(s * 0.09, 0.04, 0.06), 0.06, dark, Vector3(1.0, 0.6, 1.3))
	for k in 5:
		_ball(Vector3(0.05 * k, 0.12 + 0.07 * k, -0.2 - 0.03 * k), 0.08 - 0.006 * k, red if k % 2 == 0 else Color("#F2D2A8"),
			Vector3.ONE, Vector3.ZERO, 1)
	var coil := Vector3(-0.22, 0.2, 0.04)
	_ball(coil, 0.09, Color("#B07A4F"), Vector3(0.8, 1.0, 0.8))
	for k in 6:
		var a := k * 1.2
		_ball(coil + Vector3(cos(a) * 0.05, 0.08 + k * 0.025, sin(a) * 0.05), 0.022, Color("#D98A4A"), Vector3.ONE,
			Vector3.ZERO, 1)
	_ball(coil + Vector3(0, 0.25, 0), 0.03, Color(Color("#8AE8FF"), 0.2))
	_mark(Vector3(0, 0.3, 0.17), 0.04)


func _bear() -> void:
	var stone := Color("#A8A090")
	var moss := _tint(Color("#6CB45A"))
	_ball(Vector3(0, 0.4, 0), 0.36, stone, Vector3(1.1, 1.0, 0.95))
	_ball(Vector3(0, 0.55, -0.04), 0.33, moss, Vector3(1.12, 0.7, 0.95))
	var head := Vector3(0, 0.72, 0.18)
	_ball(head, 0.2, stone.lightened(0.04))
	_ball(head + Vector3(0, 0.1, -0.02), 0.17, moss, Vector3(1.05, 0.55, 1.0))
	_ball(head + Vector3(0, -0.06, 0.16), 0.08, Color("#D8D0C0"), Vector3(1.3, 0.85, 0.8))
	_ball(head + Vector3(0, -0.03, 0.23), 0.03, INK)
	_eyes(head, 0.2, 0.42, 0.05, 0.06, Color("#3A2A1A"))
	for s: float in [-1.0, 1.0]:
		_ball(head + Vector3(s * 0.15, 0.15, -0.04), 0.06, stone)
		_ball(Vector3(s * 0.34, 0.32, 0.12), 0.1, stone.darkened(0.05), Vector3(0.9, 1.4, 0.9))
		_ball(Vector3(s * 0.18, 0.08, 0.1), 0.11, stone.darkened(0.1), Vector3(1.0, 0.7, 1.2))
	var flowers := [Vector3(0.18, 0.78, 0.0), Vector3(-0.22, 0.74, -0.08), Vector3(0.05, 0.82, -0.18),
		Vector3(-0.08, 0.95, 0.16)]
	for k in flowers.size():
		_ball(flowers[k], 0.035, Color("#F28AB0") if k % 2 == 0 else Color("#F2E07A"), Vector3.ONE, Vector3.ZERO, 1)
	_mark(Vector3(0, 0.36, 0.34), 0.06)


func _bloomling() -> void:
	var leaf := Color("#7ACB6A")
	var head := Vector3(0, 0.56, 0.02)
	_ball(Vector3(0, 0.24, 0), 0.16, leaf.darkened(0.05), Vector3(1.0, 1.15, 0.95))
	var petal := _tint(Color("#F28AB0"))
	for k in 9:
		var a := TAU * k / 9.0
		var p := head + Vector3(cos(a) * 0.24, sin(a) * 0.24 + 0.02, -0.06)
		_ball(p, 0.08, petal.lightened(0.06 * (k % 2)), Vector3(1.0, 1.6, 0.45), Vector3(0, 0, a - PI / 2.0))
	_ball(head, 0.22, leaf.lightened(0.12))
	_eyes(head, 0.22, 0.38, 0.05, 0.085, Color("#2F8A45"))
	for s: float in [-1.0, 1.0]:
		_ball(Vector3(s * 0.16, 0.26, 0.04), 0.07, leaf, Vector3(0.5, 1.4, 0.3), Vector3(0, 0, s * 0.6))
		_ball(Vector3(s * 0.08, 0.04, 0.06), 0.055, leaf.darkened(0.2), Vector3(1.0, 0.6, 1.3))
		_ball(head + Vector3(s * 0.13, -0.08, 0.17), 0.03, Color(Color("#F28AB0"), 0.85))
	_mark(Vector3(0, 0.26, 0.15), 0.04)


func _rootrunner() -> void:
	var bark := Color("#9A6A42")
	var face := Color("#C89A6A")
	var c := Vector3(0, 0.46, 0)
	_ball(c, 0.26, bark, Vector3(0.95, 1.2, 0.9))
	_ball(c + Vector3(0, 0.05, 0.12), 0.18, face, Vector3(1.0, 0.95, 0.6))
	_eyes(c + Vector3(0, 0.06, 0.0), 0.24, 0.36, 0.0, 0.075, Color("#4A8A3A"))
	_limb(c + Vector3(0, 0.28, 0), c + Vector3(0, 0.4, 0), 0.015, Color("#4A8A3A"))
	for s: float in [-1.0, 1.0]:
		_ball(c + Vector3(s * 0.08, 0.44, 0), 0.07, _tint(Color("#6CC45A")), Vector3(1.6, 0.35, 0.8), Vector3(0, 0, s * 0.4))
		for k in 2:
			_cone(Vector3(s * (0.06 + 0.06 * k), 0.24, 0.04 - 0.08 * k), Vector3(s * (0.12 + 0.1 * k), 0.0, 0.08 - 0.12 * k),
				0.04, bark.darkened(0.15))
		_ball(Vector3(s * 0.22, 0.42, 0.06), 0.045, bark, Vector3(0.8, 1.4, 0.8))
	var basket := Color("#C9A06A")
	g.prism(Geo.place(Vector3(0, 0.3, -0.24)), 10, 0.13, 0.16, 0.2, basket, true)
	_ring_flat(Vector3(0, 0.5, -0.24), 0.16, 0.025, basket.darkened(0.15), Vector3(-PI / 2.0, 0, 0))
	_mark(c + Vector3(0, -0.12, 0.22), 0.045)


func _armour() -> void:
	var steel := Color("#C8C8DA")
	var plume := _tint(Color("#E05CB4"))
	_ball(Vector3(0, 0.5, 0), 0.25, steel, Vector3(1.2, 1.1, 0.9))
	_ball(Vector3(0, 0.82, 0.01), 0.16, steel.lightened(0.05), Vector3(1.0, 1.15, 1.0))
	_ball(Vector3(0, 0.81, 0.08), 0.11, Color("#2A1E3A"), Vector3(1.15, 0.42, 0.75))
	for s: float in [-1.0, 1.0]:
		_ball(Vector3(s * 0.045, 0.815, 0.15), 0.025, Color(Color("#FF8AD8"), 0.0), Vector3(1.3, 0.8, 0.5))
	_ring_flat(Vector3(0, 0.74, 0.0), 0.15, 0.025, steel.darkened(0.15))
	_cone(Vector3(0, 0.96, -0.02), Vector3(0, 1.08, -0.1), 0.05, plume)
	for s: float in [-1.0, 1.0]:
		_ball(Vector3(s * 0.28, 0.66, 0), 0.11, steel.darkened(0.05), Vector3(1.0, 0.8, 1.0))
		_limb(Vector3(s * 0.32, 0.6, 0.02), Vector3(s * 0.34, 0.36, 0.06), 0.06, steel.darkened(0.1))
		_limb(Vector3(s * 0.11, 0.3, 0), Vector3(s * 0.12, 0.05, 0.02), 0.07, steel.darkened(0.12))
		_ball(Vector3(s * 0.12, 0.04, 0.06), 0.08, steel.darkened(0.2), Vector3(1.0, 0.6, 1.4))
	var shield := Vector3(-0.36, 0.4, 0.2)
	_ball(shield, 0.19, plume.darkened(0.1), Vector3(0.9, 1.15, 0.22), Vector3(0, -0.5, 0))
	_ring_flat(shield + Vector3(0.02, 0, 0.04), 0.1, 0.022, Color(Color("#FFB0E8"), 0.3), Vector3(PI / 2.0, -0.5, 0))
	_ball(shield + Vector3(0.02, 0, 0.05), 0.04, Color(Color("#FFB0E8"), 0.2))
	_mark(Vector3(0, 0.55, 0.23), 0.06)


func _wisp() -> void:
	var pink := Color("#F2A0D8", 0.75)
	var c := Vector3(0, 0.46, 0)
	_ball(c, 0.25, pink, Vector3(1.0, 1.0, 0.95))
	_cone(c + Vector3(0, -0.12, 0), c + Vector3(0.06, -0.42, -0.06), 0.16, pink)
	_eyes(c, 0.25, 0.4, 0.05, 0.09, Color("#9C3380"))
	_ring_flat(c + Vector3(0, 0.22, 0), 0.11, 0.025, Color("#D9A548"))
	_ring_flat(c + Vector3(0, 0.34, 0), 0.05, 0.015, Color("#D9A548"), Vector3(PI / 2.0, 0, 0))
	for s: float in [-1.0, 1.0]:
		_cone(c + Vector3(s * 0.16, 0.14, 0), c + Vector3(s * 0.22, 0.28, 0), 0.05, pink)
		_ball(c + Vector3(s * 0.14, -0.08, 0.18), 0.03, Color(Color("#FF8AC8"), 0.7))
	_ball(c + Vector3(0, 0.0, -0.05), 0.14, Color(1.0, 0.9, 0.7, 0.3))
	_mark(c + Vector3(0, 0.14, 0.22), 0.04)


func _moth() -> void:
	var lilac := Color("#ECCDF4")
	var hood := Color("#E07CC4")
	_ball(Vector3(0, 0.34, 0), 0.22, lilac, Vector3(1.0, 1.2, 0.95))
	var head := Vector3(0, 0.66, 0.02)
	_ball(head, 0.21, hood, Vector3(1.05, 1.05, 1.0))
	_ball(head + Vector3(0, -0.03, 0.08), 0.16, lilac.darkened(0.1), Vector3(1.0, 0.9, 0.7))
	_eyes(head + Vector3(0, -0.02, 0.0), 0.2, 0.36, 0.05, 0.075, Color("#5A2A6A"))
	for s: float in [-1.0, 1.0]:
		_limb(head + Vector3(s * 0.06, 0.18, 0.02), head + Vector3(s * 0.16, 0.34, 0.06), 0.012, hood.darkened(0.2))
		_ball(head + Vector3(s * 0.17, 0.35, 0.06), 0.03, hood)
		_ball(Vector3(s * 0.3, 0.46, -0.12), 0.2, Color(Color("#F4B8E8"), 0.8), Vector3(1.2, 1.0, 0.12),
			Vector3(0, s * 0.5, s * -0.4))
		_ball(Vector3(s * 0.24, 0.28, -0.1), 0.12, Color(Color("#F4B8E8"), 0.8), Vector3(1.0, 1.0, 0.12),
			Vector3(0, s * 0.5, s * 0.3))
		_ball(Vector3(s * 0.08, 0.04, 0.06), 0.05, lilac.darkened(0.15))
	_mark(Vector3(0, 0.36, 0.2), 0.045)


## The six Sages: a tall robed figure, its look by §21.6.
func _sage() -> void:
	var robe := {"archivist": "#5A3FB0", "tinkerer": "#2F8A8A", "gardener": "#5CA04A", "wanderer": "#2E2A6E",
		"chronicler": "#2F9AAA", "lamplighter": "#4A3A44"}
	var trim := {"archivist": "#F2B43C", "tinkerer": "#C98A3A", "gardener": "#F4EBD0", "wanderer": "#C8CCE0",
		"chronicler": "#E8E0C8", "lamplighter": "#F07A3C"}
	var main := _tint(Color(str(robe.get(kind, "#5A3FB0"))))
	var edge := Color(str(trim.get(kind, "#F2B43C")))
	g.prism(Geo.place(Vector3(0, 0.0, 0)), 16, 0.27, 0.16, 0.62, main, true)
	_ring_flat(Vector3(0, 0.02, 0), 0.27, 0.03, edge)
	_ball(Vector3(0, 0.62, 0), 0.17, main, Vector3(1.1, 0.9, 0.9))
	_ring_flat(Vector3(0, 0.5, 0), 0.17, 0.025, edge)
	var head := Vector3(0, 0.84, 0.02)
	_ball(head, 0.14, SKIN)
	_eyes(head, 0.14, 0.32, 0.12, 0.035, Color("#3A2A4A"))
	_ball(head + Vector3(0, -0.03, 0.13), 0.025, SKIN.darkened(0.08))
	for s: float in [-1.0, 1.0]:
		_ball(Vector3(s * 0.2, 0.5, 0.06), 0.07, main.darkened(0.08), Vector3(0.9, 1.6, 0.9), Vector3(0.3, 0, s * 0.2))
		_ball(Vector3(s * 0.23, 0.38, 0.14), 0.04, SKIN)
	match kind:
		"archivist":
			_ball(head + Vector3(0, -0.1, 0.07), 0.11, WHITE, Vector3(1.0, 1.3, 0.7))
			_ball(head + Vector3(0, 0.07, -0.02), 0.14, WHITE, Vector3(1.05, 0.7, 1.0))
			for s: float in [-1.0, 1.0]:
				_ring_flat(head + Vector3(s * 0.05, 0.01, 0.13), 0.032, 0.01, Color("#D9A548"), Vector3(PI / 2.0, 0, 0))
			_staff(Vector3(0.28, 0.0, 0.12), 1.0, Color("#8A5A32"))
			_lantern(Vector3(0.28, 1.04, 0.12), 0.06)
			g.box(Transform3D(Basis(Vector3.UP, 0.4).rotated(Vector3.RIGHT, 0.3), Vector3(-0.3, 0.72, 0.12)),
				Vector3(0.16, 0.03, 0.12), Color("#8C2A3A"), Color("#F4EBD0"))
		"tinkerer":
			_ball(head + Vector3(0, 0.08, -0.02), 0.13, Color("#E07A3A"), Vector3(1.1, 0.8, 1.0))
			for s: float in [-1.0, 1.0]:
				_ring_flat(head + Vector3(s * 0.05, 0.07, 0.12), 0.04, 0.014, Color("#C98A3A"), Vector3(PI / 2.0 - 0.3, 0, 0))
			for k in 4:
				_ball(Vector3(0.24 + 0.03 * k, 0.5 - 0.06 * k, 0.12 + 0.02 * k), 0.04, Color("#C98A3A"), Vector3.ONE,
					Vector3.ZERO, 1)
			_ring_flat(Vector3(0, 0.42, 0), 0.19, 0.03, Color("#6A4A2A"))
		"gardener":
			g.prism(Geo.place(head + Vector3(0, 0.08, 0)), 14, 0.32, 0.28, 0.03, Color("#7AB04A"), true)
			g.prism(Geo.place(head + Vector3(0, 0.1, 0)), 12, 0.12, 0.08, 0.1, Color("#5C9A3A"), true)
			_ball(head + Vector3(0.12, 0.13, 0.12), 0.03, Color("#F28AB0"))
			g.prism(Geo.place(Vector3(-0.28, 0.28, 0.12)), 10, 0.07, 0.08, 0.12, Color("#9AD8E8", 0.6), true)
			_cone(Vector3(-0.22, 0.34, 0.12), Vector3(-0.08, 0.38, 0.2), 0.02, Color("#9AD8E8"))
		"wanderer":
			_ball(head + Vector3(0, 0.03, -0.04), 0.18, main.darkened(0.1), Vector3(1.0, 1.05, 1.0))
			_ball(head + Vector3(0, -0.1, 0.07), 0.09, WHITE, Vector3(1.0, 1.2, 0.7))
			_staff(Vector3(0.28, 0.0, 0.12), 1.0, Color("#8A5A32"))
			_ring_flat(Vector3(0.28, 1.02, 0.12), 0.05, 0.015, Color("#C8CCE0"), Vector3(PI / 2.0, 0, 0))
			for k in 5:
				_ball(Vector3(-0.08 + 0.04 * k, 0.2 + 0.08 * (k % 3), 0.24), 0.012, GLINT)
		"chronicler":
			g.prism(Geo.place(head + Vector3(0, 0.1, 0)), 14, 0.17, 0.17, 0.02, Color("#2A6A7A"), true)
			g.prism(Geo.place(head + Vector3(0, 0.12, 0)), 14, 0.11, 0.11, 0.16, Color("#2A6A7A"), true)
			_ring_flat(head + Vector3(0, 0.15, 0), 0.115, 0.015, edge)
			g.box(Transform3D(Basis(Vector3.UP, -0.3), Vector3(-0.24, 0.42, 0.16)), Vector3(0.14, 0.18, 0.04),
				Color("#8C6CF0"), Color("#F4EBD0"))
		"lamplighter":
			g.prism(Geo.place(head + Vector3(0, 0.07, 0)), 12, 0.15, 0.12, 0.08, Color("#3A2A30"), true)
			_ring_flat(Vector3(0, 0.66, 0.02), 0.15, 0.04, _tint(edge))
			_staff(Vector3(0.28, 0.0, 0.12), 1.1, Color("#5A4A4E"))
			_lantern(Vector3(0.28, 1.14, 0.12), 0.07)
	_mark(Vector3(0, 0.3, 0.24), 0.05)


## A Nursery's egg (§10.2): speckled cream with a band in each school's
## colour, since the kind is not known until it hatches.
func _egg() -> void:
	var cream := Color("#F6EBD2")
	_ball(Vector3(0, 0.42, 0), 0.32, cream, Vector3(0.85, 1.3, 0.85))
	var rng := RandomNumberGenerator.new()
	rng.seed = 11
	for k in 12:
		var p := _on(Vector3(0, 0.42, 0), 0.3, rng.randf() * TAU, rng.randf_range(-0.6, 0.9))
		p.y = 0.42 + (p.y - 0.42) * 1.3
		_ball(p, 0.03, Color("#C9A0D8").lerp(Color("#9AD8E8"), rng.randf()), Vector3.ONE, Vector3.ZERO, 1)
	var schools: Array[Color] = [Palette.MOTION, Palette.MATTER, Palette.TIME, Palette.ENERGY, Palette.LIFE,
		Palette.SPIRIT]
	for k in schools.size():
		var a := TAU * k / schools.size()
		_ball(Vector3(cos(a) * 0.27, 0.36, sin(a) * 0.27), 0.045, Color(schools[k], 0.5))
	_ring_flat(Vector3(0, 0.36, 0), 0.272, 0.02, Color("#D9A548"))


## Half an egg's shell, cup up, for a hatch's burst.
func _shell() -> void:
	var cream := Color("#F6EBD2")
	for k in 7:
		var a := TAU * k / 7.0
		_cone(Vector3(cos(a) * 0.2, 0.0, sin(a) * 0.2), Vector3(cos(a) * 0.25, 0.12 + 0.04 * (k % 2), sin(a) * 0.25),
			0.08, cream)
	_ball(Vector3(0, 0.02, 0), 0.24, cream, Vector3(1.0, 0.3, 1.0))


func _chibi(body: Color, belly: Color) -> void:
	var head := Vector3(0, 0.58, 0.02)
	_ball(Vector3(0, 0.25, 0), 0.18, body, Vector3(1.0, 1.1, 0.95))
	_ball(Vector3(0, 0.24, 0.1), 0.12, belly, Vector3(1.0, 1.2, 0.6))
	_ball(head, 0.25, body)
	_eyes(head, 0.25, 0.38, 0.05, 0.085, INK.lightened(0.2))
	_mark(Vector3(0, 0.27, 0.16), 0.04)


# --- Forms and the guard form ---------------------------------------------


## A form's pattern: the body's second colour taken toward the note's.
func _tint(c: Color) -> Color:
	if note.a == 0.0:
		return c
	return Color(c.lerp(note, 0.55), c.a)


## The guard form (§21.6): "a sash and a small lantern".
func _guard() -> void:
	_strap(Vector3(-0.2, 0.62, 0.24), Vector3(0.22, 0.2, 0.24), Palette.ALARM.darkened(0.05), 0.05)
	_lantern(Vector3(0.36, 0.3, 0.16), 0.06)


func _lantern(at: Vector3, r: float) -> void:
	var brass := Color("#C98A3A")
	_ring_flat(at + Vector3(0, r * 1.2, 0), r * 0.7, r * 0.25, brass)
	_ball(at, r, Color(1.0, 0.85, 0.45, 0.15), Vector3(1.0, 1.2, 1.0))
	_ring_flat(at - Vector3(0, r * 1.1, 0), r * 0.8, r * 0.3, brass)


# --- Shapes ----------------------------------------------------------------


## A point on a ball's surface: `yaw` round from the front, `pitch` up.
func _on(c: Vector3, r: float, yaw: float, pitch: float) -> Vector3:
	return c + Vector3(sin(yaw) * cos(pitch), sin(pitch), cos(yaw) * cos(pitch)) * r


func _ball(at: Vector3, r: float, col: Color, s := Vector3.ONE, rot := Vector3.ZERO, detail := 2) -> void:
	var rings := 9 if detail >= 2 else 5
	var segs := 14 if detail >= 2 else 8
	if r < 0.04 and detail >= 2:
		rings = 6
		segs = 10
	g.ball(Transform3D(Basis.from_euler(rot) * Basis.from_scale(s), at), r, col, rings, segs)


## A cut-glass lump: few facets, flat-looking under the toon ramp.
func _facet(at: Vector3, r: float, col: Color, s := Vector3.ONE) -> void:
	g.ball(Transform3D(Basis.from_scale(s), at), r, col, 3, 6)


## A cone from `base` to `tip`, its tip rounded (§21.6: "no sharp points").
func _cone(base: Vector3, tip: Vector3, r: float, col: Color, rounded := true) -> void:
	var d := tip - base
	var span := d.length()
	if span < 0.0001:
		return
	var y := d / span
	var x := y.cross(Vector3.FORWARD)
	if x.length() < 0.01:
		x = y.cross(Vector3.RIGHT)
	x = x.normalized()
	var z := x.cross(y)
	g.prism(Transform3D(Basis(x, y, z), base), 10, r, r * 0.18 if rounded else 0.0, span, col, true)
	if rounded:
		g.ball(Transform3D(Basis(), tip), r * 0.2, col, 3, 6)


## A limb: a rod with rounded ends.
func _limb(a: Vector3, b: Vector3, r: float, col: Color) -> void:
	var d := b - a
	var span := d.length()
	if span < 0.0001:
		return
	var y := d / span
	var x := y.cross(Vector3.FORWARD)
	if x.length() < 0.01:
		x = y.cross(Vector3.RIGHT)
	x = x.normalized()
	g.prism(Transform3D(Basis(x, y, x.cross(y)), a), 8, r, r, span, col, true)
	g.ball(Transform3D(Basis(), a), r, col, 4, 8)
	g.ball(Transform3D(Basis(), b), r, col, 4, 8)


func _staff(foot: Vector3, tall: float, col: Color) -> void:
	_limb(foot, foot + Vector3(0, tall, 0), 0.018, col)


## A strap across the body, from shoulder to hip.
func _strap(a: Vector3, b: Vector3, col: Color, width := 0.035) -> void:
	var d := b - a
	var mid := (a + b) / 2.0
	var y := d.normalized()
	var x := y.cross(Vector3.BACK).normalized()
	g.box(Transform3D(Basis(x, y, x.cross(y)), mid), Vector3(width, d.length(), 0.03), col)


## A smooth ring (a torus) lying in a plane turned by `rot` (flat on the
## ground at zero): belts, goggles, halos.
func _ring_flat(at: Vector3, r: float, w: float, col: Color, rot := Vector3.ZERO) -> void:
	var b := Basis.from_euler(rot)
	var segs := 20 if r > 0.1 else 12
	var sides := 6 if w > 0.015 else 4
	var point := func(i: int, j: int) -> Array:
		var u := TAU * i / segs
		var v := TAU * j / sides
		var ring_dir := Vector3(cos(u), 0, sin(u))
		var n := ring_dir * cos(v) + Vector3.UP * sin(v)
		return [at + b * (ring_dir * r + n * w), (b * n).normalized()]
	for i in segs:
		for j in sides:
			var q: Array = [point.call(i, j), point.call(i + 1, j), point.call(i + 1, j + 1), point.call(i, j + 1)]
			for idx: Array in [[0, 2, 3], [0, 1, 2]]:
				for k: int in idx:
					g.st.set_color(col)
					g.st.set_normal(q[k][1])
					g.st.add_vertex(q[k][0])
				g.triangles += 1


## Eyes on a head at `c` of radius `r`, `spread` apart round the front and
## `drop` below its middle (§21.6: "at or below the vertical midline …
## set wide apart"): white, a coloured iris, an ink pupil, two catch-lights.
func _eyes(c: Vector3, r: float, spread: float, drop: float, size: float, iris: Color) -> void:
	for s: float in [-1.0, 1.0]:
		var dir := Vector3(s * sin(spread), -drop, cos(spread)).normalized()
		var at := c + dir * r * 0.9
		var face := Basis.looking_at(-dir, Vector3.UP)
		g.ball(Transform3D(face * Basis.from_scale(Vector3(1.0, 1.1, 0.55)), at), size, WHITE, 7, 12)
		var front := at + dir * size * 0.32
		g.ball(Transform3D(face * Basis.from_scale(Vector3(1.0, 1.08, 0.45)), front), size * 0.74, iris, 6, 12)
		g.ball(Transform3D(face * Basis.from_scale(Vector3(1.0, 1.0, 0.4)), front + dir * size * 0.08), size * 0.46,
			INK, 5, 10)
		var up := face * Vector3(-0.3, 0.38, 0.0)
		g.ball(Transform3D(Basis(), front + dir * size * 0.3 + up * size), size * 0.2, GLINT, 3, 6)
		g.ball(Transform3D(Basis(), front + dir * size * 0.3 - up * size * 0.7), size * 0.1, GLINT, 3, 6)
		if note.a > 0.0 and look == "spark":
			g.ball(Transform3D(Basis(), at + Vector3(s * size * 0.9, size * 1.2, 0)), size * 0.14, Color(note, 0.2), 3, 6)


## The school's shape as a marking (§21.6: "its school shape appears as a
## marking"), facing out at `at`; in a form, it glows in the note's colour.
func _mark(at: Vector3, size: float, rot := Vector3.ZERO) -> void:
	var col: Color = Palette.SCHOOL.get(mark_school, Palette.MOTION)
	col = col.darkened(0.25)
	if note.a > 0.0:
		col = Color(note.lightened(0.2), 0.3)
		_form_piece()
	var b := Basis.from_euler(rot)
	var p := func(x: float, y: float) -> Vector3: return at + b * Vector3(x * size, y * size, 0)
	match Tokens.shape(mark_school):
		"chevron":
			for s: float in [-1.0, 1.0]:
				g.box(Transform3D(b * Basis(Vector3.BACK, s * 0.75), p.call(s * 0.32, 0.0)), Vector3(size * 0.28,
					size * 0.9, size * 0.2), col)
		"cube":
			g.box(Transform3D(b * Basis(Vector3.BACK, PI / 4.0), at), Vector3.ONE * size * 0.75, col)
		"hourglass":
			_cone(p.call(0, 0.55), p.call(0, 0.0), size * 0.42, col, false)
			_cone(p.call(0, -0.55), p.call(0, 0.0), size * 0.42, col, false)
		"bolt":
			var zig: Array[Vector2] = [Vector2(0.25, 0.6), Vector2(-0.15, 0.05), Vector2(0.15, -0.05), Vector2(-0.25, -0.6)]
			for k in zig.size() - 1:
				var a: Vector3 = p.call(zig[k].x, zig[k].y)
				var e: Vector3 = p.call(zig[k + 1].x, zig[k + 1].y)
				_limb(a, e, size * 0.13, col)
		"leaf":
			g.ball(Transform3D(b * Basis(Vector3.BACK, 0.6) * Basis.from_scale(Vector3(0.55, 1.0, 0.25)), at), size * 0.6,
				col, 4, 8)
		"eye":
			g.ball(Transform3D(b * Basis.from_scale(Vector3(1.0, 0.6, 0.3)), at), size * 0.6, WHITE, 4, 8)
			g.ball(Transform3D(b, at + b * Vector3(0, 0, size * 0.12)), size * 0.26, col, 3, 6)


## A form's one accessory in its note's colour, over the head: Hush's
## crescent, Spark's crown of sparks, Echo's ring.
func _form_piece() -> void:
	var y := 1.06
	var glow := Color(note, 0.35)
	match look:
		"hush":
			for k in 7:
				var a := -0.9 + k * 0.3
				_ball(Vector3(cos(a + PI / 2.0) * 0.14 + 0.1, y + sin(a + PI / 2.0) * 0.14 - 0.08, -0.04),
					0.04 - absf(k - 3) * 0.006, glow, Vector3.ONE, Vector3.ZERO, 1)
		"spark":
			for k in 5:
				var a := (k - 2) * 0.45
				_cone(Vector3(sin(a) * 0.1, y - 0.1, -0.02), Vector3(sin(a) * 0.16, y + 0.04 - absf(k - 2) * 0.03, -0.02),
					0.03, glow)
		"echo":
			_ring_flat(Vector3(0, y - 0.04, -0.12), 0.17, 0.02, glow, Vector3(PI / 2.0, 0, 0))
