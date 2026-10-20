class_name LawFxSigns3
extends RefCounted
## §21.7's world signatures for the 24 laws after launch, drawn now so a law
## added to the game needs no art pass: lighter than the launch 24's, from
## the same strokes (LawFxPaint). Returns false for a law it does not know.

const INK := Color("#1A0C14")


static func build(fx: LawFx, sig: Node3D, law: String) -> bool:
	var ground := LawFxPaint.ground(fx.site)
	var home := LawFxPaint.home(fx, law)
	var h := fx.site.half()
	match law:
		"tilt":
			# "Trees, lanterns and banners lean one way; water runs downhill."
			LawFxPaint.spray(fx, sig, law, {"n": 30, "shape": 3, "colour": Color("#B8741E", 0.8), "radius": [0.05, 0.08],
				"tiles": ground, "lift": [0.05, 0.3], "vel": Vector3(0.9, -0.05, 0.3), "period": [2.0, 3.0]})
			LawFxPaint.spray(fx, sig, law + "_leaves", {"n": 16, "shape": 10, "colour": Color("#5CC46A"),
				"tiles": fx.site.tiles(LawFxSite.PLANTS), "lift": [0.4, 1.2], "vel": Vector3(0.6, -0.1, 0.2),
				"period": [3.0, 4.0], "radius": [0.06, 0.09]})
		"heavy_ground":
			# "Grass lies flat; footprints sink deep."
			var steps: Array = []
			var r := fx.site.rng(law)
			for t: Vector2i in LawFxPaint.some(ground, 26):
				steps.append(fx.site.centre(t) + Vector3(r.randf_range(-0.3, 0.3), 0, r.randf_range(-0.3, 0.3)))
			LawFxPaint.rounds(fx, sig, steps, 0.3, 12, Color("#5A3F2E"))
		"leapfrog":
			# "Springy turf covered in hop marks."
			var marks: Array = []
			for t: Vector2i in LawFxPaint.some(ground, 18):
				marks.append(fx.site.centre(t))
			LawFxPaint.rounds(fx, sig, marks, 0.7, 4, Color("#3E9B4A"))
		"crystal_growth":
			# "Crystals sprout where walls broke and hum softly."
			var r := fx.site.rng(law)
			var b := LawFxBatch.new(LawFxBatch.Kind.SOLIDS)
			for t: Vector2i in fx.site.tiles(LawFxSite.WALLS):
				for k in 3:
					var g := Geo.new()
					var tilt := Basis(Vector3(r.randf() - 0.5, 0, r.randf() - 0.5).normalized(), 0.35)
					g.prism(Transform3D(tilt, Vector3.ZERO), 6, 0.13, 0.0, r.randf_range(0.5, 0.85),
						Color(Palette.MATTER.lightened(0.1), 0.7))
					var at := fx.site.centre(t) + Vector3(r.randf_range(-0.55, 0.55), 0, r.randf_range(-0.55, 0.55))
					b.geo(g, at, r.randf())
			if b.triangles > 0:
				fx.layer(sig, b, fx.solid_material(4, 1.0), true)
		"lodestones":
			# "Iron filings fan out around each lodestone": round the pylon.
			var b := LawFxBatch.new(LawFxBatch.Kind.MOTES)
			for k in 48:
				var a := k * TAU / 48.0
				var d := 0.6 + float(k % 4) * 0.35
				var out := Vector3(cos(a), 0, sin(a))
				b.mote(home + out * d + Vector3(0, 0.04, 0), out * 0.001, 0.0, float(k) / 48.0, 0.05, 0.0, 3,
					Color("#3A3448", 0.9))
			fx.layer(sig, b, fx.mote_material(0.0))
		"shifting_stones":
			# "Walls glide along grooves with a grinding rumble."
			LawFxPaint.mark(fx, sig, fx.site.tiles(LawFxSite.WALLS), 13, Color("#6A5A5A"), Color("#3A2A2A"))
			LawFxPaint.spray(fx, sig, law, {"n": 20, "shape": 0, "colour": Color("#B9AE9F", 0.8),
				"tiles": fx.site.tiles(LawFxSite.WALLS), "lift": [0.0, 0.3], "vel": Vector3(0.3, 0.1, 0),
				"period": [1.5, 2.5], "radius": [0.06, 0.1]})
		"transmute":
			# "Loot glints and shifts colour."
			LawFxPaint.spray(fx, sig, law, {"n": 24, "shape": 2, "colour": Color("#F6C453"),
				"colour_b": Color("#5CC46A"), "at": fx.site.heart, "reach": 1.2, "lift": [0.2, 1.0], "glow": 0.8})
		"afterimage":
			# "Faint ghost frames linger where people passed."
			LawFxPaint.spray(fx, sig, law, {"n": 30, "shape": 9, "colour": Color("#8C6CF0", 0.45),
				"tiles": LawFxPaint.some(ground, 12), "lift": [0.3, 0.5], "radius": [0.22, 0.3]})
		"held_breath":
			# "Floating dust hangs still in the air."
			LawFxPaint.spray(fx, sig, law, {"n": 90, "shape": 0, "colour": Color("#E8DCCB", 0.9),
				"lift": [0.3, 2.4], "radius": [0.04, 0.07]})
		"tidemark":
			# "A thin silver tide line sweeps the ground at each mark."
			LawFxPaint.rounds(fx, sig, [fx.site.heart], h.length(), 4, Color("#C9D3E6"), INK, 0.4)
		"heat_bloom":
			# "Heat haze around braziers."
			var hot := fx.site.tiles(LawFxSite.LIGHTS)
			if hot.is_empty() and not fx.site.pylons.is_empty():
				hot.append(fx.site.pylons[0]["tile"])
			LawFxPaint.spray(fx, sig, law, {"n": 30, "shape": 11, "colour": Color("#F07A3C", 0.6), "tiles": hot,
				"lift": [0.3, 0.8], "vel": Vector3(0, 0.5, 0), "period": [1.5, 2.5], "radius": [0.15, 0.22]})
		"spark_trails":
			# "Sparkles fade slowly on the ground."
			LawFxPaint.spray(fx, sig, law, {"n": 50, "shape": 2, "colour": Color("#FFD24A"), "tiles": ground,
				"lift": [0.03, 0.08], "radius": [0.05, 0.09], "glow": 0.8})
		"overcharge":
			# "Pylons pulse in threes."
			var at: Array = []
			for p: Dictionary in fx.site.pylons:
				at.append(p["at"])
			LawFxPaint.rounds(fx, sig, at, 1.6, 4, Palette.ENERGY, INK, 3.0)
		"sunburst":
			# "A sun flare every 25 seconds; shade patches are marked."
			var shade: Array = []
			for t: Vector2i in fx.site.tiles(LawFxSite.WALLS + LawFxSite.PLANTS):
				shade.append(fx.site.centre(t + Vector2i(1, 1)))
			LawFxPaint.rounds(fx, sig, shade, 0.6, 8, Color("#3A2B6B"))
			var tint := fx.tint(Color("#FFF2B0"), 0.0)
			if tint != null:
				fx.every(func(s: float) -> void:
					var u := fmod(s, 25.0)
					tint.set_shader_parameter("flash", 0.5 * (1.0 - u) if u < 1.0 else 0.0))
		"wild_paths":
			# "Flowers bloom wherever people walk."
			LawFxPaint.spray(fx, sig, law, {"n": 50, "shape": 5, "colour": Color("#F7A6DA"),
				"colour_b": Color("#FFF2A0"), "tiles": ground, "lift": [0.03, 0.08], "radius": [0.05, 0.08]})
		"flock":
			# "Fluffy puffballs graze across the realm."
			var r := fx.site.rng(law)
			var b := LawFxBatch.new(LawFxBatch.Kind.SOLIDS)
			for t: Vector2i in LawFxPaint.some(ground, 7):
				var g := Geo.new()
				g.ball(Geo.place(Vector3(0, 0.22, 0)), 0.22, Color("#FCFBFF"), 4, 9)
				g.ball(Geo.place(Vector3(0.14, 0.32, 0.12)), 0.13, Color("#FCFBFF"), 3, 7)
				g.ball(Geo.place(Vector3(0, 0.26, -0.2)), 0.04, INK, 2, 5)
				b.geo(g, fx.site.centre(t), r.randf(), r.randf() * TAU)
			fx.layer(sig, b, fx.solid_material(7, 0.5), true)
		"spores":
			# "Pollen clouds drift lazily."
			LawFxPaint.spray(fx, sig, law, {"n": 30, "shape": 0, "colour": Color("#F6E07A", 0.6), "lift": [0.4, 1.6],
				"vel": Vector3(0.15, 0.02, 0.1), "period": [8.0, 12.0], "radius": [0.2, 0.35], "wobble": 0.2})
		"swarm_birth":
			# "Seed pods cluster around guard posts."
			var r := fx.site.rng(law)
			var b := LawFxBatch.new(LawFxBatch.Kind.SOLIDS)
			for post: Vector3 in fx.site.posts:
				for k in 4:
					var g := Geo.new()
					g.ball(Geo.place(Vector3(0, 0.1, 0), 0.0, Vector3(0.8, 1.2, 0.8)), 0.1, Color("#7AB84A"), 3, 7)
					var a := r.randf() * TAU
					b.geo(g, post + Vector3(cos(a) * 0.6, 0, sin(a) * 0.6), r.randf())
			if b.triangles > 0:
				fx.layer(sig, b, fx.solid_material(4, 1.0), true)
		"haunting":
			# "Ghostly footprints trail anyone carrying loot."
			var steps: Array = []
			for k in 10:
				steps.append(fx.site.heart + Vector3(k * 0.45 - 2.0, 0, sin(k * 0.9) * 0.3 + 1.0))
			LawFxPaint.rounds(fx, sig, steps, 0.22, 12, Color("#8FD8FF"))
		"soul_lanterns":
			# "Warm lantern pools in cold blue dusk."
			fx.tint(Color("#1A2A6B"), 0.45, 0.08)
			var pools: Array = []
			for t: Vector2i in fx.site.tiles(LawFxSite.LIGHTS):
				pools.append(fx.site.centre(t))
			pools.append(home)
			LawFxPaint.rounds(fx, sig, pools, 1.8, 8, Color("#FFC24A"))
		"borrowed_face":
			# "Festival lanterns and confetti."
			LawFxPaint.spray(fx, sig, law, {"n": 60, "shape": 7, "colour": Color("#E05CB4"),
				"colour_b": Color("#3CC6D8"), "lift": [0.5, 2.5], "vel": Vector3(0.05, -0.3, 0.02),
				"period": [4.0, 7.0], "radius": [0.04, 0.06], "wobble": 0.2})
		"mirror_images":
			# "Mirror glints in the corners of the eye."
			LawFxPaint.spray(fx, sig, law, {"n": 24, "shape": 2, "colour": Color("#FFFFFF"), "lift": [0.3, 1.4],
				"radius": [0.08, 0.14], "glow": 1.0, "pace": 0.6})
			fx.tint(Color("#C9B6FF"), 0.25)
		_:
			return false
	return true
