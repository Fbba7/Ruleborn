class_name StabilityTests
extends RefCounted
## TD.14 on the client: §5.5's stability priced by the simulation's one
## function through the extension, the same the server charges with, held
## to the cases the simulation writes (sim/stability_cases.json).

var check: Callable


func _init(c: Callable) -> void:
	check = c


func run() -> void:
	var path := ProjectSettings.globalize_path("res://").path_join("../sim/stability_cases.json")
	var cases: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	var name := "the client's prices equal the simulation's, to the millionth of a point, for every launch law alone, "
	name += "crowned, in each era and in every pair (TD.14)"
	if not (cases is Dictionary):
		check.call(name, false, "no cases at %s" % path)
		return
	var wrong: Array[String] = []
	for c: Dictionary in cases["cases"]:
		var p := RulebornStability.price(PackedByteArray(c["wire"]))
		var micro: Array = (p.get("lines", []) as Array).map(func(l: Dictionary) -> int: return int(l["micro"]))
		var want: Array = (c["costs"] as Array).map(func(v: Variant) -> int: return int(v))
		if not p.get("ok", false) or micro != want or int(p["total_micro"]) != int(c["total"]) \
				or int(p["band"]) != int(c["band"]):
			wrong.append("%s: %s" % [c["wire"], p])
	check.call(name, wrong.is_empty() and (cases["cases"] as Array).size() == 372
			and Array(RulebornStability.law_ids()) == cases["laws"], "; ".join(wrong.slice(0, 3)))
	# §8.5's worked example: Slow rivers and Thorns in the Heart, Bloom
	# crowned, at Spire 5 and Anchor Stones 5, 5, 4, 4 and 3: 215, the chord
	# silent, 27.44.
	var rows := Array(RulebornStability.law_ids())
	var wire := PackedByteArray([5, 1, 0, 5, 5, 5, 4, 4, 3, 1, 255, 3,
		rows.find("slow_rivers"), 1, 0, rows.find("thorns"), 1, 0, rows.find("bloom"), 1, 255])
	var ex := RulebornStability.price(wire)
	check.call("§8.5's worked example priced on the client: 215 of capacity, the chord silent, 6.8 + 8.67 + 11.97 "
			+ "(5.5, 8.5, TD.14)",
		ex.get("ok", false) and is_equal_approx(float(ex["capacity"]), 215.0) and (ex["chords"] as Array).is_empty()
			and int(ex["total_micro"]) == 27438000 and int(ex["lines"][0]["micro"]) == 6800000
			and int(ex["lines"][2]["resonances"]) == 2 and not RulebornStability.price(PackedByteArray([5])).get("ok"),
		"%s" % [ex])
