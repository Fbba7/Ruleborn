class_name LawFxLinks
extends RefCounted
## §21.7's "Harmony on screen: a thread in the note's colour links the two
## pylons; a dissonance is a jagged, flickering line; a chord forms a slowly
## turning triangle of light between three pylons", with §21.9's effects for
## each: a harmony's eight (one a note, §8.2), a dissonance's four (§8.3),
## a chord's twelve (§8.5); and §7.5's three paradoxes as overlays.
##
## Which laws harmonise is the laws' notes (§8.1), copied here from
## content/laws.json (law_fx_tests checks the copy). The simulation prices
## them (RulebornStability); this only draws them. Where a dissonance's or a
## chord's effect has a moment the simulation picks (a Flicker's bright or
## dark, which law Unmaking switches off), the look is drawn without
## claiming the pick: a strobe, not a verdict.

## Each law's school and notes (content/laws.json).
const LAWS := {"bounce": ["motion", ["flow", "echo"]], "half_gravity": ["motion", ["flow"]],
	"tilt": ["motion", ["flow"]], "current": ["motion", ["flow"]], "heavy_ground": ["motion", ["weight"]],
	"leapfrog": ["motion", ["flow", "glow"]], "frictionless": ["motion", ["flow", "spark"]],
	"inward_pull": ["motion", ["weight"]], "brittle_stone": ["matter", ["spark"]],
	"crystal_growth": ["matter", ["bloom", "veil"]], "glass": ["matter", ["glow"]], "density": ["matter", ["weight"]],
	"honeycomb": ["matter", ["weight", "hush"]], "lodestones": ["matter", ["weight", "echo"]],
	"shifting_stones": ["matter", ["veil", "flow"]], "transmute": ["matter", ["veil"]],
	"day_and_night": ["time", ["echo", "hush"]], "slow_rivers": ["time", ["weight"]], "stillness": ["time", ["hush"]],
	"afterimage": ["time", ["veil", "glow"]], "delay": ["time", ["veil", "hush"]], "haste": ["time", ["flow", "spark"]],
	"held_breath": ["time", ["hush", "weight"]], "tidemark": ["time", ["echo"]], "glowing_dark": ["energy", ["hush"]],
	"heat_bloom": ["energy", ["spark"]], "spark_trails": ["energy", ["glow"]], "aurora": ["energy", ["glow"]],
	"chain_lightning": ["energy", ["spark"]], "static": ["energy", ["spark"]],
	"overcharge": ["energy", ["spark", "echo"]], "sunburst": ["energy", ["glow", "spark"]],
	"bloom": ["life", ["bloom", "hush"]], "kinship": ["life", ["bloom"]], "wild_paths": ["life", ["bloom", "flow"]],
	"flock": ["life", ["bloom"]], "spores": ["life", ["hush", "weight"]], "thorns": ["life", ["bloom", "weight"]],
	"regrowth": ["life", ["bloom", "echo"]], "swarm_birth": ["life", ["bloom"]],
	"haunting": ["spirit", ["glow", "echo"]], "soul_lanterns": ["spirit", ["glow"]],
	"whispers": ["spirit", ["glow", "echo"]], "echoes": ["spirit", ["echo"]], "sleepwalk": ["spirit", ["hush", "echo"]],
	"soul_swap": ["spirit", ["veil"]], "borrowed_face": ["spirit", ["veil", "hush"]],
	"mirror_images": ["spirit", ["veil"]]}
## §8.5's chords, each its three notes (content/chords.json).
const CHORDS := {"tempest": ["flow", "spark", "glow"], "deep_sleep": ["weight", "hush", "bloom"],
	"ghost_tide": ["flow", "echo", "hush"], "fair_lights": ["glow", "bloom", "veil"],
	"iron_bell": ["weight", "echo", "glow"], "mirage": ["flow", "veil", "glow"],
	"clockwork": ["weight", "spark", "echo"], "wild_hunt": ["flow", "spark", "hush"],
	"hidden_garden": ["bloom", "hush", "veil"], "lantern_festival": ["glow", "bloom", "echo"],
	"quicksand": ["weight", "veil", "hush"], "rebound": ["flow", "echo", "spark"]}
## §8.1's opposites; each clash is named by its first note.
const OPPOSITE := {"flow": "weight", "weight": "flow", "glow": "hush", "hush": "glow", "bloom": "spark",
	"spark": "bloom", "echo": "veil", "veil": "echo"}
const CLASHES: Array[String] = ["flow", "glow", "bloom", "echo"]
## §21.2: "Notes use the colours of the wheel in 8.1": the wheel's colours
## as Screens v3 draws them (icons.js, lawnotes).
const NOTE_COLOUR := {"flow": "#5AB8F0", "weight": "#8A7AA0", "glow": "#F6C453", "hush": "#5A4A9A",
	"bloom": "#5CC46A", "spark": "#F07A3C", "echo": "#3CC6D8", "veil": "#E05CB4"}
## Each note's symbol (§8.1) as law_fx_mote's nearest shape, so a thread's
## note reads by shape as well as colour (§20.8): a wave's streak, an
## anchor's drop, a sun's sparkle, a crescent's soft dot, a sprout's leaf,
## a star's zigzag, a ring, a mask's hexagon.
const NOTE_SHAPE := {"flow": 11, "weight": 9, "glow": 2, "hush": 0, "bloom": 10, "spark": 8, "echo": 6, "veil": 7}
## Where a link hangs, over the pylon's foot: at its crown.
const LIFT := 1.82


static func school(law: String) -> String:
	return str(LAWS.get(law, ["motion", []])[0])


static func notes(law: String) -> Array:
	return LAWS.get(law, ["", []])[1]


static func note_colour(note: String) -> Color:
	return Color(str(NOTE_COLOUR.get(note, "#FFFFFF")))


## §8.2: each pair of `laws` sharing a note, once for each note shared:
## [{"a", "b", "note"}].
static func harmonies(laws: Array) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for i in laws.size():
		for j in range(i + 1, laws.size()):
			for n: String in notes(laws[i]):
				if notes(laws[j]).has(n) and laws[i] != laws[j]:
					out.append({"a": laws[i], "b": laws[j], "note": n})
	return out


## §8.3: each pair of `laws` with opposite notes: [{"a", "b", "clash"}],
## the clash named by its first note in CLASHES.
static func dissonances(laws: Array) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for i in laws.size():
		for j in range(i + 1, laws.size()):
			for n: String in notes(laws[i]):
				if notes(laws[j]).has(OPPOSITE[n]):
					out.append({"a": laws[i], "b": laws[j], "clash": n if CLASHES.has(n) else str(OPPOSITE[n])})
	return out


## §8.5 and §8.8: each chord three distinct laws of `laws` complete, each
## law giving one of its three notes: [{"chord", "laws"}].
static func chords(laws: Array) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for id: String in CHORDS:
		var want: Array = CHORDS[id]
		var found := _triple(laws, want)
		if not found.is_empty():
			out.append({"chord": id, "laws": found})
	return out


static func _triple(laws: Array, want: Array) -> Array:
	for i in laws.size():
		for j in laws.size():
			for k in laws.size():
				if i == j or j == k or i == k or laws[i] == laws[j] or laws[j] == laws[k] or laws[i] == laws[k]:
					continue
				if notes(laws[i]).has(want[0]) and notes(laws[j]).has(want[1]) and notes(laws[k]).has(want[2]):
					return [laws[i], laws[j], laws[k]]
	return []


## Draw every link between `fx`'s pylons into `into`.
static func build(fx: LawFx, into: Node3D) -> void:
	var laws: Array = []
	for p: Dictionary in fx.site.pylons:
		if not laws.has(p["law"]):
			laws.append(p["law"])
	var threads := LawFxBatch.new(LawFxBatch.Kind.THREADS)
	var travel := LawFxBatch.new(LawFxBatch.Kind.MOTES)
	var r := fx.site.rng("links")
	var lift := Vector3(0, LIFT, 0)
	var pair_count := {}
	for h: Dictionary in harmonies(laws):
		var a := fx.site.pylon_of(h["a"]) + lift
		var b := fx.site.pylon_of(h["b"]) + lift
		# Two notes shared hang two threads, one under the other.
		var key := [h["a"], h["b"]]
		var nth: int = pair_count.get(key, 0)
		pair_count[key] = nth + 1
		var col := note_colour(h["note"])
		threads.strip(LawFxBatch.sagging(a, b, 0.45 + nth * 0.3, 20), col, 0)
		_beads(travel, LawFxBatch.sagging(a, b, 0.45 + nth * 0.3, 4), col, int(NOTE_SHAPE[h["note"]]), r)
		LawFxHarmony.note(fx, into, h["note"], a - lift, b - lift)
	for d: Dictionary in dissonances(laws):
		var a := fx.site.pylon_of(d["a"]) + lift
		var b := fx.site.pylon_of(d["b"]) + lift
		var col := note_colour(d["clash"]).lerp(note_colour(OPPOSITE[d["clash"]]), 0.35)
		threads.strip(LawFxBatch.sagging(a, b, -0.25, 28), col, 1)
		LawFxHarmony.clash(fx, into, d["clash"], a - lift, b - lift)
	for c: Dictionary in chords(laws):
		var pts: Array[Vector3] = []
		for law: String in c["laws"]:
			pts.append(fx.site.pylon_of(law) + lift + Vector3(0, 0.25, 0))
		var want: Array = CHORDS[c["chord"]]
		for k in 3:
			var col := note_colour(want[k]).lerp(note_colour(want[(k + 1) % 3]), 0.5).lightened(0.25)
			threads.strip(LawFxBatch.sagging(pts[k], pts[(k + 1) % 3], 0.0, 18), col, 2, k / 3.0, (k + 1) / 3.0)
		LawFxHarmony.chord(fx, into, c["chord"], pts)
	if threads.triangles > 0:
		fx.layer(into, threads, fx.thread_material())
	if travel.triangles > 0:
		fx.layer(into, travel, fx.mote_material(0.6))


## A note's symbols travelling along a thread through `pts`, piece by piece.
static func _beads(b: LawFxBatch, pts: Array[Vector3], col: Color, shape: int, r: RandomNumberGenerator) -> void:
	for k in pts.size() - 1:
		var a: Vector3 = pts[k]
		var c: Vector3 = pts[k + 1]
		var period := maxf(0.8, a.distance_to(c) / 0.9)
		for n in 2:
			b.mote(a, (c - a) / period, period, n * 0.5 + r.randf() * 0.1, 0.11, 0.0, shape, Color(col.lightened(0.3), 1.0))


## §7.5's paradoxes, over the whole realm.
static func paradox(fx: LawFx, id: String) -> void:
	var into := Node3D.new()
	into.name = "Paradox"
	fx.add_child(into)
	LawFxHarmony.paradox(fx, into, id)
