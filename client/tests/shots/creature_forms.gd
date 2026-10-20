extends SceneTree
## Every form of a set of ruleborn (§21.6, 11.10): a row each for base, Hush,
## Spark, Echo and the guard form, the kinds side by side to scale, saved as a
## still (tools/render/shoot.sh). KINDS picks the kinds (comma-separated; the
## default is one of each school), W and H the size, T the moment in the clips.

const DEFAULT := ["featherkin", "rambler", "hourkeeper", "emberling", "mossbear", "lanternwisp"]
const ROWS := [&"base", &"hush", &"spark", &"echo", &"guard"]


func _initialize() -> void:
	var w := int(OS.get_environment("W")) if OS.get_environment("W") != "" else 1400
	var h := int(OS.get_environment("H")) if OS.get_environment("H") != "" else 1500
	var vp := SubViewport.new()
	vp.size = Vector2i(w, h)
	vp.own_world_3d = true
	vp.msaa_3d = Viewport.MSAA_4X
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(vp)
	var world := Node3D.new()
	vp.add_child(world)
	var look := WorldLook.new(world)
	look.set_hour(12)
	var kinds: Array[String] = []
	var wanted: PackedStringArray = OS.get_environment("KINDS").split(",", false)
	for k: String in (wanted if not wanted.is_empty() else PackedStringArray(DEFAULT)):
		if CreatureModel.manifest().has(k):
			kinds.append(k)
	var tallest := 0.0
	var span := 0.0
	for k: String in kinds:
		var entry: Dictionary = CreatureModel.manifest()[k]
		tallest = maxf(tallest, float(entry.get("height", 1.0)))
		span += maxf(0.3, float(entry.get("radius", 0.3))) * 2.0 + 0.3
	var models: Array[CreatureModel] = []
	for r in ROWS.size():
		var x := -span * 0.5
		for k: String in kinds:
			var c := CreatureModel.make(StringName(k))
			var rad := maxf(0.3, float(c.info.get("radius", 0.3)))
			x += rad
			world.add_child(c)
			c.place(Vector3(x, -float(r) * tallest * 1.25, 0), Vector3(0.35, 0, 1))
			x += rad + 0.3
			if ROWS[r] == &"guard":
				c.set_guard(true)
			else:
				c.set_form(ROWS[r])
			c.play(&"idle")
			models.append(c)
	var cam := Camera3D.new()
	world.add_child(cam)
	cam.projection = Camera3D.PROJECTION_ORTHOGONAL
	cam.keep_aspect = Camera3D.KEEP_HEIGHT
	cam.size = maxf(tallest * 1.25 * float(ROWS.size()) + 0.2, span * float(h) / float(w) * 1.04)
	var target := Vector3(0, tallest * 0.6 - tallest * 1.25 * float(ROWS.size() - 1) * 0.5, 0)
	var from := target + Vector3(0, 0.9, 6.0)
	cam.transform = Transform3D(Basis.looking_at(target - from, Vector3.UP), from)
	var t := float(OS.get_environment("T")) if OS.get_environment("T") != "" else 0.8
	for i in 3:
		await process_frame
	for c: CreatureModel in models:
		c.player().seek(t, true)
	for i in 3:
		await process_frame
	var img := vp.get_texture().get_image()
	img.save_png(OS.get_environment("SHOT"))
	print("saved ", img.get_size(), " ", kinds.size(), " kinds")
	quit()
