extends SceneTree
## Each ruleborn's and Sage's mean colour in its bust (CreatureBust, clear
## behind), printed as `MEAN kind r g b` for tools/art/colour.py to set
## beside the design's portraits (run as tools/art/colour.py says).


func _initialize() -> void:
	_go()


func _go() -> void:
	var kinds: Array = StageHeroFigure.KINDS.keys().filter(func(k: String) -> bool: return k not in ["egg", "shell"])
	var busts: Array[Texture2D] = []
	for k: String in kinds:
		busts.append(CreatureBust.of(k))
	for i in 600:
		await process_frame
		if CreatureBust.settled() and i > 4:
			break
	for j in kinds.size():
		var image := busts[j].get_image()
		var sum := Vector3.ZERO
		var n := 0
		for y in range(0, image.get_height(), 2):
			for x in range(0, image.get_width(), 2):
				var c := image.get_pixel(x, y)
				if c.a > 0.8:
					sum += Vector3(c.r, c.g, c.b)
					n += 1
		sum = sum / maxf(1.0, float(n)) * 255.0
		print("MEAN %s %d %d %d" % [StageHeroFigure.key(kinds[j]).replace("_", ""), int(sum.x), int(sum.y), int(sum.z)])
	quit()
