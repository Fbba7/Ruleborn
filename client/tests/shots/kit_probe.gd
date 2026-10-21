extends SceneTree
## Prints each building's triangles at the full and the mid detail, and a
## lived-in realm's kit at both (T3's budget probe, §21.3).
func _initialize() -> void:
	var colours := RealmPalette.of("heart")
	var sums := [0, 0]
	for kind: String in BuildingKit.KINDS:
		var line := kind
		for lvl: int in BuildingKit.LOOKS:
			var n: Array[int] = []
			for det: int in [BuildingKit.FULL, BuildingKit.MID]:
				var g := Geo.new()
				g.skip_down = true
				var fine := Geo.new()
				fine.skip_down = true
				var side := 3 if kind == "keeper_s_spire" else 2
				BuildingKit.build(g, kind, Vector3.ZERO, side, lvl, colours, fine, null, 0.0, det)
				n.append(g.triangles * 2 + fine.triangles)
			line += "  L%d %d/%d" % [lvl, n[0], n[1]]
			sums[0] += n[0]
			sums[1] += n[1]
		print(line)
	print("all (hero x2 + fine): ", sums, " ratio ", float(sums[1]) / sums[0])
	for det: int in [BuildingKit.FULL, BuildingKit.MID]:
		var kit := KitTests.lived_in(10, det)
		var parts := {}
		var total := 0
		for pair: Array in [["ground", kit.ground], ["scatter", kit.scatter], ["hero", kit.hero], ["prop", kit.prop],
				["clear", kit.clear], ["water", kit.water], ["lava", kit.lava]]:
			parts[pair[0]] = (pair[1] as Geo).triangles
			total += (pair[1] as Geo).triangles
		print("realm detail ", det, " ", parts, " total ", total, " drawn (ink) ", total + kit.hero.triangles)
	for det: bool in [false, true]:
		var g := Geo.new()
		var f := Geo.new()
		g.skip_down = true
		f.skip_down = true
		g.coarse = det
		f.coarse = det
		KitSignature.build(g, f, "heart", 10.4, colours, 1.0)
		print("walls coarse ", det, " hero ", g.triangles, " fine ", f.triangles)
	for code: int in range(1, 42):
		var n: Array[int] = []
		for det: int in [BuildingKit.FULL, BuildingKit.MID]:
			var k := KitTests.single(code)
			k.detail = det
			k.build()
			n.append(k.hero.triangles * 2 + k.prop.triangles + k.scatter.triangles + k.clear.triangles)
		print("feature ", code, " ", n)
	quit()
