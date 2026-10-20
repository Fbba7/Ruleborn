class_name StageHeroFigure
extends RefCounted
## What a hero stage needs to know of a character, and the ground it stands
## on (§21.4, §21.6): each kind's school, role and height, and a patch of its
## school's realm as a small floating island. The figure itself is
## `StageHero.make_figure`'s.

## §21.6's heights and §11.11's school and role for the eighteen ruleborn,
## and the Sages' (§21.6: "Sages about 1.5"), by kind.
const KINDS := {
	"featherkin": ["motion", "Scout", 0.6], "skyskipper": ["motion", "Carrier", 0.8],
	"rambler": ["motion", "Breaker", 0.9], "glass_golem": ["matter", "Warden", 1.2],
	"quarryback": ["matter", "Breaker", 0.9], "prism_mite": ["matter", "Carrier", 0.5],
	"tidewalker": ["time", "Carrier", 0.8], "hourkeeper": ["time", "Mender", 0.9],
	"stillwatch": ["time", "Warden", 1.2], "emberling": ["energy", "Breaker", 0.7],
	"stormhound": ["energy", "Scout", 0.9], "sparkwright": ["energy", "Mender", 0.8],
	"mossbear": ["life", "Warden", 1.4], "bloomling": ["life", "Mender", 0.6],
	"rootrunner": ["life", "Carrier", 0.8], "echoplate": ["spirit", "Warden", 1.2],
	"lantern_wisp": ["spirit", "Scout", 0.6], "soulmender": ["spirit", "Mender", 0.9],
	"archivist": ["spirit", "", 1.5], "tinkerer": ["matter", "", 1.5], "gardener": ["life", "", 1.5],
	"wanderer": ["motion", "", 1.5], "chronicler": ["time", "", 1.5], "lamplighter": ["energy", "", 1.5],
	"egg": ["spirit", "", 0.7], "shell": ["spirit", "", 0.7],
}
## Each school's home realm (§21.4), whose ground a character stands on.
const REALM := {"motion": "skyfield", "matter": "crystalline", "time": "tidehold", "energy": "emberreach",
	"life": "verdant", "spirit": "lanternvale"}
## The Sages, who stand in the Sage hall.
const SAGES := ["archivist", "tinkerer", "gardener", "wanderer", "chronicler", "lamplighter"]

static var _cache := {}


## A kind's school, lower case; "motion" for a kind the table lacks.
static func school(kind: String) -> String:
	return str(KINDS.get(kind, ["motion"])[0])


static func role(kind: String) -> String:
	return str(KINDS.get(kind, ["", "Scout"])[1])


## A kind's height in metres (1 unit = 1 m, §21.1).
static func height(kind: String) -> float:
	return float(KINDS.get(kind, ["", "", 0.8])[2])


## A kind written as the content writes it: "Glass Golem" or "glass_golem"
## both become "glass_golem".
static func key(kind: String) -> String:
	return kind.strip_edges().to_lower().replace(" ", "_").replace("the_", "")


## A patch of a school's realm as a floating island `radius` across: a
## grassy top with a soft lip, a band of soil and a cone of rock beneath,
## a few tufts and pebbles. One mesh, one draw call.
static func pedestal(for_school: String, radius := 0.75) -> ArrayMesh:
	var cache_key := "%s:%.2f" % [for_school, radius]
	if _cache.has(cache_key):
		return _cache[cache_key]
	var c := RealmPalette.of(str(REALM.get(for_school, "heart")))
	var g := Geo.new()
	var n := 36
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(for_school)
	var edge: Array[float] = []
	for k in n:
		edge.append(1.0 + rng.randf_range(-0.05, 0.05) + 0.03 * sin(k * 3.1))
	var at := func(k: int, r: float, y: float) -> Vector3:
		var a := TAU * (k % n) / n
		return Vector3(cos(a) * r * edge[k % n], y, sin(a) * r * edge[k % n])
	var grass: Color = (c["grass"] as Color).lerp(c["rock"], 0.25).darkened(0.12)
	var top: Color = grass.lightened(0.05)
	# The top: a gentle dome, so the rim falls away softly.
	var rings: Array[Array] = [[0.0, 0.04], [0.55, 0.035], [0.85, 0.02], [1.0, 0.0]]
	for i in rings.size() - 1:
		for k in n:
			var r0: float = rings[i][0] * radius
			var r1: float = rings[i + 1][0] * radius
			var y0: float = rings[i][1]
			var y1: float = rings[i + 1][1]
			var shade := top.lerp(grass, float(i) / 2.0)
			if i == 0:
				g.tri(at.call(k, r0, y0), at.call(k + 1, r1, y1), at.call(k, r1, y1), shade, Vector3.UP)
				continue
			g.quad(at.call(k, r0, y0), at.call(k + 1, r0, y0), at.call(k + 1, r1, y1), at.call(k, r1, y1), shade)
	# The lip and the soil band.
	var soil: Color = c["soil"]
	var rock: Color = c["rock"]
	var bands: Array[Array] = [[1.0, 0.0, grass.darkened(0.12)], [1.02, -0.05, soil.lightened(0.1)],
		[0.97, -0.13, soil], [0.86, -0.2, rock.lightened(0.1)], [0.62, -0.42, rock], [0.34, -0.68, rock.darkened(0.15)],
		[0.08, -0.9, rock.darkened(0.3)]]
	for i in bands.size() - 1:
		for k in n:
			var r0: float = bands[i][0] * radius
			var r1: float = bands[i + 1][0] * radius
			var y0: float = bands[i][1] * radius
			var y1: float = bands[i + 1][1] * radius
			g.quad(at.call(k, r0, y0), at.call(k + 1, r0, y0), at.call(k + 1, r1, y1), at.call(k, r1, y1),
				bands[i][2])
	# Tufts and pebbles near the rim, kept off the middle where the character stands.
	for k in 9:
		var a := rng.randf() * TAU
		var r := radius * rng.randf_range(0.62, 0.9)
		var p := Vector3(cos(a) * r, 0.02, sin(a) * r)
		if k % 3 == 0:
			g.ball(Geo.place(p, rng.randf() * TAU, Vector3(1.0, 0.6, 0.8)), 0.035 * radius / 0.75,
				Color(c["stone"]), 3, 6)
		else:
			for j in 3:
				g.prism(Transform3D(Basis(Vector3(rng.randf() - 0.5, 0, rng.randf() - 0.5).normalized()
					if j > 0 else Vector3.UP, 0.35 * j), p), 4, 0.018, 0.0, 0.09 * radius / 0.75,
					Color(c["plant"]).lightened(0.05 * j))
	# Two roots hanging from the rock.
	for k in 2:
		var a := TAU * (0.2 + 0.45 * k)
		var p := Vector3(cos(a) * radius * 0.5, -0.45 * radius, sin(a) * radius * 0.5)
		g.prism(Transform3D(Basis(Vector3.RIGHT, PI), p), 4, 0.02, 0.0, 0.35 * radius, soil.darkened(0.2))
	var m := g.mesh()
	_cache[cache_key] = m
	return m


## A soft round shadow for the figure's feet: a flat disc fading out.
static func shadow_disc() -> MeshInstance3D:
	var quad := PlaneMesh.new()
	quad.size = Vector2.ONE
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	var tex := GradientTexture2D.new()
	tex.fill = GradientTexture2D.FILL_RADIAL
	tex.fill_from = Vector2(0.5, 0.5)
	tex.fill_to = Vector2(1.0, 0.5)
	var grad := Gradient.new()
	grad.set_color(0, Color(0.1, 0.04, 0.16, 0.5))
	grad.set_color(1, Color(0.1, 0.04, 0.16, 0.0))
	tex.gradient = grad
	mat.albedo_texture = tex
	var mi := MeshInstance3D.new()
	mi.mesh = quad
	mi.material_override = mat
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return mi


## The Sage hall's floor and walls, `wide` across: a round dais of warm
## flagstones in the Heart's colours, a step, and arches behind with
## lanterns, all one mesh.
static func hall(wide: float) -> ArrayMesh:
	var cache_key := "hall:%.2f" % wide
	if _cache.has(cache_key):
		return _cache[cache_key]
	var c := RealmPalette.of("heart")
	var g := Geo.new()
	var r := wide * 0.62
	var stone: Color = (c["stone"] as Color).darkened(0.42)
	g.prism(Geo.place(Vector3(0, -0.12, 0)), 40, r * 1.06, r * 1.04, 0.08, stone.darkened(0.25), true)
	g.prism(Geo.place(Vector3(0, -0.04, 0)), 40, r, r * 0.99, 0.06, stone.darkened(0.08), true, stone)
	# Flagstone joints: a few rings of darker stone on the top.
	for k in 3:
		g.ring(Geo.place(Vector3(0, 0.022 + k * 0.0005, 0)), r * (0.3 + 0.27 * k), r * (0.3 + 0.27 * k) + 0.015,
			stone.darkened(0.2), 40)
	g.ring(Geo.place(Vector3(0, 0.024, 0)), 0.0, r * 0.22, Color(c["trim"]).lightened(0.2), 24)
	# Arches round the back half, each a pair of columns under a round top, a
	# lantern hanging in it.
	var arches := 7
	for k in arches:
		var a := PI + PI * (k + 0.5) / arches
		var at := Vector3(cos(a) * r * 1.02, 0.0, sin(a) * r * 1.02)
		var face := atan2(at.x, at.z)
		var span := r * 0.42
		for side: float in [-1.0, 1.0]:
			var off := Vector3(cos(face) * side * span * 0.5, 0, -sin(face) * side * span * 0.5)
			g.prism(Geo.place(at + off), 8, 0.07, 0.06, 1.5, stone.lightened(0.05), true)
			g.box(Geo.place(at + off + Vector3(0, 1.52, 0), -face), Vector3(0.18, 0.06, 0.18), Color(c["trim"]))
		for j in 14:
			var t := PI * j / 13.0
			var p := at + Vector3(cos(face) * cos(t) * span * 0.5, 1.55 + sin(t) * span * 0.45,
				-sin(face) * cos(t) * span * 0.5)
			g.ball(Geo.place(p), 0.075, stone.lightened(0.12), 4, 8)
		g.ball(Geo.place(at + Vector3(0, 1.25, 0)), 0.06, Color(1.0, 0.82, 0.45, 0.1), 4, 8)
	var m := g.mesh()
	_cache[cache_key] = m
	return m
